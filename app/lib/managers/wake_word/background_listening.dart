import 'package:flutter/services.dart';

/// Keeping the wake word alive while the app is not on screen, and coming back
/// to the front when it hears one.
///
/// Android freezes cached processes whole. Put the app behind another one and
/// the microphone goes silent, the WebView running Voice Satellite stops, its
/// websocket to Home Assistant stops, and the remote admin's own HTTP server
/// stops answering — all at once, with the process still alive. Nothing is
/// selectively disabled and nothing can opt in on its own.
///
/// A foreground service is the exemption, and because the freeze is
/// process-wide, that one exemption thaws all of it together: the card's
/// session is still live when a wake word fires, so it can stream from the
/// pre-roll captured while we were behind another app, and no speech is lost.
///
/// Three OS grants, each separately refusable:
///
///  - the service itself, which needs nothing but shows a permanent
///    notification that cannot be dismissed;
///  - "Display over other apps", without which we hear the wake word and cannot
///    come forward — worse than not listening at all;
///  - a battery-optimisation exemption, or Samsung stops the service after a few
///    hours whatever the foreground-service rules say.
class BackgroundListening {
  static const _channel = MethodChannel('kiosk_satellite/background');

  /// Keep the process running (and the microphone real) while off screen.
  static Future<bool> start() async =>
      await _channel.invokeMethod<bool>('start') ?? false;

  static Future<bool> stop() async =>
      await _channel.invokeMethod<bool>('stop') ?? false;

  /// Whether we may start our own Activity from behind another app.
  static Future<bool> canBringToFront() async =>
      await _channel.invokeMethod<bool>('canBringToFront') ?? false;

  /// Send the user to the "Display over other apps" settings screen.
  static Future<void> requestBringToFront() =>
      _channel.invokeMethod<void>('requestBringToFront');

  /// Come to the front. False when the grant is missing, which is the caller's
  /// cue to say so rather than fail silently.
  static Future<bool> bringToFront() async =>
      await _channel.invokeMethod<bool>('bringToFront') ?? false;

  static Future<bool> isBatteryUnrestricted() async =>
      await _channel.invokeMethod<bool>('isBatteryUnrestricted') ?? false;

  static Future<void> requestBatteryUnrestricted() =>
      _channel.invokeMethod<void>('requestBatteryUnrestricted');
}
