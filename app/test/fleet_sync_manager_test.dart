import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/fleet/fleet_sync_manager.dart';
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

  Future<void> build({Map<String, Object> prefs = const {}}) async {
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
    commands.register(
      Command(
        name: 'getUpdateStatus',
        description: 'update stub',
        handler: (_) async => CommandResult.ok({
          'currentVersion': '2026.9.19',
          'availableVersion': null,
          'progress': null,
        }),
      ),
    );
    fleet = FleetSyncManager(bus, commands, log, settings)
      ..formerDefaultExcluded = formerHistory
      ..clientFactory = () => MockClient((req) async {
        sent.add(req);
        final key = '${req.method} ${req.url.path}';
        final answer = answers[key];
        if (answer == null) return http.Response('not found', 404);
        final out = answer(req);
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
        // A new follower shares the household credentials, not the user.
        expect(SyncProfile.initial.credentials, {
          'sendspin.ma_token',
          'screensaver.immich_api_key',
        });
        expect(
          SyncProfile.parse({
            'categories': [],
            'credentials': ['ha.token', 'bogus'],
          })!.describe(),
          'Categories: 0 of 16. Credentials: 1 of 3. Excluded: 28.',
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
        'Kiosk only',
      ]);
      expect((profiles[1] as Map)['kiosks'], 1);
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
  });
}
