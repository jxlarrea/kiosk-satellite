import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../managers/settings/definitions.dart';

/// Settings search, One UI style: one index over everything the Settings
/// panes can show, built from the declarative definitions plus a short list
/// of hand-built rows the definitions do not cover. The remote admin UI
/// carries the same feature over the same data (it renders from
/// GET /api/settings); its hand-built list mirrors [handBuiltSearchEntries].

/// One searchable row. Definition-backed entries carry their [defKey];
/// hand-built rows and the category pages themselves carry an anchor id (or
/// none, which lands on the top of the category).
class SettingsSearchEntry {
  const SettingsSearchEntry({
    required this.category,
    required this.title,
    required this.description,
    this.defKey,
    this.isPage = false,
    this.anchorId,
    this.subpage,
  });

  /// The definitions category ('Home Assistant'), which is also the pane the
  /// result opens.
  final String category;
  final String title;
  final String description;

  /// Set for entries backed by a [SettingDef]; lets the landing resolver walk
  /// the dependsOn chain when the row is currently gated off.
  final String? defKey;

  /// The category page itself as a result ("Screensaver"), matching One UI,
  /// where pages are findable alongside their settings.
  final bool isPage;

  /// Where tapping the result scrolls to when the entry is not backed by a
  /// definition; null means the top of the pane. Definition-backed entries
  /// resolve their landing from [defKey] instead (see [resolveSearchAnchor]).
  final String? anchorId;

  /// The second-level page this row is on, for hand-built rows that moved
  /// onto one. Definition-backed entries take it from the definition
  /// instead, and page entries leave it null: they land on the entry row,
  /// which is on the page above.
  final String? subpage;
}

/// Rows both UIs hand-build outside the definitions, so a search for
/// "permissions" or "export" still lands somewhere. Mirrored in the remote
/// admin's SEARCH_EXTRAS; keep the two lists in step.
const List<SettingsSearchEntry> handBuiltSearchEntries = [
  SettingsSearchEntry(
    category: 'Home Assistant',
    title: 'Validate connection',
    description: 'Check the URL and token against your Home Assistant.',
    anchorId: 'x:ha_validate',
  ),
  SettingsSearchEntry(
    category: 'Home Assistant',
    title: 'Secure context proxy',
    description:
        'Serve a plain-http Home Assistant through a secure proxy inside '
        'the app.',
    anchorId: 'x:secure_proxy',
  ),
  SettingsSearchEntry(
    category: 'Home Assistant',
    title: 'Dashboard',
    description: 'Pick the dashboard and view the kiosk shows.',
    anchorId: 'x:dashboard_picker',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Assigned satellite',
    description:
        'The assist_satellite entity this kiosk identifies as in Home '
        'Assistant.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Auto start',
    description: 'Auto start Voice Satellite on dashboard load.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Assist pipeline 1',
    description: 'The Assist pipeline voice commands run through.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Assist pipeline 2',
    description: 'The pipeline used when the second wake word triggers.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Engine',
    description: 'Start or Stop the Voice Satellite engine.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Mute',
    description: 'Stop listening for wake words.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Finished speaking detection',
    description: 'How long a pause ends a voice command.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Debug logging',
    description: 'Show Voice Satellite debug info in the browser console.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Voice Satellite version',
    description: 'The integration version installed in Home Assistant.',
    anchorId: 'x:assigned_satellite',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Wake word engine',
    description: 'Where detection runs and which engine listens.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Wake word sensitivity',
    description: 'How easily the wake word triggers.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Wake word noise gate',
    description:
        'Skip local wake word inference while the room is quiet, saving CPU.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Stop word interruption',
    description: 'Say the stop word to interrupt responses.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Wake word 1',
    description: 'The word that starts a voice command.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Wake word 2',
    description: 'A second wake word, answered by Assist pipeline 2.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Cached models',
    description:
        'Re-download from Home Assistant. Use after re-publishing a model.',
    anchorId: 'x:vs_wake',
    subpage: 'Wake Word',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Skin',
    description: 'The look of the voice assistant overlay.',
    anchorId: 'x:vs_appearance',
    subpage: 'Appearance',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Theme mode',
    description: 'Light or dark rendering of the overlay.',
    anchorId: 'x:vs_appearance',
    subpage: 'Appearance',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Reactive activity bar',
    description:
        'The activity bar reacts to audio. NOT RECOMMENDED for low-power devices like the Echo Show.',
    anchorId: 'x:vs_appearance',
    subpage: 'Appearance',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Reactive bar update rate',
    description:
        'How often the activity bar redraws. Higher is smoother and uses '
        'more CPU.',
    anchorId: 'x:vs_appearance',
    subpage: 'Appearance',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Text scale',
    description: 'The size of the overlay text.',
    anchorId: 'x:vs_appearance',
    subpage: 'Appearance',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Wake Word Tester',
    description: 'A live look at what the engine hears and scores.',
    anchorId: 'x:wake_word_tester',
  ),
  SettingsSearchEntry(
    category: 'Voice Satellite',
    title: 'Required system permissions',
    description: 'Microphone and the other grants wake word detection needs.',
    anchorId: 'x:vs_permissions',
  ),
  SettingsSearchEntry(
    category: 'Kiosk',
    title: 'Required system permissions',
    description: 'The grants the kiosk and lockdown protections lean on.',
    anchorId: 'x:kiosk_permissions',
  ),
  SettingsSearchEntry(
    category: 'Kiosk',
    title: 'Lockdown Mode',
    description:
        'Remote-only touch shield. Set it up from the Remote Admin UI; its '
        'grants live under Required system permissions.',
    anchorId: 'x:kiosk_permissions',
  ),
  SettingsSearchEntry(
    category: 'Screen & Audio',
    title: 'Master volume',
    description:
        'The device volume the media and assistant faders scale '
        'under.',
    anchorId: 'x:master_volume',
  ),
  // The small clock is a Widgets entry now, but "clock" is still what
  // people search for.
  SettingsSearchEntry(
    category: 'Screensaver',
    title: 'Small clock',
    description: 'A clock widget in a corner of the screensaver.',
    defKey: 'screensaver.widgets',
  ),
  SettingsSearchEntry(
    category: 'Screensaver',
    title: 'Battery',
    description:
        'A battery widget in a corner of the screensaver: this device\'s '
        'own charge.',
    defKey: 'screensaver.widgets',
  ),
  SettingsSearchEntry(
    category: 'Device',
    title: 'Permissions Manager',
    description:
        'Every Android grant the app can use, with its status: microphone, '
        'camera, notifications, unrestricted battery, display over other '
        'apps, modify system settings, system UI guard, device admin, all '
        'files access, usage access and location.',
    anchorId: 'x:device_permissions',
  ),
  SettingsSearchEntry(
    category: 'Device',
    title: 'Export configuration',
    description: "Save every setting and the page's local storage to a file.",
    anchorId: 'x:export_config',
  ),
  SettingsSearchEntry(
    category: 'Device',
    title: 'Import configuration',
    description: "Replace this device's settings from an exported file.",
    anchorId: 'x:import_config',
  ),
  SettingsSearchEntry(
    category: 'ESPHome',
    title: 'Nearby devices',
    description:
        'The Bluetooth devices this kiosk hears, with names where known.',
    anchorId: 'x:btproxy_nearby',
    subpage: 'Bluetooth Proxy',
  ),
  SettingsSearchEntry(
    category: 'ESPHome',
    title: 'Required system permissions',
    description: 'The Nearby devices grant the Bluetooth proxy needs to scan.',
    anchorId: 'x:btproxy_permissions',
  ),
  SettingsSearchEntry(
    category: 'Sendspin',
    title: 'Player to control',
    description:
        'Show and control another Music Assistant player instead of this '
        'device.',
    anchorId: 'x:ma_player',
  ),
];

/// The full index: the category pages, every non-hidden definition whose
/// category has a pane here, and the hand-built rows. Built once per screen;
/// the definitions are const so there is nothing to refresh.
List<SettingsSearchEntry> buildSettingsSearchIndex(
  List<(String category, String title, String subtitle)> pages,
) {
  final categories = {for (final p in pages) p.$1};
  return [
    for (final (category, title, subtitle) in pages)
      SettingsSearchEntry(
        category: category,
        title: title,
        description: subtitle,
        isPage: true,
      ),
    // The second-level pages, findable like the category pages above; a
    // tapped result lands on the entry row that opens them.
    for (final subpage in {
      for (final def in allSettings)
        if (!def.hidden &&
            def.subpage != null &&
            categories.contains(def.category))
          (def.category, def.subpage!),
    })
      SettingsSearchEntry(
        category: subpage.$1,
        title: subpage.$2,
        description: subpageHints[subpage.$2] ?? '',
        anchorId: 'sub:${subpage.$2}',
        isPage: true,
      ),
    for (final def in allSettings)
      if (!def.hidden && categories.contains(def.category))
        SettingsSearchEntry(
          category: def.category,
          title: def.title,
          description: def.description,
          defKey: def.key,
        ),
    for (final entry in handBuiltSearchEntries)
      if (categories.contains(entry.category)) entry,
  ];
}

/// Match [query] against the index. Every whitespace-separated term must
/// appear in the entry's title or description; results come back grouped in
/// [categoryOrder] and, within a category, titles that start with the query
/// before titles that contain it before description-only matches.
List<SettingsSearchEntry> searchSettings(
  String query,
  List<SettingsSearchEntry> index,
  List<String> categoryOrder,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final terms = q.split(RegExp(r'\s+'));

  int? score(SettingsSearchEntry e) {
    final title = e.title.toLowerCase();
    final description = e.description.toLowerCase();
    final haystack = '$title $description';
    for (final term in terms) {
      if (!haystack.contains(term)) return null;
    }
    if (title.startsWith(q)) return 0;
    if (terms.every(title.contains)) return 1;
    return 2;
  }

  final scored =
      <(int categoryRank, int score, int order, SettingsSearchEntry)>[];
  for (final (order, entry) in index.indexed) {
    final s = score(entry);
    if (s == null) continue;
    final rank = categoryOrder.indexOf(entry.category);
    scored.add((rank < 0 ? categoryOrder.length : rank, s, order, entry));
  }
  scored.sort((a, b) {
    if (a.$1 != b.$1) return a.$1 - b.$1;
    if (a.$2 != b.$2) return a.$2 - b.$2;
    return a.$3 - b.$3;
  });
  return [for (final s in scored) s.$4];
}

/// Where a tapped result should land. A definition row that is currently
/// gated off (its dependsOn chain does not hold) has no row to scroll to, so
/// the landing walks up the chain to the nearest setting that is actually on
/// screen — the parent that turns the found one on, One UI's behavior.
/// Returns null to land on the top of the category pane.
String? resolveSearchAnchor(
  SettingsSearchEntry entry,
  bool Function(SettingDef<Object> def) isVisible,
) {
  if (entry.defKey == null) return entry.anchorId;
  final byKey = {for (final d in allSettings) d.key: d};
  var def = byKey[entry.defKey];
  // Hidden gates (bookkeeping flags like media_is_folder) never render, so
  // the walk skips them the same as an unsatisfied dependency.
  while (def != null && (def.hidden || !isVisible(def))) {
    def = def.dependsOn == null ? null : byKey[def.dependsOn!];
  }
  return def?.key;
}

/// Tells the settings panes which row a search result landed on. The pane
/// wraps its scrollable in this; every [SearchLandingTarget] below checks
/// whether it is the one being looked for. The epoch makes tapping the same
/// result twice land twice.
class SearchLandingScope extends InheritedWidget {
  const SearchLandingScope({
    super.key,
    required this.target,
    required this.epoch,
    required super.child,
  });

  final String? target;
  final int epoch;

  static SearchLandingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SearchLandingScope>();

  @override
  bool updateShouldNotify(SearchLandingScope oldWidget) =>
      target != oldWidget.target || epoch != oldWidget.epoch;
}

/// Marks one row (or card) as landable. When the ambient [SearchLandingScope]
/// names this target's [id], the row scrolls into view and blinks twice —
/// One UI's found-it flash — so the eye finds the setting the search did.
class SearchLandingTarget extends StatefulWidget {
  const SearchLandingTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<SearchLandingTarget> createState() => _SearchLandingTargetState();
}

class _SearchLandingTargetState extends State<SearchLandingTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  int _consumedEpoch = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = SearchLandingScope.maybeOf(context);
    if (scope == null ||
        scope.target != widget.id ||
        scope.epoch == _consumedEpoch) {
      return;
    }
    _consumedEpoch = scope.epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  Future<void> _reveal() async {
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.2,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    if (mounted) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        // Two soft blinks over the run: 0.5 - 0.5cos(4πt) peaks at t = ¼ and
        // t = ¾ and rests at both ends.
        final t = _pulse.value;
        final wave = t == 0 || t == 1
            ? 0.0
            : 0.5 - 0.5 * math.cos(t * 4 * math.pi);
        return ColoredBox(
          color: highlight.withValues(alpha: 0.12 * wave),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
