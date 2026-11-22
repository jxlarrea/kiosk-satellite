import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/voice_timers/voice_timer_manager.dart';
import 'compass/compass_center.dart';
import 'kit.dart';
import 'alarms_overlay.dart' show alarmButtonStyle;
import 'theme.dart';
import 'timer_editor.dart';
import 'toast.dart';

/// The timers as a full screen view: the one that ends first large at the
/// top, the others listed beside or under it, each with its time as hours,
/// minutes and seconds over a bar that runs down. It opens by itself when a
/// timer starts or finishes, from the kiosk menu, a gesture or Compass, and
/// sits under the screensaver like the alarm list. A timer near its end or
/// finished dismisses the screensaver and holds it. Timers another kiosk
/// shares show with that kiosk's name.
class TimersOverlay extends StatelessWidget {
  const TimersOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: container.voiceTimers.visible,
    builder: (context, visible, _) {
      if (!visible) return const SizedBox.shrink();
      return Positioned.fill(child: _TimersScreen(container: container));
    },
  );
}

class _TimersScreen extends StatefulWidget {
  const _TimersScreen({required this.container});

  final AppContainer container;

  @override
  State<_TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends State<_TimersScreen> {
  AppContainer get c => widget.container;
  Timer? _tick;
  late final Listenable _watched = Listenable.merge([
    c.voiceTimers.timers,
    c.voiceTimers.alerts,
    c.voiceTimers.alertHidden,
    c.voiceTimers.compassView,
  ]);

  @override
  void initState() {
    super.initState();
    _watched.addListener(_changed);
    c.voiceTimers.error.addListener(_error);
    _saver = c.bus.on<ScreensaverStateChanged>().listen((_) => _changed());
    _setting = c.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.timersViewScale.key) _changed();
    });
    _schedule();
  }

  StreamSubscription<ScreensaverStateChanged>? _saver;
  StreamSubscription<SettingChanged>? _setting;

  /// The wheels are up: for a new timer, or for [_editing]'s time left.
  bool _editor = false;
  String? _editing;

  void _newTimer() => setState(() {
    _editor = true;
    _editing = null;
  });

  void _edit(VoiceTimer timer) {
    if (!c.voiceTimers.canEdit(timer)) return;
    setState(() {
      _editor = true;
      _editing = timer.id;
    });
  }

  void _closeEditor() => setState(() {
    _editor = false;
    _editing = null;
  });

  Future<void> _set(int seconds, String name) async {
    final id = _editing;
    _closeEditor();
    if (id != null) {
      c.voiceTimers.setRemaining(id, seconds);
      return;
    }
    final error = await c.voiceTimers.start(seconds: seconds, name: name);
    if (error != null && mounted) {
      showToast(
        context,
        source: 'timers',
        title: l10n(context).voiceTimerStartFailed,
        kind: ToastKind.error,
      );
    }
  }

  void _delete() {
    final id = _editing;
    _closeEditor();
    if (id != null) c.voiceTimers.control(id, 'cancel');
  }

  @override
  void dispose() {
    _watched.removeListener(_changed);
    c.voiceTimers.error.removeListener(_error);
    _saver?.cancel();
    _setting?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _schedule();
  }

  void _error() => showToast(
    context,
    source: 'timers',
    title: l10n(context).voiceTimerActionError,
    kind: ToastKind.error,
  );

  /// Repaints on the instant the next second of a running timer falls, not
  /// on a beat of its own: two kiosks showing the same timer then change
  /// their digits together.
  void _schedule() {
    _tick?.cancel();
    _tick = null;
    final now = DateTime.now().millisecondsSinceEpoch;
    int? wait;
    for (final t in c.voiceTimers.timers.value) {
      if (!t.active) continue;
      final since = now - t.startedAt;
      if (since >= t.totalSeconds * 1000) continue;
      final next = since < 0 ? -since : 1000 - since % 1000;
      wait = wait == null ? next : min(wait, next);
    }
    if (wait == null) return;
    _tick = Timer(Duration(milliseconds: wait + 4), () {
      if (!mounted) return;
      setState(() {});
      _schedule();
    });
  }

  /// The ringing ones first, then the running ones by when they end, the
  /// paused ones last.
  List<VoiceTimer> _ordered(DateTime now) {
    final timers = c.voiceTimers;
    final alerts = timers.alertHidden.value
        ? const <VoiceTimer>[]
        : timers.alerts.value;
    final running = [
      for (final t in timers.timers.value)
        if (!timers.alerts.value.any((a) => a.id == t.id)) t,
    ]..sort((a, b) => a.endsAt(now).compareTo(b.endsAt(now)));
    return [...alerts, ...running];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = l10n(context);
    final now = DateTime.now();
    final all = _ordered(now);
    // The timer the wheels change, while it still runs. One that finished
    // or went meanwhile closes them.
    final edited = _editing == null
        ? null
        : all.where((t) => t.id == _editing && !t.finished).firstOrNull;
    final editor = _editor && (_editing == null || edited != null);
    final canStart = c.voiceTimers.canStart;
    final scale = (c.settings.get(defs.timersViewScale) / 100).clamp(.75, 2.0);
    return Listener(
      child: GestureDetector(
        // The ground only shields what is underneath.
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ksGroundGradient(
              theme.colorScheme.surface,
              theme.brightness,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  final compact = box.maxWidth < 600 || box.maxHeight < 480;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(top: compact ? 48 : 60),
                          child: all.isEmpty
                              ? _Empty(
                                  text: s.voiceTimersEmpty,
                                  onNew: canStart ? _newTimer : null,
                                )
                              : _Body(
                                  container: c,
                                  timers: all,
                                  now: now,
                                  scale: scale,
                                  size: Size(
                                    box.maxWidth,
                                    box.maxHeight - (compact ? 48 : 60),
                                  ),
                                  onEdit: _edit,
                                ),
                        ),
                      ),
                      // The wheels, over the list: it keeps counting under
                      // them and is there again on Cancel.
                      if (editor)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: ksGroundGradient(
                                theme.colorScheme.surface,
                                theme.brightness,
                              ),
                            ),
                            child: TimerEditorStep(
                              key: ValueKey('timer-editor-${_editing ?? ''}'),
                              compact: compact,
                              isNew: edited == null,
                              seconds: edited?.remaining(now) ?? 300,
                              name: edited == null
                                  ? ''
                                  : _nameOf(context, edited),
                              onCancel: _closeEditor,
                              onSet: _set,
                              onDelete: edited == null ? null : _delete,
                            ),
                          ),
                        ),
                      Positioned(
                        top: compact ? 12 : 20,
                        left: compact ? 16 : 28,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            KsEyebrow(
                              label: s.voiceTimersViewTitle,
                              trail: !editor
                                  ? null
                                  : edited == null
                                  ? s.voiceTimerSetATimer
                                  : s.voiceTimerEditTimer,
                              compact: compact,
                            ),
                            // Set a timer beside the name of the view, at
                            // the eyebrow's scale: the timers keep the
                            // whole screen and the top right corner stays
                            // the close button's. With no timer running the
                            // large button under No timers does this.
                            if (!editor && canStart && all.isNotEmpty) ...[
                              SizedBox(width: compact ? 12 : 16),
                              FilledButton.icon(
                                key: const ValueKey('timers-add'),
                                onPressed: _newTimer,
                                icon: Icon(Icons.add, size: compact ? 16 : 18),
                                label: Text(s.voiceTimerSetATimer),
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(0, compact ? 30 : 34),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.fromLTRB(
                                    compact ? 10 : 12,
                                    0,
                                    compact ? 14 : 16,
                                    0,
                                  ),
                                  textStyle: TextStyle(
                                    fontFamily: Ks.displayFont,
                                    fontSize: compact ? 13 : 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!editor)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // As on the alarm list: under Compass it
                              // goes back to the center, and the center
                              // itself has none.
                              CompassCenterHides(
                                container: c,
                                kind: 'timers',
                                child: IconButton(
                                  key: const ValueKey('timers-close'),
                                  icon: const Icon(Icons.close),
                                  tooltip: s.commonClose,
                                  iconSize: 28,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  onPressed: () => compassClose(
                                    c,
                                    'timers',
                                    () => c.voiceTimers.visible.value = false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, this.onNew});

  final String text;

  /// Opens the wheels for a new timer. Null where none can be started.
  final VoidCallback? onNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 44, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(fontSize: 18, color: scheme.onSurfaceVariant),
          ),
          if (onNew != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('timers-add'),
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: Text(l10n(context).voiceTimerSetATimer),
              style: alarmButtonStyle(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the list of the other timers goes.
enum _Layout {
  /// A row of cards under the first timer: a tablet.
  under,

  /// A column beside it: a wide, short panel such as an Echo Show 5.
  beside,

  /// A column under it: a phone.
  stacked,
}

class _Body extends StatelessWidget {
  const _Body({
    required this.container,
    required this.timers,
    required this.now,
    required this.scale,
    required this.size,
    required this.onEdit,
  });

  final AppContainer container;
  final List<VoiceTimer> timers;
  final DateTime now;

  /// Timers view scale as a factor, 1 at 100 percent.
  final double scale;
  final Size size;

  /// A tap on a timer's time: the wheels open on it.
  final ValueChanged<VoiceTimer> onEdit;

  @override
  Widget build(BuildContext context) {
    final layout = size.width < 600
        ? _Layout.stacked
        : size.height < 440
        ? _Layout.beside
        : _Layout.under;
    final first = timers.first;
    final rest = timers.sublist(1);
    final side = layout == _Layout.under
        ? (size.width * .044).clamp(24.0, 56.0)
        : layout == _Layout.beside
        ? 28.0
        : 20.0;
    final hero = _Hero(
      container: container,
      timer: first,
      now: now,
      layout: layout,
      alone: rest.isEmpty,
      scale: scale,
      onEdit: container.voiceTimers.canEdit(first) ? () => onEdit(first) : null,
    );
    if (rest.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(side, 0, side, 24),
        child: hero,
      );
    }
    final roomy = layout == _Layout.under;
    // The width a card needs at a scale of 1 to show its time in full.
    final need = _TimerCard.widthFor(roomy: roomy);
    Widget card(VoiceTimer t, double scale, {double? width}) => _TimerCard(
      key: ValueKey('timer-card-${t.id}'),
      container: container,
      timer: t,
      now: now,
      roomy: roomy,
      scale: scale,
      width: width,
      onEdit: container.voiceTimers.canEdit(t) ? () => onEdit(t) : null,
    );
    switch (layout) {
      case _Layout.under:
        const gap = 16.0;
        final inner = size.width - 2 * side;
        // The width of each card with [n] in full. With more timers than
        // that, the next one shows its edge.
        double widthOf(int n) => rest.length <= n
            ? (inner - (n - 1) * gap) / n
            : (inner - n * gap - 64) / n;
        // The row keeps to about a third of the height, so the first timer
        // keeps its room.
        final target = _grown(scale, size.height * .34 / _TimerCard.rowHeight);
        // Three in full. A larger scale shows fewer, as many as still
        // come close to it, so each card keeps room for its time.
        var full = 3;
        while (target > 1 &&
            full > 1 &&
            widthOf(full) / need < max(1.0, target * .85)) {
          full--;
        }
        final width = widthOf(full);
        final cardScale = _grown(target, width / need);
        return Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, 32),
          child: Column(
            children: [
              Expanded(child: hero),
              const SizedBox(height: 16),
              SizedBox(
                height: _TimerCard.rowHeight * cardScale,
                child: rest.length <= full
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final (i, t) in rest.indexed) ...[
                            if (i > 0) const SizedBox(width: gap),
                            card(t, cardScale, width: width),
                          ],
                        ],
                      )
                    : EdgeFade(
                        axis: Axis.horizontal,
                        child: ListView.separated(
                          key: const ValueKey('timers-list'),
                          scrollDirection: Axis.horizontal,
                          itemCount: rest.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: gap),
                          itemBuilder: (_, i) =>
                              card(rest[i], cardScale, width: width),
                        ),
                      ),
              ),
            ],
          ),
        );
      case _Layout.beside:
        // A larger scale widens the column, up to 45 percent of the width.
        final base = min(348.0, size.width * .4);
        final column = scale <= 1
            ? base
            : max(base, min(need * scale, size.width * .45));
        final cardScale = _grown(scale, column / need);
        return Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, 16),
          child: Row(
            children: [
              Expanded(child: hero),
              const SizedBox(width: 24),
              SizedBox(
                width: column,
                child: _CardColumn(
                  centered: true,
                  children: [for (final t in rest) card(t, cardScale)],
                ),
              ),
            ],
          ),
        );
      case _Layout.stacked:
        final cardScale = _grown(scale, (size.width - 2 * side) / need);
        return Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, 20),
          child: Column(
            children: [
              Expanded(child: hero),
              const SizedBox(height: 16),
              ConstrainedBox(
                // Three in full and the edge of a fourth, or what a short
                // phone can give.
                constraints: BoxConstraints(
                  maxHeight: min(372.0 * cardScale, size.height * .5),
                ),
                child: _CardColumn(
                  centered: false,
                  children: [for (final t in rest) card(t, cardScale)],
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// The scale a part of the view draws at: [scale] itself at 100 percent
/// and below, and above it no more than [room] allows. Never less than 1,
/// so a larger setting never draws a part smaller than the default.
double _grown(double scale, double room) =>
    scale <= 1 ? scale : room.clamp(1.0, scale);

/// The other timers one under another, scrolling under the edge fade once
/// they do not fit.
class _CardColumn extends StatelessWidget {
  const _CardColumn({required this.children, required this.centered});

  final List<Widget> children;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final list = EdgeFade(
      child: ListView.separated(
        key: const ValueKey('timers-list'),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => children[i],
      ),
    );
    return centered ? Center(child: list) : list;
  }
}

/// The three states a timer draws in.
enum _Tone { running, paused, finished }

_Tone _toneOf(VoiceTimer t) => t.finished
    ? _Tone.finished
    : t.active
    ? _Tone.running
    : _Tone.paused;

Color _toneColor(ColorScheme scheme, _Tone tone) => switch (tone) {
  _Tone.running => scheme.primary,
  _Tone.paused => scheme.tertiary,
  _Tone.finished => scheme.error,
};

String _nameOf(BuildContext context, VoiceTimer t) =>
    t.name.isEmpty ? l10n(context).voiceTimerDefaultName : t.name;

/// The bar under a time: full at the start, empty at the end.
class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color, required this.height});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: value.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: radius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill beside a name: the kiosk a shared timer comes from, or
/// that the time is up.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.large = false,
    this.scale = 1,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool large;
  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: (large ? 12 : 9) * scale,
      vertical: (large ? 4 : 2) * scale,
    ),
    decoration: ShapeDecoration(
      color: background,
      shape: const StadiumBorder(),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: (large ? 16 : 13) * scale, color: foreground),
        SizedBox(width: (large ? 7 : 5) * scale),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (large ? 15 : 12.5) * scale,
              color: foreground,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The name of a timer with what belongs beside it: the kiosk it comes
/// from, Paused, or Time's up.
class _NameLine extends StatelessWidget {
  const _NameLine({
    required this.timer,
    required this.fontSize,
    this.large = false,
    this.centered = false,
    this.scale = 1,
  });

  final VoiceTimer timer;
  final double fontSize;
  final bool large;
  final bool centered;

  /// The size of the chips and of Paused beside the name.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = l10n(context);
    final tone = _toneOf(timer);
    return LayoutBuilder(
      builder: (context, box) => _row(context, scheme, s, tone, box.maxWidth),
    );
  }

  /// How wide [text] draws at [size].
  double _textWidth(BuildContext context, String text, double size) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: size),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width + 1;
  }

  Widget _row(
    BuildContext context,
    ColorScheme scheme,
    UiStrings s,
    _Tone tone,
    double width,
  ) {
    final name = _nameOf(context, timer);
    final shared = timer.origin.isNotEmpty;
    final gap = (large ? 12 : 8) * scale;
    final small = (large ? 15 : 12.5) * scale;
    // A chip's padding, icon and the gap after the icon.
    final chipExtra = (large ? 12 * 2 + 16 + 7 : 9 * 2 + 13 + 5) * scale;
    final finished = tone == _Tone.finished;
    final status = switch (tone) {
      _Tone.finished => s.voiceTimerTimesUp,
      _Tone.paused => s.voiceTimerPaused,
      _Tone.running => null,
    };
    final originChip = _Chip(
      icon: Icons.home_outlined,
      label: timer.origin,
      background: scheme.primaryContainer,
      foreground: scheme.onPrimaryContainer,
      large: large,
      scale: scale,
    );
    final Widget? trail = status == null
        ? null
        : finished
        ? _Chip(
            icon: Icons.notifications_active_outlined,
            label: status,
            background: scheme.errorContainer,
            foreground: scheme.onErrorContainer,
            large: large,
            scale: scale,
          )
        : Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: small, color: scheme.tertiary),
          );
    final statusWidth = status == null
        ? 0.0
        : _textWidth(context, status, small) + (finished ? chipExtra : 0);
    Widget nameText(double maxWidth) => ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max(0, maxWidth)),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, color: scheme.onSurfaceVariant),
      ),
    );
    // The first timer's name keeps the whole width: what goes beside it
    // moves under it when the line is too long, as with a large scale.
    if (centered && width.isFinite && (shared || trail != null)) {
      final whole =
          _textWidth(context, name, fontSize) +
          (shared
              ? gap + _textWidth(context, timer.origin, small) + chipExtra
              : 0) +
          (trail != null ? gap + statusWidth : 0);
      if (whole > width) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            nameText(width),
            SizedBox(height: 6 * scale),
            // The kiosk's name shortens to leave Time's up or Paused in
            // full. Each goes on a line of its own should even that not fit.
            if (!shared ||
                trail == null ||
                statusWidth + gap + 56 * scale <= width)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (shared) Flexible(child: originChip),
                  if (shared && trail != null) SizedBox(width: gap),
                  if (trail != null) shared ? trail : Flexible(child: trail),
                ],
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: gap,
                runSpacing: 6 * scale,
                children: [originChip, trail],
              ),
          ],
        );
      }
    }
    // With a kiosk name beside it, the timer's name keeps half the line at
    // most and the kiosk's name gets what is left. Time's up and Paused
    // always show in full: a long name gives way, and so does the kiosk's
    // name down to its icon. Alone on its line, the name takes all of it.
    var nameWidth = width.isFinite
        ? width * (shared ? .5 : (trail != null ? .7 : 1))
        : 400.0;
    if (trail != null && width.isFinite) {
      nameWidth = min(
        nameWidth,
        width - gap - statusWidth - (shared ? gap + 56 * scale : 0),
      );
    }
    return Row(
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        nameText(nameWidth),
        if (shared) ...[SizedBox(width: gap), Flexible(child: originChip)],
        if (trail != null) ...[
          SizedBox(width: gap),
          // On a line too narrow even for it, it shortens too.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width.isFinite
                  ? max(0, width - gap - (shared ? gap + 56 * scale : 0))
                  : double.infinity,
            ),
            child: trail,
          ),
        ],
      ],
    );
  }
}

const _digits = [FontFeature.tabularFigures()];

/// The timer that ends first, or the one that rings.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.container,
    required this.timer,
    required this.now,
    required this.layout,
    required this.alone,
    required this.scale,
    this.onEdit,
  });

  final AppContainer container;
  final VoiceTimer timer;
  final DateTime now;
  final _Layout layout;
  final bool alone;

  /// Timers view scale: the name, the bar and the buttons.
  final double scale;

  /// A tap on the time opens the wheels. Null where it cannot be changed.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = l10n(context);
    final tone = _toneOf(timer);
    final color = _toneColor(scheme, tone);
    final timers = container.voiceTimers;
    final tablet = layout == _Layout.under;
    // On a phone the two buttons share the width, however narrow.
    final narrow = layout == _Layout.stacked;
    Widget fit(Widget button) => narrow ? Expanded(child: button) : button;
    return LayoutBuilder(
      builder: (context, box) {
        // The time takes what the name, the bar and the buttons leave,
        // and no more than its width allows.
        final nameBase = tablet ? (alone ? 32.0 : 28.0) : 21.0;
        final barBase = tablet ? 12.0 : 8.0;
        final buttonsBase = tablet ? 60.0 : 52.0;
        final gaps = tablet ? 84.0 : 56.0;
        // What the scale grows: the name's line, the bar and the buttons.
        final grows = nameBase * 1.3 + barBase + buttonsBase;
        // Above 100 percent they grow while the time keeps at least 30
        // percent of the height, and on a phone while the two buttons
        // still show their labels.
        final k = _grown(
          scale,
          min(
            (box.maxHeight * .7 - gaps) / grows,
            narrow ? box.maxWidth / 250 : double.infinity,
          ),
        );
        final nameSize = nameBase * k;
        final barHeight = barBase * k;
        final buttons = buttonsBase * k;
        final free = box.maxHeight - grows * k - gaps;
        final width = min(box.maxWidth, tablet ? 1080.0 : 640.0);
        // Eight glyphs of Rubik's tabular digits run about 4.6 em wide.
        final timeSize = max(40.0, min(free, width / 4.6));
        final buttonStyle = ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(narrow ? 0 : (tablet ? 148 : 124) * k, buttons),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: (narrow ? 12 : (tablet ? 32 : 24)) * k,
            ),
          ),
          iconSize: WidgetStatePropertyAll(18 * k),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: Ks.displayFont,
              fontSize: (tablet ? 18 : 16) * k,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        final finished = tone == _Tone.finished;
        // Should the parts still not fit, as with a long name on a short
        // screen, the whole timer shrinks rather than overflow.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NameLine(
                    timer: timer,
                    fontSize: nameSize,
                    large: tablet,
                    centered: true,
                    scale: k,
                  ),
                  SizedBox(height: tablet ? 10 : 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEdit,
                    child: Semantics(
                      button: onEdit != null,
                      hint: onEdit == null ? null : s.voiceTimerEditTimer,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          voiceTimerClock(timer.remaining(now)),
                          key: const ValueKey('timers-hero-time'),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: Ks.displayFont,
                            fontSize: timeSize,
                            height: 1,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -timeSize * .012,
                            fontFeatures: _digits,
                            color: tone == _Tone.running
                                ? scheme.onSurface
                                : color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tablet ? 26 : 18),
                  FractionallySizedBox(
                    widthFactor: tablet ? .86 : 1,
                    child: _Bar(
                      value: finished ? 0 : timer.progress(now),
                      color: color,
                      height: barHeight,
                    ),
                  ),
                  SizedBox(height: tablet ? 30 : 22),
                  _fitRow(
                    narrow,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: narrow
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: finished
                          ? [
                              fit(
                                FilledButton.icon(
                                  key: const ValueKey('timers-dismiss'),
                                  style: buttonStyle.copyWith(
                                    backgroundColor: WidgetStatePropertyAll(
                                      scheme.error,
                                    ),
                                    foregroundColor: WidgetStatePropertyAll(
                                      scheme.onError,
                                    ),
                                  ),
                                  onPressed: () =>
                                      timers.control(timer.id, 'dismiss'),
                                  icon: const Icon(Icons.check),
                                  label: Text(s.voiceTimerDismiss),
                                ),
                              ),
                            ]
                          : [
                              fit(
                                OutlinedButton.icon(
                                  key: const ValueKey('timers-hero-pause'),
                                  style: buttonStyle,
                                  onPressed: () => timers.control(
                                    timer.id,
                                    timer.active ? 'pause' : 'resume',
                                  ),
                                  icon: Icon(
                                    timer.active
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(
                                    timer.active
                                        ? s.voiceTimerPause
                                        : s.voiceTimerResume,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              SizedBox(width: 14 * k),
                              fit(
                                OutlinedButton.icon(
                                  key: const ValueKey('timers-hero-cancel'),
                                  style: buttonStyle,
                                  onPressed: () =>
                                      timers.control(timer.id, 'cancel'),
                                  icon: const Icon(Icons.close),
                                  label: Text(
                                    s.commonCancel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The hero's buttons: shared across the width on a phone, and otherwise
/// shrunk to fit should a large scale and long labels not.
Widget _fitRow(bool narrow, Widget row) =>
    narrow ? row : FittedBox(fit: BoxFit.scaleDown, child: row);

/// One of the other timers.
class _TimerCard extends StatelessWidget {
  const _TimerCard({
    super.key,
    required this.container,
    required this.timer,
    required this.now,
    required this.roomy,
    this.scale = 1,
    this.width,
    this.onEdit,
  });

  /// The width a card needs at a scale of 1 for its padding, its time in
  /// full and its two buttons.
  static double widthFor({required bool roomy}) => roomy ? 316 : 254;

  /// The height of the row of cards under a tablet's first timer at a
  /// scale of 1.
  static const rowHeight = 142.0;

  final AppContainer container;
  final VoiceTimer timer;
  final DateTime now;

  /// A tap on the name and time opens the wheels. Null where the timer
  /// cannot be changed.
  final VoidCallback? onEdit;

  /// The tablet's card: larger type and more air.
  final bool roomy;

  /// Timers view scale, as far as the room for the cards allows.
  final double scale;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = l10n(context);
    final tone = _toneOf(timer);
    final color = _toneColor(scheme, tone);
    final timers = container.voiceTimers;
    final name = _nameOf(context, timer);
    Widget action(IconData icon, String tooltip, String action) =>
        IconButton.filledTonal(
          icon: Icon(icon),
          tooltip: '$tooltip: $name',
          iconSize: 20 * scale,
          constraints: BoxConstraints.tightFor(
            width: 44 * scale,
            height: 44 * scale,
          ),
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurface,
          ),
          onPressed: () => timers.control(timer.id, action),
        );
    return Container(
      width: width,
      padding:
          (roomy
              ? const EdgeInsets.fromLTRB(24, 18, 18, 20)
              : const EdgeInsets.fromLTRB(16, 12, 12, 14)) *
          scale,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(roomy ? Ks.radiusCard : 18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEdit,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NameLine(
                        timer: timer,
                        fontSize: (roomy ? 17 : 14) * scale,
                        scale: scale,
                      ),
                      // A large text scale shrinks the time before it clips.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          voiceTimerClock(timer.remaining(now)),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: Ks.displayFont,
                            fontSize: (roomy ? 42 : 30) * scale,
                            height: 1.15,
                            fontWeight: FontWeight.w500,
                            fontFeatures: _digits,
                            color: tone == _Tone.running
                                ? scheme.onSurface
                                : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              if (tone == _Tone.finished)
                action(Icons.check, s.voiceTimerDismiss, 'dismiss')
              else ...[
                action(
                  timer.active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  timer.active ? s.voiceTimerPause : s.voiceTimerResume,
                  timer.active ? 'pause' : 'resume',
                ),
                SizedBox(width: 6 * scale),
                action(Icons.close, s.commonCancel, 'cancel'),
              ],
            ],
          ),
          SizedBox(height: (roomy ? 14 : 10) * scale),
          _Bar(
            value: tone == _Tone.finished ? 0 : timer.progress(now),
            color: color,
            height: (roomy ? 6 : 4) * scale,
          ),
        ],
      ),
    );
  }
}

/// Whether the timers show as pills (the setting) and so not as the full
/// screen view that opens by itself.
bool timerPillsOn(AppContainer c) => c.settings.get(defs.voiceTimerPills);

/// Rebuilds [builder] when the pills setting changes.
class TimerPillsSetting extends StatefulWidget {
  const TimerPillsSetting({
    super.key,
    required this.container,
    required this.builder,
  });

  final AppContainer container;
  final Widget Function(BuildContext context, bool pills) builder;

  @override
  State<TimerPillsSetting> createState() => _TimerPillsSettingState();
}

class _TimerPillsSettingState extends State<TimerPillsSetting> {
  StreamSubscription<SettingChanged>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.voiceTimerPills.key && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, timerPillsOn(widget.container));
}

/// Settings > Timers: the row that opens the timers view, where timers are
/// set, changed and cancelled. Under it, the timers that are running.
/// Mirrored on the remote admin by the list itself (timers.js).
class TimersManageCard extends StatelessWidget {
  const TimersManageCard({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<VoiceTimer>>(
        valueListenable: container.voiceTimers.timers,
        builder: (context, timers, _) {
          final s = l10n(context);
          return SettingsCard(
            children: [
              SettingsRow(
                leading: const Icon(Icons.timer_outlined),
                title: Text(s.timersManage),
                subtitle: Text(
                  timers.isEmpty
                      ? s.voiceTimersEmpty
                      : [
                          for (final t in timers) _nameOf(context, t),
                        ].join(', '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  unawaited(container.commands.execute('openTimers', const {}));
                },
              ),
            ],
          );
        },
      );
}
