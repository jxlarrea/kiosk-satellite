import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;

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
                            '${c.device.deviceName} · v${c.device.appVersion}',
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
