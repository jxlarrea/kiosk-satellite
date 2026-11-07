import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../managers/alarms/alarm_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import 'alarms_overlay.dart' show alarmTimeParts, alarmTimeText;
import 'clock_setting.dart';
import 'theme.dart';

/// The alarm's own full screen view: the sunrise glow before a sunrise
/// alarm, then the ring with Snooze and Stop. Up whenever an alarm is
/// going and no screensaver took it over (Clock and Weather Mood draw the
/// ring in their own style instead, see [AlarmTakeoverControls]).
class AlarmRingOverlay extends StatelessWidget {
  const AlarmRingOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AlarmStatus>(
    valueListenable: container.alarms.status,
    builder: (context, status, _) {
      if (!status.ownView) return const SizedBox.shrink();
      return Positioned.fill(
        child: ClockSetting(
          container: container,
          setting: defs.alarmsClock24h,
          child: _OwnView(container: container, status: status),
        ),
      );
    },
  );
}

/// The label a ring shows: the alarms' labels, or Alarm.
String alarmLabel(BuildContext context, AlarmStatus status) {
  final labels = [
    for (final l in status.labels)
      if (l.isNotEmpty) l,
  ];
  return labels.isEmpty ? l10n(context).alarmsDefaultLabel : labels.join(' · ');
}

/// How much to scale Snooze and Stop on a [size] screen, 1 at 1024x600.
/// A small screen keeps them at full size, so they stay easy to hit half
/// awake, shrinking only when a row [rowWidth] wide at full size would
/// not fit across it. Zero leaves the width out, for buttons that are
/// stacked.
double alarmButtonScale(Size size, {double rowWidth = 0}) {
  final s = max(min(size.width / 1024, size.height / 600), 1.0);
  final fit = rowWidth > 0 ? (size.width - 64) / rowWidth : s;
  return min(s, fit).clamp(0.55, 1.8);
}

// The glow rises through these, bottom center outward. Four stops each,
// light to dark.
const _glowStops = [0.0, 0.35, 0.68, 1.0];
const _glowFrames = <(double, List<Color>)>[
  (
    0.0,
    [
      Color(0xFF4A160C),
      Color(0xFF2C110B),
      Color(0xFF1C0C09),
      Color(0xFF0A0707),
    ],
  ),
  (
    0.45,
    [
      Color(0xFFE06A2C),
      Color(0xFF8A3320),
      Color(0xFF2A1512),
      Color(0xFF140B0A),
    ],
  ),
  (
    0.8,
    [
      Color(0xFFFFCF7A),
      Color(0xFFF28B45),
      Color(0xFFB64D35),
      Color(0xFF4B2530),
    ],
  ),
  (
    1.0,
    [
      Color(0xFFFFF3D6),
      Color(0xFFFFD58C),
      Color(0xFFF7A25A),
      Color(0xFFD9744A),
    ],
  ),
];

/// The sunrise glow at progress [t], 0 at the start of the window and 1
/// at the ring.
Gradient sunriseGlow(double t) {
  t = t.clamp(0.0, 1.0);
  var i = 0;
  while (i < _glowFrames.length - 2 && t > _glowFrames[i + 1].$1) {
    i++;
  }
  final (a, from) = _glowFrames[i];
  final (b, to) = _glowFrames[i + 1];
  final f = b == a ? 1.0 : ((t - a) / (b - a)).clamp(0.0, 1.0);
  return RadialGradient(
    center: const Alignment(0, 1.25),
    radius: 0.9 + 0.8 * t,
    colors: [for (var k = 0; k < 4; k++) Color.lerp(from[k], to[k], f)!],
    stops: _glowStops,
  );
}

class _OwnView extends StatefulWidget {
  const _OwnView({required this.container, required this.status});

  final AppContainer container;
  final AlarmStatus status;

  @override
  State<_OwnView> createState() => _OwnViewState();
}

class _OwnViewState extends State<_OwnView> {
  late Timer _tick;
  DateTime _now = DateTime.now();

  /// A touch during the sunrise shows Stop for a while; the touch itself
  /// never ends it.
  bool _stopShown = false;
  Timer? _hideStop;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    _hideStop?.cancel();
    super.dispose();
  }

  void _revealStop() {
    _hideStop?.cancel();
    setState(() => _stopShown = true);
    _hideStop = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _stopShown = false);
    });
  }

  bool get _sunriseAlarm => widget.status.ids.any(
    (id) => widget.container.alarms.alarms.value.any(
      (a) => a.id == id && a.sunrise,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final size = MediaQuery.sizeOf(context);
    final s = (min(size.width / 1024, size.height / 600)).clamp(0.55, 1.8);
    final portrait = size.height > size.width;
    final sunrise = status.phase == AlarmPhase.sunrise;
    final theme = Theme.of(context);
    double progress = 1;
    if (sunrise && status.sunriseStart != null && status.at != null) {
      final span = status.at!.difference(status.sunriseStart!).inSeconds;
      final done = _now.difference(status.sunriseStart!).inSeconds;
      progress = span <= 0 ? 1 : done / span;
    }
    final glowing = sunrise || _sunriseAlarm;
    final Decoration background = glowing
        ? BoxDecoration(gradient: sunriseGlow(sunrise ? progress : 1))
        : BoxDecoration(
            gradient: ksGroundGradient(
              theme.colorScheme.surface,
              theme.brightness,
            ),
          );
    final (digits, suffix) = alarmTimeParts(context, _now.hour, _now.minute);
    final lit = !sunrise || progress > 0.75;
    final Color fg = !glowing
        ? theme.colorScheme.onSurface
        : sunrise
        ? Color.lerp(
            const Color(0x8CFFDCC8),
            const Color(0xF2FFFAF0),
            progress.clamp(0.0, 1.0),
          )!
        : const Color(0xFF3A1D10);
    final Color soft = !glowing
        ? theme.colorScheme.onSurfaceVariant
        : sunrise
        ? fg.withValues(alpha: fg.a * 0.85)
        : const Color(0xB83A1D10);
    final clock = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          digits,
          style: TextStyle(
            fontSize: (portrait ? 104 : 180) * s,
            fontWeight: FontWeight.w300,
            height: 1,
            color: fg,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (suffix.isNotEmpty) ...[
          SizedBox(width: 10 * s),
          Text(
            suffix,
            style: TextStyle(fontSize: (portrait ? 28 : 44) * s, color: fg),
          ),
        ],
      ],
    );
    final Widget content;
    if (sunrise) {
      final b = alarmButtonScale(size, rowWidth: 200);
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          clock,
          SizedBox(height: 12 * s),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alarm, size: 26 * s, color: soft),
              SizedBox(width: 8 * s),
              Text(
                l10n(context).alarmsAt(alarmTimeText(context, status.at!)),
                style: TextStyle(fontSize: 22 * s, color: soft),
              ),
            ],
          ),
          SizedBox(height: 36 * s),
          AnimatedOpacity(
            opacity: _stopShown ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_stopShown,
              child: _Pill(
                label: l10n(context).alarmsStop,
                icon: Icons.alarm_off,
                width: 200 * b,
                height: 60 * b,
                fontSize: 20 * b,
                background: lit
                    ? const Color(0x33FFFFFF)
                    : const Color(0x22FFFFFF),
                foreground: fg,
                onTap: () => widget.container.alarms.stop(source: 'sunrise'),
              ),
            ),
          ),
        ],
      );
    } else {
      final snoozeBg = glowing
          ? const Color(0x73FFFFFF)
          : theme.colorScheme.surfaceContainerHighest;
      final snoozeFg = glowing
          ? const Color(0xFF3A1D10)
          : theme.colorScheme.onSurface;
      final stopBg = glowing
          ? const Color(0xFF3A1D10)
          : theme.colorScheme.primary;
      final stopFg = glowing
          ? const Color(0xFFFFF4E6)
          : theme.colorScheme.onPrimary;
      final label = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alarm, size: 28 * s, color: soft),
          SizedBox(width: 10 * s),
          Flexible(
            child: Text(
              alarmLabel(context, status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 24 * s, color: soft),
            ),
          ),
        ],
      );
      final b = alarmButtonScale(size, rowWidth: portrait ? 0 : 508);
      Widget pill(
        String text,
        IconData icon,
        Color bg,
        Color fgc,
        VoidCallback tap,
      ) => _Pill(
        label: text,
        icon: icon,
        width: portrait ? double.infinity : 240 * b,
        height: (portrait ? 68 : 76) * b,
        fontSize: (portrait ? 21 : 24) * b,
        background: bg,
        foreground: fgc,
        onTap: tap,
      );
      final snoozeBtn = pill(
        l10n(context).alarmsSnooze,
        Icons.snooze,
        snoozeBg,
        snoozeFg,
        () => widget.container.alarms.snooze(source: 'button'),
      );
      final stopBtn = pill(
        l10n(context).alarmsStop,
        Icons.alarm_off,
        stopBg,
        stopFg,
        () => widget.container.alarms.stop(source: 'button'),
      );
      content = portrait
          ? Padding(
              padding: EdgeInsets.fromLTRB(28, 0, 28, 40 * s),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  label,
                  SizedBox(height: 8 * s),
                  clock,
                  const Spacer(flex: 3),
                  stopBtn,
                  SizedBox(height: 14 * s),
                  snoozeBtn,
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                label,
                SizedBox(height: 10 * s),
                clock,
                SizedBox(height: 44 * s),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    snoozeBtn,
                    SizedBox(width: 28 * b),
                    stopBtn,
                  ],
                ),
              ],
            );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: sunrise ? _revealStop : null,
      child: DecoratedBox(
        decoration: background,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: portrait && !sunrise ? content : Center(child: content),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.edge,
    this.shadows = const [],
  });

  final String label;
  final IconData icon;
  final double width, height, fontSize;
  final Color background, foreground;
  final Color? edge;
  final List<Shadow> shadows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Material(
      color: background,
      shape: StadiumBorder(
        side: edge == null ? BorderSide.none : BorderSide(color: edge!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: fontSize * 1.15,
              color: foreground,
              shadows: shadows,
            ),
            SizedBox(width: fontSize * 0.5),
            Text(
              label,
              style: TextStyle(
                fontFamily: Ks.displayFont,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: foreground,
                shadows: shadows,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A ringing alarm drawn in a screensaver's own dress, under its clock:
/// the label on the date line, then Snooze in the screensaver's glass and
/// Stop filled with its text color. The Clock and Weather Mood screensavers
/// put this in place of their date while the alarm takes them over.
class AlarmTakeoverControls extends StatelessWidget {
  const AlarmTakeoverControls({
    super.key,
    required this.container,
    required this.color,
    required this.ink,
    required this.glass,
    required this.edge,
    required this.labelSize,
    this.labelColor,
    this.labelWeight = FontWeight.w400,
    this.fontFamily,
    this.shadows = const [],
  });

  final AppContainer container;

  /// The screensaver's text color: the label, Snooze's text and Stop's
  /// fill.
  final Color color;

  /// Stop's text, the screensaver's background.
  final Color ink;
  final Color glass, edge;
  final double labelSize;
  final Color? labelColor;
  final FontWeight labelWeight;
  final String? fontFamily;
  final List<Shadow> shadows;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final s = (min(size.width / 1024, size.height / 600)).clamp(0.55, 1.8);
    final b = alarmButtonScale(size, rowWidth: 484);
    final label = labelColor ?? color.withValues(alpha: .7);
    return ValueListenableBuilder<AlarmStatus>(
      valueListenable: container.alarms.status,
      builder: (context, status, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.alarm,
                size: labelSize * 1.1,
                color: label,
                shadows: shadows,
              ),
              SizedBox(width: labelSize * 0.35),
              Flexible(
                child: Text(
                  alarmLabel(context, status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: labelSize,
                    fontWeight: labelWeight,
                    color: label,
                    shadows: shadows,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 40 * s),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pill(
                label: l10n(context).alarmsSnooze,
                icon: Icons.snooze,
                width: 230 * b,
                height: 68 * b,
                fontSize: 23 * b,
                background: glass,
                foreground: color,
                edge: edge,
                shadows: shadows,
                onTap: () => container.alarms.snooze(source: 'screensaver'),
              ),
              SizedBox(width: 24 * b),
              _Pill(
                label: l10n(context).alarmsStop,
                icon: Icons.alarm_off,
                width: 230 * b,
                height: 68 * b,
                fontSize: 23 * b,
                background: color,
                foreground: ink,
                onTap: () => container.alarms.stop(source: 'screensaver'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
