import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../../core/events.dart';
import '../../ui/mdi_icon.dart';
import 'fleet_plugin_host.dart';
import 'plugin_directory.dart';
import 'plugin_repository.dart';
import '../home_assistant/plugin_ha_socket.dart';
import '../sendspin/plugin_ma_socket.dart';
import '../settings/definitions.dart' as defs;
import 'plugin_camera.dart';
import 'plugin_host_api.dart';

class PluginWindow {
  const PluginWindow({
    required this.id,
    required this.title,
    required this.message,
    required this.buttonLabel,
  });
  final String id;
  final String title;
  final String message;
  final String buttonLabel;
}

/// A native overlay a plugin shows through SDK 1 showOverlay. Sizes and the
/// inset are in dp, or [wrap] and [fill]. [measured] is the wrapped view's
/// size in physical pixels once Android has measured it.
class PluginNativeOverlay {
  const PluginNativeOverlay({
    required this.pluginId,
    required this.session,
    required this.key,
    required this.generation,
    required this.anchor,
    required this.width,
    required this.height,
    required this.insets,
    required this.closeOnBack,
    required this.onTop,
    required this.touchable,
    this.offset = Offset.zero,
    this.closeOnOutsideTouch = false,
    this.passOutsideTouch = false,
    this.enter = 'none',
    this.exit = 'none',
    this.duration = const Duration(milliseconds: 200),
    this.measured,
  });

  static const wrap = -1;
  static const fill = -2;

  final String pluginId;
  final String session;
  final String key;
  final int generation;
  final String anchor;
  final int width;
  final int height;

  /// The distance from each kiosk edge, in logical pixels (dp).
  final EdgeInsets insets;

  /// Where the overlay moves from its anchored place, in dp.
  final Offset offset;
  final bool closeOnBack;
  final bool onTop;
  final bool touchable;

  /// A touch outside the overlay closes it. With [passOutsideTouch] that
  /// touch also reaches what is under it.
  final bool closeOnOutsideTouch;
  final bool passOutsideTouch;

  /// How it appears and leaves: none, fade, slide or scale.
  final String enter;
  final String exit;
  final Duration duration;
  final Size? measured;

  /// A replaced overlay is a new view, so the generation is part of it.
  String get id => '$pluginId/$key/$generation';

  bool get wraps => width == wrap || height == wrap;

  PluginNativeOverlay withMeasured(Size size) => PluginNativeOverlay(
    pluginId: pluginId,
    session: session,
    key: key,
    generation: generation,
    anchor: anchor,
    width: width,
    height: height,
    insets: insets,
    offset: offset,
    closeOnBack: closeOnBack,
    onTop: onTop,
    touchable: touchable,
    closeOnOutsideTouch: closeOnOutsideTouch,
    passOutsideTouch: passOutsideTouch,
    enter: enter,
    exit: exit,
    duration: duration,
    measured: size,
  );
}

/// A refused setup run, whose text is the host's message as is, ready for
/// pluginError.
class PluginSetupError implements Exception {
  const PluginSetupError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Owns the Flutter surface of the Android plugin runtime.
class PluginManager extends Manager implements FleetPluginHost {
  PluginManager(
    super.bus,
    super.commands,
    super.log, {
    PluginRepository? repository,
    PluginDirectory? directory,
  }) : repository = repository ?? PluginRepository(),
       directory = directory ?? PluginDirectory();

  final PluginRepository repository;
  final PluginDirectory directory;

  /// The running Kiosk Satellite release, which Browse plugins compares
  /// with each listed plugin's minAppVersion.
  String Function() appVersion = () => '';
  List<Map<String, Object?>> _entities = [];
  final _runtimeEntities = <String, List<Map<String, Object?>>>{};
  static const maxZipBytes = PluginRepository.maxPackageBytes;

  static const channel = MethodChannel('kiosk_satellite/plugins');
  final installed = ValueNotifier<List<Map<String, Object?>>>(const []);
  final readings = ValueNotifier<Map<String, List<Map<String, Object?>>>>({});
  final charts = ValueNotifier<Map<String, List<Map<String, Object?>>>>({});
  // Overview status tiles, keyed by plugin id. Session scoped like charts.
  final statusTiles = ValueNotifier<Map<String, List<Map<String, Object?>>>>(
    {},
  );
  final _runtimeSessions = <String, String>{};

  /// Settings page buttons and plugin choices by plugin id: each run's
  /// state and what the plugin listed. Session scoped like charts.
  final setup = ValueNotifier<Map<String, Map<String, Object?>>>({});

  /// Who has each plugin's settings page open, by plugin id: kiosk pages
  /// by their state, remote admin pages by their viewer id with the timer
  /// that closes them once they stop checking in.
  final _pageViewers = <String, Map<Object, Timer?>>{};

  /// The plugins last told their settings page is open.
  final _pagesOpen = <String>{};

  /// How long a remote admin page counts as open after it last checked in.
  static const remotePageTimeout = Duration(seconds: 5);
  final screensavers = ValueNotifier<Map<String, Map<String, Object?>>>({});
  Map<String, String> get screensaverOptions => {
    for (final entry in screensavers.value.entries)
      entry.key:
          '${entry.value['title']} (${installed.value.where((p) => p['id'] == entry.value['pluginId']).firstOrNull?['name'] ?? entry.value['pluginId']})',
  };

  /// Whether [mode] is a native renderer published with touch: single taps
  /// reach it and a double tap closes the screensaver (issue #1282).
  bool screensaverTouch(String mode) {
    final renderer = screensavers.value[mode];
    return renderer?['view'] == true && renderer?['touch'] == true;
  }

  /// Enabled plugins that offer a voice skin, by the Skin setting's value.
  /// A disabled plugin cannot draw its skin, so it is not offered.
  Map<String, String> get voiceSkinOptions => {
    for (final plugin in installed.value)
      if (enabled.value &&
          plugin['enabled'] == true &&
          (plugin['capabilities'] as List? ?? const []).contains('voice.skin'))
        'plugin:${plugin['id']}': '${plugin['name'] ?? plugin['id']}',
  };

  /// Plugin pictures by field, plugin id and package digest, so an update
  /// shows its new one.
  final _thumbnails = <String, Future<Uint8List?>>{};

  /// The picture an installed plugin names for its voice skin, or null for
  /// none. It need not be running.
  Future<Uint8List?> voiceSkinThumbnail(String id) =>
      _picture('voiceSkinThumbnail', id);

  /// The icon an installed plugin names in its manifest, or null for none.
  /// It need not be running.
  Future<Uint8List?> pluginIcon(String id) => _picture('icon', id);

  /// [field] is both the manifest field and the channel method.
  Future<Uint8List?> _picture(String field, String id) {
    final plugin = installed.value.where((p) => p['id'] == id).firstOrNull;
    if (plugin == null || plugin[field] is! String) {
      return Future.value(null);
    }
    final key = '$field:$id@${plugin['sha256']}';
    return _thumbnails[key] ??= channel
        .invokeMethod<Uint8List>(field, {'id': id})
        .timeout(const Duration(seconds: 10))
        .catchError((Object _) {
          _thumbnails.remove(key);
          return null;
        });
  }

  static String _imageMime(Uint8List bytes) {
    bool starts(List<int> magic) =>
        bytes.length >= magic.length &&
        [for (var i = 0; i < magic.length; i++) bytes[i]].join(',') ==
            magic.join(',');
    if (starts([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    return 'image/webp';
  }

  /// Whether [skin] is a plugin's voice skin and that plugin runs, so it
  /// draws the turn. Otherwise the overlay draws a built-in skin.
  bool voiceSkinRunning(String skin) =>
      enabled.value &&
      installed.value.any(
        (p) =>
            skin == 'plugin:${p['id']}' &&
            p['running'] == true &&
            (p['capabilities'] as List? ?? const []).contains('voice.skin'),
      );

  final windows = ValueNotifier<List<PluginWindow>>(const []);
  // Bottom to top across plugins: a new or replaced overlay goes on top.
  final overlays = ValueNotifier<List<PluginNativeOverlay>>(const []);
  // Flutter keeps platform views across an Activity re-creation, still bound
  // to the old Activity. A new epoch rebuilds every overlay view on the new
  // one, so plugins get a live context and the old Activity can go.
  final overlayEpoch = ValueNotifier<int>(0);

  /// The space running plugins asked the dashboard to keep clear, in dp:
  /// the largest per edge. Zero when none asked.
  final contentInsets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
  final _contentInsets = <String, EdgeInsets>{};

  void _setContentInsets(String pluginId, EdgeInsets? insets) {
    if (insets == null || insets == EdgeInsets.zero) {
      _contentInsets.remove(pluginId);
    } else {
      _contentInsets[pluginId] = insets;
    }
    var merged = EdgeInsets.zero;
    for (final i in _contentInsets.values) {
      merged = EdgeInsets.fromLTRB(
        math.max(merged.left, i.left),
        math.max(merged.top, i.top),
        math.max(merged.right, i.right),
        math.max(merged.bottom, i.bottom),
      );
    }
    if (merged != contentInsets.value) contentInsets.value = merged;
  }

  StreamSubscription<ActivityAttached>? _attachSub;
  Map<String, Object?>? _overlayTheme;
  final shizuku = ValueNotifier<Map<String, Object?>>(const {
    'status': 'checking',
  });
  final status = ValueNotifier<String>('');
  final enabled = ValueNotifier<bool>(false);
  bool _disposed = false;
  late final PluginHostApi _hostReads;

  /// Whether a fleet leader keeps this plugin in step here: its own update
  /// check is the leader's then. Set by the app container.
  bool Function(String id) fleetManaged = _never;
  static bool _never(String _) => false;

  /// Counts a plugin install, update, removal or failed install that
  /// someone asked for here, by name, for usage analytics. Fleet pushes
  /// do not count. Set by the app container.
  void Function(String name)? onActivity;

  /// Runs after a plugin is removed, by anyone, a fleet leader included,
  /// with its id. Set by the app container, which takes the plugin's
  /// actions out of Drawer menu items.
  void Function(String id)? onRemoved;

  /// The Home Assistant connection plugins with the `ha` capability share.
  /// Set by the app container before [init].
  HaPluginSocket? haSocket;

  /// The Music Assistant connection plugins with the `ma` capability
  /// share. Set by the app container before [init].
  MaPluginSocket? maSocket;

  /// The voice turn plugins follow. Set by the app container before [init].
  PluginVoiceFeed? voice;

  /// Runs an action the user chose in a plugin's action setting. The plugin
  /// names the setting and the host reads the action from the saved
  /// settings, so a plugin only decides when it runs. Set by the app
  /// container.
  Future<CommandResult> Function(Map<String, Object?> action)? runAction;

  /// The screensaver mode plugins with the screensaver.mode capability
  /// read and hold. Set by the app container before [init].
  PluginScreensaverModes? screensaverModes;

  /// The screensaver's look plugins follow. Set by the app container
  /// before [init].
  PluginScreensaverFeed? screensaverFeed;

  /// The device camera for the camera and barcode capabilities. Set by the
  /// app container before [init].
  PluginCamera? camera;

  List<Map<String, Object?>> get actions => [
    for (final plugin in installed.value)
      for (final command
          in (plugin['commands'] as List? ?? const []).whereType<Map>())
        {
          'pluginId': plugin['id'],
          'pluginName': plugin['name'],
          'command': command['id'],
          'title': command['title'],
          'available': enabled.value && plugin['running'] == true,
          'drawer':
              ((plugin['actionOptions'] as Map?)?[command['id']]
                  as Map?)?['drawer'] ==
              true,
          'homeAssistant':
              ((plugin['actionOptions'] as Map?)?[command['id']]
                  as Map?)?['homeAssistant'] ==
              true,
        },
  ];

  /// Declared gesture triggers. Only a running plugin can fire one.
  List<Map<String, Object?>> get triggers => [
    for (final plugin in installed.value)
      for (final trigger
          in (plugin['triggers'] as List? ?? const []).whereType<Map>())
        {
          'pluginId': plugin['id'],
          'pluginName': plugin['name'],
          'trigger': trigger['id'],
          'title': trigger['title'],
          'available': enabled.value && plugin['running'] == true,
        },
  ];

  /// The current names of an installed plugin's command, for a saved
  /// plugin action that keeps only the IDs.
  ({String plugin, String title})? actionNames(
    String pluginId,
    String command,
  ) {
    final plugin = installed.value
        .where((p) => p['id'] == pluginId)
        .firstOrNull;
    final entry = (plugin?['commands'] as List? ?? const [])
        .whereType<Map>()
        .where((c) => c['id'] == command)
        .firstOrNull;
    if (plugin == null || entry == null) return null;
    return (plugin: '${plugin['name']}', title: '${entry['title']}');
  }

  List<Map<String, Object?>> get drawerActions => actions
      .where(
        (action) => action['available'] == true && action['drawer'] == true,
      )
      .toList();

  @override
  String get name => 'plugins';

  @override
  Future<void> init() async {
    for (final listenable in [
      installed,
      readings,
      charts,
      statusTiles,
      shizuku,
      setup,
    ]) {
      listenable.addListener(() {
        if (!_disposed) bus.publish(const RemoteStatusChanged('plugins'));
      });
    }
    var remoteSettings = jsonEncode(_state);
    void publishSettings() {
      final next = jsonEncode(_state);
      if (!_disposed && next != remoteSettings) {
        remoteSettings = next;
        bus.publish(const RemoteStatusChanged('plugin-settings'));
      }
    }

    installed.addListener(publishSettings);
    enabled.addListener(publishSettings);
    // Screensaver mode lists each plugin screensaver by title and plugin
    // name, so the remote admin rebuilds its dropdown when either changes.
    // A slideshow's new photos leave the list alone.
    var screensaverList = jsonEncode(screensaverOptions);
    void publishScreensaverOptions() {
      final next = jsonEncode(screensaverOptions);
      if (!_disposed && next != screensaverList) {
        screensaverList = next;
        bus.publish(SettingOptionsChanged(defs.screensaverMode.key));
      }
    }

    screensavers.addListener(publishScreensaverOptions);
    installed.addListener(publishScreensaverOptions);
    // The Overview's plugin tiles, apart from the readings and charts a
    // plugin page follows: those move often, the tiles rarely.
    void publishTiles() {
      if (!_disposed) bus.publish(const RemoteStatusChanged('plugin-tiles'));
    }

    statusTiles.addListener(publishTiles);
    installed.addListener(publishTiles);
    enabled.addListener(publishTiles);
    _attachSub = bus.on<ActivityAttached>().listen((_) {
      if (!_disposed && overlays.value.isNotEmpty) overlayEpoch.value++;
    });
    camera?.notifyClosed = (args) => unawaited(
      channel.invokeMethod<void>('cameraClosed', args).catchError((_) {}),
    );
    _hostReads = PluginHostApi(
      commands,
      bus,
      (event) => channel.invokeMethod<void>('hostEvent', event),
      ha: haSocket,
      ma: maSocket,
      voice: voice,
      screensaverModes: screensaverModes,
      screensaver: screensaverFeed,
    );
    channel.setMethodCallHandler((call) async {
      if (_disposed) return null;
      switch (call.method) {
        case 'hostSession':
          final data = call.arguments as Map;
          _runtimeSessions[data['id'] as String] = data['session'] as String;
          _setScreensavers(data['id'] as String, const []);
          _setCharts(data['id'] as String, const []);
          _setStatusTiles(data['id'] as String, const []);
          _setEntities(data['id'] as String, const []);
          _setOverlays(data['id'] as String, const []);
          _setContentInsets(data['id'] as String, null);
          _setSetup(data['id'] as String, null);
          _hostReads.open(call.arguments as Map);
          // A new session has not heard that its settings page is open.
          if (_pageViewers.containsKey(data['id'])) {
            _sendSettingsPage(data['id'] as String, true);
          }
        case 'hostSessionClosed':
          final data = call.arguments as Map;
          // First, so a screensaver mode the plugin held lets go before its
          // renderers do, instead of showing black in between.
          _hostReads.close(call.arguments as Map);
          if (_runtimeSessions[data['id']] == data['session']) {
            _runtimeSessions.remove(data['id']);
            _setScreensavers(data['id'] as String, const []);
            _setCharts(data['id'] as String, const []);
            _setStatusTiles(data['id'] as String, const []);
            _setEntities(data['id'] as String, const []);
            _setOverlays(data['id'] as String, const []);
            _setContentInsets(data['id'] as String, null);
            _setSetup(data['id'] as String, null);
          }
        case 'cameraOpen':
          return camera == null
              ? 'camera_failed'
              : await camera!.open(call.arguments as Map);
        case 'cameraClose':
          camera?.close(call.arguments as Map);
        case 'barcodeScan':
          return camera?.scan(call.arguments as Map) ??
              {'ok': false, 'error': 'unavailable'};
        case 'barcodeCancel':
          camera?.cancelScan(call.arguments as Map);
        case 'hostSubscription':
          _hostReads.subscription(call.arguments as Map);
        case 'hostCommand':
          return _hostReads.execute(call.arguments as Map);
        case 'haCall':
          return _hostReads.haCall(call.arguments as Map);
        case 'haSubscribe':
          return _hostReads.haSubscribe(call.arguments as Map);
        case 'haUnsubscribe':
          _hostReads.haUnsubscribe(call.arguments as Map);
        case 'maCall':
          return _hostReads.maCall(call.arguments as Map);
        case 'maSubscribe':
          return _hostReads.maSubscribe(call.arguments as Map);
        case 'maUnsubscribe':
          _hostReads.maUnsubscribe(call.arguments as Map);
        case 'entities':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setEntities(data['id'] as String, data['entities'] as List);
          }
        case 'charts':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setCharts(data['id'] as String, data['charts'] as List);
          }
        case 'statusTiles':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setStatusTiles(data['id'] as String, data['statusTiles'] as List);
          }
        case 'trigger':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null &&
              data['trigger'] is String) {
            bus.publish(
              PluginTriggerFired(
                pluginId: data['id'] as String,
                trigger: data['trigger'] as String,
              ),
            );
          }
        case 'runAction':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] != data['session'] ||
              data['session'] == null ||
              data['action'] is! Map) {
            return const {'ok': false, 'error': 'Plugin session has ended'};
          }
          final run = runAction;
          if (run == null) {
            return const {'ok': false, 'error': 'Actions are unavailable'};
          }
          final action =
              jsonDecode(jsonEncode(data['action'])) as Map<String, Object?>;
          final result = await run(action);
          return {'ok': result.ok, if (!result.ok) 'error': result.error};
        case 'screensavers':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setScreensavers(
              data['id'] as String,
              data['screensavers'] as List,
            );
          }
        case 'contentInsets':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setContentInsets(data['id'] as String, _insets(data['insets']));
          }
        case 'setup':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setSetup(data['id'] as String, data['setup'] as Map?);
          }
        case 'overlays':
          final data = call.arguments as Map;
          if (_runtimeSessions[data['id']] == data['session'] &&
              data['session'] != null) {
            _setOverlays(data['id'] as String, data['overlays'] as List);
          }
        case 'overlaySize':
          final data = call.arguments as Map;
          final id =
              '${data['id']}/${data['key']}/${(data['generation'] as num).toInt()}';
          final size = Size(
            (data['width'] as num).toDouble(),
            (data['height'] as num).toDouble(),
          );
          if (_runtimeSessions[data['id']] == data['session']) {
            overlays.value = [
              for (final overlay in overlays.value)
                overlay.id == id ? overlay.withMeasured(size) : overlay,
            ];
          }
        case 'shizukuState':
          shizuku.value = Map<String, Object?>.from(call.arguments as Map);
        case 'changed':
          _readInstalled(call.arguments);
        case 'window':
          final data = Map<String, Object?>.from(call.arguments as Map);
          final id = data['id'] as String;
          final window = PluginWindow(
            id: id,
            title: data['title'] as String,
            message: data['message'] as String,
            buttonLabel: data['buttonLabel'] as String,
          );
          final next = [...windows.value];
          final index = next.indexWhere((w) => w.id == id);
          if (index < 0) {
            next.add(window);
          } else {
            next[index] = window;
          }
          windows.value = next;
        case 'hideWindow':
          _hide((call.arguments as Map)['id'] as String);
        case 'log':
          final data = call.arguments as Map;
          log.info('plugin:${data['id']}', '${data['message']}');
      }
      return null;
    });
    void register(
      String command,
      String description,
      Future<Object?> Function(Map<String, Object?>) action,
      Map<String, String> params,
    ) {
      commands.register(
        Command(
          name: command,
          description: description,
          // Packages and plugin settings do not belong in command logs.
          quiet: true,
          params: params,
          handler: (p) async {
            try {
              return CommandResult.ok(await action(p));
            } catch (error) {
              return CommandResult.fail(_errorText(error));
            }
          },
        ),
      );
    }

    register(
      'getPluginVoiceSkinThumbnail',
      'Read the picture a plugin voice skin shows in the Skin picker.',
      (p) async {
        final bytes = await voiceSkinThumbnail(p['id'] as String? ?? '');
        if (bytes == null) return null;
        return {'mime': _imageMime(bytes), 'data': base64Encode(bytes)};
      },
      const {'id': 'Installed plugin declaring the voice.skin capability'},
    );
    register(
      'getPluginIcon',
      'Read the icon an installed plugin names in its manifest.',
      (p) async {
        final bytes = await pluginIcon(p['id'] as String? ?? '');
        if (bytes == null) return null;
        return {'mime': _imageMime(bytes), 'data': base64Encode(bytes)};
      },
      const {'id': 'Installed plugin ID'},
    );
    register(
      'getPluginShizukuState',
      'Read Shizuku availability and the permission granted to KS.',
      (_) => refreshShizuku(),
      const {},
    );
    register(
      'requestPluginShizukuPermission',
      'Ask Shizuku to show its permission prompt on the kiosk.',
      (p) => refreshShizuku(requestFor: p['id'] as String? ?? ''),
      const {'id': 'Installed plugin declaring the shizuku capability'},
    );
    register(
      'getPluginReadings',
      'Read current plugin readings without refreshing settings.',
      (p) async => readings.value[p['id']] ?? const [],
      const {'id': 'Plugin ID'},
    );
    register(
      'getPluginCharts',
      'Read current plugin chart snapshots without refreshing settings.',
      (p) async => charts.value[p['id']] ?? const [],
      const {'id': 'Plugin ID'},
    );
    register(
      'getPluginStatusTiles',
      'Read the Overview status tiles published by running plugins.',
      (_) async => statusTileList,
      const {},
    );
    register(
      'getPluginActions',
      'List declared plugin actions and their availability.',
      (_) async => actions,
      const {},
    );
    register(
      'getPluginTriggers',
      'List declared plugin gesture triggers and their availability.',
      (_) async => triggers,
      const {},
    );
    register(
      'configurePluginAction',
      'Choose where a plugin action is available.',
      (p) => update('configureAction', p),
      const {
        'id': 'Plugin ID',
        'command': 'Command ID',
        'drawer': 'Show in kiosk drawer',
        'homeAssistant': 'Expose an ESPHome button',
      },
    );
    register(
      'getPluginEntities',
      'Read active plugin entities.',
      (_) async => _entities,
      const {},
    );
    register(
      'pluginEntityCommand',
      'Send a command to an active plugin entity.',
      (p) async {
        final entity = _entities
            .where((e) => e['objectId'] == p['objectId'])
            .firstOrNull;
        if (entity == null) throw StateError('Plugin entity is not available');
        if (entity['type'] == 'button') {
          return update('execute', {
            'id': entity['pluginId'],
            'command': entity['command'],
          });
        }
        if (!const ['light', 'select', 'switch'].contains(entity['type'])) {
          throw StateError('Plugin entity is read-only');
        }
        if (entity['type'] == 'select' &&
            !(entity['options'] as List).contains(p['value'])) {
          throw ArgumentError('Selection is not an advertised option');
        }
        if (entity['type'] == 'switch' && p['value'] is! bool) {
          throw ArgumentError('Switch command must be boolean');
        }
        return update('entityCommand', {
          'id': entity['pluginId'],
          'key': entity['key'],
          'type': entity['type'],
          'value': p['value'],
        });
      },
      const {
        'objectId': 'Plugin entity object ID',
        'value': 'Light command map, select option string or switch boolean',
      },
    );
    register(
      'listPlugins',
      'List installed plugins and their settings.',
      (_) => refresh(),
      const {},
    );
    register(
      'getPluginState',
      'Read the master plugin switch and installed plugins.',
      (_) => getState(),
      const {},
    );
    register(
      'setPluginsEnabled',
      'Enable or pause plugin execution without changing individual plugin choices.',
      (p) {
        if (p['enabled'] is! bool) {
          throw const FormatException('Missing enabled flag');
        }
        return setEnabled(p['enabled'] as bool);
      },
      const {'enabled': 'Master plugin switch'},
    );
    register(
      'previewPluginRepository',
      'Read a public GitHub plugin manifest and README before installation.',
      (p) => previewRepository(p['url'] as String? ?? ''),
      const {'url': 'Public GitHub repository URL'},
    );
    register(
      'getPluginDirectory',
      'Read Community Plugins, the plugin directory, with how each listed plugin stands against the installed ones.',
      (p) => directoryState(refresh: p['refresh'] == true),
      const {'refresh': 'True to download the list again now'},
    );
    register(
      'checkPluginUpdate',
      'Check an installed plugin repository for an updated release without installing it.',
      (p) => checkUpdate(p['id'] as String? ?? ''),
      const {'id': 'Installed plugin ID'},
    );
    register(
      'installPluginRepository',
      'Install the release from a reviewed repository preview.',
      (p) => installRepository(
        p['previewId'] as String? ?? '',
        trusted: p['trusted'] == true,
      ),
      const {
        'previewId': 'ID returned by previewPluginRepository',
        'trusted': 'Explicit trust acknowledgment',
      },
    );
    register(
      'installPlugin',
      'Install a local plugin ZIP for development. New plugins start disabled. Updates preserve the enabled state.',
      (p) async {
        if (p['trusted'] != true) {
          throw StateError('Confirm that you trust the plugin author');
        }
        final data = p['data'];
        if (data is! String ||
            data.isEmpty ||
            data.length > ((maxZipBytes + 2) ~/ 3) * 4) {
          throw const FormatException('Plugin ZIP must be at most 4 MB');
        }
        return installZip(base64Decode(data), trusted: true);
      },
      const {
        'data': 'Base64-encoded plugin ZIP, at most 4 MB',
        'trusted': 'Explicit trust acknowledgment',
      },
    );
    for (final entry in {
      'enablePlugin': 'enable',
      'disablePlugin': 'disable',
      'removePlugin': 'remove',
    }.entries) {
      register(
        entry.key,
        '${entry.value} an installed plugin.',
        (p) => update(entry.value, p),
        const {'id': 'Plugin ID'},
      );
    }
    register(
      'configurePlugin',
      'Save validated plugin settings.',
      (p) => update('configure', p),
      const {
        'id': 'Plugin ID',
        'values': 'Settings object, complete unless patch is set',
        'patch': 'True to save only the settings in values',
      },
    );
    register(
      'searchIcons',
      'Find Material Design Icons by name, with their SVG paths, for icon settings.',
      (p) async {
        final names = p['names'];
        final picked = names is List
            ? [for (final name in names.take(100)) '$name']
            : await MdiIcons.search(
                '${p['query'] ?? ''}',
                limit: ((p['limit'] as num?)?.toInt() ?? 60).clamp(1, 200),
              );
        final paths = await MdiIcons.paths(picked);
        return [
          for (final name in picked.map(MdiIcons.normalize))
            if (paths[name] != null) {'name': 'mdi:$name', 'path': paths[name]},
        ];
      },
      const {
        'query': 'Words the icon name contains. Empty lists the first icons.',
        'names': 'Exact icon names to resolve instead of a search, at most 100',
        'limit': 'Most results to return, 60 unless set, at most 200',
      },
    );
    register(
      'getPluginSetup',
      'Read the settings button runs and listed choices of a running plugin. choiceRevisions changes with each new list, so a caller that passes the revisions it holds gets only the lists that changed.',
      (p) async => _remoteSetup(p['id'] as String? ?? '', p['choiceRevisions']),
      const {
        'id': 'Plugin ID',
        'choiceRevisions':
            'Optional. The revision of each choices list held, by key. Only lists with another revision come back',
      },
    );
    register(
      'setPluginPageOpen',
      'Tell a plugin that its settings page is open in this browser. Repeat it while the page stays open: the page counts as closed ${remotePageTimeout.inSeconds} seconds after the last call, or right away with open false.',
      (p) async {
        final id = p['id'] as String? ?? '';
        if (!installed.value.any((plugin) => plugin['id'] == id)) {
          throw StateError('Plugin is not installed');
        }
        settingsPageViewer(
          id,
          'remote:${p['viewer'] ?? ''}',
          open: p['open'] != false,
          timeout: remotePageTimeout,
        );
        return null;
      },
      const {
        'id': 'Plugin ID',
        'viewer': 'An ID for this page, the same on every call',
        'open': 'False when the page closes. True unless set',
      },
    );
    register(
      'runPluginSetup',
      'Press a settings button or ask a plugin to refresh the choices of a setting. The plugin answers through the run.',
      (p) => runSetup(
        p['id'] as String? ?? '',
        target: p['target'] as String? ?? '',
        key: p['key'] as String? ?? '',
        origin: 'remote',
      ),
      const {
        'id': 'Plugin ID',
        'target': 'button or choices',
        'key': 'Button ID or setting key',
      },
    );
    register(
      'cancelPluginSetup',
      'Cancel a running settings button or choices refresh.',
      (p) => cancelSetup(p['id'] as String? ?? '', p['run'] as String? ?? ''),
      const {'id': 'Plugin ID', 'run': 'Run ID'},
    );
    register(
      'answerPluginSetup',
      'Answer the question a plugin asked during a run.',
      (p) => answerSetup(
        p['id'] as String? ?? '',
        p['run'] as String? ?? '',
        accepted: p['accepted'] == true,
      ),
      const {
        'id': 'Plugin ID',
        'run': 'Run ID',
        'accepted': 'True to go ahead',
      },
    );
    register(
      'runPluginCommand',
      'Run a declared command of an enabled plugin.',
      (p) => update('execute', p),
      const {
        'id': 'Plugin ID',
        'command': 'Command ID from the plugin manifest',
      },
    );
    // Plugin startup must not hold up the dashboard or remote administration.
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await update('initialize', const {});
    } catch (error) {
      if (_disposed) return;
      status.value = _errorText(error);
      log.warn(name, status.value);
    }
  }

  Future<Map<String, Object?>> previewRepository(String url) async {
    final preview = await repository.preview(url);
    final compatibility = await channel
        .invokeMapMethod<String, Object?>('validateManifest', {
          'manifest': jsonEncode(preview['manifest']),
        })
        .timeout(const Duration(seconds: 10));
    final listing = await directory.lookup(preview['repository'] as String);
    return {
      ...preview,
      ...?compatibility,
      'listed': listing?.listed,
      'icon': ?listing?.icon,
    };
  }

  /// Community Plugins with each entry's install state, for Browse plugins.
  Future<Map<String, Object?>> directoryState({bool refresh = false}) async {
    final data = await directory.read(refresh: refresh);
    try {
      await this.refresh();
    } catch (_) {}
    final byId = {for (final p in installed.value) p['id']: p};
    return {
      ...data,
      'plugins': [
        for (final entry in data['plugins'] as List)
          {
            ...entry as Map<String, Object?>,
            ...PluginDirectory.installStatus(
              entry,
              byId[entry['id']],
              appVersion: appVersion(),
            ),
          },
      ],
    };
  }

  Future<Map<String, Object?>> checkUpdate(String id) async {
    await refresh();
    final plugin = installed.value.where((p) => p['id'] == id).firstOrNull;
    if (plugin == null) throw StateError('Plugin is not installed');
    if (fleetManaged(id)) {
      throw StateError('The fleet leader keeps this plugin up to date');
    }
    final source = plugin['source'];
    if (source is! Map || source['repository'] is! String) {
      throw StateError(
        'This plugin was installed from ZIP. Use Install from ZIP to update it.',
      );
    }
    final preview = await previewRepository(source['repository'] as String);
    return {
      ...preview,
      'installedVersion': plugin['version'],
      'updateAvailable': PluginRepository.hasUpdate(preview, plugin),
    };
  }

  Future<List<Map<String, Object?>>> installRepository(
    String token, {
    required bool trusted,
  }) async {
    final Map<String, Object?> args;
    try {
      args = await repository.installArguments(token, trusted: trusted);
    } catch (_) {
      onActivity?.call('plugin_install_failures');
      rethrow;
    }
    return update('install', args);
  }

  Future<List<Map<String, Object?>>> installZipStream(
    Stream<List<int>> stream, {
    required bool trusted,
  }) async {
    if (!trusted) throw StateError('Confirm that you trust the plugin author');
    final data = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (data.length + chunk.length > maxZipBytes) {
        throw const FormatException('Plugin ZIP must be at most 4 MB');
      }
      data.add(chunk);
    }
    return installZip(data.takeBytes(), trusted: true);
  }

  Future<List<Map<String, Object?>>> installZip(
    Uint8List bytes, {
    required bool trusted,
  }) async {
    if (!trusted) throw StateError('Confirm that you trust the plugin author');
    if (bytes.isEmpty || bytes.length > maxZipBytes) {
      throw const FormatException('Plugin ZIP must be at most 4 MB');
    }
    return update('install', {'bytes': bytes, 'trusted': true});
  }

  Map<String, Object?> get _state => {
    'enabled': enabled.value,
    'plugins': [
      for (final p in installed.value)
        if (fleetManaged('${p['id']}')) {...p, 'fleetManaged': true} else p,
    ],
  };

  Future<Map<String, Object?>> refreshShizuku({String? requestFor}) async {
    final value = await channel
        .invokeMapMethod<String, Object?>(
          requestFor == null ? 'shizukuState' : 'requestShizukuPermission',
          requestFor == null ? null : {'id': requestFor},
        )
        .timeout(const Duration(seconds: 10));
    final state = value ?? const <String, Object?>{'status': 'unavailable'};
    if (!_disposed) shizuku.value = state;
    return state;
  }

  Future<Map<String, Object?>> getState() async {
    await refresh();
    return _state;
  }

  Future<Map<String, Object?>> setEnabled(bool value) async {
    await update('setEnabled', {'enabled': value});
    return _state;
  }

  Future<List<Map<String, Object?>>> refresh() => update('list', const {});

  // ── Fleet Management ────────────────────────────────────────────────

  @override
  Future<List<Map<String, Object?>>> fleetState() async {
    final value = await channel
        .invokeMethod<Object?>('fleetState')
        .timeout(const Duration(seconds: 10));
    // Through JSON: the channel hands nested maps typed Object? keys.
    final list = jsonDecode(jsonEncode(value ?? const []));
    return [
      for (final item in list as List)
        if (item is Map) item.cast<String, Object?>(),
    ];
  }

  @override
  Future<String?> fleetPackage(String id) async {
    final path = await channel
        .invokeMethod<String>('packagePath', {'id': id})
        .timeout(const Duration(seconds: 10));
    if (path != null) return path;
    // Installed before packages were kept: a repository release can be
    // fetched again by its tag, pinned to the hash it was installed with.
    final plugin = (await fleetState()).where((p) => p['id'] == id).firstOrNull;
    final source = plugin?['source'];
    if (plugin == null ||
        source is! Map ||
        source['repository'] is! String ||
        source['releaseTag'] is! String) {
      return null;
    }
    final bytes = await repository.downloadRelease(
      repository: source['repository'] as String,
      tag: source['releaseTag'] as String,
      id: id,
      version: '${plugin['version']}',
      digest: '${plugin['sha256']}',
    );
    return channel
        .invokeMethod<String>('keepPackage', {'id': id, 'bytes': bytes})
        .timeout(const Duration(seconds: 30));
  }

  @override
  Future<void> fleetInstall(
    Uint8List bytes, {
    required String sha256,
    Map<String, Object?>? source,
  }) async {
    if (bytes.isEmpty || bytes.length > maxZipBytes) {
      throw const FormatException('Plugin ZIP must be at most 4 MB');
    }
    await update('install', {
      'bytes': bytes,
      'trusted': true,
      'sha256': sha256,
      if (source != null) 'source': jsonEncode(source),
    }, counted: false);
  }

  @override
  Future<void> fleetConfigure(String id, Map<String, Object?> entry) =>
      update('fleetConfigure', {
        'id': id,
        'enabled': entry['enabled'] == true,
        'config': entry['config'] ?? const {},
        'actionOptions': entry['actionOptions'] ?? const {},
      });

  @override
  Future<void> fleetRemove(String id) =>
      update('remove', {'id': id}, counted: false);

  Future<List<Map<String, Object?>>> update(
    String method,
    Map<String, Object?> args, {
    bool counted = true,
  }) async {
    final count = counted && (method == 'install' || method == 'remove');
    final before = count
        ? {for (final p in installed.value) '${p['id']}'}
        : const <String>{};
    try {
      final result = await channel
          .invokeMethod<Object?>(method, args)
          .timeout(const Duration(seconds: 60));
      if (!_disposed) {
        _readInstalled(result);
        status.value = '';
      }
      if (method == 'remove' && args['id'] is String) {
        onRemoved?.call(args['id'] as String);
      }
      if (count) unawaited(_countActivity(method, args, before));
      return installed.value;
    } catch (error) {
      if (!_disposed) status.value = _errorText(error);
      if (count && method == 'install') {
        onActivity?.call('plugin_install_failures');
      }
      rethrow;
    }
  }

  /// Names what a user's install or removal did, for [onActivity]: a new
  /// plugin by where it came from, a plugin already there as an update.
  Future<void> _countActivity(
    String method,
    Map<String, Object?> args,
    Set<String> before,
  ) async {
    final report = onActivity;
    if (report == null) return;
    if (method == 'remove') return report('plugin_removals');
    final added = installed.value.any((p) => !before.contains('${p['id']}'));
    if (!added) return report('plugin_updates');
    String? repo;
    try {
      final source = args['source'];
      final decoded = source is String ? jsonDecode(source) : null;
      if (decoded is Map && decoded['repository'] is String) {
        repo = decoded['repository'] as String;
      }
    } catch (_) {}
    if (repo == null) return report('plugin_installs_zip');
    final listed = await directory.lists(repo);
    report(
      listed == true ? 'plugin_installs_directory' : 'plugin_installs_github',
    );
  }

  /// Starts a settings button ([target] `button`) or a choices refresh
  /// (`choices`) and returns the run's id.
  Future<String> runSetup(
    String id, {
    required String target,
    required String key,
    String origin = 'device',
  }) async {
    final result = await _setupCall('setupRun', {
      'id': id,
      'target': target,
      'key': key,
      'origin': origin,
    });
    return '${(result as Map)['run']}';
  }

  /// Opens or closes one [viewer] of plugin [id]'s settings page. The
  /// plugin hears settings.page when the first viewer opens it and when the
  /// last one closes it. A [timeout] closes the viewer unless it opens again
  /// before then.
  void settingsPageViewer(
    String id,
    Object viewer, {
    required bool open,
    Duration? timeout,
  }) {
    if (_disposed) return;
    final viewers = _pageViewers[id] ??= {};
    viewers.remove(viewer)?.cancel();
    if (open) {
      viewers[viewer] = timeout == null
          ? null
          : Timer(timeout, () => settingsPageViewer(id, viewer, open: false));
    }
    if (viewers.isEmpty) _pageViewers.remove(id);
    final next = _pageViewers.containsKey(id);
    if (next != _pagesOpen.contains(id)) _sendSettingsPage(id, next);
  }

  /// The host passes the state on to the plugin's running session, if any,
  /// and skips a state that session already heard.
  void _sendSettingsPage(String id, bool open) {
    open ? _pagesOpen.add(id) : _pagesOpen.remove(id);
    unawaited(
      channel
          .invokeMethod<void>('settingsPage', {'id': id, 'open': open})
          .catchError((_) {}),
    );
  }

  Future<void> cancelSetup(String id, String run) =>
      _setupCall('setupCancel', {'id': id, 'run': run});

  Future<void> answerSetup(String id, String run, {required bool accepted}) =>
      _setupCall('setupConfirm', {'id': id, 'run': run, 'accepted': accepted});

  Future<Object?> _setupCall(String method, Map<String, Object?> args) async {
    try {
      return await channel
          .invokeMethod<Object?>(method, args)
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      throw PluginSetupError(_errorText(error));
    }
  }

  /// Takes the host's setup update. Choice lists can be large, so the host
  /// sends each one only when its revision changes, and the lists already
  /// held stay for the keys it still names.
  void _setSetup(String id, Map? value) {
    final previous = setup.value[id];
    if (value == null) {
      if (previous != null) setup.value = {...setup.value}..remove(id);
      return;
    }
    final sent = value['choices'] as Map? ?? const {};
    final revisions = value['choiceRevisions'] as Map?;
    final held = previous?['choices'] as Map? ?? const {};
    final runs = jsonDecode(jsonEncode(value['runs'] ?? const {}));
    final off = [...?(value['choicesOff'] as List?)];
    final next = <String, Object?>{
      'runs': runs,
      'choiceRevisions': {...?revisions},
      'choicesOff': off,
      'choices': {
        for (final key in revisions?.keys ?? sent.keys)
          if (sent.containsKey(key))
            '$key': jsonDecode(jsonEncode(sent[key]))
          else if (held.containsKey(key))
            '$key': held[key],
      },
    };
    if (sent.isEmpty &&
        previous != null &&
        jsonEncode(previous['runs']) == jsonEncode(runs) &&
        jsonEncode(previous['choicesOff']) == jsonEncode(off) &&
        jsonEncode(previous['choiceRevisions']) ==
            jsonEncode(next['choiceRevisions'])) {
      return;
    }
    setup.value = {...setup.value, id: next};
  }

  /// A plugin's setup for the remote API. Given the revisions a caller
  /// [held], only the lists that changed since come along. Choice icons
  /// travel as path data, the way the remote pickers draw them.
  Future<Map<String, Object?>> _remoteSetup(String id, Object? held) async {
    final state = setup.value[id];
    final revisions = state?['choiceRevisions'] as Map? ?? const {};
    final choices = state?['choices'] as Map? ?? const {};
    final sent = held is Map
        ? {
            for (final entry in choices.entries)
              if (!revisions.containsKey(entry.key) ||
                  '${held[entry.key]}' != '${revisions[entry.key]}')
                entry.key: entry.value,
          }
        : choices;
    final icons = {
      for (final list in sent.values.whereType<List>())
        for (final choice in list.whereType<Map>())
          if (choice['icon'] is String) choice['icon'] as String,
    };
    final paths = icons.isEmpty
        ? const <String, String>{}
        : await MdiIcons.paths(icons);
    return {
      'runs': state?['runs'] ?? const {},
      'choiceRevisions': revisions,
      'choicesOff': state?['choicesOff'] ?? const [],
      'choices': paths.isEmpty
          ? sent
          : {
              for (final entry in sent.entries)
                entry.key: [
                  for (final choice in (entry.value as List).whereType<Map>())
                    if (paths[MdiIcons.normalize('${choice['icon'] ?? ''}')]
                        case final path?)
                      {...choice, 'iconPath': path}
                    else
                      choice,
                ],
            },
    };
  }

  void _setScreensavers(String id, List value) {
    final next = {...screensavers.value}
      ..removeWhere((_, item) => item['pluginId'] == id);
    for (final raw in value.whereType<Map>()) {
      next['plugin:$id:${raw['key']}'] = {
        ...Map<String, Object?>.from(raw),
        'pluginId': id,
      };
    }
    if (jsonEncode(next) != jsonEncode(screensavers.value)) {
      screensavers.value = next;
    }
  }

  /// Every running plugin's tiles in one list, with the owning plugin named
  /// so the Overview can show where each one comes from.
  List<Map<String, Object?>> get statusTileList => [
    for (final entry in statusTiles.value.entries)
      for (final tile in entry.value)
        {
          ...tile,
          'pluginId': entry.key,
          'pluginName':
              installed.value
                  .where((p) => p['id'] == entry.key)
                  .firstOrNull?['name'] ??
              entry.key,
        },
  ];

  void _setStatusTiles(String id, List value) {
    final next = value.map((v) => Map<String, Object?>.from(v as Map)).toList();
    if (jsonEncode(statusTiles.value[id] ?? const []) == jsonEncode(next)) {
      return;
    }
    statusTiles.value = {...statusTiles.value}
      ..remove(id)
      ..addAll(next.isEmpty ? {} : {id: next});
  }

  void _setCharts(String id, List value) {
    final next = value.map((v) => Map<String, Object?>.from(v as Map)).toList();
    if (jsonEncode(charts.value[id] ?? const []) == jsonEncode(next)) return;
    charts.value = {...charts.value}
      ..remove(id)
      ..addAll(next.isEmpty ? {} : {id: next});
  }

  void _setEntities(String id, List value) {
    final next = value.map((v) => Map<String, Object?>.from(v as Map)).toList();
    if (jsonEncode(_runtimeEntities[id] ?? const []) == jsonEncode(next)) {
      return;
    }
    if (next.isEmpty) {
      _runtimeEntities.remove(id);
    } else {
      _runtimeEntities[id] = next;
    }
    _refreshEntities();
  }

  void _readInstalled(Object? value) {
    if (value is Map) {
      enabled.value = value['enabled'] == true;
      value = value['plugins'];
    }
    if (value is! List) return;
    final items = [
      for (final item in value) Map<String, Object?>.from(item as Map),
    ];
    for (final item in items) {
      _setScreensavers(
        item['id'] as String,
        enabled.value && item['running'] == true
            ? item.remove('screensavers') as List? ?? const []
            : const [],
      );
      item.remove('screensavers');
      final data = item.remove('charts');
      final tiles = item.remove('statusTiles');
      final entities = item.remove('entities') as List? ?? const [];
      _runtimeEntities[item['id']
          as String] = enabled.value && item['running'] == true
          ? entities.map((e) => Map<String, Object?>.from(e as Map)).toList()
          : const [];
      if (!enabled.value || item['running'] != true) {
        _runtimeSessions.remove(item['id']);
        _setContentInsets(item['id'] as String, null);
      }
      _setCharts(
        item['id'] as String,
        enabled.value && item['running'] == true
            ? data as List? ?? const []
            : const [],
      );
      _setStatusTiles(
        item['id'] as String,
        enabled.value && item['running'] == true
            ? tiles as List? ?? const []
            : const [],
      );
    }
    for (final id in statusTiles.value.keys.toList()) {
      if (!items.any((p) => p['id'] == id)) _setStatusTiles(id, const []);
    }
    for (final id
        in screensavers.value.values
            .map((s) => s['pluginId'] as String)
            .toSet()) {
      if (!items.any((p) => p['id'] == id)) _setScreensavers(id, const []);
    }
    for (final id in charts.value.keys.toList()) {
      if (!items.any((p) => p['id'] == id)) {
        _runtimeSessions.remove(id);
        _setCharts(id, const []);
      }
    }
    for (final id in _contentInsets.keys.toList()) {
      if (!items.any((p) => p['id'] == id)) _setContentInsets(id, null);
    }
    _runtimeEntities.removeWhere(
      (id, _) => !items.any(
        (item) => item['id'] == id && item['running'] == true && enabled.value,
      ),
    );
    installed.value = [for (final item in items) item];
    _refreshEntities();
    final running = installed.value
        .where((p) => p['running'] == true)
        .map((p) => p['id'])
        .toSet();
    windows.value = windows.value.where((w) => running.contains(w.id)).toList();
    if (overlays.value.any((o) => !running.contains(o.pluginId))) {
      overlays.value = overlays.value
          .where((o) => running.contains(o.pluginId))
          .toList();
    }
  }

  /// Replaces one plugin's overlays and keeps the stacking order: overlays
  /// already showing stay where they are, with their measured size, and new
  /// or replaced ones go on top.
  void _setOverlays(String pluginId, List value) {
    final session = _runtimeSessions[pluginId];
    final incoming = <String, PluginNativeOverlay>{
      if (session != null)
        for (final raw in value.whereType<Map>())
          for (final overlay in [
            PluginNativeOverlay(
              pluginId: pluginId,
              session: session,
              key: raw['key'] as String,
              generation: (raw['generation'] as num).toInt(),
              anchor: raw['anchor'] as String,
              width: (raw['width'] as num).toInt(),
              height: (raw['height'] as num).toInt(),
              insets: _insets(raw['insets']),
              offset: Offset(
                (raw['offsetX'] as num? ?? 0).toDouble(),
                (raw['offsetY'] as num? ?? 0).toDouble(),
              ),
              closeOnBack: raw['closeOnBack'] == true,
              onTop: raw['onTop'] == true,
              touchable: raw['touchable'] != false,
              closeOnOutsideTouch: raw['closeOnOutsideTouch'] == true,
              passOutsideTouch: raw['passOutsideTouch'] == true,
              enter: raw['enter'] as String? ?? 'none',
              exit: raw['exit'] as String? ?? 'none',
              duration: Duration(
                milliseconds: (raw['duration'] as num? ?? 200).toInt(),
              ),
            ),
          ])
            overlay.id: overlay,
    };
    final showing = {for (final overlay in overlays.value) overlay.id};
    final next = [
      for (final overlay in overlays.value)
        if (overlay.pluginId != pluginId || incoming.containsKey(overlay.id))
          overlay,
      for (final overlay in incoming.values)
        if (!showing.contains(overlay.id)) overlay,
    ];
    if (next.length != overlays.value.length ||
        incoming.values.any((o) => !showing.contains(o.id))) {
      overlays.value = next;
    }
  }

  static EdgeInsets _insets(Object? raw) {
    final sides = [
      for (final side in raw is List ? raw : const []) (side as num).toDouble(),
    ];
    return sides.length == 4
        ? EdgeInsets.fromLTRB(sides[0], sides[1], sides[2], sides[3])
        : EdgeInsets.zero;
  }

  /// Whether the session that showed [overlay] still runs. An overlay of
  /// an ended session leaves at once, with no exit transition.
  bool overlaySessionLive(PluginNativeOverlay overlay) =>
      _runtimeSessions[overlay.pluginId] == overlay.session;

  /// The overlay a back press closes: the topmost that allows it.
  PluginNativeOverlay? get backOverlay =>
      overlays.value.where((o) => o.closeOnBack).lastOrNull;

  /// Back closed an overlay. It goes at once, and the plugin hears
  /// overlay.closed unless it replaced the overlay in the meantime.
  Future<void> closeOverlay(PluginNativeOverlay overlay) async {
    overlays.value = overlays.value.where((o) => o.id != overlay.id).toList();
    try {
      await channel
          .invokeMethod<void>('overlayClosed', {
            'id': overlay.pluginId,
            'session': overlay.session,
            'key': overlay.key,
            'generation': overlay.generation,
          })
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      log.warn('plugin:${overlay.pluginId}', _errorText(error));
    }
  }

  /// The theme new overlay views start with, and live ones restyle to.
  /// Native hears it only when it changes.
  Map<String, Object?> overlayTheme(Map<String, Object?> next) {
    if (jsonEncode(next) != jsonEncode(_overlayTheme)) {
      _overlayTheme = next;
      unawaited(
        channel.invokeMethod<void>('overlayTheme', next).catchError((_) {}),
      );
    }
    return _overlayTheme!;
  }

  void _refreshEntities() {
    // Keep live readings separate from settings and independent of ESPHome.
    final nextReadings = <String, List<Map<String, Object?>>>{
      for (final entry in _runtimeEntities.entries)
        if (enabled.value && entry.value.isNotEmpty) entry.key: entry.value,
    };
    if (jsonEncode(readings.value) != jsonEncode(nextReadings)) {
      readings.value = nextReadings;
    }
    final nextEntities = <Map<String, Object?>>[
      for (final action in actions)
        if (action['available'] == true && action['homeAssistant'] == true)
          {
            'objectId':
                'plugin_${action['pluginId'].toString().replaceAll('-', '_')}___${action['command'].toString().replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')}',
            'pluginId': action['pluginId'],
            'command': action['command'],
            'name': '${action['pluginName']}: ${action['title']}',
            'type': 'button',
            'icon': 'mdi:puzzle',
          },
      for (final plugin in installed.value)
        if (enabled.value && plugin['running'] == true)
          for (final light
              in (plugin['lights'] as List? ?? const []).whereType<Map>())
            {
              'objectId':
                  'plugin_${plugin['id'].toString().replaceAll('-', '_')}__${light['key']}',
              'pluginId': plugin['id'],
              'key': light['key'],
              'name': light['name'],
              'type': 'light',
              'icon': 'mdi:led-on',
              'colorCapable': true,
              'effects': light['effects'],
              'state': light['state'],
            },
      for (final plugin in installed.value)
        if (enabled.value && plugin['running'] == true)
          for (final entity
              in _runtimeEntities[plugin['id']] ??
                  const <Map<String, Object?>>[])
            {
              ...entity,
              'objectId':
                  'plugin_${plugin['id'].toString().replaceAll('-', '_')}____${entity['type']}_${entity['key']}',
              'pluginId': plugin['id'],
              'name': '${plugin['name']}: ${entity['name']}',
              'icon': switch (entity['type']) {
                'sensor' => 'mdi:gauge',
                'text_sensor' => 'mdi:text-box-outline',
                'binary_sensor' => 'mdi:checkbox-marked-circle-outline',
                'switch' => 'mdi:toggle-switch',
                _ => 'mdi:form-select',
              },
            },
    ];
    List<Map<String, Object?>> catalog(List<Map<String, Object?>> entries) => [
      for (final entry in entries) {...entry}..remove('state'),
    ];
    final previousEntities = _entities;
    _entities = nextEntities;
    // Only these entity types support a missing-state frame in ESPHome.
    for (final previous in previousEntities) {
      if (const [
            'sensor',
            'text_sensor',
            'binary_sensor',
            'select',
          ].contains(previous['type']) &&
          !nextEntities.any((e) => e['objectId'] == previous['objectId'])) {
        bus.publish(
          PluginEntityStateChanged(previous['objectId'] as String, null),
        );
      }
    }
    if (jsonEncode(catalog(nextEntities)) !=
        jsonEncode(catalog(previousEntities))) {
      bus.publish(const PluginEntityCatalogChanged());
    }
    for (final entity in nextEntities) {
      if (entity['type'] == 'button') continue;
      final previous = previousEntities
          .where((e) => e['objectId'] == entity['objectId'])
          .firstOrNull;
      if (previous == null ||
          jsonEncode(previous['state']) != jsonEncode(entity['state'])) {
        bus.publish(
          PluginEntityStateChanged(
            entity['objectId'] as String,
            entity['state'],
          ),
        );
      }
    }
  }

  void _hide(String id) =>
      windows.value = windows.value.where((w) => w.id != id).toList();

  Future<void> windowEvent(String id, {required bool closed}) async {
    if (closed) _hide(id);
    try {
      await channel
          .invokeMethod<void>('windowEvent', {
            'id': id,
            'event': closed ? 'window.closed' : 'window.action',
          })
          .timeout(const Duration(seconds: 10));
    } catch (error) {
      log.warn('plugin:$id', _errorText(error));
    }
  }

  String _errorText(Object error) => error is PlatformException
      ? error.message ?? error.code
      : error is MissingPluginException
      ? 'Plugins are available on Android.'
      : '$error';

  @override
  Future<void> dispose() async {
    _disposed = true;
    for (final viewers in _pageViewers.values) {
      for (final timer in viewers.values) {
        timer?.cancel();
      }
    }
    _pageViewers.clear();
    await _attachSub?.cancel();
    await _hostReads.dispose();
    haSocket?.dispose();
    maSocket?.dispose();
    repository.close();
    channel.setMethodCallHandler(null);
    try {
      await channel
          .invokeMethod<void>('stopAll')
          .timeout(const Duration(seconds: 30));
    } catch (_) {}
    readings.dispose();
    charts.dispose();
    statusTiles.dispose();
    setup.dispose();
    screensavers.dispose();
    installed.dispose();
    windows.dispose();
    overlays.dispose();
    overlayEpoch.dispose();
    contentInsets.dispose();
    shizuku.dispose();
    status.dispose();
    enabled.dispose();
  }
}
