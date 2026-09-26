import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'pcm16.dart';

/// One wake word activation or near miss, as wake word diagnostics saved it.
class WakeActivation {
  const WakeActivation({
    required this.id,
    this.nearMiss = false,
    required this.at,
    required this.wakeWord,
    required this.engine,
    required this.durationMs,
    required this.peakDb,
    required this.rmsDb,
    required this.clipped,
    this.score,
    this.threshold,
    this.trigger,
    this.decoded,
    this.editDistance,
  });

  /// Also the clip's file name, without the extension.
  final String id;

  /// Scored within reach of the threshold and fell back without firing.
  /// [score] is then the episode's peak.
  final bool nearMiss;
  final DateTime at;
  final String wakeWord;
  final String engine;

  /// What the detector scored and the cutoff it had to clear.
  final double? score;
  final double? threshold;

  /// microWakeWord and openWakeWord: 'immediate' or 'confirmed'.
  final String? trigger;

  /// vsWakeWord: the phonemes it heard and how far they were from the target.
  final String? decoded;
  final int? editDistance;

  /// Clip length and levels, in dBFS.
  final int durationMs;
  final double peakDb;
  final double rmsDb;

  /// Samples at full scale: any at all means the microphone clipped.
  final int clipped;

  static double? _finite(Object? v) {
    final d = (v as num?)?.toDouble();
    return d != null && d.isFinite ? d : null;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    if (nearMiss) 'nearMiss': true,
    'at': at.toUtc().toIso8601String(),
    'wakeWord': wakeWord,
    'engine': engine,
    if (score != null) 'score': score,
    if (threshold != null) 'threshold': threshold,
    if (trigger != null) 'trigger': trigger,
    if (decoded != null) 'decoded': decoded,
    if (editDistance != null) 'editDistance': editDistance,
    'durationMs': durationMs,
    // JSON has no -Infinity: a silent clip reads as null.
    'peakDb': _finite(peakDb),
    'rmsDb': _finite(rmsDb),
    'clipped': clipped,
  };

  static WakeActivation? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final at = DateTime.tryParse('${raw['at']}');
    if (id is! String || at == null) return null;
    return WakeActivation(
      id: id,
      nearMiss: raw['nearMiss'] == true,
      at: at.toLocal(),
      wakeWord: '${raw['wakeWord'] ?? ''}',
      engine: '${raw['engine'] ?? ''}',
      score: _finite(raw['score']),
      threshold: _finite(raw['threshold']),
      trigger: raw['trigger'] as String?,
      decoded: raw['decoded'] as String?,
      editDistance: (raw['editDistance'] as num?)?.toInt(),
      durationMs: (raw['durationMs'] as num?)?.toInt() ?? 0,
      peakDb: _finite(raw['peakDb']) ?? double.negativeInfinity,
      rmsDb: _finite(raw['rmsDb']) ?? double.negativeInfinity,
      clipped: (raw['clipped'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The last [capacity] wake word activations and the last [capacity] near
/// misses, with a short clip of each, kept on disk so they survive a
/// restart. Separate allowances, so a noisy room's near misses never push
/// the real activations out. Only written while the user has wake word
/// diagnostics on; turning it off calls [clear].
class WakeWordDiagnostics extends ChangeNotifier {
  WakeWordDiagnostics({
    @visibleForTesting Future<Directory> Function()? directory,
    this.capacity = 10,
  }) : _directory = directory ?? _defaultDirectory;

  static Future<Directory> _defaultDirectory() async => Directory(
    '${(await getApplicationSupportDirectory()).path}/wake_word_diagnostics',
  );

  /// How much audio each activation keeps, ending at the detection.
  static const clipLength = Duration(seconds: 3);

  final int capacity;
  final Future<Directory> Function() _directory;

  // Both kinds, newest first.
  List<WakeActivation> _entries = const [];

  /// Newest first.
  List<WakeActivation> get activations => [
    for (final e in _entries)
      if (!e.nearMiss) e,
  ];

  /// Newest first.
  List<WakeActivation> get nearMisses => [
    for (final e in _entries)
      if (e.nearMiss) e,
  ];

  // Every disk touch runs in order: a detection landing while the list is
  // still loading, or a clear racing a save, must not interleave.
  Future<void> _queue = Future.value();

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<Directory> _dir() async {
    final dir = await _directory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _index() async => File('${(await _dir()).path}/index.json');

  /// Read what an earlier run saved.
  Future<void> load() => _serial(() async {
    try {
      final index = await _index();
      if (!await index.exists()) return;
      final raw = jsonDecode(await index.readAsString());
      if (raw is! List) return;
      _entries = [for (final entry in raw) ?WakeActivation.fromJson(entry)];
      notifyListeners();
    } catch (_) {
      // A torn index loses the list, not the app.
    }
  });

  /// The clip of activation or near miss [id], or null when it is gone.
  Future<File?> clip(String id) async {
    if (!_entries.any((a) => a.id == id)) return null;
    final file = File('${(await _dir()).path}/$id.wav');
    return await file.exists() ? file : null;
  }

  /// Save one activation, or a near miss when [nearMiss]: [pcm] is the
  /// audio leading up to it (16 kHz mono PCM16) and [detection] what the
  /// detector reported.
  Future<WakeActivation> record({
    required String wakeWord,
    required String engine,
    required Uint8List pcm,
    Map<String, Object?>? detection,
    bool nearMiss = false,
    DateTime? at,
  }) => _serial(() async {
    final when = at ?? DateTime.now();
    var id = '${when.millisecondsSinceEpoch}';
    // Two detections in one millisecond cannot happen on a real mic, but an
    // injected clip can get close; never overwrite.
    while (_entries.any((a) => a.id == id)) {
      id = '${int.parse(id) + 1}';
    }
    final levels = pcm16Levels(pcm);
    double? number(String key) => WakeActivation._finite(detection?[key]);
    final decoded = detection?['decoded'];
    final activation = WakeActivation(
      id: id,
      nearMiss: nearMiss,
      at: when,
      wakeWord: wakeWord,
      engine: engine,
      score: number('score'),
      threshold: number('threshold'),
      trigger: detection?['trigger'] as String?,
      decoded: decoded is String && decoded.isNotEmpty ? decoded : null,
      editDistance: switch (detection?['editDistance']) {
        final num d when d >= 0 => d.toInt(),
        _ => null,
      },
      durationMs: pcm.length ~/ 32,
      peakDb: levels.peakDb,
      rmsDb: levels.rmsDb,
      clipped: levels.clipped,
    );
    final dir = await _dir();
    await File('${dir.path}/$id.wav').writeAsBytes(pcm16Wav(pcm), flush: true);
    // The allowance is per kind: only the oldest of this kind goes.
    final kept = <WakeActivation>[];
    var sameKind = 0;
    for (final e in [activation, ..._entries]) {
      if (e.nearMiss == nearMiss && ++sameKind > capacity) {
        try {
          await File('${dir.path}/${e.id}.wav').delete();
        } catch (_) {}
        continue;
      }
      kept.add(e);
    }
    _entries = List.unmodifiable(kept);
    await _writeIndex();
    notifyListeners();
    return activation;
  });

  Future<void> _writeIndex() async {
    final index = await _index();
    final tmp = File('${index.path}.tmp');
    await tmp.writeAsString(
      jsonEncode([for (final a in _entries) a.toJson()]),
      flush: true,
    );
    await tmp.rename(index.path);
  }

  /// Forget every activation and delete the clips. Never throws: it runs
  /// unawaited at startup and from a settings listener.
  Future<void> clear() => _serial(() async {
    try {
      final dir = await _directory();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
    if (_entries.isEmpty) return;
    _entries = const [];
    notifyListeners();
  });

  // A save still in flight when the manager shuts down must not notify.
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
