import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../core/logging.dart';
import '../managers/camera/models.dart' show CameraViewConfig;
import '../managers/launcher/app_launcher_manager.dart' show decodeLauncherApps;
import '../managers/screensaver/screensaver_widgets.dart';
import '../managers/settings/definitions.dart';
import '../managers/settings/export_filename.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';
import '../managers/wake_word/background_listening.dart';
import '../managers/wake_word/system_permissions.dart';
import '../managers/wake_word/engine.dart';
import 'color_picker.dart';
import 'gesture_settings.dart';
import 'glance_entity_picker.dart';
import 'camera_settings.dart';
import 'import_options_dialog.dart';
import 'kit.dart';
import 'media_picker.dart';
import 'theme.dart';
import 'mic_level_meter.dart';
import 'settings_search.dart';
import 'wake_word_tester.dart';

/// Render a category's settings as cards: consecutive settings sharing a
/// `section` become one card under one [SectionHeading]; unsectioned runs
/// share an unheaded card. Only visible settings appear.
List<Widget> _sectionedCards(
  AppContainer container,
  List<SettingDef<Object>> defs,
  VoidCallback onChanged, {
  // Extra widgets keyed by setting key, rendered inside the card directly
  // under that setting's row (a permission notice living with the switch
  // that needs it).
  Map<String, Widget> after = const {},
  // Full replacements keyed by setting key: the widget renders instead of
  // the generic tile (the motion switch shown disabled while the Camera
  // section's master switch is off).
  Map<String, Widget> replace = const {},
}) {
  final settings = container.settings;
  final visible = [
    for (final d in defs)
      if (settings.visible(d)) d,
  ];
  final out = <Widget>[];
  String? current;
  var buffer = <SettingDef<Object>>[];
  void flush() {
    if (buffer.isEmpty) return;
    out.add(
      SettingsCard(
        children: [
          for (final def in buffer) ...[
            replace[def.key] ??
                SettingTile(
                  container: container,
                  def: def,
                  onChanged: onChanged,
                ),
            if (after[def.key] != null) after[def.key]!,
          ],
        ],
      ),
    );
    buffer = [];
  }

  for (final def in visible) {
    if (def.section != current) {
      flush();
      current = def.section;
      if (current != null) out.add(SectionHeading(current));
    }
    buffer.add(def);
  }
  flush();
  return out;
}

/// (defs category, page title, icon, subtitle)
// The icon is a Material [IconData], or the path of an SVG asset for a
// category named after a product with a mark of its own.
const _categories = <(String, String, Object, String)>[
  (
    'Home Assistant',
    'Home Assistant Configuration',
    'assets/svg/home-assistant.svg',
    'Connection, dashboard, kiosk mode',
  ),
  (
    'Voice Satellite',
    'Voice Satellite',
    Icons.graphic_eq_outlined,
    'Wake word, background listening',
  ),
  (
    'Screen & Audio',
    'Screen & Audio',
    Icons.brightness_6_outlined,
    'Brightness, volume, microphone',
  ),
  ('Browser', 'Web Browsing', Icons.public, 'Cache, SSL, Zoom level'),
  (
    'Screensaver',
    'Screensaver',
    Icons.dark_mode_outlined,
    'Idle timeout, modes, motion wake',
  ),
  (
    'Camera',
    'Camera',
    Icons.photo_camera_outlined,
    'Device camera, motion detection',
  ),
  (
    'Sendspin',
    'Music Assistant',
    // The one category that answers to a product rather than a feature, so
    // it wears that product's mark instead of a Material glyph.
    'assets/svg/music-assistant.svg',
    'Configuration, Sendspin player, lyrics',
  ),
  (
    'Cameras',
    'Camera Streams',
    Icons.videocam_outlined,
    'Go2RTC and Home Assistant cameras',
  ),
  (
    'DLNA',
    'DLNA Renderer',
    Icons.cast_outlined,
    'Play images, videos and audio remotely',
  ),
  ('MQTT', 'MQTT Settings', Icons.hub_outlined, 'Publish to an MQTT broker'),
  (
    'Kiosk',
    'Kiosk Mode',
    Icons.lock_outline,
    'Exit gesture, PIN, hardware buttons',
  ),
  (
    'Launcher',
    'App Launcher',
    Icons.apps_outlined,
    'Open other apps from the kiosk',
  ),
  (
    'Gestures',
    'Gestures',
    Icons.gesture,
    'Touch and clap gestures',
  ),
  (
    'Device',
    'Device',
    Icons.tablet_android_outlined,
    'Name, app theme, remote access',
  ),
  ('About', 'About', Icons.info_outline, 'Version, author, license'),
  ('Logs', 'Logs', Icons.article_outlined, 'App log and web console'),
];

List<SettingDef<Object>> _defsFor(String category) => [
  for (final def in allSettings)
    if (def.category == category && !def.hidden) def,
];

/// A category icon the way One UI paints them: a solid color disc with a
/// white glyph. The disc colors cycle the four brand accents (already
/// light/dark-adapted by the scheme).
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.index, required this.icon});

  final int index;

  /// [IconData], or an SVG asset path (see [_categories]).
  final Object icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accents = [
      scheme.primary, // sage
      scheme.secondary, // teal
      scheme.tertiary, // ochre
      scheme.error, // rust
    ];
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accents[index % accents.length],
        shape: BoxShape.circle,
      ),
      child: icon is IconData
          ? Icon(icon as IconData, color: Colors.white, size: 22)
          // Drawn in the disc's foreground like every Material glyph beside
          // it, so a product mark does not become the one colored thing in
          // the rail.
          : Center(
              child: SvgPicture.asset(
                icon as String,
                width: 21,
                height: 21,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
    );
  }
}

/// Hierarchical settings, One UI style: on a wide screen the category list is
/// a rail that stays put on the left while the selected category's settings
/// fill the right pane; on a narrow screen the rail is a page of its own and
/// categories push on top. Both render from the declarative setting
/// definitions — the same source the remote admin UI uses.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selected = 0;

  /// Search over every pane, One UI style: the field lives with the rail (or
  /// the hub on narrow screens), typing swaps the content for results, and a
  /// tapped result opens its pane and scrolls to the row.
  final _searchCtl = TextEditingController();
  bool _showResults = false;

  /// The row the last tapped result lands on; the epoch re-arms the landing
  /// so tapping the same result again scrolls again.
  String? _landing;
  int _landingEpoch = 0;

  late final List<SettingsSearchEntry> _searchIndex = buildSettingsSearchIndex([
    for (final (category, title, _, subtitle) in _categories)
      (category, title, subtitle),
  ]);

  String get _query => _searchCtl.text.trim();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _openResult(SettingsSearchEntry entry) {
    FocusManager.instance.primaryFocus?.unfocus();
    final index = _categories.indexWhere((c) => c.$1 == entry.category);
    if (index < 0) return;
    final anchor = resolveSearchAnchor(
      entry,
      widget.container.settings.visible,
    );
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      setState(() {
        _selected = index;
        _showResults = false;
        _landing = anchor;
        _landingEpoch++;
      });
    } else {
      // The results stay behind the pushed pane, so Back returns to them.
      final (category, title, _, _) = _categories[index];
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CategorySettingsScreen(
            container: widget.container,
            title: title,
            category: category,
            landingAnchor: anchor,
          ),
        ),
      );
    }
  }

  /// The pill search field, One UI's shape: rounded fill, leading glass,
  /// trailing clear while there is something to clear.
  Widget _searchField(BuildContext context, {required EdgeInsets padding}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: TextField(
        controller: _searchCtl,
        textInputAction: TextInputAction.search,
        onTap: () {
          if (_query.isNotEmpty && !_showResults) {
            setState(() => _showResults = true);
          }
        },
        onChanged: (_) => setState(() => _showResults = _query.isNotEmpty),
        decoration: InputDecoration(
          hintText: 'Search settings',
          prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() {
                    _searchCtl.clear();
                    _showResults = false;
                  }),
                ),
          filled: true,
          // The card surface, not the rail highlight: on dark the selected
          // category tile uses surfaceContainerHighest, and a field in the
          // same color read as another selected row.
          fillColor: scheme.surfaceContainer,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// The results, grouped under their pane's heading the way One UI groups
  /// by page. Wide screens give it the pane header the category content has;
  /// narrow screens list it directly under the field.
  Widget _resultsPane(BuildContext context, {required bool wide}) {
    final theme = Theme.of(context);
    final results = searchSettings(_query, _searchIndex, [
      for (final c in _categories) c.$1,
    ]);
    final children = <Widget>[];
    if (wide) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 18),
          child: Row(
            children: [
              const Icon(Icons.search, size: 26),
              const SizedBox(width: 12),
              Text(
                'Search results',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: Ks.displayFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (results.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(Ks.inset, 12, Ks.inset, 12),
          child: Text(
            'No settings match "$_query".',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      String? category;
      var rows = <Widget>[];
      void flush() {
        if (rows.isEmpty) return;
        children.add(SettingsCard(children: rows));
        rows = [];
      }

      for (final entry in results) {
        if (entry.category != category) {
          flush();
          category = entry.category;
          final title = _categories
              .where((c) => c.$1 == category)
              .map((c) => c.$2)
              .firstOrNull;
          children.add(SectionHeading(title ?? entry.category));
        }
        rows.add(
          ListTile(
            title: _highlightMatch(entry.title, _query, theme),
            subtitle: entry.description.isEmpty
                ? null
                : Text(
                    entry.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: entry.isPage ? const Icon(Icons.chevron_right) : null,
            onTap: () => _openResult(entry),
          ),
        );
      }
      flush();
    }
    return EdgeFade(
      child: ListView(
        padding: wide
            ? const EdgeInsets.fromLTRB(8, 24, 28, 24)
            : Ks.pagePadding,
        children: children,
      ),
    );
  }

  /// The result title with the first match of the query emphasized, so the
  /// eye can tell why each row is in the list.
  Widget _highlightMatch(String text, String query, ThemeData theme) {
    final q = query.trim().toLowerCase();
    final index = q.isEmpty ? -1 : text.toLowerCase().indexOf(q);
    if (index < 0) return Text(text);
    final emphasis = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + q.length),
            style: emphasis,
          ),
          TextSpan(text: text.substring(index + q.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The split needs room for a readable rail plus content; below that,
    // fall back to push navigation (One UI does the same on phones).
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return wide ? _splitView(context) : _hub(context);
  }

  Widget _splitView(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final railWidth = (width * 0.4).clamp(320.0, 430.0);
    final (category, title, icon, _) = _categories[_selected];
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: railWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontFamily: Ks.displayFont,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  _searchField(
                    context,
                    padding: const EdgeInsets.fromLTRB(24, 0, 16, 10),
                  ),
                  Expanded(
                    child: EdgeFade(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                        children: [
                          for (final (index, (_, title, icon, subtitle))
                              in _categories.indexed)
                            _railTile(context, index, title, icon, subtitle),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showResults
                  ? _resultsPane(context, wide: true)
                  : SearchLandingScope(
                      target: _landing,
                      epoch: _landingEpoch,
                      child: EdgeFade(
                        child: ListView(
                          key: PageStorageKey('settings-pane-$category'),
                          padding: const EdgeInsets.fromLTRB(8, 24, 28, 24),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 0, 18),
                              child: Row(
                                children: [
                                  // The rail's icon again — bare glyph, no
                                  // disc: the title row is a label, not a
                                  // button.
                                  if (icon is IconData)
                                    Icon(icon, size: 26)
                                  else
                                    SvgPicture.asset(
                                      icon as String,
                                      width: 24,
                                      height: 24,
                                      colorFilter: ColorFilter.mode(
                                        theme.colorScheme.onSurface,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Text(
                                    title,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontFamily: Ks.displayFont,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            _CategoryContent(
                              key: ValueKey(category),
                              container: widget.container,
                              category: category,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// One rail row, One UI style: icon disc, semibold title, muted one-line
  /// subtitle, and a large rounded highlight on the selected row.
  Widget _railTile(
    BuildContext context,
    int index,
    String title,
    Object icon,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final selected = index == _selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Ks.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Picking a category leaves the results and disarms the last
          // landing — a stale target must not flash on a later visit.
          onTap: () => setState(() {
            _selected = index;
            _showResults = false;
            _landing = null;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _CategoryIcon(index: index, icon: icon),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Narrow screens: the classic hub page; categories push on top of it.
  /// The search field sits under the title; typing swaps the category list
  /// for results, and results push their pane like a category tap does.
  Widget _hub(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: constrainedColumn(
        Column(
          children: [
            _searchField(
              context,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            ),
            Expanded(
              child: _showResults
                  ? _resultsPane(context, wide: false)
                  : EdgeFade(
                      child: ListView(
                        padding: Ks.pagePadding,
                        children: [
                          SettingsCard(
                            children: [
                              for (final (
                                    index,
                                    (category, title, icon, subtitle),
                                  )
                                  in _categories.indexed)
                                ListTile(
                                  leading: _CategoryIcon(
                                    index: index,
                                    icon: icon,
                                  ),
                                  title: Text(title),
                                  subtitle: Text(subtitle),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CategorySettingsScreen(
                                        container: widget.container,
                                        title: title,
                                        category: category,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One category as a pushed page (narrow screens only — wide screens show the
/// same content as the split view's right pane).
class CategorySettingsScreen extends StatelessWidget {
  const CategorySettingsScreen({
    super.key,
    required this.container,
    required this.title,
    required this.category,
    this.landingAnchor,
  });

  final AppContainer container;
  final String title;
  final String category;

  /// The row a search result lands on: scrolled to and blinked once the
  /// pane is up. Null opens the pane at the top, the plain category tap.
  final String? landingAnchor;

  @override
  Widget build(BuildContext context) {
    final icon = _categories
        .where((c) => c.$1 == category)
        .map((c) => c.$3)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        // scaleDown instead of ellipsis: the longest title overshoots a
        // phone-width bar by only a few percent, and a barely smaller
        // complete title beats a chopped one.
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon is IconData) ...[
                Icon(icon, size: 24),
                const SizedBox(width: 10),
              ] else if (icon is String) ...[
                SvgPicture.asset(
                  icon,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(title),
            ],
          ),
        ),
      ),
      body: constrainedColumn(
        SearchLandingScope(
          target: landingAnchor,
          epoch: 1,
          child: EdgeFade(
            child: ListView(
              padding: Ks.pagePadding,
              children: [
                _CategoryContent(container: container, category: category),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One category's settings content — the cards only, no scaffolding — shared
/// by the split view's right pane and the narrow-screen category page.
///
/// Home Assistant is the special case: the Voice Satellite section appears
/// only when the integration is detected on the connected instance, and the
/// required-permissions card only while wake word detection is on.
class _CategoryContent extends StatefulWidget {
  const _CategoryContent({
    super.key,
    required this.container,
    required this.category,
  });

  final AppContainer container;
  final String category;

  @override
  State<_CategoryContent> createState() => _CategoryContentState();
}

class _CategoryContentState extends State<_CategoryContent> {
  Future<bool>? _vsDetected;

  /// Held rather than started in build(): a fresh Future on every rebuild
  /// sends the row back to "…" and re-runs the page query, so flipping any
  /// switch on this page made the card above it blink.
  Future<String>? _satellite;

  @override
  void initState() {
    super.initState();
    if (widget.category == 'Voice Satellite') {
      _vsDetected = widget.container.homeAssistant.detectVoiceSatellite();
      _satellite = _assignedSatellite(widget.container);
    }
    // These panes render differently on a camera-less device (disabled
    // switch, hidden rows); rebuild once the async probe has its answer.
    if (widget.category == 'Camera' || widget.category == 'Screensaver') {
      widget.container.deviceCamera.cameraPresent().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _exportConfig() async {
    final result = await widget.container.commands.execute(
      'exportConfig',
      const {},
    );
    if (!result.ok) {
      _toast('Export failed: ${result.error}');
      return;
    }
    final bytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(result.data),
    );
    // saveFile with bytes writes the file itself on Android; the system
    // dialog picks the destination.
    final path = await FilePicker.platform.saveFile(
      fileName: exportFileName(
        widget.container.settings.get(deviceName),
        DateTime.now(),
      ),
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: Uint8List.fromList(bytes),
    );
    if (path != null) _toast('Configuration exported');
  }

  Future<void> _importConfig() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null) return;
    Object? config;
    try {
      config = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      _toast('That file is not valid JSON');
      return;
    }
    if (!mounted) return;
    final options = await showImportOptionsDialog(
      context,
      backupDeviceName: config is Map
          ? '${(config['settings'] as Map?)?['device.name'] ?? ''}'
          : null,
    );
    if (options == null) return;
    final result = await widget.container.commands.execute('importConfig', {
      'config': config,
      'adoptIdentity': options.adoptIdentity,
      'importLocalStorage': options.importLocalStorage,
    });
    if (result.ok) {
      _toast('Applied ${(result.data as Map)['applied']} settings');
      if (mounted) setState(() {});
    } else {
      _toast('Import failed: ${result.error}');
    }
  }

  /// Leave the settings stack and show [url] in the kiosk browser.
  void _openLink(String url) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.container.commands.execute('loadUrl', {'url': url});
  }

  /// The app log, mirroring the remote UI's Logs tab: the same buffer the
  /// admin serves, newest at the bottom, with copy for bug reports.
  /// Which log the App Logs page shows: the app's own ring buffer, or the
  /// Android logcat tail — where renderer crashes and OS-level kills appear,
  /// which the in-app log by definition cannot record.
  String _logSource = 'app';
  String? _logcatText;
  bool _logcatLoading = false;

  /// Logcat type filters, so a crash can be copied without 800 lines of
  /// noise around it. Continuation lines (stack traces) inherit the previous
  /// line's priority, so a filtered crash keeps its whole trace.
  bool _lcErrors = true;
  bool _lcWarnings = true;
  bool _lcInfo = false;

  static final _lcPriority = RegExp(r'^\d{2}-\d{2} [\d:.]+ ([VDIWEF])/');

  List<(String, String)> _filteredLogcat() {
    final text = _logcatText;
    if (text == null) return const [];
    final out = <(String, String)>[];
    var last = 'I';
    for (final line in text.split('\n')) {
      if (line.trim().isEmpty) continue;
      final m = _lcPriority.firstMatch(line);
      final pri = m?.group(1) ?? last;
      last = pri;
      final keep = switch (pri) {
        'E' || 'F' => _lcErrors,
        'W' => _lcWarnings,
        _ => _lcInfo,
      };
      if (keep) out.add((line, pri));
    }
    return out;
  }

  Future<void> _fetchLogcat(AppContainer container) async {
    setState(() => _logcatLoading = true);
    final r = await container.commands.execute('getLogcat', const {});
    if (!mounted) return;
    setState(() {
      _logcatLoading = false;
      _logcatText = r.ok
          ? '${r.data}'
          : 'Could not read logcat: ${r.error ?? 'unknown'}';
    });
  }

  /// A fixed-height, internally scrolling box for log lines, so the Logs
  /// page always fits the viewport and only the box itself scrolls — the
  /// remote UI's panes behave the same way. Starts pinned to the newest
  /// line at the bottom.
  Widget _logBox(List<Widget> lines, {double extraChrome = 0}) {
    // Estimated chrome around the box: page title, segmented nav, card
    // header and paddings, footer; the narrow layout adds its app bar.
    // A little short is a small gap below; too tall would put the scroll
    // back on the page.
    final size = MediaQuery.sizeOf(context);
    final chrome = (size.width >= 720 ? 300.0 : 370.0) + extraChrome;
    final height = (size.height - chrome).clamp(220.0, 1200.0);
    return SizedBox(
      height: height,
      child: EdgeFade(
        child: ListView(
          reverse: true,
          children: [for (final line in lines.reversed) line],
        ),
      ),
    );
  }

  List<Widget> _logsCards(AppContainer container) {
    final theme = Theme.of(context);
    final entries = container.log.recent;
    // Brand-mapped severities (rust / ochre), legible on both themes.
    Color levelColor(LogLevel level) => switch (level) {
      LogLevel.error => theme.colorScheme.error,
      LogLevel.warn => theme.colorScheme.tertiary,
      LogLevel.debug => theme.colorScheme.outline,
      _ => theme.colorScheme.onSurface,
    };
    String fmt(LogEntry e) =>
        '${e.time.toIso8601String().substring(11, 19)} ${e.tag}: ${e.message}';
    final isLogcat = _logSource == 'logcat';
    return [
      SettingsCard(
        children: [
          ListTile(
            title: Text(
              isLogcat
                  ? 'Android system log for this app (crashes live here)'
                  : '${entries.length} entries',
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Copy log',
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: isLogcat
                            ? _filteredLogcat().map((l) => l.$1).join('\n')
                            : entries.map(fmt).join('\n'),
                      ),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Log copied'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () =>
                      isLogcat ? _fetchLogcat(container) : setState(() {}),
                ),
              ],
            ),
          ),
          // Type filters, only for logcat: copy exactly the lines shown, so a
          // crash can go into a GitHub issue without hundreds of noise lines.
          if (isLogcat)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Wrap(
                spacing: 16,
                children: [
                  for (final (label, value, set) in [
                    ('Errors & crashes', _lcErrors, (bool v) => _lcErrors = v),
                    ('Warnings', _lcWarnings, (bool v) => _lcWarnings = v),
                    ('Info & debug', _lcInfo, (bool v) => _lcInfo = v),
                  ])
                    InkWell(
                      onTap: () => setState(() => set(!value)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: value,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onChanged: (v) => setState(() => set(v ?? false)),
                          ),
                          Text(label, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: isLogcat
                ? (_logcatLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            ),
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final lines = _filteredLogcat();
                            // Errors-only is the default; a quiet log must read
                            // as good news, not as a broken viewer.
                            if (lines.isEmpty && _logcatText != null) {
                              return Text(
                                'No matching lines. Enable more types above to '
                                'see the full log.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            }
                            return _logBox([
                              for (final (line, pri) in lines)
                                Text(
                                  line,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: switch (pri) {
                                      'E' || 'F' => theme.colorScheme.error,
                                      'W' => theme.colorScheme.tertiary,
                                      _ => theme.colorScheme.onSurface,
                                    },
                                  ),
                                ),
                            ], extraChrome: 44);
                          },
                        ))
                : _logBox([
                    for (final e in entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          fmt(e),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: levelColor(e.level),
                          ),
                        ),
                      ),
                  ]),
          ),
        ],
      ),
    ];
  }

  /// The WebView console, inline, mirroring the remote admin's view. The
  /// dock button hands over to the same feed as a panel over the live page,
  /// for watching output while the dashboard is actually in front.
  List<Widget> _consoleCards(AppContainer container) {
    final theme = Theme.of(context);
    // Brand-mapped severities, legible on both themes: rust errors, ochre
    // warnings, teal tips, sage commands.
    Color levelColor(String level) => switch (level) {
      'error' => theme.colorScheme.error,
      'warn' => theme.colorScheme.tertiary,
      'debug' => theme.colorScheme.outline,
      'tip' => theme.colorScheme.secondary,
      'cmd' => theme.colorScheme.primary,
      _ => theme.colorScheme.onSurface,
    };
    return [
      SettingsCard(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: container.browser.consoleRevision,
            builder: (context, _, _) {
              final entries = container.browser.consoleEntries;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    title: Text('${entries.length} entries'),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Copy log',
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await Clipboard.setData(
                              ClipboardData(
                                text: [
                                  for (final e in entries)
                                    '${e.time.toIso8601String()} '
                                        '[${e.level}] ${e.message}',
                                ].join('\n'),
                              ),
                            );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Console log copied'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.block_outlined, size: 20),
                          onPressed: container.browser.clearConsole,
                        ),
                        IconButton(
                          tooltip: 'Dock over the live page',
                          icon: const Icon(Icons.terminal_outlined, size: 20),
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                            container.bus.publish(const WebConsoleRequested());
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: entries.isEmpty
                        ? Text(
                            'No console output yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : _logBox([
                            for (final e in entries)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                            '${e.time.toIso8601String().substring(11, 19)} ',
                                        style: TextStyle(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      TextSpan(text: e.message),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: levelColor(e.level),
                                  ),
                                ),
                              ),
                          ]),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ];
  }

  /// The About page: app identity and attribution. Mirrored on the remote
  /// UI's About tab.
  List<Widget> _aboutCards(AppContainer container) {
    final device = container.device;
    Widget row(String name, String value, {VoidCallback? onTap}) => ListTile(
      title: Text(name),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      onTap: onTap,
    );
    return [
      const SectionHeading('App'),
      SettingsCard(
        children: [
          row('App version', '${device.appVersion} (${device.buildNumber})'),
          row('Build', device.buildMode),
          row('Package', device.packageName),
        ],
      ),
      const SectionHeading('Attribution'),
      SettingsCard(
        children: [
          row(
            'Author',
            'Xavier Larrea',
            onTap: () => _openLink('https://github.com/jxlarrea'),
          ),
          ListTile(
            title: const Text('Source code'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(
                  _githubMark,
                  height: 15,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'jxlarrea/kiosk-satellite',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            onTap: () =>
                _openLink('https://github.com/jxlarrea/kiosk-satellite'),
          ),
          row(
            'License',
            'CC BY-NC-ND 4.0',
            onTap: () => _openLink(
              'https://github.com/jxlarrea/kiosk-satellite/blob/main/LICENSE',
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          'Kiosk Satellite is free for personal, non-commercial use. It is '
          'licensed under CC BY-NC-ND 4.0: you may use and share it, but '
          'commercial use and derivative works are not permitted.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final container = widget.container;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.category == 'Home Assistant')
          ..._haConnectionCards(container)
        else if (widget.category == 'Voice Satellite')
          ValueListenableBuilder<bool>(
            valueListenable: container.homeAssistant.connectionOk,
            builder: (context, _, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _vsContent(container),
            ),
          )
        else if (widget.category == 'Cameras')
          CameraSettingsPanel(container: container)
        else if (widget.category == 'Gestures')
          GestureSettingsPanel(container: container)
        else if (widget.category == 'Screen & Audio') ...[
          const SectionHeading('Screen'),
          SettingsCard(
            children: [
              for (final def in _defsFor('Screen & Audio'))
                if (def.section == 'Screen' && container.settings.visible(def))
                  SettingTile(
                    container: container,
                    def: def,
                    onChanged: () => setState(() {}),
                  ),
            ],
          ),
          _BrightnessGrantCard(container: container),
          _AmbientDisplayCard(container: container),
          // One card, mixer-style: the master fader (live device volume,
          // not a setting) with the media and assistant faders that scale
          // under it. The remote UI mirrors this page.
          const SectionHeading('Audio Volume'),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:master_volume',
                child: _MasterVolumeTile(container: container),
              ),
              for (final def in _defsFor('Screen & Audio'))
                if (def.section == 'Audio Volume')
                  SettingTile(
                    container: container,
                    def: def,
                    onChanged: () => setState(() {}),
                  ),
            ],
          ),
          // Device pickers are hand-built (their options are live hardware);
          // the remote UI mirrors both rows. The mic one only while detection
          // is on — with it off this app never opens the microphone, the
          // browser does.
          const SectionHeading('Audio Devices'),
          SettingsCard(
            children: [
              if (container.settings.get(wakeWordEnabled))
                SearchLandingTarget(
                  id: audioMicDevice.key,
                  child: AudioDeviceTile(
                    container: container,
                    def: audioMicDevice,
                    inputs: true,
                  ),
                ),
              SearchLandingTarget(
                id: audioSpeakerDevice.key,
                child: AudioDeviceTile(
                  container: container,
                  def: audioSpeakerDevice,
                  inputs: false,
                ),
              ),
            ],
          ),
          // Capture tuning. Its own group because none of it is a
          // preference: it is there for devices whose audio stack
          // misbehaves, and every default is what the app has always done.
          const SectionHeading('Microphone settings'),
          const GroupNote(_micGroupNote),
          SettingsCard(
            children: [
              for (final def in _defsFor('Screen & Audio'))
                if (def.section == 'Microphone settings' &&
                    container.settings.visible(def))
                  SettingTile(
                    container: container,
                    def: def,
                    onChanged: () => setState(() {}),
                  ),
              // The capture channel of a multichannel microphone. Hand-built
              // (its options run to the selected mic's channel count) and
              // only with detection on, like the mic picker above.
              if (container.settings.get(wakeWordEnabled))
                SearchLandingTarget(
                  id: micChannel.key,
                  child: MicChannelTile(container: container),
                ),
              // Live capture level under the gain it verifies. Only with
              // detection on: it reads the engine's telemetry, and with
              // detection off this app never opens the microphone.
              if (container.settings.get(wakeWordEnabled))
                MicLevelTile(container: container),
            ],
          ),
        ] else
          ..._sectionedCards(
            container,
            // With the Camera master switch off (or no camera on the
            // device at all), motion detection cannot run: the dismiss
            // switch renders disabled (below) with the reason, instead of
            // lying enabled; its tuning rows live in the Camera section
            // now and hide with the master there. A camera-less device
            // keeps only the disabled master switch.
            widget.category == 'Camera' &&
                    container.deviceCamera.cameraKnownAbsent
                ? const [cameraEnabled]
                : _defsFor(widget.category),
            () => setState(() {}),
            replace: {
              if (widget.category == 'Screensaver' &&
                  !container.deviceCamera.effectiveEnabled)
                screensaverDismissOnMotion.key: SearchLandingTarget(
                  id: screensaverDismissOnMotion.key,
                  child: const SwitchListTile(
                    title: Text('Dismiss on motion'),
                    subtitle: Text(
                      'Requires the camera. Turn it on in the Camera '
                      'settings first.',
                    ),
                    value: false,
                    onChanged: null,
                  ),
                ),
              if (widget.category == 'Camera' &&
                  container.deviceCamera.cameraKnownAbsent)
                cameraEnabled.key: SearchLandingTarget(
                  id: cameraEnabled.key,
                  child: SwitchListTile(
                    title: Text(cameraEnabled.title),
                    subtitle: Text(cameraEnabled.description),
                    value: false,
                    onChanged: null,
                  ),
                ),
              // One camera means no front/back choice to offer (the
              // capture falls back to the camera present regardless of
              // the stored value).
              if (widget.category == 'Camera' &&
                  container.deviceCamera.knownFacings?.length == 1)
                cameraDevice.key: SearchLandingTarget(
                  id: cameraDevice.key,
                  child: ListTile(
                    title: Text(cameraDevice.title),
                    subtitle: const Text('The only camera this device has.'),
                    trailing: Text(
                      cameraDevice.optionLabels?[container
                              .deviceCamera
                              .knownFacings!
                              .single] ??
                          container.deviceCamera.knownFacings!.single,
                    ),
                  ),
                ),
            },
            after: {
              if (widget.category == 'Browser' &&
                  container.settings.get(autoReloadOnError))
                autoReloadOnError.key: _OverlayGrantRow(key: UniqueKey()),
              if (widget.category == 'Camera')
                cameraEnabled.key: Column(
                  children: [
                    _NoCameraRow(container: container),
                    if (container.deviceCamera.effectiveEnabled)
                      _CameraGrantRow(key: UniqueKey()),
                  ],
                ),
              // Where the tuning rows used to be: camera pick, frame rate
              // and sensitivity are Camera-settings decisions now.
              if (widget.category == 'Screensaver')
                screensaverPostponeOnMotion.key: const HintRow(
                  'Motion detection is tuned in the Camera settings.',
                ),
              // The screen-off timer fails quietly without device admin;
              // this row is what says so, right where the slider is.
              if (widget.category == 'Screensaver')
                screensaverScreenOffMinutes.key: _ScreenOffAdminRow(
                  key: UniqueKey(),
                  container: container,
                ),
              // Dim is the one mode the pause-dashboard optimization cannot
              // help: there is no overlay, the page IS the display. Lives in
              // the Dim group, whose rows only render while Dim is selected.
              if (widget.category == 'Screensaver' &&
                  container.settings.get(screensaverMode) == 'dim')
                screensaverDimLevel.key: const WarnRow(_dimModeNote),
              if (widget.category == 'Screensaver') ...{
                // Rendered only while their anchor rows are (mode: immich).
                screensaverImmichApiKey.key: _ImmichValidateRow(
                  container: container,
                  onChanged: () => setState(() {}),
                ),
                screensaverImmichCacheMax.key: _ImmichCacheStatsRow(
                  container: container,
                ),
              },
              // Under the last credential field, where the Home Assistant
              // and Immich cards put theirs.
              if (widget.category == 'MQTT')
                mqttPassword.key: _MqttValidateRow(container: container),
              if (widget.category == 'Sendspin')
                sendspinMaToken.key: _MaValidateRow(container: container),
            },
          ),
        // Last and on their own card, like the Voice Satellite permissions:
        // the OS's to give, not ours to set. Always shown - Lockdown Mode
        // has no page on the device, so its grants live here too.
        if (widget.category == 'Kiosk') ...[
          const SectionHeading('Required system permissions'),
          SearchLandingTarget(
            id: 'x:kiosk_permissions',
            child: SettingsCard(
              children: [_KioskPermissionsTile(container: container)],
            ),
          ),
        ],
        if (widget.category == 'Device' &&
            container.settings.get(remoteEnabled))
          _AdminAddressCard(container: container),
        if (widget.category == 'Device') ...[
          // Every OS grant in one place (issue #156). The per-feature groups
          // elsewhere answer "what does this feature need" where it is
          // configured; this one answers "what does the app use, and where
          // do I stand" — which is how a grant nobody's current features
          // ask for, like the battery exemption on a device without voice,
          // becomes findable at all.
          const SectionHeading('Permissions Manager'),
          SearchLandingTarget(
            id: 'x:device_permissions',
            child: SettingsCard(
              children: [
                // The explanation is the group's first row rather than
                // floating text under the heading.
                const HintRow(_permissionsGroupNote),
                _DevicePermissionsTile(container: container),
              ],
            ),
          ),
          const SectionHeading('Configuration'),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:export_config',
                child: ListTile(
                  title: const Text('Export configuration'),
                  subtitle: const Text(
                    "Save every setting and the page's local storage to a "
                    'file.',
                  ),
                  trailing: const Icon(Icons.download_outlined),
                  onTap: _exportConfig,
                ),
              ),
              SearchLandingTarget(
                id: 'x:import_config',
                child: ListTile(
                  title: const Text('Import configuration'),
                  subtitle: const Text(
                    "Replace this device's settings from an exported file.",
                  ),
                  trailing: const Icon(Icons.upload_outlined),
                  onTap: _importConfig,
                ),
              ),
            ],
          ),
        ],
        if (widget.category == 'Home Assistant')
          ValueListenableBuilder<bool>(
            valueListenable: container.homeAssistant.connectionOk,
            builder: (context, connected, _) => connected
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _haConfiguredCards(container),
                  )
                : const SizedBox.shrink(),
          ),
        if (widget.category == 'About') ..._aboutCards(container),
        if (widget.category == 'Logs') ...[
          // One log at a time, picked by the links on top; the remote
          // admin's Logs tab is the same three views.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'app', label: Text('Kiosk Satellite')),
                ButtonSegment(value: 'logcat', label: Text('Logcat')),
                ButtonSegment(value: 'console', label: Text('Web Console')),
              ],
              selected: {_logSource},
              onSelectionChanged: (selection) {
                setState(() => _logSource = selection.first);
                if (_logSource == 'logcat' && _logcatText == null) {
                  _fetchLogcat(container);
                }
              },
            ),
          ),
          if (_logSource == 'console')
            ..._consoleCards(container)
          else
            ..._logsCards(container),
        ],
        _MadeByFooter(container: container),
      ],
    );
  }

  /// The connection card: base URL, token, and the validation row. Always
  /// visible — it is the gate everything else on this page waits behind.
  List<Widget> _haConnectionCards(AppContainer container) {
    return [
      SettingsCard(
        children: [
          SettingTile(
            container: container,
            def: haUrl,
            onChanged: () => setState(() {}),
          ),
          SettingTile(
            container: container,
            def: haToken,
            onChanged: () => setState(() {}),
          ),
          SearchLandingTarget(
            id: 'x:ha_validate',
            child: ListTile(
              title: const Text('Validate connection'),
              subtitle: Text(
                _haValidating
                    ? 'Checking…'
                    : _haError ??
                          (container.homeAssistant.connectionOk.value
                              ? 'Connected'
                              : 'Not validated yet. The settings below unlock '
                                    'once the connection checks out.'),
              ),
              trailing: _haValidating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Icon(
                      container.homeAssistant.connectionOk.value
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                    ),
              onTap: _haValidating ? null : () => _validateHa(container),
            ),
          ),
          // Hand-built (and mirrored in the remote UI's connection card):
          // the row's enabled state derives from the URL scheme. https
          // needs no proxy, so the switch sits disabled and off; a plain
          // http URL enables it, and validation turns it on with a modal.
          SearchLandingTarget(
            id: 'x:secure_proxy',
            child: Builder(
              builder: (context) {
                final uri = Uri.tryParse(container.settings.get(haUrl).trim());
                final isHttp =
                    uri != null &&
                    uri.scheme == 'http' &&
                    uri.host != 'localhost' &&
                    uri.host != '127.0.0.1';
                return SwitchListTile(
                  title: Text(secureProxy.title),
                  subtitle: Text(secureProxy.description),
                  value: container.settings.get(secureProxy),
                  onChanged: isHttp
                      ? (v) async {
                          await container.settings.set(secureProxy, v);
                          if (mounted) setState(() {});
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    ];
  }

  bool _haValidating = false;
  String? _haError;

  Future<void> _validateHa(AppContainer container) async {
    // A plain-http URL means the browser will withhold the microphone and
    // every other https-only API from the dashboard. The secure context
    // proxy is the fix; tell the user it is being turned on and why before
    // validating.
    final url = container.settings.get(haUrl).trim();
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.scheme == 'http' &&
        uri.host != 'localhost' &&
        uri.host != '127.0.0.1' &&
        !container.settings.get(secureProxy)) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Secure context proxy'),
          content: const Text(
            'This Home Assistant URL uses plain http, and browsers block '
            'the microphone and other features on http pages. Kiosk '
            'Satellite will route the dashboard through a secure proxy '
            'inside the app so everything works. You may need to sign in '
            'to Home Assistant again.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      await container.settings.set(secureProxy, true);
      if (!mounted) return;
    }
    setState(() {
      _haValidating = true;
      _haError = null;
    });
    final error = await container.homeAssistant.validateConnection();
    if (!mounted) return;
    setState(() {
      _haValidating = false;
      _haError = error;
    });
  }

  /// Everything a proven connection unlocks: the dashboard picker, then the
  /// regular Home Assistant settings, Voice Satellite and its permissions.
  List<Widget> _haConfiguredCards(AppContainer container) {
    return [
      const SectionHeading('Dashboard'),
      SearchLandingTarget(
        id: 'x:dashboard_picker',
        child: _DashboardPickerCard(container: container),
      ),
      ..._sectionedCards(container, [
        for (final def in _defsFor('Home Assistant'))
          if (def.key != haUrl.key &&
              def.key != haToken.key &&
              // Redundant while the theme mirror is on: the schedule
              // already targets the app theme then (issue #92).
              (def.key != themeAutoApp.key ||
                  !container.settings.get(themeMatchApp)) &&
              // The rotation group is hand-built below: its dashboard list
              // needs the live dashboards from HA, which the generic
              // renderer cannot supply.
              def.key != haRotationEnabled.key &&
              def.key != haRotationSeconds.key &&
              def.key != haRotationPauseSeconds.key &&
              // Rendered below the rotation group, which its switch is
              // gated on.
              def.key != haReturnHomeEnabled.key &&
              def.key != haReturnHomeSeconds.key &&
              // Optimizations are hand-built last so the filter can show live
              // telemetry beneath its toggle.
              def.key != disableSuspend.key &&
              def.key != wsFilter.key)
            def,
      ], () => setState(() {})),
      const SectionHeading('Dashboard View Rotation'),
      _RotationCard(container: container, onChanged: () => setState(() {})),
      // Return to the dashboard (issue #83): mutually exclusive with
      // rotation, which owns navigation on an idle kiosk — the manager
      // forces the switch off when rotation turns on, and it renders
      // disabled with the reason here.
      ..._sectionedCards(
        container,
        [haReturnHomeEnabled, haReturnHomeSeconds],
        () => setState(() {}),
        replace: {
          if (container.settings.get(haRotationEnabled))
            haReturnHomeEnabled.key: SearchLandingTarget(
              id: haReturnHomeEnabled.key,
              child: const SwitchListTile(
                title: Text('Return to home dashboard view'),
                subtitle: Text(
                  'Turned off while Dashboard view rotation is on.',
                ),
                value: false,
                onChanged: null,
              ),
            ),
        },
        after: {
          if (!container.settings.get(haRotationEnabled))
            haReturnHomeEnabled.key: HintRow(_returnHomeTargetHint(container)),
        },
      ),
      const SectionHeading('Optimizations'),
      _OptimizationsCard(container: container),
    ];
  }

  /// Where the return-home timeout lands, so nobody has to guess which
  /// view "the dashboard" means. Wording shared with the remote admin
  /// (which carries its own copy in the HTML).
  String _returnHomeTargetHint(AppContainer container) {
    final path = container.homeAssistant.homeViewPath();
    return path == null
        ? 'The configured dashboard has no view path to return to.'
        : 'Returns to "$path" after the timeout.';
  }

  /// The Voice Satellite page: gated on the proven HA connection like the
  /// rest of the HA-derived configuration, then on the integration actually
  /// being installed.
  /// The assist_satellite entity this kiosk identifies as. The page's own
  /// choice wins (localStorage, changeable in the Voice Satellite panel);
  /// the wizard's stored pick is the fallback before the page has booted.
  Future<String> _assignedSatellite(AppContainer container) async {
    final result = await container.commands.execute('evalJs', {
      'code': "localStorage.getItem('vs-satellite-entity')",
    });
    final data = result.ok ? result.data : null;
    if (data is String && data.isNotEmpty && data != 'null') return data;
    return container.settings.get(haSatelliteEntity);
  }

  List<Widget> _vsContent(AppContainer container) {
    if (!container.homeAssistant.connectionOk.value) {
      return const [
        SettingsCard(
          children: [
            ListTile(
              title: Text('Home Assistant not connected'),
              subtitle: Text(
                'Validate the connection under Home Assistant '
                'Configuration first.',
              ),
            ),
          ],
        ),
      ];
    }
    return [
      FutureBuilder<bool>(
        future: _vsDetected,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SettingsCard(
              children: [
                ListTile(
                  title: Text('Checking for Voice Satellite…'),
                  trailing: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ],
            );
          }
          if (snapshot.data != true) {
            return SettingsCard(
              children: [
                const ListTile(
                  title: Text(
                    'Voice Satellite is not installed in Home Assistant',
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Voice Satellite turns this kiosk into a full '
                      'hands-free voice assistant for Home Assistant: '
                      'wake word detection, conversations, timers and '
                      'announcements, right on the dashboard.\n\n'
                      'It is available in the default HACS repository. '
                      'Install it on your Home Assistant instance, then '
                      'come back here.',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        final url =
                            '${container.homeAssistant.baseUrl}'
                            '/hacs/repository/1159616380';
                        // Back to the kiosk, which then shows the HACS
                        // page — installing happens in Home Assistant.
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        container.commands.execute('loadUrl', {'url': url});
                      },
                      child: SvgPicture.asset(
                        'assets/branding/hacs.svg',
                        height: 44,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        container.commands.execute('loadUrl', {
                          'url':
                              'https://github.com/jxlarrea/voice-satellite-card-integration',
                        });
                      },
                      child: Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          children: [
                            const TextSpan(text: 'Learn more about '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: SvgPicture.string(
                                  _githubMark,
                                  height: 15,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: 'Voice Satellite on Github',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FutureBuilder<String>(
                future: _satellite,
                builder: (context, snap) => SearchLandingTarget(
                  id: 'x:assigned_satellite',
                  child: SettingsCard(
                    children: [
                      ListTile(
                        title: const Text('Assigned satellite'),
                        subtitle: const Text(
                          'The assist_satellite entity this kiosk identifies '
                          'as in Home Assistant.',
                        ),
                        trailing: Text(
                          snap.connectionState != ConnectionState.done
                              ? '…'
                              : ((snap.data ?? '').isEmpty
                                    ? 'None assigned'
                                    : snap.data!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsCard(
                children: [
                  for (final def in _defsFor('Voice Satellite'))
                    if (def.section == null && container.settings.visible(def))
                      SettingTile(
                        container: container,
                        def: def,
                        onChanged: () => setState(() {}),
                      ),
                  // Not a setting, but a row on the same card, so it sits
                  // behind the same line as the rest. Gone with the rest
                  // when detection is off: there is no state to report
                  // about a thing that is not running, and "it is off" is
                  // already said by the switch above.
                  if (container.settings.get(wakeWordEnabled))
                    WakeWordStatusTile(container: container),
                ],
              ),
              // The tester: a live look at what the engine hears and scores,
              // for diagnosing "the wake word isn't triggering".
              if (container.settings.get(wakeWordEnabled)) ...[
                const SectionHeading('Wake Word Tester'),
                SearchLandingTarget(
                  id: 'x:wake_word_tester',
                  child: SettingsCard(
                    children: [WakeWordTesterTile(container: container)],
                  ),
                ),
              ],
              // Last, and on their own card: these are the OS's to give,
              // not ours to set, and every one of them is a thing that
              // stops working rather than a preference. Only while we are
              // the one listening — with detection off, the browser asks
              // for the microphone through its own flow.
              if (container.settings.get(wakeWordEnabled)) ...[
                const SectionHeading('Required system permissions'),
                SearchLandingTarget(
                  id: 'x:vs_permissions',
                  child: SettingsCard(
                    children: [SystemPermissionsTile(container: container)],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ];
  }
}

/// The GitHub mark (octocat silhouette), inlined so the link row needs no
/// asset round-trip; tinted via colorFilter where used.
const _githubMark =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105'
    '.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035'
    '-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 '
    '1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765'
    '-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3'
    '-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04'
    '.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 '
    '1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095'
    '.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 '
    '0 0 24 12c0-6.63-5.37-12-12-12z"/></svg>';

/// A notice shown on the Screen page only while the "Modify system settings"
/// grant is missing: without it, brightness set from the app, the remote
/// admin or Home Assistant falls back to an app-window override the system
/// value never reflects. Disappears once granted.
/// The camera permission's status, rendered directly under "Dismiss on
/// motion" while it is enabled: motion detection silently sees nothing
/// without the grant, and the switch is where that surprise gets noticed.
/// Hidden once granted; same shape as the permission rows under Voice
/// Satellite.
/// The "Display over other apps" status, rendered directly under "Auto-reload
/// on error" while it is enabled: without the grant the app cannot bring
/// itself back after a whole-process crash on Android 10+, and the toggle is
/// where that surprise gets noticed. Hidden once granted; same shape as the
/// camera row below.
/// The grants the kiosk and lockdown protections lean on, in the same shape
/// as the Voice Satellite permissions card (mirrored in the remote UI's
/// Kiosk and Lockdown tabs): a row per grant saying what breaks without it.
/// The System UI guard is the accessibility service that closes the
/// notification shade and recents whenever they open while protections
/// hold; Android only lets the person at the device enable it, so its row
/// opens the Accessibility settings screen.
class _KioskPermissionsTile extends StatefulWidget {
  const _KioskPermissionsTile({required this.container});

  final AppContainer container;

  @override
  State<_KioskPermissionsTile> createState() => _KioskPermissionsTileState();
}

class _KioskPermissionsTileState extends State<_KioskPermissionsTile>
    with WidgetsBindingObserver {
  bool? _overlay;
  bool? _uiGuard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Both are given on OS screens that report nothing back, so re-read
    // them when the user returns from one.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    bool? overlay;
    bool? uiGuard;
    try {
      overlay = (await Permission.systemAlertWindow.status).isGranted;
    } catch (_) {}
    try {
      uiGuard = await widget.container.kiosk.uiGuardEnabled();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _overlay = overlay;
      _uiGuard = uiGuard;
    });
  }

  /// Same shape as the Voice Satellite permission rows.
  Widget _row({
    required bool? granted,
    required IconData missingIcon,
    required String title,
    required String held,
    required String missing,
    required VoidCallback onGrant,
    String action = 'Grant',
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        granted == true ? Icons.check_circle_outline : missingIcon,
        color: granted == true ? null : theme.colorScheme.error,
      ),
      title: Text(title),
      subtitle: Text(granted == true ? held : missing),
      trailing: granted == true
          ? null
          : TextButton(onPressed: onGrant, child: Text(action)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: separatedRows([
        _row(
          granted: _overlay,
          missingIcon: Icons.open_in_new_off_outlined,
          title: 'Display over other apps',
          held: 'Kiosk Satellite can bring itself back in the foreground.',
          missing:
              'Without this the kiosk cannot bring itself back and the '
              'lockdown shield only covers the app.',
          onGrant: () async {
            await requestOsPermission(Permission.systemAlertWindow);
            await _refresh();
          },
        ),
        _row(
          granted: _uiGuard,
          missingIcon: Icons.shield_outlined,
          title: 'System UI guard',
          held:
              'The notification shade and recents close on their own '
              'while the screen is protected.',
          missing:
              'Without this the notification shade and recents stay '
              'reachable. Enable Kiosk Satellite under Accessibility.',
          action: 'Enable',
          onGrant: () async {
            await widget.container.kiosk.openUiGuardSettings();
          },
        ),
      ]),
    );
  }
}

class _OverlayGrantRow extends StatefulWidget {
  const _OverlayGrantRow({super.key});

  @override
  State<_OverlayGrantRow> createState() => _OverlayGrantRowState();
}

class _OverlayGrantRowState extends State<_OverlayGrantRow> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final status = await Permission.systemAlertWindow.status;
    if (!mounted) return;
    setState(() => _granted = status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    if (_granted != false) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.layers_outlined, color: theme.colorScheme.error),
      title: const Text('Display over other apps'),
      subtitle: const Text(
        'Without this the kiosk cannot come back after a crash.',
      ),
      trailing: TextButton(
        onPressed: () async {
          await requestOsPermission(Permission.systemAlertWindow);
          await _refresh();
        },
        child: const Text('Grant'),
      ),
    );
  }
}

/// The device-admin grant, surfaced right under "Turn screen off after"
/// (mirrored in the remote UI): the timer fails quietly without the grant,
/// so this row is what says why nothing turned off. Same shape as the
/// Permissions Manager's Device admin row; hidden entirely while the grant
/// is held.
class _ScreenOffAdminRow extends StatefulWidget {
  const _ScreenOffAdminRow({super.key, required this.container});

  final AppContainer container;

  @override
  State<_ScreenOffAdminRow> createState() => _ScreenOffAdminRowState();
}

class _ScreenOffAdminRowState extends State<_ScreenOffAdminRow>
    with WidgetsBindingObserver {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The grant is given on Android's own screen, which reports nothing on
    // the way back; returning here is the moment to look again.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await BackgroundListening.isScreenOffAvailable();
    if (!mounted) return;
    setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_granted != false) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.admin_panel_settings_outlined,
        color: theme.colorScheme.error,
      ),
      title: const Text('Device admin'),
      subtitle: const Text('Not granted, so the screen cannot turn off.'),
      trailing: TextButton(
        onPressed: () async {
          await widget.container.commands.execute('requestOsPermissions', {
            'which': ['deviceAdmin'],
          });
          await _refresh();
        },
        child: const Text('Enable'),
      ),
    );
  }
}

/// The screensaver schedule editor (mirrored in the remote UI): one row per
/// entry — time, mode, brightness — plus an add button. Each entry applies
/// from its time until the next one's.
class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({required this.container, required this.onChanged});

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  /// Live slider preview while a drag is in flight; saved on release so a
  /// drag does not spam the settings store.
  int? _dragIndex;
  double? _dragLevel;

  List<Map<String, Object?>> _entries() {
    try {
      final decoded = jsonDecode(
        widget.container.settings.get(screensaverSchedule),
      );
      if (decoded is! List) return [];
      return [
        for (final e in decoded)
          if (e is Map) e.cast<String, Object?>(),
      ];
    } catch (_) {
      return [];
    }
  }

  int _minutes(String at) {
    final parts = at.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 +
        (int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0);
  }

  Future<void> _save(List<Map<String, Object?>> entries) async {
    entries.sort(
      (a, b) => _minutes('${a['at']}').compareTo(_minutes('${b['at']}')),
    );
    await widget.container.settings.setFromJson(
      screensaverSchedule.key,
      jsonEncode(entries),
    );
    if (mounted) setState(() {});
    widget.onChanged();
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '')?.clamp(0, 23) ?? 19,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '')?.clamp(0, 59) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _add() async {
    final at = await _pickTime('19:00');
    if (at == null) return;
    final s = widget.container.settings;
    final entries = _entries()
      ..add({
        'at': at,
        'mode': s.get(screensaverMode),
        'brightness': s.get(screensaverBrightnessLevel).toDouble(),
      });
    await _save(entries);
  }

  String _modeLabel(String mode) =>
      screensaverMode.optionLabels?[mode] ??
      (mode.isEmpty ? mode : mode[0].toUpperCase() + mode.substring(1));

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entries.isEmpty)
          ListTile(
            title: const Text('No times yet'),
            subtitle: Text(screensaverSchedule.description),
          ),
        // Two lines per entry, so nothing fights for width on a narrow
        // pane: the controls row (time, mode, motion, remove), then the
        // brightness row with the slider on its own full line.
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 8, 2),
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final at = await _pickTime('${entries[i]['at']}');
                        if (at == null) return;
                        entries[i]['at'] = at;
                        await _save(entries);
                      },
                      child: Text('${entries[i]['at']}'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: KsDropdown<String>(
                        expand: true,
                        value:
                            screensaverMode.options!.contains(
                              entries[i]['mode'],
                            )
                            ? entries[i]['mode'] as String
                            : screensaverMode.defaultValue,
                        items: [
                          for (final mode in screensaverMode.options!)
                            DropdownMenuItem(
                              value: mode,
                              child: Text(_modeLabel(mode)),
                            ),
                        ],
                        onChanged: (mode) async {
                          if (mode == null) return;
                          entries[i]['mode'] = mode;
                          await _save(entries);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tri-state motion override (issue #89): a Black entry
                    // overnight can keep the camera off, a Clock entry can
                    // watch even with the global switch off. Rendered
                    // disabled when the Camera master switch is off (or the
                    // device has no camera), same as the Dismiss on motion
                    // switch: no camera means no motion detection to
                    // override.
                    Tooltip(
                      message: widget.container.deviceCamera.effectiveEnabled
                          ? 'Dismiss on motion while this entry is active'
                          : 'Requires the camera. Turn it on in the Camera '
                                'settings first.',
                      child: KsDropdown<String>(
                        value: switch (entries[i]['motion']) {
                          true => 'on',
                          false => 'off',
                          _ => 'default',
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'default',
                            child: Text('Motion: default'),
                          ),
                          DropdownMenuItem(
                            value: 'on',
                            child: Text('Motion: on'),
                          ),
                          DropdownMenuItem(
                            value: 'off',
                            child: Text('Motion: off'),
                          ),
                        ],
                        onChanged:
                            !widget.container.deviceCamera.effectiveEnabled
                            ? null
                            : (choice) async {
                                if (choice == null) return;
                                if (choice == 'default') {
                                  entries[i].remove('motion');
                                } else {
                                  entries[i]['motion'] = choice == 'on';
                                }
                                await _save(entries);
                              },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove time',
                      onPressed: () async {
                        entries.removeAt(i);
                        await _save(entries);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      Icons.brightness_6_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Slider(
                        value: _dragIndex == i
                            ? _dragLevel!
                            : ((entries[i]['brightness'] as num?) ?? 0.2)
                                  .toDouble()
                                  .clamp(0.0, 1.0),
                        onChanged: (v) => setState(() {
                          _dragIndex = i;
                          _dragLevel = v;
                        }),
                        onChangeEnd: (v) async {
                          _dragIndex = null;
                          _dragLevel = null;
                          entries[i]['brightness'] = v;
                          await _save(entries);
                        },
                      ),
                    ),
                    Text(
                      '${(((_dragIndex == i ? _dragLevel! : ((entries[i]['brightness'] as num?) ?? 0.2).toDouble())) * 100).round()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add time'),
            ),
          ),
        ),
      ],
    );
  }
}

/// The screensaver Widgets editor (mirrored in the remote UI): one row per
/// widget — its type and corner — plus an add button. A widget's own
/// settings live in a dialog, so every type can carry different ones.
class _WidgetsEditor extends StatefulWidget {
  const _WidgetsEditor({required this.container, required this.onChanged});

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  State<_WidgetsEditor> createState() => _WidgetsEditorState();
}

class _WidgetsEditorState extends State<_WidgetsEditor> {
  List<ScreensaverWidget> _widgets() => decodeScreensaverWidgets(
    widget.container.settings.get(screensaverWidgets),
  );

  Future<void> _save(List<ScreensaverWidget> widgets) async {
    await widget.container.settings.setFromJson(
      screensaverWidgets.key,
      encodeScreensaverWidgets(widgets),
    );
    if (mounted) setState(() {});
    widget.onChanged();
  }

  IconData _icon(String type) => switch (type) {
    'clock' => Icons.access_time,
    'weather' => Icons.cloud_outlined,
    _ => Icons.widgets_outlined,
  };

  /// The per-type hint under the dialog's title: where the widget
  /// deliberately stays off, so nobody hunts for a hidden clock.
  String? _modeNote(String type) => switch (type) {
    'clock' => 'Hidden in Digital Clock and WebRTC screensaver modes.',
    'weather' => 'Hidden in the WebRTC screensaver mode.',
    _ => null,
  };

  /// The weather.* entities, picked from Home Assistant by friendly name.
  /// Returns (entity_id, name), or null when dismissed or unreachable.
  Future<(String, String)?> _pickWeatherEntity(
    BuildContext context,
    String current,
  ) async {
    final result = await widget.container.commands.execute(
      'haSearchEntities',
      const {'query': 'weather.'},
    );
    final data = result.data;
    if (!result.ok || data is! List) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach Home Assistant.')),
        );
      }
      return null;
    }
    final entities = [
      for (final e in data)
        if (e is Map && '${e['entity_id']}'.startsWith('weather.'))
          ('${e['entity_id']}', '${e['name'] ?? e['entity_id']}'),
    ];
    if (entities.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Home Assistant has no weather entities.'),
          ),
        );
      }
      return null;
    }
    if (!context.mounted) return null;
    return showRadioPicker<(String, String)>(
      context,
      title: 'Weather entity',
      options: [
        for (final e in entities) PickerOption(e, e.$2, detail: e.$1),
      ],
      selected: entities.where((e) => e.$1 == current).firstOrNull,
    );
  }

  Future<void> _edit(
    BuildContext context,
    ScreensaverWidget? existing,
  ) async {
    final others = [
      for (final w in _widgets())
        if (w.position != existing?.position) w,
    ];
    // Only unclaimed corners are offered: one widget per corner.
    final free = [
      for (final corner in cornerOptions)
        if (!others.any((w) => w.position == corner)) corner,
    ];
    var position = existing?.position ?? free.first;
    var type = existing?.type ?? screensaverWidgetTypes.first;
    // Defaults first, so entries saved before a type grew a key still edit
    // cleanly.
    var config = <String, Object?>{
      ...screensaverWidgetDefaults(type),
      ...?existing?.config,
    };
    // The weather location override; a controller so edits survive the
    // dialog's rebuilds.
    final labelCtrl = TextEditingController(
      text: '${config['label'] ?? ''}',
    );

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final note = _modeNote(type);
          final colorParts = '${config['color'] ?? ''}'
              .split(',')
              .map((p) => int.tryParse(p.trim()))
              .toList();
          final swatch =
              (colorParts.length == 3 && colorParts.every((p) => p != null))
              ? Color.fromARGB(
                  255,
                  colorParts[0]!,
                  colorParts[1]!,
                  colorParts[2]!,
                )
              : const Color(0xFFFAFAFA);
          // Both types carry a color; the toggle rows are per type.
          Widget colorRow() => ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Color'),
            trailing: GestureDetector(
              onTap: () async {
                final picked = await pickColor(
                  context,
                  initial: '${config['color'] ?? ''}',
                  title: 'Color',
                );
                if (picked != null) {
                  setDialogState(() => config['color'] = picked);
                }
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          );
          Widget toggle(String title, String key) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title),
            value: config[key] == true,
            onChanged: (v) => setDialogState(() => config[key] = v),
          );
          final weatherEntity = '${config['entity'] ?? ''}';
          final weatherName = '${config['name'] ?? ''}';
          return AlertDialog(
            // The widget's own name: the dialog reads as that widget's
            // settings, not as a generic form.
            title: Text(describeScreensaverWidgetType(type)),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    if (note != null)
                      Text(
                        note,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    DropdownButtonFormField<String>(
                      initialValue: position,
                      decoration: const InputDecoration(labelText: 'Corner'),
                      items: [
                        for (final corner in free)
                          DropdownMenuItem(
                            value: corner,
                            child: Text(cornerLabels[corner] ?? corner),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => position = value ?? position),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Widget'),
                      items: [
                        for (final t in screensaverWidgetTypes)
                          DropdownMenuItem(
                            value: t,
                            child: Text(describeScreensaverWidgetType(t)),
                          ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        if (value == null || value == type) return;
                        type = value;
                        // A different widget, different settings: start it
                        // from its own defaults.
                        config = {...screensaverWidgetDefaults(type)};
                        labelCtrl.text = '${config['label'] ?? ''}';
                      }),
                    ),
                    if (type == 'clock') ...[
                      colorRow(),
                      toggle('24-hour clock', 'h24'),
                      toggle('Show date', 'date'),
                    ],
                    if (type == 'weather') ...[
                      // The entity everything is read from; the friendly
                      // name is cached in the config so both editors can
                      // show it without a Home Assistant round trip.
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Weather entity'),
                        subtitle: Text(
                          weatherName.isNotEmpty
                              ? weatherName
                              : (weatherEntity.isNotEmpty
                                    ? weatherEntity
                                    : 'Not set'),
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await _pickWeatherEntity(
                              context,
                              weatherEntity,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                config['entity'] = picked.$1;
                                config['name'] = picked.$2;
                              });
                            }
                          },
                          child: const Text('Choose'),
                        ),
                      ),
                      // Weather entities carry no city attribute, so the
                      // place shown over the temperature is named by hand.
                      TextField(
                        controller: labelCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Location name',
                          helperText:
                              'Leave empty to hide the location line.',
                        ),
                        onChanged: (v) => config['label'] = v.trim(),
                      ),
                      colorRow(),
                      // The temperature always shows; each other line also
                      // needs the entity to carry the reading.
                      toggle('Location', 'location'),
                      toggle('Forecast', 'forecast'),
                      toggle('Humidity', 'humidity'),
                      toggle('Wind speed', 'wind'),
                      toggle('Visibility', 'visibility'),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                // A weather widget without its entity has nothing to show.
                onPressed: type == 'weather' && weatherEntity.isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: Text(existing == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
    labelCtrl.dispose();
    if (submitted != true) return;
    await _save([
      // The corner dropdown only offers free corners, but drop any claimant
      // anyway so a stale dialog cannot double-book one.
      for (final w in others)
        if (w.position != position) w,
      ScreensaverWidget(position: position, type: type, config: config),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final widgets = _widgets();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widgets.isEmpty)
          ListTile(
            title: const Text('No widgets yet'),
            subtitle: Text(screensaverWidgets.description),
          ),
        for (final w in widgets)
          ListTile(
            leading: Icon(_icon(w.type)),
            title: Text(describeScreensaverWidgetType(w.type)),
            subtitle: Text(cornerLabels[w.position] ?? w.position),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove widget',
              onPressed: () =>
                  _save([...widgets]..removeWhere(
                      (x) => x.position == w.position,
                    )),
            ),
            onTap: () => _edit(context, w),
          ),
        // Every corner taken means nothing left to add.
        if (widgets.length < cornerOptions.length)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: TextButton.icon(
                onPressed: () => _edit(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Add widget'),
              ),
            ),
          ),
      ],
    );
  }
}

/// A muted explanatory line inside a settings card, for context that is
/// not a control (where the motion camera picker used to be).
/// Wording for the Dim screensaver warning, shared with the remote admin
/// (which carries its own copy in the HTML).
const _dimModeNote =
    'WARNING: Dim keeps the dashboard visible, so the "Pause dashboard '
    'during screensaver" optimization will not be applied and the dashboard '
    'keeps using CPU, GPU and battery.';

/// A warning line under a setting's row, for a choice that carries a cost
/// the row itself does not show. Same shape as [HintRow], in the theme's
/// warning color.

/// Shown under "Enable camera" when the device has no camera at all
/// (a ROM without a camera HAL, e.g. LineageOS on an Echo Show): the
/// switches would work, the camera never will, so say it up front.
class _NoCameraRow extends StatelessWidget {
  const _NoCameraRow({required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: container.deviceCamera.cameraPresent(),
      builder: (context, snapshot) {
        if (snapshot.data != false) return const SizedBox.shrink();
        return ListTile(
          leading: Icon(
            Icons.no_photography_outlined,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const Text('No camera detected'),
          subtitle: const Text(
            'This device does not report any usable camera.',
          ),
        );
      },
    );
  }
}

class _CameraGrantRow extends StatefulWidget {
  const _CameraGrantRow({super.key});

  @override
  State<_CameraGrantRow> createState() => _CameraGrantRowState();
}

class _CameraGrantRowState extends State<_CameraGrantRow> {
  bool? _granted;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _granted = status.isGranted;
      _blocked = status.isPermanentlyDenied;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_granted != false) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.no_photography_outlined,
        color: theme.colorScheme.error,
      ),
      title: const Text('Camera'),
      subtitle: Text(
        _blocked
            ? 'Blocked. Android will not ask again, so allow it in the '
                  'app settings.'
            : 'Without this the camera cannot be used.',
      ),
      trailing: TextButton(
        onPressed: () async {
          if (_blocked) {
            await openOsAppSettings();
          } else {
            final outcome = await requestOsPermission(Permission.camera);
            if (outcome == PermissionOutcome.blocked && mounted) {
              setState(() => _blocked = true);
            }
          }
          await _refresh();
        },
        child: Text(_blocked ? 'App settings' : 'Grant'),
      ),
    );
  }
}

/// The Immich validate row, directly under the API key: mirrors the Home
/// Assistant connection card's gate. The rows below it only exist once the
/// server has actually answered with the calls the screensaver needs.
class _ImmichValidateRow extends StatefulWidget {
  const _ImmichValidateRow({required this.container, required this.onChanged});

  final AppContainer container;
  final VoidCallback onChanged;

  @override
  State<_ImmichValidateRow> createState() => _ImmichValidateRowState();
}

class _ImmichValidateRowState extends State<_ImmichValidateRow> {
  bool _validating = false;
  String? _error;

  Future<void> _validate() async {
    setState(() {
      _validating = true;
      _error = null;
    });
    final result = await widget.container.commands.execute(
      'immichValidate',
      const {},
    );
    if (!mounted) return;
    setState(() {
      _validating = false;
      _error = result.ok ? null : result.error;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final validated = widget.container.settings.get(screensaverImmichValidated);
    return ListTile(
      title: const Text('Validate connection'),
      subtitle: Text(
        _validating
            ? 'Checking…'
            : _error ??
                  (validated
                      ? 'Connected'
                      : 'Not validated yet. The settings below unlock once '
                            'the connection checks out.'),
      ),
      trailing: _validating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Icon(
              validated ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            ),
      onTap: _validating ? null : _validate,
    );
  }
}

/// The broker check, mirroring the Home Assistant and Immich rows: unlike
/// those it gates nothing, since MQTT publishes on its own schedule. It is
/// here to answer "are these credentials right?" without watching the log.
class _MqttValidateRow extends StatefulWidget {
  const _MqttValidateRow({required this.container});

  final AppContainer container;

  @override
  State<_MqttValidateRow> createState() => _MqttValidateRowState();
}

class _MqttValidateRowState extends State<_MqttValidateRow> {
  bool _validating = false;
  bool? _ok;
  String? _error;

  Future<void> _validate() async {
    setState(() {
      _validating = true;
      _error = null;
    });
    final result = await widget.container.commands.execute(
      'mqttValidate',
      const {},
    );
    if (!mounted) return;
    setState(() {
      _validating = false;
      _ok = result.ok;
      _error = result.ok ? null : result.error;
    });
  }

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('Validate connection'),
    subtitle: Text(
      _validating
          ? 'Checking…'
          : _error ??
                (_ok == true
                    ? 'Connected'
                    : 'Check the broker accepts these settings.'),
    ),
    trailing: _validating
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Icon(
            _ok == null
                ? Icons.cloud_queue_outlined
                : _ok!
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
          ),
    onTap: _validating ? null : _validate,
  );
}

/// The Music Assistant check, mirroring the Home Assistant, Immich and MQTT
/// rows: it opens the API with the address and token above and authenticates,
/// which is the only way to tell a wrong port from a wrong token.
class _MaValidateRow extends StatefulWidget {
  const _MaValidateRow({required this.container});

  final AppContainer container;

  @override
  State<_MaValidateRow> createState() => _MaValidateRowState();
}

class _MaValidateRowState extends State<_MaValidateRow> {
  bool _validating = false;
  bool? _ok;
  String? _message;

  Future<void> _validate() async {
    setState(() {
      _validating = true;
      _message = null;
    });
    final result = await widget.container.commands.execute(
      'maValidate',
      const {},
    );
    if (!mounted) return;
    setState(() {
      _validating = false;
      _ok = result.ok;
      if (result.ok) {
        final data = result.data;
        final version = data is Map ? data['version'] : null;
        _message = version == null
            ? 'Connected'
            : 'Connected to Music Assistant $version';
      } else {
        _message = result.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) => ListTile(
    title: const Text('Validate connection'),
    subtitle: Text(
      _validating
          ? 'Checking…'
          : _message ??
                'Check the address and token before turning on the shortcut or lyrics.',
    ),
    trailing: _validating
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          )
        : Icon(
            _ok == null
                ? Icons.cloud_queue_outlined
                : _ok!
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined,
          ),
    onTap: _validating ? null : _validate,
  );
}

/// Cache usage, directly under the cache size field: how many items sit on
/// disk and what they weigh, so the cap is a decision, not a guess.
class _ImmichCacheStatsRow extends StatefulWidget {
  const _ImmichCacheStatsRow({required this.container});

  final AppContainer container;

  @override
  State<_ImmichCacheStatsRow> createState() => _ImmichCacheStatsRowState();
}

class _ImmichCacheStatsRowState extends State<_ImmichCacheStatsRow> {
  Map<String, Object?>? _stats;

  @override
  void initState() {
    super.initState();
    widget.container.immich.cacheStats().then((stats) {
      if (mounted) setState(() => _stats = stats);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final text = stats == null
        ? '…'
        : '${stats['items']} cached, ${formatBytes(stats['bytes'] as int)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

/// Where to point the browser: shown under the Remote Administration
/// settings while the admin is enabled, since the address lives on the
/// device and nowhere else visible.
class _AdminAddressCard extends StatefulWidget {
  const _AdminAddressCard({required this.container});

  final AppContainer container;

  @override
  State<_AdminAddressCard> createState() => _AdminAddressCardState();
}

class _AdminAddressCardState extends State<_AdminAddressCard> {
  String? _ip;

  @override
  void initState() {
    super.initState();
    widget.container.device.ipAddress().then((ip) {
      if (mounted) setState(() => _ip = ip);
    });
  }

  @override
  Widget build(BuildContext context) {
    final port = widget.container.settings.get(remotePort).toInt();
    final address = 'http://${_ip ?? '…'}:$port';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('Access'),
        SettingsCard(
          children: [
            ListTile(
              title: const Text('Admin address'),
              subtitle: const Text(
                'Open this address in a browser on your computer.',
              ),
              trailing: Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrightnessGrantCard extends StatefulWidget {
  const _BrightnessGrantCard({required this.container});

  final AppContainer container;

  @override
  State<_BrightnessGrantCard> createState() => _BrightnessGrantCardState();
}

class _BrightnessGrantCardState extends State<_BrightnessGrantCard> {
  bool? _granted;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final permissions = await SystemPermissions.read();
    if (!mounted) return;
    setState(() => _granted = permissions.writeSettings);
    if (permissions.writeSettings) _poll?.cancel();
  }

  Future<void> _request() async {
    await widget.container.commands.execute('requestOsPermissions', {
      'which': ['writeSettings'],
    });
    // The grant happens on Android's own settings screen; keep re-reading
    // until it lands so the notice dismisses itself.
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _check());
    Timer(const Duration(minutes: 2), () => _poll?.cancel());
  }

  @override
  Widget build(BuildContext context) {
    if (_granted != false) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('Permission'),
        SettingsCard(
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: const Text('Brightness is using a fallback'),
              subtitle: const Text(
                'Without the "Modify system settings" permission, '
                'brightness changes only dim this app instead of setting '
                "the panel's actual brightness.",
              ),
              trailing: FilledButton.tonal(
                onPressed: _request,
                child: const Text('Grant'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shown on the Screen page only on a device that keeps its panel lit after
/// a screen-off: an always-on lock screen the app has no way to override.
/// The row exists because the alternative is a "Screen off" that appears not
/// to work, and a Home Assistant entity that has quietly withdrawn itself
/// with no explanation anywhere (issue #51).
class _AmbientDisplayCard extends StatefulWidget {
  const _AmbientDisplayCard({required this.container});

  final AppContainer container;

  @override
  State<_AmbientDisplayCard> createState() => _AmbientDisplayCardState();
}

class _AmbientDisplayCardState extends State<_AmbientDisplayCard> {
  StreamSubscription<AmbientDisplayChanged>? _sub;

  @override
  void initState() {
    super.initState();
    // The switch is flipped in Android's settings, not here, so the row has
    // to appear and disappear on its own while this page is open.
    _sub = widget.container.bus.on<AmbientDisplayChanged>().listen(
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.container.screen.ambientDisplay) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SectionHeading('Always-on display'),
        SettingsCard(
          children: [
            ListTile(
              leading: Icon(Icons.brightness_low_outlined),
              title: Text('This device keeps a dim clock on'),
              subtitle: Text(
                'Turning the screen off puts the device to sleep, but the '
                'always-on display lights the lock screen back up and no app '
                'can stop it. Turn off "Always show time and info" in '
                'Android settings under Display, near the lock screen '
                'options; some ROMs call it always-on display. The Home '
                'Assistant screen entity stays unavailable until you do.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The Optimizations group: the two connection/performance toggles, with live
/// telemetry beneath the update filter so it is visible that it is working
/// (how much of the Home Assistant update stream it is dropping for this view).
class _OptimizationsCard extends StatefulWidget {
  const _OptimizationsCard({required this.container});

  final AppContainer container;

  @override
  State<_OptimizationsCard> createState() => _OptimizationsCardState();
}

class _OptimizationsCardState extends State<_OptimizationsCard> {
  Timer? _poll;
  ({int allow, int total, int dropped})? _stats;
  bool _ready = false;

  /// The wrapper's reported mode: 'filtering', 'passthrough' (this view's
  /// entities cannot be determined, so it is deliberately unfiltered), or
  /// 'boot' while the allowlist has not been built yet.
  String _mode = 'boot';

  /// Tap on the "Watching N entities" link: opens the watched-entities list.
  late final TapGestureRecognizer _watchLink = TapGestureRecognizer()
    ..onTap = _showWatched;

  /// Samples of the wrapper's cumulative counters, kept for the last minute
  /// so the row reports a live rate — the raw counters run since page load
  /// and a lifetime total ("206980 of 206980") reads as a bug, not a status.
  final List<(DateTime, int total, int fwd)> _hist = [];

  AppContainer get c => widget.container;
  bool get _filterOn => c.settings.get(wsFilter);

  @override
  void initState() {
    super.initState();
    _syncPolling();
  }

  /// Poll the in-page filter's counters only while the filter is on.
  void _syncPolling() {
    if (_filterOn && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
      _refresh();
    } else if (!_filterOn && _poll != null) {
      _poll!.cancel();
      _poll = null;
      _stats = null;
      _ready = false;
      _hist.clear();
    }
  }

  Future<void> _refresh() async {
    final raw = await c.browser.eval(
      'JSON.stringify(window.__ksWs ? window.__ksWs.stats() : null)',
    );
    if (!mounted) return;
    Object? decoded;
    try {
      decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is String) {
        decoded = jsonDecode(decoded); // some engines double-encode
      }
    } catch (_) {
      decoded = null;
    }
    if (decoded is! Map || decoded['mode'] == null) {
      setState(() {
        _ready = false;
        _mode = 'boot';
        _stats = null;
        _hist.clear();
      });
      return;
    }
    if (decoded['mode'] != 'filtering') {
      setState(() {
        _ready = true;
        _mode = '${(decoded as Map)['mode']}';
        _stats = null;
        _hist.clear();
      });
      return;
    }
    final total = (decoded['cTotal'] as num?)?.toInt() ?? 0;
    final fwd = (decoded['cFwd'] as num?)?.toInt() ?? 0;
    final now = DateTime.now();
    // A page reload resets the counters; a shrinking total means the history
    // belongs to a previous page and must be discarded.
    if (_hist.isNotEmpty && total < _hist.last.$2) _hist.clear();
    _hist.add((now, total, fwd));
    _hist.removeWhere((s) => now.difference(s.$1) > const Duration(minutes: 1));
    // Deltas over the retained window, not lifetime counts.
    final dTotal = _hist.length > 1 ? total - _hist.first.$2 : 0;
    final dFwd = _hist.length > 1 ? fwd - _hist.first.$3 : 0;
    setState(() {
      _ready = true;
      _mode = 'filtering';
      _stats = (
        allow: decoded is Map && decoded['allow'] is num
            ? (decoded['allow'] as num).toInt()
            : 0,
        total: dTotal,
        dropped: dTotal - dFwd,
      );
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _watchLink.dispose();
    super.dispose();
  }

  void _onToggle() {
    _syncPolling();
    if (mounted) setState(() {});
  }

  /// The filter's current allowlist, with friendly names from the page's own
  /// state store, shown in a dialog so "Watching N entities" is inspectable.
  Future<void> _showWatched() async {
    final raw = await c.browser.eval(
      '(function(){var S=window.__ksWs;if(!S||!S.allow)return "null";'
      'var h=document.querySelector("home-assistant");'
      'var st=(h&&h.hass&&h.hass.states)||{};'
      'var out=Array.from(S.allow).map(function(id){var s=st[id];'
      'return {id:id,name:(s&&s.attributes&&s.attributes.friendly_name)||""};});'
      'out.sort(function(a,b){return (a.name||a.id).localeCompare(b.name||b.id);});'
      'return JSON.stringify(out);})()',
    );
    Object? decoded;
    try {
      decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is String) decoded = jsonDecode(decoded);
    } catch (_) {
      decoded = null;
    }
    if (!mounted || decoded is! List || decoded.isEmpty) return;
    final items = [
      for (final e in decoded)
        if (e is Map) (id: '${e['id']}', name: '${e['name'] ?? ''}'),
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Watched entities (${items.length})'),
        content: SizedBox(
          width: 420,
          child: EdgeFade(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final it in items)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(it.name.isEmpty ? it.id : it.name),
                    subtitle: it.name.isEmpty ? null : Text(it.id),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsCard(
      children: [
        SettingTile(container: c, def: disableSuspend, onChanged: _onToggle),
        SettingTile(
          container: c,
          def: freezeOnScreensaver,
          onChanged: _onToggle,
        ),
        SettingTile(container: c, def: wsFilter, onChanged: _onToggle),
        if (_filterOn) _telemetry(theme),
      ],
    );
  }

  Widget _telemetry(ThemeData theme) {
    final s = _stats;
    final pct = (s != null && s.total > 0)
        ? (100 * s.dropped / s.total).round()
        : null;
    final base = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Filtering with data: the "Watching N entities" sentence is a link that
    // opens the watched-entities list, so the number is inspectable.
    if (_ready && _mode == 'filtering' && s != null) {
      final rest = pct == null
          ? ' No updates in the last minute.'
          : ' Filtered $pct% of updates in the last minute '
                '(${s.dropped} of ${s.total}).';
      return _telemetryRow(
        theme,
        Text.rich(
          TextSpan(
            style: base,
            children: [
              TextSpan(
                text: 'Watching ${s.allow} entities on this view.',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
                recognizer: _watchLink,
              ),
              TextSpan(text: rest),
            ],
          ),
        ),
      );
    }
    final text = _ready && _mode == 'passthrough'
        ? 'This view\'s entities can\'t be determined, so its updates '
              'are not filtered.'
        : 'Waiting for the dashboard to load...';
    return _telemetryRow(theme, Text(text, style: base));
  }

  Widget _telemetryRow(ThemeData theme, Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.insights_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    ),
  );
}

/// The dashboard chooser: every Home Assistant dashboard as a radio row;
/// the chosen one becomes the start URL. The kiosk navigates immediately —
/// picking a dashboard and not seeing it would read as a failed tap.
class _DashboardPickerCard extends StatefulWidget {
  const _DashboardPickerCard({required this.container});

  final AppContainer container;

  @override
  State<_DashboardPickerCard> createState() => _DashboardPickerCardState();
}

class _DashboardPickerCardState extends State<_DashboardPickerCard> {
  late Future<List<Map<String, Object?>>?> _dashboards;

  // Views of the currently selected dashboard, loaded lazily: listing every
  // sub-view of every dashboard would be an unusable wall, so only the chosen
  // dashboard's views are fetched, for its row and the "Change view" popup.
  // `_viewsFor` is the url_path they belong to; a null list is a strategy
  // dashboard whose view list cannot be read.
  List<Map<String, Object?>>? _views;
  String? _viewsFor;

  AppContainer get c => widget.container;
  String get _base => c.homeAssistant.baseUrl;

  @override
  void initState() {
    super.initState();
    _dashboards = c.homeAssistant.listDashboards();
  }

  /// The selected dashboard's url_path, matched against the stored start URL
  /// by prefix (the URL also carries the view route, and maybe a ?kiosk).
  String? _selectedDash(List<Map<String, Object?>> dashboards) {
    final current = c.settings.get(startUrl);
    for (final d in dashboards) {
      final url = '$_base/${d['url_path']}';
      if (current == url || current.startsWith('$url/')) {
        return '${d['url_path']}';
      }
    }
    return null;
  }

  /// The view route within [urlPath] the start URL points at, or '' for the
  /// dashboard's default (first) view.
  String _selectedRoute(String urlPath) {
    final current = c.settings.get(startUrl);
    final prefix = '$_base/$urlPath/';
    return current.startsWith(prefix) ? current.substring(prefix.length) : '';
  }

  String _viewPath(String urlPath, String route) =>
      route.isEmpty ? urlPath : '$urlPath/$route';

  Future<void> _apply(String urlPath, String route) async {
    final url = route.isEmpty ? '$_base/$urlPath' : '$_base/$urlPath/$route';
    await c.settings.set(startUrl, url);
    await c.commands.execute('loadUrl', {'url': url});
    if (mounted) setState(() {});
  }

  /// Select a dashboard: load its views and land on the first one.
  Future<void> _pickDashboard(String urlPath) async {
    final views = await c.homeAssistant.listDashboardViews(urlPath);
    final route = (views != null && views.isNotEmpty)
        ? '${views.first['route']}'
        : '';
    if (mounted) {
      setState(() {
        _views = views;
        _viewsFor = urlPath;
      });
    }
    await _apply(urlPath, route);
  }

  /// The "Change view" popup: the dashboard's views as a radio list.
  Future<void> _changeView(String urlPath) async {
    final views = _views;
    if (views == null || views.isEmpty) return;
    final current = _selectedRoute(urlPath);
    final picked = await showRadioPicker<String>(
      context,
      title: 'Choose a view',
      selected: current,
      options: [
        for (final v in views)
          PickerOption(
            '${v['route']}',
            '${v['title']}',
            detail: _viewPath(urlPath, '${v['route']}'),
          ),
      ],
    );
    if (picked != null && picked != current) await _apply(urlPath, picked);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>?>(
      future: _dashboards,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SettingsCard(
            children: [
              ListTile(
                title: Text('Loading dashboards…'),
                trailing: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ],
          );
        }
        final dashboards = snapshot.data;
        if (dashboards == null || dashboards.isEmpty) {
          return SettingsCard(
            children: [
              ListTile(
                title: const Text('Could not list dashboards'),
                subtitle: const Text('Tap to retry.'),
                trailing: const Icon(Icons.refresh),
                onTap: () => setState(() {
                  _dashboards = c.homeAssistant.listDashboards();
                }),
              ),
            ],
          );
        }
        final selectedDash = _selectedDash(dashboards);
        // Lazily load the selected dashboard's views so its row can show the
        // chosen view and offer "Change view". Guard re-entry with _viewsFor.
        if (selectedDash != null && _viewsFor != selectedDash) {
          _viewsFor = selectedDash;
          c.homeAssistant.listDashboardViews(selectedDash).then((v) {
            if (mounted) setState(() => _views = v);
          });
        }
        return SettingsCard(
          children: [
            for (final d in dashboards)
              _dashRow(
                context,
                '${d['url_path']}',
                '${d['title'] ?? d['url_path']}',
                selectedDash,
              ),
          ],
        );
      },
    );
  }

  Widget _dashRow(
    BuildContext context,
    String urlPath,
    String title,
    String? selectedDash,
  ) {
    final theme = Theme.of(context);
    final selected = selectedDash == urlPath;
    // The selected row shows the chosen view's path (defaulting to the first
    // view); the others just name the dashboard. Only the selected row can
    // change its view.
    final subtitle = selected
        ? _viewPath(urlPath, _selectedRoute(urlPath))
        : urlPath;
    final hasViews = selected && _views != null && _views!.isNotEmpty;
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? TextButton(
              onPressed: hasViews ? () => _changeView(urlPath) : null,
              child: const Text('Change view'),
            )
          : null,
      onTap: selected ? null : () => _pickDashboard(urlPath),
    );
  }
}

/// Dashboard view rotation: the enable toggle, then (once on) the user's
/// dashboards as plain headers with a checkbox per view beneath each, and
/// the dwell time. The selection is stored as a JSON array of navigation
/// paths ("url_path/view-route") in the hidden ha.rotation_dashboards
/// setting; the rotation itself runs in HomeAssistantManager.
class _RotationCard extends StatefulWidget {
  const _RotationCard({required this.container, this.onChanged});

  final AppContainer container;

  /// Fired when the enable toggle flips, so the parent pane can refresh
  /// what gates on it (the Return to Dashboard switch below).
  final VoidCallback? onChanged;

  @override
  State<_RotationCard> createState() => _RotationCardState();
}

class _RotationCardState extends State<_RotationCard> {
  late Future<List<(String, String, List<Map<String, Object?>>)>?> _views;

  AppContainer get c => widget.container;

  @override
  void initState() {
    super.initState();
    _views = _load();
  }

  /// Every dashboard with its views: (title, url_path, views). A dashboard
  /// whose config cannot be read (auto-generated strategies) still rotates
  /// as a whole via a single synthetic entry for its first view.
  Future<List<(String, String, List<Map<String, Object?>>)>?> _load() async {
    final dashboards = await c.homeAssistant.listDashboards();
    if (dashboards == null) return null;
    final views = await Future.wait([
      for (final d in dashboards)
        c.homeAssistant.listDashboardViews('${d['url_path']}'),
    ]);
    return [
      for (final (i, d) in dashboards.indexed)
        (
          '${d['title'] ?? d['url_path']}',
          '${d['url_path']}',
          views[i] == null || views[i]!.isEmpty
              // A dashboard whose views cannot be read (the auto "Overview"
              // and other strategy dashboards) rotates as a whole via its
              // bare path — an empty route, navigated as /<url_path>, which
              // resolves the default view. A synthetic "/0" would spin.
              ? [
                  {'title': 'Default view', 'route': ''},
                ]
              : views[i]!,
        ),
    ];
  }

  List<String> _selected() {
    try {
      final list = jsonDecode(c.settings.get(haRotationDashboards)) as List;
      return [
        for (final p in list)
          if (p is String) p,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _toggle(String path) async {
    final selected = _selected();
    selected.contains(path) ? selected.remove(path) : selected.add(path);
    await c.settings.setFromJson(
      haRotationDashboards.key,
      jsonEncode(selected),
    );
    if (mounted) setState(() {});
  }

  final _urlField = TextEditingController();

  List<String> _urls() {
    try {
      final list = jsonDecode(c.settings.get(haRotationUrls)) as List;
      return [
        for (final u in list)
          if (u is String) u,
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveUrls(List<String> urls) async {
    await c.settings.setFromJson(haRotationUrls.key, jsonEncode(urls));
    if (mounted) setState(() {});
  }

  Future<void> _addUrl() async {
    var url = _urlField.text.trim();
    if (url.isEmpty) return;
    // A bare host is almost always meant as a web address; default the
    // scheme so the WebView does not treat it as a relative path.
    if (!url.contains('://')) url = 'https://$url';
    final urls = _urls();
    if (!urls.contains(url)) urls.add(url);
    _urlField.clear();
    await _saveUrls(urls);
  }

  @override
  void dispose() {
    _urlField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = c.settings.get(haRotationEnabled);
    return SettingsCard(
      children: [
        SettingTile(
          container: c,
          def: haRotationEnabled,
          onChanged: () {
            setState(() {});
            widget.onChanged?.call();
          },
        ),
        if (enabled) ...[
          SettingTile(
            container: c,
            def: haRotationSeconds,
            onChanged: () => setState(() {}),
          ),
          SettingTile(
            container: c,
            def: haRotationPauseSeconds,
            onChanged: () => setState(() {}),
          ),
          SettingTile(
            container: c,
            def: haRotationCrossfade,
            onChanged: () => setState(() {}),
          ),
          FutureBuilder<List<(String, String, List<Map<String, Object?>>)>?>(
            future: _views,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ListTile(
                  title: Text('Loading dashboards…'),
                  trailing: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              }
              final dashboards = snapshot.data;
              if (dashboards == null || dashboards.isEmpty) {
                return ListTile(
                  title: const Text('Could not list dashboards'),
                  subtitle: const Text('Tap to retry.'),
                  trailing: const Icon(Icons.refresh),
                  onTap: () => setState(() {
                    _views = _load();
                  }),
                );
              }
              final selected = _selected();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (title, urlPath, views) in dashboards) ...[
                    // The dashboard is a plain header, not a choice — the
                    // views beneath it are what rotate.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
                      child: Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final v in views)
                      // Empty route = the dashboard's bare path.
                      for (final path in [
                        '${v['route']}'.isEmpty
                            ? urlPath
                            : '$urlPath/${v['route']}',
                      ])
                        CheckboxListTile(
                          value: selected.contains(path),
                          title: Text('${v['title']}'),
                          subtitle: Text(path),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.only(
                            left: 28,
                            right: 20,
                          ),
                          onChanged: (_) => _toggle(path),
                        ),
                  ],
                  const SizedBox(height: 6),
                ],
              );
            },
          ),
          // External pages: shown in their own overlay during rotation, so
          // the dashboard (and Voice Satellite) stays loaded underneath.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
            child: Text(
              'External pages',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final url in _urls())
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 28, right: 12),
              title: Text(url, style: theme.textTheme.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Remove',
                onPressed: () => _saveUrls(_urls()..remove(url)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlField,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onSubmitted: (_) => _addUrl(),
                    // Border and fill come from the input theme.
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'https://example.com',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addUrl, child: const Text('Add')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The maker's mark, closing every settings page: centered, quiet, with
/// the name linking to GitHub and the coffee cup to the tip jar. Links
/// open in the kiosk view, the only browser this device has.
class _MadeByFooter extends StatelessWidget {
  const _MadeByFooter({required this.container});

  final AppContainer container;

  void _open(BuildContext context, String url) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    container.commands.execute('loadUrl', {'url': url});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final link = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 18, Ks.inset, 10),
      // scaleDown: the line is a touch wider than a phone pane, and an
      // overflowing Row clips at the right edge and loses its centering.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Made with ', style: muted),
            // An icon, not the \u2665 character: Android renders that
            // codepoint as the emoji glyph, which ignores text color
            // entirely and always shows its own saturated red.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Icon(Icons.favorite, size: 15, color: Color(0xFFE86A6A)),
            ),
            Text(' by ', style: muted),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _open(context, 'https://github.com/jxlarrea'),
              child: Text('Xavier Larrea', style: link),
            ),
            Text(' \u00b7 \u2615 ', style: muted),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _open(context, 'https://buymeacoffee.com/jxlarrea'),
              child: Text('Buy me a coffee', style: link),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wording for the Microphone settings group, shared with the remote admin
/// (which carries its own copy in the HTML).
const _micGroupNote =
    'Only for devices that capture too quietly. Wrong values make wake word '
    'detection worse.';

const _permissionsGroupNote =
    'Grants are given on this device, so each button opens an Android '
    'dialog or settings screen here. Some brands add their own battery or '
    'autostart manager on top, which Android cannot report.';

/// A microphone or speaker picker over the live device list ([def] selects
/// which). Options come from getAudioDevices at open; the stored value is
/// AudioRouting's stable selector, so a device that is currently off still
/// shows (by the name embedded in its selector) instead of being silently
/// forgotten.
class AudioDeviceTile extends StatefulWidget {
  const AudioDeviceTile({
    super.key,
    required this.container,
    required this.def,
    required this.inputs,
  });

  final AppContainer container;
  final SettingDef<String> def;

  /// True lists capture devices, false playback devices.
  final bool inputs;

  @override
  State<AudioDeviceTile> createState() => _AudioDeviceTileState();
}

class _AudioDeviceTileState extends State<AudioDeviceTile> {
  List<(String, String)>? _devices; // (selector, label), null while loading
  StreamSubscription<AudioDevicesChanged>? _hotplug;

  @override
  void initState() {
    super.initState();
    _load();
    // A Bluetooth headset connecting while this page is open should appear
    // without reopening settings.
    _hotplug = widget.container.bus.on<AudioDevicesChanged>().listen(
      (_) => _load(),
    );
  }

  @override
  void dispose() {
    _hotplug?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await widget.container.commands.execute(
      'getAudioDevices',
      const {},
    );
    if (!mounted) return;
    final data = result.data;
    final list = (data is Map
        ? data[widget.inputs ? 'inputs' : 'outputs']
        : null);
    setState(() {
      _devices = [
        if (list is List)
          for (final d in list)
            if (d is Map) ('${d['selector']}', '${d['label']}'),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    final current = c.settings.get(widget.def);
    final devices = _devices;
    final options = <(String, String)>[
      ('', 'Automatic'),
      ...?devices,
      // A configured device that is not present right now: keep it choosable
      // (it comes back when the device does), named from its selector.
      if (devices != null &&
          current.isNotEmpty &&
          !devices.any((d) => d.$1 == current))
        (
          current,
          '${current.split('|').length > 2 && current.split('|')[2].isNotEmpty ? current.split('|')[2] : 'Selected device'} (not connected)',
        ),
    ];
    if (devices == null) {
      return ListTile(
        title: Text(widget.def.title),
        subtitle: Text(widget.def.description),
        trailing: const Text('…'),
      );
    }
    return DropdownRow<String>(
      title: widget.def.title,
      description: widget.def.description,
      value: options.any((o) => o.$1 == current) ? current : '',
      options: options,
      onChanged: (v) async {
        if (v == null) return;
        await c.settings.setFromJson(widget.def.key, v);
        if (mounted) setState(() {});
      },
    );
  }
}

/// The capture channel of a multichannel microphone, in the Microphone
/// settings group. Hand-built because the option list is live hardware: the
/// row only exists while the selected microphone reports more than one
/// channel, and the options run to its count. Downmix (every channel
/// averaged by the platform) is the default and the app's historical
/// behavior; arrays like the reSpeaker XVF3800 reserve a channel for
/// recognition engines, and picking it keeps the call-processed channel out
/// of the wake models.
class MicChannelTile extends StatefulWidget {
  const MicChannelTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<MicChannelTile> createState() => _MicChannelTileState();
}

class _MicChannelTileState extends State<MicChannelTile> {
  int _channels = 0; // of the selected mic; below 2 renders nothing

  StreamSubscription<AudioDevicesChanged>? _hotplug;
  StreamSubscription<SettingChanged>? _selection;

  @override
  void initState() {
    super.initState();
    _load();
    // Both the hardware changing under the selection and the selection
    // itself: the row follows whichever microphone capture would use now.
    _hotplug = widget.container.bus.on<AudioDevicesChanged>().listen(
      (_) => _load(),
    );
    _selection = widget.container.bus.on<SettingChanged>().listen((e) {
      if (e.key == audioMicDevice.key) _load();
    });
  }

  @override
  void dispose() {
    _hotplug?.cancel();
    _selection?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final c = widget.container;
    final selected = c.settings.get(audioMicDevice);
    var channels = 0;
    if (selected.isNotEmpty) {
      final result = await c.commands.execute('getAudioDevices', const {});
      final data = result.data;
      final list = data is Map ? data['inputs'] : null;
      if (list is List) {
        for (final d in list) {
          if (d is Map && '${d['selector']}' == selected) {
            channels = (d['channels'] as num?)?.toInt() ?? 0;
          }
        }
      }
    }
    if (!mounted) return;
    setState(() => _channels = channels);
  }

  @override
  Widget build(BuildContext context) {
    if (_channels < 2) return const SizedBox.shrink();
    final c = widget.container;
    final current = c.settings.get(micChannel).toInt();
    final options = <(num, String)>[
      (0, 'Downmix (default)'),
      for (var i = 1; i <= _channels; i++) (i, 'Channel $i'),
      // A stored channel beyond what the mic reports stays visible instead
      // of masquerading as another option; capture falls back to the mono
      // downmix until it is repicked.
      if (current > _channels)
        (current, 'Channel $current (not on this microphone)'),
    ];
    return DropdownRow<num>(
      title: micChannel.title,
      description: micChannel.description,
      value: current,
      options: options,
      onChanged: (v) async {
        if (v == null) return;
        await c.settings.setFromJson(micChannel.key, v);
        if (mounted) setState(() {});
      },
    );
  }
}

/// Read-only status of the wake-word config inherited from Voice Satellite:
/// the active engine, the wake word(s), and whether native inference is
/// running. Updates live as the VS card pushes config / state changes.
class WakeWordStatusTile extends StatefulWidget {
  const WakeWordStatusTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<WakeWordStatusTile> createState() => _WakeWordStatusTileState();
}

class _WakeWordStatusTileState extends State<WakeWordStatusTile> {
  StreamSubscription<WakeWordStateChanged>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<WakeWordStateChanged>().listen(
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wake = widget.container.wakeWord;
    final config = wake.config;
    final status = wake.status;

    // Before the card has pushed a config there is nothing to show but the
    // status itself. The wording is the manager's, so the web admin says it
    // word for word (see WakeWordManager.status).
    if (config == null || !wake.enabled) {
      return ListTile(
        leading: Icon(
          status.code == 'disabled'
              ? Icons.mic_off_outlined
              : Icons.hourglass_empty,
        ),
        title: Text(
          status.code == 'disabled'
              ? 'Wake word detection is off'
              : 'Waiting for Voice Satellite',
        ),
        subtitle: Text(status.label),
      );
    }

    final statusColor = wake.available
        ? (wake.listening
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface)
        : theme.colorScheme.error;

    // Every row the same shape: label on the left, value on the right. These
    // are the same rows the remote admin lists, in the same order, because they
    // describe the same device — see loadWakeWord() in
    // assets/remote-ui/index.html.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: separatedRows([
        ListTile(
          leading: Icon(
            wake.available
                ? (wake.listening ? Icons.mic : Icons.mic_none)
                : Icons.warning_amber_rounded,
            color: statusColor,
          ),
          title: const Text('Status'),
          subtitle: Text(
            status.label,
            style: theme.textTheme.bodyMedium?.copyWith(color: statusColor),
          ),
        ),
        if (wake.canRetry) WakeWordRecoveryTile(container: widget.container),
        ListTile(
          leading: const Icon(Icons.graphic_eq),
          title: const Text('Engine'),
          subtitle: const Text('Running in Kiosk'),
          trailing: Text(
            config.engine.label,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (config.models.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('Wake words'),
            subtitle: const Text('Running in Kiosk'),
            trailing: _rowValue(
              context,
              config.models.map((m) => m.wakeWord).join(', '),
            ),
          ),
        if (config.stopModel != null)
          ListTile(
            leading: const Icon(Icons.front_hand_outlined),
            title: const Text('Stop word'),
            subtitle: Text(
              wake.stopWordAvailable
                  ? 'Running in Kiosk'
                  : 'Voice Satellite keeps this one in the browser',
            ),
            trailing: _rowValue(context, config.stopModel!.wakeWord),
          ),
        ClearModelCacheTile(container: widget.container),
      ]),
    );
  }
}

/// A row's value, right-aligned. Bounded because a ListTile's trailing sits in
/// an unconstrained Row: two wake words are wider than they look.
Widget _rowValue(BuildContext context, String text) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 280),
  child: Text(
    text,
    textAlign: TextAlign.end,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodyLarge,
  ),
);

/// The way out of a failed engine.
///
/// Mirrored by the web admin, which offers the same two actions from the same
/// state (`canRetry` / `needsAppSettings`). A blocked microphone is the reason
/// this exists: Android stops asking after the second refusal, the browser
/// fallback needs the same permission and goes quiet too, and without an offer
/// to open the OS settings a single stray tap disables wake words for good on a
/// device whose owner may never see a system UI again.
class WakeWordRecoveryTile extends StatefulWidget {
  const WakeWordRecoveryTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<WakeWordRecoveryTile> createState() => _WakeWordRecoveryTileState();
}

class _WakeWordRecoveryTileState extends State<WakeWordRecoveryTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final wake = widget.container.wakeWord;
    final settingsFirst = wake.needsAppSettings;

    // What went wrong is the Status row's job, right above this. This row is
    // what to do about it — same split as the remote admin's Recover row.
    return ListTile(
      leading: const Icon(Icons.build_outlined),
      title: const Text('Recover'),
      subtitle: Text(
        settingsFirst
            ? 'Allow the microphone in the app settings, then retry.'
            : 'Try starting the engine again.',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (settingsFirst)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => widget.container.commands.execute(
                      'openAppSettings',
                      const {},
                    ),
              child: const Text('App settings'),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await widget.container.commands.execute(
                      'retryWakeWord',
                      const {},
                    );
                    if (mounted) setState(() => _busy = false);
                  },
            child: Text(_busy ? 'Retrying…' : 'Retry'),
          ),
        ],
      ),
    );
  }
}

/// Every OS grant the app can use, in one list, on the Device page (issue
/// #156).
///
/// The per-feature groups elsewhere are deliberately narrow: they show what
/// the feature being configured needs, right where it is configured. The cost
/// is that a grant no enabled feature asks for is reachable from nowhere —
/// the battery exemption used to appear only under background wake-word
/// listening, so a kiosk with no voice at all could not find the one grant
/// that keeps its Home Assistant connection alive in Doze, which is the
/// report this list comes from.
///
/// Three states rather than two, because a flat granted/missing list would
/// paint half the rows red on any setup that does not use every feature:
///   * granted — held, nothing to do
///   * missing — not held AND something currently switched on needs it, so
///     something is broken right now
///   * not granted — not held and nothing needs it yet; muted, still
///     grantable, so anything can be given ahead of turning its feature on
///
/// Read on build and again on resume: these are Android dialogs and settings
/// screens that report nothing back, so returning to the app is the only
/// reliable moment to re-read them.
class _DevicePermissionsTile extends StatefulWidget {
  const _DevicePermissionsTile({required this.container});

  final AppContainer container;

  @override
  State<_DevicePermissionsTile> createState() => _DevicePermissionsTileState();
}

class _DevicePermissionsTileState extends State<_DevicePermissionsTile>
    with WidgetsBindingObserver {
  SystemPermissions? _perms;
  bool? _uiGuard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    SystemPermissions? perms;
    bool? uiGuard;
    try {
      perms = await SystemPermissions.read();
    } catch (_) {}
    try {
      uiGuard = await widget.container.kiosk.uiGuardEnabled();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _perms = perms;
      _uiGuard = uiGuard;
    });
  }

  /// One grant. [needed] drives the middle state: not held and needed reads
  /// as an error, not held and unneeded stays muted and merely informative.
  Widget _row({
    required bool? granted,
    required bool needed,
    required IconData missingIcon,
    required String title,
    required String held,
    required String missing,
    required String idle,
    required Future<void> Function() onGrant,
    String action = 'Grant',
  }) {
    final theme = Theme.of(context);
    final ok = granted == true;
    final muted = theme.colorScheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(
        ok ? Icons.check_circle_outline : missingIcon,
        color: ok
            ? null
            : needed
            ? theme.colorScheme.error
            : muted,
      ),
      title: Text(title),
      subtitle: Text(
        ok
            ? held
            : needed
            ? missing
            : idle,
        style: ok || needed ? null : TextStyle(color: muted),
      ),
      trailing: ok
          ? null
          : TextButton(
              onPressed: () async {
                await onGrant();
                await _refresh();
              },
              child: Text(action),
            ),
    );
  }

  Future<void> _requestVia(String which) async {
    await widget.container.commands.execute('requestOsPermissions', {
      'which': [which],
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.container.settings;
    final perms = _perms;
    final background =
        settings.get(wakeWordEnabled) && settings.get(wakeWordBackground);
    final micBlocked = perms?.microphoneBlocked == true;
    return Column(
      children: separatedRows([
        _row(
          granted: perms?.microphone,
          needed: settings.get(wakeWordEnabled),
          missingIcon: Icons.mic_off_outlined,
          title: 'Microphone',
          held:
              'Allows microphone usage for wake word detection and speech to text.',
          missing: micBlocked
              ? 'Blocked. Android will not ask again, so allow it in the '
                    'app settings.'
              : 'Wake word detection is on and nothing is listening.',
          idle:
              'Needed by wake word detection and by pages that ask for '
              'the microphone.',
          action: micBlocked ? 'App settings' : 'Grant',
          onGrant: () async {
            if (micBlocked) {
              await openOsAppSettings();
            } else {
              await ensureOsPermission(Permission.microphone);
            }
          },
        ),
        // Always needed: the app keeps its Home Assistant and MQTT
        // connections alive while the screen is off, and Doze is what stops
        // them. Nothing has to be switched on for this one to matter.
        _row(
          granted: perms?.batteryUnrestricted,
          needed: true,
          missingIcon: Icons.battery_alert_outlined,
          title: 'Unrestricted battery',
          held:
              'Allows the process to run in the background without being paused or killed.',
          missing:
              'Android may pause the app when the screen is off, dropping '
              'the Home Assistant connection and the MQTT entities with it.',
          idle: '',
          onGrant: BackgroundListening.requestBatteryUnrestricted,
        ),
        _row(
          granted: perms?.camera,
          needed: settings.get(cameraEnabled),
          missingIcon: Icons.videocam_off_outlined,
          title: 'Camera',
          held: 'Motion detection and snapshots can use the camera.',
          missing: 'The camera is switched on and cannot be opened.',
          idle:
              'Needed by motion detection, camera snapshots and pages '
              'that ask for the camera.',
          onGrant: () => ensureOsPermission(Permission.camera),
        ),
        _row(
          granted: perms?.notification,
          needed: background,
          missingIcon: Icons.notifications_off_outlined,
          title: 'Notifications',
          held: 'The ongoing notification that keeps listening alive.',
          missing: 'Background listening needs it to run reliably.',
          idle: 'Needed by background wake word listening.',
          onGrant: () => ensureOsPermission(Permission.notification),
        ),
        _row(
          granted: perms?.displayOverOtherApps,
          needed:
              background ||
              settings.get(autoReloadOnError) ||
              settings.get(kioskStartOnBoot) ||
              settings.get(kioskDisableStatusBar),
          missingIcon: Icons.open_in_new_off_outlined,
          title: 'Display over other apps',
          held: 'Kiosk Satellite can bring itself back in the foreground.',
          missing:
              'Without this the app cannot reopen itself after a crash, an '
              'update or a wake word heard behind another app.',
          idle:
              'Lets the app bring itself back to the front, and the '
              'lockdown shield cover the whole screen.',
          onGrant: () => requestOsPermission(Permission.systemAlertWindow),
        ),
        _row(
          granted: perms?.writeSettings,
          needed:
              settings.get(setBrightnessOnLaunch) ||
              settings.get(screensaverBrightnessEnabled),
          missingIcon: Icons.brightness_6_outlined,
          title: 'Modify system settings',
          held: "Brightness changes set the panel's real brightness.",
          missing:
              'Brightness only dims the app window, so the panel and Home '
              'Assistant never see the change.',
          idle:
              "Needed to set the panel's real brightness rather than "
              'dimming the app window.',
          onGrant: () => _requestVia('writeSettings'),
        ),
        _row(
          granted: _uiGuard,
          needed:
              settings.get(kioskEnabled) && settings.get(kioskDisableStatusBar),
          missingIcon: Icons.shield_outlined,
          title: 'System UI guard',
          held:
              'The notification shade and recents close on their own while '
              'the screen is protected.',
          missing:
              'The notification shade and recents stay reachable. Enable '
              'Kiosk Satellite under Accessibility.',
          idle:
              'Closes the notification shade and recents while kiosk mode '
              'protects the screen.',
          action: 'Enable',
          onGrant: widget.container.kiosk.openUiGuardSettings,
        ),
        // Never marked needed: the screen entity and the MQTT switch both
        // fall back to a dark panel without it, which is a lesser version of
        // the feature rather than a broken one.
        _row(
          granted: perms?.deviceAdmin,
          needed: false,
          missingIcon: Icons.admin_panel_settings_outlined,
          title: 'Device admin',
          held: 'Allows the app to turn the screen off.',
          missing: '',
          idle:
              'Lets Screen off power the panel down instead of only '
              'blacking it out.',
          action: 'Enable',
          onGrant: () => _requestVia('deviceAdmin'),
        ),
        // Same shape as Device admin: without it the File Manager still
        // works on the app's own folder, a lesser version of the feature
        // rather than a broken one.
        _row(
          granted: perms?.allFiles,
          needed: false,
          missingIcon: Icons.folder_off_outlined,
          title: 'All files access',
          held: 'The File Manager can browse the shared storage.',
          missing: '',
          idle:
              'Lets the File Manager browse the shared storage instead of '
              'only the app folder.',
          onGrant: () => _requestVia('allFiles'),
        ),
        // Same shape again: without it the Foreground app sensor still
        // reports Kiosk Satellite itself, it just cannot name other apps.
        _row(
          granted: perms?.usageAccess,
          needed: false,
          missingIcon: Icons.apps_outage,
          title: 'Usage access',
          held: 'The Foreground app sensor can name whichever app is on '
              'screen.',
          missing: '',
          idle:
              'Lets the Foreground app sensor name apps other than '
              'Kiosk Satellite.',
          onGrant: () => _requestVia('usageAccess'),
        ),
        // Pages ask for this themselves when they need it; nothing native
        // here uses it, so it is listed for completeness only.
        _row(
          granted: perms?.location,
          needed: false,
          missingIcon: Icons.location_off_outlined,
          title: 'Location',
          held: 'Pages can use the device location.',
          missing: '',
          idle: 'Only used by dashboard pages that ask for your location.',
          onGrant: () => ensureOsPermission(Permission.locationWhenInUse),
        ),
      ]),
    );
  }
}

/// Every OS grant the app needs, and whether it actually holds it.
///
/// Together and last, because they are one kind of thing: not preferences but
/// permissions, given on an Android screen, each of which silently stops
/// something working when it is missing. A row per grant, saying what breaks
/// rather than what it is called — "microphone" means nothing to someone
/// wondering why the wake word went quiet.
///
/// The microphone is always listed. The three background grants only appear
/// with the setting that needs them, because until then none of them applies.
class SystemPermissionsTile extends StatefulWidget {
  const SystemPermissionsTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<SystemPermissionsTile> createState() => _SystemPermissionsTileState();
}

class _SystemPermissionsTileState extends State<SystemPermissionsTile>
    with WidgetsBindingObserver {
  /// Null until read, or when we could not read them at all — which is not
  /// the same as denied and must not be drawn as if it were.
  SystemPermissions? _perms;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Every one of these is given on an OS screen that tells us nothing on the
    // way back, so re-read them when the user returns from one.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final perms = await SystemPermissions.read();
      if (!mounted) return;
      setState(() => _perms = perms);
    } catch (_) {
      if (!mounted) return;
      setState(() => _perms = null);
    }
  }

  /// One grant. [granted] null means we could not tell, which is not the same
  /// as denied and must not be drawn as if it were.
  Widget _row({
    required bool? granted,
    required IconData missingIcon,
    required String title,
    required String held,
    required String missing,
    required VoidCallback onGrant,
    String action = 'Grant',
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        granted == true ? Icons.check_circle_outline : missingIcon,
        color: granted == true ? null : theme.colorScheme.error,
      ),
      title: Text(title),
      subtitle: Text(granted == true ? held : missing),
      trailing: granted == true
          ? null
          : TextButton(onPressed: onGrant, child: Text(action)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.container.settings.get(wakeWordBackground);
    final perms = _perms;
    return Column(
      children: separatedRows([
        // Nothing else here matters without this one: no microphone, no wake
        // word, in the foreground or out of it.
        _row(
          granted: perms?.microphone,
          missingIcon: Icons.mic_off_outlined,
          title: 'Microphone',
          held: 'Wake word detection can hear you.',
          missing: perms?.microphoneBlocked == true
              ? 'Blocked. Android will not ask again, so allow it in the '
                    'app settings.'
              : 'Without this nothing is listening for the wake word.',
          action: perms?.microphoneBlocked == true ? 'App settings' : 'Grant',
          onGrant: () async {
            if (perms?.microphoneBlocked == true) {
              await openOsAppSettings();
            } else {
              await ensureOsPermission(Permission.microphone);
            }
            await _refresh();
          },
        ),
        if (background)
          _row(
            granted: perms?.displayOverOtherApps,
            missingIcon: Icons.open_in_new_off_outlined,
            title: 'Display over other apps',
            held: 'Kiosk Satellite can come forward when it hears you.',
            missing: 'Without this the wake word is heard and nothing happens.',
            onGrant: BackgroundListening.requestBringToFront,
          ),
        if (background)
          _row(
            granted: perms?.notification,
            missingIcon: Icons.notifications_off_outlined,
            title: 'Notifications',
            held:
                'The ongoing notification that enables background '
                'listening.',
            missing: 'Needed for background listening to work reliably.',
            onGrant: () async {
              await ensureOsPermission(Permission.notification);
              await _refresh();
            },
          ),
        if (background)
          _row(
            granted: perms?.batteryUnrestricted,
            missingIcon: Icons.battery_alert_outlined,
            title: 'Unrestricted battery',
            held: 'Android will leave the listener running.',
            missing: 'Without this the listener is stopped after a few hours.',
            onGrant: BackgroundListening.requestBatteryUnrestricted,
          ),
      ]),
    );
  }
}

/// Drop the cached models and re-download them.
///
/// Mirrored by the web admin's "Clear cache" button (both call
/// `clearWakeWordModels`). Models cache by URL, so a model re-published on Home
/// Assistant under the same name never reaches a device that already has one.
class ClearModelCacheTile extends StatefulWidget {
  const ClearModelCacheTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<ClearModelCacheTile> createState() => _ClearModelCacheTileState();
}

class _ClearModelCacheTileState extends State<ClearModelCacheTile> {
  bool _busy = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services_outlined),
      title: const Text('Cached models'),
      subtitle: Text(
        _result ??
            'Re-download from Home Assistant. Use after re-publishing a model.',
      ),
      trailing: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: () async {
                setState(() => _busy = true);
                final result = await widget.container.commands.execute(
                  'clearWakeWordModels',
                  const {},
                );
                if (!mounted) return;
                final removed = (result.data as Map?)?['removed'];
                setState(() {
                  _busy = false;
                  _result = result.ok
                      ? 'Cleared $removed file(s); re-downloading.'
                      : 'Could not clear the cache.';
                });
              },
              child: const Text('Clear'),
            ),
    );
  }
}

/// A bounded number setting as a slider row: the value reads at the right of
/// the row, the slider spans beneath. Dragging updates the label live; the
/// setting is written once, on release, so a drag is one change event rather
/// than a stream of them (settings changes can restart cameras and reload
/// pages — see KioskScreen._onSettingChanged).
/// The master volume fader: the device's live volume, not a setting, so
/// it is read and written through the getVolume/setVolume commands and
/// follows outside moves (hardware buttons, MQTT) while the page is open.
class _MasterVolumeTile extends StatefulWidget {
  const _MasterVolumeTile({required this.container});

  final AppContainer container;

  @override
  State<_MasterVolumeTile> createState() => _MasterVolumeTileState();
}

class _MasterVolumeTileState extends State<_MasterVolumeTile> {
  /// Value under the finger mid-drag; null shows the device's own level.
  double? _drag;
  double _percent = 0;
  StreamSubscription<VolumeChanged>? _sub;

  @override
  void initState() {
    super.initState();
    _read();
    _sub = widget.container.bus.on<VolumeChanged>().listen((_) => _read());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _read() async {
    final r = await widget.container.commands.execute('getVolume', const {});
    if (!mounted || !r.ok || r.data is! num) return;
    setState(() => _percent = (r.data as num).toDouble().clamp(0, 100));
  }

  @override
  Widget build(BuildContext context) {
    final value = _drag ?? _percent;
    return Column(
      children: [
        ListTile(
          title: const Text('Master volume'),
          subtitle: const Text(
            'The device volume. Media and assistant volume scale under it.',
          ),
          trailing: Text(
            '${value.round()}%',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) => setState(() => _drag = v),
            onChangeEnd: (v) async {
              setState(() {
                _drag = null;
                _percent = v;
              });
              await widget.container.commands.execute('setVolume', {
                'percent': v.round(),
              });
            },
          ),
        ),
      ],
    );
  }
}

class _SliderTile extends StatefulWidget {
  const _SliderTile({
    required this.container,
    required this.def,
    required this.onChanged,
  });

  final AppContainer container;
  final SettingDef<Object> def;
  final VoidCallback onChanged;

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  /// Value under the finger mid-drag; null reads the stored setting.
  double? _drag;

  String _label(num v) {
    final def = widget.def;
    if (def.unit == '%') {
      // max <= 1 marks a 0..1 fraction stored, percentage shown.
      return '${(def.max! <= 1 ? v * 100 : v).round()}%';
    }
    final text = v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(2);
    return def.unit == null ? text : '$text${def.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final min = def.min!.toDouble();
    final max = def.max!.toDouble();
    final step = def.step?.toDouble();
    final value =
        _drag ??
        (widget.container.settings.get(def) as num).toDouble().clamp(min, max);
    return Column(
      children: [
        ListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          trailing: Text(
            _label(value),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: step != null ? ((max - min) / step).round() : null,
            onChanged: (v) => setState(() => _drag = v),
            onChangeEnd: (v) async {
              _drag = null;
              // Trim float noise so a whole value stores as a whole value.
              final parsed = num.parse(v.toStringAsFixed(4));
              // Enabling real screen-off gets a warning first: what a dark
              // panel does to Wi-Fi, the camera and the app itself is the
              // manufacturer's call, not the app's (issue #184 and kin),
              // and the Black screensaver avoids the whole regime.
              if (def.key == screensaverScreenOffMinutes.key &&
                  (widget.container.settings.get(def) as num) == 0 &&
                  parsed > 0) {
                final go = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('WARNING: Please Read!'),
                    content: const Text(
                      'Once the display truly powers off, the tablet\'s own '
                      'power management takes over, and many Android models '
                      'misbehave in that state: Wi-Fi naps or drops, the '
                      'Home Assistant entities go unavailable, the camera '
                      'can be revoked, and some models kill background apps '
                      'outright. What happens depends on the manufacturer.\n\n'
                      'The reliable alternative is the Black screensaver '
                      'with this setting left at 0: the panel looks just as '
                      'dark, and the app keeps full control.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Turn screen off anyway'),
                      ),
                    ],
                  ),
                );
                if (go != true) {
                  // The slider snaps back to the stored 0.
                  if (mounted) setState(() {});
                  return;
                }
              }
              await widget.container.settings.setFromJson(def.key, parsed);
              widget.onChanged();
            },
          ),
        ),
      ],
    );
  }
}

/// A single setting rendered by its declared type.
class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.container,
    required this.def,
    required this.onChanged,
  });

  final AppContainer container;
  final SettingDef<Object> def;
  final VoidCallback onChanged;

  AppContainer get c => container;

  /// A select's options, filtered for context. The Home Assistant Media
  /// screensaver only makes sense with Home Assistant connected, so its option
  /// is hidden until a URL and token are set.
  List<String> _optionsFor(SettingDef<Object> def) {
    final options = List<String>.from(def.options ?? const <String>[]);
    if (def.key == screensaverMode.key && !c.homeAssistant.configured) {
      options.remove('media');
    }
    return options;
  }

  /// A number without a pointless trailing `.0` — 10, not 10.0.
  String _formatNum(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) =>
      // Every definition-rendered row is a search landing: the settings
      // search scrolls to and blinks the row whose key it resolved.
      SearchLandingTarget(id: def.key, child: _tile(context));

  Widget _tile(BuildContext context) {
    switch (def.type) {
      case SettingType.boolean:
        return SwitchListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          value: c.settings.get(def) as bool,
          onChanged: (v) async {
            await c.settings.setFromJson(def.key, v);
            onChanged();
          },
        );
      case SettingType.select:
        final options = _optionsFor(def);
        final current = c.settings.get(def) as String;
        // Stored values are lowercase identifiers; people read the declared
        // label ('media' → "Home Assistant Media"), or Capitalised as a
        // fallback.
        String label(String option) =>
            def.optionLabels?[option] ??
            (option.isEmpty
                ? option
                : option[0].toUpperCase() + option.substring(1));
        return DropdownRow<String>(
          title: def.title,
          description: def.description,
          value: options.contains(current) ? current : options.first,
          options: [for (final option in options) (option, label(option))],
          onChanged: (v) async {
            if (v == null) return;
            await c.settings.setFromJson(def.key, v);
            onChanged();
          },
        );
      case SettingType.string || SettingType.password || SettingType.number:
        // A bounded number is dragged, not typed — a slider in both UIs.
        if (def.type == SettingType.number &&
            def.min != null &&
            def.max != null) {
          return _SliderTile(container: c, def: def, onChanged: onChanged);
        }
        final value = c.settings.get(def);
        final display = def.secret
            ? ((value as String).isEmpty ? 'Not set' : '••••••••')
            : (value is num
                  ? _formatNum(value)
                  : ('$value'.isEmpty ? 'Not set' : '$value'));
        // A color is picked, not typed. Every "r,g,b" setting ends in
        // _color by convention; the remote UI keys off the same suffix.
        if (def.key.endsWith('_color')) {
          final rgb = value as String;
          final parts = rgb
              .split(',')
              .map((p) => int.tryParse(p.trim()))
              .toList();
          final swatch = (parts.length == 3 && parts.every((p) => p != null))
              ? Color.fromARGB(255, parts[0]!, parts[1]!, parts[2]!)
              : const Color(0xFFFAFAFA);
          return ListTile(
            title: Text(def.title),
            subtitle: Text(def.description),
            trailing: GestureDetector(
              onTap: () async {
                final picked = await pickColor(
                  context,
                  initial: rgb,
                  title: def.title,
                );
                if (picked != null) {
                  await c.settings.setFromJson(def.key, picked);
                  onChanged();
                }
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  // Theme outline so the ring survives both themes; a fixed
                  // dark border vanished against the dark surface.
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          );
        }
        // The clock's background photo (issue #132): one image via the
        // system photo picker, copied into app documents the same way the
        // gallery set is. Clear returns to the solid color and removes
        // the copy.
        if (def.key == screensaverClockBackground.key) {
          final path = value as String;
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              path.isEmpty ? 'No photo selected' : path.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (path.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await c.settings.setFromJson(def.key, '');
                      try {
                        await File(path).parent.delete(recursive: true);
                      } catch (_) {}
                      onChanged();
                    },
                    child: const Text('Clear'),
                  ),
                TextButton(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked == null) return;
                    final docs = await getApplicationDocumentsDirectory();
                    final dir = Directory('${docs.path}/clock_bg');
                    if (await dir.exists()) await dir.delete(recursive: true);
                    await dir.create(recursive: true);
                    final dest =
                        '${dir.path}/${picked.name.replaceAll('/', '_')}';
                    await File(picked.path).copy(dest);
                    await c.settings.setFromJson(def.key, dest);
                    onChanged();
                  },
                  child: const Text('Browse'),
                ),
              ],
            ),
          );
        }
        // Photo Gallery: picked with the system gallery picker — the
        // modern Android photo picker needs no permission at all. The
        // picker hands back cache copies, which the OS may purge, so the
        // selection is copied into app documents where it survives reboots
        // and cache trims; re-picking replaces the set.
        if (def.key == screensaverGalleryItems.key) {
          var count = 0;
          try {
            count = (jsonDecode(value as String) as List).length;
          } catch (_) {}
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              count == 0 ? 'No photos selected' : '$count selected',
            ),
            trailing: TextButton(
              onPressed: () async {
                final picked = await ImagePicker().pickMultipleMedia();
                if (picked.isEmpty) return;
                final docs = await getApplicationDocumentsDirectory();
                final dir = Directory('${docs.path}/gallery');
                if (await dir.exists()) await dir.delete(recursive: true);
                await dir.create(recursive: true);
                final paths = <String>[];
                for (var i = 0; i < picked.length; i++) {
                  final name = picked[i].name.replaceAll('/', '_');
                  final dest =
                      '${dir.path}/${i.toString().padLeft(4, '0')}_$name';
                  await File(picked[i].path).copy(dest);
                  paths.add(dest);
                }
                await c.settings.setFromJson(def.key, jsonEncode(paths));
                onChanged();
              },
              child: const Text('Browse'),
            ),
          );
        }
        // The local-media folder is picked with the system picker, not
        // typed. Media permissions are asked for first — the screensaver
        // needs them to read the files later, and asking at pick time is
        // the moment the user understands why.
        if (def.key == screensaverLocalFolder.key) {
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: () async {
                await ensureOsPermission(Permission.photos);
                await ensureOsPermission(Permission.videos);
                final path = await FilePicker.platform.getDirectoryPath();
                if (path != null) {
                  await c.settings.setFromJson(def.key, path);
                  onChanged();
                }
              },
              child: const Text('Browse'),
            ),
          );
        }
        // The screensaver's media is picked from Home Assistant, not typed.
        if (def.key == screensaverMediaId.key) {
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: TextButton(
              onPressed: () async {
                final picked = await pickMedia(context, c);
                if (picked != null) {
                  await c.settings.setFromJson(def.key, picked.id);
                  // Remember folder-ness so the playlist settings (shuffle,
                  // subfolders, interval) know whether to show.
                  await c.settings.setFromJson(
                    screensaverMediaIsFolder.key,
                    picked.isFolder,
                  );
                  onChanged();
                }
              },
              child: const Text('Browse'),
            ),
          );
        }
        // The Immich source is picked from the server's albums, not typed.
        if (def.key == screensaverImmichAlbum.key) {
          final name = c.settings.get(screensaverImmichAlbumName);
          final label = (value as String).isEmpty
              ? 'All media'
              : (name.isEmpty ? 'Album' : name);
          return ListTile(
            title: Text(def.title),
            subtitle: Text(def.description),
            trailing: TextButton(
              onPressed: () => _pickImmichAlbum(context),
              child: Text(label),
            ),
          );
        }
        // The At a Glance entities: a list, edited in its own screen rather
        // than typed as JSON.
        if (def.key == screensaverGlanceEntities.key) {
          final chosen = _glanceEntities(c);
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              chosen.isEmpty
                  ? 'None yet. Up to $screensaverGlanceMax entities.'
                  : chosen.map((e) => e['name']).join(', '),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editGlanceEntities(context),
          );
        }
        // The launcher whitelist: ticked off the device's launchable apps,
        // never typed as JSON.
        if (def.key == launcherApps.key) {
          final chosen = decodeLauncherApps(value as String);
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              chosen.isEmpty
                  ? 'None yet. Pick the apps the launcher offers.'
                  : chosen.map((a) => a.label).join(', '),
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _pickLauncherApps(context),
          );
        }
        // The camera screensaver's view is picked from the ones configured
        // under Cameras, never typed — the value is an opaque view id.
        if (def.key == screensaverCameraView.key) {
          final views = c.camera.config.views
              .where((view) => view.cameraIds.isNotEmpty)
              .toList();
          final current = views
              .where((view) => view.id == value as String)
              .firstOrNull;
          return ListTile(
            title: Text(def.title),
            subtitle: Text(
              views.isEmpty
                  ? 'No camera view has cameras yet. Add one under Cameras.'
                  : def.description,
            ),
            trailing: TextButton(
              onPressed: views.isEmpty
                  ? null
                  : () => _pickCameraView(context, views),
              child: Text(current?.name ?? 'Not set'),
            ),
          );
        }
        // The screensaver schedule: times with a mode and brightness each,
        // edited in place rather than typed as JSON.
        if (def.key == screensaverSchedule.key) {
          return _ScheduleEditor(container: c, onChanged: onChanged);
        }
        // The screensaver widgets: one summary row per corner overlay,
        // configured in a dialog rather than typed as JSON.
        if (def.key == screensaverWidgets.key) {
          return _WidgetsEditor(container: c, onChanged: onChanged);
        }
        // A time of day is picked from a clock, not typed.
        if (def.key == themeDarkAt.key || def.key == themeLightAt.key) {
          final current = value as String;
          return ListTile(
            title: Text(def.title),
            subtitle: Text(def.description),
            trailing: TextButton(
              onPressed: () => _pickTime(context, current),
              child: Text(current.isEmpty ? 'Not set' : current),
            ),
          );
        }
        return ListTile(
          title: Text(def.title),
          // A multiline blob (pasted JavaScript) is edited, not read off the
          // row — the description carries the row instead.
          subtitle: Text(def.multiline ? def.description : display),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editText(context),
        );
    }
  }

  List<Map<String, Object?>> _glanceEntities(AppContainer container) {
    try {
      final decoded = jsonDecode(
        container.settings.get(screensaverGlanceEntities),
      );
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map) item.cast<String, Object?>(),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _editGlanceEntities(BuildContext context) async {
    final saved = await Navigator.of(context).push<List<Map<String, Object?>>>(
      MaterialPageRoute(
        builder: (_) =>
            GlanceEntityPicker(container: c, initial: _glanceEntities(c)),
      ),
    );
    if (saved == null) return;
    await c.settings.setFromJson(
      screensaverGlanceEntities.key,
      jsonEncode(saved),
    );
    onChanged();
  }

  Future<void> _pickCameraView(
    BuildContext context,
    List<CameraViewConfig> views,
  ) async {
    final current = c.settings.get(screensaverCameraView);
    final picked = await showRadioPicker<CameraViewConfig>(
      context,
      title: 'Camera view',
      selected: views.where((v) => v.id == current).firstOrNull,
      options: [
        for (final view in views)
          PickerOption(
            view,
            view.name,
            detail:
                '${view.cameraIds.length} camera'
                '${view.cameraIds.length == 1 ? '' : 's'}',
          ),
      ],
    );
    if (picked == null) return;
    await c.settings.setFromJson(screensaverCameraView.key, picked.id);
    await c.settings.setFromJson(screensaverCameraViewName.key, picked.name);
    onChanged();
  }

  Future<void> _pickImmichAlbum(BuildContext context) async {
    final result = await c.commands.execute('immichAlbums', const {});
    if (!context.mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not list the albums')),
      );
      return;
    }
    final albums = (result.data as List).cast<Map>();
    final current = c.settings.get(screensaverImmichAlbum);
    final picked = await showRadioPicker<String>(
      context,
      title: 'Media source',
      selected: current,
      options: [
        const PickerOption('', 'All media'),
        for (final album in albums)
          PickerOption(
            '${album['id']}',
            '${album['name']}',
            detail: '${album['count']} items',
          ),
      ],
    );
    if (picked == null) return;
    final name = picked.isEmpty
        ? ''
        : '${albums.firstWhere((a) => '${a['id']}' == picked)['name']}';
    await c.settings.setFromJson(screensaverImmichAlbum.key, picked);
    await c.settings.setFromJson(screensaverImmichAlbumName.key, name);
    onChanged();
  }

  Future<void> _pickLauncherApps(BuildContext context) async {
    final result = await c.commands.execute('installedApps', const {});
    if (!context.mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not list the apps')),
      );
      return;
    }
    final apps = (result.data as List).cast<Map>();
    final selected = {
      for (final app in decodeLauncherApps(c.settings.get(launcherApps)))
        app.package,
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Apps'),
          content: SizedBox(
            width: 420,
            child: apps.isEmpty
                ? const Text('No launchable apps found.')
                : EdgeFade(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final app in apps)
                          CheckboxListTile(
                            value: selected.contains('${app['package']}'),
                            title: Text('${app['label']}'),
                            subtitle: Text(
                              '${app['package']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onChanged: (on) => setState(() {
                              if (on == true) {
                                selected.add('${app['package']}');
                              } else {
                                selected.remove('${app['package']}');
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    // Rebuilt from the device's list, so labels refresh and uninstalled
    // leftovers drop out on every save.
    await c.settings.setFromJson(
      launcherApps.key,
      jsonEncode([
        for (final app in apps)
          if (selected.contains('${app['package']}'))
            {'package': '${app['package']}', 'label': '${app['label']}'},
      ]),
    );
    onChanged();
  }

  Future<void> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '')?.clamp(0, 23) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '')?.clamp(0, 59) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final hhmm =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    await c.settings.setFromJson(def.key, hhmm);
    onChanged();
  }

  Future<void> _editText(BuildContext context) async {
    final current = c.settings.get(def);
    final controller = TextEditingController(
      text: def.secret
          ? ''
          : (current is num ? _formatNum(current) : '$current'),
    );
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(def.title),
        content: SizedBox(
          width: def.multiline ? 560 : 420,
          child: TextField(
            controller: controller,
            obscureText: def.secret,
            autofocus: true,
            minLines: def.multiline ? 6 : 1,
            maxLines: def.multiline ? 14 : 1,
            keyboardType: def.type == SettingType.number
                ? TextInputType.number
                : def.multiline
                ? TextInputType.multiline
                : TextInputType.text,
            style: def.multiline
                ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
                : null,
            decoration: InputDecoration(
              hintText: def.placeholder ?? def.description,
              hintMaxLines: def.multiline ? 4 : null,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final value = def.type == SettingType.number
        ? num.tryParse(result)
        : result;
    if (value != null) {
      await c.settings.setFromJson(def.key, value);
      onChanged();
    }
  }
}
