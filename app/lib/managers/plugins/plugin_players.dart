import 'dart:async';

import 'package:flutter/foundation.dart' show ValueNotifier, listEquals;
import 'package:flutter/services.dart';

/// A player a running plugin publishes (SDK `player`), offered under
/// Media Player > Player beside this device's own players.
class PluginPlayerInfo {
  const PluginPlayerInfo({
    required this.pluginId,
    required this.key,
    required this.session,
    required this.title,
    required this.pluginName,
    this.library = false,
    this.discover = false,
    this.search = false,
    this.queue = false,
  });

  final String pluginId;
  final String key;

  /// The plugin session that published it. Requests name it, so one sent
  /// to a session that has ended does nothing.
  final String session;
  final String title;
  final String pluginName;

  /// Whether it is a Music Library source too, and what that source does.
  final bool library;
  final bool discover;
  final bool search;

  /// Whether it keeps a queue Now Playing and the library can show.
  final bool queue;

  /// The `sendspin.player` value that picks it.
  String get pick => PluginPlayers.pickOf(pluginId, key);

  /// How the picker and the chip name it: the plugin, then the player.
  String get name => '$pluginName: $title';

  @override
  bool operator ==(Object other) =>
      other is PluginPlayerInfo &&
      other.pluginId == pluginId &&
      other.key == key &&
      other.session == session &&
      other.title == title &&
      other.pluginName == pluginName &&
      other.library == library &&
      other.discover == discover &&
      other.search == search &&
      other.queue == queue;

  @override
  int get hashCode => Object.hash(
    pluginId,
    key,
    session,
    title,
    pluginName,
    library,
    discover,
    search,
    queue,
  );
}

/// The plugin players of every running plugin and the calls into them.
/// PluginManager fills [published] from the plugin bridge. The Media
/// Player pick, Now Playing and the Music Library read it and talk to a
/// player through these calls, which go to the bridge by pick.
class PluginPlayers {
  PluginPlayers._();

  static const _channel = MethodChannel('kiosk_satellite/plugins');

  static const prefix = 'plugin:';

  /// The published players by pick.
  static final published = ValueNotifier<Map<String, PluginPlayerInfo>>(
    const {},
  );

  /// The last state each active player sent, by pick. Null once it
  /// stopped being the pick or its plugin stopped.
  static final states = <String, Map<String, Object?>>{};

  static String pickOf(String pluginId, String key) => '$prefix$pluginId/$key';

  static bool isPick(String value) => value.startsWith(prefix);

  /// The plugin id and key a pick names, or null for another kind.
  static (String, String)? parse(String pick) {
    if (!isPick(pick)) return null;
    final rest = pick.substring(prefix.length);
    final slash = rest.indexOf('/');
    if (slash <= 0 || slash == rest.length - 1) return null;
    return (rest.substring(0, slash), rest.substring(slash + 1));
  }

  /// Replace the players of [pluginId] with [rows] from its session.
  static void setPlugin(
    String pluginId,
    String session,
    String pluginName,
    List<Object?> rows,
  ) {
    final next = {...published.value}
      ..removeWhere((_, p) => p.pluginId == pluginId);
    for (final raw in rows.whereType<Map>()) {
      final key = '${raw['key'] ?? ''}';
      if (key.isEmpty) continue;
      final info = PluginPlayerInfo(
        pluginId: pluginId,
        key: key,
        session: session,
        title: '${raw['title'] ?? key}',
        pluginName: pluginName,
        library: raw['library'] == true,
        discover: raw['discover'] == true,
        search: raw['search'] == true,
        queue: raw['queue'] == true,
      );
      next[info.pick] = info;
    }
    for (final pick in states.keys.toList()) {
      if (!next.containsKey(pick) && pick.startsWith('$prefix$pluginId/')) {
        states.remove(pick);
      }
    }
    if (!_same(next, published.value)) published.value = next;
  }

  static bool _same(
    Map<String, PluginPlayerInfo> a,
    Map<String, PluginPlayerInfo> b,
  ) =>
      a.length == b.length &&
      listEquals(a.keys.toList(), b.keys.toList()) &&
      a.entries.every((e) => b[e.key] == e.value);

  static Map<String, Object?>? _target(String pick) {
    final info = published.value[pick];
    if (info == null) return null;
    return {'id': info.pluginId, 'session': info.session, 'key': info.key};
  }

  /// Hand the pick to the player. False while it is not published.
  static Future<bool> activate(String pick) async {
    final target = _target(pick);
    if (target == null) return false;
    try {
      return await _channel.invokeMethod<bool>('playerActivate', target) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deactivate(String pick) async {
    final target = _target(pick);
    if (target == null) return;
    try {
      await _channel.invokeMethod<void>('playerDeactivate', target);
    } catch (_) {}
  }

  static Future<bool> command(
    String pick,
    String command, [
    Map<String, Object?> arguments = const {},
  ]) async {
    final target = _target(pick);
    if (target == null) return false;
    try {
      return await _channel.invokeMethod<bool>('playerCommand', {
            ...target,
            'command': command,
            'arguments': arguments,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Play, move or remove a queue item, or clear the queue.
  static Future<bool> editQueue(
    String pick,
    String op, {
    String item = '',
    int to = 0,
  }) async {
    final target = _target(pick);
    if (target == null) return false;
    try {
      return await _channel.invokeMethod<bool>('playerQueueEdit', {
            ...target,
            'op': op,
            'item': item,
            'to': to,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// A library or queue read the plugin answers: discover, browse, search,
  /// open, play or queue. Throws [PluginPlayerError] with the plugin's
  /// message when it fails.
  static Future<Object?> request(
    String pick,
    String op, [
    Map<String, Object?> args = const {},
  ]) async {
    final target = _target(pick);
    if (target == null) {
      throw const PluginPlayerError('The plugin is not running');
    }
    try {
      return await _channel.invokeMethod<Object?>('playerRequest', {
        ...target,
        'op': op,
        'args': args,
      });
    } on PlatformException catch (e) {
      throw PluginPlayerError(e.message ?? 'The player did not answer');
    }
  }

  static Future<Uint8List?> artwork(String pick) async {
    final target = _target(pick);
    if (target == null) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('playerArtwork', target);
    } catch (_) {
      return null;
    }
  }

  /// The assistant's duck on every plugin player's output, 1 for none.
  static Future<void> duck(double factor) async {
    try {
      await _channel.invokeMethod<void>('playerDuck', {'factor': factor});
    } catch (_) {}
  }
}

/// A plugin player's request failed, with the message the plugin gave.
class PluginPlayerError implements Exception {
  const PluginPlayerError(this.message);

  final String message;

  @override
  String toString() => message;
}
