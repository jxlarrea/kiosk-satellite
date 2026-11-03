import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/screensaver/screensaver_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/plugin_screensaver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const mode = 'plugin:hello-world:dvd';
  late SettingsManager settings;
  late ScreensaverManager saver;
  late EventBus bus;
  late Logger log;
  late List<double> brightness;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'ks.screensaver.enabled': true});
    bus = EventBus();
    log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    brightness = [];
    commands.register(
      Command(
        name: 'getBrightness',
        description: 'test',
        handler: (_) async => const CommandResult.ok(.8),
      ),
    );
    commands.register(
      Command(
        name: 'setBrightness',
        description: 'test',
        handler: (p) async {
          brightness.add((p['level'] as num).toDouble());
          return const CommandResult.ok();
        },
      ),
    );
    saver = ScreensaverManager(bus, commands, log, settings);
    await saver.init();
  });
  tearDown(() async {
    await saver.dispose();
    await settings.dispose();
    await bus.dispose();
    log.dispose();
  });
  test(
    'both settings clients get live names and retain an unavailable selection',
    () async {
      settings.pluginScreensavers = () => {mode: 'DVD Logo (Hello World)'};
      expect(await settings.setFromJson(screensaverMode.key, mode), true);
      final schema = settings.describe().firstWhere(
        (s) => s['key'] == screensaverMode.key,
      );
      expect(schema['options'], contains(mode));
      expect((schema['optionLabels'] as Map)[mode], 'DVD Logo (Hello World)');
      settings.pluginScreensavers = () => {};
      expect(settings.optionsFor(screensaverMode), contains(mode));
      expect(
        settings.optionLabel(screensaverMode, mode),
        'Unavailable plugin screensaver',
      );
      expect(
        await settings.setFromJson(screensaverMode.key, 'plugin:../bad:dvd'),
        false,
      );
      expect(await settings.setFromJson(screensaverMode.key, 'clock'), true);
    },
  );
  test(
    'scheduled plugin uses stock overrides and restores brightness on stop',
    () async {
      await settings.set(screensaverScheduleEnabled, true);
      await settings.set(
        screensaverSchedule,
        jsonEncode([
          {
            'at': '00:00',
            'mode': mode,
            'brightness': .25,
            'widgets': false,
            'glance': false,
            'now_playing': false,
            'motion': false,
          },
        ]),
      );
      await pumpEventQueue();
      await saver.start();
      expect(saver.activeView.value, mode);
      expect(brightness, [.25]);
      expect(saver.scheduleWidgets.value, false);
      expect(saver.scheduleGlance.value, false);
      expect(saver.scheduleNowPlaying.value, false);
      await saver.stop();
      expect(saver.activeView.value, isNull);
      expect(brightness.last, .8);
    },
  );
  test(
    'asset URLs retain relative file paths and encode configuration as a fragment',
    () {
      final data = jsonEncode({'text': '</script>#?&%', 'color': '#00D4FF'});
      final url = pluginScreensaverAssetUrl({
        'entry': 'dvd/index.html',
        'assetOrigin': 'https://ks-plugin-test.invalid',
        'dataJson': data,
      })!;
      expect(url.path, '/assets/dvd/index.html');
      expect(url.query, isEmpty);
      expect(Uri.decodeComponent(Uri.parse(url.toString()).fragment), data);
      expect(url.resolve('dvd.css').path, '/assets/dvd/dvd.css');
      expect(pluginScreensaverAssetUrl({'html': '<h1>inline</h1>'}), isNull);
    },
  );

  test('render document isolates plugin markup and denies host access', () {
    final document = pluginScreensaverDocument(
      '<script>window.demo = "test";</script>',
    );
    expect(document, contains('sandbox="allow-scripts"'));
    expect(document, isNot(contains('allow-same-origin')));
    expect(document, contains('&lt;script&gt;'));
    expect(document, contains("connect-src 'none'"));
    expect(document, contains("form-action 'none'"));
  });

  test('inline updates swap in a sandboxed frame once it has painted', () {
    final document = pluginScreensaverDocument('<h1>first</h1>');
    expect(document, contains('window.ksUpdateDocument'));
    expect(document, contains("next.setAttribute('sandbox', 'allow-scripts')"));
    expect(document, contains("next.style.opacity = '0'"));
    expect(document, contains('if (pending !== next) return;'));
    expect(document, isNot(contains('allow-same-origin')));
  });

  testWidgets('a native renderer shows the plugin view through the overlay '
      'factory, rebuilt on every publication', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        calls.add(call);
        return call.method == 'create' ? 0 : null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      ),
    );
    final c = AppContainer();
    await c.settings.init();
    Map<String, Object?> view(int generation) => {
      'key': 'dvd',
      'title': 'DVD',
      'view': true,
      'generation': generation,
      'session': 'token',
      'pluginId': 'hello-world',
    };
    c.plugins.screensavers.value = {mode: view(3)};
    await tester.pumpWidget(
      MaterialApp(
        home: PluginScreensaver(container: c, mode: mode),
      ),
    );
    await tester.pump();
    AndroidView shown() => tester.widget<AndroidView>(find.byType(AndroidView));
    expect(shown().viewType, 'kiosk_satellite/plugin_overlay');
    final params = shown().creationParams as Map;
    expect(params['kind'], 'screensaver');
    expect(params['id'], 'hello-world');
    expect(params['session'], 'token');
    expect(params['key'], 'dvd');
    expect(params['generation'], 3);
    expect(params['width'], -2);
    expect(params['height'], -2);
    expect(params['insets'], [0, 0, 0, 0]);
    expect(params['theme'], isA<Map>());
    // Touches stay with KS.
    expect(
      find.ancestor(
        of: find.byType(AndroidView),
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsOneWidget,
    );

    final created = calls.where((c) => c.method == 'create').length;
    c.plugins.screensavers.value = {mode: view(4)};
    await tester.pump();
    await tester.pump();
    expect((shown().creationParams as Map)['generation'], 4);
    expect(calls.where((c) => c.method == 'create').length, created + 1);
    expect(calls.where((c) => c.method == 'dispose'), isNotEmpty);

    // Published with touch (issue #1282), taps reach the view.
    expect(c.plugins.screensaverTouch(mode), isFalse);
    c.plugins.screensavers.value = {
      mode: {...view(5), 'touch': true},
    };
    await tester.pump();
    await tester.pump();
    expect(c.plugins.screensaverTouch(mode), isTrue);
    expect(
      find.ancestor(
        of: find.byType(AndroidView),
        matching: find.byWidgetPredicate(
          (w) => w is IgnorePointer && w.ignoring,
        ),
      ),
      findsNothing,
    );

    // Removed, the screensaver goes black and the view is disposed, which
    // tells the plugin to stop drawing.
    final disposed = calls.where((c) => c.method == 'dispose').length;
    c.plugins.screensavers.value = {};
    await tester.pump();
    expect(find.byType(AndroidView), findsNothing);
    expect(calls.where((c) => c.method == 'dispose').length, disposed + 1);
    await tester.pumpWidget(const SizedBox());
  });

  group('asset publications keep the shown document until the next paints', () {
    Map<String, Object?> asset(String data) => {
      'entry': 'clock/index.html',
      'assetOrigin': 'https://ks-plugin-a.invalid',
      'assetDirectory': '/data/plugins/a/assets',
      'dataJson': data,
    };

    test('changed options load beneath the shown document', () {
      final documents = PluginDocuments();
      expect(documents.publish(asset('{"t":"20.1"}')), false);
      final first = documents.shown!.key;
      expect(documents.publish(asset('{"t":"20.2"}')), true);
      expect(documents.shown!.key, first);
      expect(documents.next!.renderer['dataJson'], '{"t":"20.2"}');
      expect(documents.ready(documents.next!.key), true);
      expect(documents.shown!.renderer['dataJson'], '{"t":"20.2"}');
      expect(documents.next, isNull);
    });

    test('a newer publication replaces one still loading', () {
      final documents = PluginDocuments()..publish(asset('{"t":"1"}'));
      documents.publish(asset('{"t":"2"}'));
      final stale = documents.next!.key;
      expect(documents.publish(asset('{"t":"3"}')), true);
      expect(documents.ready(stale), false);
      expect(documents.shown!.renderer['dataJson'], '{"t":"1"}');
      expect(documents.ready(documents.next!.key), true);
      expect(documents.shown!.renderer['dataJson'], '{"t":"3"}');
    });

    test('returning to the shown options drops the pending document', () {
      final documents = PluginDocuments()..publish(asset('{"t":"1"}'));
      documents.publish(asset('{"t":"2"}'));
      expect(documents.publish(asset('{"t":"1"}')), false);
      expect(documents.next, isNull);
    });

    test('inline updates stay in the shown document', () {
      final documents = PluginDocuments()..publish({'html': '<p>1</p>'});
      expect(documents.publish({'html': '<p>2</p>'}), false);
      expect(documents.next, isNull);
      expect(documents.shown!.renderer['html'], '<p>2</p>');
    });

    test('removal clears both documents', () {
      final documents = PluginDocuments()..publish(asset('{"t":"1"}'));
      documents.publish(asset('{"t":"2"}'));
      documents.publish(null);
      expect(documents.shown, isNull);
      expect(documents.next, isNull);
    });
  });
}
