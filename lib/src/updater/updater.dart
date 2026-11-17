import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'github.dart';

enum UpdatePhase { idle, checking, upToDate, available, downloading, ready, error }

@immutable
class UpdateState {
  const UpdateState(this.phase, {this.update, this.progress = 0, this.message, this.file, this.needsPermission = false});

  final UpdatePhase phase;
  final UpdateInfo? update;
  final double progress;
  final String? message;
  final File? file;

  /// Android has not yet allowed this app to install updates; Settings was opened.
  final bool needsPermission;
}

/// Device facts from the native side of the plugin.
class DeviceInfo {
  const DeviceInfo({required this.version, required this.abis, required this.freeBytes, required this.packageName});
  final String version;
  final List<String> abis;
  final int freeBytes;
  final String packageName;
}

/// Checks GitHub releases for a newer APK, downloads and verifies it, and hands it to Android's installer.
///
/// Checks once every time the app opens, and again when it returns to the foreground
/// after [resumeRecheck]. Settings can call [check] at any time.
class BasaltUpdater extends ChangeNotifier with WidgetsBindingObserver {
  BasaltUpdater._();

  static final BasaltUpdater instance = BasaltUpdater._();
  static const _channel = MethodChannel('dev.basalt/updater');
  static const resumeRecheck = Duration(minutes: 15);
  static const _kLast = 'basalt.updater.lastCheckAt';
  static const _kSkipped = 'basalt.updater.skipped';

  String _owner = '';
  String _repo = '';
  bool _started = false;
  DeviceInfo? _device;
  http.Client? _client;
  bool _cancelled = false;

  UpdateState _state = const UpdateState(UpdatePhase.idle);
  UpdateState get state => _state;

  String get currentVersion => _device?.version ?? '';
  String get repoUrl => 'https://github.com/$_owner/$_repo/releases';

  void _set(UpdateState s) {
    _state = s;
    notifyListeners();
  }

  /// Call once from main() after `WidgetsFlutterBinding.ensureInitialized()`.
  Future<void> start({required String owner, required String repo}) async {
    _owner = owner;
    _repo = repo;
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await _loadDevice();
    _clearOldDownloads();
    unawaited(check(silent: true));
  }

  Future<DeviceInfo?> _loadDevice() async {
    if (_device != null) return _device;
    if (!Platform.isAndroid) return null;
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('info');
      if (info == null) return null;
      _device = DeviceInfo(
        version: (info['version'] as String?) ?? '0.0.0',
        abis: [for (final a in (info['abis'] as List? ?? const [])) a.toString()],
        freeBytes: (info['freeBytes'] as num?)?.toInt() ?? 0,
        packageName: (info['packageName'] as String?) ?? '',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('basalt updater: device info failed: $e');
    }
    return _device;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(() async {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_kLast) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - last > resumeRecheck.inMilliseconds) {
        await check(silent: true);
      }
    }());
  }

  bool get _busy => _state.phase == UpdatePhase.checking || _state.phase == UpdatePhase.downloading;

  /// Ask GitHub for a newer release. Silent checks never show "up to date" or errors.
  Future<void> check({bool silent = false}) async {
    if (_busy || _state.phase == UpdatePhase.ready) return;
    if (_owner.isEmpty) return;
    final device = await _loadDevice();
    if (device == null) {
      if (!silent) _set(const UpdateState(UpdatePhase.error, message: 'Updates are only available on Android.'));
      return;
    }
    final before = _state;
    if (!silent) _set(const UpdateState(UpdatePhase.checking));
    final result = await _fetch(device);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLast, DateTime.now().millisecondsSinceEpoch);

    switch (result) {
      case UpdateAvailable(:final update):
        if (silent && prefs.getString(_kSkipped) == update.version) {
          _set(before.phase == UpdatePhase.checking ? const UpdateState(UpdatePhase.idle) : before);
        } else {
          _set(UpdateState(UpdatePhase.available, update: update));
        }
      case UpToDate():
        _set(silent ? (before.phase == UpdatePhase.available ? before : const UpdateState(UpdatePhase.idle)) : const UpdateState(UpdatePhase.upToDate));
      case UpdateUnavailable(:final reason):
        if (silent) {
          if (_state.phase == UpdatePhase.checking) _set(const UpdateState(UpdatePhase.idle));
        } else {
          _set(UpdateState(UpdatePhase.error, message: _reasonText(reason)));
        }
    }
  }

  String _reasonText(UnavailableReason r) => switch (r) {
        UnavailableReason.offline => "Couldn't reach GitHub. Check your connection and try again.",
        UnavailableReason.rateLimited => 'GitHub is limiting requests right now. Try again in a few minutes.',
        UnavailableReason.noRelease => 'No release has been published yet.',
        UnavailableReason.noApk => 'The latest release has no APK for this phone.',
        UnavailableReason.serverError => 'GitHub returned an unexpected response. Try again later.',
      };

  Future<CheckResult> _fetch(DeviceInfo device) async {
    final uri = Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');
    http.Response res;
    try {
      res = await http.get(uri, headers: {'Accept': 'application/vnd.github+json'}).timeout(const Duration(seconds: 10));
    } catch (_) {
      return const UpdateUnavailable(UnavailableReason.offline);
    }
    if (res.statusCode == 404) return const UpdateUnavailable(UnavailableReason.noRelease);
    if (res.statusCode == 403 || res.statusCode == 429) return const UpdateUnavailable(UnavailableReason.rateLimited);
    if (res.statusCode != 200) return const UpdateUnavailable(UnavailableReason.serverError);
    Release? release;
    try {
      release = Release.tryParse(jsonDecode(res.body));
    } catch (_) {
      release = null;
    }
    if (release == null) return const UpdateUnavailable(UnavailableReason.serverError);

    String? sidecar;
    final apk = pickApk(release.assets, device.abis);
    if (apk != null && apk.digest == null) {
      final sums = release.assets.where((a) => a.name == '${apk.name}.sha256').firstOrNull;
      if (sums != null) {
        try {
          final r = await http.get(Uri.parse(sums.url)).timeout(const Duration(seconds: 10));
          if (r.statusCode == 200) sidecar = r.body;
        } catch (_) {
          // No checksum; Android's signature check on install still applies.
        }
      }
    }
    return evaluateRelease(release, device.version, sidecar: sidecar, abis: device.abis);
  }

  /// Download the APK, verify size and SHA-256, then move to the ready state.
  Future<void> download() async {
    final update = _state.update;
    if (update == null || _busy) return;
    final device = await _loadDevice();
    if (device != null && device.freeBytes > 0 && device.freeBytes < update.sizeBytes * 2) {
      _set(UpdateState(UpdatePhase.error, update: update, message: 'Not enough free storage to download the update.'));
      return;
    }
    _cancelled = false;
    _set(UpdateState(UpdatePhase.downloading, update: update, progress: 0));
    final client = _client = http.Client();
    File? file;
    try {
      final dir = Directory(await _channel.invokeMethod<String>('updatesDir') ?? '');
      final out = File('${dir.path}/update-${update.version}.apk');
      file = out;
      if (out.existsSync()) out.deleteSync();
      final res = await client.send(http.Request('GET', Uri.parse(update.apkUrl))).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw const HttpException('bad status');
      final total = res.contentLength ?? update.sizeBytes;
      final sink = out.openWrite();
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      var received = 0;
      var lastTick = 0.0;
      try {
        await for (final chunk in res.stream.timeout(const Duration(seconds: 30))) {
          if (_cancelled) throw const _Cancelled();
          sink.add(chunk);
          hasher.add(chunk);
          received += chunk.length;
          final progress = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          if (progress - lastTick >= 0.01 || progress >= 1) {
            lastTick = progress;
            _set(UpdateState(UpdatePhase.downloading, update: update, progress: progress));
          }
        }
      } finally {
        await sink.close();
        hasher.close();
      }
      if (update.sizeBytes > 0 && received != update.sizeBytes) {
        throw const _Failure('The download was incomplete. Please try again.');
      }
      if (update.sha256 != null && digestSink.value?.toString() != update.sha256) {
        throw const _Failure('The downloaded update failed its integrity check and was discarded.');
      }
      _set(UpdateState(UpdatePhase.ready, update: update, file: out, progress: 1));
    } on _Cancelled {
      _deleteQuietly(file);
      _set(UpdateState(UpdatePhase.available, update: update));
    } on _Failure catch (e) {
      _deleteQuietly(file);
      _set(UpdateState(UpdatePhase.error, update: update, message: e.message));
    } catch (_) {
      _deleteQuietly(file);
      _set(_cancelled
          ? UpdateState(UpdatePhase.available, update: update)
          : UpdateState(
              UpdatePhase.error,
              update: update,
              message: 'Could not download the update. Check your connection and try again.',
            ));
    } finally {
      client.close();
      _client = null;
    }
  }

  void cancel() {
    _cancelled = true;
    _client?.close();
  }

  /// Open Android's installer for the verified APK. Asks for the install permission first if needed.
  Future<void> install() async {
    final file = _state.file;
    final update = _state.update;
    if (file == null || update == null) return;
    try {
      final allowed = await _channel.invokeMethod<bool>('canInstall') ?? false;
      if (!allowed) {
        await _channel.invokeMethod('openInstallSettings');
        _set(UpdateState(UpdatePhase.ready, update: update, file: file, progress: 1, needsPermission: true));
        return;
      }
      await _channel.invokeMethod('install', {'path': file.path});
      _set(UpdateState(UpdatePhase.ready, update: update, file: file, progress: 1));
    } on PlatformException catch (e) {
      _set(UpdateState(UpdatePhase.error, update: update, message: 'Could not open the installer: ${e.message ?? e.code}'));
    }
  }

  /// Hide this version until a newer one appears.
  Future<void> skip() async {
    final v = _state.update?.version;
    if (v != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSkipped, v);
    }
    _set(const UpdateState(UpdatePhase.idle));
  }

  void dismiss() => _set(const UpdateState(UpdatePhase.idle));

  Future<void> openReleasesPage() async {
    try {
      await _channel.invokeMethod('openUrl', {'url': repoUrl});
    } catch (_) {}
  }

  void _clearOldDownloads() {
    unawaited(() async {
      try {
        final path = await _channel.invokeMethod<String>('updatesDir');
        if (path == null) return;
        for (final f in Directory(path).listSync()) {
          f.deleteSync(recursive: true);
        }
      } catch (_) {}
    }());
  }

  void _deleteQuietly(File? f) {
    try {
      if (f != null && f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}

class _Cancelled implements Exception {
  const _Cancelled();
}

class _Failure implements Exception {
  const _Failure(this.message);
  final String message;
}
