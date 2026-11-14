import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/command_registry.dart';
import '../l10n/messages.dart';
import '../managers/home_assistant/entity_list.dart';
import '../managers/kiosk/drawer_items.dart';
import '../managers/settings/definitions.dart';
import 'kit.dart';
import 'mdi_icon.dart';
import 'picker_dialog.dart';
import 'theme.dart';

/// One row the picker lists: a Home Assistant entity, a media player.
class PickItem {
  const PickItem({
    required this.id,
    required this.name,
    this.sub,
    this.subMono = false,
    this.state,
    this.icon,
    this.group = '',
    this.chip,
    this.available = true,
    this.raw = const {},
  });

  /// What the setting stores: the entity id, the player id.
  final String id;
  final String name;

  /// The second line: the entity id (mono), a player's members or model.
  final String? sub;
  final bool subMono;

  /// The value on the right: the formatted state, Offline.
  final String? state;

  /// An MDI icon name ("mdi:sofa").
  final String? icon;

  /// The heading the row sits under: its area, its source. Empty for none.
  final String group;

  /// The chip that filters it in: its domain's title, its source.
  final String? chip;

  /// False dims the row. It stays pickable.
  final bool available;

  /// The fields as listed, for filters.
  final Map<String, Object?> raw;
}

/// What a source lists: the rows, a note per group (a source that could
/// not be reached), and the order of the groups when it matters.
class PickList {
  const PickList(this.items, {this.notes = const {}, this.groupOrder});

  final List<PickItem> items;
  final Map<String, String> notes;
  final List<String>? groupOrder;

  PickItem? find(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }
}

/// A cached list per source for the session. Pickers open on the cached
/// list and refresh it in place, and every field follows [of].
abstract final class PickCatalog {
  static final _lists = <String, ValueNotifier<PickList?>>{};
  static final _pending = <String, Future<PickList?>>{};

  static ValueNotifier<PickList?> of(String key) =>
      _lists.putIfAbsent(key, () => ValueNotifier<PickList?>(null));

  /// Loads [key] through [loader], one load at a time. Null when the
  /// source cannot be reached, keeping the last good list.
  static Future<PickList?> load(
    String key,
    Future<PickList?> Function() loader,
  ) => _pending[key] ??= loader()
      .then((list) {
        if (list != null) of(key).value = list;
        return list;
      })
      // A block, not an arrow: remove() hands back this very future, and
      // whenComplete would wait on it forever.
      .whenComplete(() {
        _pending.remove(key);
      });

  /// Forgets every list, for tests that stub other sources.
  @visibleForTesting
  static void reset() {
    for (final list in _lists.values) {
      list.value = null;
    }
    _pending.clear();
  }
}

/// What a picker lists and how: the source, the rows it keeps, the search
/// box's hint and the heading for rows outside every group.
class PickSpec {
  const PickSpec({
    required this.key,
    required this.loader,
    required this.searchHint,
    required this.noGroup,
    this.keep,
    this.byGroupName = true,
    this.chips = true,
    this.headings = true,
    this.noteText,
    this.grid = false,
    this.limit,
    this.emptyText,
  });

  final String key;
  final Future<PickList?> Function() loader;
  final String searchHint;
  final String noGroup;
  final bool Function(PickItem item)? keep;

  /// Groups in name order (areas). False keeps the source's order.
  final bool byGroupName;
  final bool chips;

  /// False lists the rows without group headings (one source's players).
  final bool headings;

  /// Translates a source's note for the screen.
  final String Function(BuildContext context, String note)? noteText;

  /// Lays the rows out as tiles of an icon over a short label (the icon
  /// picker), the label being the row's [PickItem.sub] or its name.
  final bool grid;

  /// The most rows on show, the picked ones first while nothing is typed.
  /// Search finds the rest. For sources too big to draw whole, like the
  /// thousands of icons.
  final int? limit;

  /// What an empty list says, for a source that can be empty without
  /// failing, such as a plugin's choices before it lists any. Nothing
  /// matches otherwise.
  final String Function(BuildContext context)? emptyText;
}

/// Home Assistant's entities, all of them, filtered on the device per
/// picker. One list serves every entity picker. Entities Home Assistant
/// hides stay out unless [includeHidden] asks for them.
PickSpec entitySpec(
  BuildContext context,
  CommandRegistry commands, {
  List<String> domains = const [],
  String? deviceClass,
  bool includeHidden = false,
}) => PickSpec(
  key: 'entities',
  loader: () => _loadEntities(commands),
  searchHint: haText(context, 'Search entities'),
  noGroup: haText(context, 'No area'),
  chips: domains.length != 1,
  keep: (item) =>
      (includeHidden || item.raw['hidden'] != true) &&
      (domains.isEmpty || domains.contains(item.raw['domain'])) &&
      (deviceClass == null || matchesDeviceClass(item.raw, deviceClass)),
);

/// Loads the entity list every entity picker shares, for a screen that
/// shows stored entities before any picker opens.
Future<PickList?> loadEntityCatalog(CommandRegistry commands) =>
    PickCatalog.load('entities', () => _loadEntities(commands));

Future<PickList?> _loadEntities(CommandRegistry commands) async {
  final result = await commands.execute('haListEntities', const {});
  if (!result.ok || result.data is! List) return null;
  return PickList([
    for (final e in (result.data as List).whereType<Map>())
      PickItem(
        id: '${e['entity_id']}',
        name: '${e['name'] ?? e['entity_id']}',
        sub: '${e['entity_id']}',
        subMono: true,
        state: e['state'] == null ? null : '${e['state']}',
        icon: e['icon'] as String?,
        group: '${e['area'] ?? ''}',
        chip: e['domain_title'] as String?,
        raw: e.cast<String, Object?>(),
      ),
  ]);
}

/// Home Assistant's services under their domains' titles, for a gesture
/// that calls one. Each row keeps the entity domains the service acts on
/// (`entity_domains`: null for none, empty for any).
PickSpec serviceSpec(BuildContext context, CommandRegistry commands) =>
    PickSpec(
      key: 'services',
      loader: () => _loadServices(commands),
      searchHint: gestureText(context, 'Search services'),
      noGroup: '',
      chips: false,
    );

Future<PickList?> _loadServices(CommandRegistry commands) async {
  final result = await commands.execute('haListServices', const {});
  if (!result.ok || result.data is! List) return null;
  final rows = (result.data as List).whereType<Map>().toList()
    ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
  return PickList([
    for (final e in rows)
      PickItem(
        id: '${e['id']}',
        name: '${e['name'] ?? e['id']}',
        sub: '${e['id']}',
        subMono: true,
        icon: e['icon'] as String?,
        group: '${e['domain_title'] ?? e['domain'] ?? ''}',
        raw: e.cast<String, Object?>(),
      ),
  ]);
}

/// The entity domains [serviceId] acts on, from the loaded services: null
/// when it takes no entity, empty when it takes any. Before the list
/// loads (or for a service it lacks) the service's own domain.
List<String>? serviceEntityDomainsOf(String serviceId) {
  if (serviceId.isEmpty) return null;
  final item = PickCatalog.of('services').value?.find(serviceId);
  if (item == null) return [serviceId.split('.').first];
  final domains = item.raw['entity_domains'];
  return domains is List ? [for (final d in domains) '$d'] : null;
}

/// One source's players (`ma`, `ha`, `sonos`), from `mediaPlayers`: the
/// Sendspin player and the voice satellite's speaker. [speakers] keeps
/// Music Assistant's own entities in Home Assistant's list. The source's
/// note (it could not be reached, it is not set up) shows above its rows.
PickSpec playerSpec(
  BuildContext context,
  CommandRegistry commands, {
  required String source,
  bool speakers = false,
}) {
  return PickSpec(
    key: 'players:$source:$speakers',
    loader: () => _loadPlayers(commands, source, speakers, false),
    searchHint: mediaText(context, 'Search players'),
    noGroup: '',
    byGroupName: false,
    chips: false,
    headings: false,
    noteText: mediaError,
  );
}

/// The players the speaker selection pill can offer (issue #974): Music
/// Assistant's players and every Sonos room, each under its source's
/// name with chips to show one source. Sonos is left out while it knows
/// no speakers, and one source alone reads as a plain list.
PickSpec speakerPillSpec(BuildContext context, CommandRegistry commands) =>
    PickSpec(
      key: 'players:pill',
      loader: () => _loadPillPlayers(commands),
      searchHint: mediaText(context, 'Search players'),
      noGroup: '',
      byGroupName: false,
      noteText: mediaError,
    );

Future<PickList?> _loadPillPlayers(CommandRegistry commands) async {
  final lists = await Future.wait([
    _loadPlayers(commands, 'ma', false, false),
    _loadPlayers(commands, 'sonos', false, true),
  ]);
  final ma = lists[0];
  final sonos = lists[1]?.items ?? const <PickItem>[];
  // Product names, the same in every language.
  final both = sonos.isNotEmpty;
  final maGroup = both ? 'Music Assistant' : '';
  PickItem under(PickItem i, String group) => PickItem(
    id: i.id,
    name: i.name,
    sub: i.sub,
    subMono: i.subMono,
    icon: i.icon,
    group: group,
    chip: group.isEmpty ? null : group,
    available: i.available,
    raw: i.raw,
  );
  final maNote = ma?.notes['ma'];
  return PickList(
    [
      for (final i in ma?.items ?? const <PickItem>[]) under(i, maGroup),
      for (final i in sonos) under(i, 'Sonos'),
    ],
    // Sonos says when it knows no speakers, which is no news to anyone
    // without them, so only Music Assistant's note stays.
    notes: {if (maNote != null && maNote.isNotEmpty) maGroup: maNote},
    groupOrder: [maGroup, 'Sonos'],
  );
}

/// The device's launchable apps from `installedApps`, alphabetical, for
/// the app launcher's picks (issue #1067). The caller lists them first, so
/// a failure can say why.
PickSpec appSpec(BuildContext context, List<Map> apps) => PickSpec(
  key: 'apps',
  loader: () async => PickList([
    for (final app in apps)
      PickItem(
        id: '${app['package']}',
        name: '${app['label']}',
        sub: '${app['package']}',
        subMono: true,
        icon: 'mdi:application-outline',
      ),
  ]),
  searchHint: launcherText(context, 'Search apps'),
  noGroup: '',
  byGroupName: false,
  chips: false,
  headings: false,
);

/// Every row the kiosk menu can show, in its default order, for Drawer
/// menu items (issue #1194): the plugin actions that asked for the
/// drawer, then the built-in rows. Mirrored on the remote
/// (drawer_items.js).
/// The plugin actions that asked for the drawer, running or not: a
/// stopped plugin keeps its place in the list while it is stopped.
List<Map<String, Object?>> drawerPluginActions(AppContainer container) => [
  for (final action in container.plugins.actions)
    if (action['drawer'] == true) action,
];

PickSpec drawerItemSpec(BuildContext context, AppContainer container) {
  final strings = l10n(context);
  final remoteOff = !container.settings.get(remoteEnabled);
  final names = <String, (String, String)>{
    'dashboard': (strings.drawerDashboard, 'mdi:view-dashboard-outline'),
    'settings': (strings.commonSettings, 'mdi:cog-outline'),
    'ha_kiosk': (strings.drawerHaKiosk, 'mdi:fullscreen'),
    'camera': (strings.drawerCameraView, 'mdi:video-outline'),
    'intercom': (strings.drawerIntercom, 'mdi:cellphone-sound'),
    'alarms': (strings.alarmsTitle, 'mdi:alarm'),
    'timers': (strings.voiceTimersViewTitle, 'mdi:timer-outline'),
    'calendar': (strings.calendarTitle, 'mdi:calendar-month-outline'),
    'music_library': (strings.libraryTitle, 'mdi:music-box-multiple-outline'),
    'music_assistant': (strings.drawerMusicAssistant, 'mdi:music'),
    'player': (
      kioskAllowSendspinPlayer.localizedTitle(context),
      'mdi:play-circle-outline',
    ),
    'now_playing': (strings.drawerNowPlaying, 'mdi:album'),
    'screensaver': (strings.drawerScreensaver, 'mdi:weather-night'),
    'lockdown': (strings.drawerLockdown, 'mdi:lock-outline'),
    'hold': (
      kioskAllowHold.localizedTitle(context),
      'mdi:pause-circle-outline',
    ),
    'apps': (strings.drawerApps, 'mdi:apps'),
    'clear_cache': (strings.drawerClearCache, 'mdi:broom'),
    'restart': (strings.drawerRestartDevice, 'mdi:restart'),
    'exit': (strings.drawerExitApplication, 'mdi:power'),
    'theme': (kioskAllowTheme.localizedTitle(context), 'mdi:theme-light-dark'),
  };
  return PickSpec(
    key: 'drawer_items',
    loader: () async => PickList([
      for (final action in drawerPluginActions(container))
        PickItem(
          id: drawerPluginItem('${action['pluginId']}', '${action['command']}'),
          name: strings.drawerPluginAction(
            '${action['pluginName']}',
            '${action['title']}',
          ),
          icon: 'mdi:puzzle-outline',
          // Dimmed while its plugin is stopped. The menu leaves it out then.
          available: action['available'] == true,
        ),
      for (final id in drawerItemOrder)
        PickItem(
          id: id,
          name: names[id]!.$1,
          // Settings stays in the menu while nothing else leads back in.
          sub: id == 'settings' && remoteOff
              ? strings.drawerItemsSettingsKept
              : null,
          icon: names[id]!.$2,
        ),
    ]),
    searchHint: strings.drawerItemsSearch,
    noGroup: '',
    byGroupName: false,
    chips: false,
    headings: false,
  );
}

/// A fixed list of players, this device's own.
PickSpec fixedPlayerSpec(
  BuildContext context, {
  required String key,
  required List<PickItem> items,
}) => PickSpec(
  key: key,
  loader: () async => PickList(items),
  searchHint: mediaText(context, 'Search players'),
  noGroup: '',
  byGroupName: false,
  chips: false,
  headings: false,
);

/// [rooms] lists every Sonos room on its own, as the speaker selection
/// pill does.
Future<PickList?> _loadPlayers(
  CommandRegistry commands,
  String source,
  bool speakers,
  bool rooms,
) async {
  final result = await commands.execute('mediaPlayers', {
    'source': source,
    if (speakers) 'speakers': true,
    if (rooms) 'rooms': true,
  });
  if (!result.ok) {
    return PickList(const [], notes: {source: result.error ?? ''});
  }
  final data = result.data;
  if (data is! Map) return null;
  final players = (data['players'] as List?) ?? const [];
  final notes = (data['notes'] as Map?) ?? const {};
  final items = <PickItem>[];
  for (final p in players.whereType<Map>()) {
    if (p['group'] != source) continue;
    final id = '${p['id']}';
    final available = p['available'] != false;
    final ha = id.startsWith('ha:');
    final sub = p['sub'];
    items.add(
      PickItem(
        id: id,
        name: '${p['name'] ?? id}',
        sub: sub != null
            ? '$sub'
            : ha
            ? id.substring(3)
            : null,
        subMono: sub == null && ha,
        // Offline is drawn, not stored: the list outlives a language switch.
        icon: '$sub'.contains(',') ? 'mdi:speaker-multiple' : 'mdi:speaker',
        group: source,
        available: available,
        raw: p.cast<String, Object?>(),
      ),
    );
  }
  final note = notes[source];
  return PickList(items, notes: {if (note != null) source: '$note'});
}

/// The outcome of a single pick: the id, or null when Clear was pressed.
typedef PickOutcome = ({String? id});

/// The picker as a dialog: the source's rows grouped under their headings,
/// a search and chips on top, Cancel (and Clear where the setting can be
/// empty) below. Under 640 it fills the screen. A tap picks and closes.
/// Null when dismissed.
Future<PickOutcome?> showItemPicker(
  BuildContext context, {
  required String title,
  required PickSpec spec,
  String? selected,
  bool allowClear = false,
}) => showDialog<PickOutcome>(
  context: context,
  barrierDismissible: false,
  builder: (context) => PickerDialog<PickOutcome>(
    title: title,
    builder: (close) => ItemPicker(
      title: title,
      spec: spec,
      selected: [?selected],
      onPick: (id) => close((id: id)),
      onClear: allowClear ? () => close((id: null)) : null,
      onClose: () => close(null),
    ),
  ),
);

/// Several at once (At a Glance): checkboxes, the picks in order on the
/// right, at most [max]. Resolves to the picks in order, null when
/// dismissed.
Future<List<String>?> showItemMultiPicker(
  BuildContext context, {
  required String title,
  required PickSpec spec,
  List<String> selected = const [],
  int? max,
}) => showDialog<List<String>>(
  context: context,
  barrierDismissible: false,
  builder: (context) => PickerDialog<List<String>>(
    title: title,
    builder: (close) => ItemPicker(
      title: title,
      spec: spec,
      selected: selected,
      multiple: true,
      max: max,
      onDone: close,
      onClose: () => close(null),
    ),
  ),
);

/// The entity picker: [showItemPicker] over Home Assistant's entities.
Future<PickOutcome?> showEntityPicker(
  BuildContext context,
  AppContainer container, {
  required String title,
  String? selected,
  List<String> domains = const [],
  String? deviceClass,
  bool allowClear = false,
}) => showItemPicker(
  context,
  title: title,
  spec: entitySpec(
    context,
    container.commands,
    domains: domains,
    deviceClass: deviceClass,
  ),
  selected: selected,
  allowClear: allowClear,
);

/// The picker's body: in a [PickerDialog] through [showItemPicker].
class ItemPicker extends StatefulWidget {
  const ItemPicker({
    super.key,
    required this.title,
    required this.spec,
    this.selected = const [],
    this.multiple = false,
    this.max,
    this.onPick,
    this.onClear,
    this.onDone,
    this.onClose,
  });

  final String title;
  final PickSpec spec;
  final List<String> selected;
  final bool multiple;
  final int? max;
  final ValueChanged<String>? onPick;
  final VoidCallback? onClear;
  final ValueChanged<List<String>>? onDone;
  final VoidCallback? onClose;

  @override
  State<ItemPicker> createState() => _ItemPickerState();
}

class _ItemPickerState extends State<ItemPicker> {
  late PickList? _list = PickCatalog.of(widget.spec.key).value;
  bool _loading = false;
  bool _failed = false;
  late final List<String> _picked = [...widget.selected];
  final _search = TextEditingController();
  String _query = '';
  String? _chip;
  final _scroll = ScrollController();
  bool _scrolledToPick = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final list = await PickCatalog.load(widget.spec.key, widget.spec.loader);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (list != null) {
        _list = list;
      } else if (_list == null) {
        _failed = true;
      }
    });
  }

  List<PickItem> get _kept {
    final keep = widget.spec.keep;
    final items = _list?.items ?? const <PickItem>[];
    return keep == null ? items : items.where(keep).toList();
  }

  bool get _full =>
      widget.multiple && widget.max != null && _picked.length >= widget.max!;

  void _tap(PickItem item) {
    if (!widget.multiple) {
      widget.onPick?.call(item.id);
      return;
    }
    setState(() {
      if (_picked.contains(item.id)) {
        _picked.remove(item.id);
      } else if (!_full) {
        _picked.add(item.id);
      }
    });
  }

  /// The rows on show: the chip's, then the search's, best match first;
  /// grouped and in name order when nothing is typed.
  List<_Entry> _entries(List<PickItem> kept) {
    var items = kept;
    if (_chip != null) items = items.where((i) => i.chip == _chip).toList();
    final q = _query.toLowerCase();
    if (q.isNotEmpty) {
      final hits = <(int, PickItem)>[];
      for (final i in items) {
        final name = i.name.toLowerCase();
        final sub = (i.sub ?? '').toLowerCase();
        final group = i.group.toLowerCase();
        if (!name.contains(q) && !sub.contains(q) && !group.contains(q)) {
          continue;
        }
        final rank = name.startsWith(q) || sub.split('.').last.startsWith(q)
            ? 0
            : name.contains(q)
            ? 1
            : 2;
        hits.add((rank, i));
      }
      hits.sort((a, b) {
        final r = a.$1.compareTo(b.$1);
        return r != 0
            ? r
            : a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase());
      });
      return [for (final h in hits) _Entry.item(h.$2)];
    }
    final groups = <String, List<PickItem>>{};
    for (final i in items) {
      groups.putIfAbsent(i.group, () => []).add(i);
    }
    final notes = _chip == null
        ? (_list?.notes ?? const {})
        : const <String, String>{};
    for (final g in notes.keys) {
      groups.putIfAbsent(g, () => []);
    }
    List<String> order;
    final given = _list?.groupOrder;
    if (!widget.spec.byGroupName && given != null) {
      order = [
        for (final g in given)
          if (groups.containsKey(g)) g,
        for (final g in groups.keys)
          if (!given.contains(g)) g,
      ];
    } else {
      order = groups.keys.toList()
        ..sort((a, b) {
          if (a.isEmpty != b.isEmpty) return a.isEmpty ? 1 : -1;
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
    }
    return [
      for (final g in order) ...[
        // Rows outside every group go without a heading when the source
        // has no name for them.
        if (widget.spec.headings &&
            (order.length > 1 || g.isNotEmpty) &&
            (g.isNotEmpty || widget.spec.noGroup.isNotEmpty))
          _Entry.heading(
            g.isEmpty ? widget.spec.noGroup : g,
            groups[g]!.length,
          ),
        if (notes[g] != null)
          _Entry.note(
            widget.spec.noteText?.call(context, notes[g]!) ?? notes[g]!,
          ),
        for (final i
            in groups[g]!..sort((a, b) {
              if (!widget.spec.byGroupName) return 0;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            }))
          _Entry.item(i),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 520;
        final kept = _kept;
        final chips = <String>{
          for (final i in kept)
            if (i.chip != null && i.chip!.isNotEmpty) i.chip!,
        }.toList()..sort();
        final showChips = widget.spec.chips && chips.length > 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, wide),
            if (showChips && _list != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  wide ? 0 : 12,
                  0,
                  wide ? 0 : 12,
                  8,
                ),
                child: _Chips(
                  all: haText(context, 'All'),
                  chips: chips,
                  active: _chip,
                  onPick: (c) => setState(() => _chip = c),
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _content(context, kept, wide)),
                  if (widget.multiple && wide) _showing(context),
                ],
              ),
            ),
            _footer(context, wide),
          ],
        );
      },
    );
  }

  Widget _searchBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    );
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v.trim()),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14.5),
        decoration: InputDecoration(
          hintText: widget.spec.searchHint,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).deleteButtonTooltip,
                  onPressed: () => setState(() {
                    _search.clear();
                    _query = '';
                  }),
                ),
          border: pill,
          enabledBorder: pill,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool wide) {
    final theme = Theme.of(context);
    final ready = _list != null && _list!.items.isNotEmpty;
    if (wide) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (ready) ...[
              const SizedBox(width: 16),
              SizedBox(width: 300, child: _searchBox(context)),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: widget.onClose,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
        if (ready)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: _searchBox(context),
          ),
      ],
    );
  }

  Widget _content(BuildContext context, List<PickItem> kept, bool wide) {
    if (_list == null) {
      if (_failed) {
        return _Message(
          icon: Icons.link_off,
          title: haText(context, 'Could not reach Home Assistant'),
          message: haText(
            context,
            'The entities load once the connection is back.',
          ),
          action: OutlinedButton.icon(
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(haText(context, 'Try again')),
          ),
        );
      }
      return const _Skeleton();
    }
    final entries = _entries(kept);
    if (entries.isEmpty) {
      final empty = _list!.items.isEmpty ? widget.spec.emptyText : null;
      return _Message(
        icon: Icons.search_off,
        title: empty?.call(context) ?? haText(context, 'Nothing matches'),
      );
    }
    if (widget.spec.grid) {
      var items = [
        for (final e in entries)
          if (e.item != null) e.item!,
      ];
      final limit = widget.spec.limit;
      if (limit != null && items.length > limit) {
        if (_query.isEmpty && _picked.isNotEmpty) {
          items = [
            for (final i in items)
              if (_picked.contains(i.id)) i,
            for (final i in items)
              if (!_picked.contains(i.id)) i,
          ];
        }
        items = items.take(limit).toList();
      }
      return _grid(context, items, wide);
    }
    if (!_scrolledToPick && _picked.isNotEmpty && _query.isEmpty) {
      _scrolledToPick = true;
      final first = entries.indexWhere(
        (e) => e.item != null && _picked.contains(e.item!.id),
      );
      if (first > 3) {
        var offset = 0.0;
        for (final e in entries.take(first)) {
          offset += e.item != null ? _ItemRow.height : _Heading.height;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(
              (offset - 60).clamp(0.0, _scroll.position.maxScrollExtent),
            );
          }
        });
      }
    }
    return EdgeFade(
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(wide ? 0 : 8, 0, wide ? 4 : 8, 8),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final e = entries[i];
          if (e.heading != null) return _Heading(e.heading!, e.count);
          if (e.note != null) return _Note(e.note!);
          final item = e.item!;
          final picked = _picked.contains(item.id);
          return _ItemRow(
            item: item,
            picked: picked,
            multiple: widget.multiple,
            disabled: widget.multiple && !picked && _full,
            query: _query,
            icon: wide,
            onTap: () => _tap(item),
          );
        },
      ),
    );
  }

  /// Tiles at least [_GridCell.width] wide, as many as fit, the way the
  /// remote admin's icon picker lays them out. Opens on the picked one.
  Widget _grid(BuildContext context, List<PickItem> items, bool wide) {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 6.0;
        final side = wide ? 0.0 : 8.0;
        final columns =
            ((box.maxWidth - 2 * side + gap) / (_GridCell.width + gap))
                .floor()
                .clamp(1, 1000);
        if (!_scrolledToPick && _picked.isNotEmpty && _query.isEmpty) {
          _scrolledToPick = true;
          final first = items.indexWhere((i) => _picked.contains(i.id));
          final row = first ~/ columns;
          if (row > 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scroll.hasClients) {
                _scroll.jumpTo(
                  ((row - 1) * (_GridCell.height + gap)).clamp(
                    0.0,
                    _scroll.position.maxScrollExtent,
                  ),
                );
              }
            });
          }
        }
        return EdgeFade(
          child: GridView.builder(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(side, 0, side, 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: _GridCell.height,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _GridCell(
              item: items[i],
              picked: _picked.contains(items[i].id),
              onTap: () => _tap(items[i]),
            ),
          ),
        );
      },
    );
  }

  /// Several mode on a roomy pane: the picks in order, reorderable.
  Widget _showing(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _list;
    return Container(
      width: 290,
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              widget.max == null
                  ? l10n(context).dashboardPickerSelected('${_picked.length}')
                  : l10n(
                      context,
                    ).entityPickerShowing('${_picked.length}', '${widget.max}'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: ReorderableListView(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) => setState(() {
                _picked.insert(to, _picked.removeAt(from));
              }),
              children: [
                for (final (i, id) in _picked.indexed)
                  _ShowingRow(
                    key: ValueKey(id),
                    index: i,
                    item: list?.find(id),
                    id: id,
                    first: i == 0,
                    last: i == _picked.length - 1,
                    onUp: () => setState(() {
                      _picked.insert(i - 1, _picked.removeAt(i));
                    }),
                    onDown: () => setState(() {
                      _picked.insert(i + 1, _picked.removeAt(i));
                    }),
                  ),
              ],
            ),
          ),
          if (_picked.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                haText(context, 'Drag or use the arrows to change the order.'),
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, bool wide) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: wide ? null : const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(top: 14, bottom: wide ? 0 : 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (widget.onClear != null)
            TextButton(
              onPressed: widget.onClear,
              child: Text(haText(context, 'Clear')),
            ),
          Expanded(
            child: widget.multiple
                ? Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _full
                          ? haText(context, 'Remove one to add another.')
                          : l10n(
                              context,
                            ).dashboardPickerSelected('${_picked.length}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          TextButton(
            onPressed: widget.onClose,
            child: Text(haText(context, 'Cancel')),
          ),
          if (widget.multiple) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => widget.onDone?.call(List.of(_picked)),
              child: Text(haText(context, 'Done')),
            ),
          ],
        ],
      ),
    );
  }
}

/// One tile of a grid picker: the icon over its label, tinted when picked.
class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.item,
    required this.picked,
    required this.onTap,
  });

  static const width = 88.0;
  static const height = 76.0;

  final PickItem item;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = picked ? scheme.primary : scheme.onSurface;
    final label = item.sub ?? item.name;
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: picked ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(Ks.radiusControl),
        child: InkWell(
          borderRadius: BorderRadius.circular(Ks.radiusControl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PickIcon(icon: item.icon, size: 28, color: color),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Entry {
  _Entry.heading(this.heading, this.count) : item = null, note = null;
  _Entry.note(this.note) : item = null, heading = null, count = 0;
  _Entry.item(this.item) : heading = null, note = null, count = 0;

  final String? heading;
  final String? note;
  final int count;
  final PickItem? item;
}

// ── Pieces ───────────────────────────────────────────────────────────────

/// What shows on the right of an item: its state, or Offline for a player
/// that is, translated as it is drawn since the list outlives a language
/// switch.
String? _stateOf(BuildContext context, PickItem item) {
  final state = item.state;
  if (state != null && state.isNotEmpty) return state;
  return item.available ? null : mediaText(context, 'Offline');
}

/// An item's icon: its MDI icon, else a generic one.
class PickIcon extends StatelessWidget {
  const PickIcon({
    super.key,
    this.icon,
    required this.size,
    required this.color,
  });

  final String? icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final name = icon;
    if (name != null && MdiIcons.looksLikeIcon(name)) {
      return MdiIcon(
        name: name,
        size: size,
        color: color,
        fallback: Icons.category_outlined,
      );
    }
    return Icon(Icons.category_outlined, size: size, color: color);
  }
}

Widget _disc(
  BuildContext context,
  String? icon, {
  required bool picked,
  double size = 40,
}) {
  final scheme = Theme.of(context).colorScheme;
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: picked ? scheme.surface : scheme.surfaceContainerHighest,
    ),
    alignment: Alignment.center,
    child: PickIcon(
      icon: icon,
      size: size * 0.55,
      color: picked ? scheme.primary : scheme.onSurfaceVariant,
    ),
  );
}

class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, this.query, {required this.style});

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final i = query.isEmpty
        ? -1
        : text.toLowerCase().indexOf(query.toLowerCase());
    if (i < 0) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final tint = Theme.of(context).colorScheme.primaryContainer;
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, i)),
          TextSpan(
            text: text.substring(i, i + query.length),
            style: TextStyle(backgroundColor: tint),
          ),
          TextSpan(text: text.substring(i + query.length)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.picked,
    required this.onTap,
    this.multiple = false,
    this.disabled = false,
    this.query = '',
    this.icon = true,
  });

  static const double height = 58;

  final PickItem item;
  final bool picked;
  final bool multiple;
  final bool disabled;
  final String query;
  final VoidCallback onTap;

  /// False on a phone: the width goes to the names.
  final bool icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(Ks.radiusRow);
    final dim = disabled || !item.available;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Opacity(
        opacity: dim ? 0.5 : 1,
        child: Material(
          color: picked ? scheme.primaryContainer : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: disabled ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (multiple) ...[
                    Checkbox(
                      value: picked,
                      onChanged: disabled ? null : (_) => onTap(),
                    ),
                    const SizedBox(width: 2),
                  ],
                  if (icon) ...[
                    _disc(context, item.icon, picked: picked),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: _Highlighted(
                                item.name,
                                query,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: picked
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            // An entity Home Assistant hides, marked the way
                            // Home Assistant marks it.
                            if (item.raw['hidden'] == true) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.visibility_off,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                        if (item.sub != null && item.sub!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          _Highlighted(
                            item.sub!,
                            query,
                            style: TextStyle(
                              fontFamily: item.subMono ? 'monospace' : null,
                              fontSize: item.subMono ? 11.5 : 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_stateOf(context, item) case final state?) ...[
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        state,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  if (picked && !multiple) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.check, size: 22, color: scheme.primary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.count);

  static const double height = 38;

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Row(
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(fontSize: 13, color: scheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// The filter chips: All, then the sources' or domains' names. One line,
/// scrolling sideways under the edge fade.
class _Chips extends StatelessWidget {
  const _Chips({
    required this.all,
    required this.chips,
    required this.active,
    required this.onPick,
  });

  final String all;
  final List<String> chips;
  final String? active;
  final ValueChanged<String?> onPick;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? value) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active == value,
        showCheckmark: false,
        onSelected: (_) => onPick(value),
      ),
    );
    return SizedBox(
      height: 40,
      child: EdgeFade(
        axis: Axis.horizontal,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [chip(all, null), for (final c in chips) chip(c, c)],
        ),
      ),
    );
  }
}

class _ShowingRow extends StatelessWidget {
  const _ShowingRow({
    super.key,
    required this.index,
    required this.item,
    required this.id,
    required this.first,
    required this.last,
    required this.onUp,
    required this.onDown,
  });

  final int index;
  final PickItem? item;
  final String id;
  final bool first;
  final bool last;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_indicator, size: 20, color: scheme.outline),
          ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: PickIcon(icon: item?.icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item?.name ?? id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l10n(context).commonMoveUp,
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: first ? null : onUp,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l10n(context).commonMoveDown,
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: last ? null : onDown,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerHighest,
              ),
              child: Icon(icon, size: 34, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Placeholder rows while the list loads, never a bare spinner.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        children: [
          for (var i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: fill,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(150, 12),
                      const SizedBox(height: 6),
                      bar(200, 9),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── The value step ───────────────────────────────────────────────────────

/// Attributes that are presentation metadata rather than values anyone
/// would put on the row or in a corner. Structured values (lists, maps)
/// are skipped too: a forecast array is not a glanceable reading.
const _hiddenAttributes = {
  'friendly_name',
  'icon',
  'entity_picture',
  'supported_features',
  'attribution',
};

/// What an entity displays: its state (the default) or one of its
/// attributes (issue #132), each shown with its current value. Returns the
/// attribute name, '' for the state, null when dismissed.
Future<String?> showEntityValuePicker(
  BuildContext context,
  AppContainer container, {
  required String entityId,
  required String current,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  builder: (context) => PickerDialog<String>(
    title: screensaverText(context, 'Displayed value'),
    builder: (close) => _ValueStep(
      container: container,
      entityId: entityId,
      current: current,
      onPick: close,
      onClose: () => close(null),
    ),
  ),
);

class _ValueStep extends StatefulWidget {
  const _ValueStep({
    required this.container,
    required this.entityId,
    required this.current,
    required this.onPick,
    required this.onClose,
  });

  final AppContainer container;
  final String entityId;
  final String current;
  final ValueChanged<String> onPick;
  final VoidCallback onClose;

  @override
  State<_ValueStep> createState() => _ValueStepState();
}

class _ValueStepState extends State<_ValueStep> {
  Map<String, Object?>? _attributes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    final result = await widget.container.commands.execute(
      'haEntityAttributes',
      {'entity_id': widget.entityId},
    );
    if (!mounted) return;
    setState(() {
      if (result.ok && result.data is Map) {
        _attributes = (result.data as Map).cast<String, Object?>();
      } else {
        _failed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = PickCatalog.of('entities').value?.find(widget.entityId);
    final attributes = _attributes;
    final names = attributes == null
        ? const <String>[]
        : ([
            for (final e in attributes.entries)
              if (e.value is! Map &&
                  e.value is! List &&
                  !_hiddenAttributes.contains(e.key))
                e.key,
          ]..sort());
    final current = widget.current.isEmpty || names.contains(widget.current)
        ? widget.current
        : '';
    Widget option(String value, String label, String? reading) {
      final on = value == current;
      final radius = BorderRadius.circular(Ks.radiusRow);
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Material(
          color: on ? scheme.primaryContainer : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () => widget.onPick(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      on
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: on ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (reading != null) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        reading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 520;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: wide ? 48 : 56,
              child: Row(
                children: [
                  if (!wide)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: widget.onClose,
                    ),
                  Expanded(
                    child: Text(
                      screensaverText(context, 'Displayed value'),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(wide ? 0 : 12, 4, wide ? 0 : 12, 12),
              child: Row(
                children: [
                  _disc(context, item?.icon, picked: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item?.name ?? widget.entityId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.entityId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: attributes == null
                  ? (_failed
                        ? _Message(
                            icon: Icons.link_off,
                            title: haText(
                              context,
                              'Could not reach Home Assistant',
                            ),
                            action: OutlinedButton.icon(
                              onPressed: _load,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: Text(haText(context, 'Try again')),
                            ),
                          )
                        : const _Skeleton())
                  : EdgeFade(
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 8),
                        children: [
                          option(
                            '',
                            screensaverText(context, 'State'),
                            item?.state,
                          ),
                          for (final n in names)
                            option(n, n, '${attributes[n]}'),
                        ],
                      ),
                    ),
            ),
            Container(
              margin: wide ? null : const EdgeInsets.symmetric(horizontal: 12),
              padding: EdgeInsets.only(top: 14, bottom: wide ? 0 : 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onClose,
                    child: Text(haText(context, 'Cancel')),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── The field ────────────────────────────────────────────────────────────

/// A stored pick at rest: the control box with the item's icon, its name
/// and its state. Empty reads [placeholder]. A pick the loaded list no
/// longer has shows its id with an error border. Before the list loads,
/// the id stands in.
class PickField extends StatelessWidget {
  const PickField({
    super.key,
    required this.value,
    required this.list,
    required this.placeholder,
    required this.onTap,
    this.detail,
    this.enabled = true,
    this.fallbackLabel,
    this.flagMissing = true,
    this.emptyIsPick = false,
  });

  final String value;
  final PickList? list;
  final String placeholder;
  final VoidCallback onTap;

  /// The empty value is a pick of its own (this device's Sendspin player),
  /// drawn with its item's icon and name once the list has it.
  final bool emptyIsPick;

  /// Shown for a pick the list does not have (or has not loaded) in
  /// place of its id: the name the setting kept.
  final String? fallbackLabel;

  /// False never marks a pick the list lacks: a player can be away for a
  /// while and come back.
  final bool flagMissing;

  /// Shown after the name instead of the state: a chosen attribute.
  final String? detail;
  final bool enabled;

  static bool missing(String value, PickList? list) =>
      value.isNotEmpty && list != null && list.find(value) == null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = value.isEmpty && !emptyIsPick ? null : list?.find(value);
    final gone = flagMissing && missing(value, list);
    Widget lead;
    Widget text;
    String? trailing;
    if (value.isEmpty && item == null) {
      lead = Icon(
        Icons.category_outlined,
        size: 20,
        color: scheme.onSurfaceVariant,
      );
      text = Text(
        placeholder,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
      );
    } else if (item == null && fallbackLabel != null && !gone) {
      lead = Icon(
        Icons.category_outlined,
        size: 20,
        color: scheme.onSurfaceVariant,
      );
      text = Text(
        fallbackLabel!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, color: scheme.onSurface),
      );
    } else if (item == null) {
      lead = gone
          ? Icon(Icons.warning_amber_rounded, size: 20, color: scheme.error)
          : Icon(
              Icons.category_outlined,
              size: 20,
              color: scheme.onSurfaceVariant,
            );
      text = Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          color: scheme.onSurface,
        ),
      );
    } else {
      lead = PickIcon(icon: item.icon, size: 20, color: scheme.primary);
      text = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: item.name),
            if (detail != null && detail!.isNotEmpty) ...[
              TextSpan(
                text: ' · ',
                style: TextStyle(color: scheme.outline),
              ),
              TextSpan(
                text: detail,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 15, color: scheme.onSurface),
      );
      if (detail == null || detail!.isEmpty) trailing = _stateOf(context, item);
    }
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: ControlBox(
        onTap: enabled ? onTap : null,
        borderColor: gone ? scheme.error : null,
        child: Row(
          children: [
            lead,
            const SizedBox(width: 10),
            Expanded(child: text),
            if (trailing != null && trailing.isNotEmpty) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// A settings row whose value is a pick: the name, a [PickField] (300 wide,
/// across the row on a tight pane) and the description, with a line in
/// error color when the stored pick is gone. Loads [spec]'s list the
/// first time one is shown.
class PickRow extends StatefulWidget {
  const PickRow({
    super.key,
    required this.title,
    required this.spec,
    required this.value,
    required this.onPick,
    this.description,
    this.placeholder,
    this.allowClear = false,
    this.detail,
    this.missingText,
    this.enabled = true,
    this.dialogTitle,
    this.fallbackLabel,
    this.flagMissing = true,
    this.emptyIsPick = false,
  });

  final String title;
  final String? description;
  final PickSpec spec;
  final String value;

  /// The picked id, or null when Clear was pressed.
  final ValueChanged<String?> onPick;
  final String? placeholder;
  final bool allowClear;
  final String? detail;
  final String? missingText;
  final bool enabled;
  final String? dialogTitle;
  final String? fallbackLabel;
  final bool flagMissing;

  /// The empty value is a pick of its own (this device's Sendspin player),
  /// checked in the list.
  final bool emptyIsPick;

  @override
  State<PickRow> createState() => _PickRowState();
}

class _PickRowState extends State<PickRow> {
  @override
  void initState() {
    super.initState();
    if (PickCatalog.of(widget.spec.key).value == null) {
      PickCatalog.load(widget.spec.key, widget.spec.loader);
    }
  }

  Future<void> _open() async {
    final outcome = await showItemPicker(
      context,
      title: widget.dialogTitle ?? widget.title,
      spec: widget.spec,
      selected: widget.value.isEmpty && !widget.emptyIsPick
          ? null
          : widget.value,
      allowClear: widget.allowClear,
    );
    if (outcome == null) return;
    if (outcome.id == widget.value) return;
    widget.onPick(outcome.id);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PickList?>(
      valueListenable: PickCatalog.of(widget.spec.key),
      builder: (context, list, _) {
        final error = Theme.of(context).colorScheme.error;
        final gone =
            widget.flagMissing && PickField.missing(widget.value, list);
        final field = PickField(
          value: widget.value,
          list: list,
          fallbackLabel: widget.fallbackLabel,
          flagMissing: widget.flagMissing,
          emptyIsPick: widget.emptyIsPick,
          placeholder:
              widget.placeholder ?? haText(context, 'Choose an entity'),
          detail: widget.detail,
          enabled: widget.enabled,
          onTap: _open,
        );
        final tight = tightPane(context);
        return SettingsRow(
          title: Text(widget.title),
          stack: true,
          enabled: widget.enabled,
          subtitle: widget.description == null && !gone
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (gone)
                      Text(
                        widget.missingText ??
                            haText(
                              context,
                              'This entity is gone from Home Assistant. Choose another.',
                            ),
                        style: TextStyle(color: error),
                      ),
                    if (widget.description != null) Text(widget.description!),
                  ],
                ),
          trailing: tight ? field : SizedBox(width: 300, child: field),
        );
      },
    );
  }
}

/// One stored entity in a list (the At a Glance picks): icon, name, then
/// the displayed value. The id stands in until the list loads, or when
/// the entity is gone.
class PickListRow extends StatelessWidget {
  const PickListRow({
    super.key,
    required this.specKey,
    required this.value,
    this.name,
    this.detail,
    this.trailing,
    this.onTap,
  });

  final String specKey;
  final String value;

  /// A name of its own, shown in place of the item's.
  final String? name;
  final String? detail;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PickList?>(
      valueListenable: PickCatalog.of(specKey),
      builder: (context, list, _) {
        final scheme = Theme.of(context).colorScheme;
        final item = list?.find(value);
        final gone = list != null && item == null;
        final second = [
          if (detail != null && detail!.isNotEmpty) detail!,
          if (item?.state != null && (detail == null || detail!.isEmpty))
            item!.state!,
        ].join();
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Ks.inset, 8, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest,
                  ),
                  alignment: Alignment.center,
                  child: gone
                      ? Icon(
                          Icons.warning_amber_rounded,
                          size: 22,
                          color: scheme.error,
                        )
                      : PickIcon(
                          icon: item?.icon,
                          size: 22,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? item?.name ?? value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        second.isEmpty ? value : '$second · $value',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A [PickField] that loads and follows [spec]'s list on its own, for a
/// field inside a dialog (a widget's entity, a gesture's script).
class PickFieldBox extends StatefulWidget {
  const PickFieldBox({
    super.key,
    required this.spec,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.detail,
    this.enabled = true,
  });

  final PickSpec spec;
  final String value;
  final VoidCallback onTap;
  final String? placeholder;
  final String? detail;
  final bool enabled;

  @override
  State<PickFieldBox> createState() => _PickFieldBoxState();
}

class _PickFieldBoxState extends State<PickFieldBox> {
  @override
  void initState() {
    super.initState();
    if (PickCatalog.of(widget.spec.key).value == null) {
      PickCatalog.load(widget.spec.key, widget.spec.loader);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PickList?>(
    valueListenable: PickCatalog.of(widget.spec.key),
    builder: (context, list, _) => PickField(
      value: widget.value,
      list: list,
      placeholder: widget.placeholder ?? haText(context, 'Choose an entity'),
      detail: widget.detail,
      enabled: widget.enabled,
      onTap: widget.onTap,
    ),
  );
}

/// A plain choice at rest in the control box, opening a picker: the
/// Displayed value of an entity.
class ChoiceBox extends StatelessWidget {
  const ChoiceBox({super.key, required this.text, required this.onTap});

  final String text;

  /// Null disables the box.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.38 : 1,
      child: ControlBox(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, color: scheme.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
