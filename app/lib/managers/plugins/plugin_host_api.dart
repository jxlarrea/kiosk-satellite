import 'dart:async';
import 'dart:convert';

import '../../core/command_registry.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../browser/dashboard_state.dart';
import '../settings/definitions.dart' as defs;

/// Explicit SDK 1 host surface. Registry additions do not expand plugin access.
class PluginHostApi {
  PluginHostApi(this.commands, EventBus bus, this.sendEvent) {
    _events = bus.stream.listen(_onEvent);
  }

  final CommandRegistry commands;
  final Future<void> Function(Map<String, Object?>) sendEvent;
  late final StreamSubscription<AppEvent> _events;
  final _sessions = <String, _HostSession>{};
  bool _disposed = false;

  static const commandNames = [
    'getHostApi',
    'isScreensaverActive',
    'getScreensaverDue',
    'getScreensaverSuppressed',
    'isScreenOn',
    'getBrightness',
    'getAmbientDisplay',
    'getVolume',
    'getLightLevel',
    'getStats',
    'getUptime',
    'getDeviceInfo',
    'getMotionEnabled',
    'getFaceEnabled',
    'getProximityEnabled',
    'getCameraViewState',
    'getWakeWordState',
    'haStatus',
    'getDashboardState',
  ];
  static const controlNames = [
    'startScreensaver',
    'stopScreensaver',
    'postponeScreensaver',
    'nextScreensaverSlide',
    'previousScreensaverSlide',
    'screenOn',
    'screenOff',
    'showCameraView',
    'hideCameraView',
    'focusCamera',
    'showNowPlaying',
    'hideNowPlaying',
    'sendspinControl',
    'showAppLauncher',
    'hideAppLauncher',
    'showOverlayPage',
    'showLinkPage',
    'hideOverlayPage',
    'showMusicAssistant',
    'loadUrl',
    'loadDashboard',
    'loadStartUrl',
    'haNavigate',
    'reload',
  ];

  static bool validArguments(String name, Map params) {
    if (params.length > 2 ||
        params.entries.any(
          (e) =>
              e.key is! String ||
              (e.key as String).length > 32 ||
              !(e.value is bool ||
                  (e.value is String && (e.value as String).length <= 2048)),
        )) {
      return false;
    }
    bool keys(Set<String> allowed) => params.keys.every(allowed.contains);
    bool text(String key, {bool empty = false}) =>
        params[key] is String &&
        (empty || (params[key] as String).trim().isNotEmpty);
    bool path(String key) =>
        text(key) &&
        RegExp(
          r'^/?[a-zA-Z0-9_-]+(?:/[a-zA-Z0-9_-]+)*$',
        ).hasMatch(params[key] as String);
    switch (name) {
      case 'getBrightness':
        return keys({'panel', 'ceiling'}) &&
            params.values.every((v) => v is bool) &&
            !(params['panel'] == true && params['ceiling'] == true);
      case 'showCameraView':
        return keys({'viewId', 'toggle'}) &&
            text('viewId') &&
            (!params.containsKey('toggle') || params['toggle'] is bool);
      case 'focusCamera':
        return keys({'cameraId'}) &&
            (params.isEmpty || text('cameraId', empty: true));
      case 'sendspinControl':
        return keys({'command'}) &&
            const [
              'play',
              'pause',
              'next',
              'previous',
            ].contains(params['command']);
      case 'showOverlayPage':
      case 'showLinkPage':
      case 'loadUrl':
        if (!keys({'url'}) || !text('url')) return false;
        final uri = Uri.tryParse(params['url'] as String);
        return uri != null &&
            const ['http', 'https'].contains(uri.scheme) &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty;
      case 'loadDashboard':
        return keys({'dashboard'}) && path('dashboard');
      case 'haNavigate':
        return keys({'path'}) && path('path');
      default:
        return params.isEmpty;
    }
  }

  static const eventNames = [
    'screensaver.state',
    'screensaver.countdown',
    'screensaver.view',
    'screen.state',
    'screen.brightness',
    'screen.ambient',
    'device.power',
    'device.network',
    'device.volume',
    'device.light',
    'detection.motion',
    'detection.face',
    'detection.proximity',
    'detection.person',
    'detection.presence',
    'voice.interaction',
    'wakeword.state',
    'wakeword.detected',
    'stopword.detected',
    'camera.view',
    'browser.state',
  ];
  static const _fields = {
    'getLightLevel': ['present', 'lux', 'live'],
    'getStats': ['battery', 'charging', 'cpu', 'temp'],
    'getUptime': ['app', 'network'],
    'getDeviceInfo': [
      'name',
      'model',
      'os',
      'osVersion',
      'sdkInt',
      'appVersion',
      'buildNumber',
      'buildMode',
      'package',
    ],
    'getCameraViewState': ['active', 'viewId', 'viewName', 'focusedCameraId'],
    'getWakeWordState': [
      'available',
      'stopWordAvailable',
      'enabled',
      'active',
      'listening',
      'engine',
      'engineLabel',
      'status',
      'statusLabel',
    ],
    'haStatus': ['configured', 'connected'],
    'getDashboardState': [
      'homeAssistantUrl',
      'startUrl',
      'currentUrl',
      'currentPath',
    ],
  };

  void open(Map args) {
    if (_disposed) return;
    final id = args['id'];
    final token = args['session'];
    if (id is! String || token is! String || token.isEmpty) return;
    final capabilities = args['capabilities'];
    if (capabilities is! List ||
        !capabilities.any((c) => c == 'host.read' || c == 'host.control')) {
      return;
    }
    _sessions.remove(id)?.close();
    _sessions[id] = _HostSession(
      id,
      token,
      capabilities.contains('host.read'),
      capabilities.contains('host.control'),
    );
  }

  void close(Map args) {
    final session = _session(args);
    if (session == null) return;
    _sessions.remove(session.id);
    session.close();
  }

  _HostSession? _session(Map args) {
    final session = _sessions[args['id']];
    return !_disposed && session != null && session.token == args['session']
        ? session
        : null;
  }

  void subscription(Map args) {
    final session = _session(args);
    final name = args['event'];
    if (session == null ||
        !session.canRead ||
        name is! String ||
        !eventNames.contains(name)) {
      return;
    }
    if (args['subscribed'] == true) {
      session.subscriptions.add(name);
    } else {
      session.subscriptions.remove(name);
      session.pending.remove(name);
    }
  }

  Future<Map<String, Object?>> execute(Map args) async {
    final session = _session(args);
    if (session == null) {
      return const CommandResult.fail(
        'Plugin session is no longer active',
      ).toJson();
    }
    final name = args['command'];
    final params = args['arguments'];
    final isControl = controlNames.contains(name);
    if (name is! String ||
        (name != 'getHostApi' &&
            !(session.canRead && commandNames.contains(name)) &&
            !(session.canControl && isControl))) {
      return const CommandResult.fail(
        'Command is not available through this plugin session',
      ).toJson();
    }
    if (params is! Map || !validArguments(name, params)) {
      return const CommandResult.fail(
        'Invalid host command arguments',
      ).toJson();
    }
    if (name == 'getHostApi') {
      return CommandResult.ok({
        'apiVersion': 1,
        'capabilities': [
          if (session.canRead) 'host.read',
          if (session.canControl) 'host.control',
        ],
        'commands': [
          'getHostApi',
          if (session.canRead) ...commandNames.skip(1),
          if (session.canControl) ...controlNames,
        ],
        'events': session.canRead ? eventNames : <String>[],
      }).toJson();
    }
    try {
      final result = await commands
          .as('plugin:${session.id}')
          .execute(
            name,
            name == 'screenOff'
                ? {'prompt': false}
                : Map<String, Object?>.from(params),
          )
          .timeout(const Duration(seconds: 8));
      if (_session(args) != session) {
        return const CommandResult.fail(
          'Plugin session is no longer active',
        ).toJson();
      }
      if (!result.ok) {
        return const CommandResult.fail(
          'KS could not complete this command. The feature may be unavailable.',
        ).toJson();
      }
      if (isControl) {
        // Camera results contain internal state. Controls return only documented
        // scalar outcomes, with state available separately through host.read.
        return CommandResult.ok(
          const [
                'nextScreensaverSlide',
                'previousScreensaverSlide',
                'haNavigate',
              ].contains(name)
              ? result.data == true
              : null,
        ).toJson();
      }
      Object? data = result.data;
      final fields = _fields[name];
      if (fields != null) {
        if (data is! Map) {
          return const CommandResult.fail(
            'KS returned an unexpected read response',
          ).toJson();
        }
        data = {for (final key in fields) key: data[key]};
        if (data.values.any((value) => !_scalar(value))) {
          return const CommandResult.fail(
            'KS returned an unexpected read response',
          ).toJson();
        }
      } else if (!(switch (name) {
        'getBrightness' => data == null || data is num,
        'getVolume' => data is num,
        'getScreensaverDue' => data == null || data is String,
        _ => data is bool,
      })) {
        return const CommandResult.fail(
          'KS returned an unexpected read response',
        ).toJson();
      }
      if (name == 'getDashboardState') {
        final state = data as Map;
        data = DashboardState.fromUrls(
          homeAssistantUrl: state['homeAssistantUrl'],
          startUrl: state['startUrl'],
          currentUrl: state['currentUrl'],
        );
      }
      if (utf8.encode(jsonEncode(data)).length > 32768) {
        return const CommandResult.fail('Read response is too large').toJson();
      }
      return CommandResult.ok(data).toJson();
    } catch (_) {
      return const CommandResult.fail(
        'KS command failed or timed out',
      ).toJson();
    }
  }

  static (String, Map<String, Object?>)? project(
    AppEvent event,
  ) => switch (event) {
    UrlChanged _ => ('browser.state', {}),
    PageChanged _ => ('browser.state', {}),
    SettingChanged e
        when e.key == defs.haUrl.key || e.key == defs.startUrl.key =>
      ('browser.state', {}),
    ScreensaverStateChanged e => ('screensaver.state', {'active': e.active}),
    ScreensaverCountdownChanged e => (
      'screensaver.countdown',
      {'due': e.due?.toUtc().toIso8601String()},
    ),
    ScreensaverViewChanged e => ('screensaver.view', {'view': e.view}),
    ScreenStateChanged e => ('screen.state', {'on': e.on, 'source': e.source}),
    BrightnessChanged e => (
      'screen.brightness',
      {'level': e.level, 'panel': e.panel},
    ),
    AmbientDisplayChanged e => ('screen.ambient', {'on': e.on}),
    PowerChanged e => ('device.power', {'charging': e.charging}),
    NetworkStateChanged e => ('device.network', {'up': e.up}),
    VolumeChanged _ => ('device.volume', {}),
    LightLevelChanged e => ('device.light', {'lux': e.lux}),
    MotionDetected _ => ('detection.motion', {}),
    FaceDetected _ => ('detection.face', {}),
    ProximityDetected e => ('detection.proximity', {'held': e.held}),
    PersonDetected e => ('detection.person', {'held': e.held}),
    PersonSensorChanged e => ('detection.presence', {'present': e.present}),
    VoiceInteractionChanged e => (
      'voice.interaction',
      {'active': e.active, 'source': e.source.name},
    ),
    WakeWordStateChanged e => (
      'wakeword.state',
      {'active': e.active, 'listening': e.listening, 'muted': e.muted},
    ),
    WakeWordDetected e => (
      'wakeword.detected',
      {'model': e.model, 'phrase': e.phrase},
    ),
    StopWordDetected _ => ('stopword.detected', {}),
    CameraViewStateChanged e => (
      'camera.view',
      {
        'active': e.active,
        'viewId': e.viewId,
        'viewName': e.viewName,
        'focusedCameraId': e.focusedCameraId,
      },
    ),
    _ => null,
  };

  void _onEvent(AppEvent event) {
    final projected = project(event);
    if (projected == null) return;
    if (projected.$2.values.any((value) => !_scalar(value)) ||
        utf8.encode(jsonEncode(projected.$2)).length > 32000) {
      return;
    }
    for (final session in _sessions.values) {
      if (!session.subscriptions.contains(projected.$1)) continue;
      session.pending[projected.$1] = {
        ...projected.$2,
        'time': DateTime.now().toUtc().toIso8601String(),
      };
      _schedule(session);
    }
  }

  void _schedule(_HostSession session) {
    if (session.closed ||
        session.sending ||
        session.timer != null ||
        session.pending.isEmpty) {
      return;
    }
    session.timer = Timer(const Duration(milliseconds: 100), () async {
      session.timer = null;
      session.sending = true;
      final batch = Map.of(session.pending);
      session.pending.clear();
      try {
        for (final entry in batch.entries) {
          if (session.closed) break;
          if (!session.subscriptions.contains(entry.key)) continue;
          await sendEvent({
            'id': session.id,
            'session': session.token,
            'event': entry.key,
            'payload': entry.value,
          });
        }
      } catch (_) {
        // Stopping the host or plugin can cancel an event delivery.
      } finally {
        session.sending = false;
        _schedule(session);
      }
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final session in _sessions.values) {
      session.close();
    }
    _sessions.clear();
    await _events.cancel();
  }

  static bool _scalar(Object? value) =>
      value == null ||
      value is String ||
      value is bool ||
      (value is num && value.isFinite);
}

class _HostSession {
  _HostSession(this.id, this.token, this.canRead, this.canControl);
  final bool canRead;
  final bool canControl;
  final String id;
  final String token;
  final subscriptions = <String>{};
  final pending = <String, Map<String, Object?>>{};
  Timer? timer;
  bool sending = false;
  bool closed = false;
  void close() {
    closed = true;
    timer?.cancel();
    pending.clear();
    subscriptions.clear();
  }
}
