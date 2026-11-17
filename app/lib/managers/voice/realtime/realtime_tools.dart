import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'mcp_client.dart';

/// A tool as the model sees it.
class RealtimeToolSpec {
  const RealtimeToolSpec({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;

  /// JSON Schema for the arguments.
  final Map<String, Object?> parameters;

  Map<String, Object?> toJson() => {
    'type': 'function',
    'name': name,
    'description': description,
    'parameters': parameters,
  };
}

/// What running a tool came back with.
class RealtimeToolOutput {
  const RealtimeToolOutput(
    this.text, {
    this.error = false,
    this.endConversation = false,
  });

  /// Handed to the model as the call's output.
  final String text;
  final bool error;

  /// The model asked to end the conversation.
  final bool endConversation;
}

/// The tools a direct backend offers the model, and how they run.
abstract class RealtimeToolbox {
  /// The tools, fetched once per session. Throws when they cannot be read.
  Future<List<RealtimeToolSpec>> list();

  Future<RealtimeToolOutput> call(String name, Map<String, Object?> args);

  /// The original name of [name], for display.
  String originalName(String name);

  void close() {}
}

/// Tools that end the conversation, run in the app itself.
class LocalToolbox implements RealtimeToolbox {
  const LocalToolbox();

  static const endConversation = 'end_conversation';

  static const _end = RealtimeToolSpec(
    name: endConversation,
    description:
        'End the voice conversation. Call it when the user says goodbye, '
        'thanks you and is done, or asks you to stop listening. Say a short '
        'goodbye in the same response.',
    parameters: {'type': 'object', 'properties': <String, Object?>{}},
  );

  @override
  Future<List<RealtimeToolSpec>> list() async => const [_end];

  @override
  Future<RealtimeToolOutput> call(
    String name,
    Map<String, Object?> args,
  ) async {
    if (name == endConversation) {
      return const RealtimeToolOutput(
        '{"success": true}',
        endConversation: true,
      );
    }
    return RealtimeToolOutput('{"error": "unknown tool $name"}', error: true);
  }

  @override
  String originalName(String name) => name;

  @override
  void close() {}
}

/// Tools from an MCP server: Home Assistant's own MCP Server integration,
/// or another one the user points at.
class McpToolbox implements RealtimeToolbox {
  McpToolbox(this._client, {this.notFound, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final McpClient _client;

  /// What to say when the server is not there at all (HTTP 404): for Home
  /// Assistant, that its MCP Server integration is not set up.
  final String? notFound;

  final DateTime Function() _now;

  /// Model-safe name to the server's name.
  final _names = <String, String>{};

  /// How long a timer start blocks the same start again (issue #1475).
  /// Models repeat a start within a second of its answer. A user asking
  /// again waits for the answer to play first, so takes longer than this.
  static const repeatTimerStart = Duration(seconds: 5);

  /// The timer starts in this conversation, by their arguments, and when
  /// the model last asked for each.
  final _timerStarts = <String, DateTime>{};

  /// What the model gets for a repeated start. Home Assistant answers a
  /// start with empty lists, which some models read as nothing done and
  /// call again, so this says plainly that the timer is running.
  static final repeatedTimerStart = jsonEncode({
    'success': true,
    'result':
        'The timer is already running. It was started a moment ago. '
        'Confirm it to the user and do not start it again.',
  });

  static bool _isTimerStart(String name) =>
      name == 'HassStartTimer' || name.endsWith('__HassStartTimer');

  /// The arguments of a start, without the blank ones Home Assistant
  /// ignores, in a fixed order.
  static String _startKey(Map<String, Object?> args) {
    final keys = args.keys.where((k) {
      final v = args[k];
      return v != null && (v is! String || v.trim().isNotEmpty);
    }).toList()..sort();
    return jsonEncode({for (final k in keys) k: args[k]});
  }

  /// A function name the model accepts: letters, digits, underscore and
  /// dash, 64 at most.
  static String safeName(String name) {
    var safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (safe.length > 64) safe = safe.substring(0, 64);
    return safe.isEmpty ? 'tool' : safe;
  }

  @override
  Future<List<RealtimeToolSpec>> list() async {
    final List<McpTool> tools;
    try {
      tools = await _client.listTools();
    } on McpException catch (e) {
      final hint = notFound;
      if (e.status == 404 && hint != null) {
        throw McpException(hint, status: 404);
      }
      rethrow;
    }
    _names.clear();
    final specs = <RealtimeToolSpec>[];
    for (final tool in tools) {
      final base = safeName(tool.name);
      var name = base;
      // Two names that collapse to one keep apart by a number.
      for (var n = 2; _names.containsKey(name); n++) {
        final suffix = '_$n';
        final keep = math.min(base.length, 64 - suffix.length);
        name = '${base.substring(0, keep)}$suffix';
      }
      _names[name] = tool.name;
      specs.add(
        RealtimeToolSpec(
          name: name,
          description: tool.description,
          parameters: _objectSchema(tool.inputSchema),
        ),
      );
    }
    return specs;
  }

  /// The model takes an object schema at the top.
  static Map<String, Object?> _objectSchema(Map<String, Object?> schema) {
    if (schema['type'] == 'object') {
      return {
        ...schema,
        if (schema['properties'] == null) 'properties': <String, Object?>{},
      };
    }
    return const {'type': 'object', 'properties': <String, Object?>{}};
  }

  @override
  Future<RealtimeToolOutput> call(
    String name,
    Map<String, Object?> args,
  ) async {
    final original = _names[name];
    if (original == null) {
      return RealtimeToolOutput(
        jsonEncode({'error': 'unknown tool $name'}),
        error: true,
      );
    }
    // Models such as Gemini Live sometimes call HassStartTimer again right
    // after it answered, and every call is one more timer. Home Assistant
    // timers have no id to tell them apart, so the copies cannot be
    // cancelled either. The same start again within a short while is
    // answered here and never reaches the server.
    String? start;
    if (_isTimerStart(original)) {
      start = _startKey(args);
      final now = _now();
      final last = _timerStarts[start];
      _timerStarts[start] = now;
      if (last != null && now.difference(last) < repeatTimerStart) {
        return RealtimeToolOutput(repeatedTimerStart);
      }
    }
    final output = await _call(original, args);
    // A start that failed can be tried again.
    if (start != null && output.error) _timerStarts.remove(start);
    return output;
  }

  Future<RealtimeToolOutput> _call(
    String original,
    Map<String, Object?> args,
  ) async {
    try {
      final result = await _client.callTool(original, args);
      return RealtimeToolOutput(result.text, error: result.error);
    } on TimeoutException {
      return RealtimeToolOutput(
        jsonEncode({'error': 'Home Assistant did not answer in time'}),
        error: true,
      );
    } catch (e) {
      return RealtimeToolOutput(jsonEncode({'error': '$e'}), error: true);
    }
  }

  @override
  String originalName(String name) => _names[name] ?? name;

  @override
  void close() => _client.close();
}

/// Several toolboxes as one: the first that knows a name runs it.
class CombinedToolbox implements RealtimeToolbox {
  CombinedToolbox(this._boxes);

  final List<RealtimeToolbox> _boxes;
  final _owner = <String, RealtimeToolbox>{};

  /// Why a toolbox offered nothing on the last [list]. The others still
  /// count: the conversation goes on without the tools that failed.
  final problems = <String>[];

  @override
  Future<List<RealtimeToolSpec>> list() async {
    _owner.clear();
    problems.clear();
    final all = <RealtimeToolSpec>[];
    for (final box in _boxes) {
      final List<RealtimeToolSpec> specs;
      try {
        specs = await box.list();
      } catch (e) {
        problems.add('$e');
        continue;
      }
      for (final spec in specs) {
        if (_owner.containsKey(spec.name)) continue;
        _owner[spec.name] = box;
        all.add(spec);
      }
    }
    return all;
  }

  @override
  Future<RealtimeToolOutput> call(String name, Map<String, Object?> args) {
    final box = _owner[name];
    if (box == null) {
      return Future.value(
        RealtimeToolOutput(
          jsonEncode({'error': 'unknown tool $name'}),
          error: true,
        ),
      );
    }
    return box.call(name, args);
  }

  @override
  String originalName(String name) => _owner[name]?.originalName(name) ?? name;

  @override
  void close() {
    for (final box in _boxes) {
      box.close();
    }
  }
}
