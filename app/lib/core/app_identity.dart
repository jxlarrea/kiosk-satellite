/// How Kiosk Satellite introduces itself on the wire.
///
/// Every request the app makes from Dart used to go out as
/// `Dart/3.9 (dart:io)`, which tells the person reading a Go2RTC, Home
/// Assistant or reverse-proxy log nothing at all: not the app, not its
/// version, not even that the traffic came from a kiosk. One string, set
/// on the global [HttpOverrides] client, covers every HTTP request and
/// every websocket the app opens.
///
/// The WebView keeps its own browser user agent: pages are browsed as a
/// browser, and Home Assistant's frontend reads that string.
class AppIdentity {
  const AppIdentity._();

  static const product = 'KioskSatellite';
  static const homepage = 'https://github.com/jxlarrea/kiosk-satellite';

  /// The user agent every outbound request carries. Set once at startup;
  /// until then it is the bare product name, so a request that somehow
  /// beats [configure] still identifies the app.
  static String userAgent = product;

  /// `KioskSatellite/2026.8.14 (Android 12; +https://github.com/...)`.
  /// The version answers "which build is doing this", the OS answers the
  /// first question every support thread asks, and the link is what
  /// services that require a contactable user agent (LRCLIB) ask for. No
  /// device model: this string reaches third-party servers, and the model
  /// is a fingerprint they have no business collecting.
  static void configure({required String version, required String osVersion}) {
    final os = osVersion.trim();
    userAgent =
        '$product/$version (${os.isEmpty ? '' : '$os; '}+$homepage)';
  }
}
