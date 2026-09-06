import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_container.dart';
import 'kit.dart';

/// The helper is activated by ADB. Its current process decides availability.
class UpdateHelperSettings extends StatefulWidget {
  const UpdateHelperSettings({
    super.key,
    required this.container,
    this.entryBuilder,
  });

  final AppContainer container;
  final WidgetBuilder? entryBuilder;

  @override
  State<UpdateHelperSettings> createState() => _UpdateHelperSettingsState();
}

class _UpdateHelperSettingsState extends State<UpdateHelperSettings>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _status;
  String? _error;
  bool _busy = false;

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
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await widget.container.update.installerStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not check the update helper.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entryBuilder != null) {
      // A missing result is unknown, not evidence that a helper is needed.
      return _status?['nativeSilent'] == false
          ? widget.entryBuilder!(context)
          : const SizedBox.shrink();
    }
    if (_status?['nativeSilent'] == true) {
      return const HintRow(
        'Android can now install updates silently. The helper is not needed.',
        inset: false,
      );
    }
    if (_status == null) {
      return SettingsCard(
        children: [
          ListTile(
            title: const Text('Helper status'),
            subtitle: Text(_error ?? 'Checking...'),
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
      );
    }
    final helper = _status?['helper'];
    final active = helper == 'ready' || helper == 'busy';
    final command = _status?['startCommand'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HintRow(
          'This device currently needs confirmation on the screen to install '
          'updates through Android. The optional helper lets Kiosk Satellite '
          'install updates without a tap.',
          inset: false,
        ),
        SettingsCard(
          children: [
            ListTile(
              title: const Text('Helper status'),
              subtitle: Text(
                _error ??
                    (helper == 'busy'
                        ? 'Installing an update.'
                        : active
                        ? 'Ready. Updates install without confirmation.'
                        : 'Unavailable. Start the helper through ADB to enable updates without confirmation.'),
              ),
              trailing: IconButton(
                tooltip: 'Refresh',
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ),
            const HintRow(
              'The helper survives app restarts and updates but stops after a '
              'device reboot. Run the command from a computer with ADB to start '
              'it again. The computer can then disconnect.',
            ),
            if (command != null)
              ListTile(
                title: const Text('Start through ADB'),
                subtitle: SelectableText(
                  command,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  tooltip: 'Copy command',
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: command)),
                ),
              ),
            ListTile(
              title: const Text('Setup guide'),
              subtitle: const Text(
                'Read the update helper instructions and requirements.',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.container.commands.execute('showLinkPage', {
                  'url':
                      'https://github.com/jxlarrea/kiosk-satellite/blob/main/docs/updates.md#optional-update-helper',
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
