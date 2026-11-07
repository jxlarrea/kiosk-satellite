import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/remote_player.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_client.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_player.dart';

/// The Now Playing chip's group menu, read out of each source's own
/// picture of its players: who leads, who is in and who could join.
/// A server answering players/all with a fixed list, or failing.
class _ListingApi extends MusicAssistantApi {
  _ListingApi(this.players) : super(baseUrl: 'ma.local', token: 't');

  final List<Object?>? players;

  @override
  Future<MusicAssistantResult> call(
    String command, {
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 15),
  }) async => players == null
      ? const MusicAssistantResult.failure('offline')
      : MusicAssistantResult.success(players, const {});
}

void main() {
  group('MusicAssistantApi.groupFrom', () {
    final players = [
      {
        'player_id': 'tablet',
        'display_name': 'Office Tablet',
        'provider': 'sendspin--1',
        'type': 'player',
        'group_members': ['echo'],
        'can_group_with': ['sendspin--1', 'lounge'],
      },
      {
        'player_id': 'echo',
        'display_name': 'Echo Show',
        'provider': 'sendspin--1',
        'type': 'player',
        'synced_to': 'tablet',
      },
      {
        'player_id': 'bedroom',
        'display_name': 'Bedroom',
        'provider': 'sendspin--1',
        'type': 'player',
        'available': false,
      },
      {
        'player_id': 'lounge',
        'display_name': 'Lounge Sonos',
        'provider': 'sonos--1',
        'type': 'player',
      },
      {
        'player_id': 'kitchen',
        'display_name': 'Kitchen Sonos',
        'provider': 'sonos--1',
        'type': 'player',
      },
      {
        'player_id': 'everywhere',
        'display_name': 'Everywhere',
        'provider': 'ugp',
        'type': 'group',
        'can_group_with': ['sendspin--1'],
      },
      {
        'player_id': 'off',
        'display_name': 'Disabled',
        'provider': 'sendspin--1',
        'enabled': false,
      },
    ];

    test('the leader lists its members first, then who could join', () {
      final group = MusicAssistantApi.groupFrom(players, 'tablet')!;
      expect(group.leaderId, 'tablet');
      expect(group.leaderName, 'Office Tablet');
      expect(group.members.map((m) => m.name), [
        'Echo Show',
        'Bedroom',
        'Lounge Sonos',
      ]);
      expect(group.members.map((m) => m.inGroup), [true, false, false]);
      // An offline candidate is listed as such; a group player and a
      // disabled one are not candidates at all.
      expect(group.members[1].available, isFalse);
    });

    test('a synced member answers with its leader as the title and itself '
        'as a row', () {
      final group = MusicAssistantApi.groupFrom(players, 'echo')!;
      expect(group.selfId, 'echo');
      expect(group.leaderId, 'tablet');
      expect(group.leaderName, 'Office Tablet');
      expect(group.leads, isFalse);
      // The same rows the leader sees: the leader is the title on both.
      expect(group.members.map((m) => m.id), ['echo', 'bedroom', 'lounge']);
      expect(group.members.first.inGroup, isTrue);
      expect(MusicAssistantApi.groupFrom(players, 'tablet')!.leads, isTrue);
    });

    test('each player carries its own volume for the menu (issue #867)', () {
      final levels = [
        {...players[0], 'volume_level': 44},
        {...players[1], 'volume_level': 22.4},
        // A player Music Assistant cannot set the volume of.
        {...players[2], 'volume_level': 10, 'volume_control': 'none'},
        ...players.skip(3),
      ];
      final group = MusicAssistantApi.groupFrom(levels, 'echo')!;
      expect(group.leaderVolume, 44);
      expect(group.members.map((m) => m.volume), [22, null, null]);
    });

    test('an unknown player is no group', () {
      expect(MusicAssistantApi.groupFrom(players, 'ghost'), isNull);
    });

    test('a wrapper is found by its members or by the name the device '
        'registered under', () {
      // One server names a universal player after the player it wraps;
      // another gives it a hash and lists the wrapped id among its
      // members; the name this device joined with is the last resort.
      final byId = <String, Map<Object?, Object?>>{
        'upbf0e4345': {
          'name': 'Office Display',
          'static_group_members': ['sendspin--3177f9a8e3b7'],
        },
        'upother': {
          'name': 'Kitchen',
          'static_group_members': ['x'],
        },
        'hiddenmatch': {'name': 'Office Display', 'hide_in_ui': true},
      };
      expect(MusicAssistantApi.ownPlayerId(byId, '3177f9a8e3b7'), 'upbf0e4345');
      expect(
        MusicAssistantApi.ownPlayerId(
          byId,
          'nowhere',
          ownName: 'office display',
        ),
        'upbf0e4345',
      );
      expect(MusicAssistantApi.ownPlayerId(byId, 'nowhere'), '');
      expect(MusicAssistantApi.ownPlayerId(byId, 'upother'), 'upother');
    });

    test('a hash wrapper is found by the output protocol naming the client '
        '(issue #1334)', () {
      // Music Assistant 2.10's players/all leaves the bare Sendspin player
      // out. A universal player with a hash id, renamed in Music Assistant,
      // names the client only in its output protocols.
      final byId = <String, Map<Object?, Object?>>{
        'syncgroup_4qmxyzfg': {
          'player_id': 'syncgroup_4qmxyzfg',
          'name': 'Whole House',
          'group_members': ['b9d9137b42c0'],
          'output_protocols': [
            {'output_protocol_id': 'native', 'protocol_domain': 'sync_group'},
          ],
        },
        'up9498417e': {
          'player_id': 'up9498417e',
          'name': 'Living Room',
          'output_protocols': [
            {
              'output_protocol_id': 'B9D9137B42C0',
              'protocol_domain': 'sendspin',
            },
          ],
        },
      };
      expect(MusicAssistantApi.ownPlayerId(byId, 'b9d9137b42c0'), 'up9498417e');
      expect(
        MusicAssistantApi.standsFor(byId['up9498417e']!, 'b9d9137b42c0'),
        isTrue,
      );
      expect(
        MusicAssistantApi.standsFor(
          byId['syncgroup_4qmxyzfg']!,
          'b9d9137b42c0',
        ),
        isFalse,
      );
      expect(MusicAssistantApi.standsFor(byId['up9498417e']!, ''), isFalse);
    });

    test('a player the list lacks is named with what the list holds', () async {
      final api = _ListingApi(players);
      expect(await api.fetchGroup('tablet-x'), isNull);
      // The log line names the id asked for, the count and the ids that
      // share its start, so a server listing the player under another
      // shape shows itself.
      expect(api.groupProblem, 'no player tablet-x among 7: tablet');
      expect(await api.fetchGroup('tablet'), isNotNull);
      expect(api.groupProblem, isNull);
      final down = _ListingApi(null);
      expect(await down.fetchGroup('tablet'), isNull);
      expect(down.groupProblem, startsWith('players/all: '));
    });

    test('a bare client id answers for the wrapper that carries it', () {
      // Music Assistant lists a Sendspin device only as its universal
      // player, the client id embedded in the wrapper's id, with a name
      // key and hide_in_ui in place of display_name and hidden.
      final wrapped = [
        {
          'player_id': 'upabc123',
          'name': 'Office Tablet',
          'provider': 'universal_player',
          'type': 'player',
          'group_members': <String>[],
          'can_group_with': ['upecho', 'uphidden'],
        },
        {
          'player_id': 'upecho',
          'name': 'Echo Show',
          'provider': 'universal_player',
          'type': 'player',
        },
        {
          'player_id': 'uphidden',
          'name': 'Hidden',
          'provider': 'universal_player',
          'type': 'player',
          'hide_in_ui': true,
        },
      ];
      final group = MusicAssistantApi.groupFrom(wrapped, 'abc123')!;
      expect(group.leaderId, 'upabc123');
      expect(group.leaderName, 'Office Tablet');
      expect(group.members.map((m) => m.id), ['upecho']);
    });
  });

  group('SonosPlayer.groupFrom', () {
    const topology =
        '<ZoneGroupState><ZoneGroups>'
        '<ZoneGroup Coordinator="RINCON_A" ID="RINCON_A:1">'
        '<ZoneGroupMember UUID="RINCON_A" Location="http://10.0.0.1:1400/x" ZoneName="Office"/>'
        '<ZoneGroupMember UUID="RINCON_B" Location="http://10.0.0.2:1400/x" ZoneName="Hall"/>'
        '</ZoneGroup>'
        '<ZoneGroup Coordinator="RINCON_C" ID="RINCON_C:2">'
        '<ZoneGroupMember UUID="RINCON_C" Location="http://10.0.0.3:1400/x" ZoneName="Bedroom"/>'
        '</ZoneGroup>'
        '</ZoneGroups></ZoneGroupState>';

    test('the coordinator leads, its rooms are in, the rest could join', () {
      final groups = SonosClient.parseZoneGroups(topology);
      final group = SonosPlayer.groupFrom(groups, 'RINCON_B')!;
      expect(group.selfId, 'RINCON_B');
      expect(group.leaderId, 'RINCON_A');
      expect(group.leaderName, 'Office');
      expect(group.leads, isFalse);
      // The coordinator is the title; the room itself is a grouped row.
      expect(group.members.map((m) => m.name), ['Hall', 'Bedroom']);
      expect(group.members.map((m) => m.inGroup), [true, false]);
      final led = SonosPlayer.groupFrom(groups, 'RINCON_A')!;
      expect(led.leads, isTrue);
      expect(led.members.map((m) => m.name), ['Hall', 'Bedroom']);
    });

    test('a room the household does not know is no group', () {
      final groups = SonosClient.parseZoneGroups(topology);
      expect(SonosPlayer.groupFrom(groups, 'RINCON_Z'), isNull);
    });
  });

  // The speaker selection pill filter (issue #974): only the picked
  // players are offered, while the group itself always shows.
  group('RemoteGroup.allowing', () {
    const group = RemoteGroup(
      selfId: 'office',
      leaderId: 'tablet',
      leaderName: 'Tablet',
      leaderVolume: 40,
      members: [
        GroupMember(id: 'office', name: 'Office', inGroup: true),
        GroupMember(id: 'bedroom', name: 'Bedroom', inGroup: true),
        GroupMember(id: 'garden', name: 'Garden Room', inGroup: false),
        GroupMember(id: 'kids', name: 'Kids Room', inGroup: false),
        GroupMember(id: 'lounge', name: 'Lounge', inGroup: false),
      ],
    );

    test('only the allowed players can join', () {
      final menu = group.allowing({'lounge', 'garden'});
      expect(menu.members.map((m) => m.id), [
        'office',
        'bedroom',
        'garden',
        'lounge',
      ]);
      expect(menu.leaderId, 'tablet');
      expect(menu.leaderName, 'Tablet');
      expect(menu.leaderVolume, 40);
    });

    test('the shown player keeps its row even when it is not grouped', () {
      const alone = RemoteGroup(
        selfId: 'office',
        leaderId: 'office',
        leaderName: 'Office',
        members: [
          GroupMember(id: 'kids', name: 'Kids Room', inGroup: false),
          GroupMember(id: 'lounge', name: 'Lounge', inGroup: false),
        ],
      );
      expect(alone.allowing({'lounge'}).members.map((m) => m.id), ['lounge']);
    });

    test('no picks offers every player', () {
      expect(identical(group.allowing(const {}), group), isTrue);
    });
  });

  group('sendspin.speaker_pill_players', () {
    test('reads back a list of ids and drops anything else', () {
      expect(decodeSpeakerPillPlayers('["ma:a","sonos:B"]'), [
        'ma:a',
        'sonos:B',
      ]);
      expect(decodeSpeakerPillPlayers('[1,"",null,"ma:a"]'), ['ma:a']);
      expect(decodeSpeakerPillPlayers('{"ma:a":true}'), isEmpty);
      expect(decodeSpeakerPillPlayers('not json'), isEmpty);
    });

    test('stores a clean list, each id once', () {
      expect(
        normalizeSpeakerPillPlayers('["ma:a",3,"ma:a","sonos:B"]'),
        '["ma:a","sonos:B"]',
      );
      expect(normalizeSpeakerPillPlayers('oops'), '[]');
    });
  });
}
