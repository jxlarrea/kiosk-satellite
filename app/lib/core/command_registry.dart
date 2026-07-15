import 'logging.dart';

/// Result of executing a [Command].
class CommandResult {
  const CommandResult.ok([this.data]) : ok = true, error = null;
  const CommandResult.fail(this.error) : ok = false, data = null;

  final bool ok;
  final Object? data;
  final String? error;

  Map<String, Object?> toJson() => {
        'ok': ok,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
      };
}

typedef CommandHandler = Future<CommandResult> Function(
    Map<String, Object?> params);

/// A named, remotely-invocable capability.
class Command {
  const Command({
    required this.name,
    required this.description,
    required this.handler,
    this.params = const {},
  });

  final String name;
  final String description;

  /// Human-readable parameter descriptions, keyed by param name
  /// (e.g. {'level': 'Brightness 0..1'}). Documentation, not validation.
  final Map<String, String> params;
  final CommandHandler handler;
}

/// The single administration surface.
///
/// Every user-facing capability is registered here once; the JS API bridge,
/// the remote REST/WS API, and (later) MQTT command topics are thin protocol
/// adapters over this registry.
class CommandRegistry {
  CommandRegistry(this._log);

  final Logger _log;
  final _commands = <String, Command>{};

  void register(Command command) {
    assert(!_commands.containsKey(command.name),
        'duplicate command ${command.name}');
    _commands[command.name] = command;
  }

  List<Command> get all => _commands.values.toList(growable: false);

  Future<CommandResult> execute(
      String name, Map<String, Object?> params) async {
    final command = _commands[name];
    if (command == null) return CommandResult.fail('unknown command: $name');
    try {
      _log.info('command', '$name ${params.isEmpty ? '' : params}');
      return await command.handler(params);
    } catch (e) {
      _log.error('command', '$name failed: $e');
      return CommandResult.fail('$e');
    }
  }
}
