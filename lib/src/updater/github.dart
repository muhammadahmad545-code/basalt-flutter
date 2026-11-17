/// Pure release logic shared with the React Native apps (`@basalt/core/updater/github.ts`).
library;

/// Parse "v1.2.3", "1.2.3+4", "1.2.3-beta" into [major, minor, patch].
List<int>? parseVersion(String input) {
  final m = RegExp(r'^v?(\d+)(?:\.(\d+))?(?:\.(\d+))?').firstMatch(input.trim());
  if (m == null) return null;
  return [int.parse(m.group(1)!), int.parse(m.group(2) ?? '0'), int.parse(m.group(3) ?? '0')];
}

/// 1 if a > b, -1 if a < b, 0 if equal or either is unparseable.
int compareVersions(String a, String b) {
  final pa = parseVersion(a);
  final pb = parseVersion(b);
  if (pa == null || pb == null) return 0;
  for (var i = 0; i < 3; i++) {
    if (pa[i] > pb[i]) return 1;
    if (pa[i] < pb[i]) return -1;
  }
  return 0;
}

bool isNewer(String candidate, String current) => compareVersions(candidate, current) == 1;

class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.size, required this.url, this.digest});

  factory ReleaseAsset.fromJson(Map<String, dynamic> j) => ReleaseAsset(
        name: (j['name'] ?? '') as String,
        size: (j['size'] as num?)?.toInt() ?? 0,
        url: (j['browser_download_url'] ?? '') as String,
        digest: j['digest'] as String?,
      );

  final String name;
  final int size;
  final String url;
  final String? digest;
}

class Release {
  const Release({
    required this.tag,
    required this.notes,
    required this.pageUrl,
    required this.publishedAt,
    required this.assets,
    this.draft = false,
    this.prerelease = false,
  });

  static Release? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final tag = json['tag_name'];
    final assets = json['assets'];
    if (tag is! String || assets is! List) return null;
    return Release(
      tag: tag,
      notes: (json['body'] as String?)?.trim() ?? '',
      pageUrl: (json['html_url'] as String?) ?? '',
      publishedAt: (json['published_at'] as String?) ?? '',
      draft: json['draft'] == true,
      prerelease: json['prerelease'] == true,
      assets: [for (final a in assets) if (a is Map<String, dynamic>) ReleaseAsset.fromJson(a)],
    );
  }

  final String tag;
  final String notes;
  final String pageUrl;
  final String publishedAt;
  final List<ReleaseAsset> assets;
  final bool draft;
  final bool prerelease;
}

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.pageUrl,
    required this.apkUrl,
    required this.apkName,
    required this.sizeBytes,
    this.sha256,
  });

  final String version;
  final String notes;
  final String pageUrl;
  final String apkUrl;
  final String apkName;
  final int sizeBytes;

  /// Lower-case hex SHA-256 of the APK, when the release publishes one.
  final String? sha256;
}

const _knownAbis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
final _hex64 = RegExp(r'^[0-9a-f]{64}$');

/// Releases ship one APK per processor type (app-1.2.0-arm64-v8a.apk). Pick the best one for
/// this phone: the first of its ABIs with an APK, else an APK built for all of them.
ReleaseAsset? pickApk(List<ReleaseAsset> assets, List<String> abis) {
  final apks = assets.where((a) => a.name.toLowerCase().endsWith('.apk')).toList();
  for (final abi in abis) {
    for (final a in apks) {
      if (a.name.toLowerCase().contains('-${abi.toLowerCase()}.apk')) return a;
    }
  }
  for (final a in apks) {
    if (!_knownAbis.any((abi) => a.name.toLowerCase().contains('-$abi.apk'))) return a;
  }
  return abis.isEmpty && apks.isNotEmpty ? apks.first : null;
}

sealed class CheckResult {
  const CheckResult();
}

class UpToDate extends CheckResult {
  const UpToDate();
}

class UpdateAvailable extends CheckResult {
  const UpdateAvailable(this.update);
  final UpdateInfo update;
}

enum UnavailableReason { offline, rateLimited, noRelease, noApk, serverError }

class UpdateUnavailable extends CheckResult {
  const UpdateUnavailable(this.reason);
  final UnavailableReason reason;
}

/// Turn a release into an update decision. [sidecar] is the text of `<apk>.sha256`, if fetched.
CheckResult evaluateRelease(Release release, String current, {String? sidecar, List<String> abis = const []}) {
  if (release.draft || release.prerelease) return const UpToDate();
  if (!isNewer(release.tag, current)) return const UpToDate();
  final apk = pickApk(release.assets, abis);
  if (apk == null) return const UpdateUnavailable(UnavailableReason.noApk);
  final fromApi = apk.digest?.toLowerCase().replaceFirst('sha256:', '');
  final fromSidecar = sidecar?.trim().split(RegExp(r'\s+')).first.toLowerCase();
  final candidate = fromApi ?? fromSidecar;
  return UpdateAvailable(
    UpdateInfo(
      version: release.tag.replaceFirst(RegExp('^v'), ''),
      notes: release.notes,
      pageUrl: release.pageUrl,
      apkUrl: apk.url,
      apkName: apk.name,
      sizeBytes: apk.size,
      sha256: candidate != null && _hex64.hasMatch(candidate) ? candidate : null,
    ),
  );
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
