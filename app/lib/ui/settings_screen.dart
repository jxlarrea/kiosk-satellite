import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';
import '../managers/wake_word/background_listening.dart';
import '../managers/wake_word/system_permissions.dart';
import '../managers/wake_word/engine.dart';
import 'color_picker.dart';
import 'media_picker.dart';

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
  VoidCallback onChanged,
) {
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
          for (final def in buffer)
            SettingTile(container: container, def: def, onChanged: onChanged),
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
    'Connection, dashboard, Voice Satellite',
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
    'Device',
    'Device',
    Icons.tablet_android_outlined,
    'Name, identity, app theme',
  ),
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
    if (widget.category == 'Home Assistant') {
      _vsDetected = widget.container.homeAssistant.detectVoiceSatellite();
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
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
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import configuration'),
        content: const Text(
          "Replace this device's settings with the file's? The page may "
          'reload.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    final result = await widget.container.commands.execute('importConfig', {
      'config': config,
    });
    if (result.ok) {
      _toast('Applied ${(result.data as Map)['applied']} settings');
      if (mounted) setState(() {});
    } else {
      _toast('Import failed: ${result.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = widget.container;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.category == 'Home Assistant')
          ..._haConnectionCards(container)
        else
          ..._sectionedCards(
            container,
            _defsFor(widget.category),
            () => setState(() {}),
          ),
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
                            : 'Not validated — the settings below unlock '
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
        ],
      ),
    ];
  }

  bool _haValidating = false;
  String? _haError;

  Future<void> _validateHa(AppContainer container) async {
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
        ..._sectionedCards(
          container,
          [
            for (final def in _defsFor('Home Assistant'))
              if (def.key != haUrl.key && def.key != haToken.key) def,
          ],
          () => setState(() {}),
        ),
          FutureBuilder<bool>(
            future: _vsDetected,
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeading('Voice Satellite'),
                  _SettingsCard(
                    children: [
                      for (final def in _defsFor('Voice Satellite'))
                        if (container.settings.visible(def))
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
                ],
              );
            },
          ),
          // Last, and on their own card: these are the OS's to give, not ours
          // to set, and every one of them is a thing that stops working rather
          // than a preference.
          //
          // Only while we are the one listening. With wake word detection off
          // the card keeps detection in the browser, which asks for the
          // microphone through the WebView's own permission flow — so none of
          // this is ours to need, and demanding it would be asking for grants
          // nothing here uses.
          if (container.settings.get(wakeWordEnabled)) ...[
            _SectionHeading('Required system permissions'),
            _SettingsCard(
              children: [SystemPermissionsTile(container: container)],
            ),
          ],
    ];
  }
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

  @override
  void initState() {
    super.initState();
    _dashboards = widget.container.homeAssistant.listDashboards();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
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
        final base = c.homeAssistant.baseUrl;
        final current = c.settings.get(startUrl);
        // Selection by prefix: the stored URL may carry ?kiosk or a view
        // suffix appended later; the dashboard is the prefix.
        bool selected(String url) =>
            current == url || current.startsWith('$url/');
        return _SettingsCard(
          children: [
            for (final d in dashboards)
              ListTile(
                leading: Icon(
                  selected('$base/${d['url_path']}')
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected('$base/${d['url_path']}')
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text('${d['title'] ?? d['url_path']}'),
                subtitle: Text('${d['url_path']}'),
                onTap: () async {
                  final url = '$base/${d['url_path']}';
                  await c.settings.set(startUrl, url);
                  await c.commands.execute('loadUrl', {'url': url});
                  if (mounted) setState(() {});
                },
              ),
          ],
        );
      },
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
              ? 'Blocked. Android will not ask again — allow it in the app '
                    'settings.'
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
            title: 'Listening notification',
            held: 'The device shows that it is listening.',
            missing:
                'Without this it listens with nothing on screen to say so.',
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
        if (def.key == screensaverClockColor.key) {
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
                  final dest = '${dir.path}/${i.toString().padLeft(4, '0')}_$name';
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
          subtitle: Text(display),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editText(context),
        );
    }
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
        content: TextField(
          controller: controller,
          obscureText: def.secret,
          autofocus: true,
          keyboardType: def.type == SettingType.number
              ? TextInputType.number
              : TextInputType.text,
          decoration: InputDecoration(hintText: def.description),
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
