import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/btproxy/oui_cache.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('oui_cache_test');
    file = File('${dir.path}/oui.json');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('the old settings copy keeps its names and drops its misses', () async {
    final cache = OuiCache(file);
    await cache.load(legacy: '{"5C:E7:53":"Govee","30:64:1C":""}');
    expect(cache.name('5C:E7:53'), 'Govee');
    expect(cache.knows('30:64:1C'), isFalse);
    expect(jsonDecode(file.readAsStringSync()), {'5C:E7:53': 'Govee'});
  });

  test('a miss is remembered but never written', () async {
    final cache = OuiCache(file);
    await cache.load();
    cache.putMiss('30:64:1C');
    expect(cache.knows('30:64:1C'), isTrue);
    expect(cache.name('30:64:1C'), isNull);
    expect(file.existsSync(), isFalse);
    expect((OuiCache(file)..putMiss('AA')).knows('30:64:1C'), isFalse);
  });

  test('a name is written once and read back', () async {
    final cache = OuiCache(file);
    await cache.load();
    await cache.putName('5C:E7:53', 'Govee');
    final written = file.lastModifiedSync();
    final size = file.lengthSync();
    await cache.putName('5C:E7:53', 'Govee');
    expect(file.lastModifiedSync(), written);
    expect(file.lengthSync(), size);
    final next = OuiCache(file);
    await next.load();
    expect(next.name('5C:E7:53'), 'Govee');
    expect(next.knows('5C:E7:53'), isTrue);
  });

  test('the oldest misses go once the limit is passed', () {
    final cache = OuiCache(null);
    for (var i = 0; i <= OuiCache.maxMisses; i++) {
      cache.putMiss('$i');
    }
    expect(cache.knows('0'), isFalse);
    expect(cache.knows('1'), isTrue);
    expect(cache.knows('${OuiCache.maxMisses}'), isTrue);
  });
}
