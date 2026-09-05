import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/screensaver_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAB4AAAAoCAIAAABmcd1FAAAALklEQVR4nO3MQQEAQAQAsHMttJJYNil4bQEWXfl2/KVXrVar1Wq1Wq1Wq9WH9QCo5QF3BVxaYAAAAABJRU5ErkJggg==',
  );
  late AppContainer c;
  late Directory directory;
  late List<File> files;
  var changes = 0;
  StreamSubscription<ScreensaverSlideChanged>? subscription;

  Future<void> drain(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await tester.pump();
    }
  }

  Future<void> mount(
    WidgetTester tester, {
    int count = 2,
    String transition = 'fade',
  }) async {
    await (() async {
      directory = await Directory.systemTemp.createTemp(
        'photo-screensaver-test',
      );
      files = [];
      for (var i = 0; i < count; i++) {
        files.add(await File('${directory.path}/$i.png').writeAsBytes(png));
      }
      SharedPreferences.setMockInitialValues({
        'ks.screensaver.mode': 'gallery',
        'ks.screensaver.gallery_items': jsonEncode(
          files.map((f) => f.path).toList(),
        ),
        'ks.screensaver.gallery_shuffle': false,
        'ks.screensaver.gallery_interval_seconds': 5,
        'ks.screensaver.gallery_transition': transition,
        'ks.screensaver.gallery_fill': 'smart',
      });
      c = AppContainer();
      await c.settings.init();
      await c.screensaver.start();
    })();
    changes = 0;
    subscription = c.bus.on<ScreensaverSlideChanged>().listen((_) => changes++);
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: LocalMediaScreensaver(container: c, mode: 'gallery'),
      ),
    );
    await drain(tester);
    expect(changes, 1);
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await subscription?.cancel();
    await directory.delete(recursive: true);
  }

  testWidgets(
    'the next slide uses prepared pixels even if its file disappears',
    (tester) async {
      await tester.runAsync(() async {
        await mount(tester);
        final widths = tester
            .widgetList<Image>(find.byType(Image))
            .map((i) => (i.image as ResizeImage).width)
            .toSet();
        expect(widths, containsAll([450, 256]));
        await files[1].delete();
        final step = c.screensaver.stepSlide(1);
        await drain(tester);
        await step;
        await tester.pump(const Duration(seconds: 1));
        expect(changes, 2);
        expect(find.text('Could not read photos.'), findsNothing);
        await finish(tester);
      });
    },
  );

  testWidgets('a single photo stays loaded and its drift freezes while dark', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await mount(tester, count: 1, transition: 'kenburns');
      await tester.pump(const Duration(seconds: 1));
      c.bus.publish(const ScreenStateChanged(on: false));
      await drain(tester);
      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump();
      expect(changes, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
      c.bus.publish(const ScreenStateChanged(on: true, source: 'app'));
      await drain(tester);
      await tester.pump(const Duration(seconds: 20));
      expect(changes, 1);
      await finish(tester);
    });
  });

  testWidgets('a dark panel preserves the current slide and resumes its hold', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await mount(tester);
      c.bus.publish(const ScreenStateChanged(on: false));
      await drain(tester);
      await Future<void>.delayed(const Duration(seconds: 6));
      await tester.pump();
      expect(changes, 1);
      c.bus.publish(const ScreenStateChanged(on: true, source: 'app'));
      await drain(tester);
      await Future<void>.delayed(const Duration(seconds: 5));
      await drain(tester);
      expect(changes, 2);
      await finish(tester);
    });
  });
  testWidgets('a single photo responds to fill changes and display rotation', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await mount(tester, count: 1);
      await c.settings.set(defs.screensaverGalleryFill, 'always');
      await drain(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(changes, 2);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect((image.image as ResizeImage).width, 800);
      tester.view.physicalSize = const Size(600, 800);
      await tester.pump();
      await drain(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(changes, 3);
      expect(
        (tester.widget<Image>(find.byType(Image)).image as ResizeImage).width,
        600,
      );
      await finish(tester);
    });
  });
}
