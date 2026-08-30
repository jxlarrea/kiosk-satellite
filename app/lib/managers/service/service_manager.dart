import 'dart:async';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// One thing the Kiosk Satellite Service is keeping the process alive for.
///
/// [id] is the wire name the native service knows (it picks the
/// foreground-service types from these); [title] and [detail] are what the
/// status page shows for it.
class ServiceReason {
  const ServiceReason(this.id, this.title, this.detail);

  final String id;
  final String title;
  final String detail;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'detail': detail};
}

/// The adb command that gives a grant on a device whose Android offers no
/// screen for it, shown in place of the Grant button.
const overlayAdbHint =
    'This device has no settings screen for it. Grant it over adb: '
    'adb shell appops set me.jxl.kiosk_satellite SYSTEM_ALERT_WINDOW allow';
const batteryAdbHint =
    'This device has no settings screen for it. Grant it over adb: '
    'adb shell dumpsys deviceidle whitelist +me.jxl.kiosk_satellite';

/// The Dart side of the Kiosk Satellite Service (KioskSatelliteService.kt),
/// the one foreground service that keeps the app alive.
///
/// The service runs on every install, whatever is switched on: Android
/// freezes cached processes whole and OEM battery managers kill backgrounded
/// apps outright, and either way the Home Assistant session, MQTT and
/// everything else stop together the moment the screen has been off for a
/// while. This manager does not decide whether it runs. It tells the service
/// *why* it runs, as a list of [ServiceReason]s computed from the settings:
/// the status page lists them, the notification names them, and the native
/// side attaches the foreground-service types Android requires for what
/// they do (microphone for listening, camera for motion detection,
/// connectedDevice for BLE scanning). "Home Assistant connection" is always
/// on the list: it is what the service exists for on a clean install.
///
/// The one setting, [defs.serviceCpuAwake], rides along with the reasons.
class ServiceManager extends Manager {
  ServiceManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/background');

  /// A native side that never answers (no plugin, a wedged main thread)
  /// must not hang the status page; it reads as stopped instead.
  static const _nativeTimeout = Duration(seconds: 3);

  final _subs = <StreamSubscription<Object?>>[];

  List<ServiceReason> _reasons = const [];

  /// What the service is currently being kept alive for, in display order.
  /// Computed on demand until the first sync has run, so a reader never
  /// sees an empty list: the base reason is always there.
  List<ServiceReason> get reasons =>
      _reasons.isEmpty ? _reasons = compute() : _reasons;

  /// The settings a reason is read from; a change to any re-syncs.
  static const _watched = {
    'remote.enabled',
    'mqtt.enabled',
    'esphome.enabled',
    'esphome.entities',
    'btproxy.enabled',
    'location.enabled',
    'screensaver.dismiss_on_person',
    'wake_word.enabled',
    'wake_word.background',
    'camera.enabled',
    'kiosk.enabled',
    'lockdown.enabled',
    'browser.auto_reload_on_error',
    'service.cpu_awake',
  };

  @override
  String get name => 'service';

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'getServiceStatus',
        description:
            'The Kiosk Satellite Service, the foreground service that keeps '
            'the app alive with the screen off: whether it is running and '
            'holds its foreground exemption, what it is running for, the '
            'foreground-service types it declares, its Wi-Fi and CPU locks, '
            'and which OS grants it needs right now.',
        handler: (_) async => CommandResult.ok(await status()),
      ),
    );
    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        if (_watched.contains(e.key)) unawaited(sync());
      }),
    );
    await sync();
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// The reasons the current settings call for. Pure, so tests can read it
  /// off a settings store without a platform.
  List<ServiceReason> compute() {
    final s = _settings;
    return [
      const ServiceReason(
        'sessions',
        'Home Assistant connection',
        'Keeps the dashboard session and its websocket open while the '
            'screen is off.',
      ),
      if (s.get(defs.wakeWordEnabled) && s.get(defs.wakeWordBackground))
        const ServiceReason(
          'listening',
          'Background listening',
          'Keeps the wake word engine and its microphone running behind '
              'other apps.',
        ),
      if (s.get(defs.esphomeEnabled))
        const ServiceReason(
          'esphome',
          'ESPHome server',
          'Keeps the ESPHome API server answering Home Assistant.',
        ),
      if (s.get(defs.esphomeEnabled) && s.get(defs.btproxyEnabled))
        const ServiceReason(
          'bluetooth',
          'Bluetooth proxy',
          'Keeps Bluetooth scanning running while the app is not on screen.',
        ),
      if (s.get(defs.esphomeEnabled) &&
          s.get(defs.esphomeEntities) &&
          s.get(defs.locationEnabled))
        const ServiceReason(
          'location',
          'Location sensors',
          'Keeps GPS fixes arriving while the screen is off or another app '
              'is in front.',
        ),
      if (s.get(defs.screensaverDismissOnPerson))
        const ServiceReason(
          'person',
          'Person detection',
          "Keeps reading the device's person sensor while another app is "
              'in front.',
        ),
      if (s.get(defs.mqttEnabled))
        const ServiceReason(
          'mqtt',
          'MQTT',
          'Keeps the broker session, and the entities on it, available.',
        ),
      if (s.get(defs.cameraEnabled))
        const ServiceReason(
          'camera',
          'Camera',
          'Keeps the camera usable after the panel powers off, for motion '
              'and face detection.',
        ),
      if (s.get(defs.remoteEnabled))
        const ServiceReason(
          'remote',
          'Remote administration',
          'Keeps the admin web server answering.',
        ),
      if (s.get(defs.kioskEnabled) || s.get(defs.lockdownEnabled))
        const ServiceReason(
          'kiosk',
          'Kiosk protections',
          'Relaunches the kiosk when it is closed from recents or crashes.',
        ),
    ];
  }

  /// Which OS grants the service needs for what it is doing right now,
  /// keyed like SystemPermissions. `true` means a missing grant breaks
  /// something that is switched on; `false` means the grant only matters
  /// for a feature that is off. Both UIs draw the permission rows from
  /// this, so they agree.
  Map<String, bool> neededGrants() {
    final ids = {for (final r in _reasons) r.id};
    return {
      // Doze is what stops the connections the service exists for; nothing
      // has to be switched on for this one to matter.
      'batteryUnrestricted': true,
      // The service runs without it, but a kiosk that may be listening to
      // a room has to be able to say so: the notification is part of the
      // deal, so its grant is required like the exemption itself.
      'notification': true,
      'displayOverOtherApps':
          ids.contains('kiosk') || _settings.get(defs.autoReloadOnError),
      'microphone': ids.contains('listening'),
      'camera': ids.contains('camera'),
      'bluetooth': ids.contains('bluetooth'),
    };
  }

  /// Recompute the reasons and push them, with the wake-lock preference,
  /// to the native service. Best-effort: off Android (tests, desktop) there
  /// is no service, and nothing is broken by not keeping it alive.
  Future<void> sync() async {
    final next = compute();
    final ids = [for (final r in next) r.id];
    final changed = ids.join(',') != [for (final r in _reasons) r.id].join(',');
    _reasons = next;
    try {
      await _channel
          .invokeMethod('setServiceReasons', {
            'reasons': ids,
            'cpuAwake': _settings.get(defs.serviceCpuAwake),
          })
          .timeout(_nativeTimeout);
      if (changed) log.info(name, 'keeping alive for: ${ids.join(', ')}');
    } catch (e) {
      log.warn(name, 'service unavailable: $e');
    }
  }

  /// Everything the status page shows: the native service's own report,
  /// the reasons with their labels, and the grants they call for.
  Future<Map<String, Object?>> status() async {
    var native = const <String, Object?>{};
    try {
      final raw = await _channel
          .invokeMethod<Map<Object?, Object?>>('serviceStatus')
          .timeout(_nativeTimeout);
      if (raw != null) native = raw.cast<String, Object?>();
    } catch (_) {}
    return {
      'running': native['running'] == true,
      'foreground': native['foreground'] == true,
      'types': [for (final t in (native['types'] as List?) ?? const []) '$t'],
      'cpuAwake': _settings.get(defs.serviceCpuAwake),
      'cpuLockHeld': native['cpuLockHeld'] == true,
      'wifiLockHeld': native['wifiLockHeld'] == true,
      'screenInteractive': native['screenInteractive'] != false,
      'uptimeMs': native['uptimeMs'],
      'notificationsEnabled': native['notificationsEnabled'] != false,
      'error': native['error'],
      'reasons': [for (final r in _reasons) r.toJson()],
      'grants': neededGrants(),
    };
  }
}
