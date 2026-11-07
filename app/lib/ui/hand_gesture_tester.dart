import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_container.dart';
import '../core/app_locales.dart';
import '../l10n/messages.dart';
import '../l10n/gesture_messages.dart';
import '../managers/gestures/gesture_mappings.dart';
import '../managers/gestures/hand_gesture_hold.dart';
import '../managers/motion/motion_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kit.dart';

/// The Hand Gesture Tester (Settings > Gestures, on the device only): a
/// live look at what the hand tracker reads, so the user learns how to
/// hold their hand for the Show fingers gesture before mapping one. The
/// row opens the tester as a modal and keeps the motion manager's hand
/// leg running for exactly as long as it is up; while it is, readings
/// come here instead of firing gestures.
class HandGestureTesterTile extends StatelessWidget {
  const HandGestureTesterTile({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    final c = container;
    final unsupported = c.deviceCamera.handsKnownUnsupported;
    final cameraOff = !c.settings.get(defs.cameraEnabled);
    final enabled = !unsupported && !cameraOff;
    return ListTile(
      leading: const Icon(Icons.waving_hand_outlined),
      title: Text(gestureText(context, 'Open tester')),
      subtitle: Text(
        unsupported
            ? gestureText(
                context,
                cameraText(
                  context,
                  c.deviceCamera.visionHint ?? 'Not available on this device.',
                ),
              )
            : cameraOff
            ? gestureText(
                context,
                'Turn on the camera in Camera settings first.',
              )
            : gestureText(
                context,
                'Watch which fingers the camera reads, to learn how to hold '
                'your hand.',
              ),
      ),
      trailing: const Icon(Icons.chevron_right),
      enabled: enabled,
      onTap: enabled
          ? () async {
              c.motion.startHandTest();
              try {
                await showDialog<void>(
                  context: context,
                  builder: (_) => HandGestureTesterDialog(
                    reading: c.motion.handTest,
                    hold: Duration(
                      milliseconds:
                          (c.settings.get(defs.handGestureHoldSeconds) * 1000)
                              .round(),
                    ),
                    mappings: decodeGestureMappings(
                      c.settings.get(defs.gestureMappings),
                    ),
                  ),
                );
              } finally {
                c.motion.stopHandTest();
              }
            }
          : null,
    );
  }
}

/// The modal: a hand whose digits light up as the tracker reads them,
/// the count and the gesture it would trigger, and how to hold the hand.
class HandGestureTesterDialog extends StatefulWidget {
  const HandGestureTesterDialog({
    super.key,
    required this.reading,
    required this.mappings,
    this.hold = Duration.zero,
    this.handClock,
  });

  final ValueListenable<HandTestReading?> reading;
  final List<GestureMapping> mappings;
  final Duration hold;
  final Duration Function()? handClock;

  @override
  State<HandGestureTesterDialog> createState() =>
      _HandGestureTesterDialogState();
}

class _HandGestureTesterDialogState extends State<HandGestureTesterDialog> {
  final _hold = HandGestureHold();
  final _clock = Stopwatch()..start();
  Timer? _expiry;

  @override
  void initState() {
    super.initState();
    widget.reading.addListener(_onReading);
    _updateHold();
  }

  @override
  void didUpdateWidget(HandGestureTesterDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reading != widget.reading || oldWidget.hold != widget.hold) {
      oldWidget.reading.removeListener(_onReading);
      widget.reading.addListener(_onReading);
      _hold.reset();
      _updateHold();
    }
  }

  void _onReading() => setState(_updateHold);

  void _updateHold() {
    final reading = widget.reading.value;
    _hold.update(
      hands: reading?.hands ?? 0,
      fingers: reading?.fingers,
      now: widget.handClock?.call() ?? _clock.elapsed,
      hold: widget.hold,
    );
    // Only fresh valid readings extend the display's lifetime.
    if (reading == null || reading.fingers != null) {
      _expiry?.cancel();
      if (widget.hold > Duration.zero && _hold.count != null) {
        _expiry = Timer(
          HandGestureHold.maxGap + const Duration(milliseconds: 1),
          () {
            if (mounted) setState(_hold.reset);
          },
        );
      }
    }
  }

  @override
  void dispose() {
    widget.reading.removeListener(_onReading);
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.waving_hand_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      gestureText(context, 'Hand Gesture Tester'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n(context).commonClose,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // The header stays put; the reading and the tips scroll
              // where the pane is short (a landscape Echo Show).
              Flexible(
                child: EdgeFade(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Reading(
                          reading: widget.reading.value,
                          mappings: widget.mappings,
                        ),
                        if (widget.hold > Duration.zero) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: _hold.progress),
                          const SizedBox(height: 8),
                          Text(
                            _hold.progress == 1
                                ? l10n(context).gestureHoldConfirmed
                                : l10n(context).gestureHoldProgress(
                                    NumberFormat.percentPattern(
                                      appLocaleName(context),
                                    ).format(_hold.progress),
                                  ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          l10n(context).gestureTesterHoldDuration(
                            localizedHandHoldDuration(
                              context,
                              widget.hold.inMilliseconds / 1000,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          style: muted,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          gestureText(
                            context,
                            'Hold your hand up at shoulder height, palm to the '
                            'camera, fingers spread. Curl a finger all the way '
                            'down to drop it from the count. Tuck the thumb '
                            'across the palm to show four: the thumb only '
                            'counts on an open hand.',
                          ),
                          style: muted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gestureText(
                            context,
                            'Gestures do not fire while the tester is open.',
                          ),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.reading, required this.mappings});

  final HandTestReading? reading;
  final List<GestureMapping> mappings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = reading;
    final fingers = r?.fingers;
    final up = r?.fingersUp;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    GestureMapping? match;
    if (fingers != null && fingers > 0) {
      for (final m in mappings) {
        if (m.triggerType != 'fingers') continue;
        if (((m.trigger['fingers'] as num?)?.toInt() ?? 5) == fingers) {
          match = m;
          break;
        }
      }
    }

    // Always the same four lines, blanks included, so the modal keeps
    // one height as hands come and go.
    final String detail;
    if (r == null) {
      detail = gestureText(context, 'Show a hand to the camera.');
    } else if (match != null) {
      detail = l10n(
        context,
      ).gestureTesterTrigger(localizedGestureAction(context, match.action));
    } else if (fingers != null && fingers > 0) {
      detail = gestureText(context, 'No gesture uses this count.');
    } else {
      detail = ' ';
    }
    final String label;
    if (r == null) {
      label = gestureText(context, 'No hand in view');
    } else if (fingers == null) {
      label = gestureText(context, 'Reading the hand');
    } else if (fingers == 0) {
      label = gestureText(context, 'No fingers up');
    } else {
      label = localizedGestureTrigger(context, {
        'type': 'fingers',
        'fingers': fingers,
      });
    }
    return Column(
      children: [
        _HandFigure(up: up, seen: r != null),
        const SizedBox(height: 16),
        Text(
          r == null ? ' ' : '${fingers ?? '?'}',
          maxLines: 1,
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.primary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(detail, textAlign: TextAlign.center, style: muted),
        Text(
          r != null && r.hands > 1
              ? l10n(context).gestureHandsCount('${r.hands}')
              : ' ',
          textAlign: TextAlign.center,
          style: muted,
        ),
      ],
    );
  }
}

/// Five bars for the five digits, thumb first, lit while the tracker
/// reads that digit as up, over a palm. Unseen hands draw dimmer.
class _HandFigure extends StatelessWidget {
  const _HandFigure({required this.up, required this.seen});

  final List<bool>? up;
  final bool seen;

  static const _heights = [48.0, 80.0, 90.0, 84.0, 64.0];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rest = scheme.surfaceContainerHighest.withValues(
      alpha: seen ? 1 : 0.6,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 8,
          children: [
            for (var i = 0; i < 5; i++)
              AnimatedContainer(
                key: ValueKey('finger-$i'),
                duration: const Duration(milliseconds: 150),
                width: 26,
                height: _heights[i],
                // The thumb sits lower and apart, off the side of the palm.
                margin: EdgeInsets.only(
                  bottom: i == 0 ? 0 : 6,
                  right: i == 0 ? 6 : 0,
                ),
                decoration: BoxDecoration(
                  color: (up?[i] ?? false) ? scheme.primary : rest,
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
          ],
        ),
        Container(
          width: 4 * 26 + 3 * 8 + 4,
          height: 52,
          margin: const EdgeInsets.only(left: 26 + 8 + 6),
          decoration: BoxDecoration(
            color: rest,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
              bottom: Radius.circular(24),
            ),
          ),
        ),
      ],
    );
  }
}
