import 'package:flutter_test/flutter_test.dart';

import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_search.dart';

/// The pages the device settings screen registers, category → (title,
/// subtitle), matching _categories in settings_screen.dart.
const _pages = <(String, String, String)>[
  ('Home Assistant', 'Home Assistant Configuration', 'Connection, dashboard'),
  ('Voice Satellite', 'Voice Satellite', 'Wake word'),
  ('Screen & Audio', 'Screen & Audio', 'Brightness, volume'),
  ('Browser', 'Web Browsing', 'Cache, SSL'),
  ('Screensaver', 'Screensaver', 'Idle timeout'),
  ('Camera', 'Camera', 'Device camera'),
  ('Sendspin', 'Sendspin Player', 'Synchronized audio'),
  ('Kiosk', 'Kiosk Mode', 'Exit gesture'),
  ('Device', 'Device', 'Name, app theme'),
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

  group('resolveSearchAnchor', () {
    SettingsSearchEntry entryFor(String key) =>
        index.firstWhere((e) => e.defKey == key);

    test('a visible setting lands on itself', () {
      final anchor = resolveSearchAnchor(entryFor(kioskEnabled.key), (_) => true);
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
