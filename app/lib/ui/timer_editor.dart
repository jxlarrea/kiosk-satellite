import 'package:flutter/material.dart';

import '../l10n/messages.dart';
import 'alarms_overlay.dart' show alarmButtonStyle, wheelBand, wheelFit;

/// Hours, minutes and seconds on three wheels, the alarm wheel's twin for a
/// length of time. Reports the whole in seconds.
class DurationWheel extends StatefulWidget {
  const DurationWheel({
    super.key,
    required this.seconds,
    required this.onChanged,
    this.compact = false,
    this.room,
  });

  final int seconds;
  final ValueChanged<int> onChanged;
  final bool compact;

  /// The space the wheel has. When five rows do not fit there it shows
  /// three bigger ones, see [wheelFit].
  final Size? room;

  @override
  State<DurationWheel> createState() => _DurationWheelState();

  /// Rows and scale for a wheel in [room], see [wheelFit].
  static ({int rows, double scale}) fitIn(
    Size? room, {
    required bool compact,
  }) => wheelFit(
    room: room,
    extent: compact ? 56.0 : 72.0,
    // The caption over each column.
    extra: compact ? 20.0 : 24.0,
    // Three columns and two colons.
    width: (compact ? 88.0 : 140.0) * 3 + (compact ? 32.0 : 42.0) * 1.2,
  );
}

class _DurationWheelState extends State<DurationWheel> {
  late int _h = widget.seconds ~/ 3600 % 24;
  late int _m = widget.seconds % 3600 ~/ 60;
  late int _s = widget.seconds % 60;
  FixedExtentScrollController? _hours, _minutes, _seconds;
  double? _extent;

  /// New controllers when the row height changes: a wheel handed a new
  /// controller keeps the old one's offset in pixels, so it would land on
  /// another row. The wheels are keyed on the height and rebuilt with these.
  void _sync(double extent) {
    if (_extent == extent) return;
    final old = [_hours, _minutes, _seconds];
    if (old.first != null) {
      // The old wheels still hold these until this build detaches them.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in old) {
          c?.dispose();
        }
      });
    }
    _extent = extent;
    _hours = FixedExtentScrollController(initialItem: _h);
    _minutes = FixedExtentScrollController(initialItem: _m);
    _seconds = FixedExtentScrollController(initialItem: _s);
  }

  @override
  void dispose() {
    _hours?.dispose();
    _minutes?.dispose();
    _seconds?.dispose();
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
    required double captionSize,
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
              fontSize: captionSize,
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
    final fit = DurationWheel.fitIn(widget.room, compact: compact);
    final extent = (compact ? 56.0 : 72.0) * fit.scale;
    final font = (compact ? 32.0 : 42.0) * fit.scale;
    final col = (compact ? 88.0 : 140.0) * fit.scale;
    final caption = (compact ? 20.0 : 24.0) * fit.scale;
    final captionSize = (compact ? 13.0 : 15.0) * fit.scale;
    _sync(extent);
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
      height: extent * fit.rows + caption,
      child: Stack(
        alignment: Alignment.center,
        children: [
          wheelBand(context, rows: fit.rows, extent: extent, top: caption),
          Row(
            // New wheels when the rows change height, with the controllers
            // [_sync] made for them.
            key: ValueKey(extent),
            mainAxisSize: MainAxisSize.min,
            children: [
              _column(
                key: const ValueKey('timer-wheel-hours'),
                controller: _hours!,
                count: 24,
                caption: s.voiceTimerHours,
                width: col,
                extent: extent,
                fontSize: font,
                captionSize: captionSize,
                onSelected: (i) {
                  _h = i;
                  _report();
                },
              ),
              colon(),
              _column(
                key: const ValueKey('timer-wheel-minutes'),
                controller: _minutes!,
                count: 60,
                caption: s.voiceTimerMinutes,
                width: col,
                extent: extent,
                fontSize: font,
                captionSize: captionSize,
                onSelected: (i) {
                  _m = i;
                  _report();
                },
              ),
              colon(),
              _column(
                key: const ValueKey('timer-wheel-seconds'),
                controller: _seconds!,
                count: 60,
                caption: s.voiceTimerSeconds,
                width: col,
                extent: extent,
                fontSize: font,
                captionSize: captionSize,
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
  final _fieldKey = GlobalKey();

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
    final top = compact ? 52.0 : 64.0;
    final bottom = compact ? 20.0 : 28.0;
    final style = alarmButtonStyle(context);
    final named = !widget.isNew && widget.name.isNotEmpty;
    // The global key keeps what was typed and the focus when the field
    // moves between under the wheel and the button row.
    final field = KeyedSubtree(
      key: _fieldKey,
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
    );
    return LayoutBuilder(
      builder: (context, box) {
        // The wheel's room: all but the gap at the top, the buttons and the
        // name of a running timer.
        final room = Size(
          box.maxWidth,
          box.maxHeight -
              top -
              8 -
              bottom -
              (compact ? 52 : 60) -
              (named ? (compact ? 32 : 38) : 0),
        );
        // A new timer's name field goes under the wheel, unless it would
        // cost the wheel its five rows there (#1474). Then it goes next to
        // the buttons.
        final underWheel = Size(room.width, room.height - 72);
        final fieldBelow =
            widget.isNew &&
            DurationWheel.fitIn(underWheel, compact: compact).rows == 5;
        return Column(
          children: [
            SizedBox(height: top),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (named)
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
                        room: fieldBelow ? underWheel : room,
                        onChanged: (v) => setState(() => _seconds = v),
                      ),
                      if (fieldBelow)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: compact ? 300 : 440,
                            child: field,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, bottom),
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
                  if (widget.isNew && !fieldBelow) ...[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: field,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else
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
      },
    );
  }
}
