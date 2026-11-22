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

  test('progress fills with the hold and holds still when paused', () {
    fakeAsync((async) {
      final timer = PausableTimer(
        const Duration(seconds: 10),
        () {},
        stopwatch: async.getClock(DateTime(2000)).stopwatch(),
      );
      expect(timer.total, const Duration(seconds: 10));
      expect(timer.progress, 0);
      async.elapse(const Duration(seconds: 4));
      expect(timer.progress, closeTo(0.4, 1e-9));
      timer.pause();
      async.elapse(const Duration(hours: 1));
      expect(timer.progress, closeTo(0.4, 1e-9));
      timer.resume();
      async.elapse(const Duration(seconds: 1));
      expect(timer.progress, closeTo(0.5, 1e-9));
      timer.cancel();
      async.elapse(const Duration(seconds: 3));
      expect(timer.progress, closeTo(0.5, 1e-9));
    });
  });

  test('progress is full once the hold fires', () {
    fakeAsync((async) {
      final timer = PausableTimer(
        const Duration(seconds: 2),
        () {},
        stopwatch: async.getClock(DateTime(2000)).stopwatch(),
      );
      async.elapse(const Duration(seconds: 2));
      expect(timer.isActive, isFalse);
      expect(timer.progress, 1);
    });
  });

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

  group('photoFraming (issue #1552)', () {
    // A 2:3 portrait photo covering a 16:10 panel shows 0.42 of its height.
    const portrait = 2 / 3;
    const panel = 16 / 10;
    const window = portrait / panel;

    test('nothing to frame keeps the centered crop', () {
      const face = Rect.fromLTWH(0.4, 0.1, 0.2, 0.1);
      expect(photoFraming(const [], portrait, panel), isNull);
      expect(photoFraming(const [face], null, panel), isNull);
      // Shaped like the frame: covering it crops nothing.
      expect(photoFraming(const [face], panel, panel), isNull);
    });

    test('a face near the top of a portrait photo moves the crop up', () {
      const face = Rect.fromLTWH(0.42, 0.12, 0.16, 0.1);
      final framing = photoFraming(const [face], portrait, panel)!;
      // Only the cropped axis moves.
      expect(framing.crop.x, 0);
      expect(framing.crop.y, lessThan(-0.6));
      // The visible window still holds the head with room above it.
      final start = (framing.crop.y + 1) / 2 * (1 - window);
      expect(start, lessThanOrEqualTo(face.top - face.height * 0.5));
      expect(start + window, greaterThan(face.bottom));
      // The face sits a little above the middle of the frame.
      expect(framing.focus.y, closeTo(-0.2, 0.01));
      expect(framing.focus.x, closeTo(0, 0.01));
    });

    test('a face at the very top pins the crop to the top edge', () {
      const face = Rect.fromLTWH(0.4, 0, 0.2, 0.08);
      final framing = photoFraming(const [face], portrait, panel)!;
      expect(framing.crop.y, -1);
    });

    test('a face low in the photo moves the crop down', () {
      const face = Rect.fromLTWH(0.4, 0.75, 0.2, 0.1);
      final framing = photoFraming(const [face], portrait, panel)!;
      expect(framing.crop.y, greaterThan(0.5));
    });

    test('a group too tall for the window keeps its top', () {
      const faces = [
        Rect.fromLTWH(0.2, 0.1, 0.15, 0.1),
        Rect.fromLTWH(0.6, 0.7, 0.15, 0.1),
      ];
      final framing = photoFraming(faces, portrait, panel)!;
      final start = (framing.crop.y + 1) / 2 * (1 - window);
      expect(start, closeTo(0.1 - 0.05, 1e-9));
    });

    test('faces in the background do not steer the crop', () {
      const subject = Rect.fromLTWH(0.4, 0.15, 0.2, 0.12);
      const passerby = Rect.fromLTWH(0.8, 0.8, 0.03, 0.03);
      expect(
        photoFraming(const [subject, passerby], portrait, panel),
        photoFraming(const [subject], portrait, panel),
      );
    });

    test('a wide photo on a portrait frame centers across on the face', () {
      // A 16:9 photo in a portrait half of 0.8 shows 0.45 of its width.
      const face = Rect.fromLTWH(0.75, 0.3, 0.1, 0.15);
      final framing = photoFraming(const [face], 16 / 9, 0.8)!;
      expect(framing.crop.y, 0);
      expect(framing.crop.x, greaterThan(0.6));
      expect(framing.focus.x, closeTo(0, 0.2));
      // Down the frame the face stays where the photo has it.
      expect(framing.focus.y, closeTo(face.center.dy * 2 - 1, 1e-9));
    });

    test('photoCropped ignores a shape a hair from the frame', () {
      expect(photoCropped(1.6, 1.6), isFalse);
      expect(photoCropped(1.605, 1.6), isFalse);
      expect(photoCropped(4 / 3, 1.6), isTrue);
      expect(photoCropped(null, 1.6), isFalse);
    });
  });
}
