import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/immich_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Immich slideshow's start readied ahead of the idle clock (issue
/// #659): the playlist is kept between sessions, the first photo's bytes
/// are fetched before the screensaver shows, and a start consumes both
/// without asking the server again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  late HttpServer server;
  late EventBus bus;
  late SettingsManager settings;
  late ImmichManager immich;
  late DateTime now;
  var listings = 0;
  var searchStatus = 200;
  final thumbnails = <String, int>{};
  var library = <String>['a', 'b', 'c'];
  Completer<void>? holdListing;

  Future<void> build({Map<String, Object> extra = const {}}) async {
    SharedPreferences.setMockInitialValues({
      'ks.screensaver.immich_url': 'http://127.0.0.1:${server.port}',
      'ks.screensaver.immich_api_key': 'k',
      'ks.screensaver.immich_validated': true,
      'ks.screensaver.immich_cache': false,
      ...extra,
    });
    bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    immich = ImmichManager(bus, commands, log, settings);
    now = DateTime(2026, 9, 22, 12);
    immich.clock = () => now;
    await immich.init();
  }

  setUp(() async {
    listings = 0;
    searchStatus = 200;
    thumbnails.clear();
    library = ['a', 'b', 'c'];
    holdListing = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      final response = request.response;
      if (path == '/api/search/metadata') {
        await utf8.decoder.bind(request).join();
        listings++;
        // Read before the hold: the answer is the library as it was when
        // the request arrived, as a real server's would be.
        final answer = [...library];
        await holdListing?.future;
        response.statusCode = searchStatus;
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode({
            'assets': {
              'items': [
                for (final id in answer)
                  {'id': id, 'type': 'IMAGE', 'fileCreatedAt': '2026-01-01'},
              ],
              'nextPage': null,
            },
          }),
        );
      } else if (path.endsWith('/thumbnail')) {
        final id = path.split('/')[3];
        thumbnails[id] = (thumbnails[id] ?? 0) + 1;
        response.add(id.codeUnits);
      } else {
        response.statusCode = 404;
      }
      await response.close();
    });
  });

  tearDown(() async {
    await immich.dispose();
    await server.close(force: true);
  });

  /// Waits for [ready] with the real clock: the fake server is real IO.
  Future<void> until(bool Function() ready) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!ready()) {
      if (DateTime.now().isAfter(deadline)) fail('timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  List<String> ids(List<ImmichAsset> assets) => [for (final a in assets) a.id];

  test('the countdown readies the playlist and first photo, and a start '
      'consumes them without the server', () async {
    await build();
    bus.publish(
      ScreensaverCountdownChanged(
        due: now.add(const Duration(seconds: 10)),
        mode: 'immich',
      ),
    );
    await until(() => thumbnails['a'] == 1);
    expect(listings, 1);

    final order = await immich.startOrder();
    expect(ids(order), ['a', 'b', 'c']);
    expect(listings, 1);
    final bytes = await immich.imageBytes(order.first);
    expect(String.fromCharCodes(bytes), 'a');
    expect(thumbnails['a'], 1, reason: 'the readied bytes answer');
    // Consumed: the next read of the same photo goes to the server (or the
    // disk cache when it is on), not to a copy kept in memory.
    await immich.imageBytes(order.first);
    expect(thumbnails['a'], 2);
  });

  test('a clock further out than the lead waits, and a cleared clock '
      'cancels the wait', () async {
    await build();
    immich.warmLead = const Duration(milliseconds: 100);
    bus.publish(
      ScreensaverCountdownChanged(
        due: now.add(const Duration(seconds: 30)),
        mode: 'immich',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(listings, 0);
    bus.publish(const ScreensaverCountdownChanged(due: null));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(listings, 0);

    // The real clock runs the timer, so a due moment within the lead by
    // the fake clock's reckoning lands right away.
    immich.warmLead = const Duration(seconds: 15);
    bus.publish(
      ScreensaverCountdownChanged(
        due: now.add(const Duration(seconds: 5)),
        mode: 'immich',
      ),
    );
    await until(() => thumbnails['a'] == 1);
  });

  test('the playlist is kept between sessions and refreshed in the '
      'background once it ages', () async {
    await build();
    expect(ids(await immich.startOrder()), ['a', 'b', 'c']);
    expect(ids(await immich.startOrder()), ['a', 'b', 'c']);
    expect(listings, 1);

    library = ['d'];
    now = now.add(ImmichManager.playlistTtl + const Duration(seconds: 1));
    // Answered from the kept list, refreshed for the start after.
    expect(ids(await immich.startOrder()), ['a', 'b', 'c']);
    await until(() => listings == 2);
    expect(ids(await immich.startOrder()), ['d']);
    expect(listings, 2);
  });

  test(
    'a filter change drops the kept playlist and the readied start',
    () async {
      await build();
      bus.publish(
        ScreensaverCountdownChanged(
          due: now.add(const Duration(seconds: 10)),
          mode: 'immich',
        ),
      );
      await until(() => thumbnails['a'] == 1);
      await settings.set(defs.screensaverImmichFavoritesOnly, true);
      await Future<void>.delayed(Duration.zero);
      library = ['b'];
      expect(ids(await immich.startOrder()), ['b']);
      expect(listings, 2);
      await immich.imageBytes(const ImmichAsset(id: 'a', isVideo: false));
      expect(thumbnails['a'], 2, reason: 'the readied photo went with it');
    },
  );

  test('another mode due drops the readied photo, a cosmetic setting '
      'keeps it', () async {
    await build();
    bus.publish(
      ScreensaverCountdownChanged(
        due: now.add(const Duration(seconds: 10)),
        mode: 'immich',
      ),
    );
    await until(() => thumbnails['a'] == 1);
    await settings.set(defs.screensaverImmichTransition, 'zoom');
    await Future<void>.delayed(Duration.zero);
    bus.publish(
      ScreensaverCountdownChanged(
        due: now.add(const Duration(seconds: 10)),
        mode: 'clock',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(listings, 1, reason: 'the playlist stays kept');
    await immich.imageBytes(const ImmichAsset(id: 'a', isVideo: false));
    expect(thumbnails['a'], 2);
  });

  test(
    'with shuffle on the readied photo is the one the start shows first',
    () async {
      await build(extra: {'ks.screensaver.immich_shuffle': true});
      library = [for (var i = 0; i < 40; i++) 'p$i'];
      bus.publish(
        ScreensaverCountdownChanged(
          due: now.add(const Duration(seconds: 10)),
          mode: 'immich',
        ),
      );
      await until(() => thumbnails.length == 1);
      final order = await immich.startOrder();
      expect(order.first.id, thumbnails.keys.single);
      expect(ids(order).toSet(), library.toSet());
      await immich.imageBytes(order.first);
      expect(thumbnails[order.first.id], 1);
    },
  );

  group('laps (issue #699)', () {
    test('a start leads with what earlier sessions did not show, and the '
        'next lap starts once everything had its turn', () async {
      await build(extra: {'ks.screensaver.immich_shuffle': true});
      library = [for (var i = 0; i < 30; i++) 'p$i'];
      final seen = <String>[];
      // Short sessions of four slides each, the way a frame that keeps
      // being woken sees the slideshow.
      for (var session = 0; session < 7; session++) {
        final order = await immich.startOrder();
        for (final asset in order.take(4)) {
          immich.markShown(asset);
          seen.add(asset.id);
        }
      }
      expect(seen.sublist(0, 28).toSet(), hasLength(28));
      // Two left in the lap: the start leads with them, and showing them
      // ends the lap.
      final order = await immich.startOrder();
      final rest = library.toSet().difference(seen.toSet());
      expect(ids(order.take(2).toList()).toSet(), rest);
      for (final asset in order.take(2)) {
        immich.markShown(asset);
      }
      final lap = ids(await immich.startOrder());
      expect(lap.toSet(), library.toSet());
      expect(listings, 1);
    });

    test(
      'without shuffle a start picks up where the last one stopped',
      () async {
        await build();
        library = ['a', 'b', 'c', 'd'];
        final first = await immich.startOrder();
        immich.markShown(first[0]);
        immich.markShown(first[1]);
        expect(ids(await immich.startOrder()), ['c', 'd', 'a', 'b']);
      },
    );

    test('a refreshed listing keeps the progress and deals new uploads '
        'into the rest of the lap', () async {
      await build(extra: {'ks.screensaver.immich_shuffle': true});
      library = [for (var i = 0; i < 10; i++) 'p$i'];
      final first = await immich.startOrder();
      for (final asset in first.take(3)) {
        immich.markShown(asset);
      }
      final shown = ids(first.take(3).toList()).toSet();
      library = [
        for (final id in library)
          if (id != first[5].id) id,
        'new',
      ];
      now = now.add(ImmichManager.playlistTtl + const Duration(seconds: 1));
      await immich.startOrder();
      await until(() => listings == 2);
      final order = ids(await immich.startOrder());
      expect(order.toSet(), library.toSet());
      expect(order.sublist(order.length - 3).toSet(), shown);
      expect(order.take(order.length - 3), contains('new'));
    });

    test(
      'a filter change starts the lap over, a fresh listing does not',
      () async {
        await build();
        library = ['a', 'b', 'c'];
        immich.markShown((await immich.startOrder()).first);
        expect(ids(await immich.startOrder(fresh: true)), ['b', 'c', 'a']);
        await settings.set(defs.screensaverImmichFavoritesOnly, true);
        await Future<void>.delayed(Duration.zero);
        expect(ids(await immich.startOrder()), ['a', 'b', 'c']);
      },
    );

    test('a start readied before a photo showed is dropped', () async {
      await build();
      bus.publish(
        ScreensaverCountdownChanged(
          due: now.add(const Duration(seconds: 10)),
          mode: 'immich',
        ),
      );
      await until(() => thumbnails['a'] == 1);
      immich.markShown(const ImmichAsset(id: 'a', isVideo: false));
      expect(ids(await immich.startOrder()), ['b', 'c', 'a']);
    });
  });

  test('a filter changed while the server lists is not lost to the '
      'answer in flight', () async {
    await build();
    holdListing = Completer<void>();
    final start = immich.startOrder();
    await until(() => listings == 1);
    // The listing in flight ran on the old filter. The new one admits
    // only what the server lists after it.
    library = ['x'];
    await settings.set(defs.screensaverImmichFavoritesOnly, true);
    holdListing!.complete();
    holdListing = null;

    expect(ids(await start), ['x']);
    expect(listings, 2);
    expect(ids(await immich.startOrder()), ['x'], reason: 'kept, not stale');
    expect(listings, 2);
  });

  test('a fresh start lists again and drops the readied photo', () async {
    await build();
    bus.publish(
      ScreensaverCountdownChanged(
        due: now.add(const Duration(seconds: 10)),
        mode: 'immich',
      ),
    );
    await until(() => thumbnails['a'] == 1);
    library = ['b'];
    expect(ids(await immich.startOrder(fresh: true)), ['b']);
    expect(listings, 2);
    await immich.imageBytes(const ImmichAsset(id: 'a', isVideo: false));
    expect(thumbnails['a'], 2);
  });

  test('an empty listing is not kept, and a failed warm-up is quiet', () async {
    await build();
    library = [];
    expect(await immich.startOrder(), isEmpty);
    expect(await immich.startOrder(), isEmpty);
    expect(listings, 2);

    searchStatus = 500;
    await immich.warmUp();
    expect(listings, 3);
    expect(thumbnails, isEmpty);
  });

  test('a start without validation readies nothing', () async {
    await build(extra: {'ks.screensaver.immich_validated': false});
    await immich.warmUp();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(listings, 0);
  });
}
