import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/update/update_manager.dart';

/// Slide-out menu (swipe from the left edge), Fully Kiosk style: Home,
/// Settings, Web Console, Clear web cache, Log out, Exit Application.
///
/// Not a Material [Drawer]: the kiosk pushes its content aside rather than
/// being covered (see KioskScreen), so this pane is square-cornered and
/// flush — the same plane as the WebView, not a sheet floating above it.
/// Only a hairline on its right edge marks the seam.
class KioskDrawer extends StatelessWidget {
  const KioskDrawer({
    super.key,
    required this.container,
    required this.onClose,
    required this.onWebConsole,
    required this.onSettings,
  });

  final AppContainer container;

  /// Slides the drawer (and the kiosk) back. Every action starts with this,
  /// mirroring how the old overlay drawer popped itself before acting.
  final VoidCallback onClose;

  /// Opens the bottom-docked JS console panel (owned by the kiosk screen).
  final VoidCallback onWebConsole;

  /// Opens the settings screen (owned by the kiosk screen, which also holds
  /// the screensaver while it is up).
  final VoidCallback onSettings;

  AppContainer get c => container;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
                child: Row(
                  children: [
                    // The bare brand mark, not the app-icon tile — cropped
                    // of its adaptive safe-zone padding at build time. White
                    // as designed on dark; on light the body is teal but the
                    // bubble keeps its three brand dots (mark_light.png).
                    Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/branding/mark.png'
                          : 'assets/branding/mark_light.png',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiosk Satellite',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            c.device.deviceName,
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
              // The actions, on one rounded section mask — the same card
              // language as the settings panes. The card hugs its content
              // and scrolls only if the screen is too short for it.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _item(
                                context,
                                Icons.dashboard_outlined,
                                'Dashboard',
                                () {
                                  onClose();
                                  c.commands.execute('loadUrl', {
                                    'url': c.browser.startUrl,
                                  });
                                },
                              ),
                              _item(
                                context,
                                Icons.settings_outlined,
                                'Settings',
                                () {
                                  onClose();
                                  onSettings();
                                },
                              ),
                              // One tap between off and the user's chosen
                              // strategy (auto/plugin/css, remembered in the
                              // hidden ha.kiosk_mode_last) — showing the HA
                              // header and sidebar briefly is the kind of
                              // thing done at the wall, without a trip into
                              // Settings. The kiosk screen reacts to the
                              // setting change and reloads the page.
                              _item(
                                context,
                                c.settings.get(defs.haKioskMode) == 'off'
                                    ? Icons.fullscreen
                                    : Icons.fullscreen_exit,
                                'Toggle HA Kiosk Mode',
                                () async {
                                  onClose();
                                  final mode = c.settings.get(
                                    defs.haKioskMode,
                                  );
                                  if (mode == 'off') {
                                    await c.settings.setFromJson(
                                      defs.haKioskMode.key,
                                      c.settings.get(defs.haKioskModeLast),
                                    );
                                  } else {
                                    await c.settings.setFromJson(
                                      defs.haKioskModeLast.key,
                                      mode,
                                    );
                                    await c.settings.setFromJson(
                                      defs.haKioskMode.key,
                                      'off',
                                    );
                                  }
                                },
                              ),
                              _item(
                                context,
                                Icons.terminal_outlined,
                                'Web Console',
                                () {
                                  onClose();
                                  onWebConsole();
                                },
                              ),
                              _item(
                                context,
                                Icons.cleaning_services_outlined,
                                'Clear web cache',
                                () {
                                  onClose();
                                  c.commands.execute('clearWebCache', const {});
                                },
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Divider(),
                              ),
                              _item(
                                context,
                                Icons.logout_outlined,
                                'Log out',
                                () async {
                                  onClose();
                                  if (context.mounted &&
                                      await _confirm(
                                        context,
                                        'Log out',
                                        'Clear cookies and site data, then reload the '
                                            'start page?',
                                      )) {
                                    await c.commands.execute(
                                      'logout',
                                      const {},
                                    );
                                  }
                                },
                              ),
                              _item(
                                context,
                                Icons.power_settings_new_outlined,
                                'Exit Application',
                                () async {
                                  onClose();
                                  if (context.mounted &&
                                      await _confirm(
                                        context,
                                        'Exit Application',
                                        'Close Kiosk Satellite?',
                                      )) {
                                    await c.commands.execute(
                                      'exitApp',
                                      const {},
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Above the theme switcher: the update notice when GitHub has
              // a newer release, the running version otherwise — the wall is
              // where an update is noticed, not the repo page.
              ValueListenableBuilder<UpdateInfo?>(
                valueListenable: c.update.available,
                builder: (context, info, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: info == null
                      // Tappable: a manual "check now" — the periodic check
                      // runs only twice a day, and the wall is where "did my
                      // update land?" gets asked.
                      ? InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _checkNow(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Version ${c.device.appVersion}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Material(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _offerUpdate(context, info),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.system_update_outlined,
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Update available',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                        ),
                                        Text(
                                          'Version ${info.version} · tap to '
                                          'install',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme.colorScheme
                                                    .onPrimaryContainer,
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
                ),
              ),
              // The theme switcher, docked at the foot of the menu. Icons
              // only — no label or separator: the card above already bounds
              // the actions, and the compact pill is the whole footer.
              // Flipping it is the kind of thing done at the wall, at night,
              // without a trip into Settings; it applies live (main.dart
              // listens for the setting) and the drawer stays open.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Center(
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: 'dark',
                        icon: Icon(Icons.dark_mode_outlined),
                        tooltip: 'Dark',
                      ),
                      ButtonSegment(
                        value: 'light',
                        icon: Icon(Icons.light_mode_outlined),
                        tooltip: 'Light',
                      ),
                      ButtonSegment(
                        value: 'system',
                        icon: Icon(Icons.brightness_auto_outlined),
                        tooltip: 'Follow Android',
                      ),
                    ],
                    selected: {c.settings.get(defs.uiTheme)},
                    onSelectionChanged: (selection) => c.settings.setFromJson(
                      defs.uiTheme.key,
                      selection.first,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One action row, same weight language as the settings rail.
  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Text(
                label,
                // The same style the settings rail titles use — titleMedium,
                // not bodyLarge: both are 16px, but bodyLarge tracks looser
                // (letter-spacing 0.5 vs 0.15) and the difference shows.
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Manual update check from the version line. An update found swaps the
  /// line for the notice via its ValueListenableBuilder on its own; the
  /// other two outcomes only exist as this feedback.
  Future<void> _checkNow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Checking for updates…')),
    );
    final reachable = await c.update.check();
    messenger.hideCurrentSnackBar();
    if (c.update.available.value != null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reachable
              ? 'You are on the latest version.'
              : 'Update check failed. Is the device online?',
        ),
      ),
    );
  }

  /// Release notes → download (progress dialog) → hand off to the Android
  /// installer, which asks its own final confirmation. The drawer stays put
  /// underneath so a cancelled install lands somewhere sensible.
  Future<void> _offerUpdate(BuildContext context, UpdateInfo info) async {
    final theme = Theme.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update to ${info.version}'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._releaseNotes(theme, info.notes),
                const SizedBox(height: 16),
                Text(
                  'The download starts on Update; Android asks you to '
                  'confirm the installation.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (go != true) return;
    if (!context.mounted) return;
    // Not awaited: the dialog is closed from below once the download
    // settles, whichever way it settles.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Downloading update'),
          content: ValueListenableBuilder<double?>(
            valueListenable: c.update.progress,
            builder: (context, p, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: p),
                const SizedBox(height: 12),
                Text(
                  p == null
                      ? 'Starting…'
                      : '${(p * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final error = await c.update.downloadAndInstall();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (error != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update failed'),
          content: Text(error),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// The GitHub release body, markdown-lite: headings bold, list markers as
  /// bullets, emphasis/code/link syntax stripped. A real markdown renderer
  /// is a dependency this one dialog does not justify.
  List<Widget> _releaseNotes(ThemeData theme, String notes) {
    String inline(String s) => s
        .replaceAllMapped(
          RegExp(r'\[([^\]]*)\]\([^)]*\)'),
          (m) => m[1] ?? '',
        )
        .replaceAll(RegExp(r'\*\*|__|`'), '');
    if (notes.isEmpty) {
      return [
        Text('No release notes.', style: theme.textTheme.bodyMedium),
      ];
    }
    final out = <Widget>[];
    for (final raw in notes.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        out.add(const SizedBox(height: 10));
      } else if (line.startsWith('#')) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              inline(line.replaceFirst(RegExp(r'^#+\s*'), '')),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else if (RegExp(r'^\s*[-*]\s+').hasMatch(line)) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '•  ${inline(line.replaceFirst(RegExp(r'^\s*[-*]\s+'), ''))}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        );
      } else {
        out.add(Text(inline(line), style: theme.textTheme.bodyMedium));
      }
    }
    return out;
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(title),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
