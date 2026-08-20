import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../home_assistant/home_assistant_manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'models.dart';

class CameraManager extends Manager {
  CameraManager(
    super.bus,
    super.commands,
    super.log,
    this._settings,
    this._homeAssistant,
  );

  final SettingsManager _settings;

  /// Streams `ha`-kind cameras through Home Assistant's own WebRTC
  /// signaling (issue #124); same composition-root reference pattern as
  /// the glance manager.
  final HomeAssistantManager _homeAssistant;

  /// Open HA signaling sessions by camera id: each carries the backend's
  /// trickled ICE candidates for one live stream, so it must outlive the
  /// negotiation and die with the stream.
  final _haSessions = <String, HaWebRtcSession>{};

  /// Set by the active camera surface (the view overlay / screensaver
  /// player): routes a backend ICE candidate into that page's peer
  /// connection. Composition wiring, not a manager reference.
  void Function(String cameraId, Map<String, Object?> candidate)?
  onRemoteCandidate;

  @override
  String get name => 'camera';

  CameraConfiguration _config = const CameraConfiguration();
  CameraConfiguration get config => _config;

  final activeViewId = ValueNotifier<String?>(null);
  final focusedCameraId = ValueNotifier<String?>(null);

  bool _saving = false;
  bool _voiceActive = false;
  int _voiceChange = 0;
  String? _interruptedViewId;
  String? _interruptedCameraId;
  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<VoiceInteractionChanged>? _voiceSub;

  /// Auto-dismiss: an open view closes on its own after the configured time.
  /// Armed off the [activeViewId] listener so every way of opening a view is
  /// covered (gesture, MQTT, drawer, the restore after a voice turn) and
  /// nothing else needs to know. The screensaver's camera mode renders its
  /// own surface and never touches [activeViewId], so it is exempt by
  /// construction. Focusing a camera re-arms the countdown: a tap on the
  /// view is someone using it.
  Timer? _autoDismiss;

  CameraViewConfig? get activeView {
    final id = activeViewId.value;
    if (id == null) return null;
    return _config.views.where((view) => view.id == id).firstOrNull;
  }

  void _armAutoDismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    if (activeViewId.value == null) return;
    final seconds = _settings.get(defs.cameraAutoDismissSeconds).toInt();
    if (seconds <= 0) return;
    _autoDismiss = Timer(Duration(seconds: seconds), () {
      if (activeViewId.value == null) return;
      log.info(name, 'camera view auto-dismissed after ${seconds}s');
      hideView();
    });
  }

  @override
  Future<void> init() async {
    _load();
    activeViewId.addListener(_armAutoDismiss);
    focusedCameraId.addListener(_armAutoDismiss);
    _settingsSub = bus.on<SettingChanged>().listen((event) {
      if (event.key == defs.cameraAutoDismissSeconds.key) {
        // A changed duration re-times an already-open view from now.
        _armAutoDismiss();
        return;
      }
      if (event.key != defs.cameraConfig.key || _saving) return;
      _load();
      bus.publish(const CameraConfigurationChanged());
      final active = activeViewId.value;
      if (active != null && !_config.views.any((view) => view.id == active)) {
        hideView();
      } else {
        _publishState();
      }
    });
    _voiceSub = bus.on<VoiceInteractionChanged>().listen(_onVoiceInteraction);

    commands
      ..register(
        Command(
          name: 'cameraGetConfig',
          description:
              'Camera servers, sources, and views. Passwords are masked.',
          handler: (_) async =>
              CommandResult.ok(_config.toJson(includePasswords: false)),
        ),
      )
      ..register(
        Command(
          name: 'cameraPutServer',
          description: 'Create or update a Go2RTC server.',
          params: const {
            'id': 'Existing server id, or empty to create one',
            'name': 'Display name',
            'baseUrl': 'Go2RTC HTTP API base URL',
            'username': 'Optional basic-auth username',
            'password': 'Optional password; omit to preserve an existing one',
            'allowInvalidCertificate':
                'Allow an invalid TLS certificate for this server',
          },
          handler: _putServerCommand,
        ),
      )
      ..register(
        Command(
          name: 'cameraDeleteServer',
          description:
              'Delete a server and remove its cameras from camera views.',
          params: const {'id': 'Server id'},
          handler: (params) async => _deleteServer('${params['id'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'cameraImportGo2Rtc',
          description:
              'Import and merge the stream names exposed by a Go2RTC server.',
          params: const {'serverId': 'Server id'},
          handler: (params) =>
              importGo2RtcStreams('${params['serverId'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'cameraImportHomeAssistant',
          description:
              'Import and merge the camera entities of the connected Home '
              'Assistant (issue #124); they play over WebRTC, HLS or MJPEG '
              'as each entity allows.',
          handler: (_) => importHomeAssistantCameras(),
        ),
      )
      ..register(
        Command(
          name: 'cameraPutSource',
          description: 'Create or update a camera source.',
          params: const {
            'id': 'Existing camera id, or empty to create one',
            'name': 'Display name',
            'kind': 'go2rtc, whep or ha',
            'serverId': 'Go2RTC server id',
            'streamName': 'Go2RTC stream name',
            'whepUrl': 'Direct WHEP endpoint',
            'entityId': 'Home Assistant camera.* entity id (kind ha)',
            'fullscreenStreamName':
                'Optional higher-quality Go2RTC stream for focus mode',
          },
          handler: _putSourceCommand,
        ),
      )
      ..register(
        Command(
          name: 'cameraDeleteSource',
          description: 'Delete a camera and remove it from camera views.',
          params: const {'id': 'Camera id'},
          handler: (params) async => _deleteSource('${params['id'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'cameraPutView',
          description:
              'Create or update a camera view containing 1 to 12 cameras.',
          params: const {
            'id': 'Existing view id, or empty to create one',
            'name': 'Unique display name',
            'cameraIds': 'Ordered list of 1 to 12 camera ids',
            'showCameraNames': 'Show camera names over the video',
            'grid':
                'Optional grid size 1 to 12, at least the camera count; '
                'slots without a camera stay empty',
          },
          handler: _putViewCommand,
        ),
      )
      ..register(
        Command(
          name: 'cameraDeleteView',
          description: 'Delete a camera view.',
          params: const {'id': 'View id'},
          handler: (params) async => _deleteView('${params['id'] ?? ''}'),
        ),
      )
      ..register(
        Command(
          name: 'showCameraView',
          description: 'Show a configured camera view over the dashboard. '
              'With toggle, a view that is already showing closes instead — '
              'gestures pass it so the same gesture opens and closes a view.',
          params: const {
            'viewId': 'Camera view id',
            'toggle': 'true to close the view when it is already showing',
          },
          handler: (params) => showView('${params['viewId'] ?? ''}',
              toggle: params['toggle'] == true),
        ),
      )
      ..register(
        Command(
          name: 'hideCameraView',
          description: 'Close the active camera view.',
          handler: (_) async {
            hideView();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'focusCamera',
          description:
              'Focus one camera in the active view, or clear cameraId for grid.',
          params: const {'cameraId': 'Camera id, or empty for grid'},
          handler: (params) async {
            final id = '${params['cameraId'] ?? ''}';
            return focusCamera(id.isEmpty ? null : id);
          },
        ),
      )
      ..register(
        Command(
          name: 'cameraStatus',
          description: 'The active camera view and focused camera.',
          handler: (_) async => CommandResult.ok(_stateJson()),
        ),
      );
  }

  @override
  Future<void> dispose() async {
    _autoDismiss?.cancel();
    await _settingsSub?.cancel();
    await _voiceSub?.cancel();
    closeHaSessions();
    closeRelaySessions();
    await _relayServer?.close(force: true);
    _relayServer = null;
    activeViewId.dispose();
    focusedCameraId.dispose();
  }

  void _load() {
    try {
      _config = CameraConfiguration.decode(_settings.get(defs.cameraConfig));
    } catch (error) {
      log.error(name, 'invalid persisted configuration: $error');
      _config = const CameraConfiguration();
    }
    // Materialized in memory, not written back: an install that never touches
    // cameras keeps an untouched (and un-exported) camera document, and the
    // first real edit persists the default along with it.
    _config = _config.withDefaultView();
  }

  Future<void> _save(CameraConfiguration next) async {
    _config = next.withDefaultView();
    _saving = true;
    try {
      await _settings.set(defs.cameraConfig, _config.encode());
    } finally {
      _saving = false;
    }
    bus.publish(const CameraConfigurationChanged());
    _publishState();
  }

  Future<CommandResult> _putServerCommand(Map<String, Object?> params) async {
    final requestedId = '${params['id'] ?? ''}'.trim();
    final existing = _config.servers
        .where((server) => server.id == requestedId)
        .firstOrNull;
    final name = '${params['name'] ?? ''}'.trim();
    final baseUrl = _normalizeBaseUrl('${params['baseUrl'] ?? ''}');
    final uri = Uri.tryParse(baseUrl);
    if (name.isEmpty) return const CommandResult.fail('name required');
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return const CommandResult.fail('valid HTTP or HTTPS baseUrl required');
    }
    final id = existing?.id ?? _newId();
    final password = params.containsKey('password')
        ? '${params['password'] ?? ''}'
        : existing?.password ?? '';
    final server = CameraServer(
      id: id,
      name: name,
      baseUrl: baseUrl,
      username: '${params['username'] ?? existing?.username ?? ''}'.trim(),
      password: password,
      allowInvalidCertificate: params['allowInvalidCertificate'] == true,
    );
    await _save(
      _config.copyWith(
        servers: [
          for (final item in _config.servers)
            if (item.id != id) item,
          server,
        ],
      ),
    );
    return CommandResult.ok(server.toJson(includePassword: false));
  }

  Future<CommandResult> _deleteServer(String id) async {
    if (!_config.servers.any((server) => server.id == id)) {
      return const CommandResult.fail('server not found');
    }
    final removedCameraIds = {
      for (final camera in _config.cameras)
        if (camera.serverId == id) camera.id,
    };
    final views = <CameraViewConfig>[];
    for (final view in _config.views) {
      final ids = [
        for (final cameraId in view.cameraIds)
          if (!removedCameraIds.contains(cameraId)) cameraId,
      ];
      // A view emptied by the delete goes with it, except the default, which
      // is permanent and keeps whatever name it was given.
      if (ids.isNotEmpty || view.isDefault) {
        views.add(view.copyWith(cameraIds: ids));
      }
    }
    await _save(
      _config.copyWith(
        servers: [
          for (final server in _config.servers)
            if (server.id != id) server,
        ],
        cameras: [
          for (final camera in _config.cameras)
            if (!removedCameraIds.contains(camera.id)) camera,
        ],
        views: views,
      ),
    );
    return CommandResult.ok({'removedCameras': removedCameraIds.length});
  }

  Future<CommandResult> importGo2RtcStreams(String serverId) async {
    final server = _config.servers
        .where((item) => item.id == serverId)
        .firstOrNull;
    if (server == null) return const CommandResult.fail('server not found');
    try {
      final response = await _request(
        server,
        'GET',
        _serverUri(server, 'api/streams'),
      );
      if (response.statusCode != HttpStatus.ok) {
        return CommandResult.fail(
          'Go2RTC returned HTTP ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return const CommandResult.fail(
          'Go2RTC returned an invalid stream list',
        );
      }
      final names = decoded.keys.map((key) => '$key').toSet();
      final cameras = <CameraSource>[];
      var added = 0;
      var restored = 0;
      for (final camera in _config.cameras) {
        if (camera.serverId != serverId || !camera.imported) {
          cameras.add(camera);
          continue;
        }
        final present = names.remove(camera.streamName);
        if (present && camera.missing) restored++;
        cameras.add(camera.copyWith(missing: !present));
      }
      for (final streamName in names.toList()..sort()) {
        cameras.add(
          CameraSource(
            id: _newId(),
            name: streamName,
            kind: 'go2rtc',
            serverId: serverId,
            streamName: streamName,
            imported: true,
          ),
        );
        added++;
      }
      await _save(_config.copyWith(cameras: cameras));
      final missing = cameras
          .where((camera) => camera.serverId == serverId && camera.missing)
          .length;
      return CommandResult.ok({
        'added': added,
        'restored': restored,
        'missing': missing,
        'total': cameras.where((camera) => camera.serverId == serverId).length,
      });
    } catch (error) {
      log.warn(name, 'Go2RTC import failed for ${server.name}: $error');
      return CommandResult.fail('could not connect to ${server.name}: $error');
    }
  }

  /// Same merge semantics as the Go2RTC import, keyed by entity id:
  /// re-importing adds new entities, keeps names and view membership of
  /// existing ones, and marks entities that stopped answering (removed,
  /// or no longer streamable) as missing rather than deleting them. The
  /// stream types HA reports (`web_rtc`, `hls`) ride along and refresh on
  /// every import — they decide which transports the player offers.
  Future<CommandResult> importHomeAssistantCameras() async {
    final List<({String entityId, String name, List<String> streamTypes})>?
    found;
    try {
      found = await _homeAssistant.listStreamableCameras();
    } catch (error) {
      return CommandResult.fail('could not read Home Assistant: $error');
    }
    if (found == null) {
      return const CommandResult.fail(
        'Home Assistant is not configured or unreachable',
      );
    }
    final byEntity = {for (final item in found) item.entityId: item};
    final cameras = <CameraSource>[];
    var added = 0;
    var restored = 0;
    for (final camera in _config.cameras) {
      if (camera.kind != 'ha' || !camera.imported) {
        cameras.add(camera);
        continue;
      }
      final item = byEntity.remove(camera.entityId);
      if (item != null && camera.missing) restored++;
      cameras.add(
        camera.copyWith(missing: item == null, streamTypes: item?.streamTypes),
      );
    }
    for (final item in byEntity.values) {
      cameras.add(
        CameraSource(
          id: _newId(),
          name: item.name,
          kind: 'ha',
          entityId: item.entityId,
          streamTypes: item.streamTypes,
          imported: true,
        ),
      );
      added++;
    }
    await _save(_config.copyWith(cameras: cameras));
    final missing = cameras
        .where((camera) => camera.kind == 'ha' && camera.missing)
        .length;
    return CommandResult.ok({
      'added': added,
      'restored': restored,
      'missing': missing,
      'total': cameras.where((camera) => camera.kind == 'ha').length,
    });
  }

  Future<CommandResult> _putSourceCommand(Map<String, Object?> params) async {
    final requestedId = '${params['id'] ?? ''}'.trim();
    final existing = _config.cameras
        .where((camera) => camera.id == requestedId)
        .firstOrNull;
    final name = '${params['name'] ?? ''}'.trim();
    final kind = '${params['kind'] ?? existing?.kind ?? 'go2rtc'}';
    if (name.isEmpty) return const CommandResult.fail('name required');
    if (kind != 'go2rtc' && kind != 'whep' && kind != 'ha') {
      return const CommandResult.fail('kind must be go2rtc, whep or ha');
    }
    final serverId = '${params['serverId'] ?? existing?.serverId ?? ''}'.trim();
    final streamName = '${params['streamName'] ?? existing?.streamName ?? ''}'
        .trim();
    final whepUrl = '${params['whepUrl'] ?? existing?.whepUrl ?? ''}'.trim();
    final entityId = '${params['entityId'] ?? existing?.entityId ?? ''}'.trim();
    if (kind == 'go2rtc') {
      if (!_config.servers.any((server) => server.id == serverId)) {
        return const CommandResult.fail('valid serverId required');
      }
      if (streamName.isEmpty) {
        return const CommandResult.fail('streamName required');
      }
    } else if (kind == 'ha') {
      if (!entityId.startsWith('camera.')) {
        return const CommandResult.fail('a camera.* entityId is required');
      }
    } else {
      final uri = Uri.tryParse(whepUrl);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        return const CommandResult.fail('valid WHEP URL required');
      }
    }
    final id = existing?.id ?? _newId();
    // An edit (rename, and the remote UI resubmits every field) must not
    // cost an imported camera its known stream types; they change only
    // when the entity itself changes. A new or re-pointed `ha` camera asks
    // Home Assistant what the entity offers, so a hand-added camera gets
    // the same honest transports (and formats label) an imported one has;
    // when HA cannot answer right now the types stay unknown and the
    // player tries everything.
    var streamTypes = kind == 'ha' && entityId == existing?.entityId
        ? existing?.streamTypes
        : null;
    if (kind == 'ha' && streamTypes == null) {
      streamTypes = await _homeAssistant.cameraCapabilities(entityId);
    }
    final source = CameraSource(
      id: id,
      name: name,
      kind: kind,
      serverId: kind == 'go2rtc' ? serverId : null,
      streamName: kind == 'go2rtc' ? streamName : null,
      whepUrl: kind == 'whep' ? whepUrl : null,
      entityId: kind == 'ha' ? entityId : null,
      streamTypes: streamTypes,
      fullscreenStreamName:
          '${params['fullscreenStreamName'] ?? existing?.fullscreenStreamName ?? ''}'
              .trim(),
      imported: existing?.imported ?? false,
      missing: false,
    );
    await _save(
      _config.copyWith(
        cameras: [
          for (final item in _config.cameras)
            if (item.id != id) item,
          source,
        ],
      ),
    );
    return CommandResult.ok(source.toJson());
  }

  Future<CommandResult> _deleteSource(String id) async {
    if (!_config.cameras.any((camera) => camera.id == id)) {
      return const CommandResult.fail('camera not found');
    }
    final views = <CameraViewConfig>[];
    for (final view in _config.views) {
      final ids = view.cameraIds.where((cameraId) => cameraId != id).toList();
      if (ids.isNotEmpty || view.isDefault) {
        views.add(view.copyWith(cameraIds: ids));
      }
    }
    await _save(
      _config.copyWith(
        cameras: [
          for (final camera in _config.cameras)
            if (camera.id != id) camera,
        ],
        views: views,
      ),
    );
    return const CommandResult.ok();
  }

  Future<CommandResult> _putViewCommand(Map<String, Object?> params) async {
    final requestedId = '${params['id'] ?? ''}'.trim();
    final existing = _config.views
        .where((view) => view.id == requestedId)
        .firstOrNull;
    final name = '${params['name'] ?? ''}'.trim();
    final rawIds = params['cameraIds'];
    if (name.isEmpty) return const CommandResult.fail('name required');
    if (rawIds is! List) {
      return const CommandResult.fail('cameraIds must be a list');
    }
    final ids = [for (final id in rawIds) '$id'];
    // The default view is allowed to stand empty: it exists before any camera
    // does, and emptying it is how you retire it without deleting it.
    if (ids.isEmpty && existing?.isDefault != true) {
      return const CommandResult.fail('a view must contain 1 to 12 cameras');
    }
    if (ids.length > 12) {
      return const CommandResult.fail('a view must contain 1 to 12 cameras');
    }
    if (ids.toSet().length != ids.length) {
      return const CommandResult.fail('a camera can appear only once per view');
    }
    final known = _config.cameras.map((camera) => camera.id).toSet();
    if (ids.any((id) => !known.contains(id))) {
      return const CommandResult.fail('view contains an unknown camera');
    }
    if (_config.views.any(
      (view) =>
          view.id != existing?.id &&
          view.name.toLowerCase() == name.toLowerCase(),
    )) {
      return const CommandResult.fail('view name must be unique');
    }
    final rawGrid = params['grid'];
    int? grid = existing?.grid;
    if (rawGrid is num) {
      grid = rawGrid.toInt();
      if (grid < 1 || grid > 12) {
        return const CommandResult.fail('grid must be between 1 and 12');
      }
      if (grid < ids.length) {
        return const CommandResult.fail(
          'grid is smaller than the camera count',
        );
      }
    }
    final id = existing?.id ?? _newId();
    final view = CameraViewConfig(
      id: id,
      name: name,
      cameraIds: ids,
      showCameraNames: params['showCameraNames'] is bool
          ? params['showCameraNames'] as bool
          : existing?.showCameraNames ?? true,
      grid: grid,
    );
    await _save(
      _config.copyWith(
        views: [
          for (final item in _config.views)
            if (item.id != id) item,
          view,
        ],
      ),
    );
    return CommandResult.ok(view.toJson());
  }

  Future<CommandResult> _deleteView(String id) async {
    if (!_config.views.any((view) => view.id == id)) {
      return const CommandResult.fail('view not found');
    }
    if (id == CameraViewConfig.defaultId) {
      return const CommandResult.fail(
        'the default view cannot be deleted; empty it instead',
      );
    }
    if (activeViewId.value == id) hideView();
    await _save(
      _config.copyWith(
        views: [
          for (final view in _config.views)
            if (view.id != id) view,
        ],
      ),
    );
    return const CommandResult.ok();
  }

  Future<CommandResult> showView(String viewId, {bool toggle = false}) async {
    final view = _config.views.where((item) => item.id == viewId).firstOrNull;
    if (view == null) return const CommandResult.fail('view not found');
    if (view.cameraIds.isEmpty) {
      return const CommandResult.fail('view has no cameras');
    }
    if (toggle && activeViewId.value == view.id) {
      hideView();
      return CommandResult.ok(_stateJson());
    }
    _clearInterruptedView();
    await _prepareToShowView();
    focusedCameraId.value = null;
    activeViewId.value = view.id;
    _publishState();
    return CommandResult.ok(_stateJson());
  }

  Future<void> _prepareToShowView() async {
    await commands.execute('screenOn', const {});
    await commands.execute('bringToFront', const {});
    await commands.execute('stopScreensaver', const {});
    await commands.execute('hideOverlayPage', const {});
  }

  void hideView() {
    _clearInterruptedView();
    _hideActiveView();
  }

  void _hideActiveView() {
    if (activeViewId.value == null) return;
    focusedCameraId.value = null;
    activeViewId.value = null;
    closeHaSessions();
    _publishState();
  }

  void _clearInterruptedView() {
    _interruptedViewId = null;
    _interruptedCameraId = null;
  }

  void _onVoiceInteraction(VoiceInteractionChanged event) {
    _voiceActive = event.active;
    final change = ++_voiceChange;
    if (event.active) {
      interruptForVoice();
      return;
    }
    if (_interruptedViewId != null) {
      unawaited(_resumeInterruptedView(change));
    }
  }

  void interruptForVoice() {
    final viewId = activeViewId.value;
    if (viewId == null) return;
    _interruptedViewId = viewId;
    _interruptedCameraId = focusedCameraId.value;
    _hideActiveView();
  }

  Future<void> _resumeInterruptedView(int change) async {
    final viewId = _interruptedViewId;
    if (viewId == null) return;
    if (!_config.views.any((view) => view.id == viewId)) {
      _clearInterruptedView();
      return;
    }

    await _prepareToShowView();
    final view = _config.views.where((item) => item.id == viewId).firstOrNull;
    if (_voiceActive ||
        _voiceChange != change ||
        _interruptedViewId != viewId ||
        activeViewId.value != null) {
      return;
    }
    if (view == null) {
      _clearInterruptedView();
      return;
    }

    final interruptedCameraId = _interruptedCameraId;
    final cameraId =
        interruptedCameraId != null &&
            view.cameraIds.contains(interruptedCameraId)
        ? interruptedCameraId
        : null;
    _clearInterruptedView();
    focusedCameraId.value = cameraId;
    activeViewId.value = view.id;
    _publishState();
  }

  CommandResult focusCamera(String? cameraId) {
    final view = activeView;
    if (view == null) return const CommandResult.fail('no active view');
    if (cameraId != null && !view.cameraIds.contains(cameraId)) {
      return const CommandResult.fail('camera is not in the active view');
    }
    focusedCameraId.value = cameraId;
    _publishState();
    return CommandResult.ok(_stateJson());
  }

  /// The RTCConfiguration the page should build its peer connection with,
  /// or null for browser defaults. Only `ha` cameras carry one: Home
  /// Assistant hands out the ICE servers its backend expects (TURN for
  /// cloud setups); Go2RTC and WHEP on the LAN need nothing.
  Future<Map<String, Object?>?> rtcConfigFor(String cameraId) async {
    final camera = _config.cameras
        .where((item) => item.id == cameraId)
        .firstOrNull;
    final entityId = camera?.entityId;
    if (camera?.kind != 'ha' || entityId == null || entityId.isEmpty) {
      return null;
    }
    return _homeAssistant.webRtcClientConfig(entityId);
  }

  /// Close every open Home Assistant signaling session. Runs when the
  /// camera surface goes away (view hidden, player torn down): the
  /// sessions exist to relay ICE candidates into peer connections that no
  /// longer exist, and each holds a websocket into Home Assistant.
  void closeHaSessions() {
    if (_haSessions.isEmpty) return;
    final sessions = _haSessions.values.toList();
    _haSessions.clear();
    for (final session in sessions) {
      unawaited(session.close());
    }
  }

  Future<String> negotiate({
    required String cameraId,
    required String offer,
    required bool fullscreen,
  }) async {
    final camera = _config.cameras
        .where((item) => item.id == cameraId)
        .firstOrNull;
    if (camera == null) throw StateError('camera not found');
    if (camera.kind == 'ha') {
      final entityId = camera.entityId;
      if (entityId == null || entityId.isEmpty) {
        throw StateError('camera has no entity id');
      }
      // A renegotiation (focus mode, the page's retry ladder) replaces the
      // stream; the old session's candidates belong to a dead peer.
      unawaited(_haSessions.remove(cameraId)?.close());
      final result = await _homeAssistant.cameraWebRtcOffer(
        entityId: entityId,
        offer: offer,
        onCandidate: (candidate) =>
            onRemoteCandidate?.call(cameraId, candidate),
      );
      _haSessions[cameraId] = result.session;
      return result.answer;
    }
    CameraServer? server;
    Uri uri;
    if (camera.kind == 'go2rtc') {
      server = _config.servers
          .where((item) => item.id == camera.serverId)
          .firstOrNull;
      if (server == null) throw StateError('camera server not found');
      final stream =
          fullscreen &&
              camera.fullscreenStreamName != null &&
              camera.fullscreenStreamName!.isNotEmpty
          ? camera.fullscreenStreamName!
          : camera.streamName!;
      uri = _serverUri(server, 'api/webrtc', {'src': stream});
    } else {
      uri = Uri.parse(camera.whepUrl!);
    }
    final response = await _request(
      server,
      'POST',
      uri,
      body: utf8.encode(offer),
      contentType: 'application/sdp',
    );
    final answer = response.body;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CameraSignalingException(response.statusCode, answer.trim(), uri);
    }
    return answer;
  }

  /// A loopback WebSocket endpoint relaying Go2RTC's MSE stream for
  /// [cameraId] (issue #160: devices whose WebView cannot play WebRTC at
  /// all — Fire tablets — stream over MSE instead).
  ///
  /// The camera page cannot open the Go2RTC socket itself: a page
  /// WebSocket carries no Authorization header, and the servers list
  /// holds credentials and the allow-invalid-certificate escape hatch
  /// only dart:io can honor. So every MSE session goes through a
  /// loopback-only relay: single-use token, upstream opened with the
  /// server's auth, frames piped both ways, both sides die together.
  Future<Map<String, Object?>> mseEndpoint({
    required String cameraId,
    required bool fullscreen,
  }) async {
    final camera = _config.cameras
        .where((item) => item.id == cameraId)
        .firstOrNull;
    if (camera == null) return {'ok': false, 'error': 'camera not found'};
    if (camera.kind != 'go2rtc') {
      return {
        'ok': false,
        'error': 'MSE streaming needs a Go2RTC camera (this one is '
            '${camera.kind})',
      };
    }
    final server = _config.servers
        .where((item) => item.id == camera.serverId)
        .firstOrNull;
    if (server == null) {
      return {'ok': false, 'error': 'camera server not found'};
    }
    final stream =
        fullscreen &&
            camera.fullscreenStreamName != null &&
            camera.fullscreenStreamName!.isNotEmpty
        ? camera.fullscreenStreamName!
        : camera.streamName!;
    var uri = _serverUri(server, 'api/ws', {'src': stream});
    uri = uri.replace(scheme: uri.scheme == 'https' ? 'wss' : 'ws');
    try {
      final port = await _ensureRelay();
      final token = _relayToken();
      _msePending[token] = (uri: uri, server: server);
      // A token the page never connects must not accumulate.
      Timer(const Duration(seconds: 30), () => _msePending.remove(token));
      return {'ok': true, 'url': 'ws://127.0.0.1:$port/$token'};
    } catch (e) {
      return {'ok': false, 'error': 'MSE relay failed: $e'};
    }
  }

  /// A loopback URL serving the HLS playlist for [cameraId] through the
  /// relay: how `ha` cameras with no WebRTC path stream at all. Every
  /// playlist and segment fetch goes through the relay because the page
  /// is a file:// origin whose fetches Home Assistant would refuse (CORS)
  /// and whose certificate trust only dart:io honors; the relay fetches
  /// upstream with the app's HTTP stack and answers with permissive CORS.
  Future<Map<String, Object?>> hlsEndpoint({required String cameraId}) async {
    final camera = _config.cameras
        .where((item) => item.id == cameraId)
        .firstOrNull;
    if (camera == null) return {'ok': false, 'error': 'camera not found'};
    final entityId = camera.entityId ?? '';
    if (camera.kind != 'ha' || entityId.isEmpty) {
      return {
        'ok': false,
        'error':
            'HLS streaming needs a Home Assistant camera (this one is '
            '${camera.kind})',
      };
    }
    final url = await _homeAssistant.cameraStreamUrl(entityId);
    final playlist = url == null ? null : Uri.tryParse(url);
    if (playlist == null ||
        (playlist.scheme != 'http' && playlist.scheme != 'https')) {
      return {
        'ok': false,
        'error': 'Home Assistant could not start an HLS stream for $entityId',
      };
    }
    try {
      final port = await _ensureRelay();
      // One live session per camera: a retry replaces the old token, so a
      // long-lived view cannot accumulate them.
      final previous = _hlsByCamera.remove(cameraId);
      if (previous != null) _hlsSessions.remove(previous);
      final token = _relayToken();
      _hlsSessions[token] = playlist;
      _hlsByCamera[cameraId] = token;
      return {
        'ok': true,
        'url':
            'http://127.0.0.1:$port/hls/$token/r?u='
            '${Uri.encodeQueryComponent(playlist.toString())}',
      };
    } catch (e) {
      return {'ok': false, 'error': 'HLS relay failed: $e'};
    }
  }

  /// A loopback URL serving [cameraId]'s MJPEG stream through the relay:
  /// Home Assistant's camera proxy stream, which every camera entity
  /// serves, streams included — it is the only path for stills-only
  /// cameras (UniFi package cameras and their kin) and the last rung of
  /// the ladder for everything else. The page's `<img>` cannot send the
  /// Authorization header, so the relay fetches upstream with it.
  Future<Map<String, Object?>> mjpegEndpoint({required String cameraId}) async {
    final camera = _config.cameras
        .where((item) => item.id == cameraId)
        .firstOrNull;
    if (camera == null) return {'ok': false, 'error': 'camera not found'};
    final entityId = camera.entityId ?? '';
    if (camera.kind != 'ha' || entityId.isEmpty) {
      return {
        'ok': false,
        'error':
            'MJPEG streaming needs a Home Assistant camera (this one is '
            '${camera.kind})',
      };
    }
    final target = _homeAssistant.cameraMjpegTarget(entityId);
    if (target == null) {
      return {'ok': false, 'error': 'Home Assistant is not configured'};
    }
    try {
      final port = await _ensureRelay();
      final token = _relayToken();
      _mjpegPending[token] = target;
      // A token the page never fetches must not accumulate.
      Timer(const Duration(seconds: 30), () => _mjpegPending.remove(token));
      return {'ok': true, 'url': 'http://127.0.0.1:$port/mjpeg/$token'};
    } catch (e) {
      return {'ok': false, 'error': 'MJPEG relay failed: $e'};
    }
  }

  HttpServer? _relayServer;
  final _msePending = <String, ({Uri uri, CameraServer server})>{};
  final _mjpegPending = <String, ({Uri uri, String token})>{};
  final _mseSockets = <WebSocket>{};

  /// Live HLS proxy sessions by token; the value is the playlist URL HA
  /// handed out, kept to pin every proxied fetch to its origin.
  final _hlsSessions = <String, Uri>{};
  final _hlsByCamera = <String, String>{};
  HttpClient? _relayClient;

  String _relayToken() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<int> _ensureRelay() async {
    final existing = _relayServer;
    if (existing != null) return existing.port;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _relayServer = server;
    server.listen(_handleRelayRequest, onError: (Object _) {});
    return server.port;
  }

  Future<void> _handleRelayRequest(HttpRequest request) async {
    final segments = request.uri.pathSegments;
    if (segments.length == 3 && segments.first == 'hls') {
      await _serveHls(request, segments[1]);
      return;
    }
    if (segments.length == 2 && segments.first == 'mjpeg') {
      await _serveMjpeg(request, segments[1]);
      return;
    }
    await _handleMseUpgrade(request);
  }

  /// Serve one proxied MJPEG stream: a single-use token bought from
  /// [mjpegEndpoint], fetched upstream with the Authorization header the
  /// page cannot send, and piped for as long as both sides stay open.
  Future<void> _serveMjpeg(HttpRequest request, String token) async {
    final response = request.response;
    final target = _mjpegPending.remove(token);
    if (target == null) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    try {
      final client = _relayClient ??= HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final upstreamRequest = await client.getUrl(target.uri);
      upstreamRequest.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${target.token}',
      );
      final upstreamResponse = await upstreamRequest.close();
      response.statusCode = upstreamResponse.statusCode;
      // The multipart content type carries the frame boundary; without it
      // the img renders nothing.
      final contentType = upstreamResponse.headers.contentType;
      if (contentType != null) response.headers.contentType = contentType;
      // Frames must leave as they arrive: a buffered live stream is a
      // frozen one.
      response.bufferOutput = false;
      await response.addStream(upstreamResponse);
      await response.close();
    } catch (e) {
      // The page dropping its img mid-stream lands here; only note it.
      log.debug(name, 'MJPEG proxy stream ended: $e');
      try {
        response.statusCode = HttpStatus.badGateway;
        await response.close();
      } catch (_) {}
    }
  }

  /// Serve one proxied HLS fetch: `/hls/{token}/r?u={absolute upstream
  /// url}`. Playlists come back with every URI they reference rewritten
  /// into the same shape, so the page only ever talks to the relay.
  Future<void> _serveHls(HttpRequest request, String token) async {
    final response = request.response;
    // The page's fetches come from a file:// origin; without this header
    // every one of them fails CORS.
    response.headers.set('Access-Control-Allow-Origin', '*');
    final session = _hlsSessions[token];
    final upstream = Uri.tryParse(request.uri.queryParameters['u'] ?? '');
    // Pinned to the origin HA handed out: the relay proxies one stream,
    // it is not a general fetcher. (The scheme check also keeps .origin
    // from throwing on garbage.)
    if (session == null ||
        request.uri.pathSegments.last != 'r' ||
        upstream == null ||
        (upstream.scheme != 'http' && upstream.scheme != 'https') ||
        !upstream.hasAuthority ||
        upstream.origin != session.origin) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    try {
      final client = _relayClient ??= HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final upstreamRequest = await client.getUrl(upstream);
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        upstreamRequest.headers.set(HttpHeaders.rangeHeader, range);
      }
      final upstreamResponse = await upstreamRequest.close();
      response.statusCode = upstreamResponse.statusCode;
      final contentType = upstreamResponse.headers.contentType;
      final isPlaylist =
          upstream.path.endsWith('.m3u8') ||
          (contentType?.mimeType.contains('mpegurl') ?? false);
      if (contentType != null) response.headers.contentType = contentType;
      if (isPlaylist && upstreamResponse.statusCode == HttpStatus.ok) {
        final body = await utf8.decoder.bind(upstreamResponse).join();
        response.write(rewriteHlsPlaylist(body, upstream));
      } else {
        await response.addStream(upstreamResponse);
      }
      await response.close();
    } catch (e) {
      log.warn(name, 'HLS proxy fetch failed: $e');
      try {
        response.statusCode = HttpStatus.badGateway;
        await response.close();
      } catch (_) {}
    }
  }

  /// [body] (an m3u8 playlist fetched from [upstream]) with every URI it
  /// references — segment lines and URI="" attributes (init sections,
  /// alternate renditions), relative or absolute — rewritten to the
  /// relay's `r?u=` form. Relative rewrites resolve against [upstream],
  /// and the browser resolves `r?u=...` against the relay URL it fetched
  /// this playlist from, so nesting works without tracking any state.
  @visibleForTesting
  static String rewriteHlsPlaylist(String body, Uri upstream) {
    String proxied(String uri) =>
        'r?u=${Uri.encodeQueryComponent(upstream.resolve(uri.trim()).toString())}';
    final lines = const LineSplitter().convert(body);
    final out = [
      for (final line in lines)
        if (line.isEmpty || line.startsWith('#'))
          line.replaceAllMapped(
            RegExp(r'URI="([^"]+)"'),
            (match) => 'URI="${proxied(match[1]!)}"',
          )
        else
          proxied(line),
    ];
    return out.join('\n') + (body.endsWith('\n') ? '\n' : '');
  }

  Future<void> _handleMseUpgrade(HttpRequest request) async {
    final target = _msePending.remove(request.uri.path.replaceFirst('/', ''));
    if (target == null || !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    WebSocket? local;
    WebSocket? upstream;
    void closeBoth() {
      local?.close();
      upstream?.close();
      _mseSockets.remove(local);
      _mseSockets.remove(upstream);
    }

    try {
      local = await WebSocketTransformer.upgrade(request);
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      if (target.server.allowInvalidCertificate) {
        client.badCertificateCallback = (certificate, host, port) =>
            host == target.uri.host;
      }
      final server = target.server;
      upstream = await WebSocket.connect(
        target.uri.toString(),
        headers: {
          if (server.username.isNotEmpty || server.password.isNotEmpty)
            HttpHeaders.authorizationHeader:
                'Basic ${base64Encode(utf8.encode('${server.username}:${server.password}'))}',
        },
        customClient: client,
      );
    } catch (e) {
      log.warn(name, 'MSE upstream connect failed: $e');
      closeBoth();
      return;
    }
    _mseSockets
      ..add(local)
      ..add(upstream);
    local.listen(
      upstream.add,
      onDone: closeBoth,
      onError: (Object _) => closeBoth(),
      cancelOnError: true,
    );
    upstream.listen(
      local.add,
      onDone: closeBoth,
      onError: (Object _) => closeBoth(),
      cancelOnError: true,
    );
  }

  /// Close every relayed stream, MSE and HLS. Runs alongside
  /// [closeHaSessions] when the camera surface goes away: each open MSE
  /// socket is a live decoder on the page, and a lingering HLS token
  /// would keep proxying for a page that no longer exists.
  void closeRelaySessions() {
    for (final socket in _mseSockets.toList()) {
      socket.close();
    }
    _mseSockets.clear();
    _msePending.clear();
    _mjpegPending.clear();
    _hlsSessions.clear();
    _hlsByCamera.clear();
    // Aborts in-flight upstream fetches; recreated lazily on the next use.
    _relayClient?.close(force: true);
    _relayClient = null;
  }

  Future<_HttpResult> _request(
    CameraServer? server,
    String method,
    Uri uri, {
    List<int>? body,
    String? contentType,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    if (server?.allowInvalidCertificate == true) {
      client.badCertificateCallback = (certificate, host, port) =>
          host == uri.host;
    }
    try {
      final request = await client.openUrl(method, uri);
      if (server != null &&
          (server.username.isNotEmpty || server.password.isNotEmpty)) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('${server.username}:${server.password}'))}',
        );
      }
      if (contentType != null) {
        request.headers.set(HttpHeaders.contentTypeHeader, contentType);
      }
      if (body != null) request.add(body);
      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      return _HttpResult(response.statusCode, responseBody);
    } finally {
      client.close();
    }
  }

  Uri _serverUri(
    CameraServer server,
    String relativePath, [
    Map<String, String>? query,
  ]) {
    final base = Uri.parse(server.baseUrl);
    final prefix = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    return base.replace(
      path: '$prefix/$relativePath',
      queryParameters: query,
      fragment: '',
    );
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  void _publishState() {
    final view = activeView;
    bus.publish(
      CameraViewStateChanged(
        viewId: view?.id,
        viewName: view?.name,
        focusedCameraId: focusedCameraId.value,
      ),
    );
  }

  Map<String, Object?> _stateJson() {
    final view = activeView;
    return {
      'active': view != null,
      'viewId': view?.id,
      'viewName': view?.name,
      'focusedCameraId': focusedCameraId.value,
    };
  }

  static String _newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// The camera server answered the offer and refused it. Distinct from never
/// reaching the server at all: one is the stream, the other is the network,
/// and the tile has to say which (issue #160).
class CameraSignalingException implements Exception {
  const CameraSignalingException(this.statusCode, this.body, this.uri);

  final int statusCode;
  final String body;
  final Uri uri;

  @override
  String toString() =>
      'WebRTC signaling returned HTTP $statusCode: $body, uri = $uri';
}

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
