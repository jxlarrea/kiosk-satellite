import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/btproxy/esp_entities.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Clock screensaver's background photo from a URL (issue #464): the
/// value is a device path or an http(s) URL the app fetches itself, capped
/// at what a Home Assistant text entity can hold, and every write reloads
/// the image so a rewrite of the same value is the refresh signal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAoCAIAAABmcd1FAAAALklEQVR4nO3MQQEAQAQAsHMttJJYNil4bQEWXfl2/KVXrVar1Wq1Wq1Wq9WH9QCo5QF3BVxaYAAAAABJRU5ErkJggg==',
  );

  group('validator', () {
    test('a device path or a blank passes', () {
      expect(defs.validateClockBackground(''), isNull);
      expect(defs.validateClockBackground('/sdcard/Download/bg.jpg'), isNull);
    });

    test('a URL must be whole, whatever its case', () {
      expect(
        defs.validateClockBackground('https://ha.local/local/a.jpg'),
        isNull,
      );
      expect(defs.validateClockBackground('HTTP://ha.local/a.jpg'), isNull);
      expect(defs.validateClockBackground('http://'), isNotNull);
      expect(defs.validateClockBackground('https:///a.jpg'), isNotNull);
      expect(defs.isClockBackgroundUrl(' https://x '), isTrue);
      expect(defs.isClockBackgroundUrl('/sdcard/https://x'), isFalse);
    });

    test('255 characters is the ceiling, on every writer', () async {
      expect(defs.validateClockBackground('a' * 255), isNull);
      expect(defs.validateClockBackground('a' * 256), isNotNull);
      SharedPreferences.setMockInitialValues({});
      final log = Logger();
      final settings = SettingsManager(EventBus(), CommandRegistry(log), log);
      await settings.init();
      expect(
        await settings.setFromJson(
          defs.screensaverClockBackground.key,
          'https://ha.local/${'a' * 250}',
        ),
        isFalse,
      );
      expect(settings.get(defs.screensaverClockBackground), '');
    });

    test('the refresh interval is whole minutes up to a day', () {
      expect(defs.validateClockBackgroundRefresh(0), isNull);
      expect(defs.validateClockBackgroundRefresh(1440), isNull);
      expect(defs.validateClockBackgroundRefresh(-1), isNotNull);
      expect(defs.validateClockBackgroundRefresh(1441), isNotNull);
      expect(defs.validateClockBackgroundRefresh(2.5), isNotNull);
      expect(defs.validateClockBackgroundRefresh('abc'), isNotNull);
    });

    test('the rows sit together on the Clock page, and the photo stays a '
        'device pick for the fleet', () {
      final photo = defs.screensaverClockBackground;
      final refresh = defs.screensaverClockBackgroundRefresh;
      expect(refresh.section, photo.section);
      expect(refresh.subpage, photo.subpage);
      expect(refresh.dependsOn, photo.dependsOn);
      expect(refresh.dependsOnValue, photo.dependsOnValue);
      expect(refresh.defaultValue, 0);
      expect(defs.fleetDefaultExcluded, contains(photo.key));
    });
  });

  group('ESPHome entity', () {
    test('a rejected write keeps and echoes the stored value', () async {
      SharedPreferences.setMockInitialValues({
        'ks.screensaver.clock_background': '/sdcard/old.jpg',
      });
      final bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final surface = EspEntitySurface(bus, commands, log, settings);
      final pushed = <(String, Object?)>[];
      surface.attach(
        (objectId, value) async => pushed.add((objectId, value)),
        (objectId, jpeg) async {},
      );
      addTearDown(surface.detach);
      pushed.clear();
      await surface.handleCommand('clock_background', 'a' * 300);
      expect(settings.get(defs.screensaverClockBackground), '/sdcard/old.jpg');
      expect(pushed.last, ('clock_background', '/sdcard/old.jpg'));
      await surface.handleCommand(
        'clock_background',
        ' https://ha.local/local/bg.jpg ',
      );
      expect(
        settings.get(defs.screensaverClockBackground),
        'https://ha.local/local/bg.jpg',
      );
      expect(pushed.last, (
        'clock_background',
        'https://ha.local/local/bg.jpg',
      ));
    });
  });

  group('clock face', () {
    late HttpServer server;
    var hits = 0;
    var status = 200;

    setUp(() async {
      hits = 0;
      status = 200;
      // flutter_test answers every HttpClient with a 400 unless the
      // override is lifted; the fetch under test is the real client.
      HttpOverrides.global = null;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        hits++;
        final body = status == 200 ? png : const <int>[];
        request.response
          ..statusCode = status
          ..headers.contentType = ContentType('image', 'png')
          ..contentLength = body.length
          ..add(body)
          ..close();
      });
    });

    tearDown(() => server.close(force: true));

    String url() => 'http://127.0.0.1:${server.port}/bg.png';

    Future<AppContainer> pumpClock(
      WidgetTester tester,
      Map<String, Object> prefs,
    ) async {
      SharedPreferences.setMockInitialValues({
        'ks.ha.url': 'http://ha.local:8123',
        'ks.ha.token': 'token',
        'ks.screensaver.mode': 'clock',
        'ks.screensaver.clock_show_date': false,
        ...prefs,
      });
      final container = AppContainer();
      await container.settings.init();
      container.screensaver.activeView.value = 'clock';
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(children: [ScreensaverOverlay(container: container)]),
        ),
      );
      return container;
    }

    Future<ImageProvider?> loadPhoto(WidgetTester tester) async {
      ImageProvider? provider;
      await tester.runAsync(() async {
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          final images = find.byType(Image).evaluate();
          if (images.isNotEmpty) {
            provider = (images.first.widget as Image).image;
            return;
          }
        }
      });
      expect(find.byType(Image), findsWidgets);
      return provider;
    }

    /// Wait until the shown provider is no longer [before].
    Future<ImageProvider?> reloaded(
      WidgetTester tester,
      ImageProvider? before,
    ) async {
      ImageProvider? provider;
      await tester.runAsync(() async {
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
          final images = find.byType(Image).evaluate();
          if (images.isEmpty) continue;
          final now = (images.first.widget as Image).image;
          if (!identical(now, before)) {
            provider = now;
            return;
          }
        }
      });
      expect(provider, isNotNull);
      return provider;
    }

    testWidgets('a URL background is fetched by the app and shown', (
      tester,
    ) async {
      await pumpClock(tester, {'ks.screensaver.clock_background': url()});
      await loadPhoto(tester);
      expect(hits, 1);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('rewriting the same URL fetches it again', (tester) async {
      final container = await pumpClock(tester, {
        'ks.screensaver.clock_background': url(),
      });
      final first = await loadPhoto(tester);
      await container.settings.set(defs.screensaverClockBackground, url());
      await reloaded(tester, first);
      expect(hits, 2);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a failed fetch keeps the photo that is up', (tester) async {
      final container = await pumpClock(tester, {
        'ks.screensaver.clock_background': url(),
      });
      await loadPhoto(tester);
      status = 500;
      await container.settings.set(defs.screensaverClockBackground, url());
      // The rebuild starts the fetch, inside runAsync so the socket can
      // move; the wait lets it fail.
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && hits < 2; i++) {
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });
      expect(hits, 2);
      expect(find.byType(Image), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a file replaced under its old name is picked up', (
      tester,
    ) async {
      final dir = Directory.systemTemp.createTempSync('clock-bg-test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/bg.png')..writeAsBytesSync(png);
      file.setLastModifiedSync(DateTime(2026, 1, 1));
      await pumpClock(tester, {'ks.screensaver.clock_background': file.path});
      final first = await loadPhoto(tester);
      file.writeAsBytesSync(png);
      file.setLastModifiedSync(DateTime(2026, 1, 2));
      // Nothing marks the face dirty for a file change; the minute tick
      // is the rebuild that notices, the same as on the device.
      await tester.pump(const Duration(seconds: 61));
      await reloaded(tester, first);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
