import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';

import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../../core/logging.dart';
import '../update/system_update_source.dart';
import 'definitions.dart' as defs;
import 'settings_manager.dart';

/// Settings the Echo images (`jxlarrea/lineageos-echo-kiosk-satellite`)
/// hold at one value on every start, unlike EchoDefaults
/// (echo_defaults.dart), which only sets a fresh install's first values.
///
/// The images always record from the raw microphone in the automatic
/// format, so Capture mode and Capture format are hidden
/// from both settings UIs and kept on Raw microphone and Automatic. Echo
/// cancellation and Noise suppression are hidden too and kept on and off:
/// Amazon's own echo canceller is out of the raw path, and the suppressor
/// changes what the wake word hears. A value stored before, imported or
/// pushed by Fleet goes back, at boot and on any later change, the same way
/// HeadlessSettings (headless_settings.dart) pins its values.
///
/// The raw microphone also comes in quieter than Amazon's processing used
/// to deliver it, so each device has a base gain under Microphone gain
/// ([micGainBaseDb]): 24 dB on both Echo Show 8 generations and 20 dB on
/// both Echo Show 5 generations, the make-up gain of their old paths, and
/// 5 dB on the Echo Dot. The slider stays the user's and moves from there, so
/// its 0 dB is the device's right level. An Echo whose speaker needs it also
/// starts with an equalizer of its own and the volumes that go with it
/// ([equalizerPresets]), set once and the user's from then on. A gain set for the old path would add on top, so
/// the first start with the base gain puts the slider back to 0 dB once
/// ([gainResetMarker]). The kiosk applies the gain after the echo
/// canceller, so the echo it cancels stays the same.
///
/// The image is told apart by its updater (SystemUpdateBridge.kt): `biscuit`
/// is the Echo Dot image and `echo` an Echo Show image. The Shows share one
/// updater, so the base gain goes by the device's codename: `crown` is the
/// 1st generation Echo Show 8 and `athena` the 2nd generation one, `cronos`
/// the 2nd generation Echo Show 5 and `checkers` the 1st generation one.
class EchoImageSettings {
  EchoImageSettings(
    this._settings,
    this._bus,
    this._log, {
    this.updater = RomSystemUpdateSource.detect,
    this.codename = _codename,
  });

  final SettingsManager _settings;
  final EventBus _bus;
  final Logger _log;

  /// The ROM's updater (SystemUpdateBridge.kt). Tests swap it.
  final Future<String?> Function() updater;

  /// The device's codename (ro.product.device). Tests swap it.
  final Future<String?> Function() codename;

  static Future<String?> _codename() async =>
      (await DeviceInfoPlugin().androidInfo).device;

  StreamSubscription<SettingChanged>? _sub;

  /// The values each updater pins.
  static Map<defs.SettingDef<Object>, Object> forUpdater(String? updater) =>
      switch (updater) {
        'biscuit' || 'echo' => {
          defs.micCaptureMode: 'mic',
          defs.micCaptureFormat: 'auto',
          defs.micSoftwareEchoCancellation: true,
          defs.micNoiseSuppression: false,
        },
        _ => const {},
      };

  /// The base gain of each Echo by codename.
  static const baseGainDb = {
    'crown': 24,
    'athena': 24,
    'cronos': 20,
    'checkers': 20,
    'biscuit': 5,
  };

  /// The equalizer each Echo starts with, by codename, set by ear over our
  /// own measurement of the speaker. The Echo Dot's driver is 8 to 11 dB
  /// down from 315 to 500 Hz and 10 dB up at 2.5 to 3 kHz against 1 kHz
  /// (pink noise at 80% volume, recorded 30 cm away), which sounds thin.
  /// Its preamp is off: the 3 kHz cut already takes more level out than the
  /// boosts add, and with the preamp on the Dot was too quiet. The preset
  /// carries the media and intercom volumes it was set at, so a Dot that
  /// gets the equalizer on an update moves to those levels with it.
  static const equalizerPresets =
      <String, Map<defs.SettingDef<Object>, Object>>{
        'biscuit': {
          defs.equalizerEnabled: true,
          defs.equalizerBand1: 1,
          defs.equalizerBand2: 2,
          defs.equalizerBand3: -3,
          defs.equalizerBand4: -7,
          defs.equalizerBand5: -1,
          defs.equalizerPreamp: false,
          // The levels that go with it, under a master and assistant
          // volume of 100%.
          defs.mediaVolume: 85,
          defs.intercomVolume: 100,
        },
      };

  /// Internal key set once the device's equalizer preset was considered.
  static const equalizerMarker = 'echo.equalizer_preset';

  /// The gain this device adds under Microphone gain
  /// (AudioRoutingManager): 0 anywhere but the Echo images.
  static num micGainBaseDb = 0;

  /// Internal key set once the slider went back to 0 dB for the base gain.
  static const gainResetMarker = 'echo.gain_reset';

  /// Before any manager reads its settings and any page renders.
  Future<void> init() async {
    String? rom;
    try {
      rom = await updater();
    } catch (_) {
      // No native side (a test, another platform): not an Echo image.
      return;
    }
    final pinned = forUpdater(rom);
    if (pinned.isEmpty) return;
    String? device;
    try {
      device = await codename();
      micGainBaseDb = baseGainDb[device] ?? 0;
    } catch (_) {
      // Without a codename the gain has no base.
    }
    await _presetEqualizer(device);
    if (micGainBaseDb != 0 && _settings.internal(gainResetMarker).isEmpty) {
      if (_settings.get(defs.micGainDb) != 0) {
        _log.info(
          'settings',
          '${defs.micGainDb.key} goes back to 0 dB once for the Echo '
              'image\'s $micGainBaseDb dB base gain',
        );
        await _settings.set(defs.micGainDb, 0, source: 'Echo image');
      }
      await _settings.setInternal(gainResetMarker, '1');
    }
    for (final entry in pinned.entries) {
      defs.deviceHiddenKeys.add(entry.key.key);
      defs.devicePinnedKeys.add(entry.key.key);
      await _pin(entry.key, entry.value);
    }
    _sub = _bus.on<SettingChanged>().listen((e) {
      for (final entry in pinned.entries) {
        if (entry.key.key == e.key) unawaited(_pin(entry.key, entry.value));
      }
    });
  }

  /// Set the device's equalizer preset and its volumes, once: on a fresh
  /// install and on the first start of a version that has one. With an
  /// equalizer the user already set, both stay theirs, and so does anything
  /// they change afterwards.
  Future<void> _presetEqualizer(String? device) async {
    final preset = equalizerPresets[device];
    if (preset == null || _settings.internal(equalizerMarker).isNotEmpty) {
      return;
    }
    final untouched =
        !_settings.get(defs.equalizerEnabled) &&
        defs.equalizerBands.every((band) => _settings.get(band) == 0);
    if (untouched) {
      for (final entry in preset.entries) {
        await _settings.set(entry.key, entry.value, source: 'Echo image');
      }
      _log.info('settings', 'set the Echo image\'s equalizer for $device');
    }
    await _settings.setInternal(equalizerMarker, device!);
  }

  Future<void> _pin(defs.SettingDef<Object> def, Object value) async {
    if (_settings.get(def) == value) return;
    _log.info('settings', '${def.key} is $value on the Echo image');
    await _settings.set(def, value, source: 'Echo image');
  }

  Future<void> dispose() async => _sub?.cancel();
}
