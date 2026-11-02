import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/wake_word/playback_watch.dart';

void main() {
  late List<bool> changes;
  late bool played;
  late bool wanted;
  late PlaybackWatch watch;

  setUp(() {
    changes = [];
    played = false;
    wanted = true;
    watch = PlaybackWatch(
      onChanged: changes.add,
      wanted: () => wanted,
      played: () async => played,
    )..start();
  });

  tearDown(() => watch.stop());

  Future<void> polls(int n) async {
    for (var i = 0; i < n; i++) {
      await watch.poll();
    }
  }

  test(
    'playback counts after a few polls in a row and ends the same way',
    () async {
      played = true;
      await polls(PlaybackWatch.confirmPolls - 1);
      expect(changes, isEmpty);
      await polls(1);
      expect(changes, [true]);
      expect(watch.playing, isTrue);

      played = false;
      await polls(PlaybackWatch.confirmPolls);
      expect(changes, [true, false]);
    },
  );

  test('a chime or a gap between tracks moves nothing', () async {
    played = true;
    await polls(2);
    played = false;
    await polls(1);
    played = true;
    await polls(2);
    expect(changes, isEmpty, reason: 'the quiet poll broke the streak');

    await polls(1);
    expect(changes, [true]);
    played = false;
    await polls(2);
    played = true;
    await polls(1);
    played = false;
    await polls(2);
    expect(changes, [true], reason: 'still playing through the gap');
  });

  test('stops itself once nothing listens, forgetting the state', () async {
    played = true;
    await polls(PlaybackWatch.confirmPolls);
    expect(changes, [true]);

    wanted = false;
    await polls(1);
    expect(watch.running, isFalse);
    expect(watch.playing, isFalse);
    expect(changes, [true], reason: 'the stopped engine forgot it on its own');
  });
}
