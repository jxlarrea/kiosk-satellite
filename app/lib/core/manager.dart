import 'command_registry.dart';
import 'event_bus.dart';
import 'logging.dart';

/// Base class for all managers.
///
/// Construction must do no work; everything happens in [init]. Managers talk
/// to each other only through [bus] events and [commands] — never by direct
/// reference.
abstract class Manager {
  Manager(this.bus, this.commands, this.log);

  final EventBus bus;
  final CommandRegistry commands;
  final Logger log;

  /// Short name used as the log tag.
  String get name;

  Future<void> init();

  Future<void> dispose() async {}
}
