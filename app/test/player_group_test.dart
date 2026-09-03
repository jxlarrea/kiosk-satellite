import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/music_assistant_api.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_client.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_player.dart';

/// The Now Playing chip's group menu, read out of each source's own
/// picture of its players: who leads, who is in and who could join.
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

    test('an unknown player is no group', () {
      expect(MusicAssistantApi.groupFrom(players, 'ghost'), isNull);
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
}
