import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_container.dart';

/// RMS (0..1) to a meter fraction on a dB scale, -60 dBFS to -6 dBFS.
///
/// The decibel mapping is what makes the meter useful for gain tuning:
/// speech on a healthy capture lands mid-scale, and the ~0.05 RMS the
/// microphone gain hint asks users to aim for sits exactly at the top of
/// the green segments.
double micLevelFraction(double rms) {
  if (rms <= 0) return 0;
  final db = 20 * math.log(rms) / math.ln10;
  return ((db + 60) / 54).clamp(0.0, 1.0);
}

/// Segment count and color boundaries, shared wording with the remote UI:
/// green to the 0.05-RMS target, amber to -12 dBFS, red above.
const micMeterSegments = 24;
const _greenUpTo = 15; // fraction 0.625 ~= -26 dBFS ~= 0.05 RMS
const _amberUpTo = 20; // fraction 0.833 ~= -15 dBFS

/// Live microphone level row for the Microphone settings card. Rides the
/// wake-word tester's telemetry feed (reference counted, so it coexists
/// with an open tester), which also means it only moves while the engine
/// is listening - exactly when the gain above it matters.
class MicLevelTile extends StatefulWidget {
  const MicLevelTile({super.key, required this.container});

  final AppContainer container;

  @override
  State<MicLevelTile> createState() => _MicLevelTileState();
}

class _MicLevelTileState extends State<MicLevelTile> {
  StreamSubscription<Map<String, Object?>>? _sub;
  Timer? _staleness;
  final _level = ValueNotifier<double>(0);
  int _lastSampleMs = 0;

  @override
  void initState() {
    super.initState();
    widget.container.wakeWord.startTest();
    _sub = widget.container.wakeWord.telemetry.listen((m) {
      _lastSampleMs = DateTime.now().millisecondsSinceEpoch;
      _level.value = micLevelFraction((m['rms'] as num?)?.toDouble() ?? 0);
    });
    // Telemetry stops when detection pauses (a voice turn) or the engine
    // drops; decay to dark instead of freezing on the last value.
    _staleness = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_level.value > 0 &&
          DateTime.now().millisecondsSinceEpoch - _lastSampleMs > 500) {
        _level.value = 0;
      }
    });
  }

  @override
  void dispose() {
    _staleness?.cancel();
    _sub?.cancel();
    widget.container.wakeWord.stopTest();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          leading: Icon(Icons.graphic_eq),
          title: Text('Microphone level'),
          subtitle: Text(
            'Speak from where you use the device; adjust the gain until '
            'normal speech tops out around the end of the green.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 14,
            child: ValueListenableBuilder<double>(
              valueListenable: _level,
              builder: (_, level, _) => CustomPaint(
                painter: _SegmentBarPainter(
                  level: level,
                  offColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentBarPainter extends CustomPainter {
  _SegmentBarPainter({required this.level, required this.offColor});

  final double level;
  final Color offColor;

  static const _green = Color(0xFF56814F);
  static const _amber = Color(0xFFC29435);
  static const _red = Color(0xFFB3542C);

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 3.0;
    final segW =
        (size.width - gap * (micMeterSegments - 1)) / micMeterSegments;
    final lit = (level * micMeterSegments).round();
    final paint = Paint();
    for (var i = 0; i < micMeterSegments; i++) {
      paint.color = i >= lit
          ? offColor
          : i < _greenUpTo
              ? _green
              : i < _amberUpTo
                  ? _amber
                  : _red;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * (segW + gap), 0, segW, size.height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentBarPainter old) =>
      old.level != level || old.offColor != offColor;
}
