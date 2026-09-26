import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../managers/wake_word/engine.dart';
import 'kit.dart';
import 'toast.dart';
import 'wake_audio_player.dart';

/// One inference's telemetry, as the engine reports it.
class _Sample {
  _Sample(Map<String, Object?> m)
    : t = (m['t'] as num?)?.toDouble() ?? 0,
      score = (m['score'] as num?)?.toDouble() ?? 0,
      threshold = (m['threshold'] as num?)?.toDouble() ?? 0.5,
      fired = m['fired'] == true,
      nearMiss = m['nearMiss'] == true,
      rms = (m['rms'] as num?)?.toDouble() ?? 0,
      editDistance = (m['editDistance'] as num?)?.toInt(),
      matchedConfidence = (m['matchedConfidence'] as num?)?.toDouble(),
      decoded = (m['decoded'] as String?) ?? '',
      latencyUs =
          ((m['chunkLatencyUs'] ?? m['latencyUs']) as num?)?.toInt() ?? 0;

  /// Position on the engine's mic timeline, in ms.
  final double t;
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

/// Settings row that opens the wake-word tester.
class WakeWordTesterTile extends StatelessWidget {
  const WakeWordTesterTile({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.insights_outlined),
      title: Text(voiceText(context, 'Open tester')),
      subtitle: Text(
        voiceText(
          context,
          'Watch what the engine hears and scores in real time, to see why the wake word is or is not triggering.',
        ),
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

class _WakeWordTesterDialogState extends State<_WakeWordTesterDialog>
    with SingleTickerProviderStateMixin {
  static const _logCapacity = 200;
  static const _logLineHeight = 17.0;

  final _chart = _ChartModel();
  final _log = <(String, _Sample)>[]; // Timestamp and original telemetry.
  // Each part of the dialog rebuilds on its own clock: the chart per frame
  // (a repaint, no widgets), the stats a few times a second, the log when a
  // line lands. Nothing rebuilds the whole dialog at the inference rate.
  final _frame = ValueNotifier<int>(0);
  final _statsTick = ValueNotifier<int>(0);
  final _logTick = ValueNotifier<int>(0);
  final _logScroll = ScrollController();
  final _logScrollH = ScrollController();
  late final WakeAudioPlayer _player;
  late final Ticker _ticker;
  StreamSubscription<Map<String, Object?>>? _sub;
  Timer? _statsTimer;

  int _hits = 0;
  int _nearMisses = 0;
  _Sample? _last;
  String _engine = '';
  // Every wake word (and the stop word) loaded for this session, so the
  // tester can watch one at a time instead of a blur of all their scores.
  List<({String id, String label, bool stop})> _words = const [];
  String? _selectedId;
  bool _statsDirty = false;
  String _lastLogged = '';
  int _lastNearMs = 0;
  // Tail the log only while the user is parked at the bottom; the moment
  // they scroll up to read history, stop yanking them back down.
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    final cfg = widget.container.wakeWord.config;
    _engine = cfg?.engine.label ?? '';
    if (cfg != null) {
      final stop = cfg.stopModel;
      _words = [
        for (final m in cfg.models) (id: m.id, label: m.wakeWord, stop: false),
        if (stop != null) (id: stop.id, label: stop.wakeWord, stop: true),
      ];
      if (_words.isNotEmpty) _selectedId = _words.first.id;
    }
    _player = WakeAudioPlayer(widget.container);
    _ticker = createTicker(_onTick);
    widget.container.wakeWord.startTest();
    _sub = widget.container.wakeWord.telemetry.listen(_onSample);
    _logScroll.addListener(() {
      if (!_logScroll.hasClients) return;
      final p = _logScroll.position;
      _follow = p.maxScrollExtent - p.pixels < 24;
    });
    _statsTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_statsDirty || !mounted) return;
      _statsDirty = false;
      _statsTick.value++;
    });
  }

  Duration _lastTick = Duration.zero;

  // Runs only while there is something to move: new telemetry, or the axis
  // still easing toward a new range. A quiet engine costs no frames.
  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1000.0;
    _lastTick = elapsed;
    if (!_chart.advance(dt.clamp(0, 100))) {
      _ticker.stop();
      _lastTick = Duration.zero;
    }
    _frame.value++;
  }

  void _onSample(Map<String, Object?> m) {
    // Only the wake word the dropdown has selected; the engine streams
    // telemetry for every loaded model at once.
    if (_selectedId != null && m['id'] != _selectedId) return;
    final s = _Sample(m);
    _chart.add(s);
    _last = s;
    if (!_ticker.isActive) _ticker.start();
    _statsDirty = true;

    final t = DateTime.now().toIso8601String().substring(11, 19);
    if (s.fired) {
      _hits++;
      _addLog(t, s);
    } else {
      // Near miss. For vsWakeWord this is the payoff: what phonemes the
      // model decoded, so a miss reads as "heard X, wanted Y". Deduped and
      // rate-limited so the log is readable, not a firehose.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final notable =
          s.nearMiss ||
          s.decoded.isNotEmpty ||
          (s.threshold > 0 && s.score >= s.threshold * 0.75);
      if (notable && (s.decoded != _lastLogged || nowMs - _lastNearMs > 500)) {
        _nearMisses++;
        _lastLogged = s.decoded;
        _lastNearMs = nowMs;
        _addLog(t, s);
      }
    }
  }

  void _addLog(String time, _Sample sample) {
    if (!mounted) return;
    _log.add((time, sample));
    if (_log.length > _logCapacity) _log.removeAt(0);
    _logTick.value++;
    if (_follow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.jumpTo(_logScroll.position.maxScrollExtent);
        }
      });
    }
  }

  // Formatted when drawn, not when received, so an open tester's log follows
  // a language change.
  String _logLine(BuildContext context, (String, _Sample) entry) {
    final (time, sample) = entry;
    final parts = [
      time,
      voiceText(context, sample.fired ? 'HIT' : 'near'),
      '${voiceText(context, 'score')} ${sample.score.toStringAsFixed(3)}',
      if (sample.decoded.isNotEmpty)
        sample.fired
            ? '[${sample.decoded}]'
            : '${voiceText(context, 'decoded')}=[${sample.decoded}]',
      if (sample.editDistance != null && sample.editDistance! >= 0)
        '${voiceText(context, 'ed')} ${sample.editDistance}',
      if (!sample.fired && sample.matchedConfidence != null)
        '${voiceText(context, 'conf')} ${sample.matchedConfidence!.toStringAsFixed(2)}',
    ];
    return parts.join('  ');
  }

  // Switch which wake word we are watching. Its chart, stats, and log are
  // independent, so wipe them: the old numbers are for a different model.
  void _selectWord(String id) {
    if (id == _selectedId) return;
    setState(() {
      _selectedId = id;
      _chart.clear();
      _log.clear();
      _last = null;
      _hits = 0;
      _nearMisses = 0;
      _lastLogged = '';
      _lastNearMs = 0;
    });
    _frame.value++;
    _statsTick.value++;
    _logTick.value++;
  }

  Future<void> _togglePlayback() async {
    if (_player.playing != null) {
      await _player.stop();
      return;
    }
    final pcm = widget.container.wakeWord.recentAudio(
      WakeWordEngine.recentAudioLimit,
    );
    if (pcm == null || pcm.isEmpty) return;
    final ok = await _player.play('recent', pcm: pcm);
    if (!ok && mounted) {
      showToast(
        context,
        title: voiceText(context, 'Could not play the sound.'),
        kind: ToastKind.error,
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _statsTimer?.cancel();
    _ticker.dispose();
    _player.dispose();
    widget.container.wakeWord.stopTest();
    _frame.dispose();
    _statsTick.dispose();
    _logTick.dispose();
    _logScroll.dispose();
    _logScrollH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _body(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        voiceText(context, 'Wake Word Tester'),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: voiceText(context, 'Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _wordPicker(theme),
                const SizedBox(height: 12),
                // Repaints from [_frame] alone, inside its own layer.
                SizedBox(
                  height: 240,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _ChartPainter(
                          chart: _chart,
                          repaint: _frame,
                          score: scheme.primary,
                          threshold: scheme.error,
                          level: scheme.secondary,
                          grid: scheme.outlineVariant,
                          label: scheme.onSurfaceVariant,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // The play button shares the legend's line where it fits and
                // drops under it on a narrow pane.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 4,
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _legend(theme, scheme.primary, 'Score'),
                        _legend(theme, scheme.error, 'Threshold'),
                        _legend(theme, scheme.secondary, 'Mic level'),
                      ],
                    ),
                    ListenableBuilder(
                      listenable: _player,
                      builder: (context, _) {
                        final playing = _player.playing != null;
                        return TextButton.icon(
                          onPressed: _togglePlayback,
                          icon: Icon(
                            playing
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                          ),
                          label: Text(
                            voiceText(
                              context,
                              playing ? 'Stop' : 'Play last 10 seconds',
                            ),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _statsTick,
                  builder: (context, _, _) => _stats(theme),
                ),
                const SizedBox(height: 12),
                // The telemetry log: hits and near misses, with the decoded
                // phonemes for vsWakeWord.
                Row(
                  children: [
                    Text(
                      voiceText(context, 'Log'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    ValueListenableBuilder<int>(
                      valueListenable: _logTick,
                      builder: (context, _, _) => TextButton.icon(
                        onPressed: _log.isEmpty ? null : _copyLog,
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: Text(voiceText(context, 'Copy')),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _logArea(child: _logView(theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordPicker(ThemeData theme) => Wrap(
    spacing: 12,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        voiceText(context, 'Wake word'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      if (_words.isEmpty)
        Text(
          voiceText(context, 'Waiting for Voice Satellite'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        )
      else
        SizedBox(
          width: math.min(260, MediaQuery.sizeOf(context).width - 80),
          child: KsDropdown<String>(
            expand: true,
            value: _selectedId,
            items: [
              for (final w in _words)
                DropdownMenuItem(
                  value: w.id,
                  child: Text(
                    w.stop
                        ? (w.label.isEmpty
                              ? voiceText(context, 'Stop word')
                              : l10n(context).voiceStopWordNamed(w.label))
                        : w.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              if (id != null) _selectWord(id);
            },
          ),
        ),
      if (_engine.isNotEmpty)
        Text(
          _engine,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
    ],
  );

  Widget _stats(ThemeData theme) {
    final last = _last;
    final lat = _chart.latency();
    return Wrap(
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
        _stat(theme, 'Peak', _chart.peak().toStringAsFixed(3)),
        _stat(
          theme,
          'Mic level',
          last == null ? '-' : last.rms.toStringAsFixed(3),
        ),
        _stat(
          theme,
          'Chunk processing (min / avg / max)',
          '${lat.min} / ${lat.avg} / ${lat.max} ms',
        ),
      ],
    );
  }

  Future<void> _copyLog() async {
    await Clipboard.setData(
      ClipboardData(text: _log.map((e) => _logLine(context, e)).join('\n')),
    );
    if (!mounted) return;
    showToast(
      context,
      title: voiceText(context, 'Copied'),
      message: voiceText(context, 'The log is on the clipboard.'),
      kind: ToastKind.success,
      duration: const Duration(seconds: 2),
    );
  }

  static const _logStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    height: 1.4,
  );

  double? _charWidth;

  // Monospace, so the widest line is its length times one glyph.
  double get _glyphWidth => _charWidth ??= (TextPainter(
    text: const TextSpan(text: '0', style: _logStyle),
    textDirection: TextDirection.ltr,
  )..layout()).width;

  Widget _logView(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _logTick,
        builder: (context, _, _) {
          if (_log.isEmpty) {
            return Text(
              voiceText(
                context,
                'Detections and near misses will appear here.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            );
          }
          final lines = [for (final e in _log) _logLine(context, e)];
          final longest = lines.fold(0, (m, l) => math.max(m, l.length));
          final hitStyle = _logStyle.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          );
          return LayoutBuilder(
            builder: (context, cons) {
              // No wrap: long lines (a full decoded phoneme run) scroll
              // sideways instead of folding. The list inside is lazy, so a
              // full log costs the lines on screen, not all 200.
              final width = math.max(cons.maxWidth, longest * _glyphWidth + 16);
              return Scrollbar(
                controller: _logScrollH,
                thumbVisibility: true,
                notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _logScrollH,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    height: cons.maxHeight,
                    child: Scrollbar(
                      controller: _logScroll,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _logScroll,
                        padding: const EdgeInsets.only(bottom: 12),
                        itemExtent: _logLineHeight,
                        itemCount: _log.length,
                        itemBuilder: (context, i) => Text(
                          lines[i],
                          maxLines: 1,
                          softWrap: false,
                          style: _log[i].$2.fired ? hitStyle : _logStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool get _compact =>
      MediaQuery.sizeOf(context).width < 600 ||
      MediaQuery.sizeOf(context).height < 800;

  Widget _body({required Widget child}) =>
      _compact ? SingleChildScrollView(child: child) : child;

  Widget _logArea({required Widget child}) =>
      _compact ? SizedBox(height: 200, child: child) : Expanded(child: child);

  Widget _legend(ThemeData theme, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 3, color: color),
      const SizedBox(width: 5),
      Text(voiceText(context, label), style: theme.textTheme.labelSmall),
    ],
  );

  Widget _stat(ThemeData theme, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        voiceText(context, label),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      Text(value, style: theme.textTheme.titleSmall),
    ],
  );
}

/// The chart's data and its moving parts: the samples of the last
/// [window], the clock the view scrolls by and the eased axis range.
class _ChartModel {
  /// The span on screen, the same 10 seconds the playback button plays.
  static final window = WakeWordEngine.recentAudioLimit.inMilliseconds
      .toDouble();

  // Fixed arrays, filled as a ring: one inference per 30-80 ms is at most
  // ~330 samples in the window, and nothing is allocated per sample.
  static const _capacity = 512;
  final _t = Float64List(_capacity);
  final _score = Float64List(_capacity);
  final _threshold = Float64List(_capacity);
  final _rms = Float64List(_capacity);
  final _fired = Uint8List(_capacity);
  final _latencyUs = Int32List(_capacity);
  int _head = 0; // next write
  int _length = 0;

  int get length => _length;
  int _index(int i) => (_head - _length + i + _capacity) % _capacity;
  double t(int i) => _t[_index(i)];
  double score(int i) => _score[_index(i)];
  double threshold(int i) => _threshold[_index(i)];
  double rms(int i) => _rms[_index(i)];
  bool fired(int i) => _fired[_index(i)] != 0;

  /// The engine-timeline instant at the chart's right edge. It runs on the
  /// frame clock between samples and is nudged toward the newest one, so
  /// the trace glides instead of stepping once per inference.
  double now = 0;

  /// Eased y range.
  double lo = 0;
  double hi = 1;

  double _latest = double.negativeInfinity;
  double _sinceSample = 0;

  void add(_Sample s) {
    // A restarted engine starts its clock at zero again.
    if (s.t < _latest - 1000) clear();
    _t[_head] = s.t;
    _score[_head] = s.score;
    _threshold[_head] = s.threshold;
    _rms[_head] = s.rms;
    _fired[_head] = s.fired ? 1 : 0;
    _latencyUs[_head] = s.latencyUs;
    _head = (_head + 1) % _capacity;
    if (_length < _capacity) _length++;
    if (_latest == double.negativeInfinity) now = s.t;
    _latest = s.t;
    _sinceSample = 0;
  }

  void clear() {
    _head = 0;
    _length = 0;
    _latest = double.negativeInfinity;
    now = 0;
  }

  /// Move one frame of [dtMs]. False once nothing is moving any more.
  bool advance(double dtMs) {
    if (_length == 0) return false;
    _sinceSample += dtMs;
    // Where the clock should be: the newest sample, plus the time since it
    // arrived, capped so a stalled engine does not scroll into emptiness.
    final target = _latest + math.min(_sinceSample, 250);
    now += dtMs;
    now += (target - now) * 0.12;
    if (now > _latest + 250) now = _latest + 250;

    var top = 0.0, bottom = 0.0, th = 0.0;
    final from = now - window;
    for (var i = 0; i < _length; i++) {
      if (t(i) < from) continue;
      top = math.max(top, score(i));
      bottom = math.min(bottom, score(i));
      th = math.max(th, threshold(i));
    }
    // Room above the threshold and the highest score, snapped to a grid
    // step so the axis settles on round numbers instead of following every
    // peak. The scale differs by engine: probabilities for microWakeWord and
    // openWakeWord, match confidences in the tens for vsWakeWord.
    final want = math.max(math.max(top * 1.1, th * 1.3), th <= 1 ? 1.0 : 0.0);
    final step = gridStep(want - math.min(bottom, 0));
    final targetHi = (want / step).ceilToDouble() * step;
    final targetLo = bottom < 0 ? (bottom / step).floorToDouble() * step : 0.0;
    hi += (targetHi - hi) * 0.15;
    lo += (targetLo - lo) * 0.15;
    final settled =
        (targetHi - hi).abs() < 0.001 && (targetLo - lo).abs() < 0.001;
    if (settled) {
      hi = targetHi;
      lo = targetLo;
    }
    return _sinceSample < 1500 || !settled;
  }

  /// A round step (1, 2, 2.5 or 5 times a power of ten) that cuts [span]
  /// into about four.
  static double gridStep(double span) {
    if (span <= 0) return 0.25;
    final raw = span / 4;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * magnitude >= raw) return m * magnitude;
    }
    return 10.0 * magnitude;
  }

  double peak() {
    var p = 0.0;
    final from = now - window;
    for (var i = 0; i < _length; i++) {
      if (t(i) >= from) p = math.max(p, score(i));
    }
    return p;
  }

  ({int min, int avg, int max}) latency() {
    var mn = 1 << 30, mx = 0, sum = 0, n = 0;
    for (var i = 0; i < _length; i++) {
      final v = _latencyUs[_index(i)];
      if (v <= 0) continue;
      if (v < mn) mn = v;
      if (v > mx) mx = v;
      sum += v;
      n++;
    }
    if (n == 0) return (min: 0, avg: 0, max: 0);
    return (min: mn ~/ 1000, avg: (sum ~/ n) ~/ 1000, max: mx ~/ 1000);
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.chart,
    required Listenable repaint,
    required this.score,
    required this.threshold,
    required this.level,
    required this.grid,
    required this.label,
  }) : super(repaint: repaint);

  final _ChartModel chart;
  final Color score;
  final Color threshold;
  final Color level;
  final Color grid;
  final Color label;

  static const _leftPad = 44.0;
  static const _rightPad = 10.0;
  static const _topPad = 12.0;
  static const _levelLane = 34.0;
  static const _laneGap = 10.0;

  /// dBFS at the bottom of the mic level lane; the top is full scale.
  static const _levelFloorDb = -60.0;

  // Tick labels keyed by their text and color: an easing axis keeps reusing
  // the same handful, and laying text out every frame is what made the old
  // chart slow.
  static final _labels = <String, TextPainter>{};

  TextPainter _labelFor(String text) =>
      _labels['${label.toARGB32()}|$text'] ??= TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: label, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final left = _leftPad;
    final right = size.width - _rightPad;
    final plotW = right - left;
    final top = _topPad;
    final bottom = size.height - _levelLane - _laneGap;
    final plotH = bottom - top;
    final laneTop = bottom + _laneGap;
    final laneBottom = size.height - 6;
    final laneH = laneBottom - laneTop;
    if (plotW <= 0 || plotH <= 0) return;

    final lo = chart.lo, hi = chart.hi;
    final span = hi - lo <= 0 ? 1.0 : hi - lo;
    double y(double v) => bottom - ((v - lo) / span) * plotH;
    final now = chart.now;
    final window = _ChartModel.window;
    double x(double t) => right - (now - t) / window * plotW;

    // Grid at quarter steps of the eased range; labels ride with the lines.
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final step = _ChartModel.gridStep(span);
    final digits = step >= 1 ? 0 : (step >= 0.5 ? 1 : 2);
    for (var k = (lo / step).ceil(); k * step <= hi + 1e-9; k++) {
      final v = k * step;
      final yy = y(v);
      if (yy < top - 1) continue;
      canvas.drawLine(Offset(left, yy), Offset(right, yy), gridPaint);
      final tp = _labelFor(v.toStringAsFixed(digits));
      tp.paint(canvas, Offset(left - tp.width - 6, yy - tp.height / 2));
    }
    // The level lane's frame: a baseline, and full scale as a faint line.
    canvas.drawLine(
      Offset(left, laneBottom),
      Offset(right, laneBottom),
      gridPaint,
    );

    final n = chart.length;
    if (n == 0) return;
    // First sample still on screen, one earlier so the line enters from the
    // left edge instead of starting mid-air.
    var first = 0;
    final from = now - window;
    while (first < n - 1 && chart.t(first + 1) < from) {
      first++;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, 0, right, size.height));

    // Mic level: RMS in dBFS, as a filled strip under the plot.
    final levelPath = Path()..moveTo(x(chart.t(first)), laneBottom);
    for (var i = first; i < n; i++) {
      final rms = chart.rms(i);
      final db = rms <= 0 ? _levelFloorDb : 20 * math.log(rms) / math.ln10;
      final f = ((db - _levelFloorDb) / -_levelFloorDb).clamp(0.0, 1.0);
      levelPath.lineTo(x(chart.t(i)), laneBottom - f * laneH);
    }
    levelPath
      ..lineTo(x(chart.t(n - 1)), laneBottom)
      ..close();
    canvas.drawPath(levelPath, Paint()..color = level.withValues(alpha: 0.45));

    // Threshold: per sample, since vsWakeWord's depends on the target.
    final thPath = Path()..moveTo(x(chart.t(first)), y(chart.threshold(first)));
    for (var i = first + 1; i < n; i++) {
      thPath.lineTo(x(chart.t(i)), y(chart.threshold(i)));
    }
    thPath.lineTo(right, y(chart.threshold(n - 1)));
    canvas.drawPath(
      thPath,
      Paint()
        ..color = threshold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Score: a line with a soft fill under it.
    final scorePath = Path()..moveTo(x(chart.t(first)), y(chart.score(first)));
    for (var i = first + 1; i < n; i++) {
      scorePath.lineTo(x(chart.t(i)), y(chart.score(i)));
    }
    final fill = Path.from(scorePath)
      ..lineTo(x(chart.t(n - 1)), y(math.max(lo, 0)))
      ..lineTo(x(chart.t(first)), y(math.max(lo, 0)))
      ..close();
    canvas.drawPath(fill, Paint()..color = score.withValues(alpha: 0.14));
    canvas.drawPath(
      scorePath,
      Paint()
        ..color = score
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Hits: a marker on the score and a rule down through the level lane,
    // so a detection lines up with what the microphone was hearing.
    final hitPaint = Paint()..color = score;
    final rule = Paint()
      ..color = score.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = first; i < n; i++) {
      if (!chart.fired(i)) continue;
      final hx = x(chart.t(i));
      canvas.drawLine(Offset(hx, top), Offset(hx, laneBottom), rule);
      canvas.drawCircle(Offset(hx, y(chart.score(i))), 4, hitPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.score != score ||
      old.threshold != threshold ||
      old.level != level ||
      old.grid != grid ||
      old.label != label;
}
