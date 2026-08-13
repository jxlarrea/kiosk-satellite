import 'dart:async';

import 'package:flutter/services.dart';

import '../app_container.dart';
import 'events.dart';
import '../managers/settings/definitions.dart' as defs;

/// Detects a wedged renderer and restarts the process.
///
/// When the Activity is destroyed and recreated (a permission dialog is
/// enough on some devices), re-attaching the process-wide cached engine can
/// silently fail: the launch splash stays on screen forever while the Dart
/// isolate runs on underneath — on a kiosk with the hardware buttons
/// blocked, a dead wall until someone kills the process.
///
/// Detection leans on two ground truths, chosen because everything subtler
/// lies in this state (the native first-frame callback reports "displayed"
/// from the previous attach; Dart frame callbacks keep completing into a
/// surface nobody sees):
///
///  1. The Activity is in front — from native onResume/onPause via the
///     background bridge, not the engine's lifecycle reporting.
///  2. A configured kiosk has no WebView attached — the platform view
///     cannot come up without a working attach, so its prolonged absence
///     is the wedge. Transients (a settings-triggered WebView rebuild) last
///     moments; the watchdog needs three consecutive strikes 5s apart.
///
/// Recovery escalates. First a WebView rebuild in place: the create-raced-
/// attach variant (issue #145 — the platform view was requested before the
/// Activity attached, failed once, and never retries) heals with a fresh
/// widget now that the Activity is up. Then, strikes later, a full process
/// restart through the background bridge: for the failed-re-attach variant
/// a rebuild has been observed to leave the wedge in place, and only a
/// restart reliably comes back.
class FrameWatchdog {
  FrameWatchdog(this._container);

  static const _channel = MethodChannel('kiosk_satellite/background');
  static const _interval = Duration(seconds: 5);

  /// 30s of foregrounded-with-no-WebView before restarting. Generous on
  /// purpose: a healthy cold boot on a fast tablet already reaches two
  /// 5s strikes before the WebView attaches, and slow devices need real
  /// headroom — a false trip here would be a restart loop.
  static const _strikesToTrip = 6;

  /// The in-place rebuild attempt, past any healthy slow boot (20s in)
  /// and early enough that a rebuild that works averts the restart.
  static const _strikesToRebuild = 4;

  final AppContainer _container;
  Timer? _timer;
  int _strikes = 0;
  bool _tripped = false;

  void start() {
    _container.log.info('watchdog', 'armed (${_interval.inSeconds}s checks)');
    _timer = Timer.periodic(_interval, (_) => _check());
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _check() async {
    if (_tripped) return;
    if (_container.settings.get(defs.startUrl).isEmpty) {
      _strikes = 0;
      return;
    }
    bool resumed;
    try {
      resumed =
          await _channel.invokeMethod<bool>('isActivityResumed') ?? false;
    } catch (e) {
      _container.log.warn('watchdog', 'resume probe failed: $e');
      return;
    }
    if (!resumed || _container.browser.hasWebView) {
      _strikes = 0;
      return;
    }
    _strikes++;
    _container.log.warn(
      'watchdog',
      'strike $_strikes/$_strikesToTrip: resumed with no WebView',
    );
    if (_strikes == _strikesToRebuild) {
      _container.log.warn(
        'watchdog',
        'requesting a WebView rebuild before restarting',
      );
      _container.bus.publish(const WebViewRebuildRequested());
      return;
    }
    if (_strikes < _strikesToTrip) return;
    _tripped = true;
    _container.log.error(
      'watchdog',
      'foregrounded with no WebView for '
          '${_interval.inSeconds * _strikesToTrip}s: renderer wedged, '
          'restarting the process',
    );
    // Give the log line a moment to flush.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      await _channel.invokeMethod<void>('restartProcess', {
        // Lands in the crash journal: this kill throws nothing, and the
        // in-memory log dies with the process, so without the reason the
        // restart is indistinguishable from a crash after the fact.
        'reason': 'the frame watchdog found the UI wedged '
            '(no frames for ${_interval.inSeconds * _strikesToTrip}s)',
      });
    } catch (e) {
      _container.log.error('watchdog', 'restart failed: $e');
      _tripped = false;
    }
  }
}
