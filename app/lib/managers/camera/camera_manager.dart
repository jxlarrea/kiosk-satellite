import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'models.dart';

class CameraManager extends Manager {
  CameraManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

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

  CameraViewConfig? get activeView {
    final id = activeViewId.value;
    if (id == null) return null;
    return _config.views.where((view) => view.id == id).firstOrNull;
  }

  @override
  Future<void> init() async {
    _load();
    _settingsSub = bus.on<SettingChanged>().listen((event) {
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
          name: 'cameraPutSource',
          description: 'Create or update a camera source.',
          params: const {
            'id': 'Existing camera id, or empty to create one',
            'name': 'Display name',
            'kind': 'go2rtc or whep',
            'serverId': 'Go2RTC server id',
            'streamName': 'Go2RTC stream name',
            'whepUrl': 'Direct WHEP endpoint',
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
              'Create or update a camera view containing 1 to 4 cameras.',
          params: const {
            'id': 'Existing view id, or empty to create one',
            'name': 'Unique display name',
            'cameraIds': 'Ordered list of 1 to 4 camera ids',
            'showCameraNames': 'Show camera names over the video',
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
          description: 'Show a configured camera view over the dashboard.',
          params: const {'viewId': 'Camera view id'},
          handler: (params) => showView('${params['viewId'] ?? ''}'),
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
    await _settingsSub?.cancel();
    await _voiceSub?.cancel();
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
  }

  Future<void> _save(CameraConfiguration next) async {
    _config = next;
    _saving = true;
    try {
      await _settings.set(defs.cameraConfig, next.encode());
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
      if (ids.isNotEmpty) views.add(view.copyWith(cameraIds: ids));
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

  Future<CommandResult> _putSourceCommand(Map<String, Object?> params) async {
    final requestedId = '${params['id'] ?? ''}'.trim();
    final existing = _config.cameras
        .where((camera) => camera.id == requestedId)
        .firstOrNull;
    final name = '${params['name'] ?? ''}'.trim();
    final kind = '${params['kind'] ?? existing?.kind ?? 'go2rtc'}';
    if (name.isEmpty) return const CommandResult.fail('name required');
    if (kind != 'go2rtc' && kind != 'whep') {
      return const CommandResult.fail('kind must be go2rtc or whep');
    }
    final serverId = '${params['serverId'] ?? existing?.serverId ?? ''}'.trim();
    final streamName = '${params['streamName'] ?? existing?.streamName ?? ''}'
        .trim();
    final whepUrl = '${params['whepUrl'] ?? existing?.whepUrl ?? ''}'.trim();
    if (kind == 'go2rtc') {
      if (!_config.servers.any((server) => server.id == serverId)) {
        return const CommandResult.fail('valid serverId required');
      }
      if (streamName.isEmpty) {
        return const CommandResult.fail('streamName required');
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
    final source = CameraSource(
      id: id,
      name: name,
      kind: kind,
      serverId: kind == 'go2rtc' ? serverId : null,
      streamName: kind == 'go2rtc' ? streamName : null,
      whepUrl: kind == 'whep' ? whepUrl : null,
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
      if (ids.isNotEmpty) views.add(view.copyWith(cameraIds: ids));
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
    if (ids.isEmpty || ids.length > 4) {
      return const CommandResult.fail('a view must contain 1 to 4 cameras');
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
    final id = existing?.id ?? _newId();
    final view = CameraViewConfig(
      id: id,
      name: name,
      cameraIds: ids,
      showCameraNames: params['showCameraNames'] is bool
          ? params['showCameraNames'] as bool
          : existing?.showCameraNames ?? true,
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

  Future<CommandResult> showView(String viewId) async {
    final view = _config.views.where((item) => item.id == viewId).firstOrNull;
    if (view == null) return const CommandResult.fail('view not found');
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

  Future<String> negotiate({
    required String cameraId,
    required String offer,
    required bool fullscreen,
  }) async {
    final camera = _config.cameras
        .where((item) => item.id == cameraId)
        .firstOrNull;
    if (camera == null) throw StateError('camera not found');
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
      throw HttpException(
        'WebRTC signaling returned HTTP ${response.statusCode}: $answer',
        uri: uri,
      );
    }
    return answer;
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

class _HttpResult {
  const _HttpResult(this.statusCode, this.body);

  final int statusCode;
  final String body;
}
