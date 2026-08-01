import 'dart:async';

import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'gesture_mappings.dart';

/// Configurable gestures (issue #99): the action half.
///
/// KioskLock/GestureEngine detect the configured triggers natively and the
/// kiosk manager relays each hit as a [GestureDetected] with the mapping
/// id. This manager owns the other side: it resolves the id against
/// gestures.mappings and runs the mapped action. Everything is a
/// registered command (or a settings write), so a gesture can do exactly
/// what the remote admin and MQTT can.
class GesturesManager extends Manager {
  GesturesManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  StreamSubscription<GestureDetected>? _sub;

  @override
  String get name => 'gestures';

  @override
  Future<void> init() async {
    _sub = bus.on<GestureDetected>().listen(_onGesture);
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
  }

  Future<void> _onGesture(GestureDetected e) async {
    final mappings = decodeGestureMappings(_settings.get(defs.gestureMappings));
    GestureMapping? mapping;
    for (final m in mappings) {
      if (m.id == e.id) {
        mapping = m;
        break;
      }
    }
    if (mapping == null) {
      // A stale trigger: the mapping changed under an armed Activity and
      // the fresh apply has not landed yet.
      log.warn(name, 'gesture ${e.id} has no mapping');
      return;
    }
    log.info(
      name,
      'gesture ${describeGestureTrigger(mapping.trigger)}: '
      '${describeGestureAction(mapping.action)}',
    );
    await runGestureAction(mapping.action);
  }

  /// Run one action object. Public so the editors' "Try it" affordances
  /// (device and remote) can exercise an action without a gesture.
  Future<void> runGestureAction(Map<String, Object?> action) async {
    final a = action;
    switch ('${a['type']}') {
      case 'navigate':
        await _run('haNavigate', {'path': a['path']});
      case 'url':
        await _run('showLinkPage', {'url': a['url']});
      case 'camera_view':
        if (a['mode'] == 'hide') {
          await _run('hideCameraView', const {});
        } else {
          await _run('showCameraView', {'viewId': a['viewId'] ?? ''});
        }
      case 'sendspin_player':
        // Show only: the fling on the card is already the way to hide it.
        await _settings.set(defs.sendspinShowPlayer, true);
      case 'launch_app':
        await _run('launchApp', {'package': a['package']});
      case 'open_uri':
        await _run('openUri', {'uri': a['uri']});
      case 'android_settings':
        await _run('openSystemSettings', const {});
      case 'ha_script':
        await _run('haCallService', {
          'domain': 'script',
          'service': 'turn_on',
          'entity_id': a['entityId'],
        });
      case 'ha_automation':
        await _run('haCallService', {
          'domain': 'automation',
          'service': 'trigger',
          'entity_id': a['entityId'],
        });
      case 'ha_service':
        await _run('haCallService', {
          'domain': a['domain'],
          'service': a['service'],
          if ('${a['entityId'] ?? ''}'.isNotEmpty) 'entity_id': a['entityId'],
          if (a['data'] is Map) 'data': a['data'],
        });
      case 'ha_event':
        await _run('haFireEvent', {
          'event': a['event'],
          if (a['data'] is Map) 'data': a['data'],
        });
      default:
        log.warn(name, 'unknown gesture action: ${a['type']}');
    }
  }

  Future<void> _run(String command, Map<String, Object?> params) async {
    final result = await commands.execute(command, params);
    if (!result.ok) log.warn(name, '$command failed: ${result.error}');
  }
}
