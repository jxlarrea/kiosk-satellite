import 'dart:async';
import 'dart:math' show Random, max;

import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/logging.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'lrclib.dart';
import 'lyrics.dart';
import 'ma_remote_player.dart';
import 'music_assistant_api.dart';

/// The device as a synchronized Sendspin audio player.
///
/// The actual player — WebSocket protocol, clock sync, decoders, the
/// timing-critical AudioTrack pipeline — lives in Kotlin (SendspinBridge and
/// the sendspin/ package): audio scheduling at millisecond precision has no
/// business crossing a platform channel per chunk. This manager owns the
/// lifecycle (settings in, state out) and translates player activity into
/// the same app-wide events every other feature speaks:
///
///  - [VoiceInteractionChanged] (reason 'media') while audio plays, so the
///    screensaver and dashboard rotation stand down exactly as they do for
///    Voice Satellite media.
///  - Status/discovery commands for the settings surfaces.
class SendspinManager extends Manager {
  SendspinManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/sendspin');

  @override
  String get name => 'sendspin';

  Timer? _restartDebounce;

  /// Serialises start/stop so a settings burst cannot interleave two
  /// client lifecycles.
  Future<void> _transition = Future.value();

  bool _running = false;
  bool _playing = false;
  Map<String, Object?> _status = const {};

  /// Live now-playing snapshot for the floating player overlay: the merged
  /// status plus 'playing' and 'receivedAt' (epoch ms of the last metadata
  /// update, for on-screen position extrapolation). Null when idle.
  final nowPlaying = ValueNotifier<Map<String, Object?>?>(null);

  /// Whether the full-screen Now Playing view has something to show: the
  /// track is playing, or paused under the view's media controls and
  /// still inside the paused hold. The screensaver slot renders the view
  /// on this (with sendspin.fullscreen), never on the raw playing flag.
  final fullscreenActive = ValueNotifier<bool>(false);

  /// Whether the playing track is a favorite in Music Assistant: null
  /// while unknown (no server configured, nothing playing, or the lookup
  /// still out). The Now Playing view's heart reads and flips it.
  final favorite = ValueNotifier<bool?>(null);

  /// The Music Assistant item behind [favorite]: uri, media_type,
  /// item_id and provider, what the add and remove commands need.
  Map<String, Object?>? _favoriteItem;

  /// The Now Playing view's queue panel: the items from the playing one
  /// on, fetched while sendspin.fullscreen_queue is on. The panel takes
  /// the lyrics' place while it is.
  final queueItems = ValueNotifier<List<Map<String, Object?>>>(const []);

  /// How many items follow the playing one, from the server's own count:
  /// the number beside the panel's Up next heading.
  final queueUpNext = ValueNotifier<int>(0);

  /// Whether the queue panel is on, the persisted setting behind the
  /// view's queue button.
  bool get queueOpen => _settings.get(defs.sendspinFullscreenQueue);
  String _queueId = '';

  /// The track the favorite and queue lookups belong to, so an answer
  /// arriving after the song changed is dropped.
  String _trackKey = '';

  /// True from a lyrics lookup starting to its answer: the view holds
  /// its panel layout through it rather than dropping to the plain look
  /// for the beat the fetch takes.
  final lyricsPending = ValueNotifier<bool>(false);

  /// The local player's queue, watched over the Music Assistant socket:
  /// the Sendspin server pushes no controller state when the queue is
  /// shuffled or edited from elsewhere, so shuffle and the queue panel
  /// would otherwise only catch up at the next track. The same follower
  /// class as the remote player's, pointed at this device's own player,
  /// its snapshots read for the queue state only, never for the card.
  MaRemotePlayer? _watcher;
  String _watcherKey = '';
  String _watchSig = '';

  /// When the local player last sent a seek, epoch ms: the re-base stands
  /// down for a moment after it.
  int _seekSentAt = 0;

  /// When the position was last taken from the server's queue time, epoch
  /// ms: for a while after it the engine's own position pushes are set
  /// aside, since the engine's extrapolation is what went wrong.
  int _maPositionAt = 0;

  /// Asks the watcher for the queue every few seconds while the local
  /// player plays: the server sends no time events of its own, and its
  /// queue's elapsed time is the one reading that matches the audio.
  Timer? _queuePoll;

  /// A track paused while the full-screen view is up, with its media
  /// controls, keeps the view, paused with its play button, for as long
  /// as the floating card keeps its paused look
  /// (sendspin.paused_hide_minutes): the person who pressed pause on that
  /// screen is not done with it. It ends when the view is dismissed, when
  /// playback resumes, and when the time runs out, and a pause landing
  /// while the view is not showing never arms it: otherwise a paused
  /// track owned the screensaver slot and the view kept coming back at
  /// every idle timeout.
  bool _pausedHold = false;

  /// Whether a screensaver session is up, which is the only time the
  /// full-screen view can be on screen.
  bool _screensaverActive = false;
  Timer? _pausedHoldTimer;

  /// True while any non-media interaction (voice, announcement, timer) is
  /// in progress: the floating player hides and playback ducks.
  final voiceActive = ValueNotifier<bool>(false);

  /// The floating card's visibility override: null follows the
  /// `sendspin.show_player` setting, true is an explicit reveal (the menu
  /// entry or a gesture, which works even while that setting is off), false
  /// an explicit dismissal (a fling, the paused-hide timer, the menu's
  /// Hide). The overlay owns the transitions back to null — a dismissal
  /// ends when playback next starts, everything resets when the session
  /// ends; it lives here so the kiosk menu can read the card's state and
  /// flip it.
  final cardOverride = ValueNotifier<bool?>(null);

  /// Whether the floating card is on screen (ignoring the momentary hide
  /// during voice interactions): what the kiosk menu's show/hide entry
  /// keys its label and action on.
  bool get cardShown =>
      nowPlaying.value != null &&
      (cardOverride.value ?? _settings.get(defs.sendspinShowPlayer));
  final _voiceReasons = <String>{};

  Timer? _idleGrace;

  /// The 'playing' flag as published to the UI. Lags reality through the
  /// grace window: at the instant playback stops, a pause and a track
  /// change are indistinguishable (both are a stream/end), so the UI keeps
  /// its playing look until the gap proves persistent.
  bool _uiPlaying = false;

  /// Whether any audio has played this session. Music Assistant reports a
  /// merely-stopped queue with its last track's metadata, which is
  /// indistinguishable from a pause; requiring a prior playing state keeps
  /// the boot sequence from conjuring a paused card out of stale metadata.
  bool _sawPlayback = false;

  /// The current track's synced lyrics, empty when there are none, the
  /// feature is off, or the lookup has not finished. The full-screen player
  /// follows it; nothing else does.
  final lyrics = ValueNotifier<List<LyricLine>>(const []);

  /// The track the lyrics in [lyrics] belong to, so a reply that arrives
  /// after the song has already changed can be discarded.
  String _lyricsKey = '';

  /// Builds the Music Assistant client. Swapped in tests; production always
  /// hands back a real one.
  @visibleForTesting
  MusicAssistantApi Function({required String baseUrl, required String token})
  apiFactory = MusicAssistantApi.new;

  /// Builds the remote-player follower (issue #265). Swapped in tests so a
  /// manager test never opens a socket.
  @visibleForTesting
  MaRemotePlayer Function({
    required String baseUrl,
    required String token,
    required String playerId,
    required void Function(Map<String, Object?>?) onSnapshot,
    required Logger log,
    String label,
  })
  remoteFactory = MaRemotePlayer.new;

  /// Live while a remote Music Assistant player is followed instead of
  /// this device's own (sendspin.ma_player): it feeds [nowPlaying] and
  /// takes the transport commands; the local player keeps playing audio
  /// but stops speaking to the UI.
  MaRemotePlayer? _remote;

  /// What [_syncRemote] last built a follower for, so an unrelated
  /// settings burst does not tear a healthy connection down.
  String _remoteKey = '';

  /// One queue recovery in flight at a time (see [_recoverQueue]).
  bool _recovering = false;

  /// Ask Music Assistant for the playing track's lyrics.
  ///
  /// One lookup per track, not per metadata update: Sendspin sends progress
  /// constantly and only the title/artist pair matters here. A track with no
  /// lyrics is remembered as such by its key, so it is not asked for again
  /// every few seconds for the length of the song.
  Future<void> _refreshLyrics() async {
    // No lyrics while following a remote player: Music Assistant reports
    // its position too coarsely to sing along with, and lyrics that lag
    // the music are worse than none.
    if (!_settings.get(defs.sendspinLyrics) || _remote != null) {
      if (lyrics.value.isNotEmpty) lyrics.value = const [];
      _lyricsKey = '';
      return;
    }
    final title = '${_status['title'] ?? ''}';
    final artist = '${_status['artist'] ?? ''}';
    final key = '$artist|$title';
    if (key == _lyricsKey) return;
    _lyricsKey = key;
    lyrics.value = const [];
    if (title.isEmpty) return;
    lyricsPending.value = true;
    final api = apiFactory(
      baseUrl: _settings.get(defs.sendspinMaUrl),
      token: _settings.get(defs.sendspinMaToken),
    );
    var lrc = await api.fetchLyrics(
      title: title,
      artist: artist,
      album: '${_status['album'] ?? ''}',
    );
    // The song may have moved on while Music Assistant was looking.
    if (_lyricsKey != key) return;
    var source = 'Music Assistant';
    if (lrc == null || lrc.trim().isEmpty) {
      // Music Assistant's providers found nothing — often strict matching
      // losing to a lyrics database's sloppy credits (issue #90). Ask
      // LRCLIB's own, looser search directly before giving up; the user's
      // local .lrc files stayed authoritative above.
      final durationMs = (_status['durationMs'] as num?)?.toInt() ?? 0;
      lrc = await LrclibApi().fetchSyncedLyrics(
        title: title,
        artist: artist,
        durationSeconds: durationMs > 0 ? (durationMs / 1000).round() : null,
      );
      if (_lyricsKey != key) return;
      source = 'LRCLIB';
    }
    final parsed = parseLrc(lrc);
    log.info(
      name,
      parsed.isEmpty
          ? 'no synced lyrics for $artist - $title'
          : 'lyrics for $artist - $title (${parsed.length} lines, $source)',
    );
    lyrics.value = parsed;
    lyricsPending.value = false;
  }

  void _setNowPlaying(Map<String, Object?>? value) {
    final wasPlaying = nowPlaying.value?['playing'] == true;
    final wasShowing = fullscreenActive.value;
    nowPlaying.value = value;
    final playing = value?['playing'] == true;
    if (playing || value == null) {
      _endPausedHold();
    } else if (wasPlaying &&
        wasShowing &&
        _screensaverActive &&
        _settings.get(defs.sendspinFullscreen) &&
        _settings.get(defs.sendspinFullscreenControls)) {
      // A pause landing under the controls of a view that is on screen
      // (after the track-change grace has ruled out a song boundary):
      // hold the view.
      _pausedHold = true;
      _pausedHoldTimer?.cancel();
      _pausedHoldTimer = Timer(
        Duration(
          minutes: _settings.get(defs.sendspinPausedHideMinutes).toInt(),
        ),
        () {
          _pausedHoldTimer = null;
          if (!_pausedHold) return;
          _pausedHold = false;
          _publishShowing();
        },
      );
    }
    final showing = playing || (value != null && _pausedHold);
    if (wasShowing != showing || wasPlaying != playing) {
      fullscreenActive.value = showing;
      bus.publish(SendspinNowPlayingChanged(active: showing, playing: playing));
    }
  }

  /// The kiosk menu's Now Playing entry: bring the view up now. A playing
  /// track takes the screensaver slot on its own; a paused one is held,
  /// the way a pause made on the view holds it, so the view opens paused
  /// with its play button instead of the regular screensaver. The
  /// screensaver start itself goes through the same command the menu's
  /// Start Screensaver uses, with every refusal that has.
  Future<void> showFullscreen() async {
    final now = nowPlaying.value;
    if (now == null) return;
    if (now['playing'] != true &&
        _settings.get(defs.sendspinFullscreenControls)) {
      _pausedHold = true;
      _pausedHoldTimer?.cancel();
      _pausedHoldTimer = Timer(
        Duration(
          minutes: _settings.get(defs.sendspinPausedHideMinutes).toInt(),
        ),
        () {
          _pausedHoldTimer = null;
          if (!_pausedHold) return;
          _pausedHold = false;
          _publishShowing();
        },
      );
      _publishShowing();
      // The takeover flag rides the bus to the screensaver; let it land
      // before the session starts.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await commands.execute('startScreensaver', const {});
  }

  /// Nothing to show any more: take the paused track off the card and
  /// the view, and forget its metadata so the next native event does not
  /// bring it back as a paused card.
  void _dropStoppedTrack() {
    _idleGrace?.cancel();
    _idleGrace = null;
    _uiPlaying = false;
    _endPausedHold();
    _status = {
      for (final e in _status.entries)
        if (!const {
          'title',
          'artist',
          'album',
          'artworkUrl',
          'positionMs',
          'durationMs',
        }.contains(e.key))
          e.key: e.value,
    };
    _setNowPlaying(null);
  }

  void _endPausedHold() {
    _pausedHold = false;
    _pausedHoldTimer?.cancel();
    _pausedHoldTimer = null;
  }

  /// Re-derive the showing flag after the hold ends on its own, or the
  /// controls are switched off under a held pause.
  void _publishShowing() {
    final playing = nowPlaying.value?['playing'] == true;
    final showing = playing || (nowPlaying.value != null && _pausedHold);
    if (fullscreenActive.value == showing) return;
    fullscreenActive.value = showing;
    bus.publish(SendspinNowPlayingChanged(active: showing, playing: playing));
  }

  void _publishNowPlaying() {
    final connected = _status['connected'] == true;
    final hasTrack = _status['title'] != null;
    if (_playing) {
      _idleGrace?.cancel();
      _idleGrace = null;
      _uiPlaying = true;
      _sawPlayback = true;
      _setNowPlaying({..._status, 'playing': true});
      return;
    }
    if (nowPlaying.value == null) {
      // Nothing shown yet: a track paused MID-SESSION still gets a card,
      // so playback paused elsewhere is resumable here. Requires having
      // actually played first — see _sawPlayback.
      if (connected && hasTrack && _sawPlayback) {
        _uiPlaying = false;
        _setNowPlaying({..._status, 'playing': false});
      }
      return;
    }
    // Something is on screen and playback just is not running: hold the
    // current look through a grace period. Track changes rebuild the
    // stream (a moment of "not playing" between stream/end and the next
    // stream/start); without the hold every song change flashed the
    // dashboard through the now-playing screensaver and the card.
    _setNowPlaying({..._status, 'playing': _uiPlaying});
    _idleGrace ??= Timer(const Duration(milliseconds: 2500), () {
      _idleGrace = null;
      if (_playing) return;
      _uiPlaying = false;
      final conn = _status['connected'] == true;
      final track = _status['title'] != null;
      if (conn && track) {
        // A real pause: the card stays, paused, ready to resume.
        _setNowPlaying({..._status, 'playing': false});
      } else {
        _setNowPlaying(null);
      }
    });
  }

  @override
  Future<void> init() async {
    nowPlaying.addListener(_onTrackChanged);
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      final map = args is Map
          ? args.cast<String, Object?>()
          : const <String, Object?>{};
      switch (call.method) {
        case 'stateChanged':
          _status = {..._status, ...map};
          log.info(
            name,
            'state: connected=${map['connected']} '
            'server=${map['serverName']} synced=${map['synced']}',
          );
        case 'metadataChanged':
          // Metadata arrives as deltas: a progress-only update carries no
          // title, and the server may send literal "null" strings. Absent
          // fields must not clobber what an earlier message established.
          // The engine's own position stands aside for a while after
          // the server's queue time was taken instead (see
          // _rebaseFromQueue): its extrapolation is the thing that
          // drifts, and every push would drag the bar back to it.
          final engineTime =
              DateTime.now().millisecondsSinceEpoch - _maPositionAt > 20000;
          _status = {
            ..._status,
            for (final e in map.entries)
              if (e.value != null &&
                  '${e.value}' != 'null' &&
                  '${e.value}'.isNotEmpty &&
                  (e.key != 'positionMs' || engineTime))
                e.key: e.value,
            if (engineTime || map.containsKey('title'))
              'receivedAt': DateTime.now().millisecondsSinceEpoch,
          };
        case 'volumeChanged':
          _status = {..._status, ...map};
          // A server-commanded media volume applied natively; persist it
          // into the media fader setting so the slider, the MQTT entity
          // and the next app start all agree. Equality-guarded: the echo
          // of our own setting push must not ping-pong.
          final vol = (map['volume'] as num?)?.toInt();
          if (vol != null && vol != _settings.get(defs.mediaVolume).toInt()) {
            unawaited(_settings.set(defs.mediaVolume, vol));
          }
        case 'controllerChanged':
          // The Sendspin server's controller state does not follow a
          // shuffle set elsewhere; with the queue watcher up, its word on
          // shuffle is the live one.
          _status = {
            ..._status,
            for (final e in map.entries)
              if (e.key != 'shuffle' || _watcher == null) e.key: e.value,
          };
        case 'playingChanged':
          final playing = map['playing'] == true;
          if (playing != _playing) {
            _playing = playing;
            _syncQueuePoll();
            // The same signal Voice Satellite media playback raises: hold
            // the screensaver and rotation while music is audible here.
            // NOT raised in full-screen player mode: there the screensaver
            // must keep firing, because it IS the now-playing display.
            if (!_settings.get(defs.sendspinFullscreen)) {
              bus.publish(
                VoiceInteractionChanged(active: playing, reason: 'media'),
              );
            } else if (!playing) {
              bus.publish(
                const VoiceInteractionChanged(active: false, reason: 'media'),
              );
            }
          }
      }
      // With a remote player followed, the local stream's metadata stays
      // off screen: the side effects above (volume, ducking, the
      // screensaver hold for audible local audio) still count, but the
      // card belongs to the remote snapshot.
      if (_remote == null) {
        _publishNowPlaying();
        unawaited(_refreshLyrics());
      }
      return null;
    });

    // Voice interactions (anything but media, which is playback itself,
    // ours included): hide the floating player and duck the audio so the
    // microphone hears the person, not the song.
    // The view leaving the screen ends a held pause: nobody is looking at
    // the paused track any more, and the regular screensaver should have
    // the slot back at the next idle timeout.
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      if (!e.active && _pausedHold) {
        _endPausedHold();
        _publishShowing();
      }
    });
    bus.on<VoiceInteractionChanged>().listen((e) {
      if (e.reason == 'media') return;
      if (e.active) {
        _voiceReasons.add(e.reason);
      } else {
        _voiceReasons.remove(e.reason);
      }
      final active = _voiceReasons.isNotEmpty;
      if (active == voiceActive.value) return;
      voiceActive.value = active;
      final factor = active
          ? _settings.get(defs.sendspinDuckPercent) / 100.0
          : 1.0;
      _channel.invokeMethod('duck', {'factor': factor}).catchError((_) {});
    });

    // The "Show the Sendspin player" gesture with nothing on screen to
    // show: the queue may still exist server-side, invisible to this app
    // since it restarted (issue #178) — go look for it.
    bus.on<SendspinShowPlayerRequested>().listen((_) {
      unawaited(_recoverQueue());
    });

    bus.on<SettingChanged>().listen((e) {
      // The card-surface flag rides the two settings that decide it.
      if (e.key == defs.sendspinMaPlayer.key ||
          e.key == defs.sendspinEnabled.key) {
        _syncFlags();
      }
      // The lyrics toggle flipping mid-track (the Now Playing view's
      // button, or either settings surface): fetch for the track already
      // playing, or clear what is up. The per-track fetch below only
      // runs at track changes.
      if (e.key == defs.sendspinLyrics.key) unawaited(_refreshLyrics());
      // The queue panel switching on (the view's button, or either
      // settings surface) fetches the queue; off drops it.
      if (e.key == defs.sendspinFullscreenQueue.key) {
        if (e.value == true) {
          unawaited(refreshQueue());
        } else {
          queueItems.value = const [];
        }
      }
      // The controls going away take a held pause with them: the view
      // has no play button to hold the screen for any more.
      if (e.key == defs.sendspinFullscreenControls.key &&
          e.value != true &&
          _pausedHold) {
        _endPausedHold();
        _publishShowing();
      }
      // The remote follower has its own lifecycle, deliberately not tied
      // to the local player's enable switch: following a remote player is
      // what the device does INSTEAD of being a player.
      if (e.key == defs.sendspinMaPlayer.key ||
          e.key == defs.sendspinMaUrl.key ||
          e.key == defs.sendspinMaToken.key) {
        _syncRemote();
        _syncWatcher();
      }
      // Only connection-shaping settings restart the client; the UI-only
      // ones (card visibility, size, position, fullscreen mode) must not
      // interrupt playback when toggled.
      // The sync offset applies live inside the running player: a slider
      // being tuned by ear must not restart the music it is tuned against.
      if (e.key == defs.sendspinSyncOffset.key) {
        unawaited(
          _channel
              .invokeMethod('setSyncOffset', {
                'ms': _settings.get(defs.sendspinSyncOffset).toInt(),
              })
              .catchError((_) {}),
        );
        return;
      }
      const uiOnly = [
        'sendspin.show_player',
        'sendspin.player_size',
        'sendspin.player_pos',
        'sendspin.fullscreen',
        'sendspin.fullscreen_controls',
        'sendspin.fullscreen_queue',
        'sendspin.fullscreen_on_play',
        'sendspin.fullscreen_shortcut',
        'sendspin.fullscreen_motion',
        'sendspin.duck_percent',
        'sendspin.paused_hide_minutes',
        'sendspin.dismiss_keeps_playing',
        // The lyric system lives on the Dart side and reads both of these
        // live (the fetch checks the toggle per track, the view reads the
        // offset every tick). An offset being tuned by ear must not restart
        // the music it is tuned against.
        'sendspin.lyrics',
        'sendspin.lyrics_offset',
        // Menu entries the kiosk drawer draws, and nothing the player does.
        'sendspin.ma_shortcut',
        'sendspin.ma_auto_close',
        'sendspin.ma_hide_close',
        'sendspin.player_shortcut',
        // The follower's display name and the bookkeeping flag: neither
        // touches the audio client. The pick itself (sendspin.ma_player)
        // is deliberately NOT here — it decides whether the local player
        // runs at all, so it goes through the restart below.
        'sendspin.ma_player_name',
        'sendspin.player_active',
        'sendspin.local_player_name',
      ];
      final relevant =
          e.key.startsWith('sendspin.') &&
              e.key != defs.sendspinClientId.key &&
              !uiOnly.contains(e.key) ||
          e.key == defs.deviceName.key;
      if (!relevant) return;
      _restartDebounce?.cancel();
      _restartDebounce = Timer(const Duration(seconds: 1), () {
        _transition = _transition.then((_) async {
          await _stop();
          if (_settings.get(defs.sendspinEnabled) && !_remotePicked) {
            await _start();
          }
        });
      });
    });

    commands.register(
      Command(
        name: 'sendspinStatus',
        description:
            'The Sendspin player status: connection, server, playback state, '
            'current track and volume.',
        handler: (_) async {
          // The cached snapshot lags fields only re-sent on events (sync
          // state); the bridge computes them live.
          var live = const <String, Object?>{};
          try {
            live = ((await _channel.invokeMethod<Map>('getStatus')) ?? const {})
                .cast<String, Object?>();
          } catch (_) {}
          return CommandResult.ok({
            'enabled': _settings.get(defs.sendspinEnabled),
            'running': _running,
            'playing': _playing,
            'fullscreenActive': fullscreenActive.value,
            if (_remote != null)
              'remotePlayer': _settings.get(defs.sendspinMaPlayerName),
            ..._status,
            ...live,
          });
        },
      ),
    );

    commands.register(
      Command(
        name: 'showNowPlaying',
        description:
            'Bring the full-screen Now Playing view up now, paused with its '
            'play button when the music is. Nothing happens with no track '
            'loaded or the view disabled.',
        handler: (_) async {
          if (nowPlaying.value == null ||
              !_settings.get(defs.sendspinFullscreen)) {
            return const CommandResult.fail('nothing to show');
          }
          await showFullscreen();
          return const CommandResult.ok();
        },
      ),
    );

    commands.register(
      Command(
        name: 'sendspinControl',
        description:
            'Send a transport command to the Sendspin group this player '
            'belongs to, or to the followed Music Assistant player when one '
            'is set (play, pause, next, previous).',
        params: const {'command': 'play | pause | next | previous'},
        handler: (p) async {
          final ok = await control('${p['command'] ?? ''}');
          return ok
              ? const CommandResult.ok()
              : const CommandResult.fail('command not supported or not sent');
        },
      ),
    );

    commands.register(
      Command(
        name: 'sendspinDiscover',
        description:
            'Scan the network for Sendspin servers (mDNS). Returns name, '
            'host, port and url per server found.',
        params: const {'timeoutMs': 'scan duration, default 3000'},
        handler: (p) async {
          try {
            final found = await _channel.invokeMethod<List<Object?>>(
              'discover',
              {'timeoutMs': (p['timeoutMs'] as num?)?.toInt() ?? 3000},
            );
            return CommandResult.ok(found ?? const []);
          } catch (e) {
            return CommandResult.fail('discovery failed: $e');
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'maValidate',
        description:
            "Check the Music Assistant address and token by opening its API "
            'and authenticating. Reports the server version on success.',
        handler: (_) async {
          final api = MusicAssistantApi(
            baseUrl: _settings.get(defs.sendspinMaUrl),
            token: _settings.get(defs.sendspinMaToken),
          );
          // 'auth' alone: it is the whole question being asked, and it needs
          // no scope, so a read-only token validates as happily as an admin
          // one.
          final result = await api.call('auth');
          if (!result.ok) {
            log.warn(
              name,
              'Music Assistant validation failed: ${result.error}',
            );
            return CommandResult.fail(result.error!);
          }
          final info = result.serverInfo;
          return CommandResult.ok({
            'version': info['server_version'],
            'schemaVersion': info['schema_version'],
            'name': info['name'],
          });
        },
      ),
    );

    commands.register(
      Command(
        name: 'maPlayers',
        description:
            'List the players Music Assistant knows, for picking which one '
            'the Now Playing card follows. Returns id, name and '
            'availability per player.',
        handler: (_) async {
          final api = apiFactory(
            baseUrl: _settings.get(defs.sendspinMaUrl),
            token: _settings.get(defs.sendspinMaToken),
          );
          final result = await api.call('players/all');
          if (!result.ok) return CommandResult.fail(result.error!);
          // This device's own player has no business in the list: "This
          // device" already is that choice, and picking it remotely would
          // take offline the very player being followed. Music Assistant
          // knows it by the Sendspin client id — bare, or embedded in a
          // wrapper's id (universal players prefix it).
          final selfId = _settings.get(defs.sendspinClientId).trim();
          final players =
              ((result.result as List?) ?? const [])
                  .whereType<Map>()
                  .where((p) => p['enabled'] != false)
                  .where(
                    (p) =>
                        selfId.isEmpty ||
                        !'${p['player_id']}'.toLowerCase().contains(
                          selfId.toLowerCase(),
                        ),
                  )
                  .map(
                    (p) => <String, Object?>{
                      'id': '${p['player_id'] ?? ''}',
                      'name':
                          '${p['display_name'] ?? p['name'] ?? p['player_id']}',
                      'available': p['available'] == true,
                    },
                  )
                  .toList()
                ..sort(
                  (a, b) => '${a['name']}'.toLowerCase().compareTo(
                    '${b['name']}'.toLowerCase(),
                  ),
                );
          return CommandResult.ok(players);
        },
      ),
    );

    _syncFlags();
    // A remote pick means the device is a remote control, not a player:
    // the local client stays down so Music Assistant shows this device
    // offline rather than as a speaker nobody should queue to.
    if (_settings.get(defs.sendspinEnabled) && !_remotePicked) {
      _transition = _transition.then((_) => _start());
    }
    _syncRemote();
  }

  /// A remote player is picked, whether or not the server is reachable.
  bool get _remotePicked =>
      _settings.get(defs.sendspinMaPlayer).trim().isNotEmpty;

  /// Keep the card-surface flag (sendspin.player_active) true whenever the
  /// card has a source — the local player enabled, or a remote player
  /// followed — so the player-UI settings rows can gate on one key.
  void _syncFlags() {
    final active = _settings.get(defs.sendspinEnabled) || _remotePicked;
    if (_settings.get(defs.sendspinPlayerActive) != active) {
      unawaited(_settings.set(defs.sendspinPlayerActive, active));
    }
  }

  /// Bring the remote follower in line with the settings: build one when a
  /// player is picked (and the server is configured), tear it down when
  /// the pick is cleared, rebuild it when the pick or the credentials
  /// change — and never touch a healthy one otherwise.
  void _syncRemote() {
    final playerId = _settings.get(defs.sendspinMaPlayer).trim();
    final baseUrl = _settings.get(defs.sendspinMaUrl).trim();
    final token = _settings.get(defs.sendspinMaToken).trim();
    final want = playerId.isNotEmpty && baseUrl.isNotEmpty && token.isNotEmpty;
    final key = want ? '$playerId|$baseUrl|$token' : '';
    if (key == _remoteKey) return;
    _remoteKey = key;
    final old = _remote;
    _remote = null;
    if (old != null) {
      unawaited(old.stop());
      // Whatever the remote showed is over; the local player's own state
      // repopulates the card (or clears it) through the normal path.
      _setNowPlaying(null);
      _publishNowPlaying();
    }
    if (!want) return;
    log.info(name, 'following Music Assistant player $playerId');
    // The local card hands the screen over to the remote one.
    _setNowPlaying(null);
    lyrics.value = const [];
    _lyricsKey = '';
    _remote = remoteFactory(
      baseUrl: baseUrl,
      token: token,
      playerId: playerId,
      onSnapshot: _onRemoteSnapshot,
      log: log,
    )..start();
  }

  void _onRemoteSnapshot(Map<String, Object?>? snapshot) {
    // A follower being torn down may answer one last time.
    if (_remote == null) return;
    _setNowPlaying(snapshot);
  }

  @override
  Future<void> dispose() async {
    _restartDebounce?.cancel();
    _pausedHoldTimer?.cancel();
    _queuePoll?.cancel();
    final watcher = _watcher;
    _watcher = null;
    await watcher?.stop();
    final remote = _remote;
    _remote = null;
    await remote?.stop();
    await _stop();
  }

  /// Bring back a queue this app session has never seen (issue #178).
  ///
  /// On connect the Sendspin server announces nothing about a queue that is
  /// not playing, so after an app restart a paused Music Assistant queue is
  /// invisible here: [nowPlaying] stays null and the reveal gesture has no
  /// card to reveal, even though the queue sits in Music Assistant ready to
  /// resume. Music Assistant does know, so when the reveal fires with
  /// nothing to show, ask it for this player's active queue and surface a
  /// paused card from the answer. Play on that card goes through the normal
  /// control channel, and live metadata takes over from there.
  ///
  /// A playing queue is left alone: its metadata is already streaming in,
  /// and a card conjured a moment earlier would only fight it.
  Future<void> _recoverQueue() async {
    // Following a remote player: its follower already holds the live
    // queue, so the reveal just asks it to surface a paused one.
    if (_remote case final remote?) {
      if (nowPlaying.value == null) remote.reveal();
      return;
    }
    if (nowPlaying.value != null || _playing || _recovering || !_running) {
      return;
    }
    _recovering = true;
    try {
      final api = apiFactory(
        baseUrl: _settings.get(defs.sendspinMaUrl),
        token: _settings.get(defs.sendspinMaToken),
      );
      final track = await api.fetchActiveQueueTrack(
        playerId: _settings.get(defs.sendspinClientId),
      );
      // The world may have moved on while Music Assistant was answering.
      if (nowPlaying.value != null || _playing || !_running) return;
      if (track == null) {
        log.info(name, 'show player: no queue to recover from Music Assistant');
        return;
      }
      if (track['state'] == 'playing') return;
      _status = {
        ..._status,
        for (final e in track.entries)
          if (e.key != 'state' && e.key != 'positionAtMs') e.key: e.value,
        'receivedAt': DateTime.now().millisecondsSinceEpoch,
      };
      _uiPlaying = false;
      _setNowPlaying({..._status, 'playing': false});
      log.info(
        name,
        'recovered the paused queue from Music Assistant: '
        '${track['artist'] ?? '?'} - ${track['title']}',
      );
      unawaited(_refreshLyrics());
    } finally {
      _recovering = false;
    }
  }

  /// Group transport control (the controller role). False when the server
  /// does not support the command or nothing is connected. With a remote
  /// player followed, the command goes to Music Assistant for that player
  /// instead of into the local Sendspin group.
  Future<bool> control(String command) async {
    if (_remote case final remote?) return remote.control(command);
    try {
      return await _channel.invokeMethod<bool>('control', {
            'command': command,
          }) ??
          false;
    } catch (e) {
      log.warn(name, 'control $command failed: $e');
      return false;
    }
  }

  bool get _maConfigured =>
      _settings.get(defs.sendspinMaUrl).trim().isNotEmpty &&
      _settings.get(defs.sendspinMaToken).trim().isNotEmpty;

  MusicAssistantApi _api() => apiFactory(
    baseUrl: _settings.get(defs.sendspinMaUrl),
    token: _settings.get(defs.sendspinMaToken),
  );

  /// The queue Music Assistant is playing on the shown player: the
  /// followed one, or this device's own (which Music Assistant resolves
  /// through the player's active source, a wrapping universal player
  /// included).
  Future<Map<String, Object?>?> _activeQueue() async {
    final String playerId =
        _remote?.playerId ?? _settings.get(defs.sendspinClientId);
    if (playerId.isEmpty) return null;
    final res = await _api().call(
      'player_queues/get_active_queue',
      args: {'player_id': playerId},
    );
    final queue = res.result;
    return res.ok && queue is Map ? queue.cast<String, Object?>() : null;
  }

  /// Start, restart or stop the queue watcher to match the moment: the
  /// local player running with a Music Assistant server configured and no
  /// remote player followed (the follower already carries that queue).
  void _syncWatcher() {
    final clientId = _settings.get(defs.sendspinClientId);
    final want =
        _remote == null && _running && _maConfigured && clientId.isNotEmpty;
    final key = want
        ? '${_settings.get(defs.sendspinMaUrl)}|'
              '${_settings.get(defs.sendspinMaToken)}|$clientId'
        : '';
    if (key == _watcherKey && (want == (_watcher != null))) return;
    _watcherKey = key;
    final old = _watcher;
    _watcher = null;
    _watchSig = '';
    if (old != null) unawaited(old.stop());
    _syncQueuePoll();
    if (!want) return;
    _watcher = remoteFactory(
      baseUrl: _settings.get(defs.sendspinMaUrl),
      token: _settings.get(defs.sendspinMaToken),
      playerId: clientId,
      onSnapshot: _onWatchSnapshot,
      log: log,
      label: 'queue watcher',
    )..start();
    _syncQueuePoll();
  }

  /// A queue snapshot for the local player: only its shuffle flag and
  /// its identity are read. Shuffle lands on the card state; a queue
  /// edit refreshes the panel while it is open.
  void _onWatchSnapshot(Map<String, Object?>? snapshot) {
    if (_watcher == null) return;
    if (snapshot == null) {
      // The queue cleared in Music Assistant: the stream merely ended,
      // which read as a pause, and the last track sat on the card and
      // the view with controls that had nothing left to act on.
      if (_watcher!.queueEmpty && !_playing && nowPlaying.value != null) {
        log.info(name, 'queue cleared in Music Assistant; track dropped');
        _dropStoppedTrack();
      }
      return;
    }
    _rebaseFromQueue(snapshot);
    final shuffle = snapshot['shuffle'] == true;
    if (shuffle != (_status['shuffle'] == true)) {
      _status = {..._status, 'shuffle': shuffle};
      if (_remote == null && nowPlaying.value != null) {
        nowPlaying.value = {...nowPlaying.value!, 'shuffle': shuffle};
      }
    }
    final sig =
        '${snapshot['queueItemId']}|${snapshot['currentIndex']}|'
        '${snapshot['queueLength']}|$shuffle';
    if (sig != _watchSig) {
      final first = _watchSig.isEmpty;
      _watchSig = sig;
      if (!first && queueOpen) unawaited(refreshQueue());
    }
  }

  /// Keep the queue poll running exactly while the local player plays
  /// with the watcher up.
  void _syncQueuePoll() {
    final want = _watcher != null && _playing;
    if (want == (_queuePoll != null)) return;
    _queuePoll?.cancel();
    _queuePoll = null;
    if (!want) return;
    _queuePoll = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_watcher?.refresh());
    });
  }

  /// The server's queue time as the position's authority for the local
  /// player. The engine extrapolates from the last metadata progress
  /// report, and Music Assistant leaves that report behind after a queue
  /// jump or a seek (or freezes it), so the engine can run a whole minute
  /// ahead of the audio or stand still. The watcher reads the queue's
  /// live elapsed time every few seconds; when it disagrees with what is
  /// on screen by more than a moment, for the same track and with both
  /// sides playing, the position is re-based on it here and in the
  /// engine's pushes alike, so the two cannot ping-pong.
  void _rebaseFromQueue(Map<String, Object?> snapshot) {
    if (_remote != null || !_playing || snapshot['playing'] != true) return;
    if (snapshot['timeFresh'] != true) return;
    if ('${snapshot['title'] ?? ''}' != '${_status['title'] ?? ''}') return;
    // Our own seek is in flight for a moment: the server's next time
    // reports may still describe the place it left.
    if (DateTime.now().millisecondsSinceEpoch - _seekSentAt < 4000) return;
    final maPos = (snapshot['positionMs'] as num?)?.toInt();
    final maAt = (snapshot['receivedAt'] as num?)?.toInt();
    final ourPos = (_status['positionMs'] as num?)?.toInt();
    final ourAt = (_status['receivedAt'] as num?)?.toInt();
    if (maPos == null || maAt == null || ourPos == null || ourAt == null) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final maNow = maPos + (now - maAt);
    final ourNow = ourPos + (now - ourAt);
    if ((maNow - ourNow).abs() < 2500) return;
    log.info(
      name,
      'position re-based on Music Assistant: '
      '${ourNow ~/ 1000}s to ${maNow ~/ 1000}s',
    );
    _status = {..._status, 'positionMs': maNow, 'receivedAt': now};
    _maPositionAt = now;
    _publishNowPlaying();
    unawaited(
      _channel
          .invokeMethod('rebasePosition', {'positionMs': maNow})
          .catchError((_) => null),
    );
  }

  /// The track on screen changed (or went away): re-read what Music
  /// Assistant knows about it for the favorite heart and the queue panel.
  void _onTrackChanged() {
    final now = nowPlaying.value;
    final key = now == null
        ? ''
        : '${now['artist'] ?? ''}|${now['title'] ?? ''}';
    if (key == _trackKey) return;
    _trackKey = key;
    if (now == null) {
      favorite.value = null;
      _favoriteItem = null;
      queueItems.value = const [];
      return;
    }
    unawaited(_refreshFavorite());
    if (queueOpen) unawaited(refreshQueue());
  }

  Future<void> _refreshFavorite() async {
    final key = _trackKey;
    favorite.value = null;
    _favoriteItem = null;
    if (!_maConfigured || key == '|') return;
    final title = '${nowPlaying.value?['title'] ?? ''}';
    // Music Assistant's queue can lag the Sendspin metadata by a beat at
    // a track boundary: an item that is not the one on screen gets one
    // more look after a moment.
    for (var attempt = 0; attempt < 2; attempt++) {
      final queue = await _activeQueue();
      if (_trackKey != key) return;
      final media = (queue?['current_item'] as Map?)?['media_item'];
      final uri = media is Map ? '${media['uri'] ?? ''}' : '';
      final name = media is Map ? '${media['name'] ?? ''}' : '';
      if (uri.isNotEmpty && (name == title || attempt == 1)) {
        await _resolveFavorite(uri, key);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_trackKey != key) return;
    }
  }

  /// Read the item's library state: the library copy when it has one
  /// (favorites always do), the provider item otherwise.
  Future<void> _resolveFavorite(String uri, String key) async {
    final res = await _api().call('music/item_by_uri', args: {'uri': uri});
    final item = res.result;
    if (_trackKey != key || !res.ok || item is! Map) return;
    _favoriteItem = {
      'uri': uri,
      'media_type': item['media_type'],
      'item_id': item['item_id'],
      'provider': item['provider'],
    };
    favorite.value = item['favorite'] == true;
  }

  /// Flip the playing track's favorite in Music Assistant: the Now
  /// Playing view's heart. Optimistic on screen, re-read from the server
  /// after, and put back on a refusal.
  Future<bool> toggleFavorite() async {
    final item = _favoriteItem;
    final current = favorite.value;
    if (item == null || current == null) return false;
    final key = _trackKey;
    favorite.value = !current;
    final res = current
        ? await _api().call(
            'music/favorites/remove_item',
            args: {
              'media_type': item['media_type'],
              'library_item_id': item['item_id'],
            },
          )
        : await _api().call(
            'music/favorites/add_item',
            args: {'item': item['uri']},
          );
    if (_trackKey != key) return res.ok;
    if (!res.ok) {
      log.warn(name, 'favorite toggle failed: ${res.error}');
      favorite.value = current;
      return false;
    }
    await _resolveFavorite('${item['uri']}', key);
    return true;
  }

  /// The view's queue button: flip the persisted panel setting, taking
  /// the lyrics down with it when it goes up, since the two share one
  /// slot. The setting's own change handler fetches the queue.
  Future<void> toggleQueue() async {
    final on = !queueOpen;
    // The incoming panel goes up before the other comes down, so the
    // layout never passes through the plain look between them.
    await _settings.set(defs.sendspinFullscreenQueue, on);
    if (on && _settings.get(defs.sendspinLyrics)) {
      await _settings.set(defs.sendspinLyrics, false);
    }
  }

  /// The view's lyrics button: the mirror of [toggleQueue].
  Future<void> toggleLyrics() async {
    final on = !_settings.get(defs.sendspinLyrics);
    await _settings.set(defs.sendspinLyrics, on);
    if (on && queueOpen) {
      await _settings.set(defs.sendspinFullscreenQueue, false);
    }
  }

  /// Fetch the queue from the playing item on: title, artist, duration
  /// and the queue index of each, the playing one flagged.
  Future<void> refreshQueue() async {
    if (!_maConfigured) {
      queueItems.value = const [];
      return;
    }
    final key = _trackKey;
    final queue = await _activeQueue();
    if (queue == null) {
      queueItems.value = const [];
      return;
    }
    final queueId = '${queue['queue_id'] ?? ''}';
    final index = (queue['current_index'] as num?)?.toInt() ?? 0;
    final currentId =
        '${(queue['current_item'] as Map?)?['queue_item_id'] ?? ''}';
    // The whole queue, what came before included: the panel lists the
    // played items faded above the playing one, the way Music Assistant
    // does. Capped where a queue is longer than anyone scrolls.
    final res = await _api().call(
      'player_queues/items',
      args: {'queue_id': queueId, 'limit': 500, 'offset': 0},
    );
    final items = res.result;
    if (_trackKey != key || !res.ok || items is! List) return;
    _queueId = queueId;
    // Music Assistant leaves every item's own index at zero here: the
    // position comes from the offset, the identity from the item id.
    queueItems.value = [
      for (final (i, it) in items.indexed)
        if (it is Map) _queueRow(it, i, index, currentId),
    ];
    final total = (queue['items'] as num?)?.toInt() ?? items.length;
    queueUpNext.value = max(0, total - index - 1);
  }

  static Map<String, Object?> _queueRow(
    Map it,
    int index,
    int currentIndex,
    String currentId,
  ) {
    final media = it['media_item'] is Map
        ? (it['media_item'] as Map).cast<String, Object?>()
        : const <String, Object?>{};
    final artist = ((media['artists'] as List?) ?? const [])
        .map((a) => a is Map ? '${a['name'] ?? ''}' : '')
        .where((s) => s.isNotEmpty)
        .join('/');
    final duration = (it['duration'] as num?) ?? (media['duration'] as num?);
    final id = '${it['queue_item_id'] ?? ''}';
    return {
      'index': index,
      'id': id,
      'title': '${media['name'] ?? it['name'] ?? ''}',
      'artist': artist,
      if (duration != null) 'durationMs': (duration * 1000).round(),
      'current': id.isNotEmpty && id == currentId,
      'played': index < currentIndex,
    };
  }

  /// Jump the queue to the item [queueItemId]: a tap on a row of the
  /// queue panel. The id, not the position: Music Assistant takes either,
  /// and the id survives a shuffle between the fetch and the tap.
  Future<bool> playQueueItem(String queueItemId) async {
    if (_queueId.isEmpty || queueItemId.isEmpty) return false;
    final res = await _api().call(
      'player_queues/play_index',
      args: {'queue_id': _queueId, 'index': queueItemId},
    );
    if (!res.ok) log.warn(name, 'play queue item failed: ${res.error}');
    return res.ok;
  }

  /// Shuffle the queue on or off: the Now Playing view's shuffle toggle.
  /// Locally the controller role's shuffle and unshuffle commands; for a
  /// followed player Music Assistant's queue setting.
  Future<bool> setShuffle(bool on) async {
    if (_remote case final remote?) return remote.setShuffle(on);
    return control(on ? 'shuffle' : 'unshuffle');
  }

  /// Jump the playing track to [positionMs]: the Now Playing view's
  /// progress bar. Locally the controller role's seek command, which the
  /// server advertises like any other; for a followed player Music
  /// Assistant's own seek, in whole seconds.
  Future<bool> seek(int positionMs) async {
    if (_remote case final remote?) return remote.seek(positionMs);
    _seekSentAt = DateTime.now().millisecondsSinceEpoch;
    try {
      return await _channel.invokeMethod<bool>('control', {
            'command': 'seek',
            'value': positionMs,
          }) ??
          false;
    } catch (e) {
      log.warn(name, 'seek failed: $e');
      return false;
    }
  }

  Future<void> _start() async {
    // The player name is the same identity everything else shows: the
    // device name setting, or the hardware model via getDeviceInfo.
    var playerName = _settings.get(defs.deviceName).trim();
    if (playerName.isEmpty) {
      final info = await commands.execute('getDeviceInfo', const {});
      final data = info.data;
      if (info.ok && data is Map) playerName = '${data['name'] ?? 'Kiosk'}';
    }
    // Remembered for the Music Assistant shortcut, which lands the web
    // interface on this player by this name (issue #265).
    if (_settings.get(defs.sendspinLocalPlayerName) != playerName) {
      unawaited(_settings.set(defs.sendspinLocalPlayerName, playerName));
    }
    // Checked at every start, not just boot: an identity-shedding import
    // (restore as a new device) clears the id, and the next start must
    // come up as a fresh player rather than reuse the cleared value.
    var clientId = _settings.get(defs.sendspinClientId);
    if (clientId.isEmpty) {
      final rng = Random.secure();
      clientId = List.generate(
        32,
        (_) => rng.nextInt(16).toRadixString(16),
      ).join();
      await _settings.set(defs.sendspinClientId, clientId);
    }
    try {
      await _channel.invokeMethod('start', {
        'serverUrl': _settings.get(defs.sendspinServer).trim(),
        'playerName': playerName,
        'clientId': clientId,
        'preferredCodec': _settings.get(defs.sendspinCodec),
        'syncOffsetMs': _settings.get(defs.sendspinSyncOffset).toInt(),
      });
      _running = true;
      log.info(name, 'player started as "$playerName"');
      _syncWatcher();
    } catch (e) {
      log.warn(name, 'start failed: $e');
    }
  }

  Future<void> _stop() async {
    if (!_running) return;
    _running = false;
    _syncWatcher();
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      log.warn(name, 'stop failed: $e');
    }
    if (_playing) {
      _playing = false;
      bus.publish(
        const VoiceInteractionChanged(active: false, reason: 'media'),
      );
    }
    _status = const {};
    _idleGrace?.cancel();
    _idleGrace = null;
    _uiPlaying = false;
    // A remote follower owns the card; a local restart must not blank it.
    if (_remote == null) _setNowPlaying(null);
  }
}
