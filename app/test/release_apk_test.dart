import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/update/release_apk.dart';

void main() {
  Map<String, dynamic> apk(String suffix) => {
    'name': 'kiosk-satellite-v1.2.3$suffix.apk',
    'browser_download_url': 'https://example.test/v1.2.3$suffix.apk',
    'state': 'uploaded',
    'size': suffix.isEmpty ? 150 : 75,
  };

  final universal = apk('');
  final arm = apk('.armeabi-v7a');
  final arm64 = apk('.arm64-v8a');
  final x64 = apk('.x86_64');

  for (final order in [
    [universal, arm, arm64, x64],
    [x64, arm, universal, arm64],
  ]) {
    test(
      'selects the OS preferred ABI with asset order ${order.first['name']}',
      () {
        expect(
          selectReleaseApk(order, '1.2.3', ['arm64-v8a', 'armeabi-v7a']),
          arm64,
        );
        expect(
          selectReleaseApk(order, 'v1.2.3', ['armeabi-v7a', 'armeabi']),
          arm,
        );
        expect(selectReleaseApk(order, '1.2.3', ['x86_64', 'x86']), x64);
      },
    );
  }

  test('uses another supported ABI when the preferred split is missing', () {
    expect(
      selectReleaseApk([universal, arm], '1.2.3', ['arm64-v8a', 'armeabi-v7a']),
      arm,
    );
  });

  test(
    'uses universal for unknown ABIs and releases without matching splits',
    () {
      for (final abis in <List<String>>[
        [],
        ['riscv64'],
        ['armeabi-v7a'],
      ]) {
        expect(selectReleaseApk([x64, universal], '1.2.3', abis), universal);
      }
      expect(selectReleaseApk([universal], '1.2.3', ['arm64-v8a']), universal);
    },
  );

  test('recognizes universal releases whose tag has no v prefix', () {
    final old = {...universal, 'name': 'kiosk-satellite-1.2.3.apk'};
    expect(selectReleaseApk([old], 'v1.2.3', ['arm64-v8a']), old);
  });

  test('never substitutes an incompatible or unrelated APK', () {
    expect(selectReleaseApk([x64, arm64], '1.2.3', ['armeabi-v7a']), isNull);
    expect(selectReleaseApk([universal], '1.2.4', ['arm64-v8a']), isNull);
    expect(
      selectReleaseApk(
        [
          {...universal, 'name': 'other.apk'},
        ],
        '1.2.3',
        [],
      ),
      isNull,
    );
  });

  test('ignores incomplete split uploads and falls back to universal', () {
    for (final broken in [
      {...arm64, 'state': 'starter'},
      {...arm64, 'browser_download_url': ''},
      {...arm64, 'browser_download_url': null},
    ]) {
      expect(
        selectReleaseApk([broken, universal], '1.2.3', ['arm64-v8a']),
        universal,
      );
    }
  });
}
