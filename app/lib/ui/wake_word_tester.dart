import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_container.dart';
import '../managers/wake_word/engine.dart';

/// One inference's telemetry, as the engine reports it.
class _Sample {
  _Sample(Map<String, Object?> m)
    : score = (m['score'] as num?)?.toDouble() ?? 0,
      threshold = (m['threshold'] as num?)?.toDouble() ?? 0.5,
      fired = m['fired'] == true,
      nearMiss = m['nearMiss'] == true,
      rms = (m['rms'] as num?)?.toDouble() ?? 0,
      editDistance = (m['editDistance'] as num?)?.toInt(),
      matchedConfidence = (m['matchedConfidence'] as num?)?.toDouble(),
      decoded = (m['decoded'] as String?) ?? '',
      latencyUs = (m['latencyUs'] as num?)?.toInt() ?? 0;

  final double score;
  final double threshold;
  final bool fired;
  final bool nearMiss;
  final double rms;
  final int? editDistance;
  final double? matchedConfidence;
  final String decoded;
  final int latencyUs;
}

/// Bumped for every telemetry sample; the chart's CustomPaint repaints from
/// this alone, so the heavy Widget tree (stats, log) is not rebuilt at the
/// inference rate.
class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

/// Settings row that opens the wake-word tester.
class WakeWordTesterTile extends StatelessWidget {
  const WakeWordTesterTile({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insights_outlined),
      title: const Text('Open tester'),
      subtitle: const Text(
        'Watch what the engine hears and scores in real time, to see why '
        'the wake word is or is not triggering.',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _WakeWordTesterDialog(container: container),
      ),
    );
  }
}

class _WakeWordTesterDialog extends StatefulWidget {
  const _WakeWordTesterDialog({required this.container});

  final AppContainer container;

  @override
  State<_WakeWordTesterDialog> createState() => _WakeWordTesterDialogState();
}

class _WakeWordTesterDialogState extends State<_WakeWordTesterDialog> {
  static const _capacity = 150;
  static const _logCapacity = 200;

  final List<_Sample> _samples = [];
  final List<(String, bool)> _log = []; // (line, isHit)
  final _repaint = _Repaint();
  final _logScroll = ScrollController();
  final _logScrollH = ScrollController();
  StreamSubscription<Map<String, Object?>>? _sub;
  Timer? _frameTimer;

  int _hits = 0;
  int _nearMisses = 0;
  String _wakeWord = '';
  String _engine = '';
  bool _dirty = false;
  bool _newSamples = false;
  int _frame = 0;
  String _lastLogged = '';
  int _lastNearMs = 0;
  // Tail the log only while the user is parked at the bottom; the moment
  // they scroll up to read history, stop yanking them back down.
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    _engine = widget.container.wakeWord.config?.engine.label ?? '';
    widget.container.wakeWord.startTest();
    _sub = widget.container.wakeWord.telemetry.listen(_onSample);
    _logScroll.addListener(() {
      if (!_logScroll.hasClients) return;
      final p = _logScroll.position;
      _follow = p.maxScrollExtent - p.pixels < 24;
    });
    // Repaint and refresh on a fixed cadence, decoupled from the inference
    // rate: telemetry can arrive tens of times a second, but the chart is
    // repainted at most ~30 fps (and only when there is new data), and the
    // heavier stats/log rebuild only a few times a second.
    _frameTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!mounted) return;
      if (_newSamples) {
        _newSamples = false;
        _repaint.tick(); // repaints only the chart (RepaintBoundary)
      }
      if (_dirty && (++_frame % 9 == 0)) {
        setState(() => _dirty = false);
        if (_follow) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_logScroll.hasClients) {
              _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
            }
          });
        }
      }
    });
  }

  void _onSample(Map<String, Object?> m) {
    final s = _Sample(m);
    _wakeWord = '${m['wakeWord'] ?? m['id'] ?? ''}';
    _samples.add(s);
    if (_samples.length > _capacity) _samples.removeAt(0);
    _newSamples = true;

    final t = DateTime.now().toIso8601String().substring(11, 19);
    if (s.fired) {
      _hits++;
      _addLog(
        '$t  HIT  score ${s.score.toStringAsFixed(3)}'
        '${s.decoded.isNotEmpty ? '  [${s.decoded}]' : ''}'
        '${s.editDistance != null && s.editDistance! >= 0 ? '  ed ${s.editDistance}' : ''}',
        true,
      );
    } else {
      // Near miss. For vsWakeWord this is the payoff: what phonemes the
      // model decoded, so a miss reads as "heard X, wanted Y". Deduped and
      // rate-limited so the log is readable, not a firehose.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final notable = s.nearMiss ||
          s.decoded.isNotEmpty ||
          (s.threshold > 0 && s.score >= s.threshold * 0.75);
      if (notable &&
          (s.decoded != _lastLogged || nowMs - _lastNearMs > 500)) {
        _nearMisses++;
        _lastLogged = s.decoded;
        _lastNearMs = nowMs;
        _addLog(
          '$t  near  score ${s.score.toStringAsFixed(3)}'
          '${s.decoded.isNotEmpty ? '  decoded=[${s.decoded}]' : ''}'
          '${s.editDistance != null && s.editDistance! >= 0 ? '  ed ${s.editDistance}' : ''}'
          '${s.matchedConfidence != null ? '  conf ${s.matchedConfidence!.toStringAsFixed(2)}' : ''}',
          false,
        );
      }
    }
    _dirty = true;
    // No repaint here: the frame timer coalesces repaints to ~30 fps.
  }

  void _addLog(String line, bool hit) {
    _log.add((line, hit));
    if (_log.length > _logCapacity) _log.removeAt(0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _frameTimer?.cancel();
    widget.container.wakeWord.stopTest();
    _repaint.dispose();
    _logScroll.dispose();
    _logScrollH.dispose();
    super.dispose();
  }

  ({int min, int avg, int max}) _latency() {
    final us = <int>[];
    for (final s in _samples) {
      if (s.latencyUs > 0) us.add(s.latencyUs);
    }
    if (us.isEmpty) return (min: 0, avg: 0, max: 0);
    var mn = us.first, mx = us.first, sum = 0;
    for (final v in us) {
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      sum += v;
    }
    return (min: mn ~/ 1000, avg: (sum ~/ us.length) ~/ 1000, max: mx ~/ 1000);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lat = _latency();
    final last = _samples.isNotEmpty ? _samples.last : null;
    final peak = _samples.fold<double>(
      0,
      (p, s) => math.max(p, s.score),
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text('Wake Word Tester', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _wakeWord.isEmpty
                    ? 'Say the wake word. The line is the threshold the score '
                          'must cross to trigger.'
                    : 'Listening for "$_wakeWord"'
                          '${_engine.isEmpty ? '' : ' ($_engine)'}. '
                          'The line is the threshold the score must cross to '
                          'trigger.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              // Chart — repaints from [_repaint], not the widget rebuild.
              SizedBox(
                height: 230,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _ScorePainter(
                        samples: _samples,
                        repaint: _repaint,
                        primary: theme.colorScheme.primary,
                        threshold: theme.colorScheme.error,
                        grid: theme.colorScheme.outlineVariant,
                        label: theme.colorScheme.onSurfaceVariant,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _legend(theme, theme.colorScheme.primary, 'Score'),
                  const SizedBox(width: 14),
                  _legend(theme, theme.colorScheme.error, 'Threshold'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 22,
                runSpacing: 10,
                children: [
                  _stat(theme, 'Hits', '$_hits'),
                  _stat(theme, 'Near misses', '$_nearMisses'),
                  _stat(
                    theme,
                    'Score',
                    last == null ? '-' : last.score.toStringAsFixed(3),
                  ),
                  _stat(theme, 'Peak', peak.toStringAsFixed(3)),
                  _stat(
                    theme,
                    'Mic level',
                    last == null ? '-' : last.rms.toStringAsFixed(3),
                  ),
                  _stat(
                    theme,
                    'Latency (min / avg / max)',
                    '${lat.min} / ${lat.avg} / ${lat.max} ms',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // The telemetry log: hits and near misses, with the decoded
              // phonemes for vsWakeWord.
              Row(
                children: [
                  Text(
                    'Log',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _log.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: _log.map((e) => e.$1).join('\n'),
                              ),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Log copied'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    icon: const Icon(Icons.copy_outlined, size: 16),
                    label: const Text('Copy'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LayoutBuilder(
                    builder: (context, cons) {
                    final logW = cons.maxWidth;
                    return _log.isEmpty
                      ? Text(
                          'Detections and near misses will appear here.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      // No wrap: long lines (a full decoded phoneme run)
                      // scroll horizontally instead of folding. Both bars
                      // shown; each scrollbar reacts only to its own axis so
                      // the nested views do not fight.
                      : Scrollbar(
                          controller: _logScroll,
                          thumbVisibility: true,
                          notificationPredicate: (n) =>
                              n.metrics.axis == Axis.vertical,
                          child: SingleChildScrollView(
                            controller: _logScroll,
                            child: Scrollbar(
                              controller: _logScrollH,
                              thumbVisibility: true,
                              notificationPredicate: (n) =>
                                  n.metrics.axis == Axis.horizontal,
                              child: SingleChildScrollView(
                                controller: _logScrollH,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(bottom: 12),
                                // Fill the pane's width so short logs still
                                // occupy the whole field and the horizontal
                                // bar only appears when a line truly overruns,
                                // otherwise the bars jitter as text lands.
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: logW),
                                  child: SelectableText.rich(
                                  TextSpan(
                                    children: [
                                      for (final (i, entry)
                                          in _log.indexed)
                                        TextSpan(
                                          text: entry.$1 +
                                              (i == _log.length - 1
                                                  ? ''
                                                  : '\n'),
                                          style: entry.$2
                                              ? TextStyle(
                                                  color: theme
                                                      .colorScheme.primary,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                )
                                              : null,
                                        ),
                                    ],
                                  ),
                                  maxLines: null,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                                ),
                              ),
                            ),
                          ),
                        );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(ThemeData theme, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 3, color: color),
      const SizedBox(width: 5),
      Text(label, style: theme.textTheme.labelSmall),
    ],
  );

  Widget _stat(ThemeData theme, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      Text(value, style: theme.textTheme.titleSmall),
    ],
  );
}

class _ScorePainter extends CustomPainter {
  _ScorePainter({
    required this.samples,
    required Listenable repaint,
    required this.primary,
    required this.threshold,
    required this.grid,
    required this.label,
  }) : super(repaint: repaint);

  final List<_Sample> samples;
  final Color primary;
  final Color threshold;
  final Color grid;
  final Color label;

  static const _leftPad = 44.0;
  static const _vPad = 16.0; // top/bottom room for the edge tick labels

  // Cached tick-label layouts, rebuilt only when the axis range changes —
  // laying out text on every 30 fps frame is what makes this feel slow.
  double? _cLo, _cSpan;
  List<TextPainter>? _cLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final plotLeft = _leftPad;
    final plotW = size.width - _leftPad - 8;
    final plotTop = _vPad;
    final plotBottom = size.height - _vPad;
    final plotH = plotBottom - plotTop;

    // Y range: 0 (or the data floor) up to headroom above the highest of the
    // score, its peak and the threshold. vsWakeWord confidence is not bounded
    // to 1, so the axis fits the data rather than assuming [0,1].
    var lo = 0.0, hi = 1.0;
    final th = samples.isNotEmpty ? samples.last.threshold : 0.5;
    hi = math.max(hi, th);
    for (final s in samples) {
      hi = math.max(hi, s.score);
      lo = math.min(lo, s.score);
    }
    final span = (hi - lo) == 0 ? 1.0 : (hi - lo) * 1.1;
    double y(double v) => plotBottom - ((v - lo) / span) * plotH;
    double x(int i) => samples.length <= 1
        ? plotLeft + plotW
        : plotLeft + i / (samples.length - 1) * plotW;

    // (Re)build the tick labels only when the range actually moved.
    if (_cLabels == null || _cLo != lo || _cSpan != span) {
      _cLo = lo;
      _cSpan = span;
      _cLabels = [
        for (var t = 0; t <= 4; t++)
          TextPainter(
            text: TextSpan(
              text: (lo + span * t / 4).toStringAsFixed(hi <= 1.2 ? 2 : 1),
              style: TextStyle(color: label, fontSize: 10),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];
    }
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var t = 0; t <= 4; t++) {
      final yy = y(lo + span * t / 4);
      canvas.drawLine(
          Offset(plotLeft, yy), Offset(plotLeft + plotW, yy), gridPaint);
      final tp = _cLabels![t];
      tp.paint(canvas, Offset(plotLeft - tp.width - 6, yy - tp.height / 2));
    }

    if (samples.isEmpty) return;

    // Threshold line.
    canvas.drawLine(
      Offset(plotLeft, y(th)),
      Offset(plotLeft + plotW, y(th)),
      Paint()
        ..color = threshold
        ..strokeWidth = 1.5,
    );

    // Score line.
    final scorePath = Path()..moveTo(x(0), y(samples.first.score));
    for (var i = 1; i < samples.length; i++) {
      scorePath.lineTo(x(i), y(samples[i].score));
    }
    canvas.drawPath(
      scorePath,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Hit markers.
    final hitPaint = Paint()..color = primary;
    for (var i = 0; i < samples.length; i++) {
      if (samples[i].fired) {
        canvas.drawCircle(Offset(x(i), y(samples[i].score)), 4, hitPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ScorePainter old) => false;
}
