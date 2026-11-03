import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/fleet/fleet_sync_manager.dart';
import 'package:kiosk_satellite/managers/plugins/fleet_plugin_host.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fleet Management: what travels and what stays per kiosk, the leader's
/// push and the follower's apply, the invitation on the follower and the
/// token it mints, the update fan out. The wire between two kiosks is a
/// fake HTTP client here; the endpoints themselves are covered by the
/// remote server test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late EventBus bus;
  late CommandRegistry commands;
  late Logger log;
  late SettingsManager settings;
  late FleetSyncManager fleet;
  var built = false;
  late List<http.Request> sent;
  late Map<String, Object? Function(http.Request)> answers;
  late List<Map<String, Object?>> peers;
  List<Set<String>> formerHistory = const [];
  int changes = 0;

  /// This kiosk as discovery announces it and the others it hears.
  Map<String, Object?> fleetSnapshot() => {
    'enabled': true,
    'listening': true,
    'devices': [
      {
        'id': 'me',
        'name': 'Living Room',
        'version': '2026.9.19',
        'address': '192.168.1.30',
        'port': 2324,
        'self': true,
      },
      ...peers,
    ],
  };

  // What getUpdateStatus reports as the uploaded APK, when a test set one,
  // and whether an install is under way.
  Map<String, Object?>? uploaded;
  var installing = false;

  Future<void> build({
    Map<String, Object> prefs = const {},
    FleetPluginHost? pluginHost,
  }) async {
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://ha.local:8123/lovelace/0',
      'ks.remote.enabled': true,
      'ks.remote.password': 'secret',
      'ks.remote.fleet_discovery': true,
      ...prefs,
    });
    bus = EventBus();
    log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    sent = [];
    // A kiosk that answers who it is: what the invitation probe needs.
    answers = {
      'GET /api/fleet/identity': (_) => {
        'id': 'bed',
        'name': 'Bedroom',
        'version': '2026.9.19',
        'leader': false,
      },
    };
    changes = 0;
    bus.on<FleetSyncChanged>().listen((_) => changes++);
    commands.register(
      Command(
        name: 'fleet',
        description: 'discovery stub',
        handler: (_) async => CommandResult.ok(fleetSnapshot()),
      ),
    );
    commands.register(
      Command(
        name: 'issueFleetToken',
        description: 'token stub',
        handler: (p) async => CommandResult.ok('tok-${p['leader']}'),
      ),
    );
    uploaded = null;
    installing = false;
    commands.register(
      Command(
        name: 'getUpdateStatus',
        description: 'update stub',
        handler: (_) async => CommandResult.ok({
          'currentVersion': '2026.9.19',
          'availableVersion': null,
          'progress': null,
          'installing': installing,
          'uploaded': uploaded,
        }),
      ),
    );
    fleet = FleetSyncManager(bus, commands, log, settings)
      ..plugins = pluginHost
      ..formerDefaultExcluded = formerHistory
      ..clientFactory = () => MockClient((req) async {
        sent.add(req);
        final key = '${req.method} ${req.url.path}';
        final answer = answers[key];
        if (answer == null) return http.Response('not found', 404);
        var out = answer(req);
        // A held answer, for a tick caught halfway.
        if (out is Future) out = await out;
        if (out is http.Response) return out;
        return http.Response(jsonEncode(out), 200);
      });
    await fleet.init();
    built = true;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 400));

  setUp(() {
    formerHistory = const [];
    peers = [
      {
        'id': 'bed',
        'name': 'Bedroom',
        'version': '2026.9.19',
        'address': '192.168.1.71',
        'port': 2324,
        'self': false,
      },
    ];
  });

  tearDown(() async {
    if (!built) return;
    built = false;
    await fleet.dispose();
  });

  Map<String, Object?> gesture(
    String id,
    String action, {
    String command = 'show',
  }) => {
    'id': id,
    'trigger': {'type': 'corner_taps', 'corner': 'tl', 'taps': 3},
    'action': {
      'type': action,
      if (action == 'plugin_action') ...{
        'pluginId': 'hello-world',
        'command': command,
      },
    },
  };

  group('manual fleet invitations', () {
    test('finds HTTPS without discovery and never sends credentials', () async {
      peers.clear();
      await build(prefs: {'ks.fleet.leader': true});
      final identity = answers['GET /api/fleet/identity']!;
      answers['GET /api/fleet/identity'] = (request) {
        if (request.url.scheme == 'http') {
          throw const SocketException(
            'HTTPS listener closed plaintext request',
          );
        }
        return identity(request);
      };
      final found = await commands.execute('fleetLookup', {
        'address': '192.168.1.80',
      });
      expect(found.ok, isTrue, reason: found.error);
      expect((found.data as Map)['tls'], isTrue);
      expect(sent.map((r) => r.url.scheme), ['http', 'https']);
      expect(sent.every((r) => r.method == 'GET'), isTrue);
      expect(
        sent.every((r) => !r.headers.containsKey('authorization')),
        isTrue,
      );
      expect(fleet.followers, isEmpty);
    });

    test('does not retry an advertised HTTPS kiosk over HTTP', () async {
      peers.single['tls'] = true;
      await build(prefs: {'ks.fleet.leader': true});
      answers['GET /api/fleet/identity'] = (_) =>
          throw const SocketException('Kiosk unavailable');
      final found = await commands.execute('fleetLookup', {
        'address': '192.168.1.71',
      });
      expect(found.ok, isFalse);
      expect(sent.map((r) => r.url.scheme), ['https']);
      expect(fleet.followers, isEmpty);
    });

    test(
      'looks up an IP and invites without discovery or syncing before acceptance',
      () async {
        peers.clear();
        await build(prefs: {'ks.fleet.leader': true});
        final found = await commands.execute('fleetLookup', {
          'address': ' 192.168.1.80 ',
          'port': '2345',
        });
        expect(found.ok, isTrue, reason: found.error);
        final kiosk = found.data as Map;
        expect(kiosk['id'], 'bed');
        expect(kiosk['name'], 'Bedroom');
        expect(kiosk['address'], '192.168.1.80');
        expect(kiosk['port'], 2345);
        expect(fleet.followers, isEmpty);
        expect(sent.every((r) => r.method == 'GET'), isTrue);
        answers['POST /api/fleet/invite'] = (_) => {
          'ok': true,
          'data': {'pending': true},
        };
        final invited = await commands.execute('fleetInvite', {
          'id': kiosk['id'],
          'address': kiosk['address'],
          'port': kiosk['port'],
          'profile': 'updates-only',
        });
        expect(invited.ok, isTrue, reason: invited.error);
        final follower = fleet.followers.single;
        expect(follower.address, '192.168.1.80');
        expect(follower.port, 2345);
        expect(follower.profile, 'updates-only');
        expect(follower.token, isNull);
        expect(follower.invite, isNotEmpty);
        expect(sent.where((r) => r.url.path == '/api/fleet/apply'), isEmpty);
        expect(
          sent.where((r) => r.url.path == '/api/fleet/identity'),
          hasLength(2),
        );
        final duplicate = await commands.execute('fleetLookup', {
          'address': '192.168.1.80',
        });
        expect(duplicate.error, 'This kiosk already belongs to this fleet.');

        answers['GET /api/fleet/invite/${follower.invite}'] = (_) => {
          'status': 'accepted',
          'token': 'accepted-token',
        };
        answers['GET /api/fleet/status'] = (_) => {
          'id': 'bed',
          'leaderId': 'me',
          'version': '2026.9.19',
        };
        answers['POST /api/fleet/apply'] = (_) => {
          'ok': true,
          'data': {'applied': 0},
        };
        await commands.execute('fleetSyncNow', const {});
        expect(follower.token, 'accepted-token');
        final push = sent.singleWhere((r) => r.url.path == '/api/fleet/apply');
        expect((jsonDecode(push.body) as Map)['settings'], isEmpty);
        expect(push.url.port, 2345);
      },
    );

    test('rejects invalid inputs before contacting any host', () async {
      await build(prefs: {'ks.fleet.leader': true});
      for (final params in [
        {'address': ''},
        {'address': 'http://192.168.1.80'},
        {'address': 'not-an-ip'},
        {'address': '192.168.1.80', 'port': 0},
        {'address': '192.168.1.80', 'port': '65536'},
        {'address': '192.168.1.80', 'port': 23.5},
      ]) {
        expect((await commands.execute('fleetLookup', params)).ok, isFalse);
      }
      expect(sent, isEmpty);
      expect(fleet.followers, isEmpty);
    });

    test(
      'IPv6 addresses use bracketed URLs and the default admin port',
      () async {
        peers.clear();
        await build(prefs: {'ks.fleet.leader': true});
        final found = await commands.execute('fleetLookup', {
          'address': '2001:db8::80',
        });
        expect(found.ok, isTrue, reason: found.error);
        expect(
          sent.single.url.toString(),
          'http://[2001:db8::80]:2324/api/fleet/identity',
        );
        answers['POST /api/fleet/invite'] = (_) => {
          'ok': true,
          'data': {'pending': true},
        };
        final invited = await commands.execute('fleetInvite', {
          'id': 'bed',
          'address': '2001:db8::80',
        });
        expect(invited.ok, isTrue, reason: invited.error);
        expect(fleet.followers.single.url, 'http://[2001:db8::80]:2324');
      },
    );

    test(
      'refuses self, malformed identities, leaders and kiosks following another leader',
      () async {
        await build(prefs: {'ks.fleet.leader': true});
        final identity = {
          'id': 'bed',
          'name': 'Bedroom',
          'version': '2026.9.19',
          'leader': false,
        };
        for (final answer in [
          {},
          {...identity, 'id': 'me'},
          {...identity, 'leader': true},
          {...identity, 'follows': 'Another leader'},
          http.Response('no fleet endpoint', 404),
        ]) {
          answers['GET /api/fleet/identity'] = (_) => answer;
          expect(
            (await commands.execute('fleetLookup', {
              'address': '192.168.1.80',
            })).ok,
            isFalse,
          );
        }
        expect(sent.where((r) => r.method == 'POST'), isEmpty);
        expect(fleet.followers, isEmpty);
      },
    );

    test(
      'rechecks the identity and profile before sending an invitation',
      () async {
        await build(prefs: {'ks.fleet.leader': true});
        final found = await commands.execute('fleetLookup', {
          'address': '192.168.1.80',
        });
        expect(found.ok, isTrue);
        final invalidProfile = await commands.execute('fleetInvite', {
          'id': 'bed',
          'address': '192.168.1.80',
          'profile': 'removed-profile',
        });
        expect(invalidProfile.error, 'No such profile');
        answers['GET /api/fleet/identity'] = (_) => {
          'id': 'someone-else',
          'name': 'Other kiosk',
          'version': '2026.9.19',
          'leader': false,
        };
        final changed = await commands.execute('fleetInvite', {
          'id': 'bed',
          'address': '192.168.1.80',
        });
        expect(
          changed.error,
          'The address belongs to a different kiosk or fleet',
        );
        expect(sent.where((r) => r.method == 'POST'), isEmpty);
        expect(fleet.followers, isEmpty);
      },
    );

    test('Invite again uses a saved address when discovery is empty', () async {
      peers.clear();
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.80',
              'port': 2345,
              'token': 'old-token',
            },
          ]),
        },
      );
      answers['GET /api/fleet/identity'] = (_) => {
        'id': 'bed',
        'name': 'Bedroom',
        'version': '2026.9.19',
        'leader': false,
        'follows': 'Living Room',
      };
      answers['POST /api/fleet/invite'] = (_) => {
        'ok': true,
        'data': {'token': 'new-token'},
      };
      final result = await commands.execute('fleetInvite', {'id': 'bed'});
      expect(result.ok, isTrue, reason: result.error);
      expect(fleet.followers, hasLength(1));
      expect(fleet.followers.single.token, 'new-token');
      expect(sent.every((r) => r.url.port == 2345), isTrue);
    });
  });

  test(
    'polls saved followers and shares membership across versions without mDNS',
    () async {
      peers.clear();
      final bedroom = {
        'id': 'bed',
        'name': 'Bedroom',
        'address': '192.168.1.71',
        'port': 2324,
        'token': 'private-token',
      };
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            bedroom,
            {...bedroom, 'id': 'pending', 'invite': 'private-nonce'},
            {...bedroom, 'id': 'left', 'token': null},
          ]),
        },
      );
      var reachable = true;
      var revision = '';
      answers['GET /api/fleet/status'] = (_) => reachable
          ? {
              'id': 'bed',
              'name': 'New bedroom name',
              'version': '2026.9.20',
              'leaderId': 'me',
              'rosterRevision': revision,
            }
          : http.Response('unreachable', 503);
      answers['POST /api/fleet/roster'] = (_) => {'ok': true};
      await commands.execute('fleetSyncNow', const {});
      final follower = fleet.followers.first;
      expect(follower.online, isTrue);
      expect(follower.version, '2026.9.20');
      expect(sent.where((r) => r.url.path == '/api/fleet/apply'), isEmpty);
      final request = sent.singleWhere(
        (r) => r.url.path == '/api/fleet/roster',
      );
      expect(request.headers['authorization'], 'Bearer private-token');
      final roster = (jsonDecode(request.body) as Map)['devices'] as List;
      expect(roster.map((d) => d['id']), ['bed', 'me']);
      expect(roster.first['name'], 'New bedroom name');
      expect(request.body, isNot(contains('private-token')));
      expect(request.body, isNot(contains('private-nonce')));
      final saved = jsonDecode(settings.get(defs.fleetFollowers)) as List;
      expect(saved.first['name'], 'New bedroom name');
      revision = follower.rosterRevision!;

      // An acknowledged directory does not need to be sent on every poll.
      sent.clear();
      await commands.execute('fleetSyncNow', const {});
      expect(sent.where((r) => r.url.path == '/api/fleet/roster'), isEmpty);

      reachable = false;
      await commands.execute('fleetSyncNow', const {});
      expect(follower.online, isFalse);
      reachable = true;
      await commands.execute('fleetSyncNow', const {});
      expect(follower.online, isTrue);

      // The saved IP now answers as another kiosk with the same leader.
      answers['GET /api/fleet/status'] = (_) => {
        'id': 'another-kiosk',
        'leaderId': 'me',
        'version': '2026.9.19',
        'rosterRevision': '',
      };
      sent.clear();
      await commands.execute('fleetSyncNow', const {});
      expect(follower.online, isFalse);
      expect(follower.token, 'private-token');
      expect(sent.where((r) => r.method == 'POST'), isEmpty);
    },
  );

  test(
    'the follower stores only directory fields and clears them on leaving',
    () async {
      const leader = {
        'id': 'lead',
        'name': 'Leader',
        'version': '2026.9.99',
        'address': '192.168.1.1',
        'port': 2324,
      };
      final sibling = {...leader, 'id': 'sibling', 'name': 'Bedroom'};
      await build(prefs: {'ks.fleet.leader_info': jsonEncode(leader)});
      final result = await commands.execute('fleetRosterReceived', {
        'devices': [
          {...sibling, 'token': 'must-not-travel', 'self': true},
          leader,
        ],
      });
      expect(result.ok, isTrue, reason: result.error);
      final stored = settings.get(defs.fleetRoster);
      expect(stored, isNot(contains('must-not-travel')));
      expect(stored, isNot(contains('self')));
      expect((jsonDecode(stored) as List).map((d) => d['id']), [
        'lead',
        'sibling',
      ]);
      expect(settings.get(defs.fleetAppliedRevision), isEmpty);
      expect(settings.get(defs.fleetSyncedKeys), isEmpty);
      final status = await fleet.followerStatus();
      expect(status['rosterRevision'], isNotEmpty);

      for (final devices in [
        [sibling],
        [leader, leader],
        [
          leader,
          {...sibling, 'port': 0},
        ],
      ]) {
        final invalid = await commands.execute('fleetRosterReceived', {
          'devices': devices,
        });
        expect(invalid.ok, isFalse);
        expect(settings.get(defs.fleetRoster), stored);
      }

      await commands.execute('fleetRosterReceived', {
        'devices': [leader],
      });
      expect(jsonDecode(settings.get(defs.fleetRoster)), hasLength(1));
      await fleet.leave();
      expect(settings.get(defs.fleetRoster), isEmpty);
      expect(
        (await commands.execute('fleetRosterReceived', {
          'devices': [leader],
        })).ok,
        isFalse,
      );
    },
  );

  test(
    'settings this kiosk pins never import and never mark it changed here',
    () async {
      await build(
        prefs: {
          'ks.fleet.leader_info': jsonEncode({'id': 'lead', 'name': 'Leader'}),
        },
      );
      defs.devicePinnedKeys.add(defs.screensaverEnabled.key);
      addTearDown(() => defs.devicePinnedKeys.clear());
      await settings.set(defs.screensaverEnabled, false);
      final (error, _) = await fleet.apply({
        'version': '2026.9.19',
        'revision': 'r1',
        'settings': {
          defs.screensaverEnabled.key: true,
          defs.screensaverMode.key: 'clock',
        },
      });
      expect(error, isNull);
      expect(settings.get(defs.screensaverEnabled), false);
      expect(settings.get(defs.screensaverMode), 'clock');
      expect(
        settings.get(defs.fleetSyncedKeys),
        isNot(contains(defs.screensaverEnabled.key)),
      );
      await settings.set(defs.screensaverEnabled, true);
      await Future<void>.delayed(Duration.zero);
      expect(settings.get(defs.fleetAppliedRevision), 'r1');
    },
  );

  group('plugins stay local', () {
    test(
      'plugin screensaver choices and schedules never travel or get overwritten',
      () async {
        await build(
          prefs: {
            'ks.fleet.leader_info': jsonEncode({
              'id': 'lead',
              'name': 'Leader',
            }),
          },
        );
        const mode = 'plugin:hello-world:dvd';
        final schedule = jsonEncode([
          {'at': '00:00', 'mode': mode},
        ]);
        await settings.set(defs.screensaverMode, mode);
        await settings.set(defs.screensaverSchedule, schedule);
        final profile = SyncProfile(
          categories: {'Screensaver'},
          excluded: const {},
        );
        final payload = fleet.profileSettings(profile);
        expect(payload.containsKey(defs.screensaverMode.key), false);
        expect(payload.containsKey(defs.screensaverSchedule.key), false);
        expect(
          FleetSyncManager.acceptable({
            defs.screensaverMode.key: mode,
            defs.screensaverSchedule.key: schedule,
          }),
          isEmpty,
        );
        final (error, _) = await fleet.apply({
          'version': '2026.9.19',
          'settings': {
            defs.screensaverMode.key: 'clock',
            defs.screensaverSchedule.key: '[]',
          },
        });
        expect(error, isNull);
        expect(settings.get(defs.screensaverMode), mode);
        expect(settings.get(defs.screensaverSchedule), schedule);
      },
    );

    test(
      'plugin entity exclusions stay local while core exclusions follow the leader',
      () async {
        await build(
          prefs: {
            'ks.fleet.leader_info': jsonEncode({
              'id': 'lead',
              'name': 'Leader',
            }),
            'ks.fleet.synced_keys': jsonEncode([
              defs.esphomeExcludedEntities.key,
            ]),
            'ks.fleet.applied_revision': 'clean',
          },
        );
        const local = 'plugin_local____sensor_ping';
        await settings.set(defs.esphomeExcludedEntities, jsonEncode([local]));
        await settle();
        expect(settings.get(defs.fleetAppliedRevision), 'clean');
        final profile = SyncProfile(
          categories: {'ESPHome'},
          excluded: const {},
        );
        expect(
          fleet.profileSettings(profile)[defs.esphomeExcludedEntities.key],
          '[]',
        );
        await settings.set(
          defs.esphomeExcludedEntities,
          jsonEncode(['battery', local]),
        );
        final result = await commands.execute('fleetApply', {
          'revision': 'updated',
          'version': '2026.9.19',
          'settings': {
            defs.esphomeExcludedEntities.key: jsonEncode([
              'screen',
              'plugin_leader____select_mode',
            ]),
          },
        });
        expect(result.ok, true, reason: result.error);
        expect(
          defs.decodeEspHomeExcludedEntities(
            settings.get(defs.esphomeExcludedEntities),
          ),
          {'screen', local},
        );
        expect(
          FleetSyncManager.acceptable({
            defs.esphomeExcludedEntities.key: 'invalid',
          }),
          isEmpty,
        );
        await settings.set(
          defs.esphomeExcludedEntities,
          jsonEncode(['screen', local, 'plugin_other__light']),
        );
        await settle();
        expect(settings.get(defs.fleetAppliedRevision), 'updated');
      },
    );

    test(
      'leader payloads and revisions exclude plugin gesture actions and plugin state',
      () async {
        await build();
        final regular = gesture('normal', 'screensaver');
        final plugin = gesture('plugin', 'plugin_action');
        // A plugin trigger (issue #888) is just as local as a plugin action.
        final pluginTrigger = {
          ...gesture('trigger', 'screensaver'),
          'trigger': {
            'type': 'plugin',
            'pluginId': 'hello-world',
            'trigger': 'hardwareKey',
          },
        };
        await settings.set(
          defs.gestureMappings,
          jsonEncode([regular, plugin, pluginTrigger]),
        );
        final profile = SyncProfile(
          categories: {
            for (final category in defs.fleetSyncCategories) category.$1,
            'Plugins',
            'Plugin Manager',
          },
          excluded: const {},
          credentials: defs.fleetCredentialKeys,
          dashboard: true,
        );
        final before = fleet.profileSettings(profile);
        expect(jsonDecode(before[defs.gestureMappings.key] as String), [
          regular,
        ]);
        expect(
          before.keys.any((key) => key.toLowerCase().contains('plugin')),
          false,
        );
        expect(
          fleet.syncable().any(
            (row) => '${row['key']}'.toLowerCase().contains('plugin'),
          ),
          false,
        );
        await settings.set(
          defs.gestureMappings,
          jsonEncode([
            gesture('other-plugin', 'plugin_action', command: 'hide'),
            regular,
          ]),
        );
        expect(
          FleetSyncManager.fingerprintOf(fleet.profileSettings(profile)),
          FleetSyncManager.fingerprintOf(before),
        );
      },
    );

    test(
      'followers reject plugin state and retain their own plugin gestures on every push',
      () async {
        await build(
          prefs: {
            'ks.fleet.leader_info': jsonEncode({
              'id': 'lead',
              'name': 'Leader',
            }),
          },
        );
        final localPlugin = gesture('local', 'plugin_action');
        await settings.set(
          defs.gestureMappings,
          jsonEncode([localPlugin, gesture('old', 'screensaver')]),
        );
        final regular = gesture('new', 'screensaver_stop');
        final incoming = {
          'pluginsEnabled': false,
          'plugins.enabled': false,
          'plugins.installed': '[untrusted]',
          'plugins.settings': {'message': 'leader'},
          'plugins.actionOptions': {'drawer': true},
          defs.gestureMappings.key: jsonEncode([
            gesture('remote-plugin', 'plugin_action'),
            gesture('local', 'screensaver'),
            regular,
          ]),
        };
        final accepted = FleetSyncManager.acceptable(incoming);
        expect(accepted.keys, [defs.gestureMappings.key]);
        expect(
          (accepted[defs.gestureMappings.key] as String).contains(
            'plugin_action',
          ),
          false,
        );
        Future<CommandResult> push(Map<String, Object?> values) =>
            commands.execute('fleetApply', {
              'revision': 'clean',
              'version': '2026.9.19',
              'settings': values,
            });
        final result = await push(incoming);
        expect(result.ok, true, reason: result.error);
        expect((result.data as Map)['received'], 1);
        expect((result.data as Map)['skipped'], 5);
        expect(jsonDecode(settings.get(defs.gestureMappings)), [
          regular,
          localPlugin,
        ]);
        expect(fleet.syncedKeys, {defs.gestureMappings.key});
        final repeated = await push(incoming);
        expect((repeated.data as Map)['applied'], 0);
        final invalid = await push({defs.gestureMappings.key: null});
        expect((invalid.data as Map)['applied'], 0);
        expect(jsonDecode(settings.get(defs.gestureMappings)), [
          regular,
          localPlugin,
        ]);
        await push({defs.gestureMappings.key: '[]'});
        expect(jsonDecode(settings.get(defs.gestureMappings)), [localPlugin]);
      },
    );

    test(
      'editing local plugin gestures does not mark a follower out of sync',
      () async {
        final regular = gesture('normal', 'screensaver');
        await build(
          prefs: {
            'ks.fleet.leader_info': jsonEncode({
              'id': 'lead',
              'name': 'Leader',
            }),
            'ks.fleet.synced_keys': jsonEncode([defs.gestureMappings.key]),
            'ks.fleet.applied_revision': 'clean',
            'ks.gestures.mappings': jsonEncode([regular]),
          },
        );
        await settings.set(
          defs.gestureMappings,
          jsonEncode([regular, gesture('local', 'plugin_action')]),
        );
        await settle();
        expect(settings.get(defs.fleetAppliedRevision), 'clean');
        await settings.set(
          defs.gestureMappings,
          jsonEncode([
            regular,
            gesture('local', 'plugin_action', command: 'hide'),
          ]),
        );
        await settle();
        expect(settings.get(defs.fleetAppliedRevision), 'clean');
        await settings.set(defs.gestureMappings, jsonEncode([regular]));
        await settle();
        expect(settings.get(defs.fleetAppliedRevision), 'clean');
        await settings.set(defs.gestureMappings, '[]');
        await settle();
        expect(settings.get(defs.fleetAppliedRevision), '');
      },
    );
  });

  group('what travels', () {
    test('the identity, hardware and remote keys stay per kiosk', () async {
      await build();
      final never = {
        for (final d in defs.allSettings)
          if (d.perDevice) d.key,
      };
      expect(
        never,
        containsAll([
          'device.name',
          'remote.enabled',
          'remote.password',
          'remote.port',
          'remote.fleet_discovery',
          'esphome.node_name',
          'esphome.mac_override',
          'btproxy.key',
          'sendspin.client_id',
          'sendspin.player',
          'ha.satellite_entity',
          'camera.device',
          'motion.camera',
          'audio.mic_device',
          'audio.speaker_device',
          'render.disable_impeller',
          'render.legacy_webview',
          'ui.scale',
        ]),
      );
      // Every fleet key describes this kiosk's own place in a fleet.
      for (final d in defs.allSettings) {
        if (d.key.startsWith('fleet.')) {
          expect(d.perDevice, isTrue, reason: d.key);
        }
      }
      // The credentials and the dashboard are choices, not per device.
      for (final key in defs.fleetCredentialKeys) {
        // Plugin secrets are the plugins' own, not a setting.
        if (key == defs.fleetPluginSecrets) continue;
        expect(settings.defByKey(key)!.perDevice, isFalse, reason: key);
      }
      expect(settings.defByKey('browser.start_url')!.perDevice, isFalse);
      // The PIN goes with Kiosk Mode (user decision).
      expect(defs.fleetCredentialKeys, isNot(contains('kiosk.pin')));
    });

    test(
      'a profile picks by category, with credentials and dashboard opt in',
      () async {
        await build();
        await settings.set(defs.haToken, 'tkn');
        await settings.set(defs.kioskPin, '1234');
        final base = const SyncProfile(categories: {'Kiosk', 'Home Assistant'});
        final pushed = fleet.profileSettings(base);
        expect(pushed.keys, contains('kiosk.pin'));
        expect(pushed.keys, contains('kiosk.enabled'));
        expect(pushed.keys, contains('ha.url'));
        expect(pushed.keys, isNot(contains('ha.token')));
        expect(pushed.keys, isNot(contains('ha.satellite_entity')));
        expect(pushed.keys, isNot(contains('browser.start_url')));
        expect(pushed.keys, isNot(contains('screensaver.mode')));
        expect(pushed.keys, isNot(contains('device.name')));
        final withCreds = fleet.profileSettings(
          const SyncProfile(
            categories: {'Home Assistant', 'Browser'},
            credentials: {'ha.token'},
            dashboard: true,
          ),
        );
        expect(withCreds['ha.token'], 'tkn');
        // Picked one by one: the other two stay with the kiosk.
        expect(withCreds.keys, isNot(contains('sendspin.ma_token')));
        expect(withCreds.keys, isNot(contains('screensaver.immich_api_key')));
        // A realtime key is a credential of its own, off unless picked:
        // Voice Satellite alone does not carry it.
        await settings.set(defs.voiceRealtimeOpenAiApiKey, 'sk-x');
        expect(
          fleet
              .profileSettings(
                const SyncProfile(categories: {'Voice Satellite'}),
              )
              .keys,
          isNot(contains('voice.realtime_openai_api_key')),
        );
        expect(
          fleet.profileSettings(
            const SyncProfile(
              categories: {'Voice Satellite'},
              credentials: {'voice.realtime_openai_api_key'},
            ),
          )['voice.realtime_openai_api_key'],
          'sk-x',
        );
        // A new follower shares the household credentials, not the user.
        // The intercom key is the household's too. The realtime keys are
        // billed per use and stay off.
        expect(SyncProfile.initial.credentials, {
          'sendspin.ma_token',
          'screensaver.immich_api_key',
          'intercom.key',
        });
        expect(
          SyncProfile.parse({
            'categories': [],
            'credentials': ['ha.token', 'bogus'],
          })!.describe(),
          'Categories: 0 of 19. Credentials: 1 of 9. Excluded: 43.',
        );
        expect(
          withCreds['browser.start_url'],
          'http://ha.local:8123/lovelace/0',
        );
        // The Web Content grants ride with Web Browsing.
        expect(withCreds.keys, contains('web.autoplay'));
        expect(withCreds.keys, isNot(contains('browser.cutout_mode')));
      },
    );

    test(
      'the follower drops what stays per kiosk whatever the leader sent',
      () {
        final kept = FleetSyncManager.acceptable({
          'screensaver.mode': 'clock',
          'device.name': 'Not mine',
          'remote.password': 'pwned',
          'sendspin.client_id': 'x',
          'no.such.key': 1,
        });
        expect(kept.keys, ['screensaver.mode']);
      },
    );
  });

  group('the follower', () {
    test(
      'an invitation is checked against the leader and waits on the screen',
      () async {
        await build();
        answers['GET /api/fleet/identity'] = (_) => {
          'id': 'lead',
          'name': 'Living Room',
          'version': '2026.9.19',
          'leader': true,
        };
        final r = await commands.execute('fleetInviteReceived', {
          'invite': 'nonce1',
          'leader': {
            'id': 'lead',
            'name': 'Living Room',
            'version': '2026.9.19',
            'port': 2324,
          },
          'address': '192.168.1.30',
        });
        expect(r.ok, isTrue, reason: r.error);
        expect(fleet.pendingInvite?['invite'], 'nonce1');
        expect(
          (fleet.pendingInvite?['leader'] as Map)['address'],
          '192.168.1.30',
        );
        expect(fleet.following, isFalse);
        // Polled before the answer: still pending, nothing handed out.
        final pending = await commands.execute('fleetInvitePoll', {
          'invite': 'nonce1',
        });
        expect((pending.data as Map)['status'], 'pending');
        await settle();
        expect(changes, greaterThan(0));
      },
    );

    test(
      'an invitation from a kiosk that is not who it says is dropped',
      () async {
        await build();
        answers['GET /api/fleet/identity'] = (_) => {
          'id': 'someone-else',
          'leader': true,
        };
        final r = await commands.execute('fleetInviteReceived', {
          'invite': 'nonce1',
          'leader': {'id': 'lead', 'name': 'Living Room', 'port': 2324},
          'address': '192.168.1.30',
        });
        expect(r.ok, isFalse);
        expect(fleet.pendingInvite, isNull);
      },
    );

    test('a leader cannot be invited to follow', () async {
      await build(prefs: {'ks.fleet.leader': true});
      answers['GET /api/fleet/identity'] = (_) => {
        'id': 'lead',
        'leader': true,
      };
      final r = await commands.execute('fleetInviteReceived', {
        'invite': 'nonce1',
        'leader': {'id': 'lead', 'name': 'Living Room', 'port': 2324},
        'address': '192.168.1.30',
      });
      expect(r.ok, isFalse);
      expect(r.error, contains('leads'));
    });

    test(
      'accepting mints a token the leader collects once, then the push applies',
      () async {
        await build();
        answers['GET /api/fleet/identity'] = (_) => {
          'id': 'lead',
          'name': 'Living Room',
          'leader': true,
        };
        await commands.execute('fleetInviteReceived', {
          'invite': 'nonce1',
          'leader': {
            'id': 'lead',
            'name': 'Living Room',
            'version': '2026.9.19',
            'port': 2324,
          },
          'address': '192.168.1.30',
        });
        // Declining and accepting are the device's; here they are commands.
        final a = await commands.execute('fleetAccept', const {});
        expect(a.ok, isTrue, reason: a.error);
        expect(fleet.following, isTrue);
        expect(fleet.leader?['id'], 'lead');
        final poll = await commands.execute('fleetInvitePoll', {
          'invite': 'nonce1',
        });
        expect((poll.data as Map)['status'], 'accepted');
        expect((poll.data as Map)['token'], 'tok-lead');
        // Once: the second poll finds nothing.
        final again = await commands.execute('fleetInvitePoll', {
          'invite': 'nonce1',
        });
        expect((again.data as Map)['status'], 'unknown');

        // The status the leader polls.
        final st = await commands.execute('fleetFollowerStatus', const {});
        expect((st.data as Map)['leaderId'], 'lead');
        expect((st.data as Map)['appliedRevision'], isNull);
        expect((st.data as Map)['dirty'], isFalse);

        // The push: only what differs is set, the rest is recorded as synced.
        await settings.set(defs.screensaverMode, 'clock');
        final apply = await commands.execute('fleetApply', {
          'revision': '7',
          'version': '2026.9.19+130',
          'settings': {
            'screensaver.mode': 'black',
            'screensaver.enabled': settings.get(defs.screensaverEnabled),
            'device.name': 'Leader Name',
          },
        });
        expect(apply.ok, isTrue, reason: apply.error);
        final data = apply.data as Map;
        expect(data['applied'], 1);
        expect(data['received'], 2);
        expect(data['skipped'], 1);
        expect(settings.get(defs.screensaverMode), 'black');
        expect(settings.get(defs.deviceName), '');
        expect(settings.get(defs.fleetAppliedRevision), '7');
        expect(fleet.syncedKeys, {'screensaver.mode', 'screensaver.enabled'});
        final status = fleet.status();
        final following = status['following'] as Map;
        expect(following['syncedCategories'], ['Screensaver']);
        expect(following['dirty'], isFalse);
      },
    );

    test('a push from another version is held', () async {
      await build(
        prefs: {
          'ks.fleet.leader_info': jsonEncode({
            'id': 'lead',
            'name': 'Living Room',
          }),
        },
      );
      await settings.set(defs.screensaverMode, 'clock');
      final apply = await commands.execute('fleetApply', {
        'revision': '7',
        'version': '2026.9.18',
        'settings': {'screensaver.mode': 'black'},
      });
      expect(apply.ok, isTrue);
      expect((apply.data as Map)['held'], 'version');
      expect(settings.get(defs.screensaverMode), 'clock');
      expect(settings.get(defs.fleetAppliedRevision), '');
    });

    test('a local change to a synced setting marks the kiosk dirty', () async {
      await build(
        prefs: {
          'ks.fleet.leader_info': jsonEncode({
            'id': 'lead',
            'name': 'Living Room',
          }),
          'ks.fleet.synced_keys': jsonEncode(['screensaver.mode']),
          'ks.fleet.applied_revision': '7',
        },
      );
      await settings.set(defs.screensaverMode, 'black');
      await settle();
      expect(settings.get(defs.fleetAppliedRevision), '');
      final st = await commands.execute('fleetFollowerStatus', const {});
      expect((st.data as Map)['dirty'], isTrue);
      // A per device change is nobody's business.
      await settings.set(defs.deviceName, 'Bedroom');
      await settle();
      expect(
        (await commands.execute('fleetFollowerStatus', const {})).ok,
        isTrue,
      );
    });

    test('leaving forgets the leader and what it pushed', () async {
      await build(
        prefs: {
          'ks.fleet.leader_info': jsonEncode({
            'id': 'lead',
            'name': 'Living Room',
          }),
          'ks.fleet.synced_keys': jsonEncode(['screensaver.mode']),
          'ks.fleet.applied_revision': '7',
        },
      );
      await commands.execute('fleetLeave', const {});
      expect(fleet.following, isFalse);
      expect(fleet.syncedKeys, isEmpty);
      expect(
        settings.get(defs.screensaverMode),
        settings.get(defs.screensaverMode),
      );
    });
  });

  group('the leader', () {
    test(
      'an invitation goes to the kiosk and the row waits for its OK',
      () async {
        await build(prefs: {'ks.fleet.leader': true});
        answers['POST /api/fleet/invite'] = (_) => {
          'ok': true,
          'data': {'pending': true},
        };
        answers['GET /api/fleet/invite/nonce'] = (_) => {'status': 'pending'};
        final r = await commands.execute('fleetInvite', {'id': 'bed'});
        expect(r.ok, isTrue, reason: r.error);
        final invite = sent.singleWhere(
          (q) => q.url.path == '/api/fleet/invite',
        );
        expect(invite.url.host, '192.168.1.71');
        final body = jsonDecode(invite.body) as Map;
        expect((body['leader'] as Map)['id'], 'me');
        expect(
          body['invite'],
          isA<String>().having((s) => s.length, 'length', 64),
        );
        final row = (fleet.status()['followers'] as List).single as Map;
        expect(row['phase'], 'pending');
        expect(row['status'], 'Waiting for its OK');
        expect(row['profile'], 'default');
        // Persisted: a restart keeps the invitation.
        final stored = jsonDecode(settings.get(defs.fleetFollowers)) as List;
        expect((stored.single as Map)['invite'], body['invite']);
      },
    );

    test(
      'an accepted invitation is collected, then the first push goes out',
      () async {
        await build(prefs: {'ks.fleet.leader': true});
        String? nonce;
        answers['POST /api/fleet/invite'] = (req) {
          nonce = (jsonDecode(req.body) as Map)['invite'] as String;
          return {
            'ok': true,
            'data': {'pending': true},
          };
        };
        answers['GET /api/fleet/status'] = (_) => {
          'id': 'bed',
          'name': 'Bedroom',
          'version': '2026.9.19',
          'leaderId': 'me',
          'appliedRevision': null,
          'dirty': false,
        };
        answers['POST /api/fleet/apply'] = (_) => {
          'ok': true,
          'data': {'applied': 3, 'received': 40, 'skipped': 0},
        };
        await commands.execute('fleetInvite', {'id': 'bed'});
        answers['GET /api/fleet/invite/$nonce'] = (_) => {
          'status': 'accepted',
          'token': 'tok-me',
        };
        await commands.execute('fleetSyncNow', const {});
        final push = sent.singleWhere((q) => q.url.path == '/api/fleet/apply');
        expect(push.headers['Authorization'], 'Bearer tok-me');
        final body = jsonDecode(push.body) as Map;
        expect(body['version'], '2026.9.19');
        expect((body['settings'] as Map).keys, contains('screensaver.mode'));
        expect((body['settings'] as Map).keys, isNot(contains('device.name')));
        final row = (fleet.status()['followers'] as List).single as Map;
        expect(row['phase'], 'synced', reason: '$row');
        expect(row['status'], startsWith('Synced'));
      },
    );

    test(
      'a follower on another version is not pushed and reads which it needs',
      () async {
        peers.single['version'] = '2026.9.18';
        await build(
          prefs: {
            'ks.fleet.leader': true,
            'ks.fleet.followers': jsonEncode([
              {
                'id': 'bed',
                'name': 'Bedroom',
                'address': '192.168.1.71',
                'port': 2324,
                'token': 't',
              },
            ]),
          },
        );
        answers['GET /api/fleet/status'] = (_) => {
          'id': 'bed',
          'version': '2026.9.18',
          'leaderId': 'me',
          'appliedRevision': null,
          'dirty': false,
          'update': {'availableVersion': '2026.9.19', 'progress': null},
        };
        await commands.execute('fleetSyncNow', const {});
        expect(sent.where((q) => q.url.path == '/api/fleet/apply'), isEmpty);
        final row = (fleet.status()['followers'] as List).single as Map;
        expect(row['phase'], 'version');
        expect(row['status'], 'Needs 2026.9.19');
        expect(fleet.status()['outdated'], ['Bedroom']);
        // Keep followers on this version: the offered release is this one.
        await settings.set(defs.fleetAutoUpdate, true);
        await commands.execute('fleetSyncNow', const {});
        expect(
          sent.where((q) => q.url.path == '/api/commands/installUpdate'),
          hasLength(1),
        );
        // Once per release.
        await commands.execute('fleetSyncNow', const {});
        expect(
          sent.where((q) => q.url.path == '/api/commands/installUpdate'),
          hasLength(1),
        );
      },
    );

    test('a follower that stopped honoring the token reads as left', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      answers['GET /api/fleet/status'] = (_) =>
          http.Response('{"error":"no"}', 403);
      await commands.execute('fleetSyncNow', const {});
      final row = (fleet.status()['followers'] as List).single as Map;
      expect(row['phase'], 'left');
    });

    test(
      'a restored backup brings its followers and profiles in (#1208)',
      () async {
        await build();
        final followers = jsonEncode([
          {
            'id': 'bed',
            'name': 'Bedroom',
            'address': '192.168.1.71',
            'port': 2324,
            'token': 't',
            'profile': 'own',
          },
        ]);
        final profiles = jsonEncode([
          {
            'id': 'default',
            'name': 'Default',
            'categories': ['Gestures'],
            'credentials': [],
            'dashboard': false,
            'excluded': [],
          },
          {
            'id': 'own',
            'name': 'Own list',
            'categories': ['Gestures'],
            'credentials': [],
            'dashboard': false,
            'excluded': [],
          },
        ]);
        await settings.import({
          defs.fleetLeader.key: true,
          defs.fleetProfiles.key: profiles,
          defs.fleetFollowers.key: followers,
        });
        await settle();
        final status = fleet.status();
        final row = (status['followers'] as List).single as Map;
        expect(row['name'], 'Bedroom');
        expect(row['profile'], 'own');
        expect([
          for (final p in status['profiles'] as List) (p as Map)['id'],
        ], containsAll(['default', 'own']));
        // A change on the Fleet page saves what was imported, not the
        // empty lists from before.
        final r = await commands.execute('fleetSetProfile', {
          'profile': {
            'name': 'Another',
            'categories': ['Kiosk'],
            'credentials': [],
            'dashboard': false,
            'excluded': [],
          },
        });
        expect(r.ok, isTrue, reason: r.error);
        final stored = jsonDecode(settings.get(defs.fleetFollowers)) as List;
        expect((stored.single as Map)['id'], 'bed');
        final storedProfiles = [
          for (final p in jsonDecode(settings.get(defs.fleetProfiles)) as List)
            (p as Map)['id'],
        ];
        expect(storedProfiles, containsAll(['default', 'own']));
      },
    );

    test('followers imported during a tick are not written over', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'old',
              'name': 'Old',
              'address': '192.168.1.80',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      await settle();
      final held = Completer<Object?>();
      answers['GET /api/fleet/status'] = (_) => held.future;
      final tick = commands.execute('fleetSyncNow', const {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await settings.import({
        defs.fleetFollowers.key: jsonEncode([
          {
            'id': 'bed',
            'name': 'Bedroom',
            'address': '192.168.1.71',
            'port': 2324,
            'token': 't',
          },
        ]),
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      held.complete(http.Response('{"error":"no"}', 403));
      await tick;
      await settle();
      final stored = jsonDecode(settings.get(defs.fleetFollowers)) as List;
      expect([for (final f in stored) (f as Map)['id']], ['bed']);
      final rows = fleet.status()['followers'] as List;
      expect([for (final r in rows) (r as Map)['name']], ['Bedroom']);
    });

    test('a change to a synced setting pushes again after a pause', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      var applied = 'x';
      answers['GET /api/fleet/status'] = (_) => {
        'id': 'bed',
        'version': '2026.9.19',
        'leaderId': 'me',
        'appliedRevision': applied,
        'dirty': false,
      };
      answers['POST /api/fleet/apply'] = (req) {
        applied = (jsonDecode(req.body) as Map)['revision'] as String;
        return {
          'ok': true,
          'data': {'applied': 1},
        };
      };
      // The first sync brings the follower up to the fingerprint.
      await commands.execute('fleetSyncNow', const {});
      int pushes() =>
          sent.where((q) => q.url.path == '/api/fleet/apply').length;
      expect(pushes(), 1);
      // A synced value changes: pushed once more after the pause.
      await settings.set(defs.screensaverMode, 'clock');
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      expect(pushes(), 2);
      // A per device change, and a change to a setting outside the
      // follower's profile, are not its business.
      await settings.set(defs.deviceName, 'Other');
      await settings.set(defs.dlnaAudioBackground, true);
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      expect(pushes(), 2);
    });

    test('a profile change reaches only the followers on it', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
            {
              'id': 'kit',
              'name': 'Kitchen',
              'address': '192.168.1.70',
              'port': 2324,
              'token': 't2',
            },
          ]),
        },
      );
      peers.add({
        'id': 'kit',
        'name': 'Kitchen',
        'version': '2026.9.19',
        'address': '192.168.1.70',
        'port': 2324,
        'self': false,
      });
      final applied = <String, String>{};
      answers['GET /api/fleet/status'] = (req) {
        final id = req.url.host == '192.168.1.71' ? 'bed' : 'kit';
        return {
          'id': id,
          'version': '2026.9.19',
          'leaderId': 'me',
          'appliedRevision': applied[id],
          'dirty': false,
        };
      };
      answers['POST /api/fleet/apply'] = (req) {
        final id = req.url.host == '192.168.1.71' ? 'bed' : 'kit';
        applied[id] = (jsonDecode(req.body) as Map)['revision'] as String;
        return {
          'ok': true,
          'data': {'applied': 1},
        };
      };
      await commands.execute('fleetSyncNow', const {});
      int pushesTo(String host) => sent
          .where((q) => q.url.path == '/api/fleet/apply' && q.url.host == host)
          .length;
      expect(pushesTo('192.168.1.71'), 1);
      expect(pushesTo('192.168.1.70'), 1);
      // A profile of its own for the Bedroom: only the Bedroom is pushed.
      final made = await commands.execute('fleetSetProfile', {
        'profile': {
          'name': 'Kiosk only',
          'categories': ['Kiosk'],
        },
      });
      await commands.execute('fleetAssignProfile', {
        'id': 'bed',
        'profile': made.data,
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(pushesTo('192.168.1.71'), 2);
      expect(pushesTo('192.168.1.70'), 1);
      // The Default changes: only the Kitchen, still on it, is pushed.
      await commands.execute('fleetSetProfile', {
        'profile': {
          'id': 'default',
          'name': 'Default',
          'categories': ['Gestures'],
        },
      });
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(pushesTo('192.168.1.71'), 2);
      expect(pushesTo('192.168.1.70'), 2);
    });

    test('a profile of its own replaces the Default wholesale', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      Map? pushed;
      answers['GET /api/fleet/status'] = (_) => {
        'id': 'bed',
        'version': '2026.9.19',
        'leaderId': 'me',
        'appliedRevision': null,
        'dirty': false,
      };
      answers['POST /api/fleet/apply'] = (req) {
        pushed = (jsonDecode(req.body) as Map)['settings'] as Map;
        return {
          'ok': true,
          'data': {'applied': 1},
        };
      };
      final made = await commands.execute('fleetSetProfile', {
        'profile': {
          'name': 'Kiosk only',
          'categories': ['Kiosk'],
          'credentials': [],
          'dashboard': false,
          'excluded': [],
        },
      });
      expect(made.ok, isTrue, reason: made.error);
      final id = made.data as String;
      await commands.execute('fleetAssignProfile', {
        'id': 'bed',
        'profile': id,
      });
      await commands.execute('fleetSyncNow', const {});
      expect(pushed!.keys, contains('kiosk.enabled'));
      expect(pushed!.keys, isNot(contains('screensaver.mode')));
      final row = (fleet.status()['followers'] as List).single as Map;
      expect(row['profile'], id);
      expect(row['profileName'], 'Kiosk only');
      final profiles = fleet.status()['profiles'] as List;
      expect(profiles.map((p) => (p as Map)['name']), [
        'Default',
        'Updates only',
        'Kiosk only',
      ]);
      expect((profiles[2] as Map)['kiosks'], 1);
      // Back to the Default.
      await commands.execute('fleetAssignProfile', {'id': 'bed'});
      await commands.execute('fleetSyncNow', const {});
      expect(pushed!.keys, contains('screensaver.mode'));
      // The Default itself can change and keeps its name.
      await commands.execute('fleetSetProfile', {
        'profile': {
          'id': 'default',
          'name': 'Renamed',
          'categories': ['Gestures'],
          'credentials': [],
          'dashboard': false,
          'excluded': [],
        },
      });
      await commands.execute('fleetSyncNow', const {});
      expect(pushed!.keys, isNot(contains('screensaver.mode')));
      expect(pushed!.keys, contains('gestures.clap_strictness'));
      expect(fleet.defaultProfile.categories, {'Gestures'});
      expect(fleet.defaultProfile.name, 'Default');
      // Names address the pages: one each, whatever the case.
      final dup = await commands.execute('fleetSetProfile', {
        'profile': {
          'name': 'kiosk ONLY',
          'categories': ['Kiosk'],
        },
      });
      expect(dup.ok, isFalse);
      expect(dup.error, contains('exists'));
      // Deleting a profile drops its kiosks back on the Default; the
      // Default cannot go.
      await commands.execute('fleetAssignProfile', {
        'id': 'bed',
        'profile': id,
      });
      await commands.execute('fleetDeleteProfile', {'id': id});
      expect(
        (fleet.status()['followers'] as List).single,
        containsPair('profile', 'default'),
      );
      expect(
        (await commands.execute('fleetDeleteProfile', {'id': 'default'})).ok,
        isFalse,
      );
    });

    test(
      'the display bound settings are out by default and can come back',
      () async {
        await build();
        final base = fleet.profileSettings(SyncProfile.initial);
        for (final key in defs.fleetDefaultExcluded) {
          expect(base.keys, isNot(contains(key)), reason: key);
        }
        expect(base.keys, isNot(contains('screensaver.clock_scale')));
        final back = fleet.profileSettings(
          const SyncProfile(
            categories: {'Screensaver', 'Browser'},
            excluded: {'browser.zoom'},
          ),
        );
        expect(back.keys, contains('screensaver.clock_scale'));
        expect(back.keys, isNot(contains('browser.zoom')));
        // Any setting can be excluded, never a per device one re-included.
        final more = fleet.profileSettings(
          const SyncProfile(
            categories: {'Screensaver'},
            excluded: {'screensaver.mode'},
          ),
        );
        expect(more.keys, isNot(contains('screensaver.mode')));
        expect(more.keys, contains('screensaver.enabled'));
        expect(more.keys, isNot(contains('device.name')));
        // The picker's list: syncable, never per device, no switches' keys.
        final keys = {for (final e in fleet.syncable()) e['key']};
        final clock = fleet.syncable().firstWhere(
          (e) => e['key'] == 'screensaver.clock_scale',
        );
        expect(clock['category'], 'Screensaver');
        expect(clock['subpage'], 'Clock screensaver');
        expect(clock['description'], isNotEmpty);
        expect(keys, contains('screensaver.clock_scale'));
        expect(keys, isNot(contains('device.name')));
        expect(keys, isNot(contains('ha.token')));
        expect(keys, isNot(contains('browser.start_url')));
      },
    );

    test('removing a follower tells it and forgets it', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      answers['POST /api/fleet/leave'] = (_) => {'ok': true};
      await commands.execute('fleetRemove', {'id': 'bed'});
      await settle();
      expect(fleet.followers, isEmpty);
      expect(sent.where((q) => q.url.path == '/api/fleet/leave'), hasLength(1));
      expect(settings.get(defs.fleetFollowers), '');
    });

    test('switching leading off disbands the fleet', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      answers['POST /api/fleet/leave'] = (_) => {'ok': true};
      await settings.set(defs.fleetLeader, false);
      await settle();
      expect(fleet.followers, isEmpty);
      expect(sent.where((q) => q.url.path == '/api/fleet/leave'), hasLength(1));
    });

    test(
      'update the fleet asks each follower afresh, then this kiosk',
      () async {
        await build(
          prefs: {
            'ks.fleet.leader': true,
            'ks.fleet.followers': jsonEncode([
              {
                'id': 'bed',
                'name': 'Bedroom',
                'address': '192.168.1.71',
                'port': 2324,
                'token': 't',
              },
            ]),
          },
        );
        answers['GET /api/fleet/status'] = (_) => {
          'id': 'bed',
          'version': '2026.9.18',
          'leaderId': 'me',
        };
        answers['POST /api/commands/checkUpdateNow'] = (_) => {
          'ok': true,
          'data': {'availableVersion': '2026.9.19', 'progress': null},
        };
        answers['POST /api/commands/installUpdate'] = (_) => {
          'ok': true,
          'data': true,
        };
        await commands.execute('fleetSyncNow', const {});
        final r = await commands.execute('fleetUpdate', const {});
        final data = r.data as Map;
        expect(data['started'], ['Bedroom']);
        expect(data['self'], isFalse);
        expect(
          sent.where((q) => q.url.path == '/api/commands/installUpdate'),
          hasLength(1),
        );
      },
    );

    test('the uploaded APK is streamed to each follower and installed there, '
        'then here', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      final apk = await File(
        '${Directory.systemTemp.path}/ks_fleet_upload_test.apk',
      ).writeAsBytes(List<int>.generate(300, (i) => i % 251));
      addTearDown(() => apk.delete());
      // What the update manager reports once the admin uploaded a file.
      uploaded = {
        'version': '2026.9.20',
        'buildNumber': 21,
        'size': 300,
        'path': apk.path,
      };
      var selfInstalls = 0;
      commands.register(
        Command(
          name: 'installUploadedApk',
          description: 'install stub',
          handler: (_) async {
            selfInstalls++;
            return const CommandResult.ok(true);
          },
        ),
      );
      answers['GET /api/fleet/status'] = (_) => {
        'id': 'bed',
        'version': '2026.9.19',
        'leaderId': 'me',
      };
      // What the status says while the follower takes the upload: the
      // whole file has streamed by the time the answer is built.
      Map<String, Object?>? midway;
      List<Map<String, Object?>>? midwayRows;
      answers['POST /api/update/upload'] = (_) {
        // A copy: the manager keeps mutating the same map.
        midway = Map<String, Object?>.of(
          (fleet.status()['install'] as Map).cast<String, Object?>(),
        );
        midwayRows = (fleet.status()['followers'] as List)
            .cast<Map<String, Object?>>();
        return {
          'ok': true,
          'data': {
            'version': '2026.9.20',
            'buildNumber': 21,
            'currentBuild': 20,
          },
        };
      };
      answers['POST /api/commands/installUploadedApk'] = (_) => {
        'ok': true,
        'data': true,
      };
      await commands.execute('fleetSyncNow', const {});
      final before = changes;
      final r = await commands.execute('fleetInstallUploaded', const {});
      expect(r.ok, isTrue);
      final data = r.data as Map;
      expect(data['started'], ['Bedroom']);
      expect(data['self'], isTrue);
      expect(selfInstalls, 1);
      // Progress reached both UIs on the way: the row said Sending, the
      // install summary named the kiosk and the fraction.
      expect(midway?['sendingTo'], 'Bedroom');
      expect(midway?['progress'], 1.0);
      expect(midway?['done'], isFalse);
      expect(midwayRows?.single['status'], 'Sending 100%');
      expect(changes - before, greaterThanOrEqualTo(3));
      final after = (fleet.status()['install'] as Map).cast<String, Object?>();
      expect(after['done'], isTrue);
      expect(after['sendingTo'], isNull);
      expect(after['started'], ['Bedroom']);
      expect(after['self'], isTrue);
      expect(after['version'], '2026.9.20');
      expect(
        (fleet.status()['followers'] as List).cast<Map>().single['status'],
        'Installing',
      );
      final upload = sent.singleWhere(
        (q) => q.url.path == '/api/update/upload',
      );
      expect(upload.headers['Authorization'], 'Bearer t');
      expect(upload.bodyBytes, await apk.readAsBytes());
      expect(
        sent.where((q) => q.url.path == '/api/commands/installUploadedApk'),
        hasLength(1),
      );

      // A follower already on that build is skipped.
      sent.clear();
      answers['POST /api/update/upload'] = (_) => {
        'ok': true,
        'data': {'version': '2026.9.20', 'buildNumber': 21, 'currentBuild': 21},
      };
      final again = await commands.execute('fleetInstallUploaded', {
        'id': 'bed',
      });
      expect((again.data as Map)['skipped'], {
        'Bedroom': 'already on 2026.9.20',
      });
      expect(
        sent.where((q) => q.url.path == '/api/commands/installUploadedApk'),
        isEmpty,
      );
    });

    test('followers mirror the leader\'s custom wake word models', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      // The first tick runs on its own before the stubs below exist: a
      // leader that cannot read its models must not touch the followers'.
      await settle();
      expect(
        sent.where((q) => q.url.path == '/api/fleet/wake-models'),
        isEmpty,
      );
      sent.clear();
      final dir = await Directory.systemTemp.createTemp('ks_wake_models');
      addTearDown(() => dir.delete(recursive: true));
      final onnx = await File('${dir.path}/my_word.onnx').writeAsBytes([1, 2]);
      final json = await File('${dir.path}/luna.json').writeAsString('{}');
      final mine = {
        'openwakeword/my_word.onnx': 'aaa',
        'microwakeword/luna.json': 'bbb',
      };
      commands
        ..register(
          Command(
            name: 'customWakeModelsManifest',
            description: 'stub',
            handler: (_) async => CommandResult.ok({'files': mine}),
          ),
        )
        ..register(
          Command(
            name: 'customWakeModelPath',
            description: 'stub',
            handler: (p) async => CommandResult.ok({
              'path': p['path'] == 'openwakeword/my_word.onnx'
                  ? onnx.path
                  : json.path,
            }),
          ),
        );
      answers['GET /api/fleet/status'] = (_) => {
        'id': 'bed',
        'version': '2026.9.19',
        'leaderId': 'me',
      };
      answers['POST /api/fleet/apply'] = (_) => {
        'ok': true,
        'data': {'applied': 0},
      };
      // The follower has an old copy of one file and one the leader dropped.
      answers['GET /api/fleet/wake-models'] = (_) => {
        'ok': true,
        'data': {
          'files': {
            'openwakeword/my_word.onnx': 'old',
            'vswakeword/gone.onnx': 'ccc',
          },
        },
      };
      answers['PUT /api/fleet/wake-models'] = (_) => {'ok': true};
      answers['DELETE /api/fleet/wake-models'] = (_) => {'ok': true};
      await commands.execute('fleetSyncNow', const {});
      await settle();
      final puts = sent.where((q) => q.method == 'PUT').toList();
      expect(
        [for (final q in puts) q.url.queryParameters['path']],
        unorderedEquals([
          'openwakeword/my_word.onnx',
          'microwakeword/luna.json',
        ]),
      );
      expect(
        puts
            .firstWhere(
              (q) =>
                  q.url.queryParameters['path'] == 'openwakeword/my_word.onnx',
            )
            .bodyBytes,
        [1, 2],
      );
      expect(
        [
          for (final q in sent)
            if (q.method == 'DELETE') q.url.queryParameters['path'],
        ],
        ['vswakeword/gone.onnx'],
      );
      // In step: the next sync compares nothing until the leader's change.
      sent.clear();
      await commands.execute('fleetSyncNow', const {});
      await settle();
      expect(
        sent.where((q) => q.url.path == '/api/fleet/wake-models'),
        isEmpty,
      );
    });

    test('with nothing uploaded the fleet install says so', () async {
      await build(prefs: {'ks.fleet.leader': true});
      final r = await commands.execute('fleetInstallUploaded', const {});
      expect(r.ok, isFalse);
      expect(r.error, contains('No uploaded APK'));
    });

    test('the fleet export carries this kiosk and each follower, and names '
        'the ones that did not answer', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
            {
              'id': 'kit',
              'name': 'Kitchen',
              'address': '192.168.1.70',
              'port': 2324,
              'token': 'k',
            },
            // Invited, not accepted: no token, nothing to ask.
            {
              'id': 'hall',
              'name': 'Hall',
              'address': '192.168.1.72',
              'port': 2324,
              'invite': 'n',
            },
          ]),
        },
      );
      answers['GET /api/config/export'] = (req) =>
          req.url.host == '192.168.1.71'
          ? {
              'kind': 'kiosk-satellite-config',
              'version': 1,
              'deviceName': 'Bedroom',
              'settings': {'device.name': 'Bedroom'},
            }
          : http.Response(jsonEncode({'error': 'fleet token'}), 403);
      final r = await commands.execute('fleetExport', const {});
      expect(r.ok, isTrue, reason: r.error);
      final out = r.data as Map;
      expect(out['kind'], 'kiosk-satellite-fleet-config');
      final devices = (out['devices'] as List).cast<Map>();
      expect(devices.map((d) => d['id']), ['me', 'bed', 'kit']);
      expect(devices[0]['self'], isTrue);
      expect(devices[0]['name'], 'Living Room');
      expect((devices[0]['config'] as Map)['kind'], 'kiosk-satellite-config');
      expect((devices[1]['config'] as Map)['deviceName'], 'Bedroom');
      expect(devices[2]['config'], isNull);
      expect(devices[2]['error'], contains('Update this kiosk'));
      final asked = sent.where((q) => q.url.path == '/api/config/export');
      expect(asked.map((q) => q.headers['Authorization']).toSet(), {
        'Bearer t',
        'Bearer k',
      });
    });

    test('a kiosk that leads nobody exports only itself', () async {
      await build();
      final r = await commands.execute('fleetExport', const {});
      final devices = ((r.data as Map)['devices'] as List).cast<Map>();
      expect(devices.single['self'], isTrue);
      expect(sent.where((q) => q.url.path == '/api/config/export'), isEmpty);
    });

    test(
      'candidates are the kiosks heard, minus the followers, with whom they follow',
      () async {
        peers.add({
          'id': 'kit',
          'name': 'Kitchen',
          'version': '2026.9.19',
          'address': '192.168.1.70',
          'port': 2324,
          'self': false,
        });
        await build(
          prefs: {
            'ks.fleet.leader': true,
            'ks.fleet.followers': jsonEncode([
              {
                'id': 'bed',
                'name': 'Bedroom',
                'address': '192.168.1.71',
                'port': 2324,
                'token': 't',
              },
            ]),
          },
        );
        answers['GET /api/fleet/identity'] = (req) => {
          'id': 'kit',
          'name': 'Kitchen',
          'leader': false,
          'follows': 'Office',
        };
        final r = await commands.execute('fleetCandidates', const {});
        final list = r.data as List;
        expect(list, hasLength(1));
        expect((list.single as Map)['name'], 'Kitchen');
        expect((list.single as Map)['follows'], 'Office');
        expect((list.single as Map)['supported'], isTrue);
        // A kiosk on a build without Fleet Management answers its login
        // gate: listed as needing an update, and an invitation says why.
        answers['GET /api/fleet/identity'] = (_) =>
            http.Response('{"error":"unauthorized"}', 401);
        final again = await commands.execute('fleetCandidates', const {});
        expect(((again.data as List).single as Map)['supported'], isFalse);
        final invite = await commands.execute('fleetInvite', {'id': 'kit'});
        expect(invite.ok, isFalse);
        expect(invite.error, contains('without Fleet Management'));
        expect(sent.where((q) => q.url.path == '/api/fleet/invite'), isEmpty);
      },
    );
  });

  test('an untouched exclusion list follows the default as it grows', () async {
    formerHistory = [
      {'browser.zoom', 'screensaver.dim_level'},
    ];
    await build(
      prefs: {
        'ks.fleet.leader': true,
        'ks.fleet.profiles': jsonEncode([
          {
            'id': 'default',
            'name': 'Default',
            'categories': ['Gestures'],
            'credentials': [],
            'dashboard': false,
            'excluded': ['browser.zoom', 'screensaver.dim_level'],
          },
          {
            'id': 'own',
            'name': 'Own list',
            'categories': ['Gestures'],
            'credentials': [],
            'dashboard': false,
            'excluded': ['browser.zoom'],
          },
        ]),
      },
    );
    expect(fleet.defaultProfile.excluded, defs.fleetDefaultExcluded);
    expect(fleet.defaultProfile.excluded, contains('audio.media_volume'));
    // A list someone edited is theirs.
    expect(fleet.profiles.last.excluded, {'browser.zoom'});
    final stored = jsonDecode(settings.get(defs.fleetProfiles)) as List;
    expect(
      ((stored.first as Map)['excluded'] as List).toSet(),
      defs.fleetDefaultExcluded,
    );
  });

  test('a profile from before the realtime keys were credentials keeps '
      'them where Voice Satellite took them', () async {
    await build(
      prefs: {
        'ks.fleet.leader': true,
        'ks.fleet.profiles': jsonEncode([
          {
            'id': 'default',
            'name': 'Default',
            'categories': ['Voice Satellite', 'Gestures'],
            'credentials': ['ha.token'],
            'dashboard': false,
            'excluded': [],
          },
          {
            'id': 'own',
            'name': 'Own list',
            'categories': ['Gestures'],
            'credentials': [],
            'dashboard': false,
            'excluded': [],
          },
          {
            'id': 'new',
            'name': 'Saved since',
            'categories': ['Voice Satellite'],
            'credentials': [],
            'credentialsOffered': defs.fleetCredentialKeys.toList(),
            'dashboard': false,
            'excluded': [],
          },
        ]),
      },
    );
    final byId = {for (final p in fleet.profiles) p.id: p};
    expect(byId['default']!.credentials, {
      'ha.token',
      'voice.realtime_openai_api_key',
      'voice.realtime_xai_api_key',
      'voice.realtime_mcp_token',
    });
    // No Voice Satellite, nothing to keep.
    expect(byId['own']!.credentials, isEmpty);
    // Saved knowing them: left off on purpose.
    expect(byId['new']!.credentials, isEmpty);
    // Stored with the marker: switching them off later sticks.
    final stored = jsonDecode(settings.get(defs.fleetProfiles)) as List;
    for (final p in stored) {
      expect(
        ((p as Map)['credentialsOffered'] as List).toSet(),
        defs.fleetCredentialKeys,
      );
    }
    final off = await commands.execute('fleetSetProfile', {
      'profile': {...byId['default']!.toJson(), 'credentials': <String>[]},
    });
    expect(off.ok, isTrue);
    await fleet.dispose();
    await build(
      prefs: {
        'ks.fleet.leader': true,
        'ks.fleet.profiles': settings.get(defs.fleetProfiles),
      },
    );
    expect(fleet.defaultProfile.credentials, isEmpty);
  });

  test('a profile from before the intercom gains its key where the default '
      'credentials were never touched (issue #1156)', () async {
    const realtime = [
      'voice.realtime_openai_api_key',
      'voice.realtime_xai_api_key',
      'voice.realtime_mcp_token',
    ];
    await build(
      prefs: {
        'ks.fleet.leader': true,
        'ks.fleet.profiles': jsonEncode([
          // Saved before the realtime keys: the upgrade adds them too.
          {
            'id': 'default',
            'name': 'Default',
            'categories': ['Voice Satellite'],
            'credentials': ['sendspin.ma_token', 'screensaver.immich_api_key'],
            'dashboard': false,
            'excluded': [],
          },
          // Saved by the realtime upgrade, which already offered the key.
          {
            'id': 'upgraded',
            'name': 'Upgraded',
            'categories': ['Voice Satellite'],
            'credentials': [
              'sendspin.ma_token',
              'screensaver.immich_api_key',
              ...realtime,
            ],
            'credentialsOffered': defs.fleetCredentialKeys.toList(),
            'dashboard': false,
            'excluded': [],
          },
          // A list someone edited is theirs.
          {
            'id': 'edited',
            'name': 'Edited',
            'categories': ['Gestures'],
            'credentials': ['sendspin.ma_token'],
            'credentialsOffered': defs.fleetCredentialKeys.toList(),
            'dashboard': false,
            'excluded': [],
          },
        ]),
      },
    );
    final byId = {for (final p in fleet.profiles) p.id: p};
    expect(byId['default']!.credentials, {
      ...defs.fleetDefaultCredentials,
      ...realtime,
    });
    expect(byId['upgraded']!.credentials, {
      ...defs.fleetDefaultCredentials,
      ...realtime,
    });
    expect(byId['edited']!.credentials, {'sendspin.ma_token'});
    final stored = jsonDecode(settings.get(defs.fleetProfiles)) as List;
    for (final p in stored) {
      expect(
        ((p as Map)['credentialsDefault'] as List).toSet(),
        defs.fleetDefaultCredentials,
      );
    }
    // Switched off now, the key stays off on the next load.
    final off = await commands.execute('fleetSetProfile', {
      'profile': {
        ...byId['default']!.toJson(),
        'credentials': ['sendspin.ma_token', 'screensaver.immich_api_key'],
      },
    });
    expect(off.ok, isTrue);
    await fleet.dispose();
    await build(
      prefs: {
        'ks.fleet.leader': true,
        'ks.fleet.profiles': settings.get(defs.fleetProfiles),
      },
    );
    expect(fleet.defaultProfile.credentials, {
      'sendspin.ma_token',
      'screensaver.immich_api_key',
    });
  });

  test('the recorded former default credentials lead to the current one', () {
    var previous = <String>{};
    for (final former in defs.fleetFormerDefaultCredentials) {
      expect(former, isNot(equals(defs.fleetDefaultCredentials)));
      expect(defs.fleetDefaultCredentials.containsAll(former), isTrue);
      expect(former.containsAll(previous), isTrue);
      previous = former;
    }
  });

  test('the brightness curve travels as one: its middle points go where '
      'Minimum brightness goes', () {
    final mids = [
      defs.adaptivePoint2Position,
      defs.adaptivePoint2Level,
      defs.adaptivePoint3Position,
      defs.adaptivePoint3Level,
      defs.adaptiveInverted,
    ];
    // Screen & Audio with the default exclusions: the ends stay per room,
    // and so do the middle points.
    const kept = SyncProfile(categories: {'Screen & Audio'});
    expect(FleetSyncManager.syncs(defs.adaptiveMinBrightness, kept), isFalse);
    for (final def in mids) {
      expect(FleetSyncManager.syncs(def, kept), isFalse, reason: def.key);
    }
    // Brought back into the profile, the whole curve travels.
    const shared = SyncProfile(categories: {'Screen & Audio'}, excluded: {});
    expect(FleetSyncManager.syncs(defs.adaptiveMinBrightness, shared), isTrue);
    for (final def in mids) {
      expect(FleetSyncManager.syncs(def, shared), isTrue, reason: def.key);
    }
    // Hidden, so a profile never lists them among its exclusions.
    for (final def in mids) {
      expect(def.hidden, isTrue);
      expect(defs.fleetDefaultExcluded, isNot(contains(def.key)));
    }
  });

  test('the recorded former default exclusions lead to the current one', () {
    // Each former list is a real past default: a strict subset of the
    // current one, never equal to it (or every fresh profile would be
    // rewritten at load) and growing across the history.
    var previous = <String>{};
    for (final former in defs.fleetFormerDefaultExcluded) {
      expect(former, isNot(equals(defs.fleetDefaultExcluded)));
      expect(defs.fleetDefaultExcluded.containsAll(former), isTrue);
      expect(former.containsAll(previous), isTrue);
      previous = former;
    }
    // The per-chime volumes joined last (issue #998): the newest former
    // list is the current one without them.
    expect(
      defs.fleetFormerDefaultExcluded.last,
      defs.fleetDefaultExcluded.difference({
        'voice_chimes.wake_volume',
        'voice_chimes.done_volume',
        'voice_chimes.error_volume',
        'voice_chimes.alert_volume',
        'voice_chimes.announce_volume',
      }),
    );
  });

  test('the Never synced table in docs/fleet.md matches the flags', () {
    // The doc lists every per device key by name (fleet.* as one entry):
    // a key flagged in the code must be there and the doc must not name a
    // key the code syncs.
    final doc = File('../docs/fleet.md').readAsStringSync();
    final section = doc
        .split(RegExp('## Never synced', caseSensitive: false))[1]
        .split('## Remote API')[0];
    final listed = RegExp(
      r'`([a-z_.*]+)`',
    ).allMatches(section).map((m) => m[1]!).toSet();
    final flagged = {
      for (final d in defs.allSettings)
        if (d.perDevice) d.key.startsWith('fleet.') ? 'fleet.*' : d.key,
    };
    expect(listed, flagged);
  });

  test('the status words wear the agreed tones', () {
    final f = Follower(id: 'x', name: 'X', address: 'a', port: 1, token: 't')
      ..online = true
      ..appliedRevision = '3'
      ..lastSyncAt = DateTime.now().millisecondsSinceEpoch - 120000;
    final now = DateTime.now().millisecondsSinceEpoch;
    expect(FleetSyncManager.phaseOf(f, '2026.9.19', '3', now), {
      'phase': 'synced',
      'status': 'Synced 2 min ago',
      'tone': 'ok',
    });
    f.version = '2026.9.20';
    expect(
      FleetSyncManager.phaseOf(f, '2026.9.19', '3', now)['status'],
      'Runs 2026.9.20, this kiosk needs an update',
    );
    f.version = '2026.9.19+118';
    f.online = false;
    expect(FleetSyncManager.phaseOf(f, '2026.9.19', '3', now)['tone'], 'muted');
    // An update on its way outranks the version gap it closes.
    f
      ..online = true
      ..version = '2026.9.18'
      ..sending = 0.4;
    expect(FleetSyncManager.phaseOf(f, '2026.9.19', '3', now), {
      'phase': 'updating',
      'status': 'Sending 40%',
      'tone': 'muted',
    });
    f
      ..sending = null
      ..update = {'installing': true};
    expect(
      FleetSyncManager.phaseOf(f, '2026.9.19', '3', now)['status'],
      'Installing',
    );
  });

  test('a follower reports that it is installing, so the leader keeps '
      'saying so between polls', () async {
    await build();
    installing = true;
    final st = await fleet.followerStatus();
    expect((st['update'] as Map)['installing'], isTrue);
  });

  group('the Updates only profile', () {
    test('ships built in after the Default, syncs nothing and stays', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.profiles': jsonEncode([
            {
              'id': 'own',
              'name': 'Own',
              'categories': ['Gestures'],
              'credentials': [],
              'dashboard': false,
              'excluded': [],
            },
            // A stored copy (an edit that somehow landed) is dropped.
            {
              'id': 'updates-only',
              'name': 'Edited',
              'categories': ['Gestures'],
              'credentials': [],
              'dashboard': false,
              'excluded': [],
            },
          ]),
        },
      );
      expect(fleet.profiles.map((p) => p.id), [
        'default',
        'updates-only',
        'own',
      ]);
      final p = fleet.profiles[1];
      expect(p.name, 'Updates only');
      expect(p.isBuiltIn, isTrue);
      expect(p.describe(), 'Nothing syncs. Only updates are pushed.');
      expect(fleet.profileSettings(p), isEmpty);
      // Never stored.
      final stored = jsonDecode(settings.get(defs.fleetProfiles)) as List;
      expect(stored.map((e) => (e as Map)['id']), ['default', 'own']);

      final edit = await commands.execute('fleetSetProfile', {
        'profile': {
          ...p.toJson(),
          'categories': ['Gestures'],
        },
      });
      expect(edit.ok, isFalse);
      expect(edit.error, contains('cannot be changed'));
      final del = await commands.execute('fleetDeleteProfile', {
        'id': 'updates-only',
      });
      expect(del.ok, isFalse);
      expect(del.error, contains('stays'));
      final dup = await commands.execute('fleetSetProfile', {
        'profile': {...p.toJson(), 'id': '', 'name': 'Some settings'},
      });
      expect(dup.ok, isTrue);
      expect(fleet.profiles.last.name, 'Some settings');
      expect(fleet.profiles.last.categories, isEmpty);
    });

    test('a follower can be put on it and then gets no settings', () async {
      await build(
        prefs: {
          'ks.fleet.leader': true,
          'ks.fleet.followers': jsonEncode([
            {
              'id': 'bed',
              'name': 'Bedroom',
              'address': '192.168.1.71',
              'port': 2324,
              'token': 't',
            },
          ]),
        },
      );
      final r = await commands.execute('fleetAssignProfile', {
        'id': 'bed',
        'profile': 'updates-only',
      });
      expect(r.ok, isTrue);
      final status =
          (await commands.execute('fleetStatus', const {})).data as Map;
      final f = (status['followers'] as List).single as Map;
      expect(f['profile'], 'updates-only');
      expect(
        fleet.profileSettings(fleet.profileFor(fleet.followers.single)),
        isEmpty,
      );
    });
  });
  group('plugins in the fleet', () {
    final zip = Uint8List.fromList(List<int>.generate(64, (i) => i));
    final zipHash = sha256.convert(zip).toString();
    final localHash = 'b' * 64;

    Map<String, Object?> plugin(
      String id,
      String hash, {
      bool enabled = true,
      Map<String, Object?> config = const {},
    }) => {
      'id': id,
      'name': id == 'hello' ? 'Hello' : 'Local',
      'version': '1.0.0',
      'sha256': hash,
      'source': {'repository': 'https://github.com/me/$id'},
      'enabled': enabled,
      'config': config,
      'actionOptions': const {},
      'secretKeys': const ['token'],
      'kept': true,
    };

    Map<String, Object> leaderPrefs({List<String> credentials = const []}) => {
      'ks.fleet.leader': true,
      'ks.fleet.followers': jsonEncode([
        {
          'id': 'bed',
          'name': 'Bedroom',
          'address': '192.168.1.71',
          'port': 2324,
          'token': 't',
        },
      ]),
      'ks.fleet.profiles': jsonEncode([
        {
          ...SyncProfile.initial.toJson(),
          'credentials': credentials,
          'plugins': ['hello'],
        },
      ]),
    };

    void followerAnswers({Map<String, String> plugins = const {}}) {
      answers['GET /api/fleet/status'] = (_) => {
        'id': 'bed',
        'version': '2026.9.19',
        'leaderId': 'me',
        'plugins': plugins,
      };
      answers['POST /api/fleet/apply'] = (_) => {
        'ok': true,
        'data': {'applied': 0},
      };
      answers['PUT /api/fleet/plugins'] = (_) => {'ok': true};
    }

    Map<String, Object?> lastPush() =>
        jsonDecode(sent.lastWhere((q) => q.url.path == '/api/fleet/apply').body)
            as Map<String, Object?>;

    test('a profile without plugins hashes as it did before', () async {
      final host = _FakePlugins()..state = [plugin('hello', zipHash)];
      await build(
        prefs: {...leaderPrefs(), 'ks.fleet.profiles': ''},
        pluginHost: host,
      );
      final f = fleet.followers.single;
      expect(
        fleet.fingerprintFor(f),
        FleetSyncManager.fingerprintOf(
          fleet.profileSettings(fleet.profileFor(f)),
        ),
      );
    });

    test('the package goes ahead of the push and the secrets stay home '
        'unless the profile includes them', () async {
      final dir = await Directory.systemTemp.createTemp('ks_fleet_plugin');
      addTearDown(() => dir.delete(recursive: true));
      final file = await File('${dir.path}/hello.zip').writeAsBytes(zip);
      final host = _FakePlugins()
        ..state = [
          plugin('hello', zipHash, config: {'color': 'red', 'token': 's3'}),
          plugin('local', localHash),
        ]
        ..package = (_) => file.path;
      await build(prefs: leaderPrefs(), pluginHost: host);
      // The tick a leader runs on its own at start, before the answers.
      await settle();
      sent.clear();
      followerAnswers();
      await commands.execute('fleetSyncNow', const {});
      await settle();
      final put = sent.singleWhere((q) => q.method == 'PUT');
      expect(put.url.path, '/api/fleet/plugins');
      expect(put.url.queryParameters['sha256'], zipHash);
      expect(put.bodyBytes, zip);
      final sentPlugins = lastPush()['plugins'] as List;
      expect(sentPlugins.single['id'], 'hello');
      expect(sentPlugins.single['config'], {'color': 'red'});
      expect(sentPlugins.single['secrets'], isFalse);

      // With Plugin secrets the token travels, and a follower that already
      // runs the package gets no second copy.
      sent.clear();
      followerAnswers(plugins: {'hello': zipHash});
      final profile = fleet.defaultProfile.copyWith(
        credentials: {defs.fleetPluginSecrets},
      );
      await commands.execute('fleetSetProfile', {'profile': profile.toJson()});
      await commands.execute('fleetSyncNow', const {});
      await settle();
      expect(sent.where((q) => q.method == 'PUT'), isEmpty);
      expect((lastPush()['plugins'] as List).single['config'], {
        'color': 'red',
        'token': 's3',
      });
    });

    test('a package this kiosk cannot pass on is reported once', () async {
      final host = _FakePlugins()..state = [plugin('hello', zipHash)];
      await build(prefs: leaderPrefs(), pluginHost: host);
      // The tick a leader runs on its own at start, before the answers.
      await settle();
      sent.clear();
      followerAnswers();
      await commands.execute('fleetSyncNow', const {});
      await settle();
      final row = (fleet.status()['followers'] as List).single as Map;
      expect(row['phase'], 'error');
      expect(row['status'], 'Reinstall Hello on this kiosk to sync it');
      final calls = host.packageCalls;
      // A change elsewhere pushes again without asking for the package.
      await settings.set(defs.screensaverMode, 'black');
      await Future<void>.delayed(const Duration(milliseconds: 2600));
      expect(host.packageCalls, calls);
    });

    test('without a plugin listing the leader holds the push', () async {
      final host = _FakePlugins()..failState = true;
      await build(prefs: leaderPrefs(), pluginHost: host);
      // The tick a leader runs on its own at start, before the answers.
      await settle();
      sent.clear();
      followerAnswers();
      await commands.execute('fleetSyncNow', const {});
      await settle();
      expect(sent.where((q) => q.url.path == '/api/fleet/apply'), isEmpty);
    });

    Map<String, Object> followerPrefs() => {
      'ks.fleet.leader_info': jsonEncode({'id': 'lead', 'name': 'Living Room'}),
    };

    Future<void> stage(Uint8List bytes, String hash) async {
      final r = await commands.execute('fleetStagePlugin', {
        'sha256': hash,
        'stream': Stream<List<int>>.value(bytes),
        'length': bytes.length,
      });
      expect(r.ok, isTrue, reason: r.error);
    }

    Future<Map<String, Object?>> push(
      List<Map<String, Object?>> plugins,
    ) async {
      final r = await commands.execute('fleetApply', {
        'revision': 'r1',
        'version': '2026.9.19',
        'settings': const {},
        'plugins': plugins,
      });
      expect(r.ok, isTrue, reason: r.error);
      return (r.data as Map).cast<String, Object?>();
    }

    test('a follower installs what was staged, takes the settings and '
        'removes only what the fleet installed', () async {
      final host = _FakePlugins()
        ..state = [plugin('local', localHash, enabled: false)]
        ..ids = {zipHash: 'hello'};
      await build(prefs: followerPrefs(), pluginHost: host);
      await stage(zip, zipHash);
      final hello = FleetSyncManager.pluginEntry(
        plugin('hello', zipHash, config: {'color': 'blue'}),
        secrets: false,
      );
      final local = FleetSyncManager.pluginEntry(
        plugin('local', localHash),
        secrets: false,
      );
      final data = await push([hello, local]);
      expect(data['pluginErrors'], isEmpty);
      expect(host.installs, [zipHash]);
      expect(host.configured.keys, unorderedEquals(['hello', 'local']));
      expect(host.byId('local')['enabled'], isTrue);
      expect(fleet.syncedPlugins['hello']?['installed'], isTrue);
      expect(fleet.syncedPlugins['local']?['installed'], isFalse);
      final st = await commands.execute('fleetFollowerStatus', const {});
      expect((st.data as Map)['plugins'], {
        'local': localHash,
        'hello': zipHash,
      });

      // The leader stops sending both: the one it installed goes, the one
      // that was here first stays.
      await push(const []);
      expect(host.removed, ['hello']);
      expect(fleet.syncedPlugins, isEmpty);
    });

    test('a package that never arrived is reported to the leader', () async {
      final host = _FakePlugins();
      await build(prefs: followerPrefs(), pluginHost: host);
      final data = await push([
        FleetSyncManager.pluginEntry(plugin('hello', zipHash), secrets: false),
      ]);
      expect((data['pluginErrors'] as Map)['hello'], {
        'sha256': zipHash,
        'name': 'Hello',
        'message': 'The package did not arrive',
      });
      final following = fleet.status()['following'] as Map;
      expect(following['pluginErrors'], [
        {'name': 'Hello', 'message': 'The package did not arrive'},
      ]);
    });

    test('a staged package must match its hash', () async {
      await build(prefs: followerPrefs(), pluginHost: _FakePlugins());
      final r = await commands.execute('fleetStagePlugin', {
        'sha256': 'c' * 64,
        'stream': Stream<List<int>>.value(zip),
        'length': zip.length,
      });
      expect(r.ok, isFalse);
      expect(r.error, 'Package SHA-256 does not match');
    });

    test('a local change to a synced plugin marks the kiosk dirty', () async {
      final host = _FakePlugins()..state = [plugin('local', localHash)];
      await build(prefs: followerPrefs(), pluginHost: host);
      await push([
        FleetSyncManager.pluginEntry(
          plugin('local', localHash, config: {'color': 'red'}),
          secrets: false,
        ),
      ]);
      expect(settings.get(defs.fleetAppliedRevision), 'r1');
      // A secret changed here is this kiosk's own business.
      host.byId('local')['config'] = {'color': 'red', 'token': 'mine'};
      bus.publish(const RemoteStatusChanged('plugin-settings'));
      await settle();
      expect(settings.get(defs.fleetAppliedRevision), 'r1');
      host.byId('local')['config'] = {'color': 'green'};
      bus.publish(const RemoteStatusChanged('plugin-settings'));
      await settle();
      expect(settings.get(defs.fleetAppliedRevision), '');
      final st = await commands.execute('fleetFollowerStatus', const {});
      expect((st.data as Map)['dirty'], isTrue);
    });
  });
}

/// The plugin runtime as Fleet Management sees it, in memory.
class _FakePlugins implements FleetPluginHost {
  List<Map<String, Object?>> state = [];

  /// Which plugin id each package hash installs.
  Map<String, String> ids = {};
  String? Function(String id) package = (_) => null;
  bool failState = false;
  int packageCalls = 0;
  final installs = <String>[];
  final configured = <String, Map<String, Object?>>{};
  final removed = <String>[];

  Map<String, Object?> byId(String id) =>
      state.firstWhere((p) => p['id'] == id);

  @override
  Future<List<Map<String, Object?>>> fleetState() async {
    if (failState) throw StateError('no runtime');
    return [
      for (final p in jsonDecode(jsonEncode(state)) as List)
        (p as Map).cast<String, Object?>(),
    ];
  }

  @override
  Future<String?> fleetPackage(String id) async {
    packageCalls++;
    return package(id);
  }

  @override
  Future<void> fleetInstall(
    Uint8List bytes, {
    required String sha256,
    Map<String, Object?>? source,
  }) async {
    installs.add(sha256);
    final id = ids[sha256]!;
    state
      ..removeWhere((p) => p['id'] == id)
      ..add({
        'id': id,
        'name': id == 'hello' ? 'Hello' : id,
        'version': '1.0.0',
        'sha256': sha256,
        'source': source,
        'enabled': false,
        'config': <String, Object?>{},
        'actionOptions': <String, Object?>{},
        'secretKeys': const ['token'],
        'kept': true,
      });
  }

  @override
  Future<void> fleetConfigure(String id, Map<String, Object?> entry) async {
    configured[id] = entry;
    final p = byId(id);
    final own = (p['config'] as Map?) ?? const {};
    p
      ..['enabled'] = entry['enabled'] == true
      ..['config'] = {
        if (own.containsKey('token')) 'token': own['token'],
        ...(entry['config'] as Map).cast<String, Object?>(),
      }
      ..['actionOptions'] = entry['actionOptions'];
  }

  @override
  Future<void> fleetRemove(String id) async {
    removed.add(id);
    state.removeWhere((p) => p['id'] == id);
  }
}
