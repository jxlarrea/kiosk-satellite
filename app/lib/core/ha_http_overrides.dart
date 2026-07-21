import 'dart:io';

import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';

/// Most Home Assistant installs on a LAN run self-signed certificates, so
/// the app must not fail TLS verification against its own configured
/// server — that would break setup validation, service calls, the
/// websocket, and wake-word model downloads alike.
///
/// Installed as [HttpOverrides.global], which every dart:io HttpClient in
/// the process inherits (package:http and WebSocket.connect included).
/// The exemption is scoped to the configured HA host only — certificates
/// for any other host still verify normally. The WebView has its own trust
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
    client.badCertificateCallback = (cert, host, port) {
      final ha = Uri.tryParse(_settings.get(defs.haUrl).trim())?.host;
      if (ha != null && ha.isNotEmpty && host == ha) {
        sawSelfSigned = true;
        return true;
      }
      // The Immich screensaver server gets the same standing as HA: a LAN
      // service the user pointed the app at, likely behind a self-signed
      // certificate. Still host-scoped; everything else verifies normally.
      final immich = Uri.tryParse(
        _settings.get(defs.screensaverImmichUrl).trim(),
      )?.host;
      if (immich != null && immich.isNotEmpty && host == immich) return true;
      return false;
    };
    return client;
  }
}
