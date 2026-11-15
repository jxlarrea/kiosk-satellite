import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../l10n/messages.dart';
import '../managers/audio/adaptive_volume_curve.dart';
import '../managers/settings/definitions.dart';
import 'kit.dart';
import 'theme.dart';
import 'toast.dart';

/// Under the chart. Shared wording with the remote admin, which carries
/// its own copy (volume_curve.js).
const _curveHint =
    'Drag a point, or tap it to type exact values. The percentages apply '
    'to the Assistant, Media and Intercom volume sliders under Screen & '
    "Audio: 100% plays at the slider's level and 50% plays like the slider "
    'set to half.';

/// The settings the editor is drawn from: the curve and which volumes
/// follow it.
final _editorKeys = {
  adaptiveVolumeCurve.key,
  adaptiveVolumeAssistant.key,
  adaptiveVolumeMedia.key,
  adaptiveVolumeIntercom.key,
  intercomEnabled.key,
};

/// A volume's name, as its switch on the page calls it.
String volumeChannelName(BuildContext context, VolumeChannel channel) =>
    screenAudioText(context, switch (channel) {
      VolumeChannel.assistant => 'Assistant',
      VolumeChannel.media => 'Media',
      VolumeChannel.intercom => 'Intercom',
    });

/// The adaptive volume curve as one editor (issue #1450), built like the
/// brightness curve's: a chart of volume over the room's noise, four
/// points, the room's level marked on it, and a chip per point that opens
/// a dialog for exact values. A point holds one noise level and a volume
/// for each of the volumes that follow the room, so the chart draws a
/// line per volume through the same four noise levels. Dragging a ring
/// moves its point along the noise scale and that one volume up or down.
/// Mirrored on the remote (volume_curve.js).
class VolumeCurveEditor extends StatefulWidget {
  const VolumeCurveEditor({super.key, required this.container});

  final AppContainer container;

  @override
  State<VolumeCurveEditor> createState() => _VolumeCurveEditorState();
}

typedef _Grip = ({int index, VolumeChannel channel});

class _VolumeCurveEditorState extends State<VolumeCurveEditor>
    with TickerProviderStateMixin {
  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<AdaptiveVolumeChanged>? _noiseSub;

  /// The curve as the setting holds it, and the one on screen, which
  /// eases toward it when something else writes it (the remote admin).
  late List<VolumePoint> _target;
  late List<VolumePoint> _from;
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..addListener(() => setState(() {}));

  /// The room's level, eased the same way.
  double? _noise;
  double? _noiseFrom;
  late final AnimationController _noiseMove = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(() => setState(() {}));

  /// A drag in progress: the ring, the curve being shaped, the chart's
  /// range frozen so the axis does not slide under the finger, and how
  /// far the finger has gone (a press that never moves is a tap).
  _Grip? _active;
  List<VolumePoint>? _drag;
  _Domain? _dragDomain;
  double _travel = 0;

  /// Where the finger landed relative to the ring's center, kept through
  /// the drag so the ring does not jump under it.
  Offset _grab = Offset.zero;

  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _target = _fromSettings();
    _from = _target;
    _morph.value = 1;
    _noise = widget.container.adaptiveVolume.noise;
    _noiseMove.value = 1;
    _settingsSub = widget.container.bus.on<SettingChanged>().listen((e) {
      if (!_editorKeys.contains(e.key) || !mounted) return;
      if (e.key != adaptiveVolumeCurve.key) {
        // A volume started or stopped following the room: its line comes
        // or goes.
        setState(() {});
        return;
      }
      if (!_committing) _retarget();
    });
    _noiseSub = widget.container.bus.on<AdaptiveVolumeChanged>().listen((e) {
      if (!mounted || e.noise == _noise) return;
      _noiseFrom = _shownNoise;
      _noise = e.noise;
      _noiseMove.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _noiseSub?.cancel();
    _morph.dispose();
    _noiseMove.dispose();
    super.dispose();
  }

  List<VolumePoint> _fromSettings() => AdaptiveVolumeCurve.parse(
    widget.container.settings.get(adaptiveVolumeCurve),
  ).points;

  /// The volumes that follow the room: only they have a line, a ring on
  /// each point and a field in the dialog.
  List<VolumeChannel> get _channels {
    final s = widget.container.settings;
    return [
      if (s.get(adaptiveVolumeAssistant)) VolumeChannel.assistant,
      if (s.get(adaptiveVolumeMedia)) VolumeChannel.media,
      if (s.get(adaptiveVolumeIntercom) && s.get(intercomEnabled))
        VolumeChannel.intercom,
    ];
  }

  void _retarget({bool animate = true}) {
    final next = _fromSettings();
    setState(() {
      _from = animate ? _shown : next;
      _target = next;
    });
    if (animate) {
      _morph.forward(from: 0);
    } else {
      _morph.value = 1;
    }
  }

  /// The curve on screen: the drag's while one is going, else the eased
  /// one.
  List<VolumePoint> get _shown {
    final drag = _drag;
    if (drag != null) return drag;
    final t = Curves.easeOutCubic.transform(_morph.value);
    if (t >= 1) return _target;
    return [
      for (var i = 0; i < _target.length; i++)
        VolumePoint(
          _lerp(_from[i].noise, _target[i].noise, t),
          _lerp(_from[i].assistant, _target[i].assistant, t),
          _lerp(_from[i].media, _target[i].media, t),
          _lerp(_from[i].intercom, _target[i].intercom, t),
        ),
    ];
  }

  double? get _shownNoise {
    final to = _noise;
    final from = _noiseFrom;
    if (to == null || from == null || _noiseMove.value >= 1) return to;
    return _lerp(from, to, Curves.easeOutCubic.transform(_noiseMove.value));
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  // ── Dragging ─────────────────────────────────────────────────────────

  void _dragStart(Offset local, _Geometry g) {
    final points = _shown;
    final grip = g.hit(points, _channels, local);
    if (grip == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _active = grip;
      _drag = List.of(points);
      _dragDomain = g.domain;
      _travel = 0;
      _grab = g.at(points[grip.index], grip.channel) - local;
    });
  }

  void _dragUpdate(Offset local, Offset delta, _Geometry g) {
    final grip = _active;
    final drag = _drag;
    if (grip == null || drag == null) return;
    _travel += delta.distance;
    if (_travel < kTouchSlop) return;
    final at = local + _grab;
    final want = drag[grip.index]
        .withNoise(g.noiseAt(at.dx).roundToDouble())
        .withLevel(grip.channel, (g.levelAt(at.dy) * 100).round() / 100);
    final curve = AdaptiveVolumeCurve(drag);
    final moved = curve.clamp(grip.index, want);
    if (moved == drag[grip.index]) return;
    // A fresh list, so the painter sees the change.
    setState(() => _drag = curve.withPoint(grip.index, moved).points);
  }

  Future<void> _dragEnd() async {
    final grip = _active;
    final drag = _drag;
    if (grip == null || drag == null) return;
    final tapped = _travel < kTouchSlop;
    if (tapped) {
      setState(() {
        _active = null;
        _drag = null;
        _dragDomain = null;
      });
      await _editPoint(grip.index);
      return;
    }
    await _commit(drag);
    if (!mounted) return;
    setState(() {
      _active = null;
      _drag = null;
      _dragDomain = null;
    });
  }

  /// Write a whole curve. Returns why it was refused, or null.
  Future<String?> _commit(List<VolumePoint> points) async {
    final value = AdaptiveVolumeCurve(points).encode();
    final settings = widget.container.settings;
    final message = settings.validate(adaptiveVolumeCurve, value);
    if (message != null) {
      _retarget(animate: false);
      return message;
    }
    _committing = true;
    try {
      if (settings.get(adaptiveVolumeCurve) != value) {
        await settings.set(adaptiveVolumeCurve, value);
      }
    } finally {
      _committing = false;
    }
    if (mounted) _retarget(animate: false);
    return null;
  }

  // ── Typed values ─────────────────────────────────────────────────────

  Future<void> _editPoint(int index) async {
    final curve = AdaptiveVolumeCurve(List.of(_target));
    final saved = await showDialog<VolumePoint>(
      context: context,
      builder: (context) => _PointDialog(
        index: index,
        point: curve.points[index],
        bounds: curve.bounds(index),
        channels: _channels,
      ),
    );
    if (saved == null || !mounted) return;
    final refused = await _commit(curve.withPoint(index, saved).points);
    if (refused != null && mounted) {
      showToast(
        context,
        title: screenAudioText(context, 'Volume curve'),
        message: refused,
        kind: ToastKind.error,
      );
    }
  }

  // ── Layout ───────────────────────────────────────────────────────────

  String _noiseText(double noise) =>
      l10n(context).screenAudioDbfs('${noise.round()}');

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final noise = _shownNoise;
    final channels = _channels;
    final domain = _dragDomain ?? _Domain.around(_target);
    final tight = tightPane(context);
    final theme = Theme.of(context);
    Widget chip(int i) => _PointChip(
      noise: _noiseText(shown[i].noise),
      levels: [
        for (final channel in channels)
          '${(shown[i].level(channel) * 100).round()}%',
      ].join(' · '),
      active: _active?.index == i,
      onTap: () => _editPoint(i),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ks.inset, 14, Ks.inset, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (channels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 18,
                runSpacing: 6,
                children: [
                  for (final channel in channels)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        CustomPaint(
                          size: const Size(26, 10),
                          painter: _SamplePainter(
                            channel,
                            theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          volumeChannelName(context, channel),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final g = _Geometry(
                Size(constraints.maxWidth, tight ? 210 : 250),
                domain,
              );
              return RawGestureDetector(
                gestures: {
                  _RingDragRecognizer:
                      GestureRecognizerFactoryWithHandlers<_RingDragRecognizer>(
                        () => _RingDragRecognizer(
                          hit: (at) => g.hit(_shown, _channels, at) != null,
                        ),
                        (r) => r
                          ..hit = ((at) => g.hit(_shown, _channels, at) != null)
                          ..dragStartBehavior = DragStartBehavior.down
                          ..onStart = ((d) => _dragStart(d.localPosition, g))
                          ..onUpdate = ((d) {
                            _dragUpdate(d.localPosition, d.delta, g);
                          })
                          ..onEnd = ((_) => _dragEnd())
                          ..onCancel = (() => _dragEnd()),
                      ),
                },
                child: CustomPaint(
                  size: g.size,
                  painter: _CurvePainter(
                    points: shown,
                    channels: channels,
                    geometry: g,
                    noise: noise,
                    active: _active,
                    theme: theme,
                    noiseLabel: noise == null ? null : _noiseText(noise),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Four across on a roomy pane. On a tight one two rows of two, so
          // three volumes still fit a line under their noise level.
          if (tight)
            Column(
              spacing: 8,
              children: [
                for (var first = 0; first < shown.length; first += 2)
                  Row(
                    spacing: 8,
                    children: [
                      for (
                        var i = first;
                        i < first + 2 && i < shown.length;
                        i++
                      )
                        Expanded(child: chip(i)),
                    ],
                  ),
              ],
            )
          else
            Row(
              spacing: 8,
              children: [
                for (var i = 0; i < shown.length; i++) Expanded(child: chip(i)),
              ],
            ),
          const SizedBox(height: 4),
          HintRow(screenAudioText(context, _curveHint), inset: false),
        ],
      ),
    );
  }
}

/// One point's exact values: its noise level and a volume for each of the
/// volumes that follow the room, each checked against the neighbors before
/// the dialog closes.
class _PointDialog extends StatefulWidget {
  const _PointDialog({
    required this.index,
    required this.point,
    required this.bounds,
    required this.channels,
  });

  final int index;
  final VolumePoint point;
  final VolumePointBounds bounds;
  final List<VolumeChannel> channels;

  @override
  State<_PointDialog> createState() => _PointDialogState();
}

class _PointDialogState extends State<_PointDialog> {
  late final _noise = TextEditingController(
    text: '${widget.point.noise.round()}',
  );
  late final _levels = {
    for (final channel in widget.channels)
      channel: TextEditingController(
        text: '${(widget.point.level(channel) * 100).round()}',
      ),
  };
  String? _noiseError;
  final _levelErrors = <VolumeChannel, String>{};

  @override
  void dispose() {
    _noise.dispose();
    for (final controller in _levels.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final b = widget.bounds;
    final strings = l10n(context);
    final noise = num.tryParse(_noise.text.trim().replaceAll(',', '.'));
    final noiseOk =
        noise != null && noise >= b.noiseLo - 1e-9 && noise <= b.noiseHi + 1e-9;
    final errors = <VolumeChannel, String>{};
    var point = widget.point;
    if (noiseOk) point = point.withNoise(noise.roundToDouble());
    for (final channel in widget.channels) {
      final level = num.tryParse(_levels[channel]!.text.trim());
      final lo = b.levelLo[channel]!;
      final hi = b.levelHi[channel]!;
      if (level == null || level / 100 < lo - 1e-9 || level / 100 > hi + 1e-9) {
        errors[channel] = strings.screenAudioVolumeCurveLevelRange(
          '${(lo * 100).round()}',
          '${(hi * 100).round()}',
        );
      } else {
        point = point.withLevel(channel, level.round() / 100);
      }
    }
    setState(() {
      _noiseError = noiseOk
          ? null
          : strings.screenAudioVolumeCurveNoiseRange(
              '${b.noiseLo.round()}',
              '${b.noiseHi.round()}',
            );
      _levelErrors
        ..clear()
        ..addAll(errors);
    });
    if (!noiseOk || errors.isNotEmpty) return;
    Navigator.pop(context, point);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(l10n(context).screenAudioCurvePoint('${widget.index + 1}')),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            TextField(
              controller: _noise,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              onChanged: (_) {
                if (_noiseError != null) setState(() => _noiseError = null);
              },
              decoration: InputDecoration(
                labelText: screenAudioText(context, 'Room noise (dBFS)'),
                errorText: _noiseError,
                errorMaxLines: 2,
              ),
            ),
            if (widget.channels.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  for (final channel in widget.channels)
                    Expanded(
                      child: TextField(
                        controller: _levels[channel],
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          if (_levelErrors.containsKey(channel)) {
                            setState(() => _levelErrors.remove(channel));
                          }
                        },
                        onSubmitted: (_) => _save(),
                        decoration: InputDecoration(
                          labelText: screenAudioText(context, switch (channel) {
                            VolumeChannel.assistant => 'Assistant (%)',
                            VolumeChannel.media => 'Media (%)',
                            VolumeChannel.intercom => 'Intercom (%)',
                          }),
                          errorText: _levelErrors[channel],
                          errorMaxLines: 4,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n(context).commonCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(deviceText(context, 'Save')),
        ),
      ],
    );
  }
}

/// The chart's noise range: whole tens of dB around the curve's ends, with
/// room past them to drag. The room's level has no say: one outside the
/// range sits on the chart's edge.
class _Domain {
  const _Domain(this.lo, this.hi);

  factory _Domain.around(List<VolumePoint> p) {
    final lo = ((p.first.noise - 5) / 10).floor() * 10.0;
    final hi = ((p.last.noise + 5) / 10).ceil() * 10.0;
    return _Domain(
      math.max(lo, AdaptiveVolumeCurve.minNoise - 4),
      math.min(hi, AdaptiveVolumeCurve.maxNoise),
    );
  }

  final double lo;
  final double hi;
}

/// Chart coordinates: the plot area inside the axis labels, noise across,
/// volume up.
class _Geometry {
  _Geometry(this.size, this.domain);

  final Size size;
  final _Domain domain;

  static const left = 40.0;
  static const right = 10.0;
  static const top = 14.0;
  static const bottom = 26.0;

  /// How close a press has to land to take a ring.
  static const reach = 30.0;

  Rect get plot =>
      Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

  double x(double noise) =>
      plot.left +
      (noise.clamp(domain.lo, domain.hi) - domain.lo) /
          (domain.hi - domain.lo) *
          plot.width;

  double y(double level) => plot.bottom - level.clamp(0.0, 1.0) * plot.height;

  Offset at(VolumePoint p, VolumeChannel channel) =>
      Offset(x(p.noise), y(p.level(channel)));

  double noiseAt(double dx) {
    final t = ((dx - plot.left) / plot.width).clamp(0.0, 1.0);
    return domain.lo + t * (domain.hi - domain.lo);
  }

  double levelAt(double dy) =>
      ((plot.bottom - dy) / plot.height).clamp(0.0, 1.0);

  /// The ring nearest to [at], if one is within [reach].
  _Grip? hit(
    List<VolumePoint> points,
    List<VolumeChannel> channels,
    Offset at,
  ) {
    _Grip? best;
    var bestDistance = reach;
    for (var i = 0; i < points.length; i++) {
      for (final channel in channels) {
        final d = (this.at(points[i], channel) - at).distance;
        if (d <= bestDistance) {
          best = (index: i, channel: channel);
          bestDistance = d;
        }
      }
    }
    return best;
  }
}

/// A pan that claims the pointer at once when it lands on a ring, so the
/// page does not scroll under a drag, and never enters the arena when it
/// lands anywhere else, so the page still scrolls from the chart.
class _RingDragRecognizer extends PanGestureRecognizer {
  _RingDragRecognizer({required this.hit});

  bool Function(Offset local) hit;

  @override
  bool isPointerAllowed(PointerEvent event) =>
      hit(event.localPosition) && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// How a volume's line is drawn: the three share one color and differ in
/// their stroke, so they stay apart for someone who does not see hue.
Path _styled(Path line, VolumeChannel channel) {
  final (on, off) = switch (channel) {
    VolumeChannel.assistant => (0.0, 0.0),
    VolumeChannel.media => (9.0, 6.0),
    VolumeChannel.intercom => (0.1, 6.0),
  };
  if (on == 0) return line;
  final out = Path();
  for (final metric in line.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += on + off) {
      out.addPath(
        metric.extractPath(d, math.min(d + on, metric.length)),
        Offset.zero,
      );
    }
  }
  return out;
}

Paint _linePaint(Color color) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2.5
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// A short piece of a volume's line, for the key above the chart.
class _SamplePainter extends CustomPainter {
  _SamplePainter(this.channel, this.color);

  final VolumeChannel channel;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Path()
      ..moveTo(1.5, size.height / 2)
      ..lineTo(size.width - 1.5, size.height / 2);
    canvas.drawPath(_styled(line, channel), _linePaint(color));
  }

  @override
  bool shouldRepaint(_SamplePainter old) =>
      old.channel != channel || old.color != color;
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.points,
    required this.channels,
    required this.geometry,
    required this.noise,
    required this.active,
    required this.theme,
    required this.noiseLabel,
  });

  final List<VolumePoint> points;
  final List<VolumeChannel> channels;
  final _Geometry geometry;
  final double? noise;
  final _Grip? active;
  final ThemeData theme;
  final String? noiseLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final scheme = theme.colorScheme;
    final g = geometry;
    final plot = g.plot;
    final curve = AdaptiveVolumeCurve(points);
    final labelStyle = theme.textTheme.labelSmall!.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 11,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final grid = Paint()
      ..color = scheme.outlineVariant.withValues(alpha: 0.7)
      ..strokeWidth = 1;

    // Volume gridlines every quarter, labeled at 0, 50 and 100.
    for (var q = 0; q <= 4; q++) {
      final y = g.y(q / 4);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      if (q.isEven) {
        _text(
          canvas,
          '${q * 25}%',
          labelStyle,
          Offset(plot.left - 8, y),
          align: _Align.right,
        );
      }
    }
    // A line every 10 dB of noise, labeled under the axis.
    final first = (g.domain.lo / 10).ceil();
    final last = (g.domain.hi / 10).floor();
    for (var t = first; t <= last; t++) {
      final x = g.x(t * 10.0);
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      _text(
        canvas,
        '${t * 10}',
        labelStyle,
        Offset(x, plot.bottom + 6),
        align: x - plot.left < 12
            ? _Align.left
            : plot.right - x < 12
            ? _Align.rightEdge
            : _Align.center,
      );
    }

    // A line per volume, flat before the first point and after the last.
    // The first one carries the fill.
    for (final channel in channels) {
      final path = Path()..moveTo(plot.left, g.y(points.first.level(channel)));
      for (final p in points) {
        path.lineTo(g.x(p.noise), g.y(p.level(channel)));
      }
      path.lineTo(plot.right, g.y(points.last.level(channel)));
      if (channel == channels.first) {
        final area = Path.from(path)
          ..lineTo(plot.right, plot.bottom)
          ..lineTo(plot.left, plot.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.primary.withValues(alpha: 0.22),
                scheme.primary.withValues(alpha: 0.02),
              ],
            ).createShader(plot),
        );
      }
      canvas.drawPath(_styled(path, channel), _linePaint(scheme.primary));
    }

    // The room right now: a dashed line at its level, a dot where it meets
    // each volume's line and the level above.
    final now = noise;
    if (now != null) {
      final x = g.x(now);
      final dash = Paint()
        ..color = scheme.tertiary.withValues(alpha: 0.8)
        ..strokeWidth = 1.5;
      for (var d = plot.top; d < plot.bottom; d += 7) {
        canvas.drawLine(
          Offset(x, d),
          Offset(x, math.min(d + 3.5, plot.bottom)),
          dash,
        );
      }
      for (final channel in channels) {
        final at = Offset(x, g.y(curve.levelAt(channel, now)));
        canvas.drawCircle(
          at,
          9,
          Paint()..color = scheme.tertiary.withValues(alpha: 0.22),
        );
        canvas.drawCircle(at, 5, Paint()..color = scheme.tertiary);
      }
      final label = noiseLabel;
      if (label != null) _pill(canvas, label, x, plot, scheme);
    }

    // The rings: open, the one under the finger filled and haloed.
    for (var i = 0; i < points.length; i++) {
      for (final channel in channels) {
        final c = g.at(points[i], channel);
        final grip = active;
        if (grip != null && grip.index == i && grip.channel == channel) {
          canvas.drawCircle(
            c,
            20,
            Paint()..color = scheme.primary.withValues(alpha: 0.16),
          );
          canvas.drawCircle(c, 9, Paint()..color = scheme.primary);
          canvas.drawCircle(
            c,
            9,
            Paint()
              ..color = scheme.surface
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        } else {
          canvas.drawCircle(c, 7, Paint()..color = scheme.surface);
          canvas.drawCircle(
            c,
            7,
            Paint()
              ..color = scheme.primary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        }
      }
    }
  }

  void _pill(Canvas canvas, String text, double x, Rect plot, ColorScheme s) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: theme.textTheme.labelSmall!.copyWith(
          color: s.onTertiaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 11,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = painter.width + 14;
    const h = 20.0;
    final left = (x - w / 2).clamp(plot.left, plot.right - w);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, plot.top - 4, w, h),
      const Radius.circular(h / 2),
    );
    canvas.drawRRect(rect, Paint()..color = s.tertiaryContainer);
    painter.paint(
      canvas,
      Offset(left + 7, plot.top - 4 + (h - painter.height) / 2),
    );
  }

  void _text(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset at, {
    _Align align = _Align.center,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (align) {
      _Align.left => at.dx,
      _Align.center => at.dx - painter.width / 2,
      _Align.right => at.dx - painter.width,
      _Align.rightEdge => at.dx - painter.width,
    };
    // A label left of the plot sits centered on its line; one under the
    // axis hangs from it.
    final dy = align == _Align.right ? at.dy - painter.height / 2 : at.dy;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points ||
      !_sameChannels(old.channels, channels) ||
      old.noise != noise ||
      old.active != active ||
      old.theme != theme ||
      old.noiseLabel != noiseLabel ||
      old.geometry.size != geometry.size ||
      old.geometry.domain.lo != geometry.domain.lo ||
      old.geometry.domain.hi != geometry.domain.hi;

  static bool _sameChannels(List<VolumeChannel> a, List<VolumeChannel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum _Align { left, center, right, rightEdge }

/// One point's values under the chart: its noise level over its volumes,
/// in the control box surface. Tapping opens the dialog.
class _PointChip extends StatelessWidget {
  const _PointChip({
    required this.noise,
    required this.levels,
    required this.active,
    required this.onTap,
  });

  final String noise;
  final String levels;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(Ks.radiusControl);
    const figures = [FontFeature.tabularFigures()];
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            border: Border.all(
              color: active ? scheme.primary : scheme.outlineVariant,
            ),
            borderRadius: radius,
          ),
          child: Column(
            children: [
              Text(
                noise,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: figures,
                ),
              ),
              if (levels.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  levels,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: figures,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
