import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kiosk_screen.dart';

/// First-run onboarding: a five-step wizard, Home Assistant-oriented from
/// the first screen.
///
///   1. Welcome — and the offer to enable the remote admin, where typing a
///      long-lived token is a paste instead of a chore.
///   2. Connect — base URL + token; Next *is* the validation.
///   3. Dashboard — pick which one the kiosk shows.
///   4. Voice Satellite — when the card is found on the instance, offer the
///      recommended kiosk settings for it. Skipped silently otherwise.
///   5. Permissions — request what the chosen setup actually needs.
///
/// The same flow exists in the remote admin (an unconfigured device serves
/// it passwordless, minting the password as its own first step); if the
/// remote wizard finishes first, this screen sees the start URL land and
/// walks itself into the kiosk.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  AppContainer get c => widget.container;

  int _step = 0;
  bool _busy = false;
  String? _error;

  // Step 1 — remote admin.
  bool _remoteWanted = false;
  final _remotePassword = TextEditingController();
  String? _deviceIp;

  // Step 2 — connection.
  final _haUrl = TextEditingController();
  final _haToken = TextEditingController();

  // Step 3 — dashboards.
  List<Map<String, Object?>>? _dashboards;
  String? _dashboard;

  // Step 4 — Voice Satellite.
  bool? _vsDetected;
  bool _applyRecommended = true;

  StreamSubscription<SettingChanged>? _sub;

  @override
  void initState() {
    super.initState();
    c.device.ipAddress().then((ip) {
      if (mounted) setState(() => _deviceIp = ip);
    });
    // The remote wizard may configure this device while this screen is up;
    // the moment a start URL exists, onboarding is done wherever it happened.
    _sub = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.startUrl.key &&
          e.value is String &&
          (e.value as String).isNotEmpty) {
        _enterKiosk();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _remotePassword.dispose();
    _haUrl.dispose();
    _haToken.dispose();
    super.dispose();
  }

  void _enterKiosk() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => KioskScreen(container: c, showMenuHint: true),
      ),
    );
  }

  // ── Step transitions ───────────────────────────────────────────────────

  Future<void> _next() async {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (_remoteWanted) {
          final password = _remotePassword.text;
          if (password.length < 4) {
            setState(
              () => _error = 'Pick a password of at least 4 characters',
            );
            return;
          }
          await c.settings.set(defs.remotePassword, password);
          await c.settings.set(defs.remoteEnabled, true);
        }
        setState(() => _step = 1);
      case 1:
        final urlError = defs.validateBaseUrl(_haUrl.text);
        if (_haUrl.text.trim().isEmpty || urlError != null) {
          setState(
            () => _error = urlError ?? 'Enter your Home Assistant base URL',
          );
          return;
        }
        if (_haToken.text.trim().isEmpty) {
          setState(() => _error = 'Paste a long-lived access token');
          return;
        }
        setState(() => _busy = true);
        await c.settings.set(defs.haUrl, _haUrl.text.trim());
        await c.settings.set(defs.haToken, _haToken.text.trim());
        final error = await c.homeAssistant.validateConnection();
        if (!mounted) return;
        if (error != null) {
          setState(() {
            _busy = false;
            _error = error;
          });
          return;
        }
        final dashboards = await c.homeAssistant.listDashboards();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _dashboards = dashboards;
          _dashboard = dashboards?.firstOrNull?['url_path'] as String?;
          _step = 2;
        });
      case 2:
        if (_dashboard == null) {
          setState(() => _error = 'Pick a dashboard');
          return;
        }
        setState(() => _busy = true);
        final vs = await c.homeAssistant.detectVoiceSatellite();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _vsDetected = vs;
          // No Voice Satellite: nothing to recommend, straight on to the
          // permissions the minimal setup needs.
          _step = vs ? 3 : 4;
        });
      case 3:
        setState(() => _step = 4);
      case 4:
        setState(() => _busy = true);
        final full = _vsDetected == true && _applyRecommended;
        if (full) {
          await c.commands.execute('applyVsRecommended', const {});
        }
        await c.commands.execute('requestOsPermissions', {'full': full});
        // Last: setting the start URL is what flips the app to configured.
        await c.settings.set(
          defs.startUrl,
          '${c.homeAssistant.baseUrl}/$_dashboard',
        );
        _enterKiosk();
    }
  }

  void _back() => setState(() {
    _error = null;
    // Step 5 backs up to the VS choice only when that step was shown.
    _step = (_step == 4 && _vsDetected != true) ? 2 : _step - 1;
  });

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(theme),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: ListView(
                        key: ValueKey(_step),
                        children: _stepBody(theme),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _navButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Image.asset(
          theme.brightness == Brightness.dark
              ? 'assets/branding/mark.png'
              : 'assets/branding/mark_light.png',
          width: 56,
          height: 56,
        ),
        const SizedBox(height: 18),
        // The step dots: the current one stretched, everything reached
        // brand-tinted — progress you can read at arm's length.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _step ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i <= _step
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }

  List<Widget> _stepBody(ThemeData theme) {
    Widget headline(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    Widget body(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    Widget card(List<Widget> children) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );

    switch (_step) {
      case 0:
        return [
          headline('Welcome to Kiosk Satellite'),
          body(
            'Turn this tablet into a Home Assistant kiosk. Setup takes a '
            'couple of minutes.',
          ),
          card([
            SwitchListTile(
              title: const Text('Enable remote administration'),
              subtitle: Text(
                _remoteWanted && _deviceIp != null
                    ? 'Continue this setup from a computer at '
                          'http://$_deviceIp:2324 — pasting the access '
                          'token there is much easier.'
                    : 'Configure this kiosk from a browser on your '
                          'network. Recommended: the next step wants a '
                          'long-lived token pasted.',
              ),
              value: _remoteWanted,
              onChanged: (v) => setState(() => _remoteWanted = v),
            ),
            if (_remoteWanted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _remotePassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Remote admin password',
                  ),
                ),
              ),
          ]),
        ];
      case 1:
        return [
          headline('Connect to Home Assistant'),
          body(
            'The base URL of your instance and a long-lived access token '
            '(HA profile → Security → Long-lived access tokens).',
          ),
          card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                controller: _haUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Home Assistant Base URL',
                  hintText: 'https://homeassistant.local:8123',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: TextField(
                controller: _haToken,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Long-lived access token',
                ),
              ),
            ),
          ]),
        ];
      case 2:
        return [
          headline('Choose a dashboard'),
          body('This is what the kiosk will show.'),
          card([
            if (_dashboards == null || _dashboards!.isEmpty)
              const ListTile(title: Text('No dashboards found'))
            else
              for (final d in _dashboards!)
                ListTile(
                  leading: Icon(
                    _dashboard == d['url_path']
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _dashboard == d['url_path']
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  title: Text('${d['title'] ?? d['url_path']}'),
                  subtitle: Text('${d['url_path']}'),
                  onTap: () =>
                      setState(() => _dashboard = d['url_path'] as String?),
                ),
          ]),
        ];
      case 3:
        return [
          headline('Voice Satellite detected'),
          body(
            'This instance runs the Voice Satellite card. Apply the '
            'recommended kiosk settings for it?',
          ),
          card([
            SwitchListTile(
              title: const Text('Apply recommended settings'),
              subtitle: const Text(
                'Auto-reload on error, pull to refresh with cache clear, '
                'mixed content, self-signed certificates, microphone, '
                'autoplay, start on boot, keep screen on, native wake '
                'word detection with background listening, and remote '
                'management.',
              ),
              value: _applyRecommended,
              onChanged: (v) => setState(() => _applyRecommended = v),
            ),
          ]),
        ];
      case 4:
        final full = _vsDetected == true && _applyRecommended;
        return [
          headline('One more thing'),
          body(
            full
                ? 'Android will ask for the permissions the recommended '
                      'setup needs. Everything is requested up front so the '
                      'kiosk never interrupts you later.'
                : 'Android will ask for microphone access, so the '
                      'dashboard can listen when you use voice.',
          ),
          card([
            const ListTile(
              leading: Icon(Icons.mic_none),
              title: Text('Microphone'),
              subtitle: Text('Voice input for the dashboard'),
            ),
            if (full) ...[
              const ListTile(
                leading: Icon(Icons.notifications_none),
                title: Text('Notifications'),
                subtitle: Text('The background listening service'),
              ),
              const ListTile(
                leading: Icon(Icons.battery_saver),
                title: Text('Ignore battery optimizations'),
                subtitle: Text('So Android never freezes the kiosk'),
              ),
              const ListTile(
                leading: Icon(Icons.layers_outlined),
                title: Text('Display over other apps'),
                subtitle: Text('Start on boot needs it'),
              ),
            ],
          ]),
        ];
    }
    return const [];
  }

  Widget _navButtons(ThemeData theme) {
    return Row(
      children: [
        if (_step > 0)
          TextButton(
            onPressed: _busy ? null : _back,
            child: const Text('Back'),
          ),
        const Spacer(),
        FilledButton(
          onPressed: _busy ? null : _next,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
          child: Text(
            _busy
                ? 'Working…'
                : switch (_step) {
                    1 => 'Validate & continue',
                    4 => 'Finish',
                    _ => 'Next',
                  },
          ),
        ),
      ],
    );
  }
}
