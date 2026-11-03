import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/echo_image_settings.dart';
import '../settings/settings_manager.dart';
import '../wake_word/vsww/native_mic.dart';
import 'mic_hub.dart';

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
///
/// Voice interactions hold transient audio focus, so other apps' music
/// ducks under a turn, an alarm or an intercom call the way Android apps
/// expect. Media playback, ours included, is not an interaction.
class AudioRoutingManager extends Manager {
  AudioRoutingManager(
    super.bus,
    super.commands,
    super.log,
    this._settings, {
    this.systemBuild = _fingerprint,
  });

  final SettingsManager _settings;

  /// The system build (Build.FINGERPRINT), which Automatic's echo
  /// cancellation verdict holds for. Tests swap it.
  final Future<String?> Function() systemBuild;

  static Future<String?> _fingerprint() async =>
      (await DeviceInfoPlugin().androidInfo).fingerprint;

  /// Internal key holding the system build Automatic's verdict was made on.
  static const echoVerdictBuild = 'audio.echo_method_build';

  static const _channel = MethodChannel('kiosk_satellite/audio_routing');

  @override
  String get name => 'audio';

  /// Device id the mic selector resolved to when last checked; null when
  /// unresolved (device absent, or no selection).
  int? _micDeviceId;

  Timer? _hotplugDebounce;

  /// Interaction reasons in progress. Focus is held while any remain.
  final _interactions = <String>{};

  @override
  Future<void> init() async {
    NativeMic.onWarning = (warning) => log.warn('mic', warning);
    await _retestEchoAfterSystemUpdate();
    NativeMic.deviceSelector = _settings.get(defs.audioMicDevice);
    _pushCaptureTuning();
    await _pushOutput(_settings.get(defs.audioSpeakerDevice));
    _micDeviceId = await _resolveMicId();

    _channel.setMethodCallHandler((call) async {
      // The echo canceller (SoftwareEcho.kt): which engine runs, each sound
      // it cancelled, Automatic's test and its verdict.
      if (call.method == 'echoLog' && call.arguments is String) {
        log.info('mic', call.arguments as String);
      } else if (call.method == 'echoMethodDetected' &&
          call.arguments is String) {
        await _echoMethodDetected(call.arguments as String);
      }
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
        // With the capture shared (clap detection can hold it without the
        // engine), the engine's own restart no longer guarantees a fresh
        // session; the hub reopens it with the values just pushed.
        await MicHub.instance.bounce();
      } else if (e.key == defs.micEchoCancellationMethod.key &&
          defs.isEchoMethodVerdict(e.previous, e.value)) {
        // The canceller already runs what it settled on: the next capture
        // opens with it.
        _pushCaptureTuning();
      } else if (e.key == defs.micCaptureMode.key ||
          e.key == defs.micSoftwareEchoCancellation.key ||
          e.key == defs.micEchoCancellationMethod.key ||
          e.key == defs.micNoiseSuppression.key ||
          e.key == defs.micGainDb.key ||
          e.key == defs.micChannel.key ||
          e.key == defs.micCaptureFormat.key) {
        // Same contract as the device selector above: the values must be
        // current before the wake-word manager reopens capture on this key.
        _pushCaptureTuning();
        await MicHub.instance.bounce();
      } else if (e.key == defs.audioSpeakerDevice.key) {
        _pushOutput(_settings.get(defs.audioSpeakerDevice));
      }
    });

    bus.on<VoiceInteractionChanged>().listen((e) {
      if (e.reason == 'media') return;
      final wasActive = _interactions.isNotEmpty;
      if (e.active) {
        _interactions.add(e.reason);
      } else {
        _interactions.remove(e.reason);
      }
      final active = _interactions.isNotEmpty;
      if (active == wasActive) return;
      unawaited(
        _channel.invokeMethod<void>('holdFocus', {'active': active}).catchError(
          (Object error) {
            log.warn(name, 'audio focus change failed: $error');
          },
        ),
      );
    });

    commands.register(
      Command(
        name: 'getAudioDevices',
        description:
            'The selectable capture and playback devices, as '
            '{inputs: [{selector, label, type}], outputs: [...]} plus the '
            'current selections (empty selector = automatic).',
        handler: (_) async {
          try {
            final devices = await _channel.invokeMapMethod<String, Object?>(
              'list',
            );
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
      ),
    );
    commands.register(
      Command(
        name: 'getEchoCancellerState',
        description:
            'The echo canceller this kiosk last ran, whatever the setting '
            'says: {engine: gtcrn | aec3 | "" (none yet), why: picked | '
            'detected | testing | unavailable, running}.',
        quiet: true,
        handler: (_) async {
          try {
            final state = await _channel.invokeMapMethod<String, Object?>(
              'echoState',
            );
            return CommandResult.ok(state ?? const {});
          } on PlatformException catch (e) {
            return CommandResult.fail('echo canceller state failed: $e');
          } on MissingPluginException {
            return const CommandResult.fail('no echo canceller here');
          }
        },
      ),
    );
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
          {
            ...o,
            'label':
                '${o['label']} (unavailable with the Bluetooth microphone)',
          }
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
            : 'selected microphone (re)appeared; capture moves to it',
      );
      // A capture held open only by the clap detector has no engine restart
      // to move it; reopen it here so it follows the device.
      await MicHub.instance.bounce();
    }
    bus.publish(AudioDevicesChanged(capturePathChanged: moved));
  }

  Future<int?> _resolveMicId() async {
    final selector = _settings.get(defs.audioMicDevice);
    if (selector.isEmpty) return null;
    try {
      return await _channel.invokeMethod<int>('resolveInput', {
        'selector': selector,
      });
    } on PlatformException {
      return null;
    }
  }

  /// Hand the Microphone settings to the capture side. Nothing is applied
  /// until the next capture opens, which is the point: the platform fixes
  /// the source, the gain and the effect chain when the session is created.
  void _pushCaptureTuning() {
    NativeMic.captureMode = _settings.get(defs.micCaptureMode);
    NativeMic.softwareEchoCancellation = _settings.get(
      defs.micSoftwareEchoCancellation,
    );
    NativeMic.echoMethod = _settings.get(defs.micEchoCancellationMethod);
    NativeMic.noiseSuppression = _settings.get(defs.micNoiseSuppression);
    // On top of the Echo images' base gain for the raw microphone.
    NativeMic.gainDb =
        _settings.get(defs.micGainDb) + EchoImageSettings.micGainBaseDb;
    NativeMic.channel = _settings.get(defs.micChannel);
    NativeMic.captureFormat = _settings.get(defs.micCaptureFormat);
  }

  /// Automatic settled on [method] ('gtcrn' or 'aec3') for this device.
  /// A pick made meanwhile wins.
  Future<void> _echoMethodDetected(String method) async {
    if (_settings.get(defs.micEchoCancellationMethod) != 'auto') return;
    String? build;
    try {
      build = await systemBuild();
    } catch (_) {}
    await _settings.setInternal(echoVerdictBuild, build ?? '');
    await _settings.set(
      defs.micEchoCancellationMethod,
      'auto:$method',
      source: 'echo cancellation test',
    );
  }

  /// A system update can change the microphone path, as the Echo images
  /// did when they stopped running Amazon's own echo canceller ahead of
  /// this one, so Automatic's verdict from another build is tested again.
  Future<void> _retestEchoAfterSystemUpdate() async {
    final method = _settings.get(defs.micEchoCancellationMethod);
    if (!method.startsWith('auto:')) return;
    String? build;
    try {
      build = await systemBuild();
    } catch (_) {
      return;
    }
    if (build == null || build == _settings.internal(echoVerdictBuild)) return;
    log.info('mic', 'system updated: testing the echo canceller again');
    await _settings.set(
      defs.micEchoCancellationMethod,
      'auto',
      source: 'system update',
    );
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
