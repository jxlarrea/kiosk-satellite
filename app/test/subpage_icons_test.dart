import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/subpage_icons.dart';

/// Every second-level page wears a glyph on its entry row and in its title,
/// on both surfaces. These lock the two registries to the page list, so a
/// new page cannot ship with a hole where its glyph should be on one side
/// and not the other.
void main() {
  final pages = subpageHints.keys.toSet();

  test('every device-drawn subpage has a glyph', () {
    final missing = pages
        .difference(remoteOnlySubpages)
        .where((p) => !subpageIcons.containsKey(p))
        .toList();
    expect(missing, isEmpty, reason: 'add these to subpageIcons');
  });

  test('every declared subpage is a page the hints know', () {
    // A def can only point at a page that has a hint (the entry row's
    // subtitle) and so a glyph.
    for (final def in allSettings) {
      if (def.subpage == null) continue;
      expect(pages, contains(def.subpage), reason: def.key);
    }
  });

  test('the icon map names no page that does not exist', () {
    final stray = subpageIcons.keys.where((p) => !pages.contains(p)).toList();
    expect(stray, isEmpty, reason: 'stale entries in subpageIcons');
    expect(remoteOnlySubpages.every(pages.contains), isTrue);
  });

  test('the remote icons module covers every subpage', () {
    final source = File('assets/remote-ui/static/icons.js').readAsStringSync();
    final missing = pages.where((p) => !source.contains("'$p':")).toList();
    expect(missing, isEmpty, reason: 'add these to SUBPAGE_ICONS');
    // The remote draws the same glyphs from its own map: the entry row and
    // the page title both go through subpageIcon.
    final tabs = File('assets/remote-ui/static/tabs.js').readAsStringSync();
    expect(tabs, contains("import { subpageIcon } from './icons.js'"));
    expect(tabs, contains('row.append(icon, info, chev)'));
    expect(tabs, contains('titleEl.prepend(back, subpageIcon(sub))'));
  });

  test('an unknown page still gets a glyph', () {
    expect(subpageIcon('No such page'), isA<IconData>());
    expect(subpageIcon('Theme'), Icons.palette_outlined);
  });

  test('a product mark is an SVG asset that exists', () {
    for (final icon in subpageIcons.values) {
      if (icon is String) {
        expect(File(icon).existsSync(), isTrue, reason: icon);
      } else {
        expect(icon, isA<IconData>());
      }
    }
    expect(subpageIcon('Immich Media screensaver'), 'assets/svg/immich.svg');
  });
}
