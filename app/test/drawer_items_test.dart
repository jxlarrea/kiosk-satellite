import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/kiosk/drawer_items.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/entity_picker.dart';
import 'package:kiosk_satellite/ui/kiosk_drawer.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Drawer menu items (issue #1194): one list decides which rows the kiosk
// menu shows and in what order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('Rubik')
      ..addFont(rootBundle.load('assets/fonts/Rubik.ttf'));
    await font.load();
  });

  group('the list', () {
    test('empty is the defaults, in the default order', () {
      final rows = DrawerItems.decode('').arrange(drawerItemOrder);
      expect(rows, [
        for (final id in drawerItemOrder)
          if (!drawerItemsOffByDefault.contains(id)) id,
      ]);
    });

    test('the chosen order holds and hidden rows stay out', () {
      const items = DrawerItems(
        shown: ['apps', 'dashboard'],
        hidden: {'settings', 'clear_cache'},
      );
      final rows = items.arrange(drawerItemOrder);
      expect(rows.indexOf('apps'), lessThan(rows.indexOf('dashboard')));
      expect(rows, isNot(contains('settings')));
      expect(rows, isNot(contains('clear_cache')));
      // A row in neither list is new and takes its default place: right
      // after the closest row ahead of it by default.
      expect(rows.indexOf('ha_kiosk'), rows.indexOf('dashboard') + 1);
      // Off by default stays off until picked.
      expect(rows, isNot(contains('lockdown')));
    });

    test('forced rows come back at their default place', () {
      final items = DrawerItems(
        shown: const ['dashboard', 'apps'],
        hidden: {
          for (final id in drawerItemOrder)
            if (id != 'dashboard' && id != 'apps') id,
        },
      );
      expect(items.arrange(drawerItemOrder, forced: {'settings'}), [
        'dashboard',
        'settings',
        'apps',
      ]);
    });

    test('new plugin actions lead the menu in their own order', () {
      final first = drawerPluginItem('a', 'one');
      final second = drawerPluginItem('b', 'two');
      const items = DrawerItems(shown: ['dashboard']);
      expect(items.arrange([first, second, ...drawerItemOrder]).take(3), [
        first,
        second,
        'dashboard',
      ]);
      // Turned off, a plugin action stays off.
      final off = DrawerItems(shown: const ['dashboard'], hidden: {first});
      expect(off.arrange([first, ...drawerItemOrder]), isNot(contains(first)));
    });

    test('a legacy switch turns one row on or off', () {
      final items = DrawerItems(
        shown: const ['apps', 'dashboard'],
        hidden: {
          for (final id in drawerItemOrder)
            if (id != 'dashboard' && id != 'apps') id,
        },
      );
      final on = items.withItem('lockdown', true);
      expect(on.shown, ['apps', 'dashboard', 'lockdown']);
      expect(on.hidden, isNot(contains('lockdown')));
      final off = on.withItem('dashboard', false);
      expect(off.shown, ['apps', 'lockdown']);
      expect(off.hidden, contains('dashboard'));
    });

    test('a removed plugin leaves the list', () {
      final keep = drawerPluginItem('b', 'two');
      final items = DrawerItems(
        shown: [drawerPluginItem('a', 'one'), 'dashboard', keep],
        hidden: {drawerPluginItem('a', 'off'), drawerPluginItem('ab', 'x')},
      ).withoutPlugin('a');
      expect(items.shown, ['dashboard', keep]);
      // Only that plugin's rows: one whose id starts the same stays.
      expect(items.hidden, {drawerPluginItem('ab', 'x')});
    });

    test('anything unreadable is the defaults', () {
      expect(DrawerItems.decode('nope').shown, isEmpty);
      expect(DrawerItems.decode('[1, 2]').hidden, isEmpty);
      final round = DrawerItems.decode(
        const DrawerItems(shown: ['apps'], hidden: {'exit'}).encode(),
      );
      expect(round.shown, ['apps']);
      expect(round.hidden, {'exit'});
    });
  });

  group('the settings', () {
    test('an upgrade seeds the list from the old switches', () async {
      SharedPreferences.setMockInitialValues({
        'ks.lockdown.menu': true,
        'ks.alarms.menu': false,
        'ks.ha.hold_menu': true,
      });
      final container = AppContainer();
      await container.settings.init();
      addTearDown(container.settings.dispose);
      final items = DrawerItems.decode(
        container.settings.get(defs.uiDrawerItems),
      );
      expect(items.shows('lockdown'), isTrue);
      expect(items.shows('hold'), isTrue);
      expect(items.shows('alarms'), isFalse);
      // The switches that were left alone keep their old defaults.
      expect(items.shows('screensaver'), isTrue);
      expect(items.shows('player'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get('ks.lockdown.menu'), isNull);
      expect(prefs.get('ks.alarms.menu'), isNull);
    });

    test('the links hold no value of their own', () async {
      SharedPreferences.setMockInitialValues({});
      final container = AppContainer();
      await container.settings.init();
      addTearDown(container.settings.dispose);
      final links = defs.allSettings.where((d) => d.linksTo != null).toList();
      // The old per-row switches, plus Compass's Menu items row, which
      // only leads to the same list.
      expect({
        for (final d in links)
          if (d.key != defs.navCompassMenuItems.key) d.key,
      }, drawerItemLinks.keys.toSet());
      final export = container.settings.export();
      for (final d in links) {
        expect(export.containsKey(d.key), isFalse, reason: d.key);
        expect(d.linksTo, defs.uiDrawerItems.key);
      }
      final described = container.settings.describe().firstWhere(
        (d) => d['key'] == 'alarms.menu',
      );
      expect(described['linksTo'], 'ui.drawer_items');
    });

    test('a backup from before still turns rows on and off', () async {
      SharedPreferences.setMockInitialValues({});
      final container = AppContainer();
      await container.settings.init();
      addTearDown(container.settings.dispose);
      await container.settings.import({
        'lockdown.menu': true,
        'screensaver.menu': false,
      });
      final items = DrawerItems.decode(
        container.settings.get(defs.uiDrawerItems),
      );
      expect(items.shows('lockdown'), isTrue);
      expect(items.shows('screensaver'), isFalse);
      // A batch that carries the list itself is not overridden by them.
      await container.settings.import({
        'ui.drawer_items': jsonEncode({
          'shown': ['dashboard'],
          'hidden': <String>[],
        }),
        'lockdown.menu': true,
        'screensaver.menu': true,
      });
      final batch = DrawerItems.decode(
        container.settings.get(defs.uiDrawerItems),
      );
      expect(batch.shown, ['dashboard']);
      expect(batch.shows('lockdown'), isFalse);
    });
  });

  test('removing a plugin prunes it and a stopped one stays listed', () async {
    SharedPreferences.setMockInitialValues({});
    final container = AppContainer();
    await container.settings.init();
    addTearDown(container.settings.dispose);
    final action = drawerPluginItem('hello', 'scan');
    await container.settings.set(
      defs.uiDrawerItems,
      DrawerItems(shown: [action, 'dashboard']).encode(),
    );
    container.plugins.installed.value = [
      {
        'id': 'hello',
        'name': 'Hello',
        'running': false,
        'commands': [
          {'id': 'scan', 'title': 'Scan'},
        ],
        'actionOptions': {
          'scan': {'drawer': true},
        },
      },
    ];
    // Stopped: out of the menu, still in the picker's list.
    expect(container.plugins.drawerActions, isEmpty);
    expect(drawerPluginActions(container).single['command'], 'scan');
    container.plugins.onRemoved!('hello');
    await Future<void>.delayed(Duration.zero);
    expect(
      DrawerItems.decode(container.settings.get(defs.uiDrawerItems)).shown,
      ['dashboard'],
    );
  });

  testWidgets('the drawer draws the list in its order', (tester) async {
    SharedPreferences.setMockInitialValues({
      'ks.ui.drawer_items': jsonEncode({
        'shown': ['exit', 'clear_cache', 'dashboard', 'settings'],
        'hidden': ['theme', 'apps', 'screensaver'],
      }),
    });
    final container = AppContainer();
    await container.settings.init();
    container.device.appVersion = 'test';
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await container.settings.dispose();
      await container.bus.dispose();
      await container.log.dispose();
    });
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> pumpDrawer({bool restricted = false}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: KioskDrawer(
              container: container,
              onClose: () {},
              onSettings: () {},
              restricted: restricted,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    double top(String text) => tester.getTopLeft(find.text(text)).dy;

    await pumpDrawer();
    expect(top('Exit Application'), lessThan(top('Clear web cache')));
    expect(top('Clear web cache'), lessThan(top('Dashboard')));
    expect(top('Dashboard'), lessThan(top('Settings')));
    expect(find.text('Start Screensaver'), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsNothing);
    // Exit leads, so the rule that sets it apart at the end is not drawn.
    expect(
      find.byWidgetPredicate(
        (w) => w is Divider && w.thickness == 1 && w.color == null,
      ),
      findsNothing,
    );

    // Settings may go only while the remote admin can lead back in.
    await container.settings.setFromJson(
      defs.uiDrawerItems.key,
      jsonEncode({
        'shown': ['dashboard'],
        'hidden': ['settings'],
      }),
    );
    await container.settings.set(defs.remoteEnabled, true);
    await pumpDrawer();
    expect(find.text('Settings'), findsNothing);
    await container.settings.set(defs.remoteEnabled, false);
    await pumpDrawer();
    expect(find.text('Settings'), findsOneWidget);

    // The quick-actions menu keeps Allowed Actions on top of the list.
    await container.settings.set(defs.kioskAllowDashboard, false);
    await pumpDrawer(restricted: true);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(
      KioskDrawer.visibleItems(container, restricted: true),
      isNot(contains('dashboard')),
    );
  });
}
