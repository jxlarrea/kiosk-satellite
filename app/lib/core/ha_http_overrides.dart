import 'dart:io';

import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';
import 'app_identity.dart';

/// Most Home Assistant installs on a LAN run self-signed certificates, so
/// the app must not fail TLS verification against its own configured
/// server — that would break setup validation, service calls, the
/// websocket, and wake-word model downloads alike.
///
/// Installed as [HttpOverrides.global], which every dart:io HttpClient in
/// the process inherits (package:http and WebSocket.connect included).
/// The exemption is scoped to the configured HA host only — certificates
/// for any other host still verify normally — unless the user enabled the
/// browser's "Ignore SSL errors" setting, which turns verification off for
/// these clients just as it does for the WebView. The WebView has its own trust
/// stack; [sawSelfSigned] lets the connection check align the browser's
/// "Ignore SSL errors" setting when a self-signed certificate was in fact
/// accepted.
class HaHttpOverrides extends HttpOverrides {
  HaHttpOverrides(this._settings);

  final SettingsManager _settings;

  /// Set when a bad certificate for the HA host was accepted this run.
  static bool sawSelfSigned = false;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    // Every client in the process is born here, so this is the one place
    // the app has to name itself. A request that sets its own User-Agent
    // header still wins, which is what keeps the secure-context proxy
    // forwarding the browser's own string.
    client.userAgent = AppIdentity.userAgent;
    client.badCertificateCallback = (cert, host, port) =>
        allowBadCertificate(host);
    return client;
  }

  /// The policy behind badCertificateCallback, separate so tests can
  /// exercise it without staging a TLS handshake.
  bool allowBadCertificate(String host) {
    final ha = Uri.tryParse(_settings.get(defs.haUrl).trim())?.host;
    if (ha != null && ha.isNotEmpty && host == ha) {
      sawSelfSigned = true;
      return true;
    }
    // "Ignore SSL errors" is the browser's blanket opt-in, and these
    // clients must agree with the WebView about what connects. Wake-word
    // manifest URLs come from the dashboard page's own origin, which can
    // name a host neither setting above knows about, e.g. an old IP the
    // dashboard still loads from while the HA URL moved to a domain
    // (issue #216).
    if (_settings.get(defs.ignoreSslErrors)) return true;
    // The Immich screensaver server gets the same standing as HA: a LAN
    // service the user pointed the app at, likely behind a self-signed
    // certificate. Still host-scoped; everything else verifies normally.
    final immich = Uri.tryParse(
      _settings.get(defs.screensaverImmichUrl).trim(),
    )?.host;
    if (immich != null && immich.isNotEmpty && host == immich) return true;
    return false;
  }
}
