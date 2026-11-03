import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../device/device_details.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// One kiosk discovered on the network or saved in the fleet directory.
class FleetDevice {
  const FleetDevice({
    required this.id,
    required this.name,
    required this.version,
    required this.address,
    required this.port,
    this.self = false,
    this.tls = false,
    this.dnsName = '',
    this.adminUrl = '',
  });

  final String id;
  final String name;
  final String version;
  final String address;
  final int port;

  /// Whether this is the device the list was read from.
  final bool self;
  final bool tls;

  /// The DNS name its imported certificate covers, empty for none.
  final String dnsName;

  /// The Admin URL it was given, such as a reverse proxy name, empty for
  /// none (issue #967).
  final String adminUrl;

  /// Where the switcher opens its remote admin: its Admin URL when it has
  /// one, else over HTTPS with a CA-signed certificate its DNS name, since
  /// the browser rejects that certificate under the IP address (issue
  /// #833). Fleet calls and the intercom use [address] and [port] instead.
  String get url => adminUrl.isNotEmpty
      ? adminUrl
      : Uri(
          scheme: tls ? 'https' : 'http',
          host: tls && dnsName.isNotEmpty ? dnsName : address,
          port: port,
        ).toString();

  static final _dnsName = RegExp(
    r'^(?=.{1,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$',
  );

  static FleetDevice? fromMap(Map<Object?, Object?>? raw, {bool self = false}) {
    if (raw == null) return null;
    final address = '${raw['address'] ?? ''}';
    final port = raw['port'];
    if (port is! num) return null;
    return FleetDevice(
      id: '${raw['id'] ?? ''}',
      name: '${raw['name'] ?? ''}',
      version: '${raw['version'] ?? ''}',
      address: address,
      port: port.toInt(),
      self: self,
      tls: raw['tls'] == true,
      dnsName: switch ('${raw['dnsName'] ?? ''}'.toLowerCase()) {
        final n when _dnsName.hasMatch(n) => n,
        _ => '',
      },
      adminUrl: defs.adminUrlOrigin('${raw['adminUrl'] ?? ''}') ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'address': address,
    'port': port,
    if (tls) 'tls': true,
    if (dnsName.isNotEmpty) 'dnsName': dnsName,
    if (adminUrl.isNotEmpty) 'adminUrl': adminUrl,
    'url': url,
    'self': self,
  };

  /// Public directory fields only. Fleet credentials never travel here.
  Map<String, Object?> toDirectory() => {
    'id': id,
    'name': name,
    'version': version,
    'address': address,
    'port': port,
    if (tls) 'tls': true,
    if (dnsName.isNotEmpty) 'dnsName': dnsName,
    if (adminUrl.isNotEmpty) 'adminUrl': adminUrl,
  };

  static FleetDevice? directoryEntry(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['address'] is! String ||
        raw['port'] is! int) {
      return null;
    }
    final device = fromMap(raw.cast<Object?, Object?>());
    if (device == null ||
        device.id.isEmpty ||
        device.address.isEmpty ||
        device.port < 1 ||
        device.port > 65535) {
      return null;
    }
    return device;
  }
}

/// The kiosks on this network, for the remote admin's kiosk switcher.
///
/// While the remote admin server is up (remote management on, with a
/// password) and Find other kiosks is on, the native `FleetDiscovery`
/// announces this device over mDNS and listens for the others.
/// Saved fleet members are merged with discovered peers. Every change
/// to the combined list is published as [FleetChanged], which the
/// remote admin page hears over its socket, and the `fleet` command
/// answers the list on demand: this device first, then the others by
/// name.
///
/// The condition mirrors the remote manager's own, since what is
/// announced is the admin server's address and port: a kiosk that does
/// not serve the admin has nothing to be listed under.
///
/// The same announcer carries this kiosk's hostname (issue #470): while
/// the admin serves it answers to `<hostname>.local`, so the admin is
/// reachable by name from a laptop without the IP address. That part
/// runs with Find other kiosks off too; only the service records and
/// the listening for the others follow the switch.
///
/// The fleet part also waits for onboarding to finish (start URL set).
/// A kiosk still in the setup wizard cannot accept a fleet invite, since
/// the invite prompt lives on the kiosk screen, so it stays out of the
/// other kiosks' lists until then. The hostname still goes out, which
/// keeps the remote setup wizard reachable by name.
///
/// Over HTTPS with an imported certificate, the DNS name it covers is
/// announced too, and the other kiosks link here by that name instead of
/// the IP address their browser would reject the certificate under
/// (issue #833).
///
/// The Admin URL setting is announced the same way, and the other
/// kiosks' switchers open it ahead of both (issue #967).
///
/// The mDNS name setting is seeded here, the way the ESPHome node name
/// is at its server's first start: as soon as the device has a name and
/// the field is empty, the device name as a DNS label under `ks-` is
/// written into it, so the settings row holds the real name to copy.
/// Renaming the device afterwards leaves it alone; clearing the field
/// seeds it again.
class FleetManager extends Manager {
  FleetManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _methods = MethodChannel('kiosk_satellite/fleet');
  static const _stream = EventChannel('kiosk_satellite/fleet_stream');

  @override
  String get name => 'fleet';

  /// Whether this device should be announcing and listening right now.
  bool get enabled =>
      _settings.get(defs.remoteEnabled) &&
      _settings.get(defs.remotePassword).isNotEmpty &&
      _settings.get(defs.remoteFleetDiscovery) &&
      _settings.get(defs.startUrl).isNotEmpty;

  /// Whether the remote admin serves, which is when there is an address
  /// worth a name.
  bool get serving =>
      _settings.get(defs.remoteEnabled) &&
      _settings.get(defs.remotePassword).isNotEmpty;

  /// The name this kiosk answers to on the network, without `.local`:
  /// the mDNS name setting, else (before the seed lands) the device name
  /// as a DNS label under `ks-`. Empty when neither yields one, and then
  /// nothing is announced.
  String get hostname => defs.effectiveHostname(
    _settings.get(defs.deviceHostname),
    _settings.get(defs.deviceName),
  );

  /// The DNS name of the imported certificate the admin serves over
  /// HTTPS, empty for none. Read on every sync.
  String get certificateName => _certificateName;
  String _certificateName = '';

  /// Where the admin answers by name, or null with no name or no server.
  /// With an imported certificate that is the name it covers, since the
  /// browser rejects it under `.local`.
  String? get hostUrl {
    if (!serving) return null;
    final port = _settings.get(defs.remotePort).toInt();
    if (_certificateName.isNotEmpty) return 'https://$_certificateName:$port';
    if (hostname.isEmpty) return null;
    return '${_settings.get(defs.remoteTls) ? 'https' : 'http'}://$hostname.local:$port';
  }

  /// Whether the native announcer should run at all: for the fleet, for
  /// the hostname, or both.
  bool get active => enabled || (serving && hostname.isNotEmpty);

  /// Whether the native discovery is running.
  bool get running => _sub != null;

  /// The list as last heard: this device first, the rest by name.
  List<FleetDevice> get devices => List.unmodifiable(_devices);
  List<FleetDevice> _devices = const [];
  List<FleetDevice> _discovered = const [];

  StreamSubscription<Object?>? _sub;
  final _subs = <StreamSubscription<Object?>>[];

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'fleet',
        description:
            'The kiosks on this network with their remote admin on, as '
            'discovered or saved in the fleet: this device first, then the others by name, '
            'each with its name, address, admin port, version and url.',
        quiet: true,
        handler: (_) async {
          if (running) await _refresh();
          return CommandResult.ok({
            'enabled': enabled,
            // False where the mDNS port is taken: this kiosk announces but
            // hears nobody, so an empty list says nothing about the network.
            'listening': _listening,
            'devices': [for (final d in _devices) d.toJson()],
            // The name this kiosk answers to while the admin serves, and
            // the admin's address under it, for the Access cards.
            'hostname': serving ? hostname : '',
            'hostUrl': hostUrl,
            // Set when hostUrl is the certificate's name, not `.local`.
            'certificateName': serving ? _certificateName : '',
          });
        },
      ),
    );

    _subs.add(
      bus.on<SettingChanged>().listen((e) {
        // An import brought another id, or a clone's import cleared the
        // one it shared: announce under the new one.
        if (e.key == defs.fleetId.key) {
          _seedId().then((_) => _sync());
          return;
        }
        if (e.key == defs.fleetLeader.key ||
            e.key == defs.fleetFollowers.key ||
            e.key == defs.fleetLeaderInfo.key ||
            e.key == defs.fleetRoster.key) {
          _mergeDirectory();
        }
        if (e.key == defs.remoteEnabled.key ||
            e.key == defs.remotePassword.key ||
            e.key == defs.remotePort.key ||
            e.key == defs.remoteTls.key ||
            e.key == defs.remoteFleetDiscovery.key ||
            e.key == defs.remoteAdminUrl.key ||
            // Onboarding finishing is when the fleet part may start.
            e.key == defs.startUrl.key ||
            e.key == defs.deviceName.key ||
            e.key == defs.deviceHostname.key) {
          // The seed's own write comes back here, while the start that
          // carries it may still be under way: not a second start.
          if (e.key == defs.deviceHostname.key && _seedEcho) {
            _seedEcho = false;
            return;
          }
          _seed().then((_) => _sync());
        }
      }),
    );
    // An imported certificate brings the DNS name the others link to.
    _subs.add(bus.on<TlsIdentityChanged>().listen((_) => _sync()));
    // A network coming back is when the others need telling again: the
    // announcements they missed while it was down are gone.
    _subs.add(
      bus.on<NetworkStateChanged>().listen((e) {
        if (e.up && running) {
          _methods.invokeMethod<void>('nudge').catchError((_) {});
        }
      }),
    );
    await _seedId();
    await _seed();
    await _sync();
    _mergeDirectory();
  }

  /// Writes the Android ID into an empty fleet id, the id this kiosk has
  /// always announced, so a fleet formed before the setting keeps its
  /// trust. Left empty when the platform declines, and the announcer
  /// falls back to the Android ID itself.
  Future<void> _seedId() async {
    if (_settings.get(defs.fleetId).isNotEmpty) return;
    final id = await DeviceDetails.androidId();
    if (id == null || id.isEmpty) return;
    await _settings.set(defs.fleetId, id);
  }

  /// Fills an empty mDNS name from the device name. Nothing to write
  /// while the device has no usable name yet (the wizard's first page
  /// gives it one, and the change lands here).
  Future<void> _seed() async {
    if (_settings.get(defs.deviceHostname).isNotEmpty) return;
    final derived = defs.effectiveHostname('', _settings.get(defs.deviceName));
    if (derived.isEmpty) return;
    _seedEcho = true;
    await _settings.set(defs.deviceHostname, derived);
    log.info(name, 'mDNS name set to $derived from the device name');
  }

  /// Set across a seed write, so its change event is told apart from a
  /// user's edit.
  bool _seedEcho = false;

  Future<void> _sync() async {
    _certificateName = await _readCertificateName();
    if (active) {
      await _start();
    } else if (running) {
      await _stop();
    }
    _mergeDirectory();
  }

  /// The DNS name of the imported certificate the admin serves, or empty
  /// over HTTP, with the generated certificate or when it cannot be read.
  Future<String> _readCertificateName() async {
    if (!_settings.get(defs.remoteTls)) return '';
    try {
      return (await _settings.tls.load()).publicName ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _start() async {
    final host = hostname;
    final tls = _settings.get(defs.remoteTls);
    final dnsName = _certificateName;
    final adminUrl = _settings.get(defs.remoteAdminUrl);
    final id = _settings.get(defs.fleetId);
    final args = {
      if (id.isNotEmpty) 'id': id,
      'name': _settings.get(defs.deviceName),
      'port': _settings.get(defs.remotePort).toInt(),
      if (tls) 'tls': true,
      if (dnsName.isNotEmpty) 'dnsName': dnsName,
      if (adminUrl.isNotEmpty) 'adminUrl': adminUrl,
      'hostname': host,
      'fleet': enabled,
    };
    try {
      await _methods.invokeMethod<void>('start', args);
      final announced = host.isEmpty ? '' : ' as $host.local';
      if (!running) {
        _sub = _stream.receiveBroadcastStream().listen(
          _onSnapshot,
          onError: (Object e) => log.warn(name, 'discovery stream: $e'),
        );
        _warnedDeaf = false;
        _warnedClash = null;
        log.info(
          name,
          enabled
              ? 'announcing on :${args['port']}$announced and listening '
                    'for other kiosks'
              : 'announcing on :${args['port']}$announced',
        );
      } else if (host != _announcedHost && host.isNotEmpty) {
        log.info(name, 'now answering to $host.local');
      }
      _announcedHost = host;
    } on MissingPluginException {
      // No bridge (tests, a desktop run): nothing to discover with.
    } catch (e) {
      log.warn(name, 'could not start discovery: $e');
    }
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _methods.invokeMethod<void>('stop');
    } on MissingPluginException {
      // As above.
    } catch (e) {
      log.warn(name, 'could not stop discovery: $e');
    }
    _discovered = const [];
    _mergeDirectory();
    log.info(name, 'stopped');
  }

  Future<void> _refresh() async {
    try {
      final snap = await _methods.invokeMethod<Map<Object?, Object?>>(
        'snapshot',
      );
      if (snap != null) _onSnapshot(snap);
    } catch (_) {}
  }

  /// Said once per run: the socket could not have the mDNS port, so this
  /// kiosk announces but hears nobody.
  bool _warnedDeaf = false;

  /// Whether the socket has the mDNS port (see the warning below).
  bool _listening = true;

  /// The hostname last handed to the announcer, so a change is logged.
  String _announcedHost = '';

  /// The hostname another kiosk was heard answering to as well, warned
  /// about once: two kiosks under one name resolve to either of them.
  String? _warnedClash;

  void _onSnapshot(Object? raw) {
    if (raw is! Map) return;
    _listening = raw['listening'] != false;
    if (raw['listening'] == false && running && !_warnedDeaf) {
      _warnedDeaf = true;
      log.warn(
        name,
        'port 5353 is taken on this device, so other kiosks will not be '
        'heard; this one still announces itself',
      );
    }
    final clash = raw['hostClash'];
    if (clash is String && clash.isNotEmpty && clash != _warnedClash) {
      _warnedClash = clash;
      log.warn(
        name,
        'another kiosk also answers to $clash.local; give one of them '
        'a different mDNS name under Settings, Device',
      );
    }
    final self = FleetDevice.fromMap(
      (raw['self'] as Map?)?.cast<Object?, Object?>(),
      self: true,
    );
    final peers = <FleetDevice>[];
    for (final p in (raw['peers'] as List? ?? const [])) {
      if (p is! Map) continue;
      final d = FleetDevice.fromMap(p.cast<Object?, Object?>());
      if (d != null) peers.add(d);
    }
    _discovered = [?self, ...peers];
    _mergeDirectory();
  }

  Object? _stored(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  void _mergeDirectory() {
    if (!serving) {
      _apply(const []);
      return;
    }
    final byId = <String, FleetDevice>{};
    final selfId = _discovered.where((d) => d.self).firstOrNull?.id;
    void add(Object? raw) {
      final device = FleetDevice.directoryEntry(raw);
      if (device != null) byId[device.id] = device;
    }

    if (enabled) {
      if (_settings.get(defs.fleetLeader)) {
        final followers = _stored(_settings.get(defs.fleetFollowers));
        if (followers is List) {
          for (final follower in followers) {
            if (follower is Map &&
                follower['token'] is String &&
                (follower['token'] as String).isNotEmpty &&
                follower['invite'] == null &&
                follower['declined'] != true) {
              add(follower);
            }
          }
        }
      } else {
        final leader = FleetDevice.directoryEntry(
          _stored(_settings.get(defs.fleetLeaderInfo)),
        );
        if (leader != null) {
          final roster = _stored(_settings.get(defs.fleetRoster));
          // Wait for local identity before loading a roster that includes
          // this kiosk, so intercom never mistakes itself for a peer.
          if (roster is List && selfId != null) {
            for (final member in roster) {
              if (member is Map && member['id'] != selfId) add(member);
            }
          }
          // The invitation records the address that reached this kiosk.
          byId[leader.id] = leader;
        }
      }
    }
    // Fresh discovery wins over saved addresses and identifies this kiosk.
    for (final device in _discovered) {
      byId[device.id] = device;
    }
    final list = byId.values.toList()
      ..sort((a, b) {
        if (a.self != b.self) return a.self ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    _apply(list);
  }

  void _apply(List<FleetDevice> list) {
    final before = [for (final d in _devices) d.toJson()];
    final after = [for (final d in list) d.toJson()];
    _devices = list;
    if (_same(before, after)) return;
    final others = list.where((d) => !d.self).length;
    log.info(
      name,
      '$others other kiosk${others == 1 ? '' : 's'} on the network',
    );
    bus.publish(FleetChanged(devices: after));
  }

  static bool _same(
    List<Map<String, Object?>> a,
    List<Map<String, Object?>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (x.length != y.length) return false;
      for (final k in x.keys) {
        if (x[k] != y[k]) return false;
      }
    }
    return true;
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    if (running) await _stop();
  }
}
