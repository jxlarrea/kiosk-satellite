import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../plugins/plugin_players.dart';
import 'remote_player.dart';

/// The Now Playing surfaces following a player a plugin publishes (SDK
/// `player`), one of this device's own players beside the Sendspin
/// player, the AirPlay receiver and the Local Media Session.
///
/// Following it is what makes it the pick on the plugin's side: [start]
/// activates it and [stop] takes the pick back. A plugin that is not
/// running yet, or restarts, is activated again once it publishes the
/// player. The plugin's states reach the manager over the bus and come in
/// here through [handle]. Transport goes back to the plugin, only for the
/// actions its state lists. Volume is the device's own media volume,
/// which the manager handles as it does for the local player.
class PluginRemotePlayer implements RemotePlayer {
  PluginRemotePlayer({
    required this.pick,
    required this.onSnapshot,
    this.onUnavailable,
  });

  /// The `artworkUrl` scheme of covers the plugin sends as bytes, which
  /// SendspinManager.fetchArtwork reads from the plugin bridge.
  static const artworkScheme = 'plugin-art:';

  final String pick;
  final void Function(Map<String, Object?>? snapshot) onSnapshot;

  /// The player went missing or came back, for the chip's name.
  final void Function()? onUnavailable;

  bool _stopped = false;

  /// The session it was last activated in, so a new one activates again.
  String? _activeSession;

  @override
  String get playerId => pick;

  /// What the picker and the chip call it while it is published.
  String? get name => PluginPlayers.published.value[pick]?.name;

  @override
  bool queueEmpty = false;

  @override
  bool get hasQueue => PluginPlayers.published.value[pick]?.queue ?? false;

  @override
  bool get lyricsSynced => true;

  @override
  bool get hasFavorites => false;

  @override
  Future<bool> setFavorite(bool on) async => false;

  @override
  bool get hasGrouping => false;

  @override
  Future<RemoteGroup?> fetchGroup() async => null;

  @override
  Future<bool> setGrouped(String id, bool grouped) async => false;

  @override
  void start() {
    PluginPlayers.published.addListener(_onPublished);
    _onPublished();
  }

  @override
  Future<void> stop() async {
    _stopped = true;
    PluginPlayers.published.removeListener(_onPublished);
    if (_activeSession != null) await PluginPlayers.deactivate(pick);
    _activeSession = null;
  }

  void _onPublished() {
    if (_stopped) return;
    final info = PluginPlayers.published.value[pick];
    if (info == null) {
      if (_activeSession != null) {
        _activeSession = null;
        handle(null);
        onUnavailable?.call();
      }
      return;
    }
    if (_activeSession == info.session) return;
    _activeSession = info.session;
    onUnavailable?.call();
    unawaited(
      PluginPlayers.activate(pick).then((ok) {
        if (!ok && _activeSession == info.session) _activeSession = null;
      }),
    );
  }

  @override
  void reveal() => unawaited(refresh());

  @override
  Future<void> refresh() async => handle(PluginPlayers.states[pick]);

  @override
  Future<bool> control(String command) => PluginPlayers.command(pick, command);

  @override
  Future<bool> setShuffle(bool on) =>
      PluginPlayers.command(pick, 'shuffle', {'on': on});

  @override
  Future<bool> setRepeat(String mode) =>
      PluginPlayers.command(pick, 'repeat', {'mode': mode});

  @override
  Future<bool> seek(int positionMs) =>
      PluginPlayers.command(pick, 'seek', {'positionMs': positionMs});

  /// The device's media volume, set by the manager.
  @override
  Future<bool> setVolume(int percent) async => false;

  @override
  Future<bool> setMute(bool muted) async => false;

  @override
  Future<RemoteQueue?> fetchQueue() async {
    if (!hasQueue) return null;
    try {
      return queueFrom(await PluginPlayers.request(pick, 'queue'));
    } on PluginPlayerError {
      return null;
    }
  }

  @override
  Future<bool> playQueueItem(String id) =>
      PluginPlayers.editQueue(pick, 'play', item: id);

  /// A plugin state, null once the player stopped being the pick.
  void handle(Map<String, Object?>? state) {
    if (_stopped) return;
    final snap = snapshotFrom(pick, state);
    queueEmpty = snap == null;
    onSnapshot(snap);
  }

  /// The plugin's state in the shape every source publishes. Idle shows
  /// nothing.
  @visibleForTesting
  static Map<String, Object?>? snapshotFrom(
    String pick,
    Map<String, Object?>? state,
  ) {
    if (state == null) return null;
    final status = '${state['state'] ?? 'idle'}';
    if (status == 'idle') return null;
    String text(String key) => '${state[key] ?? ''}'.trim();
    final actions = [
      for (final a in state['actions'] as List? ?? const [])
        if (a is String) a,
    ];
    final duration = (state['durationMs'] as num?)?.toInt();
    final artworkId = (state['artworkId'] as num?)?.toInt() ?? 0;
    final url = text('artworkUrl');
    return {
      'title': text('title'),
      'artist': text('artist'),
      'album': text('album'),
      'durationMs': ?duration,
      'positionMs': (state['positionMs'] as num?)?.toInt() ?? 0,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
      'artworkUrl': artworkId > 0 ? '$artworkScheme$pick#$artworkId' : url,
      // Buffering is a track on its way, which reads as playing.
      'playing': status == 'playing' || status == 'buffering',
      'shuffle': state['shuffle'] == true,
      'repeat': switch (state['repeat']) {
        'one' => 'one',
        'all' => 'all',
        _ => 'off',
      },
      // Volume is always there: it is the device's own.
      'supportedCommands': [
        for (final a in actions)
          if (a != 'seek' || duration != null) a,
        'volume',
      ],
      if (duration == null) 'stream': true,
    };
  }

  /// The pick a [snapshotFrom] cover address names, or null.
  static String? artworkPick(String url) {
    if (!url.startsWith(artworkScheme)) return null;
    final rest = url.substring(artworkScheme.length);
    final hash = rest.lastIndexOf('#');
    return hash < 0 ? rest : rest.substring(0, hash);
  }

  /// A queue answer as the Now Playing panel lists it: the played ones
  /// above the playing one, the rest after it.
  @visibleForTesting
  static RemoteQueue? queueFrom(Object? raw) {
    if (raw is! Map) return null;
    final items = (raw['items'] as List? ?? const []).whereType<Map>().toList();
    final current = (raw['current'] as num?)?.toInt() ?? -1;
    return RemoteQueue(
      items: [
        for (final (i, item) in items.indexed)
          {
            'index': i,
            'id': '${item['id']}',
            'title': '${item['title'] ?? ''}',
            'artist': '${item['subtitle'] ?? ''}',
            'durationMs': ?(item['durationMs'] as num?)?.toInt(),
            'current': i == current,
            'played': current >= 0 && i < current,
            if ('${item['artworkUrl'] ?? ''}'.isNotEmpty)
              'artworkUrl': '${item['artworkUrl']}',
          },
      ],
      upNext: current < 0 ? items.length : items.length - current - 1,
    );
  }
}
