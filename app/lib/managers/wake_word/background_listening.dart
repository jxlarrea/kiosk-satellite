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

  /// Whether the device admin grant behind the real "Screen off" is active.
  static Future<bool> isScreenOffAvailable() async =>
      await _channel.invokeMethod<bool>('isScreenOffAvailable') ?? false;

  /// Send the user to the "Display over other apps" settings screen.
  static Future<void> requestBringToFront() =>
      _channel.invokeMethod<void>('requestBringToFront');

  /// Come to the front. False when the grant is missing, which is the caller's
  /// cue to say so rather than fail silently.
  static Future<bool> bringToFront() async =>
      await _channel.invokeMethod<bool>('bringToFront') ?? false;

  static Future<bool> isBatteryUnrestricted() async =>
      await _channel.invokeMethod<bool>('isBatteryUnrestricted') ?? false;

  /// Hand a WebView download to Android's DownloadManager. Same app-context
  /// bridge as the rest: works whether or not an Activity is up. Returns the
  /// DownloadManager id (-1 on failure), which [onDownloadComplete] reports
  /// back and [openDownload] accepts.
  static Future<int> download({
    required String url,
    String? filename,
    String? userAgent,
    String? mimeType,
  }) async =>
      (await _channel.invokeMethod<num>('download', {
        'url': url,
        'filename': filename,
        'userAgent': userAgent,
        'mimeType': mimeType,
      }))
          ?.toInt() ??
      -1;

  /// Launch a finished download (the snackbar's "Open" action): an APK goes
  /// to the package installer, anything else to its default viewer.
  static Future<bool> openDownload(int id) async =>
      await _channel.invokeMethod<bool>('openDownload', {'id': id}) ?? false;

  /// Completion feedback for [download]. The kiosk hides the status bar, so
  /// the DownloadManager notification is invisible; the platform side pushes
  /// completion through the channel instead and this hands it to the UI.
  /// Setting a handler replaces the previous one.
  static void Function(int id, bool success, String? filename)?
      _onDownloadComplete;

  static set onDownloadComplete(
      void Function(int id, bool success, String? filename)? handler) {
    _onDownloadComplete = handler;
    _channel.setMethodCallHandler(handler == null
        ? null
        : (call) async {
            if (call.method == 'downloadComplete') {
              final args = (call.arguments as Map?) ?? const {};
              _onDownloadComplete?.call(
                (args['id'] as num?)?.toInt() ?? -1,
                args['success'] == true,
                args['filename'] as String?,
              );
            }
            return null;
          });
  }

  static Future<void> requestBatteryUnrestricted() =>
      _channel.invokeMethod<void>('requestBatteryUnrestricted');
}
