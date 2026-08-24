import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;

/// Pinch to zoom a single camera (issue #286). The gesture itself lives in
/// the camera view page, so what a Dart test can hold onto is the wiring:
/// the setting, the three places that carry it, and the two rules the page
/// applies it under.
void main() {
  final page = File('assets/camera-view/index.html').readAsStringSync();

  test('the setting is registered and on by default', () {
    expect(defs.cameraPinchZoom.defaultValue, isTrue);
    expect(defs.cameraPinchZoom.category, 'Cameras');
    expect(defs.allSettings, contains(defs.cameraPinchZoom));
  });

  test('the camera view overlay hands the setting to the page', () {
    final overlay = File('lib/ui/camera_view_overlay.dart').readAsStringSync();
    expect(overlay, contains("'pinchZoom': "));
    expect(overlay, contains('defs.cameraPinchZoom'));
    // The page defaults to zooming when the app says nothing, which keeps a
    // config written by an older build behaving like the new default.
    expect(page, contains('CFG.pinchZoom !== false'));
  });

  test('zooming is off for the screensaver grid', () {
    // The screensaver's cameras are scenery: any touch there wakes the
    // kiosk, so the page must not spend a two-finger gesture on zooming.
    expect(
      page,
      contains('CFG.pinchZoom !== false && CFG.interactive !== false'),
    );
  });

  test('only one camera filling the view can zoom', () {
    // zoomTile() is the single gate: the focused tile, or the sole camera
    // of a one-camera view, and null for every grid.
    final tile = RegExp(
      r'function zoomTile\(\) \{(.*?)\n\}',
      dotAll: true,
    ).firstMatch(page)?.group(1);
    expect(tile, isNotNull);
    expect(tile, contains('if (!PINCH_ZOOM) return null;'));
    expect(tile, contains('CFG.cameras.length === 1'));
    expect(tile, contains('focusId'));
  });

  test('the remote admin shows the row with the other playback settings', () {
    final remote = File('assets/remote-ui/static/cameras.js').readAsStringSync();
    final keys = RegExp(
      r'const playbackKeys = \[(.*?)\];',
      dotAll: true,
    ).firstMatch(remote)?.group(1);
    expect(keys, isNotNull);
    expect(keys, contains("'camera.pinch_zoom'"));
    // Right after the sound toggle, as on the device.
    expect(
      keys!.indexOf("'camera.pinch_zoom'"),
      greaterThan(keys.indexOf("'camera.single_audio'")),
    );
    expect(
      keys.indexOf("'camera.pinch_zoom'"),
      lessThan(keys.indexOf("'camera.auto_dismiss_seconds'")),
    );
  });
}
