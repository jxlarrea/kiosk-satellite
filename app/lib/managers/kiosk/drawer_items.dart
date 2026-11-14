/// The drawer menu's rows (issue #1194): which ones it shows and in what
/// order, picked in Settings > Device > User Interface > Drawer menu
/// items. Stored in ui.drawer_items as `{"shown": [...], "hidden": [...]}`:
/// the rows in
/// the order the menu draws them, and the ones turned off. A row in
/// neither list is new to this kiosk (a plugin action, a row added by an
/// update) and takes its default: on, unless [drawerItemsOffByDefault]
/// says otherwise, at its place in [drawerItemOrder].
///
/// A row the list shows still has to have something to do: the camera
/// view needs cameras, the intercom needs the intercom on. And the locked
/// kiosk's quick menu still only shows what Allowed Actions allows.
library;

import 'dart:convert';

/// The built-in rows in their default order. The theme switcher keeps the
/// foot of the menu wherever it is placed; it is listed so it can be
/// turned off. Plugin actions ([drawerPluginItem]) go ahead of these.
const drawerItemOrder = [
  'dashboard',
  'settings',
  'ha_kiosk',
  'camera',
  'intercom',
  'alarms',
  'timers',
  'calendar',
  'music_library',
  'music_assistant',
  'player',
  'now_playing',
  'screensaver',
  'lockdown',
  'hold',
  'apps',
  'clear_cache',
  'restart',
  'exit',
  'theme',
];

/// The rows a kiosk starts without: the ones whose own "Show in the kiosk
/// menu" switch used to default to off.
const drawerItemsOffByDefault = {'lockdown', 'hold', 'player', 'now_playing'};

/// The rows that leave or restart the app. The menu sets them apart with a
/// rule when they close the list, as they do by default.
const drawerPowerItems = {'restart', 'exit'};

/// The rows on feature pages that open Drawer menu items, keyed to the
/// menu row each stands for. All but the App Launcher's used to switch
/// their row on and off one by one: their stored values seed the list once
/// on upgrade, and a backup, a fleet leader or an API caller from before
/// still sending one turns the row on or off.
const drawerItemLinks = {
  'ha.kiosk_menu': 'ha_kiosk',
  'screensaver.menu': 'screensaver',
  'lockdown.menu': 'lockdown',
  'intercom.menu': 'intercom',
  'alarms.menu': 'alarms',
  'calendar.menu': 'calendar',
  'library.menu': 'music_library',
  'sendspin.ma_shortcut': 'music_assistant',
  'sendspin.player_shortcut': 'player',
  'sendspin.fullscreen_shortcut': 'now_playing',
  'ha.hold_menu': 'hold',
  'launcher.menu': 'apps',
};

/// The row of a plugin action that asked for the drawer.
String drawerPluginItem(String pluginId, String command) =>
    'plugin:$pluginId/$command';

bool isDrawerPluginItem(String id) => id.startsWith('plugin:');

class DrawerItems {
  const DrawerItems({this.shown = const [], this.hidden = const {}});

  /// The rows on, in menu order.
  final List<String> shown;

  /// The rows turned off.
  final Set<String> hidden;

  /// Anything unreadable is the defaults, which an empty value also is.
  factory DrawerItems.decode(String raw) {
    if (raw.trim().isEmpty) return const DrawerItems();
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const DrawerItems();
      List<String> ids(Object? list) => [
        if (list is List)
          for (final id in list)
            if (id is String && id.isNotEmpty) id,
      ];
      final shown = ids(map['shown']).toSet().toList();
      return DrawerItems(
        shown: shown,
        hidden: ids(map['hidden']).toSet()..removeAll(shown),
      );
    } catch (_) {
      return const DrawerItems();
    }
  }

  String encode() =>
      jsonEncode({'shown': shown, 'hidden': hidden.toList()..sort()});

  /// Whether the list has [id] on, by choice or by default.
  bool shows(String id) =>
      shown.contains(id) ||
      (!hidden.contains(id) && !drawerItemsOffByDefault.contains(id));

  /// The rows of [available] the menu shows, in menu order: the chosen
  /// ones as arranged, then the new ones and [forced] at their default
  /// places. [forced] are on whatever the list says (Settings while the
  /// remote admin is off, so it is never the only way back in).
  List<String> arrange(
    Iterable<String> available, {
    Set<String> forced = const {},
  }) {
    final pool = available.toSet();
    final out = [
      for (final id in shown)
        if (pool.contains(id)) id,
    ];
    for (final id in _defaultOrder(pool)) {
      if (out.contains(id)) continue;
      if (forced.contains(id) || (shows(id) && !shown.contains(id))) {
        _insertAtDefault(out, id);
      }
    }
    return out;
  }

  /// The list with [id] turned on or off, for a legacy switch written by a
  /// backup, a fleet leader or an API caller. Turned on, the row takes its
  /// default place among the rows on.
  DrawerItems withItem(String id, bool on) {
    if (on) {
      final rows = arrange([...drawerItemOrder, ...shown]);
      if (!rows.contains(id)) _insertAtDefault(rows, id);
      return DrawerItems(shown: rows, hidden: {...hidden}..remove(id));
    }
    final rows = arrange([...drawerItemOrder, ...shown])..remove(id);
    return DrawerItems(shown: rows, hidden: {...hidden, id});
  }

  /// The list without the rows of the plugin [pluginId], once it is gone.
  DrawerItems withoutPlugin(String pluginId) {
    bool of(String id) => id.startsWith('plugin:$pluginId/');
    return DrawerItems(
      shown: shown.where((id) => !of(id)).toList(),
      hidden: hidden.where((id) => !of(id)).toSet(),
    );
  }

  /// [pool] in default order: plugin actions first, then the built-ins.
  static List<String> _defaultOrder(Set<String> pool) => [
    for (final id in pool)
      if (isDrawerPluginItem(id)) id,
    for (final id in drawerItemOrder)
      if (pool.contains(id)) id,
  ];

  /// Puts [id] right after the closest row that comes before it by
  /// default, or first when none does. Plugin actions go after the ones
  /// already leading the menu.
  static void _insertAtDefault(List<String> rows, String id) {
    if (isDrawerPluginItem(id)) {
      var i = 0;
      while (i < rows.length && isDrawerPluginItem(rows[i])) {
        i++;
      }
      rows.insert(i, id);
      return;
    }
    final at = drawerItemOrder.indexOf(id);
    if (at > 0) {
      for (var i = at - 1; i >= 0; i--) {
        final before = rows.indexOf(drawerItemOrder[i]);
        if (before >= 0) {
          rows.insert(before + 1, id);
          return;
        }
      }
    }
    rows.insert(0, id);
  }
}
