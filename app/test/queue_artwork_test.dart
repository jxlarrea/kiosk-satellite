import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/sendspin/queue_artwork_cache.dart';
import 'package:kiosk_satellite/ui/sendspin_player_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Request implements HttpClientRequest {
  _Request(this.url);
  final Uri url;
  final response = Completer<HttpClientResponse>();
  bool cancelled = false;

  @override
  Future<HttpClientResponse> close() => response.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements HttpClient {
  _Client(this.requests);
  final List<_Request> requests;
  _Request? request;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final next = _Request(url);
    requests.add(next);
    request = next;
    return next;
  }

  @override
  void close({bool force = false}) {
    final pending = request;
    if (pending != null && !pending.response.isCompleted) {
      pending.cancelled = true;
      pending.response.completeError(const SocketException('closed'));
    }
  }

  @override
  set badCertificateCallback(
    bool Function(X509Certificate, String, int)? callback,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  final body = StreamController<List<int>>();

  @override
  int get statusCode => 200;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => body.stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppContainer c;
  late List<_Request> requests;
  var run = 0;

  Future<void> boot(
    WidgetTester tester, {
    int current = -1,
    bool shared = false,
  }) async {
    run++;
    SharedPreferences.setMockInitialValues({
      'ks.sendspin.ma_url': 'https://ma.local:8095',
      'ks.sendspin.ma_token': 'token',
      'ks.sendspin.fullscreen_queue': true,
      'ks.sendspin.queue_art': true,
    });
    c = AppContainer();
    c.sendspin.queueArtworkCache = QueueArtworkCache(
      directory: () async => null,
      prepare: (bytes) async => bytes,
    );
    await c.settings.init();
    c.sendspin.nowPlaying.value = {
      'title': 'Song',
      'artist': 'Artist',
      'playing': false,
    };
    c.sendspin.queueItems.value = List.generate(
      200,
      (i) => {
        'id': '$i',
        'title': 'Track $i',
        'artist': 'Artist',
        'current': i == current,
        'played': i < current,
        'artworkUrl': 'http://art.local/$run/${shared && i < 2 ? 0 : i}',
      },
    );
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    requests = [];
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SendspinFullscreenView(container: c)),
        ),
      );
      await tester.pump();
    }, createHttpClient: (_) => _Client(requests));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> withNetwork(Future<void> Function() work) =>
      HttpOverrides.runZoned(work, createHttpClient: (_) => _Client(requests));

  testWidgets(
    'only visible rows download and scrolling cancels old downloads',
    (tester) async {
      await boot(tester);
      await withNetwork(() async {
        await settle(tester);
        final list = find.byType(ListView);
        final viewport = tester.getRect(list);
        expect(requests, isNotEmpty);
        expect(requests.length, lessThanOrEqualTo(6));
        for (final request in requests) {
          final row = find.text('Track ${request.url.pathSegments.last}');
          expect(tester.getRect(row).overlaps(viewport), isTrue);
        }
        final old = requests.toList();
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        );
        scroll.position.jumpTo(3000);
        await settle(tester);
        expect(old.every((r) => r.cancelled), isTrue);
        final fresh = requests.where((r) => !r.cancelled).toList();
        expect(fresh, isNotEmpty);
        for (final request in fresh) {
          final row = find.text('Track ${request.url.pathSegments.last}');
          expect(tester.getRect(row).overlaps(viewport), isTrue);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(requests.every((r) => r.cancelled), isTrue);
      });
    },
  );

  testWidgets('opening a deep queue skips artwork before the playing track', (
    tester,
  ) async {
    await boot(tester, current: 150);
    await withNetwork(() async {
      await settle(tester);
      expect(requests, isNotEmpty);
      expect(
        requests.every((r) => int.parse(r.url.pathSegments.last) >= 149),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  testWidgets('shared covers survive until their last visible row leaves', (
    tester,
  ) async {
    await boot(tester, shared: true);
    await withNetwork(() async {
      await settle(tester);
      final shared = requests
          .where((r) => r.url.pathSegments.last == '0')
          .single;
      final list = find.byType(ListView);
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)),
      );
      final secondTop = tester.getTopLeft(find.text('Track 1')).dy;
      scroll.position.jumpTo(secondTop - tester.getTopLeft(list).dy);
      await settle(tester);
      expect(shared.cancelled, isFalse);
      scroll.position.jumpTo(3000);
      await settle(tester);
      expect(shared.cancelled, isTrue);
      // Returning starts a fresh request even if the old response arrives late.
      scroll.position.jumpTo(0);
      await settle(tester);
      // More than six rows fit here. Free the newer visible requests
      // so the shared cover can take its turn in the bounded lane.
      for (final request in requests.where((r) => !r.cancelled).toList()) {
        final response = _Response();
        request.response.complete(response);
        unawaited(response.body.close());
      }
      await settle(tester);
      expect(
        requests.where((r) => r.url.pathSegments.last == '0'),
        hasLength(2),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  testWidgets('artwork cancellation releases a hung request immediately', (
    tester,
  ) async {
    await boot(tester);
    await tester.pumpWidget(const SizedBox());
    await withNetwork(() async {
      final cancelled = Completer<void>();
      var done = false;
      final result = c.sendspin
          .fetchArtwork('http://art.local/hung', cancelled: cancelled.future)
          .then((value) {
            done = true;
            return value;
          });
      await tester.pump();
      expect(done, isFalse);
      cancelled.complete();
      await tester.pump();
      expect(done, isTrue);
      expect(await result, isNull);
      expect(requests.single.cancelled, isTrue);
    });
  });

  testWidgets(
    'artwork total timeout includes a response that keeps sending bytes',
    (tester) async {
      await boot(tester);
      await tester.pumpWidget(const SizedBox());
      await withNetwork(() async {
        var done = false;
        final result = c.sendspin
            .fetchArtwork(
              'http://art.local/trickle',
              timeout: const Duration(seconds: 2),
            )
            .then((value) {
              done = true;
              return value;
            });
        await tester.pump();
        final response = _Response();
        requests.single.response.complete(response);
        await tester.pump();
        for (var i = 0; i < 3; i++) {
          response.body.add([1]);
          await tester.pump(const Duration(milliseconds: 500));
          expect(done, isFalse);
        }
        response.body.add([2]);
        await tester.pump(const Duration(milliseconds: 500));
        expect(done, isTrue);
        expect(await result, isNull);
        await response.body.close();
      });
    },
  );

  testWidgets('completed artwork is displayed and reused on reopening', (
    tester,
  ) async {
    await boot(tester, shared: true);
    await withNetwork(() async {
      await settle(tester);
      final request = requests.first;
      final response = _Response();
      request.response.complete(response);
      response.body.add(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4AWMAAQAABQABDQottAAAAABJRU5ErkJggg==',
        ),
      );
      unawaited(response.body.close());
      await settle(tester);
      expect(find.byType(Image), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      requests.clear();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SendspinFullscreenView(container: c)),
        ),
      );
      await settle(tester);
      expect(requests.any((r) => r.url == request.url), isFalse);
      expect(find.byType(Image), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
