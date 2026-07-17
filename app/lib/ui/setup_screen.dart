import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kiosk_screen.dart';

/// First-run onboarding: a five-step wizard, Home Assistant-oriented from
/// the first screen, in the app's One UI split layout — the step list on a
/// left rail, the current step's work on the right, exactly like Settings.
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

  static const _steps = <(IconData, String, String)>[
    (Icons.waving_hand_outlined, 'Welcome', 'Remote administration'),
    (Icons.link_outlined, 'Connect', 'Home Assistant URL & token'),
    (Icons.dashboard_outlined, 'Dashboard', 'What the kiosk shows'),
    (Icons.graphic_eq_outlined, 'Voice Satellite', 'Recommended settings'),
    (Icons.verified_user_outlined, 'Permissions', 'What the setup needs'),
  ];

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

  /// Whether the Voice Satellite step (index 3) is part of this run. Unknown
  /// until step 3's detection completes; the rail dims it meanwhile.
  bool get _vsStepActive => _vsDetected == true;

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
        final full = _vsStepActive && _applyRecommended;
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
    // Step 5 backs up to the dashboard step when Voice Satellite was skipped.
    _step = (_step == 4 && !_vsStepActive) ? 2 : _step - 1;
  });

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      body: SafeArea(child: wide ? _splitView(context) : _stacked(context)),
    );
  }

  Widget _splitView(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final railWidth = (width * 0.4).clamp(320.0, 430.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: railWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 20, 8),
                child: Row(
                  children: [
                    Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/branding/mark.png'
                          : 'assets/branding/mark_light.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Set up\nKiosk Satellite',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                  children: [
                    for (final (i, (icon, title, subtitle))
                        in _steps.indexed)
                      _railStep(context, i, icon, title, subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(8, 28, 28, 12),
                  children: _pane(theme),
                ),
              ),
              _footer(theme, const EdgeInsets.fromLTRB(8, 4, 28, 20)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stacked(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            children: [
              Image.asset(
                theme.brightness == Brightness.dark
                    ? 'assets/branding/mark.png'
                    : 'assets/branding/mark_light.png',
                width: 44,
                height: 44,
              ),
              const SizedBox(height: 12),
              // Compact progress dots on narrow screens; the rail is too wide.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
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
          ),
        ),
        Expanded(
          child: ListView(
            key: ValueKey(_step),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: _pane(theme),
          ),
        ),
        _footer(theme, const EdgeInsets.fromLTRB(20, 4, 20, 16)),
      ],
    );
  }

  /// One rail row: a numbered (or checked) disc, the step title and a
  /// one-line description, with the current step on a rounded highlight —
  /// the same shape Settings uses for its category rail.
  Widget _railStep(
    BuildContext context,
    int index,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    final current = index == _step;
    final done = index < _step && !(index == 3 && !_vsStepActive);
    final skipped = index == 3 && !_vsStepActive && _step > 3;
    final reachable = current || done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: current
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _StepDisc(
                number: index + 1,
                done: done,
                current: current,
                skipped: skipped,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: reachable
                            ? null
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      skipped ? 'Not installed — skipped' : subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Right pane per step ──────────────────────────────────────────────────

  List<Widget> _pane(ThemeData theme) {
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
      child: Text(
        text,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    Widget lead(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 20),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
    );

    switch (_step) {
      case 0:
        return [
          heading('Welcome'),
          lead(
            'Turn this tablet into a Home Assistant kiosk. Setup takes a '
            'couple of minutes — this wizard walks you through it.',
          ),
          _Card([
            SwitchListTile(
              title: const Text('Enable remote administration'),
              subtitle: Text(
                _remoteWanted && _deviceIp != null
                    ? 'Continue from a computer at http://$_deviceIp:2324 — '
                          'pasting the access token there is much easier.'
                    : 'Configure this kiosk from a browser on your network. '
                          'Recommended: the next step wants a long-lived '
                          'token pasted.',
              ),
              value: _remoteWanted,
              onChanged: (v) => setState(() => _remoteWanted = v),
            ),
            if (_remoteWanted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: TextField(
                  controller: _remotePassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Remote admin password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
          ]),
        ];
      case 1:
        return [
          heading('Connect to Home Assistant'),
          lead(
            'The base URL of your instance and a long-lived access token, '
            'created under your HA profile → Security → Long-lived access '
            'tokens.',
          ),
          _Card([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _haUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Home Assistant Base URL',
                  hintText: 'https://homeassistant.local:8123',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _haToken,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Long-lived access token',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ]),
        ];
      case 2:
        return [
          heading('Choose a dashboard'),
          lead('This is what the kiosk will show when it starts.'),
          _Card([
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
          heading('Voice Satellite detected'),
          lead(
            'This instance runs the Voice Satellite card. Apply the '
            'recommended kiosk settings for it? You can change any of them '
            'later in Settings.',
          ),
          _Card([
            SwitchListTile(
              title: const Text('Apply recommended settings'),
              subtitle: const Text(
                'Auto-reload on error, pull to refresh with cache clear, '
                'mixed content, self-signed certificates, microphone, '
                'autoplay, start on boot, keep screen on, native wake word '
                'detection with background listening, and remote management.',
              ),
              value: _applyRecommended,
              onChanged: (v) => setState(() => _applyRecommended = v),
            ),
          ]),
        ];
      case 4:
        final full = _vsStepActive && _applyRecommended;
        return [
          heading('Permissions'),
          lead(
            full
                ? 'Android will ask for the permissions the recommended setup '
                      'needs. Everything is requested up front so the kiosk '
                      'never interrupts you later.'
                : 'Android will ask for microphone access so the dashboard '
                      'can listen when you use voice.',
          ),
          _Card([
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

  Widget _footer(ThemeData theme, EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          Row(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
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
          ),
        ],
      ),
    );
  }
}

/// The step's numbered badge: a filled disc with the number, a check once
/// the step is done, or a dash when it was skipped; muted before it is
/// reached. Mirrors the colour-disc language of the settings rail.
class _StepDisc extends StatelessWidget {
  const _StepDisc({
    required this.number,
    required this.done,
    required this.current,
    required this.skipped,
  });

  final int number;
  final bool done;
  final bool current;
  final bool skipped;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = done || current;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: active ? scheme.primary : scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: done
          ? Icon(Icons.check, size: 18, color: scheme.onPrimary)
          : skipped
          ? Icon(Icons.remove, size: 18, color: scheme.onSurfaceVariant)
          : Text(
              '$number',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: current ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

/// The One UI section mask, matching the settings cards.
class _Card extends StatelessWidget {
  const _Card(this.children);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: children),
    ),
  );
}
