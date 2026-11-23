import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// The camera flashlight (issue #1574, Flashlight.kt on the native side).
///
/// [defs.cameraFlashlight] is the source of truth: the settings pages, the
/// remote admin and the ESPHome switch all write it, and this manager
/// turns the light on or off to match. A switch made elsewhere, such as
/// the quick settings tile, comes back as `changed` and lands in the
/// setting, so every surface shows the light as it is.
///
/// On a device without a flash the Flashlight group is hidden everywhere
/// and nothing runs.
class FlashlightManager extends Manager {
  FlashlightManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;
  static const _channel = MethodChannel('kiosk_satellite/flashlight');

  bool _present = false;
  bool get present => _present;
  StreamSubscription<SettingChanged>? _sub;

  @override
  String get name => 'flashlight';

  @override
  Future<void> init() async {
    try {
      final info = await _channel.invokeMapMethod<String, Object?>('describe');
      _present = info?['present'] == true;
    } catch (_) {
      _present = false;
    }
    commands.register(
      Command(
        name: 'getFlashlightSupport',
        description: 'Whether this device has a camera flashlight.',
        handler: (_) async => CommandResult.ok({'supported': _present}),
      ),
    );
    if (!_present) {
      defs.deviceHiddenKeys.add(defs.cameraFlashlight.key);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'changed') return;
      final on = (call.arguments as Map?)?['on'] == true;
      if (_settings.get(defs.cameraFlashlight) == on) return;
      log.info(
        name,
        'flashlight switched ${on ? 'on' : 'off'} outside the app',
      );
      await _settings.set(defs.cameraFlashlight, on, source: 'flashlight');
    });
    _sub = bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.cameraFlashlight.key) {
        unawaited(_apply(e.value == true));
      }
    });
    // Off at boot leaves the light alone: something else may have it on.
    if (_settings.get(defs.cameraFlashlight)) await _apply(true);
  }

  Future<void> _apply(bool on) async {
    try {
      await _channel.invokeMethod<void>('set', {'on': on});
    } catch (e) {
      log.warn(name, 'could not switch the flashlight: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
  }
}
