import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';
import '../managers/wake_word/background_listening.dart';
import '../managers/wake_word/system_permissions.dart';
import '../managers/wake_word/engine.dart';

/// A line between rows, and never after the last one.
///
/// The same rule the remote admin's `.row` border follows (see
/// assets/remote-ui/index.html): these two screens show the same settings and
/// are meant to read alike.
List<Widget> _separated(List<Widget> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1) const Divider(height: 1),
      ],
    ];

/// Hierarchical settings, Fully Kiosk style: the top level is a list of
/// category pages, each rendered from the declarative setting definitions —
/// the same source the remote admin UI uses.
///
/// Home Assistant and Voice Satellite share one page; the Voice Satellite
/// section only appears when the VS integration is detected on the
/// connected HA instance.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.container});

  final AppContainer container;

  static const _categories = <(String, String, IconData, String)>[
    // (defs category, page title, icon, subtitle)
    ('Browser', 'Web Browsing', Icons.public,
        'Start URL, error recovery'),
    ('Web Content', 'Web Content', Icons.tune,
        'Microphone, camera, geolocation, pop-ups'),
    ('Screen', 'Screen', Icons.brightness_6_outlined,
        'Brightness, keep awake'),
    ('Screensaver', 'Screensaver', Icons.dark_mode_outlined,
        'Idle timeout, dim and black modes'),
    ('Motion', 'Motion Detection', Icons.sensors,
        'Wake the screen with the camera'),
    ('Home Assistant', 'Home Assistant', Icons.home_outlined,
        'Connection, kiosk mode, Voice Satellite'),
    ('Remote', 'Remote Administration', Icons.settings_remote_outlined,
        'Web console access'),
    ('Device', 'Device', Icons.tablet_android_outlined,
        'Name and identity'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: _separated([
          for (final (category, title, icon, subtitle) in _categories)
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => category == 'Home Assistant'
                    ? HomeAssistantSettingsScreen(container: container)
                    : CategorySettingsScreen(
                        container: container,
                        title: title,
                        defs: _defsFor(category),
                      ),
              )),
            ),
        ]),
      ),
    );
  }

  static List<SettingDef<Object>> _defsFor(String category) =>
      [for (final def in allSettings) if (def.category == category) def];
}

/// One category's settings.
class CategorySettingsScreen extends StatefulWidget {
  const CategorySettingsScreen({
    super.key,
    required this.container,
    required this.title,
    required this.defs,
  });

  final AppContainer container;
  final String title;
  final List<SettingDef<Object>> defs;

  @override
  State<CategorySettingsScreen> createState() => _CategorySettingsScreenState();
}

class _CategorySettingsScreenState extends State<CategorySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        children: _separated([
          for (final def in widget.defs)
            if (widget.container.settings.visible(def))
              SettingTile(
                container: widget.container,
                def: def,
                onChanged: () => setState(() {}),
              ),
        ]),
      ),
    );
  }
}

/// Home Assistant + Voice Satellite share a page; the VS section is only
/// shown when the integration is detected on the connected instance.
class HomeAssistantSettingsScreen extends StatefulWidget {
  const HomeAssistantSettingsScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<HomeAssistantSettingsScreen> createState() =>
      _HomeAssistantSettingsScreenState();
}

class _HomeAssistantSettingsScreenState
    extends State<HomeAssistantSettingsScreen> {
  late Future<bool> _vsDetected;

  @override
  void initState() {
    super.initState();
    _vsDetected = widget.container.homeAssistant.detectVoiceSatellite();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Assistant')),
      body: ListView(
        children: [
          ..._separated([
            for (final def in SettingsScreen._defsFor('Home Assistant'))
              SettingTile(
                container: widget.container,
                def: def,
                onChanged: () => setState(() {}),
              ),
          ]),
          FutureBuilder<bool>(
            future: _vsDetected,
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The heading is the section break; a line as well would be
                  // saying it twice.
                  _SectionHeading('Voice Satellite'),
                  ..._separated([
                    for (final def
                        in SettingsScreen._defsFor('Voice Satellite'))
                      if (widget.container.settings.visible(def))
                        SettingTile(
                          container: widget.container,
                          def: def,
                          onChanged: () => setState(() {}),
                        ),
                    // Not a setting, but a row on the same list, so it sits
                    // behind the same line as the rest. Gone with the rest when
                    // detection is off: there is no state to report about a
                    // thing that is not running, and "it is off" is already
                    // said by the switch above.
                    if (widget.container.settings.get(wakeWordEnabled))
                      WakeWordStatusTile(container: widget.container),
                  ]),
                ],
              );
            },
          ),
          // Last, and on their own: these are the OS's to give, not ours to
          // set, and every one of them is a thing that stops working rather
          // than a preference.
          //
          // Only while we are the one listening. With wake word detection off
          // the card keeps detection in the browser, which asks for the
          // microphone through the WebView's own permission flow — so none of
          // this is ours to need, and demanding it would be asking for grants
          // nothing here uses.
          if (widget.container.settings.get(wakeWordEnabled)) ...[
            _SectionHeading('Required system permissions'),
            SystemPermissionsTile(container: widget.container),
          ],
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.primary),
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
    _sub = widget.container.bus
        .on<WakeWordStateChanged>()
        .listen((_) => setState(() {}));
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
        leading: Icon(status.code == 'disabled'
            ? Icons.mic_off_outlined
            : Icons.hourglass_empty),
        title: Text(status.code == 'disabled'
            ? 'Wake word detection is off'
            : 'Waiting for Voice Satellite'),
        subtitle: Text(status.label),
      );
    }

    final statusColor = wake.available
        ? (wake.listening ? theme.colorScheme.primary : theme.colorScheme.onSurface)
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
          subtitle: Text(status.label,
              style: theme.textTheme.bodyMedium?.copyWith(color: statusColor)),
        ),
        if (wake.canRetry) WakeWordRecoveryTile(container: widget.container),
        ListTile(
          leading: const Icon(Icons.graphic_eq),
          title: const Text('Engine'),
          subtitle: const Text('Running in Kiosk'),
          trailing: Text(config.engine.label,
              style: theme.textTheme.titleMedium),
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
            subtitle: Text(wake.stopWordAvailable
                ? 'Running in Kiosk'
                : 'Voice Satellite keeps this one in the browser'),
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
      subtitle: Text(settingsFirst
          ? 'Allow the microphone in the app settings, then retry.'
          : 'Try starting the engine again.'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (settingsFirst)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => widget.container.commands
                      .execute('openAppSettings', const {}),
              child: const Text('App settings'),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await widget.container.commands
                        .execute('retryWakeWord', const {});
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
            missing: 'Without this it listens with nothing on screen to say so.',
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
      subtitle: Text(_result ??
          'Re-download from Home Assistant. Use after re-publishing a model.'),
      trailing: _busy
          ? const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(
              onPressed: () async {
                setState(() => _busy = true);
                final result = await widget.container.commands
                    .execute('clearWakeWordModels', const {});
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
        return ListTile(
          title: Text(def.title),
          subtitle: Text(def.description),
          trailing: DropdownButton<String>(
            value: c.settings.get(def) as String,
            items: [
              for (final option in def.options ?? const <String>[])
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await c.settings.setFromJson(def.key, v);
              onChanged();
            },
          ),
        );
      case SettingType.string ||
            SettingType.password ||
            SettingType.number:
        final value = c.settings.get(def);
        final display = def.secret
            ? ((value as String).isEmpty ? 'Not set' : '••••••••')
            : '$value';
        return ListTile(
          title: Text(def.title),
          subtitle: Text(display),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _editText(context),
        );
    }
  }

  Future<void> _editText(BuildContext context) async {
    final current = c.settings.get(def);
    final controller = TextEditingController(
      text: def.secret ? '' : '$current',
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
