import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kiosk_screen.dart';

/// First-run wizard: the minimum needed to launch the kiosk.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  AppContainer get c => widget.container;

  final _haUrl = TextEditingController();
  final _haToken = TextEditingController();
  final _startUrl = TextEditingController();

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
    var url = _startUrl.text.trim();
    if (url.isEmpty && _selectedDashboard != null) {
      final base = c.homeAssistant.baseUrl;
      url = '$base/$_selectedDashboard';
    }
    if (url.isEmpty) {
      setState(() => _status = 'Enter a start URL or pick a dashboard');
      return;
    }
    await c.settings.set(defs.startUrl, url);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => KioskScreen(container: c),
    ));
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
              Icon(Icons.satellite_alt_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Kiosk Satellite',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Point this device at a dashboard to get started.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 32),
              TextField(
                controller: _haUrl,
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
              const SizedBox(height: 16),
              TextField(
                controller: _startUrl,
                decoration: const InputDecoration(
                  labelText: 'Or a custom start URL',
                  hintText: 'https://…',
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _haUrl.dispose();
    _haToken.dispose();
    _startUrl.dispose();
    super.dispose();
  }
}
