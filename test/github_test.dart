import 'package:basalt/basalt.dart';
import 'package:flutter_test/flutter_test.dart';

ReleaseAsset a(String name, {int size = 10, String? digest}) =>
    ReleaseAsset(name: name, size: size, url: 'https://example.com/$name', digest: digest);

Release r(String tag, List<ReleaseAsset> assets, {bool draft = false, bool pre = false}) =>
    Release(tag: tag, notes: 'notes', pageUrl: 'p', publishedAt: '', assets: assets, draft: draft, prerelease: pre);

void main() {
  test('compares versions', () {
    expect(isNewer('v1.2.0', '1.1.9'), isTrue);
    expect(isNewer('1.2.0', '1.2.0'), isFalse);
    expect(isNewer('1.10.0', '1.9.0'), isTrue);
    expect(isNewer('2.0.0+5', '1.9.9+40'), isTrue);
    expect(isNewer('garbage', '1.0.0'), isFalse);
  });

  test('picks the APK for the phone ABI', () {
    final assets = [a('app-1.2.0-x86_64.apk'), a('app-1.2.0-arm64-v8a.apk'), a('app-1.2.0-armeabi-v7a.apk')];
    expect(pickApk(assets, ['arm64-v8a', 'armeabi-v7a'])!.name, 'app-1.2.0-arm64-v8a.apk');
    expect(pickApk(assets, ['armeabi-v7a'])!.name, 'app-1.2.0-armeabi-v7a.apk');
    expect(pickApk(assets, ['x86']), isNull);
    expect(pickApk([a('app.apk')], ['x86'])!.name, 'app.apk');
  });

  test('evaluates releases', () {
    final sum = 'a' * 64;
    final rel = r('v1.3.0', [a('x-1.3.0-arm64-v8a.apk', size: 5), a('x-1.3.0-arm64-v8a.apk.sha256')]);
    final res = evaluateRelease(rel, '1.2.0', sidecar: '$sum  x-1.3.0-arm64-v8a.apk', abis: ['arm64-v8a']);
    expect(res, isA<UpdateAvailable>());
    final u = (res as UpdateAvailable).update;
    expect(u.version, '1.3.0');
    expect(u.sha256, sum);
    expect(u.sizeBytes, 5);

    expect(evaluateRelease(rel, '1.3.0', abis: ['arm64-v8a']), isA<UpToDate>());
    expect(evaluateRelease(r('v9.0.0', [a('x.apk')], draft: true), '1.0.0'), isA<UpToDate>());
    expect(evaluateRelease(r('v9.0.0', [a('x.zip')]), '1.0.0'), isA<UpdateUnavailable>());
    final digest = evaluateRelease(r('v9.0.0', [a('x.apk', digest: 'sha256:${'b' * 64}')]), '1.0.0') as UpdateAvailable;
    expect(digest.update.sha256, 'b' * 64);
    final bad = evaluateRelease(rel, '1.0.0', sidecar: 'nothex', abis: ['arm64-v8a']) as UpdateAvailable;
    expect(bad.update.sha256, isNull);
  });

  test('parses a GitHub payload', () {
    final rel = Release.tryParse({
      'tag_name': 'v1.0.1',
      'body': ' hi ',
      'html_url': 'u',
      'published_at': 'now',
      'assets': [
        {'name': 'a.apk', 'size': 3, 'browser_download_url': 'd'},
      ],
    });
    expect(rel!.tag, 'v1.0.1');
    expect(rel.notes, 'hi');
    expect(rel.assets.single.size, 3);
    expect(Release.tryParse({'nope': 1}), isNull);
  });

  test('formats bytes', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(2048), '2 KB');
    expect(formatBytes(17858719), '17.0 MB');
  });
}
