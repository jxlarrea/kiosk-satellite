import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kiosk_screen.dart';

enum _SetupMode { website, homeAssistant }

/// First-run wizard.
///
/// Kiosk Satellite is a standalone kiosk app first: the primary path is
/// "point this device at any URL". Home Assistant is an optional mode that
/// unlocks the dashboard picker and kiosk mode — never a requirement.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  AppContainer get c => widget.container;

  var _mode = _SetupMode.website;

  final _startUrl = TextEditingController();
  final _haUrl = TextEditingController();
  final _haToken = TextEditingController();
  final _remotePassword = TextEditingController();

  List<Map<String, Object?>>? _dashboards;
  String? _selectedDashboard;
  String? _status;
  bool _busy = false;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    await c.settings.set(defs.haUrl, _haUrl.text.trim());
    await c.settings.set(defs.haToken, _haToken.text.trim());
    final error = await c.homeAssistant.checkConnection();
    if (error != null) {
      setState(() {
        _busy = false;
        _status = error;
      });
      return;
    }
    final dashboards = await c.homeAssistant.listDashboards();
    setState(() {
      _busy = false;
      _status = 'Connected';
      _dashboards = dashboards;
      if (dashboards != null && dashboards.isNotEmpty) {
        _selectedDashboard = dashboards.first['url_path'] as String?;
      }
    });
  }

  Future<void> _launch() async {
    String url;
    if (_mode == _SetupMode.website) {
      url = _startUrl.text.trim();
      if (url.isEmpty) {
        setState(() => _status = 'Enter the URL this kiosk should show');
        return;
      }
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
    } else {
      if (_selectedDashboard == null) {
        setState(() => _status = 'Connect and pick a dashboard first');
        return;
      }
      url = '${c.homeAssistant.baseUrl}/$_selectedDashboard';
    }
    final remotePassword = _remotePassword.text;
    if (remotePassword.isNotEmpty) {
      await c.settings.set(defs.remotePassword, remotePassword);
      await c.settings.set(defs.remoteEnabled, true);
    }
    await c.settings.set(defs.startUrl, url);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => KioskScreen(container: c, showMenuHint: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(32),
            children: [
              Image.asset('assets/branding/icon.png', width: 72, height: 72),
              const SizedBox(height: 16),
              Text(
                'Kiosk Satellite',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Turn this device into a kiosk. What should it show?',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SegmentedButton<_SetupMode>(
                segments: const [
                  ButtonSegment(
                    value: _SetupMode.website,
                    icon: Icon(Icons.public),
                    label: Text('Website'),
                  ),
                  ButtonSegment(
                    value: _SetupMode.homeAssistant,
                    icon: Icon(Icons.home_outlined),
                    label: Text('Home Assistant'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() {
                  _mode = selection.first;
                  _status = null;
                }),
              ),
              const SizedBox(height: 24),
              if (_mode == _SetupMode.website) ...[
                TextField(
                  controller: _startUrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://example.com',
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _haUrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Home Assistant URL',
                    hintText: 'http://homeassistant.local:8123',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _haToken,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Long-lived access token',
                    helperText: 'HA profile → Security → Long-lived tokens',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _busy ? null : _connect,
                  child: Text(_busy ? 'Connecting…' : 'Connect'),
                ),
                if (_dashboards != null) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDashboard,
                    decoration: const InputDecoration(labelText: 'Dashboard'),
                    items: [
                      for (final d in _dashboards!)
                        DropdownMenuItem(
                          value: d['url_path'] as String?,
                          child: Text('${d['title']}'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedDashboard = v),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _remotePassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Remote admin password (optional)',
                  helperText:
                      'Enables the web admin at http://<device-ip>:2324',
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 16),
                Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _status == 'Connected'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _launch,
                child: const Text('Launch kiosk'),
              ),
              if (_mode == _SetupMode.website) ...[
                const SizedBox(height: 12),
                Text(
                  'You can connect Home Assistant later in Settings.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startUrl.dispose();
    _haUrl.dispose();
    _haToken.dispose();
    _remotePassword.dispose();
    super.dispose();
  }
}
