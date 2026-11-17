import 'dart:async';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kit.dart';

/// The Voice Match page's status row, under Enable Voice Match: whether
/// the kiosk found and signed in to Kiosk Satellite Voice Match, and who is
/// enrolled there. Mirrored in the remote admin (vs_native.js).
class VoiceMatchStatusRow extends StatefulWidget {
  const VoiceMatchStatusRow({super.key, required this.container});

  final AppContainer container;

  @override
  State<VoiceMatchStatusRow> createState() => _VoiceMatchStatusRowState();
}

class _VoiceMatchStatusRowState extends State<VoiceMatchStatusRow> {
  StreamSubscription<Object?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<RemoteStatusChanged>().listen((e) {
      if (e.topic == 'voice-match' && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    if (!c.settings.get(defs.voiceMatchEnabled)) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final m = c.voiceMatch;
    final names = [
      for (final p in m.people) '${p['name'] ?? ''}',
    ].where((n) => n.isNotEmpty).toList();
    final (String word, Color color, String detail) = switch (m.status) {
      'connected' => (
        voiceText(context, 'Connected'),
        scheme.primary,
        names.isEmpty
            ? voiceText(context, 'Nobody is enrolled yet.')
            : names.join(', '),
      ),
      'connecting' => (
        voiceText(context, 'Connecting'),
        scheme.onSurfaceVariant,
        m.baseUrl ?? '',
      ),
      'unreachable' => (
        voiceText(context, 'Not reachable'),
        scheme.tertiary,
        m.baseUrl ?? '',
      ),
      'refused' => (
        voiceText(context, 'Sign-in refused'),
        scheme.tertiary,
        voiceText(context, "Home Assistant refused this kiosk's token."),
      ),
      _ => (
        voiceText(context, 'Searching'),
        scheme.onSurfaceVariant,
        voiceText(context, 'Looking for Voice Match on the network.'),
      ),
    };
    final status = SettingsRow(
      title: Text(voiceText(context, 'Voice Match')),
      subtitle: detail.isEmpty ? null : Text(detail),
      trailing: Text(
        word,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    final app = m.appUrl;
    if (app == null) return status;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        status,
        // The app's page in Home Assistant, or the container's own page,
        // over the dashboard like a tapped dashboard link.
        SettingsRow(
          title: Text(voiceText(context, 'Voice Match app')),
          subtitle: Text(
            voiceText(context, 'People, enrollment, sessions and settings.'),
          ),
          trailing: TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              c.browser.showLinkOverlay(app);
            },
            child: Text(voiceText(context, 'Open')),
          ),
        ),
      ],
    );
  }
}
