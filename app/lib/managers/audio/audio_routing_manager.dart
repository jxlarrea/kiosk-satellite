import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../wake_word/vsww/native_mic.dart';

/// The user's microphone and speaker selections, applied to native audio.
///
/// Selections are AudioRouting selectors ("type|address|name", empty =
/// automatic) so they survive reboots and device ids changing. The mic
/// selector travels with the mic stream itself ([NativeMic.deviceSelector],
/// read when the wake-word engine opens capture); the speaker selector is
/// pushed to the platform and resolved per play. Dashboard audio the page
/// has not delegated plays in the WebView and follows the system's own
/// routing - Android gives apps no per-stream control over it.
///
/// Hotplug: the platform reports every device change, and when the change
/// moves where the mic selector resolves (the Bluetooth mic reconnected, the
/// USB mic was pulled) an [AudioDevicesChanged] with capturePathChanged goes
/// out so the wake-word engine reopens capture on the right device instead
/// of holding whatever was true at its last start.
class AudioRoutingManager extends Manager {
  AudioRoutingManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/audio_routing');

  @override
  String get name => 'audio';

  /// Device id the mic selector resolved to when last checked; null when
  /// unresolved (device absent, or no selection).
  int? _micDeviceId;

  Timer? _hotplugDebounce;

  @override
  Future<void> init() async {
    NativeMic.deviceSelector = _settings.get(defs.audioMicDevice);
    await _pushOutput(_settings.get(defs.audioSpeakerDevice));
    _micDeviceId = await _resolveMicId();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'devicesChanged') {
        // Connect/disconnect fires several callbacks in a burst (each
        // profile of a Bluetooth device registers separately); settle
        // before re-resolving.
        _hotplugDebounce?.cancel();
        _hotplugDebounce = Timer(const Duration(milliseconds: 1200), () {
          _onDevicesSettled();
        });
      }
      return null;
    });

    bus.on<SettingChanged>().listen((e) async {
      if (e.key == defs.audioMicDevice.key) {
        // The wake-word manager restarts its engine on this key; the selector
        // must already be current when the new capture opens, which holds
        // because this manager inits (and so subscribes) first.
        NativeMic.deviceSelector = _settings.get(defs.audioMicDevice);
        _micDeviceId = await _resolveMicId();
      } else if (e.key == defs.audioSpeakerDevice.key) {
        _pushOutput(_settings.get(defs.audioSpeakerDevice));
      }
    });

    commands.register(Command(
      name: 'getAudioDevices',
      description:
          'The selectable capture and playback devices, as '
          '{inputs: [{selector, label, type}], outputs: [...]} plus the '
          'current selections (empty selector = automatic).',
      handler: (_) async {
        try {
          final devices =
              await _channel.invokeMapMethod<String, Object?>('list');
          return CommandResult.ok({
            ...?devices,
            'outputs': _annotateOutputs(devices?['outputs']),
            'micSelected': _settings.get(defs.audioMicDevice),
            'speakerSelected': _settings.get(defs.audioSpeakerDevice),
          });
        } on PlatformException catch (e) {
          return CommandResult.fail('audio device listing failed: $e');
        }
      },
    ));
  }

  /// Classic Bluetooth cannot run its hi-fi profile while the same
  /// headset's call link carries the mic, so with a Bluetooth mic selected
  /// that headset's A2DP output is guaranteed silence. Say so on the row
  /// instead of letting the user discover it.
  Object? _annotateOutputs(Object? outputs) {
    if (outputs is! List) return outputs;
    final mic = _settings.get(defs.audioMicDevice).split('|');
    if (mic.length < 2 || mic[0] != '7') return outputs;
    final micAddress = mic[1];
    return [
      for (final o in outputs)
        if (o is Map &&
            '${o['type']}' == '8' &&
            '${o['selector']}'.split('|').elementAtOrNull(1) == micAddress)
          {...o, 'label': '${o['label']} (unavailable with the Bluetooth microphone)'}
        else
          o,
    ];
  }

  Future<void> _onDevicesSettled() async {
    // Dropdowns refresh on any change; the engine restart is reserved for
    // an actual move of the capture path.
    final id = await _resolveMicId();
    final moved =
        id != _micDeviceId && _settings.get(defs.audioMicDevice).isNotEmpty;
    _micDeviceId = id;
    if (moved) {
      log.info(
          name,
          id == null
              ? 'selected microphone disappeared; capture falls back'
              : 'selected microphone (re)appeared; capture moves to it');
    }
    bus.publish(AudioDevicesChanged(capturePathChanged: moved));
  }

  Future<int?> _resolveMicId() async {
    final selector = _settings.get(defs.audioMicDevice);
    if (selector.isEmpty) return null;
    try {
      return await _channel
          .invokeMethod<int>('resolveInput', {'selector': selector});
    } on PlatformException {
      return null;
    }
  }

  Future<void> _pushOutput(String selector) async {
    try {
      await _channel.invokeMethod<void>('setOutput', {'selector': selector});
    } on PlatformException catch (e) {
      log.warn(name, 'speaker selection failed to apply: $e');
    }
  }

  @override
  Future<void> dispose() async {
    _hotplugDebounce?.cancel();
  }
}
