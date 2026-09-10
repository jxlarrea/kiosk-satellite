import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/ui/plugin_overlay.dart';
import 'package:kiosk_satellite/ui/plugin_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();
  late PluginManager plugins;
  late Logger log;
  late EventBus bus;
  late CommandRegistry commands;
  late List<MethodCall> calls;
  late List<Map<String, Object?>> installed;

  Future<void> native(String method, Object? args) async {
    await messenger.handlePlatformMessage(
      'kiosk_satellite/plugins',
      codec.encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );
  }

  Future<void> window({
    String id = 'hello-world',
    String message = 'Hello from a plugin!',
  }) => native('window', {
    'id': id,
    'title': 'Hello World',
    'message': message,
    'buttonLabel': 'Say hello',
  });

  setUp(() async {
    log = Logger();
    bus = EventBus();
    commands = CommandRegistry(log);
    plugins = PluginManager(bus, commands, log);
    calls = [];
    installed = [
      {
        'id': 'hello-world',
        'name': 'Hello World',
        'version': '1.0.0',
        'description': 'Floating greeting',
        'enabled': true,
        'running': true,
        'settings': [
          {
            'key': 'message',
            'title': 'Greeting',
            'type': 'string',
            'default': 'Hello',
          },
        ],
        'commands': [
          {'id': 'show', 'title': 'Show window'},
        ],
        'values': {'message': 'Hello'},
      },
    ];
    messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
      calls.add(call);
      if (call.method == 'disable') {
        installed = [
          {...installed.first, 'running': false, 'enabled': false},
        ];
      }
      if (call.method == 'remove') installed = [];
      return installed;
    });
    await plugins.init();
    await plugins.refresh();
  });
  tearDown(() async {
    await plugins.dispose();
    await bus.dispose();
    await log.dispose();
    messenger.setMockMethodCallHandler(PluginManager.channel, null);
  });

  test('local ZIP installation is not exposed as a command', () async {
    final count = calls.length;
    final result = await commands.execute('installPlugin', {
      'data': 'AQID',
      'trusted': true,
    });
    expect(result.ok, isFalse);
    expect(calls.length, count);
  });
  test(
    'updates replace only the owning window and disable removes it',
    () async {
      await window();
      await window(message: 'Updated');
      expect(plugins.windows.value, hasLength(1));
      expect(plugins.windows.value.single.message, 'Updated');
      await plugins.update('disable', {'id': 'hello-world'});
      expect(plugins.windows.value, isEmpty);
    },
  );
  test('uninstall removes the window and installed entry', () async {
    await window();
    await plugins.update('remove', {'id': 'hello-world'});
    expect(plugins.windows.value, isEmpty);
    expect(plugins.installed.value, isEmpty);
  });
  test('native error messages reach command callers', () async {
    messenger.setMockMethodCallHandler(PluginManager.channel, (_) async {
      throw PlatformException(
        code: 'plugin_error',
        message: 'Unsupported plugin capability',
      );
    });
    final result = await commands.execute('enablePlugin', {
      'id': 'hello-world',
    });
    expect(result.ok, isFalse);
    expect(result.error, 'Unsupported plugin capability');
  });
  testWidgets(
    'floating window passes outside touches through and sends button and close events',
    (tester) async {
      var dashboardTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => dashboardTaps++,
                  child: const SizedBox.expand(),
                ),
                PluginOverlay(plugins: plugins),
              ],
            ),
          ),
        ),
      );
      await window();
      await tester.pump();
      expect(find.text('Hello World'), findsOneWidget);
      await tester.tapAt(const Offset(30, 400));
      expect(dashboardTaps, 1);
      await tester.tap(find.text('Say hello'));
      await tester.pump();
      expect(calls.last.arguments, {
        'id': 'hello-world',
        'event': 'window.action',
      });
      final before = tester.getTopLeft(find.text('Hello World'));
      await tester.drag(find.text('Hello World'), const Offset(-100, 80));
      await tester.pump();
      final after = tester.getTopLeft(find.text('Hello World'));
      expect(after.dx, lessThan(before.dx));
      await tester.tap(find.byTooltip('Close Hello World'));
      await tester.pump();
      expect(plugins.windows.value, isEmpty);
      expect(calls.last.arguments, {
        'id': 'hello-world',
        'event': 'window.closed',
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('window stays reachable after a display resize', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PluginOverlay(plugins: plugins)),
      ),
    );
    await window(message: 'A long greeting. ' * 100);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byTooltip('Close Hello World')).right,
      lessThanOrEqualTo(320),
    );
    tester.view.physicalSize = const Size(240, 320);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byTooltip('Close Hello World')).right,
      lessThanOrEqualTo(240),
    );
  });
  testWidgets(
    'entry rows open details and keep lifecycle controls on the list',
    (tester) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PluginSettingsPanel(
                plugins: plugins,
                onOpen: (id) => opened = id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Save settings'), findsNothing);
      expect(find.text('Show window'), findsNothing);
      await tester.tap(find.text('Hello World'));
      expect(opened, 'hello-world');
      opened = null;
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(calls.lastWhere((c) => c.method == 'disable').arguments, {
        'id': 'hello-world',
      });
      await tester.tap(find.byTooltip('Uninstall Hello World'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Uninstall'));
      await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(
        find.text('No plugins installed. Add a repository to get started.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'loading stays inside its control without moving the installed row',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PluginSettingsPanel(plugins: plugins, onOpen: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Refresh'), findsNothing);
      expect(find.text('Install local ZIP'), findsNothing);
      final before = tester.getRect(find.text('Hello World'));
      final pending = Completer<void>();
      messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
        if (call.method == 'disable') await pending.future;
        return installed;
      });
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.getRect(find.text('Hello World')), before);
      pending.complete();
      await tester.pumpAndSettle();
    },
  );
  testWidgets('settings save edited values and invoke declared commands', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PluginDetailPanel(plugins: plugins, id: 'hello-world'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Uninstall Hello World'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'Edited greeting');
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    final configure = calls.lastWhere((c) => c.method == 'configure');
    expect(configure.arguments, {
      'id': 'hello-world',
      'values': {'message': 'Edited greeting'},
    });
    await tester.tap(find.byTooltip('Show window'));
    await tester.pumpAndSettle();
    expect(calls.last.arguments, {'id': 'hello-world', 'command': 'show'});
  });
}
