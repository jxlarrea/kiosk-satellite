import 'dart:convert';

class CameraServer {
  const CameraServer({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.username = '',
    this.password = '',
    this.allowInvalidCertificate = false,
  });

  final String id;
  final String name;
  final String baseUrl;
  final String username;
  final String password;
  final bool allowInvalidCertificate;

  CameraServer copyWith({
    String? name,
    String? baseUrl,
    String? username,
    String? password,
    bool? allowInvalidCertificate,
  }) => CameraServer(
    id: id,
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    username: username ?? this.username,
    password: password ?? this.password,
    allowInvalidCertificate:
        allowInvalidCertificate ?? this.allowInvalidCertificate,
  );

  Map<String, Object?> toJson({bool includePassword = true}) => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    if (username.isNotEmpty) 'username': username,
    if (includePassword && password.isNotEmpty) 'password': password,
    if (!includePassword) 'passwordSet': password.isNotEmpty,
    if (allowInvalidCertificate)
      'allowInvalidCertificate': allowInvalidCertificate,
  };

  static CameraServer fromJson(Map<Object?, Object?> json) => CameraServer(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    baseUrl: '${json['baseUrl'] ?? ''}',
    username: '${json['username'] ?? ''}',
    password: '${json['password'] ?? ''}',
    allowInvalidCertificate: json['allowInvalidCertificate'] == true,
  );
}

class CameraSource {
  const CameraSource({
    required this.id,
    required this.name,
    required this.kind,
    this.serverId,
    this.streamName,
    this.whepUrl,
    this.entityId,
    this.streamTypes,
    this.fullscreenStreamName,
    this.imported = false,
    this.missing = false,
  });

  final String id;
  final String name;

  /// `go2rtc`, `whep`, or `ha` (a Home Assistant camera entity streamed
  /// over HA's own WebRTC signaling, issue #124).
  final String kind;
  final String? serverId;
  final String? streamName;
  final String? whepUrl;

  /// The `camera.*` entity id backing a `ha` camera.
  final String? entityId;

  /// The frontend stream types Home Assistant reported for a `ha` camera
  /// when it was imported (`web_rtc`, `hls`). Null means unknown (a camera
  /// added by hand, or imported before HLS support existed): the player
  /// tries WebRTC first and falls back to HLS.
  final List<String>? streamTypes;
  final String? fullscreenStreamName;
  final bool imported;
  final bool missing;

  CameraSource copyWith({
    String? name,
    String? serverId,
    String? streamName,
    String? whepUrl,
    String? entityId,
    List<String>? streamTypes,
    String? fullscreenStreamName,
    bool? imported,
    bool? missing,
  }) => CameraSource(
    id: id,
    name: name ?? this.name,
    kind: kind,
    serverId: serverId ?? this.serverId,
    streamName: streamName ?? this.streamName,
    whepUrl: whepUrl ?? this.whepUrl,
    entityId: entityId ?? this.entityId,
    streamTypes: streamTypes ?? this.streamTypes,
    fullscreenStreamName: fullscreenStreamName ?? this.fullscreenStreamName,
    imported: imported ?? this.imported,
    missing: missing ?? this.missing,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    if (serverId != null) 'serverId': serverId,
    if (streamName != null) 'streamName': streamName,
    if (whepUrl != null) 'whepUrl': whepUrl,
    if (entityId != null) 'entityId': entityId,
    if (streamTypes != null) 'streamTypes': streamTypes,
    if (fullscreenStreamName != null && fullscreenStreamName!.isNotEmpty)
      'fullscreenStreamName': fullscreenStreamName,
    if (imported) 'imported': imported,
    if (missing) 'missing': missing,
  };

  static CameraSource fromJson(Map<Object?, Object?> json) => CameraSource(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    kind: '${json['kind'] ?? 'go2rtc'}',
    serverId: json['serverId'] as String?,
    streamName: json['streamName'] as String?,
    whepUrl: json['whepUrl'] as String?,
    entityId: json['entityId'] as String?,
    streamTypes: json['streamTypes'] is List
        ? [
            for (final type in json['streamTypes'] as List)
              if (type is String) type,
          ]
        : null,
    fullscreenStreamName: json['fullscreenStreamName'] as String?,
    imported: json['imported'] == true,
    missing: json['missing'] == true,
  );
}

class CameraViewConfig {
  const CameraViewConfig({
    required this.id,
    required this.name,
    required this.cameraIds,
    this.showCameraNames = true,
    this.grid,
  });

  /// The view every install has. It is created on first load, survives
  /// deletion, and is allowed to stand empty — it is what the drawer, the
  /// screensaver and an automation reach for when nothing else is set up.
  static const defaultId = 'default';
  static const defaultName = 'Default';

  final String id;
  final String name;
  final List<String> cameraIds;
  final bool showCameraNames;

  /// The grid the view lays out on, 1 to 12 slots. Slots past the camera
  /// count render empty. Null falls back to the camera count, which is what
  /// every view saved before grids existed means.
  final int? grid;

  bool get isDefault => id == defaultId;

  /// The slot count the view actually renders with.
  int get effectiveGrid {
    final slots = grid ?? cameraIds.length;
    return slots < cameraIds.length ? cameraIds.length : slots;
  }

  CameraViewConfig copyWith({
    String? name,
    List<String>? cameraIds,
    bool? showCameraNames,
    int? grid,
  }) => CameraViewConfig(
    id: id,
    name: name ?? this.name,
    cameraIds: cameraIds ?? this.cameraIds,
    showCameraNames: showCameraNames ?? this.showCameraNames,
    grid: grid ?? this.grid,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'cameraIds': cameraIds,
    'showCameraNames': showCameraNames,
    if (grid != null) 'grid': grid,
    if (isDefault) 'isDefault': true,
  };

  static CameraViewConfig fromJson(Map<Object?, Object?> json) =>
      CameraViewConfig(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        cameraIds: [
          for (final id in json['cameraIds'] as List? ?? const [])
            if (id is String) id,
        ],
        showCameraNames: json['showCameraNames'] != false,
        grid: json['grid'] is num ? (json['grid'] as num).toInt() : null,
      );
}

class CameraConfiguration {
  const CameraConfiguration({
    this.version = 1,
    this.servers = const [],
    this.cameras = const [],
    this.views = const [],
  });

  final int version;
  final List<CameraServer> servers;
  final List<CameraSource> cameras;
  final List<CameraViewConfig> views;

  CameraViewConfig? get defaultView {
    for (final view in views) {
      if (view.isDefault) return view;
    }
    return null;
  }

  /// This configuration with the default view guaranteed present, first in
  /// the list. Every load goes through here, so nothing downstream has to
  /// wonder whether it exists.
  CameraConfiguration withDefaultView() {
    final existing = defaultView;
    return CameraConfiguration(
      version: version,
      servers: servers,
      cameras: cameras,
      views: [
        existing ??
            CameraViewConfig(
              id: CameraViewConfig.defaultId,
              // View names are unique, and someone may already have made
              // their own "Default" by hand. Step aside rather than create
              // a pair that neither can be renamed out of.
              name: _freeName(CameraViewConfig.defaultName),
              cameraIds: const [],
            ),
        for (final view in views)
          if (!view.isDefault) view,
      ],
    );
  }

  String _freeName(String preferred) {
    final taken = {for (final view in views) view.name.toLowerCase()};
    if (!taken.contains(preferred.toLowerCase())) return preferred;
    for (var suffix = 2; suffix < 100; suffix++) {
      final candidate = '$preferred $suffix';
      if (!taken.contains(candidate.toLowerCase())) return candidate;
    }
    return preferred;
  }

  CameraConfiguration copyWith({
    List<CameraServer>? servers,
    List<CameraSource>? cameras,
    List<CameraViewConfig>? views,
  }) => CameraConfiguration(
    version: version,
    servers: servers ?? this.servers,
    cameras: cameras ?? this.cameras,
    views: views ?? this.views,
  );

  Map<String, Object?> toJson({bool includePasswords = true}) => {
    'version': version,
    'servers': [
      for (final server in servers)
        server.toJson(includePassword: includePasswords),
    ],
    'cameras': [for (final camera in cameras) camera.toJson()],
    'views': [for (final view in views) view.toJson()],
  };

  String encode() => jsonEncode(toJson());

  static CameraConfiguration decode(String raw) {
    if (raw.trim().isEmpty) return const CameraConfiguration();
    final json = jsonDecode(raw);
    if (json is! Map) {
      throw const FormatException('camera config is not an object');
    }
    final version = json['version'];
    if (version != 1) {
      throw FormatException('unsupported camera config version: $version');
    }
    return CameraConfiguration(
      version: 1,
      servers: [
        for (final item in json['servers'] as List? ?? const [])
          if (item is Map) CameraServer.fromJson(item),
      ],
      cameras: [
        for (final item in json['cameras'] as List? ?? const [])
          if (item is Map) CameraSource.fromJson(item),
      ],
      views: [
        for (final item in json['views'] as List? ?? const [])
          if (item is Map) CameraViewConfig.fromJson(item),
      ],
    );
  }
}
