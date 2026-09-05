import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' show Random;

import 'package:crypto/crypto.dart' show md5;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

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
  });

  static const defaultId = 'default';

  /// The built-in Default, until the leader edits it.
  static const initial = SyncProfile(
    categories: defs.fleetDefaultCategories,
    credentials: defs.fleetDefaultCredentials,
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
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'categories': categories.toList(),
    'credentials': credentials.toList(),
    'dashboard': dashboard,
    'excluded': excluded.toList(),
  };

  SyncProfile copyWith({
    String? id,
    String? name,
    Set<String>? categories,
    Set<String>? credentials,
    bool? dashboard,
    Set<String>? excluded,
  }) => SyncProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    categories: categories ?? this.categories,
    credentials: credentials ?? this.credentials,
    dashboard: dashboard ?? this.dashboard,
    excluded: excluded ?? this.excluded,
  );

  bool get isDefault => id == defaultId;

  /// One line for a row: "Categories: 9 of 16. Credentials: 2 of 3.
  /// Excluded: 14."
  String describe() =>
      'Categories: ${categories.length} of ${defs.fleetSyncCategories.length}. '
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
      setEquals(other.excluded, excluded);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(credentials),
    dashboard,
    Object.hashAllUnordered(excluded),
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

  final int addedAt;
  int lastSyncAt;
  String version;

  // What the last poll learned. Not persisted.
  bool online = false;
  String? appliedRevision;
  bool dirty = false;
  Map<String, Object?>? update;
  String? error;

  String get url => 'http://$address:$port';

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
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'port': port,
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
  http.Client Function() clientFactory = http.Client.new;

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

  Timer? _timer;
  Timer? _bump;
  int _ticks = 0;
  bool _ticking = false;
  DateTime _watchedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  final _subs = <StreamSubscription<Object?>>[];

  /// Followers already told to install a release, by the version asked,
  /// so Keep followers on this version asks once per release.
  final _autoUpdated = <String, String>{};

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
    _loadFollowers();
    await _loadProfiles();
    _register();

    _subs.add(bus.on<SettingChanged>().listen(_onSettingChanged));
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
    if (raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            var p = SyncProfile.parse(item);
            if (p == null || p.id.isEmpty) continue;
            // An exclusion list nobody touched follows the default as it
            // grows (the volumes joined it after the first profiles).
            final excluded = p.excluded;
            if (formerDefaultExcluded.any(
              (former) => setEquals(excluded, former),
            )) {
              p = p.copyWith(excluded: defs.fleetDefaultExcluded);
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
    if (changed) await _saveProfiles();
  }

  Future<void> _saveProfiles() => _settings.set(
    defs.fleetProfiles,
    jsonEncode([for (final p in _profiles) p.toJson()]),
  );

  Future<void> _saveFollowers() => _settings.set(
    defs.fleetFollowers,
    _followers.isEmpty
        ? ''
        : jsonEncode([for (final f in _followers) f.toJson()]),
  );

  void _publish() => bus.publish(const FleetSyncChanged());

  /// This kiosk as the discovery announces it: the id the others know it
  /// by, its name and its version. Empty while discovery is off.
  Future<void> _readSelf() async {
    final r = await commands.execute('fleet', const {});
    final data = r.data;
    if (data is! Map) return;
    for (final d in (data['devices'] as List? ?? const [])) {
      if (d is Map && d['self'] == true) {
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
    if (e.key.startsWith('fleet.')) return;
    final def = _settings.defByKey(e.key);
    if (def == null || def.perDevice) return;
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
  String fingerprintFor(Follower f) =>
      fingerprintOf(profileSettings(profileFor(f)));

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
    final watched = DateTime.now().isBefore(_watchedUntil);
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
      if (_selfId.isEmpty) await _readSelf();
      final peers = await _peers();
      final listening = peers.isNotEmpty || await _discoveryListening();
      var changed = false;
      for (final f in _followers) {
        if (only != null && f.id != only) continue;
        final peer = peers[f.id];
        if (peer != null) {
          f.online = true;
          final address = '${peer['address'] ?? f.address}';
          final port = (peer['port'] as num?)?.toInt() ?? f.port;
          final version = '${peer['version'] ?? f.version}';
          final peerName = '${peer['name'] ?? f.name}';
          if (address != f.address ||
              port != f.port ||
              version != f.version ||
              peerName != f.name) {
            f
              ..address = address
              ..port = port
              ..version = version
              ..name = peerName;
            changed = true;
          }
        } else if (listening) {
          // Heard nothing from it: not there. Where this kiosk cannot
          // hear (the mDNS port is taken), every follower is tried.
          f.online = false;
          continue;
        }
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
          changed = await _push(f) || changed;
        }
      }
      if (changed) await _saveFollowers();
    } finally {
      _ticking = false;
      _publish();
    }
  }

  /// Whether this kiosk hears the others at all (the mDNS port could be
  /// taken); a deaf kiosk polls every follower instead of trusting an
  /// empty list.
  Future<bool> _discoveryListening() async {
    final r = await commands.execute('fleet', const {});
    final data = r.data;
    return data is Map && data['enabled'] == true && data['listening'] != false;
  }

  Future<bool> _pollInvite(Follower f) async {
    final res = await _get('${f.url}/api/fleet/invite/${f.invite}');
    final body = _jsonOf(res);
    if (body == null) return false;
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
    if (body == null) {
      f.error = 'Bad answer';
      return;
    }
    f
      ..error = null
      ..online = true
      ..version = '${body['version'] ?? f.version}'
      ..appliedRevision = body['appliedRevision'] as String?
      ..dirty = body['dirty'] == true
      ..update = (body['update'] as Map?)?.cast<String, Object?>();
    final peerName = body['name'];
    if (peerName is String && peerName.isNotEmpty) f.name = peerName;
  }

  /// Push a follower everything its list allows. The full set every time,
  /// not a delta: a few hundred values, idempotent and the follower skips
  /// what it already holds.
  Future<bool> _push(Follower f) async {
    final settings = profileSettings(profileFor(f));
    final revision = fingerprintOf(settings);
    final res = await _post('${f.url}/api/fleet/apply', {
      'revision': revision,
      'version': _selfVersion,
      'settings': settings,
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
    final applied = (data['applied'] as num?)?.toInt() ?? 0;
    log.info(
      name,
      'synced ${settings.length} settings to ${f.name} '
      '($applied changed)',
    );
    return true;
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
      if (!syncs(def, profile)) continue;
      out[def.key] = _settings.get(def);
    }
    return out;
  }

  /// Whether one setting travels under [profile].
  static bool syncs(defs.SettingDef<Object> def, SyncProfile profile) {
    if (def.perDevice) return false;
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
        if (byKey[e.key] case final def? when !def.perDevice) e.key: e.value,
    };
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
            if (_selfId.isEmpty) await _readSelf();
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
          name: 'fleetInvite',
          description:
              'Invite a kiosk heard on the network to follow this one. The '
              'invitation waits on that kiosk\'s screen; nothing is synced '
              'until it is accepted there.',
          params: const {
            'id': 'The kiosk id, from fleetCandidates',
            'profile': 'The profile id it gets or omitted for the Default',
          },
          handler: (p) async {
            final r = await inviteKiosk(
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
          name: 'fleetAccept',
          description:
              'Accept the invitation waiting on this kiosk. Answered on '
              'the kiosk itself; the remote admin refuses it.',
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
              'Decline the invitation waiting on this kiosk. Answered on '
              'the kiosk itself; the remote admin refuses it.',
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
            if (_selfId.isEmpty) await _readSelf();
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
          },
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
            final url = 'http://${p['address']}:${p['port']}';
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

  /// Send the invitation. Null on success, else why not.
  Future<String?> inviteKiosk(String id, String? profile) async {
    if (!leading) return 'Lead this fleet is off';
    if (!enabled) return 'The remote admin and Find other kiosks must be on';
    if (id.isEmpty || id == _selfId) return 'Pick another kiosk';
    final peer = (await _peers())[id];
    if (peer == null) return 'That kiosk is not on the network right now';
    if (_selfId.isEmpty) await _readSelf();
    final nonce = _nonce();
    final address = '${peer['address']}';
    final port = (peer['port'] as num?)?.toInt() ?? 2324;
    // Asked first: a kiosk on a build without Fleet Management answers
    // the invitation with its login gate, and "unauthorized" says nothing.
    final probe = await _get('http://$address:$port/api/fleet/identity');
    if (probe == null) return 'That kiosk did not answer';
    if (probe.statusCode != 200) {
      return 'That kiosk runs a build without Fleet Management. It joins '
          'once it runs one.';
    }
    final res = await _post('http://$address:$port/api/fleet/invite', {
      'invite': nonce,
      'leader': {
        'id': _selfId,
        'name': _selfName,
        'version': _selfVersion,
        'port': _settings.get(defs.remotePort).toInt(),
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
          name: '${peer['name'] ?? address}',
          address: address,
          port: port,
        );
    f
      ..name = '${peer['name'] ?? f.name}'
      ..address = address
      ..port = port
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
    log.info(name, 'invited ${f.name} at $address');
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
  /// the page it lives on so a picker can say where it is.
  List<Map<String, Object?>> syncable() {
    final titles = {for (final c in defs.fleetSyncCategories) c.$1: c.$2};
    return [
      for (final d in defs.allSettings)
        if (!d.perDevice &&
            !defs.fleetCredentialKeys.contains(d.key) &&
            !defs.fleetDashboardKeys.contains(d.key) &&
            titles.containsKey(defs.fleetCategoryOf(d)))
          {
            'key': d.key,
            'title': d.title,
            'description': d.description,
            'category': titles[defs.fleetCategoryOf(d)],
            if (d.subpage != null) 'subpage': d.subpage,
            'hidden': d.hidden,
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
      await _get('http://$address:$port/api/fleet/identity'),
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
    await _settings.set(defs.fleetSyncedKeys, '');
    await _settings.set(defs.fleetAppliedRevision, '');
    await _settings.set(defs.fleetLastSyncAt, 0);
    _publish();
  }

  Future<Map<String, Object?>> followerStatus() async {
    if (_selfId.isEmpty) await _readSelf();
    final update = await commands.execute('getUpdateStatus', const {});
    final u = update.data;
    final applied = _settings.get(defs.fleetAppliedRevision);
    return {
      'id': _selfId,
      'name': _selfName,
      'version': _selfVersion,
      'leaderId': leader?['id'],
      'appliedRevision': applied.isEmpty ? null : applied,
      'dirty': applied.isEmpty && syncedKeys.isNotEmpty,
      'update': u is Map
          ? {
              'currentVersion': u['currentVersion'],
              'availableVersion': u['availableVersion'],
              'progress': u['progress'],
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
    final wanted = acceptable(raw.cast<String, Object?>());
    // Only what differs: setting a value already held would still wake
    // every listener (a server restart, a page reload) for nothing.
    final changes = <String, Object?>{};
    for (final e in wanted.entries) {
      final def = _settings.defByKey(e.key);
      if (def == null) continue;
      if (_sameValue(_settings.get(def), e.value)) continue;
      changes[e.key] = e.value;
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
      },
    );
  }

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
          ...phaseOf(f, mine, fingerprintFor(f), now),
        },
    ];
    final inv = pendingInvite;
    final led = leader;
    final synced = syncedKeys;
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
      'following': led == null
          ? null
          : {
              'leader': led,
              'appliedRevision': _settings.get(defs.fleetAppliedRevision),
              'dirty':
                  _settings.get(defs.fleetAppliedRevision).isEmpty &&
                  synced.isNotEmpty,
              'syncedKeys': synced.toList(),
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
    int now,
  ) {
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
    if (f.error != null) {
      return {'phase': 'error', 'status': f.error, 'tone': 'warn'};
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
