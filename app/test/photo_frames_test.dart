import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/photo_frames.dart';

void main() {
  testWidgets('EXIF rotation is applied exactly once when measuring a photo', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await File(
        'test/fixtures/photo-orientation-6.jpg',
      ).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 30);
      expect(frame.image.height, 40);
      expect(await photoAspect(bytes), frame.image.width / frame.image.height);
      frame.image.dispose();
      codec.dispose();
    });
  });
  test('decode dimensions respect fit, crop, paired frames and zoom', () {
    const screen = Size(2560, 1600);
    expect(photoDecodeWidth(screen, 3 / 4, 'smart', false), 1200);
    expect(photoDecodeWidth(screen, 3 / 4, 'smart', true), 1320);
    expect(photoDecodeWidth(screen, 3 / 4, 'always', false), 2508);
    expect(photoDecodeWidth(screen, 4 / 3, 'smart', false), 2560);
    expect(
      photoDecodeWidth(const Size(1280, 1600), 3 / 4, 'smart', false),
      1280,
    );
    expect(photoDecodeWidth(screen, 3, 'off', false), 2560);
    expect(photoDecodeWidth(screen, null, 'smart', false), 2560);
  });

  test(
    'screen-off holds the remaining slide duration across repeated wakes',
    () {
      fakeAsync((async) {
        var changes = 0;
        final timer = PausableTimer(
          const Duration(seconds: 10),
          () => changes++,
          stopwatch: async.getClock(DateTime(2000)).stopwatch(),
        );
        async.elapse(const Duration(seconds: 3));
        timer.pause();
        timer.pause();
        async.elapse(const Duration(hours: 1));
        expect(changes, 0);
        timer.resume();
        async.elapse(const Duration(seconds: 4));
        timer.pause();
        async.elapse(const Duration(hours: 1));
        timer.resume();
        async.elapse(const Duration(seconds: 2));
        expect(changes, 0);
        async.elapse(const Duration(seconds: 1));
        expect(changes, 1);
        expect(timer.isActive, isFalse);
      });
    },
  );

  test('a cancelled or initially sleeping hold schedules no work', () {
    fakeAsync((async) {
      var changes = 0;
      final timer = PausableTimer(
        const Duration(seconds: 2),
        () => changes++,
        paused: true,
      );
      async.elapse(const Duration(hours: 1));
      expect(changes, 0);
      timer.cancel();
      timer.resume();
      async.elapse(const Duration(hours: 1));
      expect(changes, 0);
    });
  });

  test(
    'display consumes the pending preparation without a second load',
    () async {
      final disposed = <int>[];
      final cache = SlidePreloader<int>(disposed.add);
      final pending = Completer<int>();
      var loads = 0;
      Future<int> load(bool Function() valid) {
        loads++;
        return pending.future;
      }

      cache.warm('next', load);
      final showing = cache.take('next', load);
      cache.clear();
      pending.complete(42);
      expect(await showing, 42);
      expect(loads, 1);
      expect(disposed, isEmpty);
    },
  );

  test(
    'obsolete warm-ups release their results without replacing the next slide',
    () async {
      final disposed = <int>[];
      final cache = SlidePreloader<int>(disposed.add);
      final old = Completer<int>();
      late bool Function() oldValid;
      cache.warm('old', (valid) {
        oldValid = valid;
        return old.future;
      });
      cache.warm('new', (_) async => 2);
      expect(oldValid(), isFalse);
      old.complete(1);
      await Future<void>.delayed(Duration.zero);
      expect(disposed, [1]);
      expect(await cache.take('new', (_) async => 3), 2);
    },
  );

  test('failed warm-ups retry when the slide is requested', () async {
    final cache = SlidePreloader<int>((_) {});
    cache.warm('next', (_) => throw StateError('offline'));
    await Future<void>.delayed(Duration.zero);
    expect(await cache.take('next', (_) async => 1), 1);
  });
}
