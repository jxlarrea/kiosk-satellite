import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/voice_timers/voice_timer_manager.dart';
import 'kit.dart';
import 'theme.dart';
import 'toast.dart';

/// The timers as a full screen view: the one that ends first large at the
/// top, the others listed beside or under it, each with its time as hours,
/// minutes and seconds over a bar that runs down. It opens by itself when a
/// timer starts or finishes, from the kiosk menu, a gesture or Compass, and
/// sits over the screensaver the way the timer pills do. Timers another
/// kiosk shares show with that kiosk's name.
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
    _schedule();
  }

  StreamSubscription<ScreensaverStateChanged>? _saver;

  @override
  void dispose() {
    _watched.removeListener(_changed);
    c.voiceTimers.error.removeListener(_error);
    _saver?.cancel();
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
    // With nothing on it, as Compass holds it between timers, the view
    // leaves the screen to the screensaver.
    if (all.isEmpty && c.screensaver.isActive) return const SizedBox.shrink();
    return Listener(
      // Over the screensaver: a touch here is a touch on a control, not a
      // tap that dismisses it.
      onPointerDown: (_) => c.screensaver.markControlTouch(),
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
                              ? _Empty(text: s.voiceTimersEmpty)
                              : _Body(
                                  container: c,
                                  timers: all,
                                  now: now,
                                  size: Size(
                                    box.maxWidth,
                                    box.maxHeight - (compact ? 48 : 60),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        top: compact ? 12 : 20,
                        left: compact ? 16 : 28,
                        child: KsEyebrow(
                          label: s.voiceTimersViewTitle,
                          compact: compact,
                        ),
                      ),
                      // Compass moves between its views by swipes: the one
                      // in hand has no close of its own.
                      if (!c.voiceTimers.compassView.value)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            key: const ValueKey('timers-close'),
                            icon: const Icon(Icons.close),
                            tooltip: s.commonClose,
                            iconSize: 28,
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: () =>
                                c.voiceTimers.visible.value = false,
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
  const _Empty({required this.text});

  final String text;

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
    required this.size,
  });

  final AppContainer container;
  final List<VoiceTimer> timers;
  final DateTime now;
  final Size size;

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
    );
    if (rest.isEmpty) {
      return Padding(
        padding: EdgeInsets.fromLTRB(side, 0, side, 24),
        child: hero,
      );
    }
    Widget card(VoiceTimer t, {double? width}) => _TimerCard(
      key: ValueKey('timer-card-${t.id}'),
      container: container,
      timer: t,
      now: now,
      roomy: layout == _Layout.under,
      width: width,
    );
    switch (layout) {
      case _Layout.under:
        const gap = 16.0;
        final inner = size.width - 2 * side;
        // Three in full. With more, the fourth shows its edge.
        final width = rest.length <= 3
            ? (inner - 2 * gap) / 3
            : (inner - 3 * gap - 64) / 3;
        return Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, 32),
          child: Column(
            children: [
              Expanded(child: hero),
              const SizedBox(height: 16),
              SizedBox(
                height: 142,
                child: rest.length <= 3
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final (i, t) in rest.indexed) ...[
                            if (i > 0) const SizedBox(width: gap),
                            card(t, width: width),
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
                          itemBuilder: (_, i) => card(rest[i], width: width),
                        ),
                      ),
              ),
            ],
          ),
        );
      case _Layout.beside:
        return Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, 16),
          child: Row(
            children: [
              Expanded(child: hero),
              const SizedBox(width: 24),
              SizedBox(
                width: min(348.0, size.width * .4),
                child: _CardColumn(
                  centered: true,
                  children: [for (final t in rest) card(t)],
                ),
              ),
            ],
          ),
        );
      case _Layout.stacked:
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
                  maxHeight: min(372.0, size.height * .5),
                ),
                child: _CardColumn(
                  centered: false,
                  children: [for (final t in rest) card(t)],
                ),
              ),
            ],
          ),
        );
    }
  }
}

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
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 12 : 9,
      vertical: large ? 4 : 2,
    ),
    decoration: ShapeDecoration(
      color: background,
      shape: const StadiumBorder(),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: large ? 16 : 13, color: foreground),
        SizedBox(width: large ? 7 : 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: large ? 15 : 12.5, color: foreground),
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
  });

  final VoiceTimer timer;
  final double fontSize;
  final bool large;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = l10n(context);
    final tone = _toneOf(timer);
    return LayoutBuilder(
      builder: (context, box) => _row(context, scheme, s, tone, box.maxWidth),
    );
  }

  Widget _row(
    BuildContext context,
    ColorScheme scheme,
    UiStrings s,
    _Tone tone,
    double width,
  ) {
    // With a kiosk name beside it, the timer's name keeps half the line at
    // most and the kiosk's name gets what is left.
    final shared = timer.origin.isNotEmpty;
    return Row(
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width.isFinite ? width * (shared ? .5 : .7) : 400,
          ),
          child: Text(
            _nameOf(context, timer),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (timer.origin.isNotEmpty) ...[
          SizedBox(width: large ? 12 : 8),
          Flexible(
            child: _Chip(
              icon: Icons.home_outlined,
              label: timer.origin,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
              large: large,
            ),
          ),
        ],
        if (tone == _Tone.finished) ...[
          SizedBox(width: large ? 12 : 8),
          _Chip(
            icon: Icons.notifications_active_outlined,
            label: s.voiceTimerTimesUp,
            background: scheme.errorContainer,
            foreground: scheme.onErrorContainer,
            large: large,
          ),
        ] else if (tone == _Tone.paused) ...[
          SizedBox(width: large ? 12 : 8),
          Text(
            s.voiceTimerPaused,
            style: TextStyle(
              fontSize: large ? 15 : 12.5,
              color: scheme.tertiary,
            ),
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
  });

  final AppContainer container;
  final VoiceTimer timer;
  final DateTime now;
  final _Layout layout;
  final bool alone;

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
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(narrow ? 0 : (tablet ? 132 : 112), tablet ? 52 : 46),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: narrow ? 12 : (tablet ? 28 : 22)),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: Ks.displayFont,
          fontSize: tablet ? 16 : 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        // The time takes what the name, the bar and the buttons leave,
        // and no more than its width allows.
        final nameSize = tablet ? (alone ? 32.0 : 28.0) : 21.0;
        final barHeight = tablet ? 12.0 : 8.0;
        final buttons = tablet ? 52.0 : 46.0;
        final gaps = tablet ? 84.0 : 56.0;
        final free =
            box.maxHeight - nameSize * 1.3 - barHeight - buttons - gaps;
        final width = min(box.maxWidth, tablet ? 1080.0 : 640.0);
        // Eight glyphs of Rubik's tabular digits run about 4.6 em wide.
        final timeSize = max(40.0, min(free, width / 4.6));
        final finished = tone == _Tone.finished;
        return Center(
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
                ),
                SizedBox(height: tablet ? 10 : 6),
                FittedBox(
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
                      color: tone == _Tone.running ? scheme.onSurface : color,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                          const SizedBox(width: 14),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One of the other timers.
class _TimerCard extends StatelessWidget {
  const _TimerCard({
    super.key,
    required this.container,
    required this.timer,
    required this.now,
    required this.roomy,
    this.width,
  });

  final AppContainer container;
  final VoiceTimer timer;
  final DateTime now;

  /// The tablet's card: larger type and more air.
  final bool roomy;
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
          iconSize: 20,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          style: IconButton.styleFrom(
            backgroundColor: scheme.surfaceContainerHighest,
            foregroundColor: scheme.onSurface,
          ),
          onPressed: () => timers.control(timer.id, action),
        );
    return Container(
      width: width,
      padding: roomy
          ? const EdgeInsets.fromLTRB(24, 18, 18, 20)
          : const EdgeInsets.fromLTRB(16, 12, 12, 14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NameLine(timer: timer, fontSize: roomy ? 17 : 14),
                    // A large text scale shrinks the time before it clips.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        voiceTimerClock(timer.remaining(now)),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: Ks.displayFont,
                          fontSize: roomy ? 42 : 30,
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
              const SizedBox(width: 8),
              if (tone == _Tone.finished)
                action(Icons.check, s.voiceTimerDismiss, 'dismiss')
              else ...[
                action(
                  timer.active ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  timer.active ? s.voiceTimerPause : s.voiceTimerResume,
                  timer.active ? 'pause' : 'resume',
                ),
                const SizedBox(width: 6),
                action(Icons.close, s.commonCancel, 'cancel'),
              ],
            ],
          ),
          SizedBox(height: roomy ? 14 : 10),
          _Bar(
            value: tone == _Tone.finished ? 0 : timer.progress(now),
            color: color,
            height: roomy ? 6 : 4,
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
