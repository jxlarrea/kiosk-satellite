import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../managers/plugins/plugin_manager.dart';
import 'kit.dart';
import 'toast.dart';

String pluginShizukuHint(Map<String, Object?> state) =>
    switch (state['status']) {
      'checking' => 'Checking availability',
      'ready' =>
        state['uid'] == 0
            ? 'Connected with root access'
            : 'Connected with shell access',
      'permission_required' =>
        'Tap to grant access. Approve the request on this kiosk.',
      'denied' => 'Allow Kiosk Satellite in the Shizuku app.',
      'unsupported' =>
        'Shizuku 13 or later is required. Tap for setup instructions.',
      _ => 'Start Shizuku on this device. Tap for setup instructions.',
    };

class PluginShizukuPanel extends StatefulWidget {
  const PluginShizukuPanel({
    super.key,
    required this.plugins,
    required this.id,
  });
  final PluginManager plugins;
  final String id;
  @override
  State<PluginShizukuPanel> createState() => _PluginShizukuPanelState();
}

class _PluginShizukuPanelState extends State<PluginShizukuPanel> {
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      await widget.plugins.refreshShizuku();
    } catch (_) {
      if (mounted) {
        widget.plugins.shizuku.value = const {'status': 'unavailable'};
      }
    }
  }

  Future<void> _activate(bool request) async {
    setState(() => _busy = true);
    try {
      if (request) {
        await widget.plugins.refreshShizuku(requestFor: widget.id);
      } else {
        await launchUrl(
          Uri.parse('https://shizuku.rikka.app/guide/setup/'),
          mode: LaunchMode.externalApplication,
        );
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<Map<String, Object?>>(
    valueListenable: widget.plugins.shizuku,
    builder: (_, state, _) => SettingsCard(
      children: [
        SettingsRow(
          title: const Text('Shizuku access'),
          subtitle: Text(pluginShizukuHint(state)),
          trailing: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  state['granted'] == true
                      ? Icons.check_circle_outline
                      : state['status'] == 'permission_required'
                      ? Icons.lock_open_rounded
                      : Icons.open_in_new,
                ),
          onTap:
              _busy || state['granted'] == true || state['status'] == 'checking'
              ? null
              : () => _activate(state['status'] == 'permission_required'),
        ),
        const HintRow(
          'Shizuku grants Kiosk Satellite shell or root access. Installed plugins run inside KS, so only grant access if you trust them.',
        ),
      ],
    ),
  );
}
