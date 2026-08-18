import 'dart:async';

import '../../core/command_registry.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../../core/logging.dart';

/// The kiosk entities served over the ESPHome native API (the same
/// connection the Bluetooth proxy holds), issue: retire the MQTT broker
/// requirement. This is the Dart half of the pair with the native
/// EntityHub: it owns WHAT exists and what values and commands mean; the
/// native side owns the wire.
///
/// Phase 1 is a deliberately small starter set proving every command shape
/// (switch, number, button) and every sensor family; the rest of the MQTT
/// catalog migrates in a follow-up pass.
///
/// Entity object ids are permanent API: they become Home Assistant entity
/// ids (`sensor.<device>_battery`) and survive in users' automations.
/// Never rename one casually.
class EspEntitySurface {
  EspEntitySurface(this.bus, this.commands, this.log);

  final EventBus bus;
  final CommandRegistry commands;
  final Logger log;

  static const _pollInterval = Duration(seconds: 60);

  /// Sends one entity's fresh value to the native hub; set while attached.
  Future<void> Function(String objectId, Object? value)? _push;
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _poll;

  /// Descriptors for the native side, in display order. Categories:
  /// 0 = primary, 1 = config, 2 = diagnostic (api.proto EntityCategory).
  List<Map<String, Object?>> descriptors() => [
        {
          'type': 'switch',
          'objectId': 'screensaver',
          'name': 'Screensaver',
          'icon': 'mdi:sleep',
        },
        {
          'type': 'number',
          'objectId': 'screen_brightness',
          'name': 'Screen brightness',
          'icon': 'mdi:brightness-6',
          'min': 0,
          'max': 100,
          'step': 1,
          'unit': '%',
          'mode': 2, // slider
        },
        {
          'type': 'button',
          'objectId': 'reload',
          'name': 'Reload dashboard',
          'icon': 'mdi:refresh',
        },
        {
          'type': 'sensor',
          'objectId': 'battery',
          'name': 'Battery',
          'deviceClass': 'battery',
          'unit': '%',
          'stateClass': 1, // measurement
          'category': 2,
        },
        {
          'type': 'binary_sensor',
          'objectId': 'charging',
          'name': 'Charging',
          'deviceClass': 'battery_charging',
          'category': 2,
        },
        {
          'type': 'sensor',
          'objectId': 'uptime',
          'name': 'Uptime',
          'icon': 'mdi:timer-outline',
          'deviceClass': 'duration',
          'unit': 's',
          'stateClass': 2, // total_increasing
          'category': 2,
        },
        {
          'type': 'text_sensor',
          'objectId': 'ip_address',
          'name': 'IP address',
          'icon': 'mdi:ip-network',
          'category': 2,
        },
      ];

  /// Starts serving values: initial snapshot, change events, slow poll.
  void attach(Future<void> Function(String, Object?) push) {
    _push = push;
    _subs.add(bus.on<ScreensaverStateChanged>().listen(
        (e) => _send('screensaver', e.active)));
    _subs.add(bus.on<BrightnessChanged>().listen(
        (e) => _send('screen_brightness', (e.level * 100).round())));
    _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    _refresh();
    _sendBrightness();
    _send('screensaver', false);
  }

  void detach() {
    _push = null;
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _poll?.cancel();
    _poll = null;
  }

  /// A command from Home Assistant landed (via the native hub). State
  /// echoes ride the ordinary change events the acted-on managers publish,
  /// so HA sees the real outcome, not an optimistic assumption.
  Future<void> handleCommand(String objectId, Object? value) async {
    switch (objectId) {
      case 'screensaver':
        await commands.execute(
            value == true ? 'startScreensaver' : 'stopScreensaver', const {});
      case 'screen_brightness':
        final level = ((value as num?) ?? 0).clamp(0, 100) / 100.0;
        await commands.execute('setBrightness', {'level': level});
      case 'reload':
        await commands.execute('reload', const {});
      default:
        log.warn('btproxy', 'entity command for unknown id $objectId');
    }
  }

  Future<void> _send(String objectId, Object? value) async {
    try {
      await _push?.call(objectId, value);
    } catch (_) {}
  }

  Future<void> _sendBrightness() async {
    final result = await commands.execute('getBrightness', const {});
    final level = (result.data as num?)?.toDouble();
    if (result.ok && level != null) {
      await _send('screen_brightness', (level * 100).round());
    }
  }

  /// The slow-moving values, refreshed on the poll cadence (matching the
  /// MQTT sensors so both surfaces agree while they coexist).
  Future<void> _refresh() async {
    final stats = await commands.execute('getStats', const {});
    final data = stats.data;
    if (stats.ok && data is Map) {
      final battery = (data['battery'] as num?)?.toInt();
      if (battery != null) await _send('battery', battery);
      await _send('charging', data['charging'] == true);
    }
    final up = await commands.execute('getUptime', const {});
    if (up.ok && up.data is Map) {
      final app = ((up.data as Map)['app'] as num?)?.toInt();
      if (app != null) await _send('uptime', app);
    }
    final ips = await commands.execute('getIpAddresses', const {});
    if (ips.ok && ips.data is Map) {
      final byInterface = (ips.data as Map)['ipv4'];
      if (byInterface is Map) {
        final first = byInterface.values
            .whereType<List>()
            .expand((addresses) => addresses)
            .map((a) => '$a')
            .where((a) => a.isNotEmpty)
            .toList();
        if (first.isNotEmpty) await _send('ip_address', first.first);
      }
    }
  }
}
