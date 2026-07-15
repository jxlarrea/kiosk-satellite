import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/logging.dart';
import 'settings_manager.dart';

/// Provisioning via Android launch-intent extras — configure a device from
/// adb or an MDM without touching the UI:
///
///   adb shell am start -n me.jxl.kiosk_satellite/.MainActivity \
///     --es ks.provision '{"remote.enabled":true,"remote.password":"..."}'
///
/// Keys/values are the same JSON the remote API's settings import accepts.
///
/// TODO(security): gate behind a "provisioning allowed" setting (or
/// first-run-only) before release — any app on the device can send intents.
class ProvisioningChannel {
  ProvisioningChannel(this._settings, this._log);

  static const _channel = MethodChannel('kiosk_satellite/provision');

  final SettingsManager _settings;
  final Logger _log;

  Future<void> init() async {
    // Push path: app already running when a provisioning intent arrives.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'provision' && call.arguments is String) {
        await _apply(call.arguments as String);
      }
    });

    // Pull path: provisioning extra on the launch intent.
    try {
      final json = await _channel.invokeMethod<String>('getProvisionJson');
      if (json != null) await _apply(json);
    } on MissingPluginException {
      // Not on Android, or the host activity doesn't expose the channel.
    }
  }

  Future<void> _apply(String json) async {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map) return;
      final applied = await _settings.import(decoded.cast<String, Object?>());
      _log.info('provision', 'applied $applied setting(s) from intent');
    } catch (e) {
      _log.warn('provision', 'bad provisioning payload: $e');
    }
  }
}
