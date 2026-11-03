import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/fleet/fleet_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The kiosk switcher's discovery: the native bridge announces this device
/// and streams the kiosks it hears; the manager runs it only while the
/// remote admin serves and Find other kiosks is on, answers the `fleet`
/// command with this device first and the rest by name, and publishes a
/// change as an event the remote admin page hears.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  var listens = 0;
  var cancels = 0;
  MockStreamHandlerEventSink? sink;
  Map<String, Object?> snapshot = {'self': null, 'peers': const []};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('kiosk_satellite/fleet'),
          (call) async {
            calls.add(call);
            return switch (call.method) {
              'snapshot' => snapshot,
              _ => null,
            };
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('kiosk_satellite/fleet_stream'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              listens++;
              sink = events;
            },
            onCancel: (arguments) {
              cancels++;
              sink = null;
            },
          ),
        );
  });

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;
  late FleetManager fleet;
  late List<FleetChanged> events;

  Future<void> build(Map<String, Object> initial) async {
    calls.clear();
    listens = 0;
    cancels = 0;
    sink = null;
    snapshot = {'self': null, 'peers': const []};
    SharedPreferences.setMockInitialValues(initial);
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    events = [];
    bus.on<FleetChanged>().listen(events.add);
    fleet = FleetManager(bus, commands, log, settings);
    addTearDown(fleet.dispose);
    await fleet.init();
  }

  Future<void> pump() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  const serving = {
    'ks.remote.enabled': true,
    'ks.remote.password': 'secret',
    'ks.remote.port': 2324,
    'ks.device.name': 'Living Room',
    // Onboarding done: the fleet part waits for it.
    'ks.browser.start_url': 'http://ha.local:8123/lovelace',
  };

  const self = {
    'id': 'aaaa',
    'name': 'Living Room',
    'version': '2026.9.18',
    'address': '192.168.1.30',
    'port': 2324,
  };

  test('announces with the device name and admin port while serving', () async {
    await build(serving);
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments, {
      'name': 'Living Room',
      'port': 2324,
      // The device name as a DNS label under ks-, seeded at init.
      'hostname': 'ks-living-room',
      'fleet': true,
    });
    expect(listens, 1);
    expect(fleet.running, isTrue);
    expect(fleet.hostname, 'ks-living-room');
    expect(fleet.hostUrl, 'http://ks-living-room.local:2324');
  });

  test('the fleet id is seeded from the Android ID and announced', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const details = MethodChannel('kiosk_satellite/device_details');
    messenger.setMockMethodCallHandler(
      details,
      (call) async => call.method == 'androidId' ? 'a1b2c3' : null,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(details, null));
    await build(serving);
    expect(settings.get(defs.fleetId), 'a1b2c3');
    expect(
      calls.lastWhere((c) => c.method == 'start').arguments['id'],
      'a1b2c3',
    );
    // A backup restored with Replace brings the id of the kiosk it
    // replaces, and the announcement goes out under it.
    await settings.set(defs.fleetId, 'feed42');
    await pump();
    expect(calls.last.method, 'start');
    expect(calls.last.arguments['id'], 'feed42');
    // A clone's import cleared it: the Android ID comes back.
    await settings.set(defs.fleetId, '');
    await pump();
    expect(settings.get(defs.fleetId), 'a1b2c3');
    expect(calls.last.arguments['id'], 'a1b2c3');
  });

  test('a seeded fleet id is kept', () async {
    await build({...serving, 'ks.fleet.id': 'feed42'});
    expect(settings.get(defs.fleetId), 'feed42');
    expect(
      calls.singleWhere((c) => c.method == 'start').arguments['id'],
      'feed42',
    );
  });

  test('the mDNS name is seeded from the device name and then kept', () async {
    await build(serving);
    // Written into the setting, so the row holds the name to copy.
    expect(settings.get(defs.deviceHostname), 'ks-living-room');
    // A rename leaves it alone, as with the ESPHome node name.
    await settings.set(defs.deviceName, 'Kitchen');
    await pump();
    expect(settings.get(defs.deviceHostname), 'ks-living-room');
    expect(calls.last.arguments['hostname'], 'ks-living-room');
    // Clearing it takes the device name again.
    await settings.set(defs.deviceHostname, '');
    await pump();
    expect(settings.get(defs.deviceHostname), 'ks-kitchen');
    expect(calls.last.arguments['hostname'], 'ks-kitchen');
  });

  test(
    'no seed without a usable device name, then one when it comes',
    () async {
      await build({'ks.device.name': '!!!'});
      expect(settings.get(defs.deviceHostname), isEmpty);
      await settings.set(defs.deviceName, 'Hall');
      await pump();
      expect(settings.get(defs.deviceHostname), 'ks-hall');
    },
  );

  test('a typed hostname wins and is a DNS label', () async {
    await build({...serving, 'ks.device.hostname': 'Kitchen Tablet'});
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments['hostname'], 'kitchen-tablet');
    expect(fleet.hostUrl, 'http://kitchen-tablet.local:2324');
    final r = await commands.execute('fleet', const {});
    expect((r.data as Map)['hostname'], 'kitchen-tablet');
    expect((r.data as Map)['hostUrl'], 'http://kitchen-tablet.local:2324');
    // Typed on a settings page, the label is what gets stored.
    await settings.set(defs.deviceHostname, 'Hall Way (2)');
    expect(settings.get(defs.deviceHostname), 'hall-way-2');
  });

  test('the hostname is announced with Find other kiosks off', () async {
    await build({...serving, 'ks.remote.fleet_discovery': false});
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments, {
      'name': 'Living Room',
      'port': 2324,
      'hostname': 'ks-living-room',
      'fleet': false,
    });
    expect(fleet.enabled, isFalse);
    expect(fleet.running, isTrue);
    final r = await commands.execute('fleet', const {});
    expect((r.data as Map)['enabled'], isFalse);
    expect((r.data as Map)['hostUrl'], 'http://ks-living-room.local:2324');
  });

  test('a new hostname goes out at once', () async {
    await build(serving);
    calls.clear();
    await settings.set(defs.deviceHostname, 'hall');
    await pump();
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments['hostname'], 'hall');
    expect(listens, 1);
  });

  test('nothing announced by name without a usable name', () async {
    await build({...serving, 'ks.device.name': '!!!'});
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments['hostname'], '');
    expect(fleet.hostUrl, isNull);
    // And with the fleet off too there is nothing to run for.
    await build({
      ...serving,
      'ks.device.name': '!!!',
      'ks.remote.fleet_discovery': false,
    });
    expect(calls.where((c) => c.method == 'start'), isEmpty);
    expect(fleet.running, isFalse);
  });

  test('stays off without remote management or a password', () async {
    await build({'ks.remote.enabled': true, 'ks.remote.port': 2324});
    expect(calls.where((c) => c.method == 'start'), isEmpty);
    expect(fleet.running, isFalse);

    await build({'ks.remote.password': 'secret'});
    expect(calls.where((c) => c.method == 'start'), isEmpty);
  });

  test('the switch takes the fleet off the wire, not the hostname', () async {
    await build(serving);
    await settings.set(defs.remoteFleetDiscovery, false);
    await pump();
    // Still running, for the hostname: the announcer is told the fleet
    // part is off.
    expect(calls.last.method, 'start');
    expect(calls.last.arguments['fleet'], isFalse);
    expect(cancels, 0);
    expect(fleet.running, isTrue);
    expect(fleet.enabled, isFalse);

    await settings.set(defs.remoteFleetDiscovery, true);
    await pump();
    expect(calls.last.method, 'start');
    expect(calls.last.arguments['fleet'], isTrue);
    expect(fleet.running, isTrue);
  });

  test('the fleet waits for onboarding, the hostname does not', () async {
    await build({...serving, 'ks.browser.start_url': ''});
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments['hostname'], 'ks-living-room');
    expect(start.arguments['fleet'], isFalse);
    expect(fleet.enabled, isFalse);

    // The wizard's last step sets the start URL.
    await settings.set(defs.startUrl, 'http://ha.local:8123/lovelace');
    await pump();
    expect(calls.last.method, 'start');
    expect(calls.last.arguments['fleet'], isTrue);
    expect(fleet.enabled, isTrue);
  });

  test('the switch stops it outright with nothing to answer to', () async {
    await build({...serving, 'ks.device.name': '!!!'});
    await settings.set(defs.remoteFleetDiscovery, false);
    await pump();
    expect(calls.last.method, 'stop');
    expect(cancels, 1);
    expect(fleet.running, isFalse);

    await settings.set(defs.remoteFleetDiscovery, true);
    await pump();
    expect(calls.last.method, 'start');
    expect(fleet.running, isTrue);
  });

  test('a rename goes out at once', () async {
    await build(serving);
    calls.clear();
    await settings.set(defs.deviceName, 'Kitchen');
    await pump();
    final start = calls.singleWhere((c) => c.method == 'start');
    expect(start.arguments, {
      'name': 'Kitchen',
      'port': 2324,
      // Seeded at init and kept through the rename.
      'hostname': 'ks-living-room',
      'fleet': true,
    });
    // Still the one stream: a restart is a re-announce, not a new listen.
    expect(listens, 1);
  });

  test('lists this device first and the others by name', () async {
    await build(serving);
    // The command re-reads the native snapshot, so it holds the same.
    snapshot = {
      'self': self,
      'peers': [
        {
          'id': 'cccc',
          'name': 'kitchen',
          'version': '2026.9.17',
          'address': '192.168.1.70',
          'port': 2324,
        },
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    };
    sink!.success(snapshot);
    await pump();

    final r = await commands.execute('fleet', const {});
    expect(r.ok, isTrue);
    final data = r.data as Map;
    expect(data['enabled'], isTrue);
    final devices = (data['devices'] as List).cast<Map>();
    expect(devices.map((d) => d['name']), [
      'Living Room',
      'Bedroom',
      'kitchen',
    ]);
    expect(devices.first['self'], isTrue);
    expect(devices[1]['self'], isFalse);
    expect(devices[1]['url'], 'http://192.168.1.71:2324');
    expect(devices[2]['version'], '2026.9.17');
  });

  test('publishes a change as an event the remote page hears', () async {
    await build(serving);
    sink!.success({
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    });
    await pump();
    expect(events, hasLength(1));
    expect(events.single.wireName, 'fleet');
    final listed = events.single.toJson()['devices'] as List;
    expect(listed, hasLength(2));

    // The same list again is not a change.
    sink!.success({
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    });
    await pump();
    expect(events, hasLength(1));

    // A peer gone is.
    sink!.success({'self': self, 'peers': const []});
    await pump();
    expect(events, hasLength(2));
    expect((events.last.toJson()['devices'] as List), hasLength(1));
  });

  test('the fleet command reads the native snapshot while running', () async {
    await build(serving);
    snapshot = {
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    };
    final r = await commands.execute('fleet', const {});
    final devices = (r.data as Map)['devices'] as List;
    expect(devices, hasLength(2));
    expect(calls.last.method, 'snapshot');
  });

  test('the remote admin switching off empties the list', () async {
    await build(serving);
    sink!.success({
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
        },
      ],
    });
    await pump();
    await settings.set(defs.remoteEnabled, false);
    await pump();
    expect(fleet.running, isFalse);
    final r = await commands.execute('fleet', const {});
    expect((r.data as Map)['enabled'], isFalse);
    expect((r.data as Map)['devices'], isEmpty);
    expect(events.last.toJson()['devices'], isEmpty);
  });

  test('saved members survive missing mDNS without exposing tokens', () async {
    final bedroom = {
      'id': 'bbbb',
      'name': 'Bedroom',
      'version': '2026.9.18',
      'address': '192.168.1.71',
      'port': 2324,
      'token': 'private-fleet-token',
    };
    await build({
      ...serving,
      'ks.fleet.leader': true,
      'ks.fleet.followers': jsonEncode([
        bedroom,
        {...bedroom, 'id': 'pending', 'invite': 'nonce'},
        {...bedroom, 'id': 'declined', 'declined': true},
        {...bedroom, 'id': 'left', 'token': null},
      ]),
    });
    snapshot = {'self': self, 'peers': const []};
    var result = await commands.execute('fleet', const {});
    expect(fleet.devices.map((d) => d.id), ['aaaa', 'bbbb']);
    expect(jsonEncode(result.data), isNot(contains('private-fleet-token')));
    expect(jsonEncode(result.data), isNot(contains('nonce')));

    // Discovery supplies a fresh address without making a duplicate.
    snapshot = {
      'self': self,
      'peers': [
        {...bedroom, 'address': '192.168.1.72'},
      ],
    };
    await commands.execute('fleet', const {});
    expect(fleet.devices.last.address, '192.168.1.72');
    expect(fleet.devices, hasLength(2));

    // The leader saves the new address after polling the member.
    await settings.set(
      defs.fleetFollowers,
      jsonEncode([
        {...bedroom, 'address': '192.168.1.72'},
      ]),
    );
    snapshot = {'self': self, 'peers': const []};
    result = await commands.execute('fleet', const {});
    expect(fleet.devices.last.address, '192.168.1.72');
    expect((result.data as Map)['devices'], hasLength(2));
    await settings.set(defs.fleetFollowers, '');
    await pump();
    expect(fleet.devices.map((d) => d.id), ['aaaa']);
    expect(events.last.devices, hasLength(1));
  });

  test(
    'a follower restores its leader and siblings without discovery',
    () async {
      final leader = {...self, 'id': 'lead', 'name': 'Leader'};
      final sibling = {...self, 'id': 'sibling', 'name': 'Bedroom'};
      await build({
        ...serving,
        'ks.fleet.leader_info': jsonEncode(leader),
        'ks.fleet.roster': jsonEncode([self, leader, sibling]),
      });
      expect(fleet.devices.map((d) => d.id), ['lead']);
      snapshot = {'self': self, 'peers': const []};
      await commands.execute('fleet', const {});
      expect(fleet.devices.map((d) => d.id), ['aaaa', 'sibling', 'lead']);
      expect(fleet.devices.where((d) => d.self), hasLength(1));

      await settings.set(defs.fleetRoster, jsonEncode([self, leader]));
      await pump();
      expect(fleet.devices.map((d) => d.id), ['aaaa', 'lead']);
      // A stale roster cannot keep a former fleet in the switcher.
      await settings.set(defs.fleetLeaderInfo, '');
      await pump();
      expect(fleet.devices.map((d) => d.id), ['aaaa']);
    },
  );

  group('a kiosk with an imported certificate (issue #833)', () {
    const tls = MethodChannel('kiosk_satellite/tls');
    Map<String, Object?> certificate = {};

    setUp(() {
      certificate = {
        'certificate': File('test/fixtures/tls/cert.pem').readAsStringSync(),
        'privateKey': File('test/fixtures/tls/key.pem').readAsStringSync(),
        'notAfter': DateTime.utc(2036).millisecondsSinceEpoch,
        'imported': true,
        'dnsNames': ['*.example.com', 'kitchen.local', 'Kitchen.Example.com'],
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(tls, (call) async => certificate);
    });
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(tls, null),
    );

    test('announces the DNS name its certificate covers', () async {
      await build({...serving, 'ks.remote.tls': true});
      final start = calls.lastWhere((c) => c.method == 'start');
      expect((start.arguments as Map)['dnsName'], 'kitchen.example.com');
    });

    test('the Access cards show the name its certificate covers', () async {
      await build({...serving, 'ks.remote.tls': true});
      expect(fleet.hostUrl, 'https://kitchen.example.com:2324');
      final r = await commands.execute('fleet', const {});
      expect((r.data as Map)['hostUrl'], 'https://kitchen.example.com:2324');
      expect((r.data as Map)['certificateName'], 'kitchen.example.com');
    });

    test('announces no DNS name with the generated certificate', () async {
      certificate = {...certificate, 'imported': false};
      await build({...serving, 'ks.remote.tls': true});
      final start = calls.lastWhere((c) => c.method == 'start');
      expect((start.arguments as Map).containsKey('dnsName'), isFalse);
      expect(fleet.hostUrl, 'https://ks-living-room.local:2324');
      final r = await commands.execute('fleet', const {});
      expect((r.data as Map)['certificateName'], '');
    });

    test('announces no DNS name over HTTP', () async {
      await build(serving);
      final start = calls.lastWhere((c) => c.method == 'start');
      expect((start.arguments as Map).containsKey('dnsName'), isFalse);
    });

    test('a new certificate goes out at once', () async {
      certificate = {...certificate, 'imported': false};
      await build({...serving, 'ks.remote.tls': true});
      calls.clear();
      certificate = {
        ...certificate,
        'imported': true,
        'dnsNames': ['office.example.com'],
      };
      await settings.tls.change('import');
      await pump();
      final start = calls.lastWhere((c) => c.method == 'start');
      expect((start.arguments as Map)['dnsName'], 'office.example.com');
    });
  });

  test('the switcher links an HTTPS kiosk by its DNS name', () async {
    await build(serving);
    snapshot = {
      'self': self,
      'peers': [
        {
          'id': 'bbbb',
          'name': 'Bedroom',
          'version': '2026.9.18',
          'address': '192.168.1.71',
          'port': 2324,
          'tls': true,
          'dnsName': 'bedroom.example.com',
        },
        {
          'id': 'cccc',
          'name': 'Kitchen',
          'version': '2026.9.18',
          'address': '192.168.1.70',
          'port': 2324,
          'dnsName': 'kitchen.example.com',
        },
        {
          'id': 'dddd',
          'name': 'Office',
          'version': '2026.9.18',
          'address': '192.168.1.72',
          'port': 2324,
          'tls': true,
          'dnsName': 'not a name/',
        },
      ],
    };
    final r = await commands.execute('fleet', const {});
    final devices = (r.data as Map)['devices'] as List;
    final urls = {for (final d in devices.cast<Map>()) d['id']: d['url']};
    expect(urls['bbbb'], 'https://bedroom.example.com:2324');
    // Over HTTP the address still works, so it stays.
    expect(urls['cccc'], 'http://192.168.1.70:2324');
    // A name that is not a hostname is dropped.
    expect(urls['dddd'], 'https://192.168.1.72:2324');
    // The address is kept for everything else that reaches the kiosk.
    expect(
      fleet.devices.firstWhere((d) => d.id == 'bbbb').address,
      '192.168.1.71',
    );
  });

  test('a saved member keeps its DNS name', () async {
    final leader = {
      ...self,
      'id': 'lead',
      'name': 'Leader',
      'tls': true,
      'dnsName': 'leader.example.com',
    };
    await build({...serving, 'ks.fleet.leader_info': jsonEncode(leader)});
    expect(fleet.devices.single.url, 'https://leader.example.com:2324');
    expect(fleet.devices.single.toDirectory()['dnsName'], 'leader.example.com');
  });

  group('an Admin URL (issue #967)', () {
    test('is stored as the origin alone', () async {
      await build(serving);
      await settings.set(defs.remoteAdminUrl, ' https://Kiosk.Example.com/ ');
      expect(settings.get(defs.remoteAdminUrl), 'https://kiosk.example.com');
      await settings.set(defs.remoteAdminUrl, 'http://kstest.lan:8080');
      expect(settings.get(defs.remoteAdminUrl), 'http://kstest.lan:8080');
    });

    test('refuses a path, credentials or another scheme', () {
      for (final bad in [
        'kiosk.example.com',
        'ftp://kiosk.example.com',
        'https://kiosk.example.com/admin',
        'https://kiosk.example.com/?a=1',
        'https://user:pw@kiosk.example.com',
        'https://not_a_host',
        'https://${'a' * 250}.com',
      ]) {
        expect(defs.validateAdminUrl(bad), isNotNull, reason: bad);
      }
      expect(defs.validateAdminUrl(''), isNull);
      expect(defs.validateAdminUrl('https://kiosk.example.com:8443'), isNull);
      expect(
        defs.validateAdminUrl('https://kiosk.example.com/admin'),
        startsWith('Enter only the address'),
      );
    });

    test('is announced, and a change goes out at once', () async {
      await build(serving);
      var start = calls.lastWhere((c) => c.method == 'start');
      expect((start.arguments as Map).containsKey('adminUrl'), isFalse);
      calls.clear();
      await settings.set(defs.remoteAdminUrl, 'https://kstest.example.com');
      await pump();
      start = calls.lastWhere((c) => c.method == 'start');
      expect(
        (start.arguments as Map)['adminUrl'],
        'https://kstest.example.com',
      );
    });

    test(
      'the switcher opens it ahead of the DNS name and the address',
      () async {
        await build(serving);
        snapshot = {
          'self': {...self, 'adminUrl': 'https://living.example.com'},
          'peers': [
            {
              'id': 'bbbb',
              'name': 'Bedroom',
              'version': '2026.10.21',
              'address': '192.168.1.71',
              'port': 2324,
              'tls': true,
              'dnsName': 'bedroom.example.com',
              'adminUrl': 'https://bedroom.proxy.example.com',
            },
            {
              'id': 'cccc',
              'name': 'Kitchen',
              'version': '2026.10.21',
              'address': '192.168.1.70',
              'port': 2324,
              'adminUrl': 'javascript:alert(1)',
            },
          ],
        };
        final r = await commands.execute('fleet', const {});
        final devices = (r.data as Map)['devices'] as List;
        final byId = {for (final d in devices.cast<Map>()) d['id']: d};
        expect(byId['aaaa']!['url'], 'https://living.example.com');
        expect(byId['bbbb']!['url'], 'https://bedroom.proxy.example.com');
        // Anything that is not a plain web origin is dropped.
        expect(byId['cccc']!['url'], 'http://192.168.1.70:2324');
        expect(byId['cccc']!.containsKey('adminUrl'), isFalse);
        // The address and port stay for fleet calls and the intercom.
        expect(byId['bbbb']!['address'], '192.168.1.71');
        expect(byId['bbbb']!['port'], 2324);
      },
    );

    test('travels in the fleet directory', () async {
      final leader = {
        ...self,
        'id': 'lead',
        'name': 'Leader',
        'adminUrl': 'https://leader.example.com',
      };
      await build({...serving, 'ks.fleet.leader_info': jsonEncode(leader)});
      expect(fleet.devices.single.url, 'https://leader.example.com');
      expect(
        fleet.devices.single.toDirectory()['adminUrl'],
        'https://leader.example.com',
      );
    });
  });
}
