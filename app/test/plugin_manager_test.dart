import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/ui/plugin_overlay.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/plugin_settings.dart';

class _ZipPicker extends FilePicker {
  FilePickerResult? result;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    expect(type, FileType.custom);
    expect(allowedExtensions, ['zip']);
    expect(withReadStream, isTrue);
    expect(withData, isFalse);
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FilePicker.platform = _ZipPicker();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();
  late PluginManager plugins;
  late FilePicker originalPicker;
  late _ZipPicker picker;
  late Logger log;
  late EventBus bus;
  late CommandRegistry commands;
  late List<MethodCall> calls;
  late List<Map<String, Object?>> installed;
  late bool masterEnabled;

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
    originalPicker = FilePicker.platform;
    picker = _ZipPicker();
    FilePicker.platform = picker;
    log = Logger();
    bus = EventBus();
    commands = CommandRegistry(log);
    plugins = PluginManager(bus, commands, log);
    calls = [];
    masterEnabled = true;
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
      if (call.method == 'setEnabled') {
        masterEnabled = (call.arguments as Map)['enabled'] as bool;
        installed = [
          for (final p in installed)
            {...p, 'running': masterEnabled && p['enabled'] == true},
        ];
      }
      if (call.method == 'enable' && !masterEnabled) {
        throw PlatformException(
          code: 'plugin_error',
          message: 'Enable Plugins first',
        );
      }
      if (call.method == 'disable') {
        installed = [
          {...installed.first, 'running': false, 'enabled': false},
        ];
      }
      if (call.method == 'remove') installed = [];
      return {'enabled': masterEnabled, 'plugins': installed};
    });
    await plugins.init();
    await plugins.refresh();
  });
  tearDown(() async {
    FilePicker.platform = originalPicker;
    await plugins.dispose();
    await bus.dispose();
    await log.dispose();
    messenger.setMockMethodCallHandler(PluginManager.channel, null);
  });

  test(
    'master switch preserves selections, hides windows and exposes state through the command API',
    () async {
      await window();
      final before = Map<String, Object?>.from(installed.single);
      final paused = await commands.execute('setPluginsEnabled', {
        'enabled': false,
      });
      expect(paused.ok, isTrue);
      expect(plugins.enabled.value, isFalse);
      expect(plugins.windows.value, isEmpty);
      expect(plugins.installed.value.single['enabled'], before['enabled']);
      expect(plugins.installed.value.single['values'], before['values']);
      expect(plugins.installed.value.single['running'], isFalse);
      final enable = await commands.execute('enablePlugin', {
        'id': 'hello-world',
      });
      expect(enable.ok, isFalse);
      expect(enable.error, 'Enable Plugins first');
      final resumed = await commands.execute('setPluginsEnabled', {
        'enabled': true,
      });
      expect(resumed.ok, isTrue);
      expect(plugins.enabled.value, isTrue);
      expect(plugins.installed.value.single['running'], isTrue);
      final state = await commands.execute('getPluginState', {});
      expect(state.data, {'enabled': true, 'plugins': installed});
      final list = await commands.execute('listPlugins', {});
      expect(list.data, installed);
      final count = calls.length;
      expect((await commands.execute('setPluginsEnabled', {})).ok, isFalse);
      expect(
        (await commands.execute('setPluginsEnabled', {'enabled': 'false'})).ok,
        isFalse,
      );
      expect(calls.length, count);
    },
  );
  testWidgets(
    'master switch keeps its hint visible and hides follow-up settings while off',
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
      expect(
        find.text(
          'Plugins add additional community developed features to Kiosk Satellite.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('Plugins add optional features'),
        findsNothing,
      );
      final masterRow = find.widgetWithText(SettingsRow, 'Enable Plugins');
      final masterSwitch = find.descendant(
        of: masterRow,
        matching: find.byType(Switch),
      );
      final add = tester.getRect(find.text('Add plugin'));
      final warning = tester.getRect(find.text(pluginTrustNotice));
      expect(warning.top, greaterThan(add.bottom));
      expect(
        warning.bottom,
        lessThan(tester.getRect(find.text('Installed plugins')).top),
      );
      final before = tester.getRect(find.text('Hello World'));
      final masterBefore = tester.getRect(masterRow);
      await tester.tap(masterSwitch);
      await tester.pumpAndSettle();
      expect(plugins.enabled.value, isFalse);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Add plugin'), findsNothing);
      expect(find.text(pluginTrustNotice), findsNothing);
      expect(find.text('Installed plugins'), findsNothing);
      expect(find.text('Hello World'), findsNothing);
      expect(find.text('Developer Tools'), findsNothing);
      expect(find.text('Install from ZIP'), findsNothing);
      expect(tester.getRect(masterRow), masterBefore);
      await tester.tap(masterSwitch);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Hello World')), before);
      expect(
        tester.widget<Switch>(find.byType(Switch).last).onChanged,
        isNotNull,
      );
    },
  );
  testWidgets(
    'plugin subpages close when the master switch is disabled from another interface',
    (tester) async {
      var closed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PluginDetailPanel(
                plugins: plugins,
                id: 'hello-world',
                onDisabled: () => closed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await native('changed', {
        'enabled': false,
        'plugins': [
          {...installed.single, 'running': false},
        ],
      });
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      expect(find.byTooltip('Show window'), findsNothing);
      expect(find.text('Save settings'), findsNothing);
      await native('changed', {'enabled': true, 'plugins': installed});
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Show window',
              ),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
  test(
    'ZIP command requires trust and rejects invalid or oversized input before native install',
    () async {
      final count = calls.length;
      for (final params in [
        {'data': 'AQID', 'trusted': false},
        {'data': 'AQID'},
        {'data': '', 'trusted': true},
        {'data': '!invalid!', 'trusted': true},
        {
          'data': 'A' * (((PluginManager.maxZipBytes + 2) ~/ 3) * 4 + 1),
          'trusted': true,
        },
        {
          'data': base64Encode(Uint8List(PluginManager.maxZipBytes + 1)),
          'trusted': true,
        },
      ]) {
        final result = await commands.execute('installPlugin', params);
        expect(result.ok, isFalse);
      }
      expect(calls.length, count);
      final result = await commands.execute('installPlugin', {
        'data': 'AQID',
        'trusted': true,
        'source': 'untrusted override',
      });
      expect(result.ok, isTrue);
      expect(calls.last.method, 'install');
      expect(calls.last.arguments, {
        'bytes': Uint8List.fromList([1, 2, 3]),
        'trusted': true,
      });
    },
  );
  test('direct ZIP installs also enforce trust and size', () async {
    final count = calls.length;
    await expectLater(
      plugins.installZip(Uint8List.fromList([1]), trusted: false),
      throwsStateError,
    );
    await expectLater(
      plugins.installZip(Uint8List(0), trusted: true),
      throwsFormatException,
    );
    await expectLater(
      plugins.installZip(
        Uint8List(PluginManager.maxZipBytes + 1),
        trusted: true,
      ),
      throwsFormatException,
    );
    expect(calls.length, count);
  });
  testWidgets(
    'Developer Tools ZIP flow handles picker cancel, trust cancel and confirmed install without shifting rows',
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
      expect(find.text('Developer Tools'), findsOneWidget);
      await tester.ensureVisible(find.text('Install from ZIP'));
      await tester.tap(find.text('Install from ZIP'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'install'), isEmpty);
      picker.result = FilePickerResult([
        PlatformFile(
          name: 'development.zip',
          size: 3,
          readStream: Stream.value([1, 2, 3]),
        ),
      ]);
      await tester.tap(find.text('Install from ZIP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('development.zip'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'install'), isEmpty);
      final before = tester.getRect(find.text('Hello World'));
      final pending = Completer<void>();
      messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
        calls.add(call);
        if (call.method == 'install') await pending.future;
        return installed;
      });
      await tester.tap(find.text('Install from ZIP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Trust and install'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls.last.method, 'install');
      expect(calls.last.arguments, {
        'bytes': Uint8List.fromList([1, 2, 3]),
        'trusted': true,
      });
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getRect(find.text('Hello World')), before);
      pending.complete();
      await tester.pumpAndSettle();
    },
  );
  test(
    'ZIP streams enforce the actual size and stop reading oversized files',
    () async {
      final count = calls.length;
      var canceled = false;
      final stream = StreamController<List<int>>(
        onCancel: () {
          canceled = true;
        },
      );
      final result = expectLater(
        plugins.installZipStream(stream.stream, trusted: true),
        throwsFormatException,
      );
      stream.add(Uint8List(PluginManager.maxZipBytes));
      stream.add([1]);
      await result;
      expect(canceled, isTrue);
      expect(calls.length, count);
      await stream.close();
      await plugins.installZipStream(
        Stream.fromIterable([
          [1],
          [2, 3],
        ]),
        trusted: true,
      );
      expect(calls.last.arguments, {
        'bytes': Uint8List.fromList([1, 2, 3]),
        'trusted': true,
      });
    },
  );
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
      expect(
        tester.getCenter(find.byType(Switch).last).dx,
        lessThan(tester.getTopLeft(find.text('Hello World')).dx),
      );
      await tester.tap(find.byTooltip('About Hello World'));
      await tester.pumpAndSettle();
      expect(opened, isNull);
      expect(
        find.text(
          'This plugin was installed from ZIP and has no repository README.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      installed[0]['source'] = {
        'readme': '# Saved README',
        'readmeBaseUrl': 'https://example.com/',
      };
      await plugins.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('About Hello World'));
      await tester.pumpAndSettle();
      expect(find.text('Saved README'), findsOneWidget);
      expect(opened, isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getCenter(find.byType(Switch).last).dx,
        lessThan(tester.getTopLeft(find.text('Hello World')).dx),
      );
      expect(
        tester.getCenter(find.byTooltip('About Hello World')).dx,
        lessThan(tester.getCenter(find.byTooltip('Uninstall Hello World')).dx),
      );
      await tester.tap(find.text('Hello World'));
      expect(opened, 'hello-world');
      opened = null;
      await tester.tap(find.byType(Switch).last);
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
      expect(find.text('Install from ZIP'), findsOneWidget);
      final before = tester.getRect(find.text('Hello World'));
      final pending = Completer<void>();
      messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
        if (call.method == 'disable') await pending.future;
        return installed;
      });
      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.getRect(find.text('Hello World')), before);
      pending.complete();
      await tester.pumpAndSettle();
    },
  );
  test(
    'plugin lights publish namespaced catalogs and route commands',
    () async {
      var catalogs = 0;
      final states = <PluginEntityStateChanged>[];
      final catalogSub = bus.on<PluginEntityCatalogChanged>().listen(
        (_) => catalogs++,
      );
      final stateSub = bus.on<PluginEntityStateChanged>().listen(states.add);
      installed[0]['lights'] = [
        {
          'key': 'panel',
          'name': 'Panel LED',
          'effects': ['None', 'Pulse'],
          'state': {
            'on': true,
            'brightness': 0.5,
            'red': 1.0,
            'green': 0.0,
            'blue': 0.0,
            'effect': 'None',
          },
        },
      ];
      await plugins.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(catalogs, 1);
      expect(states.single.objectId, 'plugin_hello_world__panel');
      final catalog = await commands.execute('getPluginEntities', const {});
      final entity = (catalog.data as List).single as Map;
      expect(entity['colorCapable'], true);
      await commands.execute('pluginEntityCommand', {
        'objectId': entity['objectId'],
        'value': {'on': false},
      });
      expect(calls.lastWhere((c) => c.method == 'entityCommand').arguments, {
        'id': 'hello-world',
        'key': 'panel',
        'value': {'on': false},
      });
      final light = (installed[0]['lights'] as List).single as Map;
      (light['state'] as Map)['brightness'] = 0.75;
      await plugins.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(catalogs, 1);
      expect(states.last.value['brightness'], 0.75);
      await plugins.setEnabled(false);
      await Future<void>.delayed(Duration.zero);
      expect(catalogs, 2);
      expect(
        (await commands.execute('getPluginEntities', const {})).data,
        isEmpty,
      );
      await catalogSub.cancel();
      await stateSub.cancel();
    },
  );
  testWidgets('SDK 2 controls retain edits during runtime status updates', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {
        'key': 'brightness',
        'title': 'Brightness',
        'type': 'number',
        'min': 0,
        'max': 100,
        'step': 1,
        'default': 50,
        'group': 'LED',
      },
      {
        'key': 'effect',
        'title': 'Effect',
        'type': 'select',
        'options': ['None', 'Pulse'],
        'default': 'None',
        'group': 'LED',
      },
      {
        'key': 'color',
        'title': 'Color',
        'type': 'color',
        'default': '#123456',
        'group': 'LED',
      },
    ];
    installed[0]['values'] = {
      'brightness': 50,
      'effect': 'None',
      'color': '#123456',
    };
    await plugins.refresh();
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
    expect(find.text('LED'), findsOneWidget);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(75);
    await tester.pump();
    installed[0]['status'] = 'Connected';
    await plugins.refresh();
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 75);
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulse').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save settings'));
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      {'brightness': 75.0, 'effect': 'Pulse', 'color': '#123456'},
    );
    expect(tester.takeException(), isNull);
  });
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
