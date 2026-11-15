import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'adaptive_volume_curve.dart';

/// Adaptive volume (issue #1450): the room's noise sets how loud the kiosk
/// plays. Each volume that follows the room plays at a share of its own
/// slider, read off the curve at the room's level.
///
/// The room is only known while the kiosk is silent. The noise level
/// manager measures in five second windows and throws away any the kiosk
/// played into, so a share is picked before a sound starts and cannot move
/// until it ends: an answer never changes loudness halfway and music does
/// not chase its own echo.
///
/// One window is a poor guess at the next half minute of a room with a
/// television in it, so the level followed here is an estimate over the
/// windows. It rises once two windows in a row are louder, to the quieter
/// of the two, so a slammed door changes nothing. It falls by [fallStep]
/// per window, so a quiet scene does not take the volume down with it.
/// After [staleAfter] without a window (an hour of music) the next quieter
/// one is taken as it is.
///
/// The noise level manager holds the microphone open for this while the
/// switch is on, so the room is read with or without Voice Satellite.
/// Before the first reading every share is 1 and the sliders play as they
/// always did. A reading that goes away later keeps its last estimate:
/// muting the microphone at night must not make the next announcement
/// loud. A window of digital silence is a capture Android has silenced
/// (the app behind another one), not a quiet room, and is skipped.
///
/// The shares go out as [AdaptiveVolumeChanged]. The device manager hands
/// the media and assistant ones to the platform's mixer and the intercom
/// applies its own.
class AdaptiveVolumeManager extends Manager {
  AdaptiveVolumeManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    @visibleForTesting DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SettingsManager _settings;
  final DateTime Function() _now;

  @override
  String get name => 'adaptive_volume';

  /// How far the estimate falls per quieter window, in dB.
  static const fallStep = 1.0;

  /// A gap between windows after which the estimate is out of date.
  static const staleAfter = Duration(seconds: 60);

  /// At or below this a window is digital silence: no microphone in a
  /// room reads the bottom of 16-bit audio.
  static const _silence = -95.5;

  static final _keys = {
    defs.adaptiveVolume.key,
    defs.adaptiveVolumeAssistant.key,
    defs.adaptiveVolumeMedia.key,
    defs.adaptiveVolumeIntercom.key,
    defs.adaptiveVolumeCurve.key,
  };

  final _subs = <StreamSubscription<Object?>>[];

  double? _estimate;

  /// A louder window waiting for the next one to agree.
  double? _louder;
  DateTime? _lastWindow;

  AdaptiveVolumeChanged? _sent;

  /// The room's level as the curve follows it, in dBFS, or null before the
  /// first reading.
  double? get noise => _estimate;

  bool get enabled => _settings.get(defs.adaptiveVolume);

  AdaptiveVolumeCurve get curve =>
      AdaptiveVolumeCurve.parse(_settings.get(defs.adaptiveVolumeCurve));

  /// The share of its slider [channel] plays at now: 1 with the feature
  /// off, the volume not following the room or no reading yet.
  double share(VolumeChannel channel) {
    final noise = _estimate;
    if (noise == null || !enabled || !_follows(channel)) return 1;
    return curve.levelAt(channel, noise).clamp(0.0, 1.0).toDouble();
  }

  bool _follows(VolumeChannel channel) => switch (channel) {
    VolumeChannel.assistant => _settings.get(defs.adaptiveVolumeAssistant),
    VolumeChannel.media => _settings.get(defs.adaptiveVolumeMedia),
    VolumeChannel.intercom =>
      _settings.get(defs.adaptiveVolumeIntercom) &&
          _settings.get(defs.intercomEnabled),
  };

  Map<String, Object?> describe() => {
    'enabled': enabled,
    'noise': _rounded(_estimate),
    'assistant': share(VolumeChannel.assistant),
    'media': share(VolumeChannel.media),
    'intercom': share(VolumeChannel.intercom),
  };

  @override
  Future<void> init() async {
    _subs
      ..add(bus.on<NoiseWindowMeasured>().listen((e) => _onWindow(e.dbfs)))
      ..add(
        bus.on<SettingChanged>().listen((e) {
          if (_keys.contains(e.key) || e.key == defs.intercomEnabled.key) {
            _publish();
          }
        }),
      );
    commands.register(
      Command(
        name: 'getAdaptiveVolume',
        description:
            'Adaptive volume: whether it is on, the room noise level it '
            'follows in dBFS (null before the first reading) and the share '
            'of its own slider each volume plays at, 0 to 1',
        handler: (_) async => CommandResult.ok(describe()),
      ),
    );
    _publish();
  }

  void _onWindow(double db) {
    if (db <= _silence) return;
    final now = _now();
    final last = _lastWindow;
    final stale = last == null || now.difference(last) > staleAfter;
    _lastWindow = now;
    if (stale) _louder = null;
    final estimate = _estimate;
    if (estimate == null) {
      _estimate = db;
    } else if (db <= estimate) {
      _louder = null;
      _estimate = stale ? db : math.max(db, estimate - fallStep);
    } else {
      final louder = _louder;
      if (louder != null) _estimate = math.min(louder, db);
      _louder = db;
    }
    _publish();
  }

  static double? _rounded(double? db) =>
      db == null ? null : (db * 10).round() / 10;

  void _publish() {
    double share2(VolumeChannel c) => (share(c) * 1000).round() / 1000;
    final next = AdaptiveVolumeChanged(
      noise: _rounded(_estimate),
      assistant: share2(VolumeChannel.assistant),
      media: share2(VolumeChannel.media),
      intercom: share2(VolumeChannel.intercom),
    );
    final sent = _sent;
    if (sent != null &&
        sent.noise == next.noise &&
        sent.assistant == next.assistant &&
        sent.media == next.media &&
        sent.intercom == next.intercom) {
      return;
    }
    // One line per whole percent moved, not per window of a slow fall.
    if (sent == null ||
        _percent(sent.assistant) != _percent(next.assistant) ||
        _percent(sent.media) != _percent(next.media) ||
        _percent(sent.intercom) != _percent(next.intercom)) {
      log.info(
        name,
        'room ${next.noise?.toStringAsFixed(1) ?? 'unknown'} dBFS: '
        'assistant ${_percent(next.assistant)}, '
        'media ${_percent(next.media)}, '
        'intercom ${_percent(next.intercom)}',
      );
    }
    _sent = next;
    bus.publish(next);
  }

  static String _percent(double share) => '${(share * 100).round()}%';

  @override
  Future<void> dispose() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }
}
