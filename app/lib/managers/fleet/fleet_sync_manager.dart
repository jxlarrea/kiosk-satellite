import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show File, InternetAddress;
import 'dart:math' show Random;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show md5, sha256;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/kiosk_http_client.dart';
import '../../core/manager.dart';
import '../gestures/gesture_mappings.dart';
import '../plugins/fleet_plugin_host.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'fleet_manager.dart';

/// A profile: what a follower assigned to it gets from its leader. The
/// categories, which of the credentials, whether the dashboard and the
/// settings taken back out. The built-in Default (id `default`) is always
/// there and editable; the leader adds more and hands each follower one.
@immutable
class SyncProfile {
  const SyncProfile({
    this.id = defaultId,
    this.name = 'Default',
    required this.categories,
    this.credentials = const {},
    this.dashboard = false,
    this.excluded = defs.fleetDefaultExcluded,
    this.plugins = const {},
  });

  static const defaultId = 'default';

  /// The built-in Default, until the leader edits it.
  static const initial = SyncProfile(
    categories: defs.fleetDefaultCategories,
    credentials: defs.fleetDefaultCredentials,
  );

  /// The built-in Updates only: no category, no credential, no dashboard,
  /// so a kiosk on it keeps every setting of its own and the leader only
  /// pushes updates to it. Never stored, never edited, never deleted.
  static const updatesOnlyId = 'updates-only';
  static const updatesOnly = SyncProfile(
    id: updatesOnlyId,
    name: 'Updates only',
    categories: {},
    credentials: {},
    excluded: {},
  );

  final String id;
  final String name;

  /// The definitions categories that travel (`Screensaver`, `Sendspin`).
  final Set<String> categories;

  /// The credential keys that travel, out of [defs.fleetCredentialKeys].
  final Set<String> credentials;
  final bool dashboard;

  /// Settings taken out whatever their category says: the display-bound
  /// ones by default and anything the leader added.
  final Set<String> excluded;

  /// The leader's plugins that travel, by id: the package, its settings
  /// and whether it runs.
  final Set<String> plugins;

  /// A profile from its JSON (a map or the string it was stored as); null
  /// for nothing. A map without an id is a new profile for the caller to
  /// name.
  static SyncProfile? parse(Object? raw) {
    Object? value = raw;
    if (value is String) {
      if (value.trim().isEmpty) return null;
      try {
        value = jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    if (value is! Map) return null;
    final cats = value['categories'];
    if (cats is! List) return null;
    final creds = value['credentials'];
    final excluded = value['excluded'];
    final plugins = value['plugins'];
    return SyncProfile(
      id: '${value['id'] ?? ''}',
      name: '${value['name'] ?? ''}',
      categories: {for (final c in cats) '$c'},
      credentials: creds is List
          ? {
              for (final c in creds)
                if (defs.fleetCredentialKeys.contains('$c')) '$c',
            }
          : const {},
      dashboard: value['dashboard'] == true,
      excluded: excluded is List
          ? {for (final k in excluded) '$k'}
          : defs.fleetDefaultExcluded,
      plugins: plugins is List ? {for (final id in plugins) '$id'} : const {},
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'categories': categories.toList(),
    'credentials': credentials.toList(),
    // What this version offered, so a later one tells the credentials
    // left off from the ones it adds (_loadProfiles).
    'credentialsOffered': defs.fleetCredentialKeys.toList(),
    // The default then, so a later one adds what joined it only where
    // nothing of it was switched off (_loadProfiles).
    'credentialsDefault': defs.fleetDefaultCredentials.toList(),
    'dashboard': dashboard,
    'excluded': excluded.toList(),
    'plugins': plugins.toList(),
  };

  SyncProfile copyWith({
    String? id,
    String? name,
    Set<String>? categories,
    Set<String>? credentials,
    bool? dashboard,
    Set<String>? excluded,
    Set<String>? plugins,
  }) => SyncProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    categories: categories ?? this.categories,
    credentials: credentials ?? this.credentials,
    dashboard: dashboard ?? this.dashboard,
    excluded: excluded ?? this.excluded,
    plugins: plugins ?? this.plugins,
  );

  bool get isDefault => id == defaultId;
  bool get isUpdatesOnly => id == updatesOnlyId;

  /// The two that ship with the app: neither can be deleted, and Updates
  /// only cannot be changed either.
  bool get isBuiltIn => isDefault || isUpdatesOnly;

  /// One line for a row: "Categories: 9 of 16. Credentials: 2 of 3.
  /// Excluded: 14."
  String describe() => isUpdatesOnly
      ? 'Nothing syncs. Only updates are pushed.'
      : 'Categories: ${categories.length} of ${defs.fleetSyncCategories.length}. '
            'Credentials: ${credentials.length} of ${defs.fleetCredentialKeys.length}. '
            'Excluded: ${excluded.length}.';

  @override
  bool operator ==(Object other) =>
      other is SyncProfile &&
      other.id == id &&
      other.name == name &&
      setEquals(other.categories, categories) &&
      setEquals(other.credentials, credentials) &&
      other.dashboard == dashboard &&
      setEquals(other.excluded, excluded) &&
      setEquals(other.plugins, plugins);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(credentials),
    dashboard,
    Object.hashAllUnordered(excluded),
    Object.hashAllUnordered(plugins),
  );
}

/// One kiosk a leader pushes to: what is persisted about it and what the
/// last poll learned.
class Follower {
  Follower({
    required this.id,
    required this.name,
    required this.address,
    required this.port,
    this.token,
    this.invite,
    this.profile,
    this.declined = false,
    int? addedAt,
    this.lastSyncAt = 0,
    this.version = '',
    this.tls = false,
    this.dnsName = '',
    this.adminUrl = '',
  }) : addedAt = addedAt ?? DateTime.now().millisecondsSinceEpoch;

  final String id;
  String name;
  String address;
  int port;

  /// The fleet token the kiosk minted on accepting, null until then (or
  /// after it left).
  String? token;

  /// The nonce of the invitation still waiting on the kiosk's screen.
  String? invite;

  /// The id of the profile this kiosk gets, null for the Default.
  String? profile;

  /// The invitation was declined on the kiosk: the row says so until it is
  /// removed or invited again.
  bool declined;

  /// The leader's custom wake word models this kiosk last matched, by their
  /// hash. Not saved: after a restart one comparison sets it again.
  String? wakeModelsRevision;

  final int addedAt;
  int lastSyncAt;
  String version;
  bool tls;

  /// The DNS name its imported certificate covers, for the member
  /// directory's links. Fleet calls keep to [address].
  String dnsName;

  /// Its Admin URL, for the member directory's links too.
  String adminUrl;

  // What the last poll learned. Not persisted.
  bool online = false;
  String? appliedRevision;
  bool dirty = false;
  Map<String, Object?>? update;
  String? error;

  /// Null on older kiosks that do not support the member directory.
  String? rosterRevision;

  /// The plugin packages installed there, by id: their hashes, as the last
  /// poll reported. Not persisted.
  Map<String, String> pluginHashes = const {};

  /// The synced plugins that failed there, by id, with the package hash,
  /// the plugin's name and why, as the kiosk reports them.
  Map<String, Map<String, Object?>> pluginErrors = const {};

  /// The packages this kiosk could not send, by plugin id: the hash and
  /// the plugin's name. Not sent again until the hash changes or a sync
  /// is asked for.
  final packageErrors = <String, (String, String)>{};

  /// How much of the uploaded APK the leader has streamed to this kiosk,
  /// 0 to 1 while a fleet install sends it, null otherwise. The leader's
  /// own count, so the poll never overwrites it.
  double? sending;

  String get url =>
      Uri(scheme: tls ? 'https' : 'http', host: address, port: port).toString();

  static Follower? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = '${raw['id'] ?? ''}';
    if (id.isEmpty) return null;
    final port = raw['port'];
    return Follower(
      id: id,
      name: '${raw['name'] ?? ''}',
      address: '${raw['address'] ?? ''}',
      port: port is num ? port.toInt() : 2324,
      token: raw['token'] as String?,
      invite: raw['invite'] as String?,
      profile: raw['profile'] as String?,
      declined: raw['declined'] == true,
      addedAt: (raw['addedAt'] as num?)?.toInt(),
      lastSyncAt: (raw['lastSyncAt'] as num?)?.toInt() ?? 0,
      version: '${raw['version'] ?? ''}',
      tls: raw['tls'] == true,
      dnsName: '${raw['dnsName'] ?? ''}',
      adminUrl: '${raw['adminUrl'] ?? ''}',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'port': port,
    if (tls) 'tls': true,
    if (dnsName.isNotEmpty) 'dnsName': dnsName,
    if (adminUrl.isNotEmpty) 'adminUrl': adminUrl,
    if (token != null) 'token': token,
    if (invite != null) 'invite': invite,
    if (profile != null) 'profile': profile,
    if (declined) 'declined': true,
    'addedAt': addedAt,
    'lastSyncAt': lastSyncAt,
    'version': version,
  };
}

/// One kiosk leads, the others follow.
///
/// The leader keeps a list of followers and pushes each the settings its
/// list allows (the fleet default or the kiosk's own), whenever something
/// in them changes here, whenever a follower reports it drifted and never
/// while the two run different versions. A follower accepts an invitation
/// on its own screen, hands the leader a token good only for the fleet
/// endpoints, applies what arrives through the settings import path, and
/// leaves whenever it likes. Both UIs draw the `fleetStatus` command and
/// hear [FleetSyncChanged] when to redraw.
///
/// Kiosks find each other through the switcher's discovery (the `fleet`
/// command), which is also where this kiosk's own id and version come from,
/// so the whole feature needs the remote admin and Find other kiosks on.
class FleetSyncManager extends Manager {
  FleetSyncManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'fleetsync';

  /// Swapped for a fake in tests.
  http.Client Function() clientFactory = kioskPeerClient;

  /// How long one call to another kiosk may take. A kiosk on the list is on
  /// the same network, so anything past this is a kiosk that is not there.
  Duration requestTimeout = const Duration(seconds: 6);

  /// The status poll runs at this cadence while a page is watching
  /// (`fleetStatus` was asked within a minute) and every tenth tick
  /// otherwise: the followers are few and the poll is a small GET, but a
  /// fleet nobody is looking at needs no metronome.
  Duration tickInterval = const Duration(seconds: 30);

  // ── State ──────────────────────────────────────────────────────────

  final List<Follower> _followers = [];

  /// The profiles, the Default first.
  final List<SyncProfile> _profiles = [];

  String _selfId = '';
  String _selfName = '';
  String _selfVersion = '';
  FleetDevice? _self;

  Timer? _timer;
  Timer? _bump;
  int _ticks = 0;
  bool _ticking = false;
  bool _remoteObserved = false;

  /// What this manager last read or wrote for the followers and the
  /// profiles. Anything else in the setting came from outside, a restored
  /// backup, and is read back in.
  String _followersRaw = '';
  String _profilesRaw = '';

  /// Set when the followers changed outside while a tick was walking
  /// them: the tick does not save its copy and reads them back at its end.
  bool _followersStale = false;
  DateTime _watchedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  final _subs = <StreamSubscription<Object?>>[];

  /// Followers already told to install a release, by the version asked,
  /// so Keep followers on this version asks once per release.
  final _autoUpdated = <String, String>{};

  /// The fleet install of an uploaded APK under way or the last one done,
  /// as `install` in [status]: which kiosk the APK is going to and how far,
  /// who is installing, who was skipped and why. Both UIs ride it.
  Map<String, Object?>? _install;

  /// The plugin runtime, set by the app container before [init]. Null
  /// leaves plugins out of the fleet.
  FleetPluginHost? plugins;

  /// The leader's plugins as the runtime last listed them, and whether a
  /// listing ever arrived: without one a push could not tell a profile's
  /// plugins from none and would remove them on the followers.
  List<Map<String, Object?>> _pluginState = const [];
  bool _pluginsKnown = false;

  /// Plugin packages a leader sent ahead of its push, by hash.
  final _staged = <String, Uint8List>{};
  bool _applyingPlugins = false;

  /// Followers, for the device UI (the remote reads `fleetStatus`).
  List<Follower> get followers => List.unmodifiable(_followers);

  bool get leading => _settings.get(defs.fleetLeader);

  /// Whether the feature can run: the remote admin serves, with the
  /// discovery that names this kiosk and finds the others.
  bool get enabled =>
      _settings.get(defs.remoteEnabled) &&
      _settings.get(defs.remotePassword).isNotEmpty &&
      _settings.get(defs.remoteFleetDiscovery);

  /// The leader this kiosk follows or null.
  Map<String, Object?>? get leader {
    final raw = _settings.get(defs.fleetLeaderInfo);
    if (raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      return map is Map ? map.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  bool get following => leader != null;

  /// The invitation waiting on this kiosk or null.
  Map<String, Object?>? get invite {
    final raw = _settings.get(defs.fleetInvite);
    if (raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      return map is Map ? map.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  /// An invitation nobody has answered yet: what the kiosk screen shows.
  Map<String, Object?>? get pendingInvite {
    final inv = invite;
    return inv != null && inv['status'] == 'pending' ? inv : null;
  }

  /// The keys the leader last pushed here.
  Set<String> get syncedKeys {
    final raw = _settings.get(defs.fleetSyncedKeys);
    if (raw.isEmpty) return const {};
    try {
      final list = jsonDecode(raw);
      return list is List ? {for (final k in list) '$k'} : const {};
    } catch (_) {
      return const {};
    }
  }

  /// The plugins the leader syncs here, by id: `name`, `fp` (what was
  /// applied), `secrets` and `installed` (the fleet installed it).
  Map<String, Map<String, Object?>> get syncedPlugins =>
      _jsonMap(_settings.get(defs.fleetSyncedPlugins));

  /// The synced plugins that failed here, by id: `sha256`, `name` and
  /// `message`.
  Map<String, Map<String, Object?>> get pluginErrors =>
      _jsonMap(_settings.get(defs.fleetPluginErrors));

  static Map<String, Map<String, Object?>> _jsonMap(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return const {};
      return {
        for (final e in map.entries)
          if (e.value is Map)
            '${e.key}': (e.value as Map).cast<String, Object?>(),
      };
    } catch (_) {
      return const {};
    }
  }

  /// The leader's installed plugins, for the profile pages.
  List<Map<String, Object?>> get pluginState => _pluginState;

  /// The profiles, the Default first.
  List<SyncProfile> get profiles => List.unmodifiable(_profiles);

  SyncProfile get defaultProfile =>
      _profiles.where((p) => p.isDefault).firstOrNull ?? SyncProfile.initial;

  /// The profile a follower gets: its own or the Default when it names
  /// none or one that was deleted.
  SyncProfile profileFor(Follower f) {
    final id = f.profile;
    if (id == null) return defaultProfile;
    return _profiles.where((p) => p.id == id).firstOrNull ?? defaultProfile;
  }

  String get selfVersion => _selfVersion;

  // ── Init ───────────────────────────────────────────────────────────

  @override
  Future<void> init() async {
    _subs.add(
      bus.on<RemoteObserversChanged>().listen((event) {
        _remoteObserved = event.topics.contains('fleetsync');
      }),
    );
    _loadFollowers();
    await _loadProfiles();
    _register();

    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
    // The leader's custom wake word models changed: pass them on soon, as
    // a setting change is.
    _subs.add(
      bus.on<RemoteStatusChanged>().listen((e) {
        if (e.topic == 'plugin-settings') {
          unawaited(_onPluginsChanged());
          return;
        }
        if (e.topic != 'wake-models' || !leading) return;
        _bump?.cancel();
        _bump = Timer(const Duration(seconds: 2), _scheduleTick);
      }),
    );
    // A kiosk coming back on the network is the moment to look again.
    _subs.add(
      bus.on<FleetChanged>().listen((_) {
        unawaited(_readSelf());
        if (leading) _scheduleTick();
      }),
    );
    // The invitation on a kiosk screen must survive a restart, not a
    // reboot's worth of the leader polling into the void: an invitation
    // older than a day is dropped, the leader shows Waiting for its OK
    // until it is removed or invited again.
    final inv = invite;
    if (inv != null) {
      final at = (inv['at'] as num?)?.toInt() ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - at > 86400000) {
        await _settings.set(defs.fleetInvite, '');
      }
    }
    await _readSelf();
    if (leading) await _readPlugins();
    _timer = Timer.periodic(tickInterval, (_) => _onTimer());
    if (leading) _scheduleTick();
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _bump?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
  }

  void _loadFollowers() {
    _followers.clear();
    final raw = _settings.get(defs.fleetFollowers);
    _followersRaw = raw;
    if (raw.isEmpty) return;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return;
      for (final item in list) {
        final f = Follower.fromJson(item);
        if (f != null) _followers.add(f);
      }
    } catch (e) {
      log.warn(name, 'could not read the followers: $e');
    }
  }

  /// The lists the default exclusions used to be, for the upgrade at load;
  /// tests hand in a history of their own.
  @visibleForTesting
  List<Set<String>> formerDefaultExcluded = defs.fleetFormerDefaultExcluded;

  /// The profiles from their setting, the built-in Default synthesized when
  /// missing.
  Future<void> _loadProfiles() async {
    _profiles.clear();
    var changed = false;
    final raw = _settings.get(defs.fleetProfiles);
    _profilesRaw = raw;
    if (raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            var p = SyncProfile.parse(item);
            if (p == null || p.id.isEmpty || p.isUpdatesOnly) continue;
            // An exclusion list nobody touched follows the default as it
            // grows (the volumes joined it after the first profiles).
            final excluded = p.excluded;
            if (formerDefaultExcluded.any(
              (former) => setEquals(excluded, former),
            )) {
              p = p.copyWith(excluded: defs.fleetDefaultExcluded);
              changed = true;
            }
            // A default credential that joined after the profile was saved
            // travels where the old default still does (the intercom key
            // joined after the first profiles). Before profiles recorded
            // their default, an untouched list tells it.
            Set<String>? savedDefault;
            if (item is Map && item['credentialsDefault'] is List) {
              savedDefault = {
                for (final k in item['credentialsDefault'] as List) '$k',
              };
            } else {
              final own = p.credentials.difference(
                defs.fleetFormerCategoryCredentials.keys.toSet(),
              );
              for (final former in defs.fleetFormerDefaultCredentials) {
                if (setEquals(own, former)) savedDefault = former;
              }
            }
            if (savedDefault != null &&
                p.credentials.containsAll(savedDefault)) {
              final joined = defs.fleetDefaultCredentials.difference(
                savedDefault,
              );
              if (joined.isNotEmpty) {
                p = p.copyWith(credentials: {...p.credentials, ...joined});
                changed = true;
              }
            }
            // A credential its version did not offer traveled with its
            // category then, and still does.
            final offered = item is Map && item['credentialsOffered'] is List
                ? {for (final k in item['credentialsOffered'] as List) '$k'}
                : const <String>{};
            final added = defs.fleetFormerCategoryCredentials.entries.where(
              (e) => !offered.contains(e.key),
            );
            if (added.isNotEmpty) {
              p = p.copyWith(
                credentials: {
                  ...p.credentials,
                  for (final e in added)
                    if (p.categories.contains(e.value)) e.key,
                },
              );
              changed = true;
            }
            _profiles.add(p);
          }
        }
      } catch (e) {
        log.warn(name, 'could not read the profiles: $e');
      }
    }
    if (!_profiles.any((p) => p.isDefault)) {
      _profiles.insert(0, SyncProfile.initial);
      changed = true;
    }
    // Right after the Default, in code only: the setting never carries it,
    // so an edit cannot stick and an older version that reads the setting
    // does not meet a profile it would let the leader change.
    _profiles.insert(1, SyncProfile.updatesOnly);
    if (changed) await _saveProfiles();
  }

  Future<void> _saveProfiles() {
    _profilesRaw = jsonEncode([
      for (final p in _profiles)
        if (!p.isUpdatesOnly) p.toJson(),
    ]);
    return _settings.set(defs.fleetProfiles, _profilesRaw);
  }

  Future<void> _saveFollowers() {
    _followersRaw = _followers.isEmpty
        ? ''
        : jsonEncode([for (final f in _followers) f.toJson()]);
    return _settings.set(defs.fleetFollowers, _followersRaw);
  }

  /// A restored backup wrote the followers or the profiles: they are read
  /// back in, or the next save would put the copy from before the import
  /// over them (issue #1208).
  Future<void> _reloadImported(String key) async {
    if (key == defs.fleetFollowers.key) {
      if (_settings.get(defs.fleetFollowers) == _followersRaw) return;
      if (_ticking) {
        _followersStale = true;
        return;
      }
      _loadFollowers();
    } else {
      if (_settings.get(defs.fleetProfiles) == _profilesRaw) return;
      await _loadProfiles();
    }
    log.info(name, 'read the imported fleet settings');
    _publish();
    if (leading) _scheduleTick();
  }

  void _publish() => bus.publish(const FleetSyncChanged());

  /// This kiosk as the discovery announces it: the id the others know it
  /// by, its name and its version. Empty while discovery is off.
  Future<void> _readSelf() async {
    final r = await commands.execute('fleet', const {});
    final data = r.data;
    if (data is! Map) return;
    for (final d in (data['devices'] as List? ?? const [])) {
      if (d is Map && d['self'] == true) {
        _self = FleetDevice.directoryEntry(d);
        _selfId = '${d['id'] ?? ''}';
        _selfName = '${d['name'] ?? ''}';
        _selfVersion = '${d['version'] ?? ''}';
      }
    }
  }

  /// The kiosks heard on the network right now, by id (this one excluded).
  Future<Map<String, Map<String, Object?>>> _peers() async {
    final r = await commands.execute('fleet', const {});
    final data = r.data;
    final out = <String, Map<String, Object?>>{};
    if (data is! Map) return out;
    for (final d in (data['devices'] as List? ?? const [])) {
      if (d is! Map || d['self'] == true) continue;
      final m = d.cast<String, Object?>();
      out['${m['id'] ?? ''}'] = m;
    }
    return out;
  }

  // ── Settings changes ────────────────────────────────────────────────

  void _onSettingChanged(SettingChanged e) {
    if (e.key == defs.fleetLeader.key) {
      if (leading) {
        _scheduleTick();
      } else {
        unawaited(_disband());
      }
      _publish();
      return;
    }
    if (e.key == defs.fleetFollowers.key || e.key == defs.fleetProfiles.key) {
      unawaited(_reloadImported(e.key));
      return;
    }
    if (e.key.startsWith('fleet.')) return;
    final def = _settings.defByKey(e.key);
    if (def == null || def.perDevice) return;
    if (_pluginScreensaverSetting(e.key, e.previous) ||
        _pluginScreensaverSetting(e.key, e.value)) {
      return;
    }
    if (_containsPluginReferences(e.key) &&
        _sameValue(
          _fleetValue(e.key, e.previous),
          _fleetValue(e.key, e.value),
        )) {
      return;
    }
    // A leader: what the followers get changed, tell them (after the burst
    // a slider or an import makes has settled).
    if (leading) {
      _bump?.cancel();
      _bump = Timer(const Duration(seconds: 2), _scheduleTick);
    }
    // A follower: a synced setting changed here, not by the leader (the
    // import flag holds through a push), so this kiosk has drifted until
    // the leader pushes again.
    if (following &&
        !_settings.importing &&
        syncedKeys.contains(e.key) &&
        _settings.get(defs.fleetAppliedRevision).isNotEmpty) {
      unawaited(_settings.set(defs.fleetAppliedRevision, ''));
    }
  }

  /// What a follower should hold right now, as one short string: a hash
  /// of every value its profile allows. A follower is pushed while the
  /// revision it applied differs, so a change reaches only the followers
  /// whose payload it touched, not the whole fleet.
  String fingerprintFor(Follower f) {
    final profile = profileFor(f);
    final settings = profileSettings(profile);
    // A profile without plugins hashes as it always did, so adding the
    // feature pushes nothing new to those followers.
    if (profile.plugins.isEmpty) return fingerprintOf(settings);
    return fingerprintOf({
      ...settings,
      '\u0000plugins': _canonical(profilePlugins(profile)),
    });
  }

  static String fingerprintOf(Map<String, Object?> settings) {
    final sorted = SplayTreeMap<String, Object?>.from(settings);
    return md5.convert(utf8.encode(jsonEncode(sorted))).toString();
  }

  /// Leading switched off: the followers are told and forgotten. A
  /// follower that cannot be reached forgets the leader on its own the
  /// next time it is asked (its token no longer names a leader here).
  Future<void> _disband() async {
    final gone = _followers.toList();
    _followers.clear();
    await _saveFollowers();
    for (final f in gone) {
      if (f.token != null) {
        unawaited(_post('${f.url}/api/fleet/leave', {}, token: f.token));
      }
    }
    if (gone.isNotEmpty) {
      log.info(name, 'stopped leading ${gone.length} kiosks');
    }
  }

  // ── The leader's loop ───────────────────────────────────────────────

  void _onTimer() {
    _ticks++;
    if (!leading) return;
    final watched = _remoteObserved || DateTime.now().isBefore(_watchedUntil);
    if (watched || _ticks % 10 == 0) unawaited(_tick());
  }

  void _scheduleTick() {
    // Off the caller's stack: a settings listener must not block on the
    // network and two triggers in a row share one tick.
    Future<void>.delayed(const Duration(milliseconds: 200), _tick);
  }

  Future<void> _tick({String? only, bool force = false}) async {
    if (!leading || !enabled || _ticking) return;
    _ticking = true;
    try {
      await _readSelf();
      await _readPlugins();
      final peers = await _peers();
      final before = jsonEncode([for (final f in _followers) f.toJson()]);
      var changed = false;
      // The leader's custom wake word models, read once per tick. Null when
      // they could not be read: a failed read must never look like an empty
      // set, which would clear every follower's models.
      Map<String, String>? models;
      var modelsRead = false;
      for (final f in _followers) {
        if (only != null && f.id != only) continue;
        final peer = peers[f.id];
        if (peer != null) {
          final address = '${peer['address'] ?? f.address}';
          final port = (peer['port'] as num?)?.toInt() ?? f.port;
          final version = '${peer['version'] ?? f.version}';
          final peerName = '${peer['name'] ?? f.name}';
          final tls = peer['tls'] == true;
          final dnsName = '${peer['dnsName'] ?? ''}';
          final adminUrl = '${peer['adminUrl'] ?? ''}';
          if (tls != f.tls ||
              dnsName != f.dnsName ||
              adminUrl != f.adminUrl ||
              address != f.address ||
              port != f.port ||
              version != f.version ||
              peerName != f.name) {
            f
              ..tls = tls
              ..dnsName = dnsName
              ..adminUrl = adminUrl
              ..address = address
              ..port = port
              ..version = version
              ..name = peerName;
            changed = true;
          }
        }
        // Membership survives missing multicast. Try the saved endpoint
        // and let its answer determine whether this follower is online.
        if (f.invite != null) {
          changed = await _pollInvite(f) || changed;
          continue;
        }
        if (f.token == null) continue;
        await _pollStatus(f);
        if (f.error != null || f.token == null) {
          changed = true;
          continue;
        }
        if (_versionName(f.version) != _versionName(_selfVersion)) {
          await _maybeAutoUpdate(f);
          continue;
        }
        if (force || f.dirty || f.appliedRevision != fingerprintFor(f)) {
          changed = await _push(f, force: force) || changed;
        }
        if (f.error == null && f.token != null) {
          if (!modelsRead) {
            models = await _wakeModels();
            modelsRead = true;
          }
          if (models != null) {
            changed = await _syncWakeModels(f, models) || changed;
          }
        }
      }
      if (!_followersStale &&
          (changed ||
              before != jsonEncode([for (final f in _followers) f.toJson()]))) {
        await _saveFollowers();
      }
      await _shareRoster();
    } finally {
      _ticking = false;
      if (_followersStale) {
        _followersStale = false;
        _loadFollowers();
        log.info(name, 'read the imported fleet settings');
        if (leading) _scheduleTick();
      }
      _publish();
    }
  }

  Future<bool> _pollInvite(Follower f) async {
    final res = await _get('${f.url}/api/fleet/invite/${f.invite}');
    final body = _jsonOf(res);
    if (res?.statusCode != 200 || body == null) {
      f.online = false;
      return false;
    }
    f.online = true;
    switch (body['status']) {
      case 'accepted':
        final token = body['token'];
        if (token is! String || token.isEmpty) return false;
        f
          ..token = token
          ..invite = null
          ..declined = false
          ..appliedRevision = null;
        log.info(name, '${f.name} joined the fleet');
        // Straight on to the first push: the kiosk just said yes.
        await _pollStatus(f);
        if (f.error == null &&
            _versionName(f.version) == _versionName(_selfVersion)) {
          await _push(f);
        }
        return true;
      case 'declined':
        f
          ..invite = null
          ..declined = true;
        log.info(name, '${f.name} declined the invitation');
        return true;
      case 'unknown':
        // The kiosk forgot the invitation (a restart past its day or a
        // newer one replaced it): waiting is over.
        f
          ..invite = null
          ..declined = true;
        return true;
    }
    return false;
  }

  Future<void> _pollStatus(Follower f) async {
    f.online = false;
    f.rosterRevision = null;
    final res = await _get('${f.url}/api/fleet/status', token: f.token);
    if (res == null) {
      f.error = 'Unreachable';
      return;
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      // The kiosk no longer honors the token: it left or another leader
      // has it now.
      f
        ..token = null
        ..error = null;
      log.info(name, '${f.name} no longer follows this kiosk');
      return;
    }
    final body = _jsonOf(res);
    if (res.statusCode != 200 || body == null) {
      f.error = 'Bad answer';
      return;
    }
    // A saved address can be reassigned to another kiosk by DHCP.
    if (body['id'] != f.id || body['leaderId'] != _selfId) {
      f.error = 'The address belongs to a different kiosk or fleet';
      return;
    }
    f
      ..error = null
      ..online = true
      ..rosterRevision = body['rosterRevision'] is String
          ? body['rosterRevision'] as String
          : null
      ..version = '${body['version'] ?? f.version}'
      ..appliedRevision = body['appliedRevision'] as String?
      ..dirty = body['dirty'] == true
      ..update = (body['update'] as Map?)?.cast<String, Object?>()
      ..pluginHashes = {
        for (final e in ((body['plugins'] as Map?) ?? const {}).entries)
          '${e.key}': '${e.value}',
      }
      ..pluginErrors = _jsonMap(jsonEncode(body['pluginErrors'] ?? const {}));
    final peerName = body['name'];
    if (peerName is String && peerName.isNotEmpty) f.name = peerName;
  }

  /// Send membership independently of settings and version compatibility.
  /// A status response advertises support and acknowledges the stored list.
  Future<void> _shareRoster() async {
    if (!leading || _self == null) return;
    final members = [
      _self!,
      for (final f in _followers)
        if (f.token != null && f.invite == null && !f.declined)
          FleetDevice(
            id: f.id,
            name: f.name,
            version: f.version,
            address: f.address,
            port: f.port,
            tls: f.tls,
            dnsName: f.dnsName,
            adminUrl: f.adminUrl,
          ),
    ]..sort((a, b) => a.id.compareTo(b.id));
    final devices = [for (final member in members) member.toDirectory()];
    final revision = _rosterRevision(jsonEncode(devices));
    for (final f in _followers.toList()) {
      if (!leading) return;
      if (f.token == null ||
          !f.online ||
          f.rosterRevision == null ||
          f.rosterRevision == revision) {
        continue;
      }
      final response = await _post('${f.url}/api/fleet/roster', {
        'devices': devices,
      }, token: f.token);
      final body = _jsonOf(response);
      if (response?.statusCode == 200 && body?['ok'] == true) {
        f.rosterRevision = revision;
      }
    }
  }

  static String _rosterRevision(String roster) =>
      roster.isEmpty ? '' : md5.convert(utf8.encode(roster)).toString();

  Future<String?> receiveRoster(Map<String, Object?> p) async {
    if (!following) return 'This kiosk follows nobody';
    final raw = p['devices'];
    if (raw is! List) return 'devices must be a list';
    final members = <String, FleetDevice>{};
    for (final item in raw) {
      final member = FleetDevice.directoryEntry(item);
      if (member == null || members.containsKey(member.id)) {
        return 'Invalid fleet member';
      }
      members[member.id] = member;
    }
    final currentLeader = leader!;
    final updatedLeader = members[currentLeader['id']];
    if (updatedLeader == null) {
      return 'The roster must include this kiosk\'s leader';
    }
    final sorted = members.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final roster = jsonEncode([
      for (final member in sorted) member.toDirectory(),
    ]);
    final leaderInfo = jsonEncode(updatedLeader.toDirectory());
    if (_settings.get(defs.fleetLeaderInfo) != leaderInfo) {
      await _settings.set(defs.fleetLeaderInfo, leaderInfo);
    }
    if (_settings.get(defs.fleetRoster) != roster) {
      await _settings.set(defs.fleetRoster, roster);
    }
    return null;
  }

  /// Push a follower everything its list allows. The full set every time,
  /// not a delta: a few hundred values, idempotent and the follower skips
  /// what it already holds.
  Future<bool> _push(Follower f, {bool force = false}) async {
    final profile = profileFor(f);
    // Without the plugin listing a push would read as "no plugins" and
    // remove them on the follower: wait for the next tick.
    if (profile.plugins.isNotEmpty && plugins != null && !_pluginsKnown) {
      return false;
    }
    final settings = profileSettings(profile);
    final revision = fingerprintFor(f);
    final wanted = profilePlugins(profile);
    await _sendPackages(f, wanted, force: force);
    final res = await _post('${f.url}/api/fleet/apply', {
      'revision': revision,
      'version': _selfVersion,
      'settings': settings,
      'plugins': wanted,
    }, token: f.token);
    final body = _jsonOf(res);
    if (res == null || body == null) {
      f.error = 'Unreachable';
      return false;
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      f.token = null;
      return true;
    }
    final data = body['data'];
    if (body['ok'] != true || data is! Map) {
      f.error = '${body['error'] ?? 'The push failed'}';
      return false;
    }
    if (data['held'] != null) {
      // Refused for the version: the poll already knows, nothing to keep.
      f.version = '${data['version'] ?? f.version}';
      return false;
    }
    f
      ..appliedRevision = revision
      ..dirty = false
      ..error = null
      ..lastSyncAt = DateTime.now().millisecondsSinceEpoch;
    if (data['pluginErrors'] is Map) {
      f.pluginErrors = _jsonMap(jsonEncode(data['pluginErrors']));
    }
    final applied = (data['applied'] as num?)?.toInt() ?? 0;
    log.info(
      name,
      'synced ${settings.length} settings to ${f.name} '
      '($applied changed)',
    );
    return true;
  }

  /// Sends a follower the plugin packages its profile carries that it does
  /// not run yet, ahead of the push that installs them. A package the
  /// follower failed to install, or this kiosk failed to send, is not sent
  /// again until its hash changes or someone asks for a sync.
  Future<void> _sendPackages(
    Follower f,
    List<Map<String, Object?>> wanted, {
    bool force = false,
  }) async {
    final host = plugins;
    if (host == null) return;
    if (force) f.packageErrors.clear();
    for (final p in wanted) {
      final id = '${p['id']}';
      final hash = '${p['sha256']}';
      final title = '${p['name']}';
      if (f.pluginHashes[id] == hash) continue;
      if (!force &&
          (f.packageErrors[id]?.$1 == hash ||
              (f.pluginErrors[id]?['sha256'] == hash &&
                  f.pluginErrors[id]?['message'] != _notArrived))) {
        continue;
      }
      String? path;
      try {
        path = await host.fleetPackage(id);
      } catch (e) {
        log.warn(name, 'cannot read the package of $id: $e');
      }
      if (path == null) {
        f.packageErrors[id] = (hash, title);
        log.warn(name, '$title cannot be passed on: no package here');
        continue;
      }
      final sent = await _upload(
        '${f.url}/api/fleet/plugins?sha256=$hash',
        File(path),
        token: f.token,
        method: 'PUT',
        contentType: 'application/zip',
      );
      if (sent?.statusCode == 200) {
        f.packageErrors.remove(id);
      } else {
        log.warn(
          name,
          'could not send $title to ${f.name} (${sent?.statusCode})',
        );
      }
    }
    f.packageErrors.removeWhere(
      (id, e) => !wanted.any((p) => p['id'] == id && p['sha256'] == e.$1),
    );
  }

  /// Why a follower lists a plugin it could not install: its package never
  /// came. The leader sends it again.
  static const _notArrived = 'The package did not arrive';

  /// Lists the leader's plugins again. A failed listing keeps the last one.
  Future<void> _readPlugins() async {
    final host = plugins;
    if (host == null) return;
    try {
      _pluginState = await host.fleetState();
      _pluginsKnown = true;
    } catch (e) {
      log.debug(name, 'could not list the plugins: $e');
    }
  }

  /// A plugin was installed, changed or removed here. A leader passes it
  /// on, a follower checks it still holds what the leader sent.
  Future<void> _onPluginsChanged() async {
    if (plugins == null) return;
    if (leading) {
      await _readPlugins();
      _bump?.cancel();
      _bump = Timer(const Duration(seconds: 2), _scheduleTick);
    }
    if (following && !_applyingPlugins) await _checkPluginDrift();
  }

  /// A follower whose synced plugins changed here (not by the leader) has
  /// drifted until the leader pushes again, as with a synced setting.
  Future<void> _checkPluginDrift() async {
    final synced = syncedPlugins;
    if (synced.isEmpty ||
        _settings.get(defs.fleetAppliedRevision).isEmpty ||
        plugins == null) {
      return;
    }
    final List<Map<String, Object?>> state;
    try {
      state = await plugins!.fleetState();
    } catch (_) {
      return;
    }
    if (_applyingPlugins) return;
    final errors = pluginErrors;
    for (final e in synced.entries) {
      // A plugin that failed here differs on purpose: the error says so.
      if (errors.containsKey(e.key)) continue;
      final mine = state.where((p) => p['id'] == e.key).firstOrNull;
      if (mine == null ||
          pluginFingerprint(mine, secrets: e.value['secrets'] == true) !=
              e.value['fp']) {
        await _settings.set(defs.fleetAppliedRevision, '');
        _publish();
        return;
      }
    }
  }

  /// What the leader sends for each of a profile's plugins, by id order:
  /// the package by hash and where it came from, whether it runs, its
  /// settings (the secret ones only when the profile includes plugin
  /// secrets) and where its actions show.
  List<Map<String, Object?>> profilePlugins(SyncProfile profile) {
    if (profile.plugins.isEmpty) return const [];
    final secrets = profile.credentials.contains(defs.fleetPluginSecrets);
    return [
      for (final p in _pluginState)
        if (profile.plugins.contains(p['id'])) pluginEntry(p, secrets: secrets),
    ]..sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
  }

  /// One plugin as the fleet carries it, from the runtime's listing.
  static Map<String, Object?> pluginEntry(
    Map<String, Object?> p, {
    required bool secrets,
  }) {
    final secretKeys = {for (final k in (p['secretKeys'] as List?) ?? []) '$k'};
    final config = (p['config'] as Map?) ?? const {};
    return {
      'id': p['id'],
      'name': p['name'],
      'version': p['version'],
      'sha256': p['sha256'],
      'source': p['source'],
      'enabled': p['enabled'] == true,
      'secrets': secrets,
      'config': {
        for (final e in config.entries)
          if (secrets || !secretKeys.contains('${e.key}')) '${e.key}': e.value,
      },
      'actionOptions': p['actionOptions'] ?? const {},
    };
  }

  /// What a follower compares to tell its own change from the leader's:
  /// the package, whether it runs, the settings the leader sent and the
  /// action placements.
  static String pluginFingerprint(
    Map<String, Object?> p, {
    required bool secrets,
  }) {
    final entry = pluginEntry(p, secrets: secrets);
    return fingerprintOf(
      _canonical({
            'sha256': entry['sha256'],
            'enabled': entry['enabled'],
            'config': entry['config'],
            'actionOptions': entry['actionOptions'],
          })
          as Map<String, Object?>,
    );
  }

  /// Maps sorted by key all the way down, so two kiosks hash the same
  /// values the same whatever order they were listed in.
  static Object? _canonical(Object? value) => switch (value) {
    final Map m => SplayTreeMap<String, Object?>.from({
      for (final e in m.entries) '${e.key}': _canonical(e.value),
    }),
    final List l => [for (final v in l) _canonical(v)],
    _ => value,
  };

  /// The leader's custom wake word files with their SHA-256, by
  /// `folder/name`.
  Future<Map<String, String>?> _wakeModels() async {
    final r = await commands.execute('customWakeModelsManifest', const {});
    final files = r.ok && r.data is Map ? (r.data as Map)['files'] : null;
    return files is Map
        ? {for (final e in files.entries) '${e.key}': '${e.value}'}
        : null;
  }

  /// Followers mirror the leader's custom wake word models while their
  /// profile syncs Voice Satellite: what is missing or different is sent,
  /// what the leader does not have is removed. Compared by hash, so an
  /// unchanged set costs one request per follower until the leader's
  /// changes, and a follower that was away catches up on its next tick.
  Future<bool> _syncWakeModels(Follower f, Map<String, String> mine) async {
    if (!profileFor(f).categories.contains('Voice Satellite')) return false;
    final revision = fingerprintOf(mine);
    if (f.wakeModelsRevision == revision) return false;
    final res = await _get('${f.url}/api/fleet/wake-models', token: f.token);
    final body = _jsonOf(res);
    final data = body?['data'];
    // A follower without the route runs an older build: its version check
    // holds it anyway until it updates.
    if (res?.statusCode != 200 || data is! Map || data['files'] is! Map) {
      return false;
    }
    final theirs = {
      for (final e in (data['files'] as Map).entries) '${e.key}': '${e.value}',
    };
    for (final e in mine.entries) {
      if (theirs[e.key] == e.value) continue;
      final path = await commands.execute('customWakeModelPath', {
        'path': e.key,
      });
      final local = path.ok && path.data is Map
          ? (path.data as Map)['path']
          : null;
      if (local is! String) continue;
      final sent = await _upload(
        '${f.url}/api/fleet/wake-models?path=${Uri.encodeQueryComponent(e.key)}',
        File(local),
        token: f.token,
        method: 'PUT',
        contentType: 'application/octet-stream',
      );
      if (sent?.statusCode != 200) {
        f.error = 'Could not send the wake word model ${e.key.split('/').last}';
        log.warn(name, '${f.name}: ${f.error} (${sent?.statusCode})');
        return true;
      }
    }
    for (final path in theirs.keys) {
      if (mine.containsKey(path)) continue;
      await _delete(
        '${f.url}/api/fleet/wake-models?path=${Uri.encodeQueryComponent(path)}',
        token: f.token,
      );
    }
    f.wakeModelsRevision = revision;
    log.info(
      name,
      'wake word models in step on ${f.name} (${mine.length} files)',
    );
    return false;
  }

  Future<void> _delete(String url, {String? token}) async {
    final client = clientFactory();
    try {
      await client
          .delete(
            Uri.parse(url),
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          )
          .timeout(requestTimeout);
    } catch (e) {
      log.debug(name, 'DELETE $url: $e');
    } finally {
      client.close();
    }
  }

  /// Keep followers on this version: a follower behind this kiosk that is
  /// offered exactly this release installs it, once per release.
  Future<void> _maybeAutoUpdate(Follower f) async {
    if (!_settings.get(defs.fleetAutoUpdate)) return;
    if (!isNewer(_selfVersion, f.version)) return;
    final offered = '${f.update?['availableVersion'] ?? ''}';
    if (offered.isEmpty ||
        _versionName(offered) != _versionName(_selfVersion)) {
      return;
    }
    if (f.update?['progress'] != null) return;
    if (_autoUpdated[f.id] == offered) return;
    _autoUpdated[f.id] = offered;
    log.info(name, 'updating ${f.name} to $offered');
    await _post('${f.url}/api/commands/installUpdate', {}, token: f.token);
  }

  // ── The profile ─────────────────────────────────────────────────────

  /// The values a profile pushes: every setting in one of its categories
  /// except what stays per kiosk, the credentials unless included, the
  /// dashboard unless included.
  Map<String, Object?> profileSettings(SyncProfile profile) {
    final out = <String, Object?>{};
    for (final def in defs.allSettings) {
      if (!syncs(def, profile) ||
          _pluginScreensaverSetting(def.key, _settings.get(def))) {
        continue;
      }
      out[def.key] = _fleetValue(def.key, _settings.get(def));
    }
    return out;
  }

  /// Whether one setting travels under [profile].
  static bool syncs(defs.SettingDef<Object> def, SyncProfile profile) {
    // A link holds no value of its own; its target travels instead.
    if (def.perDevice || def.linksTo != null) return false;
    final lead = defs.fleetFollowsKey[def.key];
    if (lead != null) {
      final leadDef = defs.allSettings.where((d) => d.key == lead).first;
      return syncs(leadDef, profile);
    }
    if (profile.excluded.contains(def.key)) return false;
    if (defs.fleetCredentialKeys.contains(def.key)) {
      return profile.credentials.contains(def.key);
    }
    if (defs.fleetDashboardKeys.contains(def.key)) return profile.dashboard;
    return profile.categories.contains(defs.fleetCategoryOf(def));
  }

  /// The follower's own filter over what a leader sent: what stays per
  /// kiosk stays, whatever the leader thought and a key this version does
  /// not know is dropped rather than stored blind.
  static Map<String, Object?> acceptable(Map<String, Object?> incoming) {
    final byKey = {for (final d in defs.allSettings) d.key: d};
    return {
      for (final e in incoming.entries)
        if (byKey[e.key] case final def?
            when !def.perDevice &&
                !_pluginScreensaverSetting(e.key, e.value) &&
                (!_containsPluginReferences(e.key) || e.value is String) &&
                (e.key != defs.esphomeExcludedEntities.key ||
                    defs.esphomeExcludedEntities.validator!(e.value) == null))
          e.key: _fleetValue(e.key, e.value),
    };
  }

  /// Renderer choices and schedules containing them are local to the kiosk.
  static bool _pluginScreensaverSetting(String key, Object? value) {
    if (key == defs.screensaverMode.key) return defs.isPluginScreensaver(value);
    if (key != defs.screensaverSchedule.key || value is! String) return false;
    try {
      final entries = jsonDecode(value);
      return entries is List &&
          entries.whereType<Map>().any(
            (e) => defs.isPluginScreensaver(e['mode']),
          );
    } catch (_) {
      return false;
    }
  }

  static bool _containsPluginReferences(String key) =>
      key == defs.gestureMappings.key ||
      key == defs.esphomeExcludedEntities.key;

  /// Plugin gesture assignments and entity exclusions stay on their kiosk.
  static Object? _fleetValue(String key, Object? value) {
    if (key == defs.esphomeExcludedEntities.key) {
      final ids =
          defs
              .decodeEspHomeExcludedEntities(value is String ? value : '')
              .where((id) => !id.startsWith('plugin_'))
              .toList()
            ..sort();
      return jsonEncode(ids);
    }
    if (key != defs.gestureMappings.key) return value;
    return jsonEncode([
      for (final mapping in decodeGestureMappings(value is String ? value : ''))
        if (!mapping.usesPlugin) mapping.toJson(),
    ]);
  }

  String _preservePluginEntityExclusions(Object? incoming) {
    final local = defs
        .decodeEspHomeExcludedEntities(
          _settings.get(defs.esphomeExcludedEntities),
        )
        .where((id) => id.startsWith('plugin_'));
    final ids = {
      ...defs.decodeEspHomeExcludedEntities(incoming as String),
      ...local,
    }.toList()..sort();
    return jsonEncode(ids);
  }

  String _preservePluginGestures(Object? incoming) {
    final local = decodeGestureMappings(
      _settings.get(defs.gestureMappings),
    ).where((mapping) => mapping.usesPlugin).toList();
    final localIds = {for (final mapping in local) mapping.id};
    return jsonEncode([
      for (final mapping in decodeGestureMappings(incoming as String))
        if (!localIds.contains(mapping.id)) mapping.toJson(),
      for (final mapping in local) mapping.toJson(),
    ]);
  }

  // ── Commands ────────────────────────────────────────────────────────

  void _register() {
    commands
      ..register(
        Command(
          name: 'fleetStatus',
          description:
              "This kiosk's place in its fleet: whether it leads, its "
              'followers with their state, the fleet default, the leader '
              'it follows and the invitation waiting on it. Both UIs draw '
              'the Fleet Management page from this.',
          quiet: true,
          handler: (_) async {
            _watchedUntil = DateTime.now().add(const Duration(seconds: 90));
            await _readSelf();
            return CommandResult.ok(status());
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetCandidates',
          description:
              'The kiosks on the network this one could invite: not itself, '
              'not a follower already, with whether each follows another '
              'leader (asked from the kiosk itself).',
          quiet: true,
          handler: (_) async => CommandResult.ok(await candidates()),
        ),
      )
      ..register(
        Command(
          name: 'fleetLookup',
          description: 'Find a kiosk by IP address before inviting it.',
          params: const {
            'address': 'The kiosk IP address',
            'port': 'Its remote admin port, default 2324',
          },
          handler: (p) async {
            final (error, kiosk) = await lookupKiosk(p['address'], p['port']);
            return error == null
                ? CommandResult.ok(kiosk)
                : CommandResult.fail(error);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetInvite',
          description:
              'Invite a discovered kiosk or one found by IP address. The '
              'invitation waits on that kiosk until it is accepted on its '
              'screen or in its remote admin. Nothing syncs before that.',
          params: const {
            'id': 'The kiosk id, from fleetCandidates or fleetLookup',
            'address':
                'The IP address returned by fleetLookup, if entered manually',
            'port': 'Its remote admin port, default 2324',
            'profile': 'The profile id it gets or omitted for the Default',
          },
          handler: (p) async {
            final r = await inviteKiosk(
              '${p['id'] ?? ''}',
              p['profile'] as String?,
              address: p['address'],
              port: p['port'],
            );
            return r == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(r);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetSetProfile',
          description:
              'Add a profile or change one (the Default included). Answers '
              'the profile id.',
          params: const {
            'profile':
                '{id, name, categories, credentials, dashboard, excluded}; '
                'no id adds a new one',
          },
          handler: (p) async {
            final r = await setProfile(p['profile']);
            return r.$1 == null
                ? CommandResult.ok(r.$2)
                : CommandResult.fail(r.$1!);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetDeleteProfile',
          description:
              'Delete a profile. Followers on it get the Default. The '
              'Default itself stays.',
          params: const {'id': 'The profile id'},
          handler: (p) async {
            final r = await deleteProfile('${p['id'] ?? ''}');
            return r == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(r);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetAssignProfile',
          description: 'Hand a follower a profile.',
          params: const {
            'id': 'The follower',
            'profile': 'The profile id or omitted for the Default',
          },
          handler: (p) async {
            final r = await assignProfile(
              '${p['id'] ?? ''}',
              p['profile'] as String?,
            );
            return r == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(r);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetSyncable',
          description:
              'Every setting a profile can exclude: the ones that travel '
              'with a category, each with its title and page.',
          quiet: true,
          handler: (_) async => CommandResult.ok(syncable()),
        ),
      )
      ..register(
        Command(
          name: 'fleetRemove',
          description: 'Remove a follower. The kiosk keeps its settings.',
          params: const {'id': 'The follower'},
          handler: (p) async {
            final r = await removeFollower('${p['id'] ?? ''}');
            return r == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(r);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetSyncNow',
          description:
              'Push the settings to one follower or to every follower '
              'without an id, whether or not anything changed.',
          params: const {'id': 'The follower or omitted for all'},
          handler: (p) async {
            if (!leading) return const CommandResult.fail('not leading');
            final id = '${p['id'] ?? ''}';
            await _tick(only: id.isEmpty ? null : id, force: true);
            return const CommandResult.ok(true);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetUpdate',
          description:
              'Install the release offered to each follower behind this '
              'kiosk, then to this kiosk. Followers first so this one stays '
              'up to drive it.',
          params: const {'id': 'One follower or omitted for the fleet'},
          handler: (p) async =>
              CommandResult.ok(await updateFleet('${p['id'] ?? ''}')),
        ),
      )
      ..register(
        Command(
          name: 'fleetExport',
          description:
              'The full configuration of this kiosk and each follower, '
              'secrets included, as one backup. A follower that does not '
              'answer is listed with the reason.',
          handler: (_) async => CommandResult.ok(await exportFleet()),
        ),
      )
      ..register(
        Command(
          name: 'fleetInstallUploaded',
          description:
              'Push the APK uploaded to this kiosk (POST /api/update/upload) '
              'to each follower and install it there, then install it here. '
              'Followers first so this one stays up to drive it',
          params: const {'id': 'One follower or omitted for the fleet'},
          handler: (p) async {
            final out = await installUploadedOnFleet('${p['id'] ?? ''}');
            final error = out['error'];
            return error is String
                ? CommandResult.fail(error)
                : CommandResult.ok(out);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetAccept',
          description:
              'Accept the invitation waiting on this kiosk, from its '
              'screen or the remote admin.',
          handler: (_) async {
            final r = await accept();
            return r == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(r);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetDecline',
          description:
              'Decline the invitation waiting on this kiosk, from its '
              'screen or the remote admin.',
          handler: (_) async {
            await decline();
            return const CommandResult.ok(true);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetLeave',
          description:
              'Stop following the leader. Settings stay as they are; the '
              "leader's token stops working here.",
          handler: (_) async {
            await leave();
            return const CommandResult.ok(true);
          },
        ),
      )
      // The follower's side of the wire, called by the remote server for
      // the fleet endpoints. Nothing here needs the device screen.
      ..register(
        Command(
          name: 'fleetIdentity',
          description:
              'Who this kiosk is to another kiosk: id, name, version, '
              'whether it leads and whom it follows.',
          quiet: true,
          handler: (_) async {
            await _readSelf();
            return CommandResult.ok({
              'id': _selfId,
              'name': _selfName,
              'version': _selfVersion,
              'leader': leading,
              'follows': leader?['name'],
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetInviteReceived',
          description:
              'An invitation from a leader on the network landed here (the '
              'remote server relays it). Checked against the leader itself, '
              'then shown on the screen.',
          params: const {
            'invite': 'The nonce the leader polls with',
            'leader': '{id, name, version, port}',
            'address': "The leader's address, as the request came from",
          },
          handler: (p) async {
            final r = await receiveInvite(p);
            return r.$1 == null
                ? CommandResult.ok(r.$2)
                : CommandResult.fail(r.$1!);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetInvitePoll',
          description:
              'What became of an invitation: pending, accepted (with the '
              'fleet token, handed out once), declined or unknown.',
          params: const {'invite': 'The nonce'},
          quiet: true,
          handler: (p) async =>
              CommandResult.ok(await pollInvite('${p['invite'] ?? ''}')),
        ),
      )
      ..register(
        Command(
          name: 'fleetFollowerStatus',
          description:
              'What the leader polls: version, the revision applied, '
              'whether a synced setting changed here since, the update '
              'state.',
          quiet: true,
          handler: (_) async => CommandResult.ok(await followerStatus()),
        ),
      )
      ..register(
        Command(
          name: 'fleetApply',
          description:
              "The leader's push: apply the settings it sent, unless the "
              'versions differ. What stays per kiosk is dropped here again '
              'whatever was sent.',
          params: const {
            'revision': "The leader's revision",
            'version': "The leader's version",
            'settings': '{key: value}',
            'plugins': 'The plugins it syncs here, each with its settings',
          },
          secretParams: const {'settings', 'plugins'},
          handler: (p) async {
            final r = await apply(p);
            return r.$1 == null
                ? CommandResult.ok(r.$2)
                : CommandResult.fail(r.$1!);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetStagePlugin',
          description:
              'A plugin package from the leader, the raw body, held until '
              'the push that installs it.',
          params: const {'sha256': 'The package SHA-256', 'stream': 'the body'},
          quiet: true,
          handler: (p) async {
            final error = await stagePlugin(
              '${p['sha256'] ?? ''}',
              p['stream'],
              (p['length'] as num?)?.toInt(),
            );
            return error == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(error);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetRosterReceived',
          description:
              'Store the member directory sent by this kiosk\'s leader.',
          params: const {'devices': 'Fleet members and their admin addresses'},
          handler: (p) async {
            final error = await receiveRoster(p);
            return error == null
                ? const CommandResult.ok(true)
                : CommandResult.fail(error);
          },
        ),
      )
      ..register(
        Command(
          name: 'fleetLeaderLeft',
          description: 'The leader removed this kiosk: forget it.',
          handler: (_) async {
            if (following) {
              log.info(name, '${leader?['name']} stopped leading this kiosk');
              await _forgetLeader();
            }
            return const CommandResult.ok(true);
          },
        ),
      );
  }

  // ── The leader's actions ────────────────────────────────────────────

  Follower? _follower(String id) =>
      _followers.where((f) => f.id == id).firstOrNull;

  Future<List<Map<String, Object?>>> candidates() async {
    final peers = await _peers();
    final taken = {for (final f in _followers) f.id};
    final out = <Map<String, Object?>>[];
    await Future.wait([
      for (final e in peers.entries)
        if (!taken.contains(e.key))
          () async {
            final p = e.value;
            final url = Uri(
              scheme: p['tls'] == true ? 'https' : 'http',
              host: '${p['address']}',
              port: (p['port'] as num).toInt(),
            ).toString();
            // The status matters: a build without the endpoint answers
            // its login gate with a JSON body of its own.
            final probe = await _get('$url/api/fleet/identity');
            final identity = probe != null && probe.statusCode == 200
                ? _jsonOf(probe)
                : null;
            out.add({
              'id': e.key,
              'name': p['name'],
              'address': p['address'],
              'port': p['port'],
              if (p['tls'] == true) 'tls': true,
              'version': p['version'],
              'follows': identity?['follows'],
              'leader': identity?['leader'] == true,
              // A build from before Fleet Management answers the login
              // gate instead; the same version name can hide that.
              'supported': identity != null,
            });
          }(),
    ]);
    out.sort(
      (a, b) =>
          '${a['name']}'.toLowerCase().compareTo('${b['name']}'.toLowerCase()),
    );
    return out;
  }

  /// Resolve a manual address without sending an invitation or saving a member.
  Future<(String?, Map<String, Object?>?)> lookupKiosk(
    Object? address,
    Object? port, {
    String? expectedId,
    bool allowExisting = false,
  }) async {
    if (!leading) return ('Lead this fleet is off', null);
    if (!enabled) {
      return ('The remote admin and Find other kiosks must be on', null);
    }
    final ip = address is String
        ? InternetAddress.tryParse(address.trim())
        : null;
    if (ip == null) return ('Enter a valid IP address.', null);
    final number = port == null
        ? 2324
        : port is int
        ? port
        : port is String
        ? int.tryParse(port.trim())
        : null;
    if (number == null || number < 1 || number > 65535) {
      return ('Enter a port from 1 to 65535.', null);
    }
    await _readSelf();
    if (_selfId.isEmpty) {
      return ('This kiosk identity is not ready yet. Try again.', null);
    }
    final discovered = (await _peers()).values
        .where((p) => p['address'] == ip.address && p['port'] == number)
        .firstOrNull;
    var secure = discovered?['tls'] == true;
    final url = Uri(
      scheme: secure ? 'https' : 'http',
      host: ip.address,
      port: number,
    );
    var probe = await _get('$url/api/fleet/identity');
    // Manual lookup can reach an encrypted kiosk before discovery sees it.
    // Only this public identity probe retries with a different protocol.
    if (probe == null && !secure) {
      probe = await _get('${url.replace(scheme: 'https')}/api/fleet/identity');
      secure = probe != null;
    }
    if (probe == null) return ('That kiosk did not answer', null);
    if (probe.statusCode != 200) {
      return (
        'That kiosk runs a build without Fleet Management. It joins once it runs one.',
        null,
      );
    }
    final identity = _jsonOf(probe);
    final id = identity?['id'];
    if (id is! String ||
        id.isEmpty ||
        identity?['name'] is! String ||
        identity?['version'] is! String ||
        identity?['leader'] is! bool) {
      return ('That address did not return a valid kiosk identity.', null);
    }
    if (id == _selfId) return ('Pick another kiosk', null);
    if (expectedId != null && id != expectedId) {
      return ('The address belongs to a different kiosk or fleet', null);
    }
    final existing = _follower(id);
    if (!allowExisting &&
        existing != null &&
        (existing.token != null || existing.invite != null)) {
      return ('This kiosk already belongs to this fleet.', null);
    }
    if (identity!['leader'] == true) return ('That kiosk leads a fleet.', null);
    if (identity['follows'] != null && !(allowExisting && existing != null)) {
      return ('That kiosk already follows another leader.', null);
    }
    return (
      null,
      {
        'id': id,
        'name': identity['name'],
        'version': identity['version'],
        'address': ip.address,
        'port': number,
        'supported': true,
        'manual': true,
        if (secure) 'tls': true,
      },
    );
  }

  /// Recheck identity before sending the invitation to the selected endpoint.
  Future<String?> inviteKiosk(
    String id,
    String? profile, {
    Object? address,
    Object? port,
  }) async {
    if (!leading) return 'Lead this fleet is off';
    if (!enabled) return 'The remote admin and Find other kiosks must be on';
    if (id.isEmpty || id == _selfId) return 'Pick another kiosk';
    if (profile != null && !_profiles.any((p) => p.id == profile)) {
      return 'No such profile';
    }
    final manual = address != null;
    if (!manual) {
      final peer = (await _peers())[id];
      final saved = _follower(id);
      address = peer?['address'] ?? saved?.address;
      port = peer?['port'] ?? saved?.port;
      if (address == null) return 'That kiosk is not on the network right now';
    }
    final (error, found) = await lookupKiosk(
      address,
      port,
      expectedId: id,
      allowExisting: !manual,
    );
    if (error != null) return error;
    final peer = found!;
    final host = peer['address'] as String;
    final adminPort = peer['port'] as int;
    final url = Uri(
      scheme: peer['tls'] == true ? 'https' : 'http',
      host: host,
      port: adminPort,
    );
    final nonce = _nonce();
    final res = await _post('$url/api/fleet/invite', {
      'invite': nonce,
      'leader': {
        'id': _selfId,
        'name': _selfName,
        'version': _selfVersion,
        'port': _settings.get(defs.remotePort).toInt(),
        if (_settings.get(defs.remoteTls)) 'tls': true,
      },
    });
    final body = _jsonOf(res);
    if (res == null) return 'That kiosk did not answer';
    if (res.statusCode != 200 || body?['ok'] != true) {
      return '${body?['error'] ?? 'That kiosk refused the invitation'}';
    }
    final existing = _follower(id);
    final f =
        existing ??
        Follower(
          id: id,
          name: '${peer['name'] ?? host}',
          address: host,
          port: adminPort,
        );
    f
      ..tls = peer['tls'] == true
      ..name = '${peer['name'] ?? f.name}'
      ..address = host
      ..port = adminPort
      ..version = '${peer['version'] ?? ''}'
      ..profile = profile == null || profile == SyncProfile.defaultId
          ? null
          : profile
      ..declined = false
      ..online = true
      ..error = null;
    // An already trusting kiosk answers at once with a token; anyone else
    // is asked on its screen.
    final data = body?['data'];
    final token = data is Map ? data['token'] : null;
    if (token is String && token.isNotEmpty) {
      f
        ..token = token
        ..invite = null;
    } else {
      f
        ..token = null
        ..invite = nonce;
    }
    if (existing == null) _followers.add(f);
    await _saveFollowers();
    log.info(name, 'invited ${f.name} at $host');
    _publish();
    _scheduleTick();
    return null;
  }

  /// Add or change a profile. Answers (error, id).
  Future<(String?, String?)> setProfile(Object? raw) async {
    var profile = SyncProfile.parse(raw);
    if (profile == null) return ('A profile needs its categories', null);
    final trimmedName = profile.name.trim();
    if (profile.id.isEmpty) {
      if (trimmedName.isEmpty) return ('A profile needs a name', null);
      profile = profile.copyWith(id: _nonce().substring(0, 12));
    }
    if (profile.isUpdatesOnly) {
      return ('The Updates only profile cannot be changed', null);
    }
    if (profile.isDefault) {
      profile = profile.copyWith(name: 'Default');
    } else if (trimmedName.isEmpty) {
      return ('A profile needs a name', null);
    } else {
      profile = profile.copyWith(name: trimmedName);
    }
    // Names are how the pages are addressed on both surfaces: one each.
    final taken = _profiles.any(
      (p) =>
          p.id != profile!.id &&
          p.name.toLowerCase() == profile.name.toLowerCase(),
    );
    if (taken) return ('A profile named ${profile.name} exists', null);
    final at = _profiles.indexWhere((p) => p.id == profile!.id);
    if (at < 0) {
      _profiles.add(profile);
    } else {
      _profiles[at] = profile;
    }
    await _saveProfiles();
    _scheduleTick();
    _publish();
    return (null, profile.id);
  }

  Future<String?> deleteProfile(String id) async {
    if (id == SyncProfile.defaultId) return 'The Default profile stays';
    if (id == SyncProfile.updatesOnlyId) {
      return 'The Updates only profile stays';
    }
    final at = _profiles.indexWhere((p) => p.id == id);
    if (at < 0) return 'No such profile';
    _profiles.removeAt(at);
    for (final f in _followers) {
      if (f.profile == id) f.profile = null;
    }
    await _saveProfiles();
    await _saveFollowers();
    _scheduleTick();
    _publish();
    return null;
  }

  Future<String?> assignProfile(String id, String? profile) async {
    final f = _follower(id);
    if (f == null) return 'No such follower';
    if (profile != null &&
        profile != SyncProfile.defaultId &&
        !_profiles.any((p) => p.id == profile)) {
      return 'No such profile';
    }
    f.profile = profile == null || profile == SyncProfile.defaultId
        ? null
        : profile;
    await _saveFollowers();
    _scheduleTick();
    _publish();
    return null;
  }

  /// Every setting a profile can take out: what travels with a category
  /// (the credentials and the dashboard have switches of their own), with
  /// the page it lives on so a picker can say where it is. Home Assistant's
  /// mirrored selects are hidden settings but travel like any other, so the
  /// pickers list them on the Voice Satellite page that draws them.
  List<Map<String, Object?>> syncable() {
    final titles = {for (final c in defs.fleetSyncCategories) c.$1: c.$2};
    final selects = {
      for (final e in defs.voiceHaSelectSettings.entries)
        e.value.key: e.key.startsWith('wake_word') ? 'Wake Word' : 'Assistant',
    };
    return [
      for (final d in defs.allSettings)
        // A setting that follows another one travels with it, so excluding
        // it alone would do nothing.
        if (!d.perDevice &&
            d.linksTo == null &&
            !defs.fleetCredentialKeys.contains(d.key) &&
            !defs.fleetDashboardKeys.contains(d.key) &&
            !defs.fleetFollowsKey.containsKey(d.key) &&
            titles.containsKey(defs.fleetCategoryOf(d)))
          {
            'key': d.key,
            'title': d.title,
            'description': d.description,
            'category': titles[defs.fleetCategoryOf(d)],
            if ((d.subpage ?? selects[d.key]) != null)
              'subpage': d.subpage ?? selects[d.key],
            'hidden': d.hidden && !selects.containsKey(d.key),
          },
    ];
  }

  Future<String?> removeFollower(String id) async {
    final f = _follower(id);
    if (f == null) return 'No such follower';
    _followers.remove(f);
    await _saveFollowers();
    if (f.token != null) {
      unawaited(_post('${f.url}/api/fleet/leave', {}, token: f.token));
    }
    log.info(name, 'removed ${f.name} from the fleet');
    _scheduleTick();
    _publish();
    return null;
  }

  /// Update the fleet: each follower behind this kiosk that is offered a
  /// release installs it, then this kiosk installs its own if it has one.
  /// Answers who was told and who was skipped, with the reason.
  Future<Map<String, Object?>> updateFleet(String id) async {
    final started = <String>[];
    final skipped = <String, String>{};
    for (final f in _followers) {
      if (id.isNotEmpty && f.id != id) continue;
      if (f.token == null) {
        skipped[f.name] = 'not a follower yet';
        continue;
      }
      if (!f.online) {
        skipped[f.name] = 'offline';
        continue;
      }
      // Ask afresh: the follower's own check runs twice a day.
      final check = _jsonOf(
        await _post('${f.url}/api/commands/checkUpdateNow', {}, token: f.token),
      );
      final data = check?['data'];
      final offered = data is Map ? '${data['availableVersion'] ?? ''}' : '';
      if (offered.isEmpty) {
        skipped[f.name] = 'up to date';
        continue;
      }
      if (data is Map && data['progress'] != null) {
        skipped[f.name] = 'already downloading';
        continue;
      }
      final res = _jsonOf(
        await _post('${f.url}/api/commands/installUpdate', {}, token: f.token),
      );
      if (res?['ok'] == true) {
        started.add(f.name);
        f.update = {'availableVersion': offered, 'progress': 0};
      } else {
        skipped[f.name] = '${res?['error'] ?? 'did not answer'}';
      }
    }
    var self = false;
    if (id.isEmpty) {
      final status = await commands.execute('getUpdateStatus', const {});
      final data = status.data;
      if (data is Map && data['availableVersion'] != null) {
        final r = await commands.execute('installUpdate', const {});
        self = r.ok;
      }
    }
    log.info(
      name,
      'update the fleet: ${started.length} follower(s) installing'
      '${self ? ', then this kiosk' : ''}',
    );
    _publish();
    return {'started': started, 'skipped': skipped, 'self': self};
  }

  /// The full configuration of this kiosk and every follower, for a backup
  /// of the whole fleet in one call. Each follower answers its own
  /// `exportConfig` over the fleet token, secrets included, like the
  /// admin's own export. A follower that cannot be reached is listed with
  /// the reason instead, so one tablet that is off never fails the rest.
  Future<Map<String, Object?>> exportFleet() async {
    await _readSelf();
    final own = await commands.execute('exportConfig', const {});
    final ownConfig = (own.data as Map?)?.cast<String, Object?>();
    Future<Map<String, Object?>> follower(Follower f) async {
      final entry = <String, Object?>{'id': f.id, 'name': f.name};
      final res = await _get('${f.url}/api/config/export', token: f.token);
      final body = _jsonOf(res);
      if (res == null) {
        entry['error'] = 'Unreachable';
      } else if (res.statusCode == 200 &&
          body?['kind'] == 'kiosk-satellite-config') {
        entry['config'] = body;
      } else if (body?['error'] == 'fleet token') {
        // Older kiosks keep their configuration away from a fleet token.
        entry['error'] = 'Update this kiosk to export it from the fleet';
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        entry['error'] = 'No longer follows this kiosk';
      } else {
        entry['error'] = '${body?['error'] ?? 'Bad answer'}';
      }
      return entry;
    }

    final followers = leading
        ? await Future.wait([
            for (final f in _followers)
              if (f.token != null) follower(f),
          ])
        : const <Map<String, Object?>>[];
    final exported = followers.where((d) => d['config'] != null).length;
    log.info(
      name,
      'exported the configuration of this kiosk and $exported of '
      '${followers.length} follower(s)',
    );
    return {
      'kind': 'kiosk-satellite-fleet-config',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'devices': [
        {
          'id': _selfId,
          'name': _selfName.isNotEmpty
              ? _selfName
              : '${ownConfig?['deviceName'] ?? ''}',
          'self': true,
          if (own.ok) 'config': ownConfig else 'error': own.error,
        },
        ...followers,
      ],
    };
  }

  /// How long one APK upload to a follower may take. A release APK is
  /// under 200 MB and a wall tablet's Wi-Fi moves that in a minute or two;
  /// the ceiling is for one that stalls.
  @visibleForTesting
  Duration uploadTimeout = const Duration(minutes: 15);

  /// Install the APK uploaded to this kiosk on the fleet (issue #566): the
  /// file is streamed to each follower's own upload endpoint, which
  /// inspects it under the same rules (a newer Kiosk Satellite build) and
  /// installs it, then this kiosk installs its own copy. Followers first
  /// so this one stays up to drive it. Answers who was told and who was
  /// skipped, with the reason, or `error` when nothing is uploaded here.
  Future<Map<String, Object?>> installUploadedOnFleet(String id) async {
    if (_install?['done'] == false) {
      return {'error': 'A fleet install is already under way.'};
    }
    final status = await commands.execute('getUpdateStatus', const {});
    final data = status.data;
    final up = data is Map ? data['uploaded'] : null;
    if (up is! Map) return {'error': 'No uploaded APK is waiting.'};
    final file = File('${up['path']}');
    if (!await file.exists()) {
      return {'error': 'The uploaded APK is gone. Upload it again.'};
    }
    final version = '${up['version']}';
    final build = (up['buildNumber'] as num?)?.toInt() ?? 0;
    final started = <String>[];
    final skipped = <String, String>{};
    final install = _install = {
      'version': version,
      'buildNumber': build,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
      'done': false,
      'sendingTo': null,
      'progress': null,
      'started': started,
      'skipped': skipped,
      'self': null,
    };
    _publish();
    try {
      for (final f in _followers) {
        if (id.isNotEmpty && f.id != id) continue;
        if (f.token == null) {
          skipped[f.name] = 'not a follower yet';
          continue;
        }
        if (!f.online) {
          skipped[f.name] = 'offline';
          continue;
        }
        log.info(name, 'sending v$version to ${f.name}');
        install
          ..['sendingTo'] = f.name
          ..['progress'] = 0.0;
        f.sending = 0;
        _publish();
        var last = DateTime.now();
        final sent = _jsonOf(
          await _upload(
            '${f.url}/api/update/upload',
            file,
            token: f.token,
            onProgress: (fraction) {
              f.sending = fraction;
              install['progress'] = fraction;
              // Every half second, not every chunk: each publish is a
              // status read on every admin page open.
              final now = DateTime.now();
              if (now.difference(last) < const Duration(milliseconds: 500)) {
                return;
              }
              last = now;
              _publish();
            },
          ),
        );
        f.sending = null;
        install
          ..['sendingTo'] = null
          ..['progress'] = null;
        if (sent?['ok'] != true) {
          skipped[f.name] = '${sent?['error'] ?? 'did not take the upload'}';
          _publish();
          continue;
        }
        final accepted = sent!['data'];
        if (accepted is Map && accepted['currentBuild'] == build) {
          skipped[f.name] = 'already on $version';
          _publish();
          continue;
        }
        final res = _jsonOf(
          await _post(
            '${f.url}/api/commands/installUploadedApk',
            {},
            token: f.token,
          ),
        );
        if (res?['ok'] == true) {
          started.add(f.name);
          // It just answered: whatever the last poll held against it is
          // stale, and the row says Installing until the poll says more.
          f
            ..error = null
            ..update = {...?f.update, 'installing': true};
        } else {
          skipped[f.name] = '${res?['error'] ?? 'did not answer'}';
        }
        _publish();
      }
      var self = false;
      if (id.isEmpty) {
        final r = await commands.execute('installUploadedApk', const {});
        self = r.ok;
        if (!r.ok) {
          skipped[_selfName.isEmpty ? 'this kiosk' : _selfName] = '${r.error}';
        }
      }
      install['self'] = self;
      log.info(
        name,
        'install the uploaded v$version on the fleet: ${started.length} '
        'follower(s) installing${self ? ', then this kiosk' : ''}',
      );
      return {'started': started, 'skipped': skipped, 'self': self};
    } finally {
      for (final f in _followers) {
        f.sending = null;
      }
      install
        ..['done'] = true
        ..['sendingTo'] = null
        ..['progress'] = null;
      _publish();
    }
  }

  // ── The follower's actions ──────────────────────────────────────────

  Future<(String?, Map<String, Object?>?)> receiveInvite(
    Map<String, Object?> p,
  ) async {
    if (!enabled) return ('This kiosk is not set up for a fleet', null);
    if (leading) return ('This kiosk leads a fleet of its own', null);
    final nonce = '${p['invite'] ?? ''}';
    final leaderRaw = p['leader'];
    final address = '${p['address'] ?? ''}';
    if (nonce.isEmpty || leaderRaw is! Map || address.isEmpty) {
      return ('Malformed invitation', null);
    }
    final leaderId = '${leaderRaw['id'] ?? ''}';
    final port = (leaderRaw['port'] as num?)?.toInt() ?? 2324;
    if (leaderId.isEmpty) return ('Malformed invitation', null);
    // The kiosk at the address the invitation came from must be the one
    // it claims to be and must lead.
    final identity = _jsonOf(
      await _get(
        Uri(
          scheme: leaderRaw['tls'] == true ? 'https' : 'http',
          host: address,
          port: port,
          path: '/api/fleet/identity',
        ).toString(),
      ),
    );
    if (identity == null || '${identity['id']}' != leaderId) {
      return ('The invitation does not match the kiosk it came from', null);
    }
    final current = leader;
    if (current != null && '${current['id']}' != leaderId) {
      return ('This kiosk already follows ${current['name']}', null);
    }
    final leaderInfo = {
      'id': leaderId,
      'name': '${leaderRaw['name'] ?? identity['name'] ?? address}',
      'version': '${leaderRaw['version'] ?? identity['version'] ?? ''}',
      if (leaderRaw['tls'] == true) 'tls': true,
      'address': address,
      'port': port,
    };
    // Already this kiosk's leader (a removal that never reached here, an
    // invitation sent again): nothing to confirm, the trust is standing.
    if (current != null) {
      await _settings.set(defs.fleetLeaderInfo, jsonEncode(leaderInfo));
      final token = await _mintToken(leaderId);
      if (token == null) return ('Could not mint a token', null);
      log.info(name, 'invited again by ${leaderInfo['name']}, still following');
      return (null, {'token': token});
    }
    await _settings.set(
      defs.fleetInvite,
      jsonEncode({
        'invite': nonce,
        'leader': leaderInfo,
        'at': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      }),
    );
    log.info(name, '${leaderInfo['name']} wants to lead this kiosk');
    _publish();
    return (null, {'pending': true});
  }

  Future<Map<String, Object?>> pollInvite(String nonce) async {
    final inv = invite;
    if (inv == null || nonce.isEmpty || '${inv['invite']}' != nonce) {
      return {'status': 'unknown'};
    }
    switch (inv['status']) {
      case 'accepted':
        // Handed out once.
        await _settings.set(defs.fleetInvite, '');
        _publish();
        return {'status': 'accepted', 'token': inv['token']};
      case 'declined':
        await _settings.set(defs.fleetInvite, '');
        _publish();
        return {'status': 'declined'};
      default:
        return {'status': 'pending'};
    }
  }

  Future<String?> _mintToken(String leaderId) async {
    final r = await commands.execute('issueFleetToken', {'leader': leaderId});
    final token = r.data;
    return r.ok && token is String && token.isNotEmpty ? token : null;
  }

  /// Accept on the kiosk: the leader is stored, a token minted for its next
  /// poll to collect.
  Future<String?> accept() async {
    final inv = pendingInvite;
    if (inv == null) return 'No invitation is waiting';
    final leaderInfo = (inv['leader'] as Map?)?.cast<String, Object?>();
    if (leaderInfo == null) return 'Malformed invitation';
    final token = await _mintToken('${leaderInfo['id']}');
    if (token == null) return 'Could not mint a token';
    await _settings.set(defs.fleetLeaderInfo, jsonEncode(leaderInfo));
    await _settings.set(defs.fleetRoster, '');
    await _settings.set(defs.fleetAppliedRevision, '');
    await _settings.set(defs.fleetSyncedKeys, '');
    await _settings.set(defs.fleetLastSyncAt, 0);
    await _settings.set(
      defs.fleetInvite,
      jsonEncode({...inv, 'status': 'accepted', 'token': token}),
    );
    log.info(name, 'now following ${leaderInfo['name']}');
    _publish();
    return null;
  }

  Future<void> decline() async {
    final inv = pendingInvite;
    if (inv == null) return;
    await _settings.set(
      defs.fleetInvite,
      jsonEncode({...inv, 'status': 'declined'}),
    );
    log.info(name, 'declined ${(inv['leader'] as Map?)?['name']}');
    _publish();
  }

  Future<void> leave() async {
    if (!following) return;
    log.info(name, 'left the fleet of ${leader?['name']}');
    await _forgetLeader();
  }

  Future<void> _forgetLeader() async {
    await _settings.set(defs.fleetLeaderInfo, '');
    await _settings.set(defs.fleetRoster, '');
    await _settings.set(defs.fleetSyncedKeys, '');
    // The plugins stay installed and configured, as the settings do.
    await _settings.set(defs.fleetSyncedPlugins, '');
    await _settings.set(defs.fleetPluginErrors, '');
    _staged.clear();
    await _settings.set(defs.fleetAppliedRevision, '');
    await _settings.set(defs.fleetLastSyncAt, 0);
    _publish();
  }

  Future<Map<String, Object?>> followerStatus() async {
    if (_selfId.isEmpty) await _readSelf();
    final update = await commands.execute('getUpdateStatus', const {});
    final u = update.data;
    final applied = _settings.get(defs.fleetAppliedRevision);
    var installed = const <Map<String, Object?>>[];
    try {
      installed = await plugins?.fleetState() ?? const [];
    } catch (_) {}
    return {
      'id': _selfId,
      'name': _selfName,
      'version': _selfVersion,
      'leaderId': leader?['id'],
      'rosterRevision': _rosterRevision(_settings.get(defs.fleetRoster)),
      'appliedRevision': applied.isEmpty ? null : applied,
      'dirty':
          applied.isEmpty &&
          (syncedKeys.isNotEmpty || syncedPlugins.isNotEmpty),
      // The installed packages by hash, so the leader sends only what is
      // missing, and the synced plugins that failed here.
      'plugins': {for (final p in installed) '${p['id']}': p['sha256']},
      'pluginErrors': pluginErrors,
      'update': u is Map
          ? {
              'currentVersion': u['currentVersion'],
              'availableVersion': u['availableVersion'],
              'progress': u['progress'],
              'installing': u['installing'],
              'lastOutcome': u['lastOutcome'],
            }
          : null,
    };
  }

  Future<(String?, Map<String, Object?>?)> apply(Map<String, Object?> p) async {
    if (!following) return ('This kiosk follows nobody', null);
    if (_selfVersion.isEmpty) await _readSelf();
    final version = '${p['version'] ?? ''}';
    if (_versionName(version) != _versionName(_selfVersion)) {
      return (null, {'held': 'version', 'version': _selfVersion});
    }
    final raw = p['settings'];
    if (raw is! Map) return ('settings must be an object', null);
    // The plugins first: a setting may name one of them.
    final sentPlugins = p['plugins'];
    if (sentPlugins is List && plugins != null) {
      await _applyPlugins(sentPlugins);
    }
    // Settings this kiosk pins, such as the screensaver on one without a
    // screen, stay out of both the import and the synced keys.
    final wanted = acceptable(raw.cast<String, Object?>())
      ..removeWhere((key, _) => defs.devicePinnedKeys.contains(key));
    // Only what differs: setting a value already held would still wake
    // every listener (a server restart, a page reload) for nothing.
    final changes = <String, Object?>{};
    for (final e in wanted.entries) {
      final def = _settings.defByKey(e.key);
      if (def == null || _pluginScreensaverSetting(e.key, _settings.get(def))) {
        continue;
      }
      final value = switch (e.key) {
        'gestures.mappings' => _preservePluginGestures(e.value),
        'esphome.excluded_entities' => _preservePluginEntityExclusions(e.value),
        _ => e.value,
      };
      if (_sameValue(_settings.get(def), value)) continue;
      changes[e.key] = value;
    }
    final applied = changes.isEmpty
        ? 0
        : await _settings.import(changes, source: 'fleet');
    final revision = '${p['revision'] ?? ''}';
    await _settings.set(defs.fleetSyncedKeys, jsonEncode(wanted.keys.toList()));
    await _settings.set(defs.fleetAppliedRevision, revision);
    await _settings.set(
      defs.fleetLastSyncAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    log.info(
      name,
      'synced ${wanted.length} settings from ${leader?['name']} '
      '($applied changed)',
    );
    _publish();
    return (
      null,
      {
        'applied': applied,
        'received': wanted.length,
        'skipped': raw.length - wanted.length,
        'appliedRevision': revision,
        'pluginErrors': pluginErrors,
      },
    );
  }

  /// Holds a package the leader sent until the push that installs it.
  Future<String?> stagePlugin(
    String sha256Hex,
    Object? stream,
    int? length,
  ) async {
    if (!following) return 'This kiosk follows nobody';
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256Hex)) {
      return 'sha256 must be a SHA-256 in hex';
    }
    if (stream is! Stream<List<int>>) return 'no body';
    const limit = 4 * 1024 * 1024;
    if ((length ?? 0) > limit) return 'Plugin ZIP must be at most 4 MB';
    final data = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      if (data.length + chunk.length > limit) {
        return 'Plugin ZIP must be at most 4 MB';
      }
      data.add(chunk);
    }
    final bytes = data.takeBytes();
    if (sha256.convert(bytes).toString() != sha256Hex) {
      return 'Package SHA-256 does not match';
    }
    // A fleet carries at most eight plugins: more held means stale ones.
    while (_staged.length >= 8) {
      _staged.remove(_staged.keys.first);
    }
    _staged[sha256Hex] = bytes;
    return null;
  }

  /// What the leader holds for its plugins, applied here: a package whose
  /// hash differs installs from what was staged, then each takes the
  /// leader's settings, action placements and enabled state. A plugin the
  /// fleet installed and the leader no longer sends is removed. One that
  /// was here before the fleet stays when the leader stops sending it.
  Future<void> _applyPlugins(List<Object?> raw) async {
    final host = plugins!;
    _applyingPlugins = true;
    try {
      final wanted = {
        for (final e in raw.whereType<Map>())
          if (e['id'] is String && e['sha256'] is String)
            e['id'] as String: e.cast<String, Object?>(),
      };
      final before = syncedPlugins;
      final errors = <String, Map<String, Object?>>{
        for (final e in pluginErrors.entries)
          if (wanted.containsKey(e.key)) e.key: e.value,
      };
      var state = await host.fleetState();
      final installedByFleet = <String>{};
      for (final entry in wanted.values) {
        final id = entry['id'] as String;
        final hash = entry['sha256'] as String;
        void failed(String message) => errors[id] = {
          'sha256': hash,
          'name': '${entry['name'] ?? id}',
          'message': message,
        };
        try {
          final mine = state.where((p) => p['id'] == id).firstOrNull;
          if (mine?['sha256'] != hash) {
            final bytes = _staged.remove(hash);
            if (bytes == null) {
              // A failure already recorded for this package says more.
              if (errors[id]?['sha256'] != hash) failed(_notArrived);
              continue;
            }
            final source = entry['source'];
            await host.fleetInstall(
              bytes,
              sha256: hash,
              source: source is Map ? source.cast<String, Object?>() : null,
            );
            if (mine == null) installedByFleet.add(id);
            state = await host.fleetState();
          }
          await host.fleetConfigure(id, entry);
          errors.remove(id);
        } catch (e) {
          failed(_errorText(e));
        }
      }
      for (final id in before.keys) {
        if (wanted.containsKey(id) || before[id]?['installed'] != true) {
          continue;
        }
        try {
          await host.fleetRemove(id);
        } catch (e) {
          log.warn(name, 'could not remove the plugin $id: $e');
        }
      }
      state = await host.fleetState();
      final synced = <String, Map<String, Object?>>{};
      for (final entry in wanted.values) {
        final id = entry['id'] as String;
        final mine = state.where((p) => p['id'] == id).firstOrNull;
        final ours =
            before[id]?['installed'] == true || installedByFleet.contains(id);
        if (mine == null) {
          // Kept so a later push still knows the fleet put it here.
          if (ours) {
            synced[id] = {'name': entry['name'], 'fp': '', 'installed': true};
          }
          continue;
        }
        final secrets = entry['secrets'] == true;
        synced[id] = {
          'name': mine['name'],
          'fp': pluginFingerprint(mine, secrets: secrets),
          'secrets': secrets,
          'installed': ours,
        };
      }
      await _settings.set(
        defs.fleetSyncedPlugins,
        synced.isEmpty ? '' : jsonEncode(synced),
      );
      await _settings.set(
        defs.fleetPluginErrors,
        errors.isEmpty ? '' : jsonEncode(errors),
      );
      if (wanted.isNotEmpty || before.isNotEmpty) {
        log.info(
          name,
          'synced ${wanted.length} plugins from ${leader?['name']}'
          '${errors.isEmpty ? '' : ' (${errors.length} failed)'}',
        );
      }
    } finally {
      _staged.clear();
      _applyingPlugins = false;
    }
  }

  static String _errorText(Object error) => switch (error) {
    PlatformException(:final message?) => message,
    StateError(:final message) => message,
    FormatException(:final message) => message,
    _ => '$error',
  };

  // ── The status both UIs draw ────────────────────────────────────────

  Map<String, Object?> status() {
    final mine = _versionName(_selfVersion);
    final now = DateTime.now().millisecondsSinceEpoch;
    List<Map<String, Object?>> rows() => [
      for (final f in _followers)
        {
          'id': f.id,
          'name': f.name,
          'address': f.address,
          'port': f.port,
          'version': f.version,
          'online': f.online,
          'profile': profileFor(f).id,
          'profileName': profileFor(f).name,
          'lastSyncAt': f.lastSyncAt,
          'update': f.update,
          ...phaseOf(
            f,
            mine,
            fingerprintFor(f),
            now,
            profilePlugins(profileFor(f)),
          ),
        },
    ];
    final inv = pendingInvite;
    final led = leader;
    final synced = syncedKeys;
    final plugged = syncedPlugins;
    final syncedCategories = <String>{};
    final credentials = <String>{};
    var dashboard = false;
    for (final key in synced) {
      final def = _settings.defByKey(key);
      if (def == null) continue;
      if (defs.fleetCredentialKeys.contains(key)) credentials.add(key);
      if (defs.fleetDashboardKeys.contains(key)) dashboard = true;
      syncedCategories.add(defs.fleetCategoryOf(def));
    }
    final titles = {for (final c in defs.fleetSyncCategories) c.$1: c.$2};
    final outdated = [
      for (final f in _followers)
        if (f.token != null &&
            f.online &&
            f.version.isNotEmpty &&
            _versionName(f.version) != mine)
          f.name,
    ];
    return {
      'enabled': enabled,
      'self': {'id': _selfId, 'name': _selfName, 'version': _selfVersion},
      'leader': leading,
      'profiles': [
        for (final p in _profiles)
          {
            ...p.toJson(),
            'kiosks': _followers.where((f) => profileFor(f).id == p.id).length,
          },
      ],
      'followers': rows(),
      'outdated': outdated,
      'install': _install,
      // The leader's installed plugins, for a profile's Plugins dialog.
      'plugins': [
        for (final p in _pluginState)
          {
            'id': p['id'],
            'name': p['name'],
            'version': p['version'],
            'kept': p['kept'] == true,
          },
      ],
      'following': led == null
          ? null
          : {
              'leader': led,
              'appliedRevision': _settings.get(defs.fleetAppliedRevision),
              'dirty':
                  _settings.get(defs.fleetAppliedRevision).isEmpty &&
                  (synced.isNotEmpty || plugged.isNotEmpty),
              'syncedKeys': synced.toList(),
              // The plugins the leader syncs here by name and the ones
              // that failed, with why.
              'syncedPlugins': [
                for (final e in plugged.entries) '${e.value['name'] ?? e.key}',
              ],
              'pluginErrors': [
                for (final e in pluginErrors.values)
                  {'name': e['name'], 'message': e['message']},
              ],
              'syncedCategories': [
                for (final c in defs.fleetSyncCategories)
                  if (syncedCategories.contains(c.$1)) titles[c.$1],
              ],
              // The titles, in the pick list's order.
              'credentials': [
                for (final c in defs.fleetCredentials)
                  if (credentials.contains(c.$1)) c.$2,
              ],
              'dashboard': dashboard,
              'lastSyncAt': _settings.get(defs.fleetLastSyncAt).toInt(),
            },
      'invite': inv == null ? null : {'leader': inv['leader'], 'at': inv['at']},
      'categories': [
        for (final c in defs.fleetSyncCategories)
          {'id': c.$1, 'title': c.$2, 'note': c.$3},
      ],
      // The credentials a list can include, one switch each.
      'credentials': [
        for (final c in defs.fleetCredentials) {'key': c.$1, 'title': c.$2},
      ],
    };
  }

  /// A follower's state in words and which color it wears: `ok` for in
  /// sync, `warn` for a version to bring up, `muted` for the rest.
  static Map<String, Object?> phaseOf(
    Follower f,
    String mine,
    String revision,
    int now, [
    List<Map<String, Object?>> plugins = const [],
  ]) {
    String ago(int at) {
      final s = ((now - at) / 1000).round();
      if (s < 60) return 'just now';
      final m = s ~/ 60;
      if (m < 60) return '$m min ago';
      final h = m ~/ 60;
      if (h < 48) return '$h h ago';
      return '${h ~/ 24} days ago';
    }

    if (f.declined) {
      return {
        'phase': 'declined',
        'status': 'Declined on the kiosk',
        'tone': 'muted',
      };
    }
    if (f.invite != null) {
      return {
        'phase': 'pending',
        'status': 'Waiting for its OK',
        'tone': 'muted',
      };
    }
    if (f.token == null) {
      return {'phase': 'left', 'status': 'Left the fleet', 'tone': 'muted'};
    }
    if (!f.online) {
      return {'phase': 'offline', 'status': 'Offline', 'tone': 'muted'};
    }
    // The APK on its way is the freshest fact there is: it outranks the
    // last poll's error and the version gap it is there to close.
    final sending = f.sending;
    if (sending != null) {
      return {
        'phase': 'updating',
        'status': 'Sending ${(sending * 100).round()}%',
        'tone': 'muted',
      };
    }
    if (f.error != null) {
      return {'phase': 'error', 'status': f.error, 'tone': 'warn'};
    }
    if (f.update?['installing'] == true) {
      return {'phase': 'updating', 'status': 'Installing', 'tone': 'muted'};
    }
    if (f.version.isNotEmpty && mine.isNotEmpty) {
      final theirs = _versionName(f.version);
      if (theirs != mine) {
        return {
          'phase': 'version',
          'status': isNewer(f.version, mine)
              ? 'Runs $theirs, this kiosk needs an update'
              : 'Needs $mine',
          'tone': 'warn',
        };
      }
    }
    if (f.update?['progress'] != null) {
      final pct = ((f.update!['progress'] as num) * 100).round();
      return {
        'phase': 'updating',
        'status': 'Downloading $pct%',
        'tone': 'muted',
      };
    }
    // A plugin the kiosk could not take, for the package the leader runs
    // now: one that changed since is on its way again.
    for (final p in plugins) {
      final id = '${p['id']}';
      final hash = p['sha256'];
      final unsent = f.packageErrors[id];
      if (unsent != null && unsent.$1 == hash) {
        return {
          'phase': 'error',
          'status': 'Reinstall ${unsent.$2} on this kiosk to sync it',
          'tone': 'warn',
        };
      }
      final failed = f.pluginErrors[id];
      if (failed != null && failed['sha256'] == hash) {
        return {
          'phase': 'error',
          'status': 'Could not install ${failed['name']}: ${failed['message']}',
          'tone': 'warn',
        };
      }
    }
    if (!f.dirty && f.appliedRevision == revision && f.lastSyncAt > 0) {
      return {
        'phase': 'synced',
        'status': 'Synced ${ago(f.lastSyncAt)}',
        'tone': 'ok',
      };
    }
    return {'phase': 'syncing', 'status': 'Syncing…', 'tone': 'muted'};
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  /// The version name, without the build number: `2026.9.19+118` and
  /// `2026.9.19+120` are the same release.
  static String _versionName(String v) => v.split('+').first.trim();

  /// Numeric-triple comparison, the update manager's rule.
  static bool isNewer(String a, String b) {
    List<int> nums(String v) => RegExp(
      r'\d+',
    ).allMatches(_versionName(v)).take(3).map((m) => int.parse(m[0]!)).toList();
    final r = nums(a);
    final c = nums(b);
    for (var i = 0; i < 3; i++) {
      final x = i < r.length ? r[i] : 0;
      final y = i < c.length ? c[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static bool _sameValue(Object? a, Object? b) {
    if (a is num && b is num) return a == b;
    return a == b;
  }

  static String _nonce() {
    final random = Random.secure();
    return List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<http.Response?> _get(String url, {String? token}) async {
    final client = clientFactory();
    try {
      return await client
          .get(
            Uri.parse(url),
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          )
          .timeout(requestTimeout);
    } catch (e) {
      log.debug(name, 'GET $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  Future<http.Response?> _post(
    String url,
    Map<String, Object?> body, {
    String? token,
  }) async {
    final client = clientFactory();
    try {
      return await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);
    } catch (e) {
      log.debug(name, 'POST $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Streams [file] as the raw body of a POST, the way the update upload
  /// endpoint takes an APK. The response comes once the whole file is
  /// across, so this waits [uploadTimeout], not [requestTimeout].
  Future<http.Response?> _upload(
    String url,
    File file, {
    String? token,
    void Function(double fraction)? onProgress,
    String method = 'POST',
    String contentType = 'application/vnd.android.package-archive',
  }) async {
    final client = clientFactory();
    try {
      final length = await file.length();
      final request = http.StreamedRequest(method, Uri.parse(url))
        ..contentLength = length
        ..headers['Content-Type'] = contentType;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      var done = 0;
      final counted = onProgress == null || length == 0
          ? file.openRead()
          : file.openRead().map((chunk) {
              done += chunk.length;
              onProgress(done / length);
              return chunk;
            });
      // pipe closes the sink after the last chunk, which is what ends the
      // request; a read error ends it too and surfaces from send.
      unawaited(
        counted.pipe(request.sink).catchError((Object e) {
          log.debug(name, 'upload $url: $e');
        }),
      );
      final streamed = await client.send(request).timeout(uploadTimeout);
      return await http.Response.fromStream(streamed).timeout(requestTimeout);
    } catch (e) {
      log.debug(name, 'POST $url: $e');
      return null;
    } finally {
      client.close();
    }
  }

  static Map<String, Object?>? _jsonOf(http.Response? res) {
    if (res == null) return null;
    try {
      final decoded = jsonDecode(res.body);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }
}
