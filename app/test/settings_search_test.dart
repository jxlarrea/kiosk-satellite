import 'package:flutter_test/flutter_test.dart';

import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_search.dart';

/// The pages the device settings screen registers, category → (title,
/// subtitle), matching _categories in settings_screen.dart.
const _pages = <(String, String, String)>[
  ('Home Assistant', 'Home Assistant Setup', 'Connection, dashboard'),
  ('Voice Satellite', 'Voice Satellite', 'Wake word'),
  ('Screen & Audio', 'Screen & Audio', 'Brightness, volume'),
  ('Browser', 'Web Browsing', 'Cache, SSL'),
  ('Screensaver', 'Screensaver', 'Idle timeout'),
  ('Camera', 'Camera', 'Device camera'),
  ('Sendspin', 'Media Player', 'Music Assistant, Sendspin, Sonos'),
  ('Kiosk', 'Kiosk Mode', 'Exit gesture'),
  ('Device', 'Device', 'Name, app theme'),
  ('Plugins', 'Plugin Manager', 'Install and manage plugins'),
];

List<String> get _order => [for (final p in _pages) p.$1];

void main() {
  final index = buildSettingsSearchIndex(_pages);

  group('buildSettingsSearchIndex', () {
    test('carries every non-hidden definition of a registered category', () {
      final keys = index.map((e) => e.defKey).whereType<String>().toSet();
      for (final def in allSettings) {
        final registered = _order.contains(def.category);
        expect(
          keys.contains(def.key),
          !def.hidden && registered,
          reason: def.key,
        );
      }
    });

    test('skips categories with no pane here (Lockdown on the device)', () {
      expect(index.where((e) => e.category == 'Lockdown'), isEmpty);
    });

    test('includes the pages themselves and the hand-built rows', () {
      expect(
        index.where((e) => e.isPage).map((e) => e.title),
        containsAll(['Screensaver', 'Web Browsing']),
      );
      expect(
        index.where((e) => e.anchorId == 'x:kiosk_permissions'),
        isNotEmpty,
      );
    });

    test('second-level pages are findable, landing on their entry row', () {
      final entry = index.singleWhere((e) => e.title == 'User Interface');
      expect(entry.category, 'Home Assistant');
      expect(entry.isPage, isTrue);
      expect(entry.anchorId, 'sub:User Interface');
      // The hint the entry row shows is what the search matches on.
      expect(entry.description, subpageHints['User Interface']);
    });

    test('a setting that moved onto a subpage is still indexed itself', () {
      // Moving the group must not cost the rows their own search results.
      expect(
        index.where((e) => e.defKey == haHaptics.key),
        isNotEmpty,
        reason: 'haptics row',
      );
    });
  });

  group('searchSettings', () {
    test('empty query matches nothing', () {
      expect(searchSettings('', index, _order), isEmpty);
      expect(searchSettings('   ', index, _order), isEmpty);
    });

    test('matches titles and descriptions, case-insensitively', () {
      final byTitle = searchSettings('BRIGHTNESS', index, _order);
      expect(byTitle, isNotEmpty);
      expect(
        byTitle.any((e) => e.title.toLowerCase().contains('brightness')),
        isTrue,
      );
    });

    test('every term must match somewhere', () {
      final hits = searchSettings('wake word zzznope', index, _order);
      expect(hits, isEmpty);
    });

    test('title matches rank above description-only matches', () {
      final hits = searchSettings('screensaver', index, _order);
      final inScreensaver = [
        for (final e in hits)
          if (e.category == 'Screensaver') e,
      ];
      final firstDescOnly = inScreensaver.indexWhere(
        (e) => !e.title.toLowerCase().contains('screensaver'),
      );
      final lastTitle = inScreensaver.lastIndexWhere(
        (e) => e.title.toLowerCase().contains('screensaver'),
      );
      if (firstDescOnly >= 0) {
        expect(lastTitle, lessThan(firstDescOnly));
      }
    });

    test('results come back grouped in category order', () {
      final hits = searchSettings('volume', index, _order);
      final cats = <String>[];
      for (final e in hits) {
        if (cats.isEmpty || cats.last != e.category) cats.add(e.category);
      }
      // No category appears twice: grouping is contiguous.
      expect(cats.toSet().length, cats.length);
      // And the groups follow the pane order.
      final ranks = [for (final c in cats) _order.indexOf(c)];
      expect(ranks, orderedEquals([...ranks]..sort()));
    });
  });

  test(
    'custom Plugin Manager and Shizuku rows are indexed by their own text',
    () {
      List<SettingsSearchEntry> hits(String text) =>
          searchSettings(text, index, _order);
      expect(
        hits('plugin').map((e) => e.title),
        containsAll(['Enable Plugins', 'Add plugin', 'Create a plugin']),
      );
      expect(hits('ZIP').single.title, 'Install from ZIP');
      expect(
        hits('Shizuku').map((e) => e.title),
        containsAll([
          'Shizuku access',
          'Set up Shizuku',
          'Install updates through Shizuku',
        ]),
      );
      expect(
        hits('Shizuku').map((e) => e.title),
        isNot(contains('Test connection')),
      );
      final connection = hits('Test connection').single;
      expect(connection.subpage, 'Shizuku');
      expect(connection.anchorId, 'x:shizuku:identity');
      expect(
        hits('Grant all permissions').first.anchorId,
        'x:shizuku:grantAll',
      );
      expect(
        hits('Nearby devices').any((e) => e.anchorId == 'x:shizuku:bluetooth'),
        true,
      );
      expect(hits('For developers only').single.anchorId, 'x:plugins:zip');
    },
  );

  test(
    'installed plugin settings refresh from manifests without matching the parent name',
    () {
      List<SettingsSearchEntry> dynamicIndex(
        List<Map<String, Object?>> plugins,
      ) => [...index, ...pluginSettingsSearchEntries(plugins)];
      final plugins = <Map<String, Object?>>[
        {
          'id': 'hello',
          'name': 'Hello World',
          'capabilities': ['shizuku'],
          'description': 'A sample plugin',
          'settings': [
            {
              'key': 'greeting',
              'title': 'Greeting',
              'description': 'Text shown in the floating window.',
            },
          ],
          'commands': [
            {'id': 'show', 'title': 'Show greeting'},
          ],
        },
      ];
      final withPlugin = dynamicIndex(plugins);
      expect(
        searchSettings(
          'Shizuku access',
          withPlugin,
          _order,
        ).any((e) => e.anchorId == 'plugin:hello:shizuku'),
        true,
      );
      final greeting = searchSettings(
        'floating window',
        withPlugin,
        _order,
      ).singleWhere((e) => e.anchorId == 'plugin:hello:setting:greeting');
      expect(greeting.subpage, 'hello');
      expect(greeting.anchorId, 'plugin:hello:setting:greeting');
      expect(
        searchSettings(
          'Hello World',
          withPlugin,
          _order,
        ).where((e) => e.subpage == 'hello').map((e) => e.title),
        ['Hello World'],
      );
      expect(
        searchSettings(
          'Show greeting',
          withPlugin,
          _order,
        ).singleWhere((e) => e.title == 'Show greeting').anchorId,
        'plugin:hello:action:show',
      );
      expect(
        resolveSearchAnchor(greeting, (_) => true, pluginsEnabled: false),
        'x:plugins:master',
      );
      expect(
        searchSettings(
          'floating window',
          dynamicIndex([]),
          _order,
        ).where((e) => e.subpage == 'hello'),
        isEmpty,
      );
    },
  );

  group('resolveSearchAnchor', () {
    SettingsSearchEntry entryFor(String key) =>
        index.firstWhere((e) => e.defKey == key);

    test('a visible setting lands on itself', () {
      final anchor = resolveSearchAnchor(
        entryFor(kioskEnabled.key),
        (_) => true,
      );
      expect(anchor, kioskEnabled.key);
    });

    test('a gated setting lands on the parent that turns it on', () {
      // Simulate kiosk mode off: everything gated on the master switch
      // reports not-visible, and only the master itself is on screen.
      final anchor = resolveSearchAnchor(
        entryFor(kioskExitGesture.key),
        (def) => def.key == kioskEnabled.key,
      );
      expect(anchor, kioskEnabled.key);
    });

    test('a chain with no visible parent lands on the pane top', () {
      final anchor = resolveSearchAnchor(
        entryFor(kioskExitGesture.key),
        (_) => false,
      );
      expect(anchor, isNull);
    });

    test('hand-built entries keep their anchor untouched', () {
      const entry = SettingsSearchEntry(
        category: 'Kiosk',
        title: 'Required system permissions',
        description: '',
        anchorId: 'x:kiosk_permissions',
      );
      expect(resolveSearchAnchor(entry, (_) => true), 'x:kiosk_permissions');
    });

    test('page entries land on the pane top', () {
      final page = index.firstWhere((e) => e.isPage);
      expect(resolveSearchAnchor(page, (_) => true), isNull);
    });
  });
}
