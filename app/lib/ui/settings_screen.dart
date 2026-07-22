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
import '../managers/settings/definitions.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';
import '../managers/wake_word/background_listening.dart';
import '../managers/wake_word/system_permissions.dart';
import '../managers/wake_word/engine.dart';
import 'color_picker.dart';
import 'import_options_dialog.dart';
import 'media_picker.dart';
import 'wake_word_tester.dart';

/// A line between rows, and never after the last one. Inset from the card
/// edges, One UI style, so the line reads as part of the card rather than a
/// cut through it. The remote admin's `.row` border follows the same
/// no-line-after-the-last rule.
List<Widget> _separated(List<Widget> rows) => [
  for (var i = 0; i < rows.length; i++) ...[
    rows[i],
    if (i < rows.length - 1)
      const Divider(height: 1, indent: 20, endIndent: 20),
  ],
];

/// A group of settings rows on one flat, borderless, large-radius card —
/// One UI's rounded section mask. Clips so row ink stays inside the corners.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Column(children: _separated(children)),
  );
}

/// Narrow-screen pages read as a column, not a sheet: capped at a comfortable
/// reading width and centered.
Widget _constrained(Widget child) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 760),
    child: child,
  ),
);

const _pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 24);

/// Render a category's settings as cards: consecutive settings sharing a
/// `section` become one card under one [_SectionHeading]; unsectioned runs
/// share an unheaded card. Only visible settings appear.
List<Widget> _sectionedCards(
  AppContainer container,
  List<SettingDef<Object>> defs,
  VoidCallback onChanged, {
  // Extra widgets keyed by setting key, rendered inside the card directly
  // under that setting's row (a permission notice living with the switch
  // that needs it).
  Map<String, Widget> after = const {},
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
      _SettingsCard(
        children: [
          for (final def in buffer) ...[
            SettingTile(container: container, def: def, onChanged: onChanged),
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
      if (current != null) out.add(_SectionHeading(current));
    }
    buffer.add(def);
  }
  flush();
  return out;
}

/// (defs category, page title, icon, subtitle)
const _categories = <(String, String, IconData, String)>[
  (
    'Home Assistant',
    'Home Assistant Configuration',
    Icons.home_outlined,
    'Connection, dashboard, kiosk mode',
  ),
  (
    'Voice Satellite',
    'Voice Satellite',
    Icons.graphic_eq_outlined,
    'Wake word, background listening',
  ),
  ('Browser', 'Web Browsing', Icons.public, 'Reload, cache, zoom'),
  (
    'Kiosk',
    'Kiosk Mode',
    Icons.lock_outline,
    'Exit gesture, PIN, hardware buttons',
  ),
  ('Screen', 'Screen', Icons.brightness_6_outlined, 'Brightness, keep awake'),
  (
    'Screensaver',
    'Screensaver',
    Icons.dark_mode_outlined,
    'Idle timeout, modes, motion wake',
  ),
  (
    'Remote',
    'Remote Administration',
    Icons.settings_remote_outlined,
    'Web console access',
  ),
  (
    'MQTT',
    'MQTT Settings',
    Icons.hub_outlined,
    'Publish to an MQTT broker',
  ),
  (
    'Sendspin',
    'Sendspin Player',
    Icons.speaker_outlined,
    'Synchronized audio player',
  ),
  (
    'DLNA',
    'DLNA Renderer',
    Icons.cast_outlined,
    'Play images, videos and audio remotely',
  ),
  (
    'Device',
    'Device',
    Icons.tablet_android_outlined,
    'Name, identity, app theme',
  ),
  ('About', 'About', Icons.info_outline, 'Version, author, license'),
  ('Logs', 'App Logs', Icons.article_outlined, 'What the app has been doing'),
];

List<SettingDef<Object>> _defsFor(String category) => [
  for (final def in allSettings)
    if (def.category == category && !def.hidden) def,
];

/// A category icon the way One UI paints them: a solid colour disc with a
/// white glyph. The disc colours cycle the four brand accents (already
/// light/dark-adapted by the scheme).
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.index, required this.icon});

  final int index;
  final IconData icon;

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
      child: Icon(icon, color: Colors.white, size: 22),
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
                              fontWeight: FontWeight.w700,
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
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                      children: [
                        for (final (index, (_, title, icon, subtitle))
                            in _categories.indexed)
                          _railTile(context, index, title, icon, subtitle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: PageStorageKey('settings-pane-$category'),
                padding: const EdgeInsets.fromLTRB(8, 24, 28, 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 0, 18),
                    child: Row(
                      children: [
                        // The rail's icon again — bare glyph, no disc: the
                        // title row is a label, not a button.
                        Icon(icon, size: 26),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
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
    IconData icon,
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
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _selected = index),
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
  Widget _hub(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _constrained(
        ListView(
          padding: _pagePadding,
          children: [
            _SettingsCard(
              children: [
                for (final (index, (category, title, icon, subtitle))
                    in _categories.indexed)
                  ListTile(
                    leading: _CategoryIcon(index: index, icon: icon),
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
  });

  final AppContainer container;
  final String title;
  final String category;

  @override
  Widget build(BuildContext context) {
    final icon = _categories
        .where((c) => c.$1 == category)
        .map((c) => c.$3)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24),
              const SizedBox(width: 10),
            ],
            Text(title),
          ],
        ),
      ),
      body: _constrained(
        ListView(
          padding: _pagePadding,
          children: [
            _CategoryContent(container: container, category: category),
          ],
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

  @override
  void initState() {
    super.initState();
    if (widget.category == 'Voice Satellite') {
      _vsDetected = widget.container.homeAssistant.detectVoiceSatellite();
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
      fileName: 'kiosk-satellite-config.json',
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
      _logcatText =
          r.ok ? '${r.data}' : 'Could not read logcat: ${r.error ?? 'unknown'}';
    });
  }

  List<Widget> _logsCards(AppContainer container) {
    final theme = Theme.of(context);
    final entries = container.log.recent;
    Color levelColor(LogLevel level) => switch (level) {
      LogLevel.error => Colors.red.shade300,
      LogLevel.warn => Colors.amber.shade700,
      LogLevel.debug => theme.colorScheme.outline,
      _ => theme.colorScheme.onSurface,
    };
    String fmt(LogEntry e) =>
        '${e.time.toIso8601String().substring(11, 19)} ${e.tag}: ${e.message}';
    final isLogcat = _logSource == 'logcat';
    return [
      _SettingsCard(
        children: [
          ListTile(
            title: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _logSource,
                isDense: true,
                items: const [
                  DropdownMenuItem(
                      value: 'app', child: Text('Kiosk Satellite')),
                  DropdownMenuItem(value: 'logcat', child: Text('Logcat')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _logSource = v);
                  if (v == 'logcat' && _logcatText == null) {
                    _fetchLogcat(container);
                  }
                },
              ),
            ),
            subtitle: Text(isLogcat
                ? 'Android system log for this app (crashes live here)'
                : '${entries.length} entries'),
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
                            ? _filteredLogcat()
                                .map((l) => l.$1)
                                .join('\n')
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
                  onPressed: () => isLogcat
                      ? _fetchLogcat(container)
                      : setState(() {}),
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
                    ('Errors & crashes', _lcErrors,
                        (bool v) => _lcErrors = v),
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
                            onChanged: (v) =>
                                setState(() => set(v ?? false)),
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
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      )
                    : Builder(builder: (context) {
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (line, pri) in lines)
                              Text(
                                line,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: switch (pri) {
                                    'E' || 'F' => Colors.red.shade300,
                                    'W' => Colors.amber.shade700,
                                    _ => theme.colorScheme.onSurface,
                                  },
                                ),
                              ),
                          ],
                        );
                      }))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
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
      const _SectionHeading('App'),
      _SettingsCard(
        children: [
          row('App version', '${device.appVersion} (${device.buildNumber})'),
          row('Build', device.buildMode),
          row('Package', device.packageName),
        ],
      ),
      const _SectionHeading('Attribution'),
      _SettingsCard(
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
        else
          ..._sectionedCards(
            container,
            _defsFor(widget.category),
            () => setState(() {}),
            after: {
              if (widget.category == 'Screensaver' &&
                  container.settings.get(screensaverDismissOnMotion))
                screensaverDismissOnMotion.key: _CameraGrantRow(
                  key: UniqueKey(),
                ),
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
            },
          ),
        if (widget.category == 'Screen')
          _BrightnessGrantCard(container: container),
        if (widget.category == 'Remote' &&
            container.settings.get(remoteEnabled))
          _AdminAddressCard(container: container),
        if (widget.category == 'Device') ...[
          const _SectionHeading('Configuration'),
          _SettingsCard(
            children: [
              ListTile(
                title: const Text('Export configuration'),
                subtitle: const Text(
                  "Save every setting and the page's local storage to a "
                  'file.',
                ),
                trailing: const Icon(Icons.download_outlined),
                onTap: _exportConfig,
              ),
              ListTile(
                title: const Text('Import configuration'),
                subtitle: const Text(
                  "Replace this device's settings from an exported file.",
                ),
                trailing: const Icon(Icons.upload_outlined),
                onTap: _importConfig,
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
        if (widget.category == 'Logs') ..._logsCards(container),
        _MadeByFooter(container: container),
      ],
    );
  }

  /// The connection card: base URL, token, and the validation row. Always
  /// visible — it is the gate everything else on this page waits behind.
  List<Widget> _haConnectionCards(AppContainer container) {
    return [
      _SettingsCard(
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
          ListTile(
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
          // Hand-built (and mirrored in the remote UI's connection card):
          // the row's enabled state derives from the URL scheme. https
          // needs no proxy, so the switch sits disabled and off; a plain
          // http URL enables it, and validation turns it on with a modal.
          Builder(
            builder: (context) {
              final uri = Uri.tryParse(
                container.settings.get(haUrl).trim(),
              );
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
      const _SectionHeading('Dashboard'),
      _DashboardPickerCard(container: container),
      ..._sectionedCards(container, [
        for (final def in _defsFor('Home Assistant'))
          if (def.key != haUrl.key &&
              def.key != haToken.key &&
              // The rotation group is hand-built below: its dashboard list
              // needs the live dashboards from HA, which the generic
              // renderer cannot supply.
              def.key != haRotationEnabled.key &&
              def.key != haRotationSeconds.key &&
              def.key != haRotationPauseSeconds.key &&
              // Optimizations are hand-built last so the filter can show live
              // telemetry beneath its toggle.
              def.key != disableSuspend.key &&
              def.key != wsFilter.key)
            def,
      ], () => setState(() {})),
      const _SectionHeading('Dashboard View Rotation'),
      _RotationCard(container: container),
      const _SectionHeading('Optimizations'),
      _OptimizationsCard(container: container),
    ];
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
        _SettingsCard(
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
            return const _SettingsCard(
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
            return _SettingsCard(
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
                future: _assignedSatellite(container),
                builder: (context, snap) => _SettingsCard(
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
              _SettingsCard(
                children: [
                  for (final def in _defsFor('Voice Satellite'))
                    if (container.settings.visible(def))
                      SettingTile(
                        container: container,
                        def: def,
                        onChanged: () => setState(() {}),
                      ),
                  // Device pickers are hand-built (their options are live
                  // hardware); the remote UI mirrors both rows. The mic one
                  // only while detection is on — with it off this app never
                  // opens the microphone, the browser does.
                  if (container.settings.get(wakeWordEnabled))
                    AudioDeviceTile(
                      container: container,
                      def: audioMicDevice,
                      inputs: true,
                    ),
                  AudioDeviceTile(
                    container: container,
                    def: audioSpeakerDevice,
                    inputs: false,
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
                const _SectionHeading('Wake Word Tester'),
                _SettingsCard(
                  children: [WakeWordTesterTile(container: container)],
                ),
              ],
              // Last, and on their own card: these are the OS's to give,
              // not ours to set, and every one of them is a thing that
              // stops working rather than a preference. Only while we are
              // the one listening — with detection off, the browser asks
              // for the microphone through its own flow.
              if (container.settings.get(wakeWordEnabled)) ...[
                const _SectionHeading('Required system permissions'),
                _SettingsCard(
                  children: [SystemPermissionsTile(container: container)],
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
            : 'Without this motion cannot be detected.',
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
    final validated = widget.container.settings.get(
      screensaverImmichValidated,
    );
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
        const _SectionHeading('Access'),
        _SettingsCard(
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
        const _SectionHeading('Permission'),
        _SettingsCard(
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
      if (decoded is String) decoded = jsonDecode(decoded); // some engines double-encode
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
      builder: (ctx) => SimpleDialog(
        title: Row(
          children: [
            Expanded(child: Text('Watched entities (${items.length})')),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        children: [
          for (final it in items)
            ListTile(
              dense: true,
              title: Text(it.name.isEmpty ? it.id : it.name),
              subtitle: it.name.isEmpty ? null : Text(it.id),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SettingsCard(
      children: [
        SettingTile(container: c, def: disableSuspend, onChanged: _onToggle),
        SettingTile(container: c, def: wsFilter, onChanged: _onToggle),
        if (_filterOn) _telemetry(theme),
      ],
    );
  }

  Widget _telemetry(ThemeData theme) {
    final s = _stats;
    final pct =
        (s != null && s.total > 0) ? (100 * s.dropped / s.total).round() : null;
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
    final route =
        (views != null && views.isNotEmpty) ? '${views.first['route']}' : '';
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
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SimpleDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Choose a view')),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          children: [
            for (final v in views)
              ListTile(
                leading: Icon(
                  '${v['route']}' == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: '${v['route']}' == current
                      ? theme.colorScheme.primary
                      : null,
                ),
                title: Text('${v['title']}'),
                subtitle: Text(_viewPath(urlPath, '${v['route']}')),
                onTap: () => Navigator.pop(ctx, '${v['route']}'),
              ),
          ],
        );
      },
    );
    if (picked != null && picked != current) await _apply(urlPath, picked);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>?>(
      future: _dashboards,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SettingsCard(
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
          return _SettingsCard(
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
        return _SettingsCard(
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
    final subtitle =
        selected ? _viewPath(urlPath, _selectedRoute(urlPath)) : urlPath;
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
  const _RotationCard({required this.container});

  final AppContainer container;

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
    return _SettingsCard(
      children: [
        SettingTile(
          container: c,
          def: haRotationEnabled,
          onChanged: () => setState(() {}),
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
              title: Text(url, style: const TextStyle(fontSize: 14)),
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
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'https://example.com',
                      border: OutlineInputBorder(),
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
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final link = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Made with ', style: muted),
          // An icon, not the \u2665 character: Android renders that
          // codepoint as the emoji glyph, which ignores text colour
          // entirely and always shows its own saturated red.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Icon(Icons.favorite, size: 13, color: Color(0xFFE86A6A)),
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
    );
  }
}

/// A section break. The heading is the break; a divider as well says it twice.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sits between cards, which already carry a 16px bottom margin; the left
    // inset lines the text up with the rows inside the cards.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
    _hotplug = widget.container.bus
        .on<AudioDevicesChanged>()
        .listen((_) => _load());
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
    final list = (data is Map ? data[widget.inputs ? 'inputs' : 'outputs'] : null);
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
    return ListTile(
      title: Text(widget.def.title),
      subtitle: Text(widget.def.description),
      trailing: devices == null
          ? const Text('…')
          : DropdownButton<String>(
              value: options.any((o) => o.$1 == current) ? current : '',
              items: [
                for (final (selector, label) in options)
                  DropdownMenuItem(value: selector, child: Text(label)),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await c.settings.setFromJson(widget.def.key, v);
                if (mounted) setState(() {});
              },
            ),
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
      children: _separated([
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
      children: _separated([
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
            held: 'The ongoing notification that enables background '
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
              await widget.container.settings.setFromJson(
                def.key,
                num.parse(v.toStringAsFixed(4)),
              );
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
  Widget build(BuildContext context) {
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
        return ListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          trailing: DropdownButton<String>(
            value: options.contains(current) ? current : options.first,
            items: [
              for (final option in options)
                DropdownMenuItem(value: option, child: Text(label(option))),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await c.settings.setFromJson(def.key, v);
              onChanged();
            },
          ),
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
        // A colour is picked, not typed.
        if (def.key == screensaverClockColor.key ||
            def.key == screensaverMiniClockColor.key) {
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
                  border: Border.all(color: Colors.black26),
                ),
              ),
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
    final picked = await showDialog<(String, String)>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Media source'),
        children: [
          ListTile(
            leading: Icon(
              current.isEmpty
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: const Text('All media'),
            onTap: () => Navigator.pop(context, ('', '')),
          ),
          for (final album in albums)
            ListTile(
              leading: Icon(
                current == '${album['id']}'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text('${album['name']}'),
              subtitle: Text('${album['count']} items'),
              onTap: () => Navigator.pop(
                context,
                ('${album['id']}', '${album['name']}'),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    await c.settings.setFromJson(screensaverImmichAlbum.key, picked.$1);
    await c.settings.setFromJson(screensaverImmichAlbumName.key, picked.$2);
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
          width: def.multiline ? 560 : null,
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
