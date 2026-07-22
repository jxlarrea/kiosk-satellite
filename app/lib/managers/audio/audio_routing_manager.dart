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
/// pushed to the platform, which pins the SendSpin player's AudioTrack and
/// re-routes it live on change. Dashboard audio (Voice Satellite TTS, chimes)
/// plays in the WebView and follows the system's own routing - Android gives
/// apps no per-stream control over it.
class AudioRoutingManager extends Manager {
  AudioRoutingManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/audio_routing');

  @override
  String get name => 'audio';

  @override
  Future<void> init() async {
    NativeMic.deviceSelector = _settings.get(defs.audioMicDevice);
    await _pushOutput(_settings.get(defs.audioSpeakerDevice));

    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.audioMicDevice.key) {
        // The wake-word manager restarts its engine on this key; the selector
        // must already be current when the new capture opens, which holds
        // because this manager inits (and so subscribes) first.
        NativeMic.deviceSelector = _settings.get(defs.audioMicDevice);
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
            'micSelected': _settings.get(defs.audioMicDevice),
            'speakerSelected': _settings.get(defs.audioSpeakerDevice),
          });
        } on PlatformException catch (e) {
          return CommandResult.fail('audio device listing failed: $e');
        }
      },
    ));
  }

  Future<void> _pushOutput(String selector) async {
    try {
      await _channel.invokeMethod<void>('setOutput', {'selector': selector});
    } on PlatformException catch (e) {
      log.warn(name, 'speaker selection failed to apply: $e');
    }
  }
}
