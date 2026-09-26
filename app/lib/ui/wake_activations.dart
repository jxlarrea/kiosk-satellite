import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/locale_dates.dart';
import '../l10n/messages.dart';
import '../managers/wake_word/wake_diagnostics.dart';
import 'kit.dart';
import 'toast.dart';
import 'wake_audio_player.dart';

/// The activations and near misses wake word diagnostics saved, as two
/// groups, newest first, each row with its scores, the clip's levels and a
/// button that plays the clip on the kiosk. One player for both, so two
/// clips never play over each other. Sits under the switch on the Wake word
/// diagnostics page; the remote admin draws the same groups from
/// getWakeWordActivations.
class WakeDiagnosticsLists extends StatefulWidget {
  const WakeDiagnosticsLists({super.key, required this.container});

  final AppContainer container;

  @override
  State<WakeDiagnosticsLists> createState() => _WakeDiagnosticsListsState();
}

class _WakeDiagnosticsListsState extends State<WakeDiagnosticsLists> {
  late final WakeAudioPlayer _player = WakeAudioPlayer(widget.container);

  WakeWordDiagnostics get _diagnostics => widget.container.wakeWord.diagnostics;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(WakeActivation a) async {
    if (_player.playing == a.id) {
      await _player.stop();
      return;
    }
    final file = await _diagnostics.clip(a.id);
    final ok = file != null && await _player.play(a.id, file: file);
    if (!ok && mounted) {
      showToast(
        context,
        title: voiceText(context, 'Could not play the sound.'),
        kind: ToastKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_diagnostics, _player]),
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ..._group(
          context,
          'Activations',
          _diagnostics.activations,
          'No wake word activations recorded yet.',
        ),
        ..._group(
          context,
          'Near misses',
          _diagnostics.nearMisses,
          'No near misses recorded yet.',
        ),
      ],
    ),
  );

  List<Widget> _group(
    BuildContext context,
    String title,
    List<WakeActivation> entries,
    String empty,
  ) => [
    SectionHeading(voiceText(context, title)),
    SettingsCard(
      children: entries.isEmpty
          ? [HintRow(voiceText(context, empty))]
          : [for (final a in entries) _row(context, a)],
    ),
  ];

  Widget _row(BuildContext context, WakeActivation a) {
    final theme = Theme.of(context);
    final playing = _player.playing == a.id;
    final muted = theme.colorScheme.onSurfaceVariant;
    return SettingsRow(
      trailing: IconButton.filledTonal(
        tooltip: voiceText(context, playing ? 'Stop' : 'Play'),
        onPressed: () => _toggle(a),
        icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
      ),
      title: Text(a.wakeWord.isEmpty ? a.engine : a.wakeWord),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: shortDateTime(a.at)),
            TextSpan(text: '\n${activationStats(context, a)}'),
            if (a.clipped > 0)
              TextSpan(
                text: '  ${voiceText(context, 'Clipped')}',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (a.decoded != null)
              TextSpan(
                text: '\n${voiceText(context, 'Heard')} [${a.decoded}]',
                style: TextStyle(color: muted, fontFamily: 'monospace'),
              ),
          ],
        ),
      ),
      onTap: () => _toggle(a),
    );
  }
}

/// "Score 0.912 · Threshold 0.650 · Peak level -3.1 dBFS · Average level
/// -31.2 dBFS", leaving out what the engine did not report.
String activationStats(BuildContext context, WakeActivation a) {
  String db(double v) =>
      v.isFinite ? '${v.toStringAsFixed(1)} dBFS' : '-∞ dBFS';
  return [
    if (a.score != null)
      '${voiceText(context, 'Score')} ${a.score!.toStringAsFixed(3)}',
    if (a.threshold != null)
      '${voiceText(context, 'Threshold')} ${a.threshold!.toStringAsFixed(3)}',
    '${voiceText(context, 'Peak level')} ${db(a.peakDb)}',
    '${voiceText(context, 'Average level')} ${db(a.rmsDb)}',
  ].join(' · ');
}
