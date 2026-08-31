import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:shared_preferences/shared_preferences.dart';

/// Second-level settings pages: the `subpage` axis both UIs render from.
/// A page that grew too long hands a group to a page of its own, reached by
/// one entry row; the settings themselves are untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsManager settings;

  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    final bus = EventBus();
    final log = Logger();
    settings = SettingsManager(bus, CommandRegistry(log), log);
    await settings.init();
  }

  test('the Home Assistant User Interface page holds both groups', () {
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'User Interface') d,
    ];
    // Both former top-level groups, and nothing else.
    expect(moved.map((d) => d.section).toSet(), {'User Interface', 'Haptics'});
    expect(moved.every((d) => d.category == 'Home Assistant'), isTrue);
    // The sections survive the move: they are the cards *inside* the page.
    expect(
      moved.map((d) => d.key),
      containsAll([
        defs.haKioskMode.key,
        defs.haDashboardCarousel.key,
        defs.haHaptics.key,
        defs.haTapSound.key,
      ]),
    );
  });

  test('the Home Assistant page keeps only its connection and dashboard', () {
    // What is left at the top level after the move: the connection rows the
    // rest of the page waits behind. Everything else opens a page of its own.
    final top = [
      for (final d in defs.allSettings)
        if (d.category == 'Home Assistant' && !d.hidden && d.subpage == null)
          d.key,
    ];
    expect(top, [defs.haUrl.key, defs.haToken.key, defs.haAutoLogin.key]);
  });

  test('the entry rows come out in page order', () {
    // Both UIs put each entry row where that group's first setting sat, so
    // allSettings order *is* the order of the rows on the page.
    final order = <String>[];
    for (final d in defs.allSettings) {
      if (d.category != 'Home Assistant' || d.subpage == null) continue;
      if (!order.contains(d.subpage)) order.add(d.subpage!);
    }
    expect(order, [
      'User Interface',
      'Theme',
      'Dashboard View Rotation',
      'Return to home dashboard view',
      'Hold mode',
      'Optimizations',
    ]);
  });

  test('every subpage a setting declares has an entry-row hint', () {
    for (final def in defs.allSettings) {
      if (def.subpage == null) continue;
      expect(
        defs.subpageHints[def.subpage],
        isNotNull,
        reason: '${def.subpage} (from ${def.key}) has no hint',
      );
    }
  });

  test('a subpage never splits a section across two pages', () {
    // A section straddling the boundary would render as two cards with one
    // heading, and syncGatedRows in the remote UI could not place a row.
    final pageOf = <String, Set<String?>>{};
    for (final def in defs.allSettings) {
      if (def.section == null) continue;
      (pageOf['${def.category}/${def.section}'] ??= {}).add(def.subpage);
    }
    for (final entry in pageOf.entries) {
      expect(entry.value, hasLength(1), reason: entry.key);
    }
  });

  test('a gated row is on its gate\'s page, or on one below it', () {
    // Where a gate and its dependants share a page, both UIs bring the rows
    // in and out in place. Where they do not, the remote's syncGatedRows
    // refuses (its sameCard compares the subpage) and the caller re-renders
    // instead, which is correct but heavier — so the only cross-page shape
    // allowed is the deliberate one: a switch on the category page opening a
    // page of its own, as the screensaver mode does for its six modes.
    // A hidden gate is exempt either way: it draws no row, so nothing ever
    // flips it from a page.
    final byKey = {for (final d in defs.allSettings) d.key: d};
    for (final def in defs.allSettings) {
      final gate = def.dependsOn == null ? null : byKey[def.dependsOn];
      if (gate == null || gate.hidden || gate.subpage == null) continue;
      expect(def.subpage, gate.subpage, reason: '${def.key} vs ${gate.key}');
    }
  });

  test('the screensaver mode pages exist only while that mode is picked', () {
    // Every setting on the mode pages gates on the mode select, so the row
    // that opens the page comes and goes with the mode — the group's own
    // behaviour before it moved. The other modes keep their group inline.
    // Home Assistant Media's playlist rows gate on the hidden folder flag,
    // which itself gates on the mode; the walk below follows that chain.
    for (final page in [
      'Clock screensaver',
      'Home Assistant Media screensaver',
      'Local Media screensaver',
      'Photo Gallery screensaver',
      'Immich Media screensaver',
      'Camera Streams screensaver',
    ]) {
      final rows = [
        for (final d in defs.allSettings)
          if (d.subpage == page) d,
      ];
      expect(rows, isNotEmpty, reason: page);
      // Directly or through one of its own rows, each one hangs off the mode.
      final byKey = {for (final d in defs.allSettings) d.key: d};
      for (final row in rows) {
        var d = row;
        while (d.dependsOn != null && d.subpage == page) {
          d = byKey[d.dependsOn!]!;
        }
        expect(d.key, defs.screensaverMode.key, reason: row.key);
      }
    }
  });

  test('the Voice Satellite Wake Word page holds the detection settings', () {
    // The rest of that page (engine, wake words, sensitivity) is live rows
    // from the integration, so these two are all the schema knows about it.
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'Wake Word') d.key,
    ];
    expect(moved, [
      defs.wakeWordPreferFp32.key,
      defs.wakeWordResumeTimeoutSeconds.key,
    ]);
    // Keep listening in the background stays in General on the page above.
    expect(defs.wakeWordBackground.subpage, isNull);
  });

  test('the Screen & Audio capture tuning is a page of its own', () {
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'Microphone settings') d.key,
    ];
    expect(moved, [
      defs.micAudioSource.key,
      defs.micAgc.key,
      defs.micGainDb.key,
      // Hidden and hand-built (its options run to the mic's channel count),
      // but it belongs to that page too.
      defs.micChannel.key,
    ]);
    // The mixer and the device pickers stay on the page above.
    expect(defs.mediaVolume.subpage, isNull);
    expect(defs.audioMicDevice.subpage, isNull);
  });

  test('the ESPHome Notifications page holds appearance and sound', () {
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'Notifications') d.key,
    ];
    expect(moved, [
      defs.notificationsTransparency.key,
      defs.notificationsBlur.key,
      defs.notificationsChimeFile.key,
      defs.notificationsVolume.key,
    ]);
    expect(defs.notificationsTransparency.section, 'Appearance');
    expect(defs.notificationsBlur.section, 'Appearance');
    expect(defs.notificationsChimeFile.section, 'Sound');
    expect(defs.notificationsVolume.section, 'Sound');
    // Its entry row sits above the Bluetooth Proxy one: entry order
    // follows allSettings.
    final keys = defs.allSettings.map((d) => d.key).toList();
    expect(
      keys.indexOf(defs.notificationsChimeFile.key),
      lessThan(keys.indexOf(defs.btproxyEnabled.key)),
    );
    expect(defs.subpageHints, contains('Notifications'));
  });

  test('the Person Detection page holds its two switches, under Proximity', () {
    final page = [
      for (final d in defs.allSettings)
        if (d.subpage == 'Person Detection') d.key,
    ];
    expect(page, [
      defs.screensaverDismissOnPerson.key,
      defs.screensaverPostponeOnPerson.key,
    ]);
    expect(defs.screensaverDismissOnPerson.section, 'Person Detection');
    expect(defs.screensaverDismissOnPerson.dependsOn, isNull);
    expect(
      defs.screensaverPostponeOnPerson.dependsOn,
      defs.screensaverDismissOnPerson.key,
    );
    final keys = defs.allSettings.map((d) => d.key).toList();
    expect(
      keys.indexOf(defs.screensaverDismissOnPerson.key),
      greaterThan(keys.indexOf(defs.screensaverPostponeOnProximity.key)),
    );
    expect(defs.subpageHints, contains('Person Detection'));
  });

  test('a device-hidden definition is hidden in describe() too', () async {
    await build();
    defs.deviceHiddenKeys.add(defs.screensaverDismissOnPerson.key);
    try {
      final row = settings.describe().firstWhere(
        (d) => d['key'] == defs.screensaverDismissOnPerson.key,
      );
      expect(row['hidden'], isTrue);
    } finally {
      defs.deviceHiddenKeys.clear();
    }
    final row = settings.describe().firstWhere(
      (d) => d['key'] == defs.screensaverDismissOnPerson.key,
    );
    expect(row['hidden'], isNull);
  });

  test('the ESPHome GPS Sensor page holds the switch and its interval', () {
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'GPS Sensor') d.key,
    ];
    expect(moved, [defs.locationEnabled.key, defs.locationInterval.key]);
    expect(defs.locationInterval.section, 'GPS Sensor');
    // The switch rides the entities switch on the page above (the
    // screensaver-mode shape: the whole page comes and goes with it), and
    // the interval rides the switch on its own page.
    expect(defs.locationEnabled.dependsOn, defs.esphomeEntities.key);
    expect(defs.esphomeEntities.subpage, isNull);
    expect(defs.locationInterval.dependsOn, defs.locationEnabled.key);
    // Under the Bluetooth Proxy page, above Advanced settings.
    final keys = defs.allSettings.map((d) => d.key).toList();
    expect(
      keys.indexOf(defs.locationEnabled.key),
      greaterThan(keys.indexOf(defs.btproxyNearbySort.key)),
    );
    expect(
      keys.indexOf(defs.locationEnabled.key),
      lessThan(keys.indexOf(defs.esphomeRealMac.key)),
    );
    expect(defs.subpageHints, contains('GPS Sensor'));
  });

  test('the ESPHome Bluetooth half is one page', () {
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'Bluetooth Proxy') d.key,
    ];
    expect(moved, [
      defs.btproxyEnabled.key,
      defs.btproxyScanDuty.key,
      defs.btproxyConnections.key,
      defs.btproxyMinConnectRssi.key,
      defs.btproxyMacLookup.key,
      defs.btproxyNearbySort.key,
    ]);
    // Both groups: the proxy's own settings and the nearby list's, which
    // keeps its heading inside the page.
    expect(defs.btproxyNearbySort.section, 'Nearby devices');
    // The entity server's own settings stay on the page above — the API
    // port and key are ESPHome's, not the proxy's.
    expect(defs.btproxyPort.subpage, isNull);
    expect(defs.esphomeEntities.subpage, isNull);
  });

  test('the Kiosk allowed actions are one page', () {
    final moved = [
      for (final d in defs.allSettings)
        if (d.subpage == 'Allowed Actions') d.key,
    ];
    // The menu's own switch leads, then the action it gates, one per row.
    expect(moved.first, defs.kioskAllowDrawer.key);
    expect(moved, hasLength(9));
    // The protections stay on the page above: they are what kiosk mode is.
    expect(defs.kioskExitGesture.subpage, isNull);
    expect(defs.kioskDisableStatusBar.subpage, isNull);
  });

  test('every second-level page has a hint, defless ones included', () {
    // Voice Satellite's two pages carry no settings of their own, so their
    // names only exist here and in the two UIs that place them.
    expect(defs.subpageHints.containsKey('Wake Word'), isTrue);
    expect(defs.subpageHints.containsKey('Appearance'), isTrue);
  });

  test('describe() names each setting\'s page for the remote UI', () async {
    await build();
    final described = settings.describe();
    final haptics = described.firstWhere((s) => s['key'] == 'ha.haptics');
    expect(haptics['subpage'], 'User Interface');
    // Sections are unchanged: the page groups its cards the same way.
    expect(haptics['section'], 'Haptics');
    // A setting that stayed on the category page says nothing about pages.
    final url = described.firstWhere((s) => s['key'] == 'ha.url');
    expect(url.containsKey('subpage'), isFalse);
    // The hints ride beside the definitions rather than on each one: a page
    // with no settings of its own still needs a label for its entry row.
    expect(described.every((s) => !s.containsKey('subpageHint')), isTrue);
  });
}
