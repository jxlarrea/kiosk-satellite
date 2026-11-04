import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/event_bus.dart';
import '../../core/events.dart';
import '../browser/dashboard_state.dart';
import '../home_assistant/plugin_entities.dart';
import '../home_assistant/plugin_ha_socket.dart';
import '../intercom/intercom_sensors.dart';
import '../kiosk/kiosk_link.dart';
import '../sendspin/plugin_ma_socket.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../voice/assist_view.dart';

/// What plugins follow of a voice turn: the overlay's view, the level its
/// bar follows and the settings that pick what it shows.
class PluginVoiceFeed {
  const PluginVoiceFeed({
    required this.view,
    required this.level,
    required this.settings,
  });

  final ValueListenable<AssistView> view;
  final ValueListenable<double> level;
  final SettingsManager settings;
}

/// The screensaver mode plugins with the screensaver.mode capability read
/// and hold, through the screensaver manager.
class PluginScreensaverModes {
  const PluginScreensaverModes({
    required this.read,
    required this.hold,
    required this.release,
  });

  /// {mode, saved, schedule, override, active, modes}.
  final Map<String, Object?> Function() read;

  /// Holds the screensaver on a mode for an owner. False for a mode the
  /// device cannot show.
  final bool Function(String owner, String mode) hold;

  /// Drops the owner's hold.
  final void Function(String owner) release;
}

/// What plugins follow of the screensaver's look: the view on screen, the
/// Clock screensaver's Night mode decision and the settings that color it.
class PluginScreensaverFeed {
  const PluginScreensaverFeed({
    required this.view,
    required this.night,
    required this.nowPlaying,
    required this.settings,
    this.setTint,
    this.clearTint,
  });

  final ValueListenable<String?> view;
  final ValueListenable<bool> night;

  /// Tints the widgets over a plugin's own screensaver while it is on
  /// screen, false when it is not. Null where nothing can be tinted.
  final bool Function(String pluginId, int color)? setTint;

  /// Drops a plugin's tint.
  final void Function(String pluginId)? clearTint;

  /// Whether Now Playing fills the screensaver, hiding the view under it.
  final bool Function() nowPlaying;
  final SettingsManager settings;
}

/// Explicit SDK 1 host surface. Registry additions do not expand plugin access.
class PluginHostApi {
  PluginHostApi(
    this.commands,
    EventBus bus,
    this.sendEvent, {
    this.ha,
    this.ma,
    this.voice,
    this.screensaverModes,
    this.screensaver,
  }) {
    _events = bus.stream.listen(_onEvent);
    ha?.emit = _onHaEvent;
    ma?.emit = _onMaEvent;
    voice?.view.addListener(_onVoice);
    voice?.level.addListener(_onVoiceLevel);
    screensaver?.view.addListener(_onScreensaverAppearance);
    screensaver?.night.addListener(_onScreensaverAppearance);
    _screensaverAppearanceSent = jsonEncode(_screensaverAppearance());
  }

  final CommandRegistry commands;

  /// Home Assistant commands and subscriptions for sessions that declare
  /// the `ha` capability.
  final HaPluginSocket? ha;

  /// Music Assistant commands and events for sessions that declare the
  /// `ma` capability.
  final MaPluginSocket? ma;
  final Future<void> Function(Map<String, Object?>) sendEvent;

  /// The voice turn, for voice.text, voice.level and voice.skin.
  final PluginVoiceFeed? voice;

  /// The screensaver mode, for sessions that declare screensaver.mode.
  final PluginScreensaverModes? screensaverModes;

  /// The screensaver's look, for screensaver.appearance.
  final PluginScreensaverFeed? screensaver;
  late final StreamSubscription<AppEvent> _events;
  final _sessions = <String, _HostSession>{};
  bool _disposed = false;
  String? _intercomSent;
  String? _voiceTextSent;
  String _overlaySent = 'hidden';
  double _voiceLevelSent = 0;
  String? _screensaverAppearanceSent;

  static const commandNames = [
    'getHostApi',
    'isScreensaverActive',
    'getScreensaverDue',
    'getScreensaverSuppressed',
    'getScreensaverAppearance',
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
    'getVoiceState',
    'getVoiceAppearance',
    'getIntercomState',
    'haStatus',
    'getHaEntityState',
    'getDashboardState',
    'getCameraViews',
    'getDashboards',
    'getSendspinPlayer',
    'getLauncherApps',
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
    'setVolume',
    'setWakeWordMuted',
    'showAppLauncher',
    'hideAppLauncher',
    'launchApp',
    'showOverlayPage',
    'showLinkPage',
    'hideOverlayPage',
    'showMusicAssistant',
    'openCalendar',
    'hideCalendar',
    'openAlarms',
    'hideAlarms',
    'openKioskLink',
    'loadUrl',
    'loadDashboard',
    'loadStartUrl',
    'haNavigate',
    'reload',
  ];

  /// The room's noise level, for sessions that also declare the noise
  /// capability (issue #910): a plugin that reads how loud the room is says
  /// so in its manifest.
  static const noiseCommandNames = ['getNoiseLevel'];
  static const noiseEventNames = ['audio.noise'];

  /// What was said and answered, for sessions that also declare the
  /// voice.text capability (issue #1027). It follows the Conversation
  /// settings the overlay follows.
  static const voiceTextCommandNames = ['getVoiceText'];
  static const voiceTextEventNames = ['voice.text'];

  /// The longest command or answer a plugin gets, in characters.
  static const maxVoiceText = 16000;

  /// Which screensaver shows, for sessions that declare the
  /// screensaver.mode capability. A plugin holds a mode in place of the
  /// schedule and the setting until it clears it or its session ends.
  static const screensaverModeCommandNames = [
    'getScreensaverMode',
    'setScreensaverMode',
    'clearScreensaverMode',
  ];

  /// The corner widgets and At a Glance row over a plugin's own
  /// screensaver, for sessions that declare the screensaver capability
  /// (issue #1299). The tint ends when that screensaver leaves the screen.
  static const screensaverTintCommandNames = [
    'setScreensaverTint',
    'clearScreensaverTint',
  ];

  static bool _volumeChannel(Map params) =>
      !params.containsKey('channel') ||
      const [
        'master',
        'media',
        'assistant',
        'intercom',
      ].contains(params['channel']);

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
    // A view path with an optional query and fragment, such as
    // cameras/0?camera=garage. Segments may hold dots, as custom pages do,
    // but never stand for a parent folder.
    bool viewPath(String key) {
      if (!text(key)) return false;
      final value = params[key] as String;
      final route = value.split(RegExp(r'[?#]')).first;
      return RegExp(
            r'^/?[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*/?(?:\?[^\s#]*)?(?:#\S*)?$',
          ).hasMatch(value) &&
          !route.split('/').any((segment) => segment == '.' || segment == '..');
    }

    switch (name) {
      case 'getHaEntityState':
        return keys({'entityId'}) &&
            HaPluginEntities.validId(params['entityId']);
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
      case 'getVolume':
        return keys({'channel'}) && _volumeChannel(params);
      case 'setVolume':
        final percent = params['percent'];
        final value = percent is String ? num.tryParse(percent.trim()) : null;
        return keys({'percent', 'channel'}) &&
            _volumeChannel(params) &&
            value != null &&
            value >= 0 &&
            value <= 100;
      case 'setWakeWordMuted':
        return params.length == 1 && params['muted'] is bool;
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
      case 'openCalendar':
        final date = params['date'];
        return keys({'view', 'date'}) &&
            (!params.containsKey('view') ||
                const [
                  'day',
                  'week',
                  'month',
                  'schedule',
                ].contains(params['view'])) &&
            (date == null ||
                (date is String &&
                    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
                    DateTime.tryParse(date) != null));
      case 'openAlarms':
        return keys({'alarm'}) && (params.isEmpty || params['alarm'] == 'next');
      case 'openKioskLink':
        // Any ks:// link a dashboard can use (issue #1213). The command
        // refuses the few a plugin may not run.
        return keys({'url'}) &&
            text('url') &&
            kioskLinkAction(params['url'] as String) != null;
      case 'loadDashboard':
        return keys({'dashboard'}) && path('dashboard');
      case 'setScreensaverMode':
        return params.length == 1 && text('mode');
      case 'setScreensaverTint':
        return params.length == 1 &&
            text('color') &&
            RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(params['color'] as String);
      case 'launchApp':
        return params.length == 1 &&
            text('package') &&
            RegExp(
              r'^[a-zA-Z][a-zA-Z0-9_]*(?:\.[a-zA-Z][a-zA-Z0-9_]*)+$',
            ).hasMatch(params['package'] as String);
      case 'haNavigate':
        return keys({'path'}) && viewPath('path');
      default:
        return params.isEmpty;
    }
  }

  static const eventNames = [
    'screensaver.state',
    'screensaver.countdown',
    'screensaver.view',
    'screensaver.appearance',
    'screen.state',
    'screen.brightness',
    'screen.ambient',
    'device.power',
    'device.network',
    'device.volume',
    'device.light',
    'device.key',
    'detection.motion',
    'detection.face',
    'detection.proximity',
    'detection.person',
    'detection.presence',
    'voice.interaction',
    'voice.state',
    'voice.level',
    'voice.overlay',
    'voice.skin',
    'voice.appearance',
    'intercom.state',
    'wakeword.state',
    'wakeword.detected',
    'stopword.detected',
    'camera.view',
    'browser.state',
    'sendspin.player',
  ];
  static const _fields = {
    'getLightLevel': ['present', 'lux', 'live'],
    'getNoiseLevel': ['available', 'dbfs', 'held', 'updated'],
    'getStats': [
      'battery',
      'charging',
      'cpu',
      'cpuClock',
      'temp',
      'batteryTemp',
      'memFree',
      'memTotal',
    ],
    'getUptime': ['app', 'network'],
    'getDeviceInfo': [
      'name',
      'model',
      'device',
      'board',
      'manufacturer',
      'abis',
      'ramFree',
      'ramTotal',
      'storageFree',
      'storageTotal',
      'ip',
      'ipv6',
      'battery',
      'brightness',
      'screenOn',
      'screenWidth',
      'screenHeight',
      'screenDensity',
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
      'muted',
    ],
    'getVoiceState': ['enabled', 'state', 'skinSelected', 'overlay'],
    'getIntercomState': ['enabled', 'state', 'kiosk', 'dnd'],
    'haStatus': ['configured', 'connected'],
    'getSendspinPlayer': [
      'enabled',
      'running',
      'connected',
      'playing',
      'clientId',
      'playerName',
      'serverName',
      'maConfigured',
      'maPlayerId',
      'maServerId',
      'maServerName',
      'maServerVersion',
    ],
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
        !capabilities.any(
          (c) =>
              c == 'host.read' ||
              c == 'host.control' ||
              c == 'ha' ||
              c == 'ma' ||
              c == 'screensaver.mode' ||
              // A renderer alone may tint the widgets over itself.
              c == 'screensaver',
        )) {
      return;
    }
    final previous = _sessions.remove(id);
    if (previous != null) _closeSession(previous);
    _sessions[id] = _HostSession(
      id,
      token,
      capabilities.contains('host.read'),
      capabilities.contains('host.control'),
      canNoise: capabilities.contains('noise'),
      canHa: capabilities.contains('ha'),
      canMa: capabilities.contains('ma'),
      canVoiceText: capabilities.contains('voice.text'),
      canScreensaverMode: capabilities.contains('screensaver.mode'),
      canScreensaver: capabilities.contains('screensaver'),
    );
  }

  void close(Map args) {
    final session = _session(args);
    if (session == null) return;
    _sessions.remove(session.id);
    _closeSession(session);
  }

  void _closeSession(_HostSession session) {
    session.close();
    unawaited(
      commands.execute('haPluginUnwatchEntity', {'owner': session.owner}),
    );
    if (session.canHa) ha?.release(session.owner);
    if (session.canMa) ma?.release(session.owner);
    if (session.canScreensaverMode) {
      screensaverModes?.release(session.owner);
    }
    if (session.canScreensaver) screensaver?.clearTint?.call(session.id);
  }

  static String? entityEventId(String event) {
    if (!event.startsWith('ha.entity.')) return null;
    final id = event.substring('ha.entity.'.length);
    return HaPluginEntities.validId(id) ? id : null;
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
        (!eventNames.contains(name) &&
            !(session.canNoise && noiseEventNames.contains(name)) &&
            !(session.canVoiceText && voiceTextEventNames.contains(name)) &&
            entityEventId(name) == null)) {
      return;
    }
    final entityId = entityEventId(name);
    if (args['subscribed'] == true) {
      if (session.subscriptions.contains(name)) return;
      if (entityId != null &&
          session.subscriptions.where((e) => entityEventId(e) != null).length >=
              16) {
        return;
      }
      session.subscriptions.add(name);
      if (entityId != null) {
        unawaited(
          commands.execute('haPluginWatchEntity', {
            'owner': session.owner,
            'entityId': entityId,
          }),
        );
      }
    } else {
      session.subscriptions.remove(name);
      session.pending.remove(name);
      if (entityId != null) {
        unawaited(
          commands.execute('haPluginUnwatchEntity', {
            'owner': session.owner,
            'entityId': entityId,
          }),
        );
      }
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
            !(session.canRead &&
                session.canNoise &&
                noiseCommandNames.contains(name)) &&
            !(session.canRead &&
                session.canVoiceText &&
                voiceTextCommandNames.contains(name)) &&
            !(session.canScreensaverMode &&
                screensaverModeCommandNames.contains(name)) &&
            !(session.canScreensaver &&
                screensaverTintCommandNames.contains(name)) &&
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
        'entitySubscriptions': session.canRead
            ? {'eventPrefix': 'ha.entity.', 'maxEntities': 16}
            : null,
        'haSubscriptions': session.canHa && ha != null
            ? {
                'eventPrefix': 'ha.subscription.',
                'maxSubscriptions': HaPluginSocket.maxSubscriptions,
              }
            : null,
        'maSubscriptions': session.canMa && ma != null
            ? {
                'eventPrefix': 'ma.subscription.',
                'maxSubscriptions': MaPluginSocket.maxSubscriptions,
              }
            : null,
        'capabilities': [
          if (session.canRead) 'host.read',
          if (session.canControl) 'host.control',
          if (session.canRead && session.canNoise) 'noise',
          if (session.canHa && ha != null) 'ha',
          if (session.canMa && ma != null) 'ma',
          if (session.canRead && session.canVoiceText) 'voice.text',
          if (session.canScreensaverMode && screensaverModes != null)
            'screensaver.mode',
        ],
        'commands': [
          'getHostApi',
          if (session.canRead) ...commandNames.skip(1),
          if (session.canRead && session.canNoise) ...noiseCommandNames,
          if (session.canRead && session.canVoiceText) ...voiceTextCommandNames,
          if (session.canScreensaverMode && screensaverModes != null)
            ...screensaverModeCommandNames,
          if (session.canScreensaver && screensaver?.setTint != null)
            ...screensaverTintCommandNames,
          if (session.canControl) ...controlNames,
        ],
        'events': [
          if (session.canRead) ...eventNames,
          if (session.canRead && session.canNoise) ...noiseEventNames,
          if (session.canRead && session.canVoiceText) ...voiceTextEventNames,
        ],
      }).toJson();
    }
    if (name == 'getScreensaverAppearance') {
      final appearance = _screensaverAppearance();
      return appearance == null
          ? const CommandResult.fail(
              'KS could not complete this command. The feature may be unavailable.',
            ).toJson()
          : CommandResult.ok(appearance).toJson();
    }
    if (screensaverTintCommandNames.contains(name)) {
      final set = screensaver?.setTint;
      final clear = screensaver?.clearTint;
      if (set == null || clear == null) {
        return const CommandResult.fail(
          'KS could not complete this command. The feature may be unavailable.',
        ).toJson();
      }
      if (name == 'clearScreensaverTint') {
        clear(session.id);
        return const CommandResult.ok().toJson();
      }
      final rgb = int.parse(
        (params['color'] as String).substring(1),
        radix: 16,
      );
      return set(session.id, 0xFF000000 | rgb)
          ? const CommandResult.ok().toJson()
          : const CommandResult.fail(
              'None of this plugin\'s screensavers is on screen',
            ).toJson();
    }
    if (name == 'getVoiceAppearance') {
      final appearance = _appearance();
      return appearance == null
          ? const CommandResult.fail(
              'KS could not complete this command. The feature may be unavailable.',
            ).toJson()
          : CommandResult.ok(appearance).toJson();
    }
    if (screensaverModeCommandNames.contains(name)) {
      final modes = screensaverModes;
      if (modes == null) {
        return const CommandResult.fail(
          'KS could not complete this command. The feature may be unavailable.',
        ).toJson();
      }
      if (name == 'getScreensaverMode') {
        return CommandResult.ok(modes.read()).toJson();
      }
      if (name == 'setScreensaverMode') {
        return modes.hold(session.owner, params['mode'] as String)
            ? const CommandResult.ok().toJson()
            : const CommandResult.fail('Unknown screensaver mode').toJson();
      }
      modes.release(session.owner);
      return const CommandResult.ok().toJson();
    }
    if (name == 'getVoiceText') {
      final text = _voiceText();
      return text == null
          ? const CommandResult.fail(
              'KS could not complete this command. The feature may be unavailable.',
            ).toJson()
          : CommandResult.ok(text).toJson();
    }
    try {
      if (name == 'getCameraViews' ||
          name == 'getDashboards' ||
          name == 'getLauncherApps') {
        final scoped = commands.as('plugin:${session.id}');
        final data = await (switch (name) {
          'getCameraViews' => _cameraViews(scoped),
          'getDashboards' => _dashboards(scoped),
          _ => _launcherApps(scoped),
        }).timeout(const Duration(seconds: 8));
        if (_session(args) != session) {
          return const CommandResult.fail(
            'Plugin session is no longer active',
          ).toJson();
        }
        if (data == null) {
          return const CommandResult.fail(
            'KS could not complete this command. The feature may be unavailable.',
          ).toJson();
        }
        if (utf8.encode(jsonEncode(data)).length > 32768) {
          return const CommandResult.fail(
            'Read response is too large',
          ).toJson();
        }
        return CommandResult.ok(data).toJson();
      }
      final result = await commands
          .as('plugin:${session.id}')
          .execute(
            switch (name) {
              'getHaEntityState' => 'haPluginReadEntity',
              'getVoiceState' => 'voiceStatus',
              'getIntercomState' => 'intercomSensors',
              'getSendspinPlayer' => 'sendspinPlayer',
              'launchApp' => 'pluginLaunchApp',
              'openKioskLink' => 'pluginOpenKioskLink',
              _ => name,
            },
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
        return CommandResult.ok(switch (name) {
          'nextScreensaverSlide' ||
          'previousScreensaverSlide' => result.data == true,
          // haNavigate reports what happened. A page already on the view
          // counts as arrived.
          'haNavigate' =>
            result.data == 'navigated' || result.data == 'already',
          // The muted state it set. Home Assistant may still be applying it
          // on the dashboard runtime; wakeword.state follows.
          'setWakeWordMuted' => result.data == true,
          _ => null,
        }).toJson();
      }
      Object? data = result.data;
      if (name == 'getHaEntityState') {
        if (data is! Map || data['entityId'] != params['entityId']) {
          return const CommandResult.fail(
            'KS returned an unexpected entity response',
          ).toJson();
        }
        final projected = <String, Object?>{
          for (final key in [
            'entityId',
            'status',
            'state',
            'attributes',
            'lastChanged',
            'lastUpdated',
          ])
            key: data[key],
        };
        if (utf8.encode(jsonEncode(projected)).length > 32768) {
          return const CommandResult.fail(
            'Read response is too large',
          ).toJson();
        }
        return CommandResult.ok(projected).toJson();
      }
      final fields = _fields[name];
      if (fields != null) {
        if (data is! Map) {
          return const CommandResult.fail(
            'KS returned an unexpected read response',
          ).toJson();
        }
        data = {
          for (final key in fields)
            key: switch (key) {
              'skinSelected' => _skinSelected(session),
              'overlay' => _overlay(),
              _ => data[key],
            },
        };
        if (data.entries.any((entry) {
          final value = entry.value;
          if (name == 'getDeviceInfo' &&
              (entry.key == 'abis' || entry.key == 'ipv6')) {
            return value != null &&
                !(value is List && value.every((item) => item is String));
          }
          return !_scalar(value);
        })) {
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

  /// Run one Home Assistant websocket command for a plugin. Answers
  /// `{ok: true, data: result}` or `{ok: false, error, data: {code, message}}`.
  Future<Map<String, Object?>> haCall(Map args) async {
    final session = _haSession(args);
    final message = _haMessage(args['message']);
    if (session == null || message == null) return _haRefused(session);
    final result = await ha!.call(session.owner, message);
    if (_session(args) != session) return _haRefused(null);
    return _answer(result, data: result['result']);
  }

  /// Subscribe a plugin to a Home Assistant websocket subscription under
  /// its own key. Events follow as `ha.subscription.KEY`.
  Future<Map<String, Object?>> haSubscribe(Map args) async {
    final session = _haSession(args);
    final message = _haMessage(args['message']);
    final key = args['key'];
    if (session == null || message == null || key is! String) {
      return _haRefused(session);
    }
    final result = await ha!.subscribe(session.owner, key, message);
    if (_session(args) != session) {
      ha!.unsubscribe(session.owner, key);
      return _haRefused(null);
    }
    return _answer(result);
  }

  void haUnsubscribe(Map args) {
    final session = _haSession(args);
    final key = args['key'];
    if (session == null || key is! String) return;
    ha!.unsubscribe(session.owner, key);
    session.ordered.removeWhere((e) => e.key == 'ha.subscription.$key');
    session.orderedDropped.remove('ha.subscription.$key');
  }

  _HostSession? _haSession(Map args) {
    final session = _session(args);
    return session != null && session.canHa && ha != null ? session : null;
  }

  /// A detached copy of the plugin's message, when it is one.
  static Map<String, Object?>? _haMessage(Object? message) =>
      message is Map ? Map<String, Object?>.from(message) : null;

  static Map<String, Object?> _haRefused(_HostSession? session) => _answer({
    'ok': false,
    'error': {
      'code': session == null ? 'not_allowed' : 'invalid_message',
      'message': session == null
          ? 'Home Assistant is not available through this plugin session'
          : 'The message must be a JSON object',
    },
  });

  /// A Home Assistant or Music Assistant answer as the SDK hands it over:
  /// on failure, error reads "code: message" and data keeps both.
  static Map<String, Object?> _answer(
    Map<String, Object?> result, {
    Object? data,
  }) {
    if (result['ok'] == true) return {'ok': true, 'data': data};
    final error = result['error'] is Map
        ? Map<String, Object?>.from(result['error'] as Map)
        : <String, Object?>{'code': 'unknown_error', 'message': ''};
    final message = '${error['message'] ?? ''}';
    return {
      'ok': false,
      'error': message.isEmpty
          ? '${error['code']}'
          : '${error['code']}: $message',
      'data': error,
    };
  }

  /// A subscription's event, queued in order: unlike KS's own state
  /// events, none of these may be merged into the next one.
  void _onHaEvent(String owner, String key, Map<String, Object?> payload) =>
      _queueOrdered(owner, 'ha.subscription.$key', payload, (s) => s.canHa);

  void _queueOrdered(
    String owner,
    String name,
    Map<String, Object?> payload,
    bool Function(_HostSession session) allowed,
  ) {
    for (final session in _sessions.values) {
      if (session.owner != owner || !allowed(session)) continue;
      if (session.ordered.length >= _HostSession.maxOrdered) {
        session.orderedDropped[name] = (session.orderedDropped[name] ?? 0) + 1;
      } else {
        session.ordered.add(
          MapEntry(name, {
            ...payload,
            'time': DateTime.now().toUtc().toIso8601String(),
          }),
        );
      }
      _schedule(session);
    }
  }

  /// Run one Music Assistant command for a plugin. Answers like [haCall].
  Future<Map<String, Object?>> maCall(Map args) async {
    final session = _maSession(args);
    final command = args['command'];
    final params = args['args'];
    if (session == null || command is! String || params is! Map) {
      return _maRefused(session);
    }
    final result = await ma!.call(
      session.owner,
      command,
      Map<String, Object?>.from(params),
    );
    if (_session(args) != session) return _maRefused(null);
    return _answer(result, data: result['result']);
  }

  /// Hear Music Assistant events under a key of the plugin's own. Events
  /// follow as `ma.subscription.KEY`.
  Future<Map<String, Object?>> maSubscribe(Map args) async {
    final session = _maSession(args);
    final filter = args['filter'];
    final key = args['key'];
    if (session == null || filter is! Map || key is! String) {
      return _maRefused(session);
    }
    final result = await ma!.subscribe(
      session.owner,
      key,
      Map<String, Object?>.from(filter),
    );
    if (_session(args) != session) {
      ma!.unsubscribe(session.owner, key);
      return _maRefused(null);
    }
    return _answer(result);
  }

  void maUnsubscribe(Map args) {
    final session = _maSession(args);
    final key = args['key'];
    if (session == null || key is! String) return;
    ma!.unsubscribe(session.owner, key);
    session.ordered.removeWhere((e) => e.key == 'ma.subscription.$key');
    session.orderedDropped.remove('ma.subscription.$key');
  }

  _HostSession? _maSession(Map args) {
    final session = _session(args);
    return session != null && session.canMa && ma != null ? session : null;
  }

  static Map<String, Object?> _maRefused(_HostSession? session) => _answer({
    'ok': false,
    'error': {
      'code': session == null ? 'not_allowed' : 'invalid_message',
      'message': session == null
          ? 'Music Assistant is not available through this plugin session'
          : 'The request needs a command and JSON object args',
    },
  });

  /// A Music Assistant subscription's event, queued in order like Home
  /// Assistant's.
  void _onMaEvent(String owner, String key, Map<String, Object?> payload) =>
      _queueOrdered(owner, 'ma.subscription.$key', payload, (s) => s.canMa);

  /// The kiosk's camera views by name, without servers, streams or
  /// credentials.
  static Future<List<Map<String, Object?>>?> _cameraViews(
    CommandRegistry commands,
  ) async {
    final result = await commands.execute('cameraGetConfig', const {});
    final views = result.ok && result.data is Map
        ? (result.data as Map)['views']
        : null;
    if (views is! List) return null;
    return [
      for (final view in views.whereType<Map>())
        {
          'id': '${view['id']}',
          'name': '${view['name'] ?? ''}',
          'cameraCount': (view['cameraIds'] as List?)?.length ?? 0,
        },
    ];
  }

  /// The launcher apps this kiosk lets a plugin open, for launchApp.
  static Future<List<Map<String, Object?>>?> _launcherApps(
    CommandRegistry commands,
  ) async {
    final result = await commands.execute('pluginLauncherApps', const {});
    if (!result.ok || result.data is! List) return null;
    return [
      for (final app in (result.data as List).whereType<Map>())
        {'package': '${app['package']}', 'label': '${app['label']}'},
    ];
  }

  /// Home Assistant's dashboards and their views, through the same commands
  /// the dashboard picker reads. Each view's path is what haNavigate takes.
  static Future<List<Map<String, Object?>>?> _dashboards(
    CommandRegistry commands,
  ) async {
    final listed = await commands.execute('haListDashboards', const {});
    if (!listed.ok || listed.data is! List) return null;
    final dashboards = [
      for (final d in (listed.data as List).whereType<Map>())
        if ('${d['url_path'] ?? ''}'.isNotEmpty) d,
    ];
    final views = await Future.wait([
      for (final d in dashboards)
        commands.execute('haListDashboardViews', {'url_path': d['url_path']}),
    ]);
    String? icon(Object? value) => value is String ? value : null;
    return [
      for (final (i, d) in dashboards.indexed)
        {
          'urlPath': '${d['url_path']}',
          'title': '${d['title'] ?? d['url_path']}',
          'icon': icon(d['icon']),
          'custom': d['custom'] == true,
          'builtIn': d['builtIn'] == true,
          'views': [
            if (views[i].ok && views[i].data is List)
              for (final v in (views[i].data as List).whereType<Map>())
                if ('${v['route'] ?? ''}'.isNotEmpty)
                  {
                    'path': '${d['url_path']}/${v['route']}',
                    'title': '${v['title'] ?? v['route']}',
                    'icon': icon(v['icon']),
                    'subview': v['subview'] == true,
                  },
          ],
        },
    ];
  }

  static (String, Map<String, Object?>)? project(
    AppEvent event,
  ) => switch (event) {
    UrlChanged _ => ('browser.state', {}),
    PageChanged _ => ('browser.state', {}),
    SettingChanged e
        when e.key == defs.haUrl.key || e.key == defs.startUrl.key =>
      ('browser.state', {}),
    SendspinPlayerChanged e => ('sendspin.player', e.player),
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
    SettingChanged e
        when e.key == defs.mediaVolume.key ||
            e.key == defs.assistantVolume.key ||
            e.key == defs.intercomVolume.key =>
      ('device.volume', {}),
    LightLevelChanged e => ('device.light', {'lux': e.lux}),
    NoiseLevelChanged e => (
      'audio.noise',
      {'available': e.available, 'dbfs': e.dbfs, 'held': e.held},
    ),
    MotionDetected _ => ('detection.motion', {}),
    FaceDetected _ => ('detection.face', {}),
    ProximityDetected e => ('detection.proximity', {'held': e.held}),
    PersonDetected e => ('detection.person', {'held': e.held}),
    PersonSensorChanged e => ('detection.presence', {'present': e.present}),
    VoiceInteractionChanged e => (
      'voice.interaction',
      {'active': e.active, 'source': e.source.name},
    ),
    VoiceSatelliteStateChanged e => ('voice.state', {'state': e.state}),
    IntercomStateChanged e => ('intercom.state', intercomSensors(e.status)),
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

  /// Whether this session's plugin draws the overlay: the Skin setting of
  /// the assistant on screen picks it. While nothing shows, either
  /// assistant's does.
  bool _skinSelected(_HostSession session) {
    final feed = voice;
    if (feed == null) return false;
    final id = 'plugin:${session.id}';
    final view = feed.view.value;
    if (view.visible) {
      return feed.settings.get(defs.voiceSkinOf(view.assistant)) == id;
    }
    return feed.settings.get(defs.voiceSkin) == id ||
        feed.settings.get(defs.voiceSkin2) == id;
  }

  /// Sends voice.skin to each session whose answer changed. Before the
  /// overlay event of the same change, so a plugin knows it draws by the
  /// time the overlay shows.
  void _onVoiceSkin() {
    for (final session in _sessions.values) {
      if (!session.subscriptions.contains('voice.skin')) continue;
      final selected = _skinSelected(session);
      if (selected == session.skinSelectedSent) continue;
      session.skinSelectedSent = selected;
      session.pending['voice.skin'] = {
        'selected': selected,
        'time': DateTime.now().toUtc().toIso8601String(),
      };
      _schedule(session);
    }
  }

  /// The turn's words as the overlay would show them: a line whose
  /// Conversation setting is off is empty.
  Map<String, Object?>? _voiceText() {
    final feed = voice;
    if (feed == null) return null;
    final view = feed.view.value;
    final settings = feed.settings;
    String cap(String text) =>
        text.length > maxVoiceText ? text.substring(0, maxVoiceText) : text;
    return {
      'command': settings.get(defs.voiceShowCommand) ? cap(view.command) : '',
      'answer': settings.get(defs.voiceShowAnswer) ? cap(view.answer) : '',
      'tools': settings.get(defs.voiceShowTools)
          ? [for (final tool in view.tools.take(20)) cap(tool)]
          : const <String>[],
      'streaming': view.streaming,
      'announcement': view.phase == AssistPhase.announcement,
    };
  }

  /// Whether the voice overlay shows, and how: `hidden`, `full` or
  /// `docked`. It shows for a preview and while an answer stays on screen,
  /// when the turn's state already reads idle.
  String _overlay() {
    final view = voice?.view.value;
    if (view == null || !view.visible) return 'hidden';
    return view.docked ? 'docked' : 'full';
  }

  void _onVoice() {
    _onVoiceLevel();
    _onVoiceSkin();
    final overlay = _overlay();
    if (overlay != _overlaySent) {
      _overlaySent = overlay;
      for (final session in _sessions.values) {
        if (!session.subscriptions.contains('voice.overlay')) continue;
        session.pending['voice.overlay'] = {
          'overlay': overlay,
          'time': DateTime.now().toUtc().toIso8601String(),
        };
        _schedule(session);
      }
    }
    final text = _voiceText();
    if (text == null) return;
    final value = jsonEncode(text);
    if (value == _voiceTextSent) return;
    _voiceTextSent = value;
    for (final session in _sessions.values) {
      if (!session.canVoiceText ||
          !session.subscriptions.contains('voice.text')) {
        continue;
      }
      session.pending['voice.text'] = {
        ...text,
        'time': DateTime.now().toUtc().toIso8601String(),
      };
      _schedule(session);
    }
  }

  /// The Appearance settings a skin follows: Theme, Background (null for
  /// the skin's own), Text size as a factor and Reactive activity bar.
  Map<String, Object?>? _appearance() {
    final settings = voice?.settings;
    if (settings == null) return null;
    final background = settings.get(defs.voiceBackgroundOpacity).toDouble();
    return {
      'theme': settings.get(defs.voiceTheme),
      'background': background < 0 ? null : background.clamp(0, 100) / 100,
      'textScale': settings.get(defs.voiceTextScale).toDouble() / 100,
      'reactive': settings.get(defs.voiceReactiveBar),
    };
  }

  /// The screensaver's look as plugins follow it: the view, whether the
  /// Clock screensaver wears its Night mode colors and those colors as
  /// ARGB, null outside Night mode. The card color is the flip clock's
  /// alone. Night mode never shows under Now Playing, which hides the face.
  Map<String, Object?>? _screensaverAppearance() {
    final feed = screensaver;
    if (feed == null) return null;
    final view = feed.view.value;
    final night = view == 'clock' && feed.night.value && !feed.nowPlaying();
    final s = feed.settings;
    int color(defs.SettingDef<String> def) =>
        _argb(s.get(def)) ?? _argb(def.defaultValue)!;
    return {
      'view': view,
      'night': night,
      'textColor': night ? color(defs.screensaverClockNightColor) : null,
      'backgroundColor': night
          ? color(defs.screensaverClockNightBgColor)
          : null,
      'cardColor': night && s.get(defs.screensaverClockStyle) == 'flip'
          ? color(defs.screensaverClockNightCardColor)
          : null,
      'widgetsHidden': night && s.get(defs.screensaverClockNightHideWidgets),
    };
  }

  /// An opaque ARGB color from an "r,g,b" setting, as the clock face
  /// reads it, or null for a malformed one.
  static int? _argb(String raw) {
    final parts = raw.split(',').map((p) => int.tryParse(p.trim())).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) return null;
    return 0xFF000000 |
        (parts[0]! & 0xFF) << 16 |
        (parts[1]! & 0xFF) << 8 |
        (parts[2]! & 0xFF);
  }

  void _onScreensaverAppearance() {
    final appearance = _screensaverAppearance();
    if (appearance == null) return;
    final value = jsonEncode(appearance);
    if (value == _screensaverAppearanceSent) return;
    _screensaverAppearanceSent = value;
    for (final session in _sessions.values) {
      if (!session.subscriptions.contains('screensaver.appearance')) continue;
      session.pending['screensaver.appearance'] = {
        ...appearance,
        'time': DateTime.now().toUtc().toIso8601String(),
      };
      _schedule(session);
    }
  }

  /// The level the reactive bar follows: the voice while listening, the
  /// answer while speaking, 0 while the assistant thinks, the wake chime
  /// plays, nothing shows or Reactive activity bar is off.
  double _voiceLevel() {
    final view = voice!.view.value;
    final live =
        voice!.settings.get(defs.voiceReactiveBar) &&
        view.reactive &&
        !view.lingering &&
        const [
          AssistPhase.listening,
          AssistPhase.speaking,
          AssistPhase.announcement,
        ].contains(view.phase);
    final level = voice!.level.value;
    return live && level.isFinite
        ? (level.clamp(0.0, 1.0) * 1000).roundToDouble() / 1000
        : 0;
  }

  void _onVoiceLevel() {
    if (voice == null) return;
    final level = _voiceLevel();
    if (level == _voiceLevelSent) return;
    _voiceLevelSent = level;
    for (final session in _sessions.values) {
      if (!session.subscriptions.contains('voice.level')) continue;
      session.pending['voice.level'] = {
        'level': level,
        'time': DateTime.now().toUtc().toIso8601String(),
      };
      _schedule(session);
    }
  }

  void _onEvent(AppEvent event) {
    if ((event is FullscreenViewChanged && event.view == 'nowPlaying') ||
        (event is SettingChanged &&
            (event.key == defs.screensaverClockNightColor.key ||
                event.key == defs.screensaverClockNightBgColor.key ||
                event.key == defs.screensaverClockNightCardColor.key ||
                event.key == defs.screensaverClockNightHideWidgets.key ||
                event.key == defs.screensaverClockStyle.key))) {
      _onScreensaverAppearance();
      return;
    }
    if (event is SettingChanged &&
        (event.key == defs.voiceTheme.key ||
            event.key == defs.voiceBackgroundOpacity.key ||
            event.key == defs.voiceTextScale.key ||
            event.key == defs.voiceReactiveBar.key)) {
      final appearance = _appearance();
      if (appearance == null) return;
      for (final session in _sessions.values) {
        if (!session.subscriptions.contains('voice.appearance')) continue;
        session.pending['voice.appearance'] = {
          ...appearance,
          'time': DateTime.now().toUtc().toIso8601String(),
        };
        _schedule(session);
      }
      if (event.key == defs.voiceReactiveBar.key) _onVoiceLevel();
      return;
    }
    if (event is SettingChanged &&
        (event.key == defs.voiceShowCommand.key ||
            event.key == defs.voiceShowAnswer.key ||
            event.key == defs.voiceShowTools.key)) {
      _onVoice();
      return;
    }
    if (event is SettingChanged && defs.isVoiceSkinSetting(event.key)) {
      _onVoiceSkin();
      return;
    }
    if (event is PluginHaStateChanged) {
      final name = 'ha.entity.${event.entityId}';
      for (final session in _sessions.values) {
        if (session.owner != event.owner ||
            !session.subscriptions.contains(name)) {
          continue;
        }
        if (utf8.encode(jsonEncode(event.data)).length > 30000) continue;
        session.pending[name] = {
          ...event.data,
          'time': DateTime.now().toUtc().toIso8601String(),
        };
        _schedule(session);
      }
      return;
    }
    final projected = project(event);
    if (projected == null) return;
    if (projected.$2.values.any((value) => !_scalar(value)) ||
        utf8.encode(jsonEncode(projected.$2)).length > 32000) {
      return;
    }
    // The intercom's status also changes with the roster and each talking
    // flag. Plugins hear only what the sensors would show.
    if (projected.$1 == 'intercom.state') {
      final value = jsonEncode(projected.$2);
      if (value == _intercomSent) return;
      _intercomSent = value;
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
        (session.pending.isEmpty &&
            session.ordered.isEmpty &&
            session.orderedDropped.isEmpty)) {
      return;
    }
    // The voice level alone goes out about 30 times a second, so a skin
    // moves with the voice. Everything else is batched every 100 ms.
    final levelOnly =
        session.ordered.isEmpty &&
        session.orderedDropped.isEmpty &&
        session.pending.keys.every((k) => k == 'voice.level');
    session.timer = Timer(
      Duration(milliseconds: levelOnly ? 33 : 100),
      () async {
        session.timer = null;
        session.sending = true;
        final batch = [
          ...session.pending.entries,
          ...session.ordered,
          // Events that did not fit: the plugin hears how many it missed.
          for (final entry in session.orderedDropped.entries)
            MapEntry(entry.key, {
              'type': 'overflow',
              'dropped': entry.value,
              'time': DateTime.now().toUtc().toIso8601String(),
            }),
        ];
        session.pending.clear();
        session.ordered.clear();
        session.orderedDropped.clear();
        try {
          for (final entry in batch) {
            if (session.closed) break;
            // Unsubscribed while the batch went out. The Android side drops
            // events for ended Home Assistant and Music Assistant
            // subscriptions.
            if (!entry.key.startsWith('ha.subscription.') &&
                !entry.key.startsWith('ma.subscription.') &&
                !session.subscriptions.contains(entry.key)) {
              continue;
            }
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
      },
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final session in _sessions.values) {
      _closeSession(session);
    }
    _sessions.clear();
    voice?.view.removeListener(_onVoice);
    voice?.level.removeListener(_onVoiceLevel);
    screensaver?.view.removeListener(_onScreensaverAppearance);
    screensaver?.night.removeListener(_onScreensaverAppearance);
    await _events.cancel();
  }

  static bool _scalar(Object? value) =>
      value == null ||
      value is String ||
      value is bool ||
      (value is num && value.isFinite);
}

class _HostSession {
  _HostSession(
    this.id,
    this.token,
    this.canRead,
    this.canControl, {
    this.canNoise = false,
    this.canHa = false,
    this.canMa = false,
    this.canVoiceText = false,
    this.canScreensaverMode = false,
    this.canScreensaver = false,
  });

  /// Home Assistant and Music Assistant events waiting for a slow plugin.
  /// Past this the newest are dropped and counted.
  static const maxOrdered = 64;

  final bool canRead;
  final bool canControl;
  final bool canNoise;
  final bool canHa;
  final bool canMa;
  final bool canVoiceText;
  final bool canScreensaverMode;

  /// The plugin publishes screensavers, so it may tint the widgets over
  /// its own.
  final bool canScreensaver;
  final String id;
  final String token;
  String get owner => '$id:$token';
  final subscriptions = <String>{};

  /// The last voice.skin answer sent, null before the first.
  bool? skinSelectedSent;
  final pending = <String, Map<String, Object?>>{};
  final ordered = <MapEntry<String, Map<String, Object?>>>[];
  final orderedDropped = <String, int>{};
  Timer? timer;
  bool sending = false;
  bool closed = false;
  void close() {
    closed = true;
    timer?.cancel();
    pending.clear();
    ordered.clear();
    orderedDropped.clear();
    subscriptions.clear();
  }
}
