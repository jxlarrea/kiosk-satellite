import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_client.dart';
import 'package:kiosk_satellite/managers/sendspin/sonos_player.dart';
import 'package:kiosk_satellite/managers/sendspin/volume_ducker.dart';

class _Client extends SonosClient {
  _Client(super.host, this.levels);
  final Map<String, int?> levels;
  @override
  Future<int?> volume() async => levels[host];
  @override
  Future<void> setVolume(int level) async {
    levels[host] = level;
  }

  @override
  Future<List<SonosGroup>> zoneGroups() async => const [
    SonosGroup(
      coordinator: 'a',
      members: [
        SonosMember(uuid: 'a', host: 'a.local', name: 'A'),
        SonosMember(uuid: 'b', host: 'b.local', name: 'B'),
      ],
    ),
  ];
}

void main() {
  for (final grouped in [true, false]) {
    test(
      'Sonos restores individual levels with group volume $grouped',
      () async {
        final levels = <String, int?>{'a.local': 7, 'b.local': 43};
        final player = SonosPlayer(
          host: 'b.local',
          uuid: 'b',
          onSnapshot: (_) {},
          log: Logger(),
          groupVolume: grouped,
          clientFactory: (host) => _Client(host, levels),
        );
        final ducker = VolumeDucker(
          capture: player.captureDuckingVolumes,
          onError: (error) => fail('$error'),
        );
        await ducker.update(active: true, factor: 0);
        expect(levels, {'a.local': grouped ? 0 : 7, 'b.local': 0});
        await ducker.close();
        expect(levels, {'a.local': 7, 'b.local': 43});
        await player.stop();
      },
    );
  }

  test('an unreadable room prevents partial group ducking', () async {
    final levels = <String, int?>{'a.local': 7, 'b.local': null};
    final errors = <Object>[];
    final player = SonosPlayer(
      host: 'b.local',
      uuid: 'b',
      onSnapshot: (_) {},
      log: Logger(),
      clientFactory: (host) => _Client(host, levels),
    );
    final ducker = VolumeDucker(
      capture: player.captureDuckingVolumes,
      onError: errors.add,
    );
    await ducker.update(active: true, factor: .1);
    expect(errors, hasLength(1));
    expect(levels, {'a.local': 7, 'b.local': null});
    await ducker.close();
    await player.stop();
  });
}
