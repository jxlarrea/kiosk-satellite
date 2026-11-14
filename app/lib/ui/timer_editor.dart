import 'package:flutter/material.dart';

import '../l10n/messages.dart';
import 'alarms_overlay.dart' show alarmButtonStyle;

/// Hours, minutes and seconds on three wheels, the alarm wheel's twin for a
/// length of time. Reports the whole in seconds.
class DurationWheel extends StatefulWidget {
  const DurationWheel({
    super.key,
    required this.seconds,
    required this.onChanged,
    this.compact = false,
  });

  final int seconds;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  State<DurationWheel> createState() => _DurationWheelState();
}

class _DurationWheelState extends State<DurationWheel> {
  late int _h = widget.seconds ~/ 3600 % 24;
  late int _m = widget.seconds % 3600 ~/ 60;
  late int _s = widget.seconds % 60;
  late final _hours = FixedExtentScrollController(initialItem: _h);
  late final _minutes = FixedExtentScrollController(initialItem: _m);
  late final _seconds = FixedExtentScrollController(initialItem: _s);

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _report() => widget.onChanged(_h * 3600 + _m * 60 + _s);

  Widget _column({
    required Key key,
    required FixedExtentScrollController controller,
    required int count,
    required String caption,
    required ValueChanged<int> onSelected,
    required double width,
    required double extent,
    required double fontSize,
  }) {
    final scheme = Theme.of(context).colorScheme;
    Widget item(int i) => Center(
      child: Text(
        '$i'.padLeft(2, '0'),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: widget.compact ? 13 : 15,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Semantics(
              label: caption,
              child: ListWheelScrollView.useDelegate(
                key: key,
                controller: controller,
                itemExtent: extent,
                diameterRatio: 2.4,
                perspective: 0.002,
                useMagnifier: true,
                magnification: 1.35,
                overAndUnderCenterOpacity: 0.4,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => onSelected(i % count),
                childDelegate: ListWheelChildLoopingListDelegate(
                  children: [for (var i = 0; i < count; i++) item(i)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = l10n(context);
    final compact = widget.compact;
    final extent = compact ? 56.0 : 72.0;
    final font = compact ? 32.0 : 42.0;
    final col = compact ? 88.0 : 140.0;
    final caption = compact ? 20.0 : 24.0;
    Widget colon() => Padding(
      padding: EdgeInsets.only(top: caption),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: font * 1.35,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
      ),
    );
    return SizedBox(
      height: extent * 5 + caption,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: caption + extent * 1.875,
            height: extent * 1.25,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _column(
                key: const ValueKey('timer-wheel-hours'),
                controller: _hours,
                count: 24,
                caption: s.voiceTimerHours,
                width: col,
                extent: extent,
                fontSize: font,
                onSelected: (i) {
                  _h = i;
                  _report();
                },
              ),
              colon(),
              _column(
                key: const ValueKey('timer-wheel-minutes'),
                controller: _minutes,
                count: 60,
                caption: s.voiceTimerMinutes,
                width: col,
                extent: extent,
                fontSize: font,
                onSelected: (i) {
                  _m = i;
                  _report();
                },
              ),
              colon(),
              _column(
                key: const ValueKey('timer-wheel-seconds'),
                controller: _seconds,
                count: 60,
                caption: s.voiceTimerSeconds,
                width: col,
                extent: extent,
                fontSize: font,
                onSelected: (i) {
                  _s = i;
                  _report();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The timers view's second page: the wheels for a new timer's length or a
/// running one's time left, the name of a new one, and the buttons.
class TimerEditorStep extends StatefulWidget {
  const TimerEditorStep({
    super.key,
    required this.compact,
    required this.seconds,
    required this.isNew,
    required this.name,
    required this.onCancel,
    required this.onSet,
    this.onDelete,
  });

  final bool compact;

  /// What the wheels open on.
  final int seconds;

  /// A new timer takes a name. A running one keeps its own: Home Assistant
  /// has no way to rename a timer.
  final bool isNew;
  final String name;
  final VoidCallback onCancel;
  final void Function(int seconds, String name) onSet;

  /// Cancels the timer being changed. Null for a new one.
  final VoidCallback? onDelete;

  @override
  State<TimerEditorStep> createState() => _TimerEditorStepState();
}

class _TimerEditorStepState extends State<TimerEditorStep> {
  late int _seconds = widget.seconds;
  late final _name = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = l10n(context);
    final scheme = Theme.of(context).colorScheme;
    final compact = widget.compact;
    final gutter = compact ? 20.0 : 40.0;
    final style = alarmButtonStyle(context);
    return Column(
      children: [
        SizedBox(height: compact ? 52 : 64),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.isNew && widget.name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          fontSize: compact ? 18 : 22,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  DurationWheel(
                    seconds: widget.seconds,
                    compact: compact,
                    onChanged: (v) => setState(() => _seconds = v),
                  ),
                  if (widget.isNew)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: compact ? 300 : 440,
                        child: TextField(
                          key: const ValueKey('timer-name'),
                          controller: _name,
                          maxLength: 40,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: s.voiceTimerName,
                            counterText: '',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, compact ? 20 : 28),
          child: Row(
            children: [
              if (widget.onDelete != null)
                TextButton(
                  key: const ValueKey('timer-delete'),
                  style: style.copyWith(
                    foregroundColor: WidgetStatePropertyAll(scheme.error),
                  ),
                  onPressed: widget.onDelete,
                  child: Text(s.commonDelete),
                ),
              const Spacer(),
              TextButton(
                style: style,
                onPressed: widget.onCancel,
                child: Text(s.commonCancel),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const ValueKey('timer-set'),
                style: style,
                // A timer of no length is no timer.
                onPressed: _seconds <= 0
                    ? null
                    : () => widget.onSet(_seconds, _name.text.trim()),
                child: Text(widget.isNew ? s.voiceStart : s.commonSet),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
