import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/sendspin/player_handoff.dart';

/// Lending the followed player to an alarm and taking it back: the player
/// before comes back, a pick made meanwhile stands and a restart in the
/// middle gives the player back.
void main() {
  late FollowedPlayer followed;
  late String kept;
  late List<FollowedPlayer> follows;
  late PlayerHandoff handoff;

  setUp(() {
    followed = (source: 'sonos', player: 'sonos:RINCON_1', name: 'Living Room');
    kept = '';
    follows = [];
    handoff = PlayerHandoff(
      read: () => followed,
      follow: (p) async {
        follows.add(p);
        followed = p;
      },
      load: () => kept,
      save: (json) async => kept = json,
    );
  });

  test(
    'a borrow follows the lent player and the return puts it back',
    () async {
      await handoff.borrow('alarm', '', 'Hallway');
      expect(followed, (source: '', player: '', name: 'Hallway'));
      expect(handoff.owners, ['alarm']);
      await handoff.giveBack('alarm');
      expect(followed.player, 'sonos:RINCON_1');
      expect(followed.source, 'sonos');
      expect(kept, '');
    },
  );

  test('borrowing the followed player changes nothing', () async {
    await handoff.borrow('alarm', 'sonos:RINCON_1', 'Living Room');
    await handoff.giveBack('alarm');
    expect(follows, isEmpty);
  });

  test('a player picked while lent stays picked', () async {
    await handoff.borrow('alarm', 'ma:kitchen', 'Kitchen');
    followed = (source: 'ha', player: 'ha:media_player.tv', name: 'TV');
    await handoff.giveBack('alarm');
    expect(followed.player, 'ha:media_player.tv');
    expect(kept, '');
  });

  test('the last owner out gives back the first player', () async {
    await handoff.borrow('alarm', 'ma:kitchen', 'Kitchen');
    await handoff.borrow('preview', 'ma:office', 'Office');
    expect(followed.player, 'ma:office');
    await handoff.giveBack('alarm');
    expect(followed.player, 'ma:office');
    await handoff.giveBack('preview');
    expect(followed.player, 'sonos:RINCON_1');
  });

  test('a return by someone who never borrowed does nothing', () async {
    await handoff.giveBack('alarm');
    expect(follows, isEmpty);
  });

  test('a restart in the middle gives the player back', () async {
    await handoff.borrow('alarm', 'ma:kitchen', 'Kitchen');
    final restarted = PlayerHandoff(
      read: () => followed,
      follow: (p) async => followed = p,
      load: () => kept,
      save: (json) async => kept = json,
    );
    await restarted.recover();
    expect(followed.player, 'sonos:RINCON_1');
    expect(restarted.lent, isFalse);
  });
}
