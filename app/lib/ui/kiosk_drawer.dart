import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_container.dart';
import '../managers/sendspin/music_assistant_api.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/update/update_manager.dart';
import 'kit.dart';
import 'theme.dart';

/// Slide-out menu (swipe from the left edge), Fully Kiosk style: Home,
/// Settings, Clear web cache, Log out, Exit Application.
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
    required this.onSettings,
    this.restricted = false,
  });

  final AppContainer container;

  /// Quick-actions mode: the drawer was opened by an edge swipe while kiosk
  /// mode holds the door (kiosk.allow_drawer). Only the harmless actions the
  /// owner allowed are shown; everything that changes state or escapes the
  /// kiosk stays behind the exit gesture and PIN.
  final bool restricted;

  /// Slides the drawer (and the kiosk) back. Every action starts with this,
  /// mirroring how the old overlay drawer popped itself before acting.
  final VoidCallback onClose;

  /// Opens the settings screen (owned by the kiosk screen, which also holds
  /// the screensaver while it is up).
  final VoidCallback onSettings;

  AppContainer get c => container;

  /// The Music Assistant web interface to offer, or null when the shortcut
  /// is switched off or no server address has been set.
  String? get _musicUrl => c.settings.get(defs.sendspinMaShortcut)
      ? musicAssistantWebUrl(c.settings.get(defs.sendspinMaUrl))
      : null;

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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Row(
                  children: [
                    // The app-icon tile, as vectors. It carries its own teal
                    // background, so the same asset reads on both themes.
                    SvgPicture.asset(
                      'assets/branding/icon_rounded.svg',
                      width: 48,
                      height: 48,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kiosk Satellite',
                            // The display face ties the header to the page
                            // titles and the screensaver clock.
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: Ks.displayFont,
                              fontWeight: FontWeight.w600,
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
                        borderRadius: BorderRadius.circular(Ks.radiusCard),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!restricted ||
                                  c.settings.get(defs.kioskAllowDashboard))
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
                              if (!restricted)
                                _item(
                                  context,
                                  Icons.settings_outlined,
                                  'Settings',
                                  () {
                                    onClose();
                                    onSettings();
                                  },
                                ),
                              // One tap between hidden and shown — bringing
                              // the HA header and sidebar back briefly is the
                              // kind of thing done at the wall, without a trip
                              // into Settings. The kiosk screen reacts to the
                              // setting change and restyles the page.
                              if (!restricted)
                                _item(
                                  context,
                                  c.settings.get(defs.haKioskMode)
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  'HA Kiosk Mode',
                                  () async {
                                    onClose();
                                    await c.settings.set(
                                      defs.haKioskMode,
                                      !c.settings.get(defs.haKioskMode),
                                    );
                                  },
                                ),
                              // Only once the default view actually holds
                              // cameras: an empty one is the placeholder
                              // every install starts with, and a menu entry
                              // that can only fail is worse than no entry.
                              if (!restricted ||
                                  c.settings.get(defs.kioskAllowCamera))
                                if (c.camera.config.defaultView case final view?
                                    when view.cameraIds.isNotEmpty)
                                  _item(
                                    context,
                                    Icons.videocam_outlined,
                                    'Camera View',
                                    () {
                                      onClose();
                                      c.camera.showView(view.id);
                                    },
                                  ),
                              // Music Assistant's own web interface, over
                              // the dashboard on the same surface a tapped
                              // link gets — browsing, queueing and
                              // playlists belong to the server that
                              // already does all of it well. Shown only
                              // once its address is configured (the same
                              // one the lyrics use): an entry that can
                              // only fail is worse than no entry.
                              if (!restricted ||
                                  c.settings.get(defs.kioskAllowMusic))
                                if (_musicUrl case final url?)
                                  _item(
                                    context,
                                    'assets/svg/music-assistant.svg',
                                    'Music Assistant',
                                    () {
                                      onClose();
                                      c.commands.execute('showLinkPage', {
                                        'url': url,
                                      });
                                    },
                                  ),
                              if (!restricted ||
                                  c.settings.get(defs.kioskAllowScreensaver))
                                _item(
                                  context,
                                  Icons.dark_mode_outlined,
                                  'Start Screensaver',
                                  () {
                                    onClose();
                                    c.commands.execute(
                                      'startScreensaver',
                                      const {},
                                    );
                                  },
                                ),
                              // Only with the launcher enabled and apps
                              // actually whitelisted: an empty launcher is
                              // the placeholder every install starts with,
                              // and a menu entry that can only fail is
                              // worse than no entry.
                              if (!restricted ||
                                  c.settings.get(defs.kioskAllowApps))
                                if (c.settings.get(defs.launcherEnabled) &&
                                    c.launcher.apps.isNotEmpty)
                                  _item(
                                    context,
                                    Icons.apps_outlined,
                                    'Apps',
                                    () {
                                      onClose();
                                      c.launcher.visible.value = true;
                                    },
                                  ),
                              if (!restricted)
                                _item(
                                  context,
                                  Icons.cleaning_services_outlined,
                                  'Clear web cache',
                                  () {
                                    onClose();
                                    c.commands.execute(
                                      'clearWebCache',
                                      const {},
                                    );
                                  },
                                ),
                              if (!restricted)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Divider(),
                                ),
                              if (!restricted)
                                _item(
                                  context,
                                  Icons.logout_outlined,
                                  'Log out',
                                  () async {
                                    onClose();
                                    if (context.mounted &&
                                        await showConfirmDialog(
                                          context,
                                          title: 'Log out',
                                          message:
                                              'Clear cookies and site data, '
                                              'then reload the start page?',
                                          confirmLabel: 'Log out',
                                        )) {
                                      await c.commands.execute(
                                        'logout',
                                        const {},
                                      );
                                    }
                                  },
                                ),
                              if (!restricted)
                                _item(
                                  context,
                                  Icons.power_settings_new_outlined,
                                  'Exit Application',
                                  () async {
                                    onClose();
                                    if (context.mounted &&
                                        await showConfirmDialog(
                                          context,
                                          title: 'Exit Application',
                                          message: 'Close Kiosk Satellite?',
                                          confirmLabel: 'Exit',
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
              // where an update is noticed, not the repo page. Not in the
              // restricted menu: installing an update is not a quick action.
              if (!restricted)
                ValueListenableBuilder<UpdateInfo?>(
                  valueListenable: c.update.available,
                  builder: (context, info, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: info == null
                        // Tappable: a manual "check now" — the periodic check
                        // runs only twice a day, and the wall is where "did my
                        // update land?" gets asked.
                        ? InkWell(
                            borderRadius: BorderRadius.circular(
                              Ks.radiusControl,
                            ),
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
                            borderRadius: BorderRadius.circular(Ks.radiusRow),
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
                                                  color: theme
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                          ),
                                          Text(
                                            'Version ${info.version} · tap to '
                                            'install',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
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
              if (!restricted || c.settings.get(defs.kioskAllowTheme))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Center(
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
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
  /// One menu row. [icon] is a Material glyph, or the path of an SVG asset
  /// for the entries that answer to a product rather than a feature — the
  /// same rule the settings rail follows, drawn in the row's own color so a
  /// product mark does not become the one colored thing in the menu.
  Widget _item(
    BuildContext context,
    Object icon,
    String label,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(Ks.radiusRow),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (icon is String)
                // Boxed to the glyph size so every label in the menu starts
                // on the same line, whatever the mark's own proportions.
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: SvgPicture.asset(
                      icon,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  icon as IconData,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
    final canRelaunch = await c.update.canRelaunch();
    if (!context.mounted) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update to ${info.version}'),
        content: SizedBox(
          width: 420,
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
                if (!canRelaunch) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Without the "Display over other apps" permission the '
                    'app cannot reopen itself after updating.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
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
                  p == null ? 'Starting…' : '${(p * 100).toStringAsFixed(0)}%',
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
      // The download re-checks GitHub before it starts, so it can also come
      // back with "nothing to install" (the offered release was pulled and
      // this build is the latest); that is not a failure. Nothing pending
      // afterwards is what tells the two apart.
      final pending = c.update.available.value != null;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(pending ? 'Update failed' : 'Updates'),
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
        .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1] ?? '')
        .replaceAll(RegExp(r'\*\*|__|`'), '');
    if (notes.isEmpty) {
      return [Text('No release notes.', style: theme.textTheme.bodyMedium)];
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
}
