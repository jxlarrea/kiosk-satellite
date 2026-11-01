import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// One tool an MCP server offers.
class McpTool {
  const McpTool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  final String name;
  final String description;

  /// JSON Schema for the arguments.
  final Map<String, Object?> inputSchema;
}

/// What a tool call came back with: its text, and whether the server
/// flagged it as an error.
class McpResult {
  const McpResult(this.text, {this.error = false});
  final String text;
  final bool error;
}

class McpException implements Exception {
  McpException(this.message, {this.status});
  final String message;

  /// The HTTP status, when the server answered with one.
  final int? status;

  @override
  String toString() => message;
}

/// A minimal MCP client over Streamable HTTP: initialize, list tools, call
/// a tool. Enough for Home Assistant's MCP Server integration and any
/// server that speaks the same transport. A reply comes back either as
/// plain JSON or as a short server-sent event stream, and both are read.
class McpClient {
  McpClient({
    required this.url,
    this.token = '',
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.clientVersion = '',
    this.deviceId,
    this.deviceName,
  }) : _client = client ?? http.Client();

  final Uri url;
  final String token;
  final Duration timeout;
  final String clientVersion;
  final http.Client _client;

  /// The Home Assistant device the calls act for. Home Assistant offers
  /// the timer tools only to a device that can run timers, and starts the
  /// timers on it. Scripts get it as [scriptDeviceArgument]. Null for any
  /// other server.
  final Future<String?> Function()? deviceId;

  /// The kiosk's name, which scripts get as [scriptNameArgument]. Null or
  /// empty leaves it out.
  final String Function()? deviceName;

  static const protocolVersion = '2025-06-18';

  /// The request metadata key Home Assistant reads the device from.
  static const deviceMetaKey = 'io.home-assistant/device_id';

  String? _session;
  bool _initialized = false;
  int _nextId = 1;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/event-stream',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    'MCP-Protocol-Version': protocolVersion,
    'Mcp-Session-Id': ?_session,
  };

  Future<void> _initialize() async {
    if (_initialized) return;
    await _request('initialize', {
      'protocolVersion': protocolVersion,
      'capabilities': const <String, Object?>{},
      // Servers built on the MCP SDKs refuse a client without a version.
      'clientInfo': {
        'name': 'Kiosk Satellite',
        'version': clientVersion.isEmpty ? '1.0' : clientVersion,
      },
    });
    _initialized = true;
    await _notify('notifications/initialized');
  }

  /// The script variable that carries [deviceId] into every Home Assistant
  /// script the model runs, so a script knows which kiosk asked. Home
  /// Assistant passes a script call's arguments on as its variables,
  /// declared as fields or not.
  static const scriptDeviceArgument = 'ks_device_id';

  /// The script variable that carries [deviceName] the same way.
  static const scriptNameArgument = 'ks_device_name';

  /// Home Assistant's MCP Server names the tool of each exposed script
  /// this way. With more than one LLM API ticked on the server, every tool
  /// name starts with its API's id, and scripts come from Assist's.
  static bool isScriptTool(String name) =>
      name.startsWith('script__') || name.startsWith('assist__script__');

  Future<String?> _device() async {
    try {
      final device = await deviceId?.call();
      return device == null || device.isEmpty ? null : device;
    } catch (_) {
      // Without a device the tools still work, only the timers and the
      // scripts' device are left out.
      return null;
    }
  }

  /// What every script gets about the kiosk, each argument left out while
  /// unknown.
  Map<String, String> _scriptArguments(String? device) {
    var name = '';
    try {
      name = deviceName?.call().trim() ?? '';
    } catch (_) {}
    return {
      scriptDeviceArgument: ?device,
      if (name.isNotEmpty) scriptNameArgument: name,
    };
  }

  static Map<String, Object?>? _metaFor(String? device) =>
      device == null ? null : {deviceMetaKey: device};

  /// [schema] without the [fields] a script declares: the kiosk fills
  /// them in, so the model must not.
  static Map<String, Object?> _withoutFields(
    Map<String, Object?> schema,
    Iterable<String> fields,
  ) {
    final properties = schema['properties'];
    if (properties is! Map || !fields.any(properties.containsKey)) {
      return schema;
    }
    final required = schema['required'];
    return {
      ...schema,
      'properties': {...properties}..removeWhere((k, _) => fields.contains(k)),
      if (required is List)
        'required': [
          for (final field in required)
            if (!fields.contains(field)) field,
        ],
    };
  }

  /// Every tool the server offers, following its pages.
  Future<List<McpTool>> listTools() async {
    await _initialize();
    final device = await _device();
    final meta = _metaFor(device);
    final filled = _scriptArguments(device).keys;
    final tools = <McpTool>[];
    String? cursor;
    for (var page = 0; page < 20; page++) {
      final result = await _request('tools/list', {
        'cursor': ?cursor,
        '_meta': ?meta,
      });
      final list = result['tools'];
      if (list is List) {
        for (final raw in list) {
          if (raw is! Map) continue;
          final name = '${raw['name'] ?? ''}';
          if (name.isEmpty) continue;
          final declared = raw['inputSchema'];
          final schema = declared is Map
              ? declared.cast<String, Object?>()
              : const <String, Object?>{'type': 'object', 'properties': {}};
          tools.add(
            McpTool(
              name: name,
              description: '${raw['description'] ?? ''}',
              inputSchema: isScriptTool(name)
                  ? _withoutFields(schema, filled)
                  : schema,
            ),
          );
        }
      }
      final next = result['nextCursor'];
      if (next is! String || next.isEmpty) break;
      cursor = next;
    }
    return tools;
  }

  Future<McpResult> callTool(
    String name,
    Map<String, Object?> arguments,
  ) async {
    await _initialize();
    final device = await _device();
    final meta = _metaFor(device);
    Future<Map<String, Object?>> call(Map<String, Object?> args) => _request(
      'tools/call',
      {'name': name, 'arguments': args, '_meta': ?meta},
    );
    Map<String, Object?> result;
    if (isScriptTool(name)) {
      final added = _scriptArguments(device);
      result = await call({...arguments, ...added});
      // A Home Assistant that checks script arguments against the fields
      // refuses an undeclared one: run the script without it, keeping the
      // ones it declares.
      for (
        var refused = _refusedKey(result, added.keys);
        refused != null;
        refused = _refusedKey(result, added.keys)
      ) {
        added.remove(refused);
        result = await call({...arguments, ...added});
      }
    } else {
      result = await call(arguments);
    }
    final parts = <String>[];
    final content = result['content'];
    if (content is List) {
      for (final item in content) {
        if (item is Map && item['type'] == 'text') parts.add('${item['text']}');
      }
    }
    final structured = result['structuredContent'];
    if (parts.isEmpty && structured != null) parts.add(jsonEncode(structured));
    return McpResult(parts.join('\n'), error: result['isError'] == true);
  }

  /// Which of the kiosk's [added] arguments the call was refused for
  /// before the script ran, or null. Any other error stands, so a script
  /// never runs twice.
  static String? _refusedKey(
    Map<String, Object?> result,
    Iterable<String> added,
  ) {
    if (result['isError'] != true) return null;
    final text = jsonEncode(result['content']);
    if (!text.contains('extra keys not allowed')) return null;
    // Home Assistant names the key as data['key'], ahead of any copy of
    // the arguments it quotes.
    for (final key in added) {
      if (text.contains("['$key']")) return key;
    }
    for (final key in added) {
      if (text.contains(key)) return key;
    }
    return null;
  }

  Future<void> _notify(String method) async {
    final response = await _client
        .post(
          url,
          headers: _headers,
          body: jsonEncode({'jsonrpc': '2.0', 'method': method}),
        )
        .timeout(timeout);
    if (response.statusCode >= 400) {
      throw McpException(
        '$method refused (HTTP ${response.statusCode})',
        status: response.statusCode,
      );
    }
  }

  Future<Map<String, Object?>> _request(
    String method,
    Map<String, Object?> params,
  ) async {
    final id = _nextId++;
    final request = http.Request('POST', url)
      ..headers.addAll(_headers)
      ..body = jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      });
    final streamed = await _client.send(request).timeout(timeout);
    final session = streamed.headers['mcp-session-id'];
    if (session != null && session.isNotEmpty) _session = session;
    if (streamed.statusCode == 404 &&
        _session != null &&
        method != 'initialize') {
      // The server forgot the session: start a new one once.
      _session = null;
      _initialized = false;
      await streamed.stream.drain<void>();
      await _initialize();
      return _request(method, params);
    }
    if (streamed.statusCode >= 400) {
      final body = await streamed.stream.bytesToString().timeout(timeout);
      throw McpException(
        'HTTP ${streamed.statusCode}${body.isEmpty ? '' : ': ${_short(body)}'}',
        status: streamed.statusCode,
      );
    }
    final type = streamed.headers['content-type'] ?? '';
    final Map<String, Object?> message;
    if (type.contains('text/event-stream')) {
      message = await _fromEvents(streamed.stream, id);
    } else {
      final body = await streamed.stream.bytesToString().timeout(timeout);
      message = _decode(body);
    }
    final error = message['error'];
    if (error is Map) {
      throw McpException('${error['message'] ?? 'error'}');
    }
    final result = message['result'];
    return result is Map ? result.cast<String, Object?>() : const {};
  }

  /// The response to [id] from a server-sent event stream.
  Future<Map<String, Object?>> _fromEvents(
    Stream<List<int>> stream,
    int id,
  ) async {
    final data = StringBuffer();
    await for (final line
        in stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .timeout(timeout)) {
      if (line.startsWith('data:')) {
        data.write(line.substring(5).trimLeft());
        continue;
      }
      if (line.isNotEmpty || data.isEmpty) continue;
      // A blank line ends an event.
      final message = _decode(data.toString());
      data.clear();
      if (message['id'] == id) return message;
    }
    if (data.isNotEmpty) {
      final message = _decode(data.toString());
      if (message['id'] == id) return message;
    }
    throw McpException('no response');
  }

  Map<String, Object?> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) return decoded.cast<String, Object?>();
    } catch (_) {}
    throw McpException('unreadable response: ${_short(body)}');
  }

  static String _short(String text) =>
      text.length > 160 ? '${text.substring(0, 160)}...' : text;

  void close() => _client.close();
}
