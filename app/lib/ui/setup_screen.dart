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
  String? _errorHint;

  void _fail(String error, String hint) => setState(() {
    _error = error;
    _errorHint = hint;
  });

  /// The connection check's terse verdicts, translated into something a
  /// person standing at a wall tablet can act on.
  void _connectFail(String error) {
    if (error.contains('invalid token')) {
      _fail(
        'Invalid access token',
        'Home Assistant rejected this token. In Home Assistant, open your '
        'profile → Security → Long-lived access tokens, create a new '
        'token, and copy the complete value.',
      );
    } else if (error.startsWith('unreachable')) {
      _fail(
        "Can't reach Home Assistant",
        'No response from this address. Check that the URL is correct and '
        'that this device is on the same network as your Home Assistant '
        'server.',
      );
    } else if (error.startsWith('HTTP')) {
      _fail(
        'Unexpected response ($error)',
        "A server responded, but it doesn't appear to be Home Assistant. "
        'Check that the URL is your Home Assistant base address, for '
        'example https://homeassistant.local:8123.',
      );
    } else {
      _fail("Can't connect", error);
    }
  }

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

  // Step 4 — Voice Satellite. Each recommended setting is its own choice;
  // the master switch just sets them all. Microphone and native wake word
  // detection are not choices — Voice Satellite does not work without
  // them, so they render locked-on.
  bool? _vsDetected;
  static const _lockedRecommended = <(String, String)>[
    ('web.microphone', 'Microphone access'),
    ('wake_word.enabled', 'Native wake word detection'),
  ];
  static const _optionalRecommended = <(String, String)>[
    ('browser.auto_reload_on_error', 'Auto-reload on error'),
    ('browser.pull_to_refresh', 'Pull to refresh'),
    ('browser.pull_to_refresh_clear_cache', 'Clear cache when pulling to refresh'),
    ('browser.allow_mixed_content', 'Allow mixed content'),
    ('browser.ignore_ssl_errors', 'Ignore SSL errors'),
    ('web.autoplay', 'Autoplay audio and video'),
    ('kiosk.start_on_boot', 'Start on boot'),
    ('screen.keep_on', 'Keep screen on'),
    ('wake_word.background', 'Keep listening in the background'),
    ('remote.enabled', 'Remote management'),
  ];
  late final Map<String, bool> _recommended = {
    for (final (key, _) in _optionalRecommended) key: true,
  };
  bool get _allRecommended => _recommended.values.every((v) => v);

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
    setState(() {
      _error = null;
      _errorHint = null;
    });
    switch (_step) {
      case 0:
        if (_remoteWanted) {
          final password = _remotePassword.text;
          if (password.length < 4) {
            _fail(
              'Password too short',
              'Use at least 4 characters.',
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
          _fail(
            urlError == null
                ? 'Enter your Home Assistant base URL'
                : 'Invalid base URL',
            urlError ??
                'This is the address you use to open Home Assistant, for '
                    'example https://homeassistant.local:8123.',
          );
          return;
        }
        if (_haToken.text.trim().isEmpty) {
          _fail(
            'Enter a long-lived access token',
            'In Home Assistant, open your profile → Security → Long-lived '
            'access tokens to create one.',
          );
          return;
        }
        setState(() => _busy = true);
        await c.settings.set(defs.haUrl, _haUrl.text.trim());
        await c.settings.set(defs.haToken, _haToken.text.trim());
        final error = await c.homeAssistant.validateConnection();
        if (!mounted) return;
        if (error != null) {
          setState(() => _busy = false);
          _connectFail(error);
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
          _fail(
            'Select a dashboard',
            'Choose the dashboard the kiosk will display. You can change '
            'it later in Settings.',
          );
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
        if (_vsStepActive) {
          for (final (key, _) in _lockedRecommended) {
            await c.settings.setFromJson(key, true);
          }
          for (final entry in _recommended.entries) {
            await c.settings.setFromJson(entry.key, entry.value);
          }
        }
        await c.commands.execute('requestOsPermissions', {
          'which': [
            'microphone',
            if (_vsStepActive && _recommended['wake_word.background']!) ...[
              'notifications',
              'batteryOptimizations',
            ],
            if (_vsStepActive && _recommended['kiosk.start_on_boot']!)
              'overlay',
          ],
        });
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
    _errorHint = null;
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
    // The step's content, with the error (if any) directly under the card
    // it belongs to — where the eye already is, not anchored to the screen
    // edge.
    List<Widget> withError(List<Widget> children) => [
      ...children,
      if (_error != null) _ErrorCard(title: _error!, hint: _errorHint),
    ];

    switch (_step) {
      case 0:
        return withError([
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
                    ? 'Continue this setup from a web browser at '
                          'http://$_deviceIp:2324 — pasting the Home '
                          'Assistant access token there is much easier.'
                    : 'Configure this kiosk from a web browser on your '
                          'network. Recommended: the next step needs a Home '
                          'Assistant access token pasted.',
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
        ]);
      case 1:
        return withError([
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
        ]);
      case 2:
        return withError([
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
        ]);
      case 3:
        return withError([
          heading('Voice Satellite detected'),
          lead(
            'This Home Assistant instance runs the Voice Satellite '
            'integration. You can change any of these later in Settings.',
          ),
          _Card([
            SwitchListTile(
              title: const Text('Apply all recommended settings'),
              subtitle: const Text(
                'The optimal settings for full Voice Satellite integration '
                'and functionality.',
              ),
              value: _allRecommended,
              onChanged: (v) => setState(() {
                for (final key in _recommended.keys) {
                  _recommended[key] = v;
                }
              }),
            ),
          ]),
          _Card([
            for (final (_, label) in _lockedRecommended)
              SwitchListTile(
                title: Text(label),
                subtitle: const Text('Required by Voice Satellite'),
                value: true,
                onChanged: null,
              ),
            for (final (key, label) in _optionalRecommended)
              SwitchListTile(
                title: Text(label),
                value: _recommended[key]!,
                onChanged: (v) => setState(() => _recommended[key] = v),
              ),
          ]),
        ]);
      case 4:
        final background =
            _vsStepActive && _recommended['wake_word.background']!;
        final bootStart =
            _vsStepActive && _recommended['kiosk.start_on_boot']!;
        return withError([
          heading('Permissions'),
          lead(
            'Android will ask for these permissions. Everything is '
            'requested up front so the kiosk never interrupts you later.',
          ),
          _Card([
            const ListTile(
              leading: Icon(Icons.mic_none),
              title: Text('Microphone'),
              subtitle: Text('Voice Satellite requires microphone access'),
            ),
            if (background) ...[
              const ListTile(
                leading: Icon(Icons.notifications_none),
                title: Text('Notifications'),
                subtitle: Text(
                  'Allows Kiosk Satellite to continue listening to the '
                  'wake word in the background',
                ),
              ),
              const ListTile(
                leading: Icon(Icons.battery_saver),
                title: Text('Ignore battery optimizations'),
                subtitle: Text(
                  'Allows Kiosk Satellite to run in the background '
                  'permanently',
                ),
              ),
            ],
            if (bootStart)
              const ListTile(
                leading: Icon(Icons.layers_outlined),
                title: Text('Display over other apps'),
                subtitle: Text(
                  'Grant this permission if you want Kiosk Satellite to '
                  'auto start when your device boots.',
                ),
              ),
          ]),
        ]);
    }
    return const [];
  }

  Widget _footer(ThemeData theme, EdgeInsets padding) {
    const buttonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_step > 0) ...[
            // Beside Next and dressed like it — the pair reads as one
            // control group, tonal vs filled carrying the hierarchy.
            FilledButton.tonal(
              onPressed: _busy ? null : _back,
              style: FilledButton.styleFrom(padding: buttonPadding),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          FilledButton(
            onPressed: _busy ? null : _next,
            style: FilledButton.styleFrom(padding: buttonPadding),
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
    );
  }
}

/// A problem, said usefully: what went wrong in bold, what to do about it
/// underneath — on the error container tint, same rounded mask as the rest
/// of the wizard, sitting right under the card it refers to.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: scheme.onErrorContainer,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onErrorContainer.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
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
