import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/screensaver/photo_metadata.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #1290: the description written for a photo in Immich, shown as a
/// caption centered at the bottom of the screen with the At a Glance row
/// above it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SettingsManager> build(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final log = Logger();
    final settings = SettingsManager(EventBus(), CommandRegistry(log), log);
    await settings.init();
    return settings;
  }

  group('caption switch', () {
    test('off out of the box, so nothing moves on update', () async {
      final settings = await build({'ks.screensaver.immich_metadata': true});
      expect(photoCaptionOn(settings, 'immich'), isFalse);
    });

    test('follows the metadata master switch', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata_description': true,
      });
      expect(photoCaptionOn(settings, 'immich'), isFalse);
      expect(immichMetadataShown(settings), isFalse);
    });

    test('a caption alone claims no corner for the panel', () async {
      final settings = await build({
        'ks.screensaver.immich_metadata': true,
        'ks.screensaver.immich_metadata_description': true,
        'ks.screensaver.immich_metadata_album': false,
        'ks.screensaver.immich_metadata_date': false,
        'ks.screensaver.immich_metadata_camera': false,
        'ks.screensaver.immich_metadata_location': false,
      });
      expect(photoCaptionOn(settings, 'immich'), isTrue);
      expect(immichMetadataShown(settings), isTrue);
      expect(immichMetadataVisible(settings), isFalse);
      expect(immichMetadataCorner(settings), isNull);
    });

    test('the EXIF modes have no caption', () async {
      final settings = await build({
        'ks.screensaver.media_metadata': true,
        'ks.screensaver.local_metadata': true,
        'ks.screensaver.url_metadata': true,
      });
      for (final mode in ['media', 'local', 'url']) {
        expect(photoCaptionOn(settings, mode), isFalse, reason: mode);
      }
    });
  });

  group('captionPlacement', () {
    ({double bottom, double maxWidth}) place(double width, {Size? panel}) =>
        captionPlacement(width: width, inset: 36, scale: 1, panel: panel);

    test('without a bottom panel it keeps a reading width', () {
      expect(place(1280), (bottom: 36, maxWidth: 640));
      expect(place(800), (bottom: 36, maxWidth: 480));
      // A phone keeps a usable line rather than 60% of a narrow screen.
      expect(place(400), (bottom: 36, maxWidth: 344));
    });

    test('it wraps between the panel and its mirror image', () {
      // 1280 less two 300-wide panels leaves 680, wider than 640.
      expect(place(1280, panel: const Size(300, 160)), (
        bottom: 36,
        maxWidth: 640,
      ));
      // 960 less two 300-wide panels leaves 360.
      expect(place(960, panel: const Size(300, 160)), (
        bottom: 36,
        maxWidth: 360,
      ));
    });

    test('it rises above a panel that leaves no room', () {
      // 800 less two 300-wide panels leaves 200, too little to read.
      expect(place(800, panel: const Size(300, 160)), (
        bottom: 160,
        maxWidth: 480,
      ));
    });
  });

  group('Immich details', () {
    setUpAll(() => HttpOverrides.global = null);
    late HttpServer server;
    late AppContainer c;
    late Object? description;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) async {
        r.response.write(
          jsonEncode({
            'exifInfo': {'model': 'Camera', 'description': description},
          }),
        );
        await r.response.close();
      });
      SharedPreferences.setMockInitialValues({
        'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
        'ks.screensaver.immich_api_key': 'key',
        'ks.screensaver.immich_cache': false,
        'ks.screensaver.immich_metadata_album': false,
      });
      c = AppContainer();
      await c.settings.init();
      await c.immich.init();
    });
    tearDown(() async {
      await c.immich.dispose();
      await server.close(force: true);
    });

    test('the description comes trimmed from the same response', () async {
      description = '  Grandma at the lake, summer 1998 \n';
      final details = await c.immich.assetDetails(
        const ImmichAsset(id: 'one', isVideo: false),
      );
      expect(details['description'], 'Grandma at the lake, summer 1998');
      expect(details['camera'], 'Camera');
    });

    test('a blank or missing description leaves no caption', () async {
      description = '   ';
      final blank = await c.immich.assetDetails(
        const ImmichAsset(id: 'blank', isVideo: false),
      );
      expect(blank.containsKey('description'), isFalse);
      description = null;
      final missing = await c.immich.assetDetails(
        const ImmichAsset(id: 'missing', isVideo: false),
      );
      expect(missing.containsKey('description'), isFalse);
    });

    test('the caption footprint only grows', () {
      final screensaver = c.screensaver;
      expect(screensaver.captionFootprint.value, 0);
      screensaver.reportCaptionFootprint(90);
      screensaver.reportCaptionFootprint(60);
      expect(screensaver.captionFootprint.value, 90);
      screensaver.reportCaptionFootprint(120);
      expect(screensaver.captionFootprint.value, 120);
    });
  });
}
