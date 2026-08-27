import 'command_registry.dart';
import 'event_bus.dart';
import 'logging.dart';

/// Base class for all managers.
///
/// Construction must do no work; everything happens in [init]. Managers talk
/// to each other only through [bus] events and [commands] — never by direct
/// reference.
abstract class Manager {
  Manager(this.bus, CommandRegistry commands, this.log) : _commands = commands;

  final EventBus bus;
  final CommandRegistry _commands;
  final Logger log;

  /// The shared registry, seen through a handle that logs [commandSource]
  /// as the source of every command it executes. Lazy because the source
  /// is the subclass's, and construction must do no work anyway.
  late final CommandRegistry commands = _commands.as(commandSource);

  /// How this manager is named as the caller on `command:` log lines; the
  /// log tag unless a manager reads better as who is behind it (the remote
  /// admin page rather than "remote").
  String get commandSource => name;

  /// Short name used as the log tag.
  String get name;

  Future<void> init();

  Future<void> dispose() async {}
}
