import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../managers/shizuku/shizuku_manager.dart';
import '../managers/wake_word/permission_descriptions.dart';
import 'kit.dart';
import 'plugin_shizuku.dart';
import 'toast.dart';
import 'settings_search.dart';

class ShizukuSettingsPanel extends StatefulWidget {
  const ShizukuSettingsPanel({
    super.key,
    required this.manager,
    required this.updateSettings,
  });
  final ShizukuManager manager;
  final Widget updateSettings;
  @override
  State<ShizukuSettingsPanel> createState() => _ShizukuSettingsPanelState();
}

class _ShizukuSettingsPanelState extends State<ShizukuSettingsPanel>
    with WidgetsBindingObserver {
  String? _busy;
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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.manager.refresh();
    } catch (_) {
      if (mounted) widget.manager.state.value = const {'status': 'unavailable'};
    }
  }

  Future<void> _run(String action) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    try {
      if (action == 'permission') {
        await widget.manager.refresh(request: true);
      } else {
        final result = await widget.manager.run(action);
        if (!mounted) return;
        if (action == 'identity') {
          final ok = result['exitCode'] == 0 && result['timedOut'] != true;
          showToast(
            context,
            title: 'Connection test',
            message: ok
                ? 'Shizuku successfully ran a command with ${widget.manager.state.value['uid'] == 0 ? 'root' : 'shell'} access.'
                : 'Shizuku could not complete the connection test.',
            kind: ok ? ToastKind.success : ToastKind.error,
          );
        } else {
          final rows = (result['results'] as List? ?? const [])
              .whereType<Map>()
              .toList();
          final failed = rows.where((row) => row['ok'] != true).toList();
          final names = {
            for (final entry in devicePermissionDescriptions.entries)
              entry.key: entry.value.title,
          };
          final message = rows.isEmpty
              ? 'All permissions are already granted.'
              : failed.isEmpty
              ? 'Android confirmed the requested permissions.'
              : failed
                    .map(
                      (row) =>
                          '${names[row['key']] ?? row['key']}: ${row['error']}',
                    )
                    .join('\n');
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission results'),
              content: SingleChildScrollView(child: Text(message)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        showToast(
          context,
          title: 'Shizuku',
          message: '$error',
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _button(
    String action,
    String label,
    bool enabled, {
    bool primary = false,
  }) {
    final child = _busy == action
        ? SizedBox(
            width: 48,
            height: 20,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : Text(label);
    final onPressed = enabled && _busy == null ? () => _run(action) : null;
    return primary
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<Map<String, Object?>>(
    valueListenable: widget.manager.state,
    builder: (_, state, _) {
      final ready = state['granted'] == true;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading('Connection'),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:shizuku:permission',
                child: SettingsRow(
                  title: const Text('Shizuku access'),
                  subtitle: Text(
                    pluginShizukuHint(
                      state,
                    ).replaceAll(' Tap for setup instructions.', ''),
                  ),
                  trailing: ready
                      ? const Icon(Icons.check_circle_outline)
                      : _button(
                          'permission',
                          'Grant',
                          state['status'] == 'permission_required',
                        ),
                ),
              ),
              SearchLandingTarget(
                id: 'x:shizuku:identity',
                child: SettingsRow(
                  title: const Text('Test connection'),
                  subtitle: const Text(
                    'Read the process identity without changing the device.',
                  ),
                  trailing: _button('identity', 'Test', ready),
                ),
              ),
            ],
          ),
          SettingsCard(children: [widget.updateSettings]),
          const SectionHeading('Permissions'),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:shizuku:grantAll',
                child: SettingsRow(
                  title: const Text('Grant all permissions'),
                  subtitle: const Text(
                    'Grant all permissions used by KS, including features that are currently off.',
                  ),
                  trailing: _button('grantAll', 'Grant', ready, primary: true),
                ),
              ),
              for (final entry in devicePermissionDescriptions.entries)
                SearchLandingTarget(
                  id: 'x:shizuku:${entry.key}',
                  child: SettingsRow(
                    title: Text(entry.value.title),
                    subtitle: Text(entry.value.description),
                    trailing: _button(entry.key, 'Grant', ready),
                  ),
                ),
            ],
          ),
          const SectionHeading('Help'),
          SettingsCard(
            children: [
              SearchLandingTarget(
                id: 'x:shizuku:setup',
                child: SettingsRow(
                  title: const Text('Set up Shizuku'),
                  subtitle: const Text(
                    'Read installation and startup instructions.',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => launchUrl(
                    Uri.parse('https://shizuku.rikka.app/guide/setup/'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              const HintRow(
                'Shizuku started through ADB must be started again after a device reboot. Shell access does not provide root permissions.',
              ),
            ],
          ),
        ],
      );
    },
  );
}
