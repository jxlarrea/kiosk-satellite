import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;
import 'settings_screen.dart';

/// Slide-out menu (swipe from the left edge), Fully Kiosk style:
/// Home, Settings, Web Console, Log out, Exit Application.
class KioskDrawer extends StatelessWidget {
  const KioskDrawer({super.key, required this.container});

  final AppContainer container;

  AppContainer get c => container;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationDrawer(
      onDestinationSelected: (index) => _onSelected(context, index),
      selectedIndex: null,
      children: [
        DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.satellite_alt_rounded,
                  size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Kiosk Satellite', style: theme.textTheme.titleLarge),
              Text(
                '${c.device.deviceName} · v${c.device.appVersion}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          label: Text('Home'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          label: Text('Settings'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.terminal_outlined),
          label: Text('Web Console'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.logout_outlined),
          label: Text('Log out'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.power_settings_new_outlined),
          label: Text('Exit Application'),
        ),
      ],
    );
  }

  Future<void> _onSelected(BuildContext context, int index) async {
    Navigator.pop(context); // close the drawer first
    switch (index) {
      case 0: // Home
        await c.commands.execute('loadUrl', {'url': c.browser.startUrl});
      case 1: // Settings
        if (context.mounted) {
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => SettingsScreen(container: c),
          ));
        }
      case 2: // Web Console
        if (context.mounted) await _showWebConsoleInfo(context);
      case 3: // Log out
        if (context.mounted && await _confirm(context, 'Log out',
            'Clear cookies and site data, then reload the start page?')) {
          await c.commands.execute('logout', const {});
        }
      case 4: // Exit
        if (context.mounted && await _confirm(context, 'Exit Application',
            'Close Kiosk Satellite?')) {
          await c.commands.execute('exitApp', const {});
        }
    }
  }

  Future<void> _showWebConsoleInfo(BuildContext context) async {
    final enabled = c.settings.get(defs.remoteEnabled) &&
        c.settings.get(defs.remotePassword).isNotEmpty;
    final port = c.settings.get(defs.remotePort).toInt();
    final ip = await c.device.ipAddress();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Web Console'),
        content: Text(
          enabled
              ? 'Manage this kiosk from any browser on your network:\n\n'
                  'http://${ip ?? '<device-ip>'}:$port'
              : 'The web console is disabled.\n\nSet an admin password under '
                  'Settings → Remote to enable it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirm(
      BuildContext context, String title, String message) async {
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
