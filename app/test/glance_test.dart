import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/glance/glance_manager.dart';
import 'package:kiosk_satellite/managers/home_assistant/home_assistant_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/glance_row.dart';
import 'package:kiosk_satellite/ui/mdi_icon.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records every subscription attempt instead of opening a socket. Returning
/// null is the manager's "unreachable" path, which only schedules a retry —
/// enough to observe whether the gate let the attempt through at all.
class _RecordingHa extends HomeAssistantManager {
  _RecordingHa(super.bus, super.commands, super.log, super.settings);

  final attempts = <List<String>>[];

  @override
  Future<GlanceSubscription?> subscribeEntities(
    List<String> entityIds,
    void Function(String entityId, Map<String, Object?> state) onState, {
    void Function(Map<String, int> precisions)? onPrecision,
  }) async {
    attempts.add(List.of(entityIds));
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GlanceEntity entity(
    String id, {
    String? state,
    String? icon,
    String? deviceClass,
    String? unit,
    int? precision,
  }) => GlanceEntity(
    entityId: id,
    name: 'Test',
    state: state,
    icon: icon,
    deviceClass: deviceClass,
    unit: unit,
    precision: precision,
  );

  group('state text', () {
    test('reads as a person would say it, not as a slug', () {
      expect(glanceStateText(entity('cover.g', state: 'open')), 'Open');
      expect(glanceStateText(entity('lock.f', state: 'locked')), 'Locked');
      expect(
        glanceStateText(entity('alarm_control_panel.a', state: 'armed_away')),
        'Armed Away',
      );
    });

    test('a measurement carries its unit', () {
      expect(
        glanceStateText(entity('sensor.t', state: '21.5', unit: '°C')),
        '21.5 °C',
      );
    });

    test('display precision rounds the way the entity card would (#74)', () {
      expect(
        glanceStateText(
          entity('sensor.t', state: '69.44', unit: '°F', precision: 0),
        ),
        '69 °F',
      );
      expect(
        glanceStateText(
          entity('sensor.t', state: '69.44', unit: '°F', precision: 1),
        ),
        '69.4 °F',
      );
      // Padded, not just truncated: Home Assistant shows 69.0 at
      // precision 1, so the row does too.
      expect(
        glanceStateText(entity('sensor.t', state: '69', precision: 1)),
        '69.0',
      );
    });

    test('a fetched precision survives later state updates', () {
      final before = entity(
        'sensor.t',
        state: '69.44',
        unit: '°F',
        precision: 0,
      );
      final after = before.merge(state: '70.12');
      expect(glanceStateText(after), '70 °F');
    });

    test('precision leaves everything non-numeric alone', () {
      // No precision known: the raw state, exactly as before.
      expect(
        glanceStateText(entity('sensor.t', state: '69.44', unit: '°F')),
        '69.44 °F',
      );
      // A precision on a non-numeric state changes nothing.
      expect(
        glanceStateText(entity('cover.g', state: 'open', precision: 1)),
        'Open',
      );
      expect(
        glanceStateText(entity('sensor.t', state: 'unavailable', precision: 0)),
        'Unavailable',
      );
    });

    test('the states nobody wants to read raw are spelled out', () {
      expect(
        glanceStateText(entity('x.y', state: 'unavailable')),
        'Unavailable',
      );
      expect(glanceStateText(entity('x.y', state: 'unknown')), 'Unknown');
      // Nothing has reported yet: a placeholder, not an empty row.
      expect(glanceStateText(entity('x.y')), '…');
    });
  });

  group('attribute display (#132)', () {
    GlanceEntity weather({String? value, String? state}) => GlanceEntity(
      entityId: 'weather.home',
      name: 'Weather',
      attribute: 'temperature',
      attributeValue: value,
      state: state ?? 'sunny',
    );

    test('shows the attribute value instead of the state', () {
      expect(glanceStateText(weather(value: '92')), '92');
    });

    test('slug-like attribute values prettify like states', () {
      expect(glanceStateText(weather(value: 'partly_cloudy')), 'Partly Cloudy');
    });

    test('waits with a placeholder until the value arrives', () {
      expect(glanceStateText(weather()), '…');
    });

    test('an unavailable entity reads unavailable, not a stale value', () {
      expect(
        glanceStateText(weather(value: '92', state: 'unavailable')),
        'Unavailable',
      );
    });

    test('state unit and precision never leak onto an attribute', () {
      final e = GlanceEntity(
        entityId: 'weather.home',
        name: 'Weather',
        attribute: 'humidity',
        attributeValue: '47.25',
        state: '21.5',
        unit: '°C',
        precision: 0,
      );
      expect(glanceStateText(e), '47.25');
    });

    test('attribute values flatten to display text', () {
      expect(glanceAttributeText(92.0), '92');
      expect(glanceAttributeText(92.06), '92.06');
      expect(glanceAttributeText(15), '15');
      expect(glanceAttributeText('sunny'), 'sunny');
      expect(glanceAttributeText(null), '');
    });

    test('the chosen attribute survives a storage round trip', () {
      final stored = weather().toJson();
      expect(stored['attribute'], 'temperature');
      final loaded = GlanceEntity.fromJson(stored);
      expect(loaded.attribute, 'temperature');
      // No attribute chosen: the key stays out of storage entirely.
      final plain = const GlanceEntity(entityId: 'x.y', name: 'X').toJson();
      expect(plain.containsKey('attribute'), isFalse);
      expect(GlanceEntity.fromJson(plain).attribute, isNull);
    });

    test('merge keeps the value across unrelated updates', () {
      final before = weather(value: '92');
      final after = before.merge(state: 'cloudy');
      expect(after.attributeValue, '92');
      expect(after.attribute, 'temperature');
    });
  });

  group('custom names (#206)', () {
    test('a custom name wins over the Home Assistant name', () {
      const renamed = GlanceEntity(
        entityId: 'cover.g',
        name: 'Garage Door Left Side',
        customName: 'Garage',
      );
      expect(renamed.displayName, 'Garage');
      expect(
        const GlanceEntity(
          entityId: 'cover.g',
          name: 'Garage Door',
        ).displayName,
        'Garage Door',
      );
    });

    test('a friendly_name update does not overwrite a custom name', () {
      const renamed = GlanceEntity(
        entityId: 'cover.g',
        name: 'Garage Door',
        customName: 'Garage',
      );
      final after = renamed.merge(name: 'Garage Door Left Side', state: 'open');
      expect(after.displayName, 'Garage');
      // The live name is still tracked, so clearing the custom name later
      // falls back to the current one, not the one saved at pick time.
      expect(after.name, 'Garage Door Left Side');
    });

    test('the custom name survives a storage round trip', () {
      const renamed = GlanceEntity(
        entityId: 'cover.g',
        name: 'Garage Door',
        customName: 'Garage',
      );
      final loaded = GlanceEntity.fromJson(renamed.toJson());
      expect(loaded.customName, 'Garage');
      expect(loaded.displayName, 'Garage');
      // No custom name: the key stays out of storage entirely.
      final plain = const GlanceEntity(entityId: 'x.y', name: 'X').toJson();
      expect(plain.containsKey('custom_name'), isFalse);
      expect(GlanceEntity.fromJson(plain).customName, isNull);
    });
  });

  group('icons', () {
    setUpAll(() {
      // Same file-backed read the icon tests use; the asset channel
      // cannot be awaited outside a pumping widget test.
      MdiIcons.readShard = (key) => File(key).readAsString();
    });

    testWidgets('an icon set in Home Assistant is drawn, not approximated', (
      tester,
    ) async {
      // Reading the icon is real I/O, which a pumping test's clock does
      // not drive; resolve it first, as a long-lived row would have.
      await tester.runAsync(() => MdiIcons.path('mdi:garage-open'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlanceIcon(
              entity: entity('light.x', icon: 'mdi:garage-open', state: 'on'),
              size: 34,
              color: Colors.white,
            ),
          ),
        ),
      );
      await tester.pump();
      // The real icon, not the Material lookalike the table used to pick.
      expect(find.byIcon(Icons.lightbulb), findsNothing);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('an unknown name keeps the domain default', (tester) async {
      await tester.runAsync(() => MdiIcons.path('mdi:not-a-real-icon'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlanceIcon(
              entity: entity(
                'lock.x',
                icon: 'mdi:not-a-real-icon',
                state: 'locked',
              ),
              size: 34,
              color: Colors.white,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    test('state picks the icon apart, so open and shut differ', () {
      expect(
        glanceIcon(entity('cover.x', deviceClass: 'garage', state: 'open')),
        Icons.garage,
      );
      expect(
        glanceIcon(entity('cover.x', deviceClass: 'garage', state: 'closed')),
        Icons.garage,
      );
      expect(glanceIcon(entity('lock.x', state: 'unlocked')), Icons.lock_open);
      expect(glanceIcon(entity('lock.x', state: 'locked')), Icons.lock);
    });

    test('an unmapped domain still gets something', () {
      expect(glanceIcon(entity('counter.x', state: '3')), Icons.sensors);
    });
  });

  test('the Now Playing setting registers and gates on the master toggle', () {
    expect(defs.allSettings, contains(defs.screensaverGlanceNowPlaying));
    expect(
      defs.screensaverGlanceNowPlaying.dependsOn,
      defs.screensaverGlanceEnabled.key,
    );
  });

  test('the style settings register, off by default, gated the same', () {
    for (final def in [
      defs.screensaverGlanceTextOnly,
      defs.screensaverGlanceBwIcons,
      defs.screensaverGlanceHideNames,
    ]) {
      expect(defs.allSettings, contains(def));
      expect(def.defaultValue, isFalse);
      expect(def.dependsOn, defs.screensaverGlanceEnabled.key);
    }
  });

  test('the appearance rows sit in their own group at the subpage end', () {
    final glancePage = defs.allSettings
        .where((d) => d.subpage == 'At a Glance')
        .toList();
    // The behavior rows lead under the subpage's own heading; the
    // Appearance group closes the page.
    expect(
      [for (final d in glancePage) d.section],
      [
        'At a Glance',
        'At a Glance',
        'At a Glance',
        ...List.filled(4, 'Appearance'),
      ],
    );
    expect(glancePage.last.section, 'Appearance');
  });

  test('the scaling slider registers with the Widget scaling range', () {
    expect(defs.allSettings, contains(defs.screensaverGlanceScale));
    expect(defs.screensaverGlanceScale.defaultValue, 100);
    expect(defs.screensaverGlanceScale.min, defs.screensaverWidgetScale.min);
    expect(defs.screensaverGlanceScale.max, defs.screensaverWidgetScale.max);
    expect(
      defs.screensaverGlanceScale.dependsOn,
      defs.screensaverGlanceEnabled.key,
    );
  });

  group('Now Playing subscription gating (#209)', () {
    late EventBus bus;
    late GlanceManager glance;
    late _RecordingHa ha;

    Future<void> build(Map<String, Object> initial) async {
      SharedPreferences.setMockInitialValues({
        'ks.screensaver.glance_enabled': true,
        'ks.screensaver.glance_entities':
            '[{"entity_id":"sensor.t","name":"T"}]',
        ...initial,
      });
      bus = EventBus();
      final log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      ha = _RecordingHa(bus, commands, log, settings);
      glance = GlanceManager(bus, commands, log, settings, ha);
      await glance.init();
    }

    tearDown(() async {
      await glance.dispose();
      await bus.dispose();
    });

    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    test(
      'a non-row mode subscribes only while Now Playing shows the row',
      () async {
        await build({
          'ks.screensaver.mode': 'camera',
          'ks.sendspin.fullscreen': true,
          'ks.screensaver.glance_now_playing': true,
        });
        bus.publish(const ScreensaverStateChanged(active: true));
        await settle();
        expect(ha.attempts, isEmpty);
        bus.publish(const SendspinNowPlayingChanged(active: true));
        await settle();
        expect(ha.attempts.length, 1);
        expect(ha.attempts.single, ['sensor.t']);
      },
    );

    test('without the opt-in, playback changes nothing', () async {
      await build({
        'ks.screensaver.mode': 'camera',
        'ks.sendspin.fullscreen': true,
      });
      bus.publish(const ScreensaverStateChanged(active: true));
      bus.publish(const SendspinNowPlayingChanged(active: true));
      await settle();
      expect(ha.attempts, isEmpty);
    });

    test('a photo mode holds a subscription now: the row rides it', () async {
      await build({'ks.screensaver.mode': 'immich'});
      bus.publish(const ScreensaverStateChanged(active: true));
      await settle();
      expect(ha.attempts.length, 1);
      expect(ha.attempts.single, ['sensor.t']);
    });

    test('the camera grid never subscribes, like the corner widgets', () async {
      await build({'ks.screensaver.mode': 'camera'});
      bus.publish(const ScreensaverStateChanged(active: true));
      await settle();
      expect(ha.attempts, isEmpty);
    });

    test('Black with Hide all extras still stays dark (#151)', () async {
      await build({
        'ks.screensaver.mode': 'black',
        'ks.screensaver.black_hide_extras': true,
      });
      bus.publish(const ScreensaverStateChanged(active: true));
      await settle();
      expect(ha.attempts, isEmpty);
    });

    test(
      'a row mode keeps its one subscription across playback changes',
      () async {
        await build({
          'ks.screensaver.mode': 'clock',
          'ks.sendspin.fullscreen': true,
          'ks.screensaver.glance_now_playing': true,
        });
        bus.publish(const ScreensaverStateChanged(active: true));
        await settle();
        expect(ha.attempts.length, 1);
        bus.publish(const SendspinNowPlayingChanged(active: true));
        await settle();
        expect(ha.attempts.length, 1);
      },
    );
  });

  group('row styles', () {
    late AppContainer container;

    Future<void> pump(
      WidgetTester tester, {
      Map<String, Object> settings = const {},
      int count = 4,
      bool narrow = false,
      Size size = const Size(1280, 800),
      List<GlanceEntity>? entities,
    }) async {
      SharedPreferences.setMockInitialValues(settings);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      container = AppContainer();
      await container.settings.init();
      container.glance.entities.value =
          entities ??
          [
            for (var i = 0; i < count; i++)
              GlanceEntity(
                entityId: 'sensor.e$i',
                name: 'Entity $i',
                state: '$i',
              ),
          ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlanceRow(container: container, narrow: narrow),
          ),
        ),
      );
    }

    // The card backdrop, found by its one fixed color: the pill is what
    // separates the styles, so its presence is the assertion. A
    // StadiumBorder on purpose, never a large-radius BoxDecoration: an
    // over-sized RRect radius froze Impeller's raster thread on resize.
    Finder cardBoxes() => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is ShapeDecoration &&
          (w.decoration as ShapeDecoration).color == const Color(0xB31C1C1E) &&
          (w.decoration as ShapeDecoration).shape is StadiumBorder,
    );

    testWidgets('cards are the default: every entity gets a bordered pill', (
      tester,
    ) async {
      await pump(tester);
      expect(cardBoxes(), findsNWidgets(4));
      expect(find.text('Entity 0'), findsOneWidget);
      // The hairline outline the reference chips carry.
      final pill = tester.widget<Container>(cardBoxes().first);
      final shape = (pill.decoration as ShapeDecoration).shape as StadiumBorder;
      expect(shape.side.style, BorderStyle.solid);
    });

    testWidgets('Floating text style opts back into the floating text', (
      tester,
    ) async {
      await pump(tester, settings: {'ks.screensaver.glance_text_only': true});
      expect(cardBoxes(), findsNothing);
      expect(find.text('Entity 0'), findsOneWidget);
    });

    testWidgets('narrow wraps a landscape row the way portrait does', (
      tester,
    ) async {
      await pump(tester);
      double top(int i) => tester.getTopLeft(find.text('Entity $i')).dy;
      // Spread: one line, every name at the same height.
      expect({for (var i = 0; i < 4; i++) top(i)}.length, 1);
      await pump(tester, narrow: true);
      // Narrowed: the width cap breaks the chips onto two lines.
      expect({for (var i = 0; i < 4; i++) top(i)}.length, 2);
    });

    testWidgets('the Row scaling slider sizes the whole row', (tester) async {
      await pump(tester);
      final base = tester.getSize(find.byType(GlanceRow)).height;
      await pump(tester, settings: {'ks.screensaver.glance_scale': 150});
      expect(tester.getSize(find.byType(GlanceRow)).height, greaterThan(base));
    });

    testWidgets('the chip wrap hugs its height, so a bottom pin stays put', (
      tester,
    ) async {
      await pump(tester);
      // Handed the whole 800px body, the row must still size to its
      // chips: an expanding centre floated the bottom-pinned overlay's
      // row to the middle of the screen.
      expect(tester.getSize(find.byType(GlanceRow)).height, lessThan(120));
    });

    // The circle behind an icon, found by its exact color.
    Finder circles(Color color) => find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color == color,
    );

    const amber = Color(0xFFFFD54F);
    const neutral = Color(0x24FFFFFF);
    final lit = [
      const GlanceEntity(entityId: 'light.desk', name: 'Desk', state: 'on'),
      const GlanceEntity(entityId: 'sensor.t', name: 'Temp', state: '21'),
    ];

    testWidgets('an active entity lights its circle, a sensor stays grey', (
      tester,
    ) async {
      await pump(tester, entities: lit);
      expect(circles(amber), findsOneWidget);
      expect(circles(neutral), findsOneWidget);
    });

    testWidgets('a wrapped grid gives every chip one shared width', (
      tester,
    ) async {
      final mixed = [
        const GlanceEntity(entityId: 'sensor.a', name: 'A', state: '1'),
        const GlanceEntity(
          entityId: 'sensor.b',
          name: 'A Much Longer Name',
          state: '2',
        ),
        const GlanceEntity(entityId: 'sensor.c', name: 'Mid', state: '3'),
        const GlanceEntity(entityId: 'sensor.d', name: 'Name', state: '4'),
      ];
      await pump(tester, entities: mixed);
      double width(int i) => tester.getSize(cardBoxes().at(i)).width;
      // On one line the chips hug their text, the reference look.
      expect({for (var i = 0; i < 4; i++) width(i)}.length, greaterThan(1));
      await pump(tester, entities: mixed, narrow: true);
      // Wrapped, they all take the widest chip's width.
      expect({for (var i = 0; i < 4; i++) width(i)}.length, 1);
    });

    testWidgets('Hide names drops the name and grows the value', (
      tester,
    ) async {
      await pump(tester);
      double valueSize() =>
          tester.widget<Text>(find.text('0')).style!.fontSize!;
      final named = valueSize();
      final height = tester.getSize(cardBoxes().first).height;
      await pump(tester, settings: {'ks.screensaver.glance_hide_names': true});
      expect(find.text('Entity 0'), findsNothing);
      expect(find.text('0'), findsOneWidget);
      expect(cardBoxes(), findsNWidgets(4));
      // The value takes the room the name gave up: bigger type, and the
      // pill no shorter than it was with two lines.
      expect(valueSize(), greaterThan(named));
      expect(tester.getSize(cardBoxes().first).height, height);
      // The floating text style hides the name the same way.
      await pump(
        tester,
        settings: {
          'ks.screensaver.glance_hide_names': true,
          'ks.screensaver.glance_text_only': true,
        },
      );
      expect(find.text('Entity 0'), findsNothing);
      expect(find.text('0'), findsOneWidget);
      expect(valueSize(), greaterThan(named));
    });

    testWidgets('Monochromatic icons keeps every circle grey', (tester) async {
      await pump(
        tester,
        settings: {'ks.screensaver.glance_bw_icons': true},
        entities: lit,
      );
      expect(circles(amber), findsNothing);
      expect(circles(neutral), findsNWidgets(2));
    });
  });

  group('icon accents', () {
    test('color means active: idle and sensors stay neutral', () {
      Color? accent(String id, String state, {String? deviceClass}) =>
          glanceIconAccent(
            GlanceEntity(
              entityId: id,
              name: 'X',
              state: state,
              deviceClass: deviceClass,
            ),
          );
      expect(accent('light.x', 'on'), isNotNull);
      expect(accent('light.x', 'off'), isNull);
      expect(accent('sensor.x', '21.5'), isNull);
      expect(accent('lock.x', 'unlocked'), const Color(0xFFE57373));
      expect(accent('lock.x', 'locked'), const Color(0xFF81C784));
      expect(accent('cover.x', 'open'), isNotNull);
      expect(accent('cover.x', 'closed'), isNull);
      expect(
        accent('binary_sensor.x', 'on', deviceClass: 'moisture'),
        const Color(0xFFE57373),
      );
      expect(accent('binary_sensor.x', 'off', deviceClass: 'moisture'), isNull);
      expect(accent('media_player.x', 'playing'), isNotNull);
      expect(accent('media_player.x', 'paused'), isNull);
      // Nothing reported yet: no state, no color.
      expect(
        glanceIconAccent(const GlanceEntity(entityId: 'light.x', name: 'X')),
        isNull,
      );
    });
  });
}
