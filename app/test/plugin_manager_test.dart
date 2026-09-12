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

  test('screensavers reject stale sessions and clear on disable', () async {
    final renderer = {'key': 'dvd', 'title': 'DVD Logo', 'html': '<p>DVD</p>'};
    Future<void> open(String token) => native('hostSession', {
      'id': 'hello-world',
      'session': token,
      'capabilities': ['screensaver'],
    });
    Future<void> publish(String token) => native('screensavers', {
      'id': 'hello-world',
      'session': token,
      'screensavers': [renderer],
    });
    await open('first');
    await publish('first');
    expect(
      plugins.screensaverOptions['plugin:hello-world:dvd'],
      'DVD Logo (Hello World)',
    );
    await open('second');
    expect(plugins.screensavers.value, isEmpty);
    await publish('first');
    expect(plugins.screensavers.value, isEmpty);
    await publish('second');
    await native('hostSessionClosed', {
      'id': 'hello-world',
      'session': 'first',
    });
    expect(plugins.screensavers.value, hasLength(1));
    await plugins.setEnabled(false);
    expect(plugins.screensavers.value, isEmpty);
    await publish('second');
    expect(plugins.screensavers.value, isEmpty);
  });

  testWidgets('Shizuku is opt-in and permission requests require a user tap', (
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
    expect(find.text('Shizuku access'), findsNothing);
    expect(
      calls.where((c) => c.method.toLowerCase().contains('shizuku')),
      isEmpty,
    );
    installed[0]['capabilities'] = ['shizuku'];
    await plugins.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Shizuku access'), findsOneWidget);
    expect(calls.where((c) => c.method == 'requestShizukuPermission'), isEmpty);
    await tester.tap(find.text('Shizuku access'));
    await tester.pumpAndSettle();
    expect(
      calls
          .where((c) => c.method == 'requestShizukuPermission')
          .single
          .arguments,
      {'id': 'hello-world'},
    );
    var settingUpdates = 0;
    plugins.installed.addListener(() => settingUpdates++);
    await native('shizukuState', {
      'status': 'ready',
      'available': true,
      'granted': true,
      'uid': 2000,
    });
    await tester.pumpAndSettle();
    expect(find.text('Connected with shell access'), findsOneWidget);
    expect(settingUpdates, 0);
    await tester.tap(find.text('Shizuku access'));
    await tester.pumpAndSettle();
    expect(
      calls.where((c) => c.method == 'requestShizukuPermission').length,
      1,
    );
    await native('shizukuState', {
      'status': 'unavailable',
      'available': false,
      'granted': false,
    });
    await tester.pumpAndSettle();
    expect(
      find.text('Start Shizuku on this device. Tap for setup instructions.'),
      findsOneWidget,
    );
  });

  test(
    'local readings update without settings refresh and clear with their session',
    () async {
      var settingsUpdates = 0;
      var readingUpdates = 0;
      plugins.installed.addListener(() => settingsUpdates++);
      plugins.readings.addListener(() => readingUpdates++);
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'readings',
        'capabilities': ['entities'],
      });
      final reading = <String, Object?>{
        'type': 'sensor',
        'key': 'cpu',
        'name': 'CPU',
        'unit': '%',
        'accuracyDecimals': 2,
        'state': 12.5,
      };
      Future<void> publish(
        List<Map<String, Object?>> values, {
        String session = 'readings',
      }) => native('entities', {
        'id': 'hello-world',
        'session': session,
        'entities': values,
      });
      await publish([reading]);
      expect(plugins.readings.value['hello-world'], [reading]);
      expect(readingUpdates, 1);
      await publish([reading]);
      expect(readingUpdates, 1);
      final beforeCalls = calls.length;
      expect(
        (await commands.execute('getPluginReadings', {
          'id': 'hello-world',
        })).data,
        [reading],
      );
      expect(
        (await commands.execute('getPluginReadings', {
          'id': 'another-plugin',
        })).data,
        isEmpty,
      );
      expect(calls.length, beforeCalls);
      await publish([
        {...reading, 'state': null},
      ]);
      expect(plugins.readings.value['hello-world']!.single['state'], isNull);
      expect(settingsUpdates, 0);
      await publish([]);
      expect(plugins.readings.value, isEmpty);
      await publish([reading]);
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'readings',
      });
      expect(plugins.readings.value, isEmpty);
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'replacement',
        'capabilities': ['entities'],
      });
      await publish([reading]);
      expect(plugins.readings.value, isEmpty);
      await publish([reading], session: 'replacement');
      expect(plugins.readings.value['hello-world'], [reading]);
      await plugins.setEnabled(false);
      expect(plugins.readings.value, isEmpty);
    },
  );

  test(
    'charts are session scoped and do not notify setting listeners',
    () async {
      var settingsUpdates = 0;
      plugins.installed.addListener(() => settingsUpdates++);
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'first',
        'capabilities': [],
      });
      final chart = {
        'key': 'cpu',
        'title': 'CPU',
        'unit': '%',
        'timestamps': [1000],
        'series': [
          {
            'name': 'CPU',
            'values': [12],
          },
        ],
      };
      await native('charts', {
        'id': 'hello-world',
        'session': 'first',
        'charts': [chart],
      });
      expect(plugins.charts.value['hello-world'], [chart]);
      expect(settingsUpdates, 0);
      final response = await commands.execute('getPluginCharts', {
        'id': 'hello-world',
      });
      expect(response.data, [chart]);
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'first',
      });
      expect(plugins.charts.value, isEmpty);
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'second',
        'capabilities': [],
      });
      await native('charts', {
        'id': 'hello-world',
        'session': 'first',
        'charts': [chart],
      });
      expect(plugins.charts.value, isEmpty);
      await native('charts', {
        'id': 'hello-world',
        'session': 'second',
        'charts': [chart],
      });
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'first',
      });
      expect(plugins.charts.value['hello-world'], [chart]);
      await plugins.setEnabled(false);
      expect(plugins.charts.value, isEmpty);
      expect(plugins.installed.value.first.containsKey('charts'), false);
    },
  );

  test(
    'sensor and select catalogs separate metadata, state and session lifetime',
    () async {
      var catalogs = 0;
      var settingsUpdates = 0;
      final states = <PluginEntityStateChanged>[];
      final catalogSub = bus.on<PluginEntityCatalogChanged>().listen(
        (_) => catalogs++,
      );
      final stateSub = bus.on<PluginEntityStateChanged>().listen(states.add);
      plugins.installed.addListener(() => settingsUpdates++);
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'sensors',
        'capabilities': ['entities'],
      });
      var entities = <Map<String, Object?>>[
        {
          'type': 'sensor',
          'key': 'reading',
          'name': 'Reading',
          'unit': 'ms',
          'stateClass': 1,
          'accuracyDecimals': 2,
          'state': 12.5,
        },
        {
          'type': 'text_sensor',
          'key': 'reading',
          'name': 'Link',
          'state': 'WiFi',
        },
        {
          'type': 'binary_sensor',
          'key': 'reading',
          'name': 'Connected',
          'state': false,
        },
        {
          'type': 'select',
          'key': 'reading',
          'name': 'Mode',
          'options': ['Auto', 'Fast'],
          'state': 'Auto',
        },
      ];
      Future<void> publish(String session) async {
        installed[0]['entities'] = entities;
        await native('entities', {
          'id': 'hello-world',
          'session': session,
          'entities': entities,
        });
        await Future<void>.delayed(Duration.zero);
      }

      await publish('sensors');
      expect(catalogs, 1);
      expect(states.length, 4);
      expect(settingsUpdates, 0);
      final catalog =
          (await commands.execute('getPluginEntities', {})).data as List;
      expect(catalog.map((e) => (e as Map)['objectId']).toSet().length, 4);
      expect(catalog.first['objectId'], 'plugin_hello_world____sensor_reading');
      for (final type in ['sensor', 'text_sensor', 'binary_sensor']) {
        final result = await commands.execute('pluginEntityCommand', {
          'objectId': 'plugin_hello_world____${type}_reading',
          'value': 'Fast',
        });
        expect(result.ok, false);
      }
      final invalid = await commands.execute('pluginEntityCommand', {
        'objectId': 'plugin_hello_world____select_reading',
        'value': 'Other',
      });
      expect(invalid.ok, false);
      expect(calls.where((c) => c.method == 'entityCommand'), isEmpty);
      final select = await commands.execute('pluginEntityCommand', {
        'objectId': 'plugin_hello_world____select_reading',
        'value': 'Fast',
      });
      expect(select.ok, true);
      expect(calls.lastWhere((c) => c.method == 'entityCommand').arguments, {
        'id': 'hello-world',
        'type': 'select',
        'key': 'reading',
        'value': 'Fast',
      });
      expect(
        ((await commands.execute('getPluginEntities', {})).data as List)
            .last['state'],
        'Auto',
      );
      await Future<void>.delayed(Duration.zero);
      expect(catalogs, 1);
      entities = [
        {...entities[0], 'state': null},
        entities[1],
        entities[2],
        {...entities[3], 'state': 'Fast'},
      ];
      final before = settingsUpdates;
      await publish('sensors');
      expect(catalogs, 1);
      expect(settingsUpdates, before);
      expect(states.last.value, 'Fast');
      expect(
        states
            .where((e) => e.objectId == 'plugin_hello_world____sensor_reading')
            .last
            .value,
        isNull,
      );
      entities = [
        ...entities.take(3),
        {
          ...entities[3],
          'options': ['Auto', 'Fast', 'Quiet'],
        },
      ];
      await publish('sensors');
      expect(catalogs, 2);
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'sensors',
      });
      await Future<void>.delayed(Duration.zero);
      expect((await commands.execute('getPluginEntities', {})).data, isEmpty);
      expect(
        states.skip(states.length - 4).every((e) => e.value == null),
        true,
      );
      await publish('sensors');
      expect((await commands.execute('getPluginEntities', {})).data, isEmpty);
      await catalogSub.cancel();
      await stateSub.cancel();
    },
  );

  test(
    'switch commands preserve false, wait for confirmation and stop with their session',
    () async {
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'switches',
        'capabilities': ['entities'],
      });
      var settingsUpdates = 0;
      var catalogs = 0;
      final states = <PluginEntityStateChanged>[];
      plugins.installed.addListener(() => settingsUpdates++);
      final catalogSub = bus.on<PluginEntityCatalogChanged>().listen(
        (_) => catalogs++,
      );
      final stateSub = bus.on<PluginEntityStateChanged>().listen(states.add);
      Future<void> publish(bool on) async {
        final entries = [
          {'type': 'switch', 'key': 'power', 'name': 'Power', 'state': on},
        ];
        installed[0]['entities'] = entries;
        await native('entities', {
          'id': 'hello-world',
          'session': 'switches',
          'entities': entries,
        });
        await Future<void>.delayed(Duration.zero);
      }

      await publish(true);
      expect(settingsUpdates, 0);
      expect(catalogs, 1);
      const id = 'plugin_hello_world____switch_power';
      for (final invalid in [
        null,
        'false',
        0,
        {'on': false},
      ]) {
        expect(
          (await commands.execute('pluginEntityCommand', {
            'objectId': id,
            'value': invalid,
          })).ok,
          false,
        );
      }
      expect(calls.where((c) => c.method == 'entityCommand'), isEmpty);
      final result = await commands.execute('pluginEntityCommand', {
        'objectId': id,
        'value': false,
      });
      expect(result.ok, true);
      expect(calls.lastWhere((c) => c.method == 'entityCommand').arguments, {
        'id': 'hello-world',
        'key': 'power',
        'type': 'switch',
        'value': false,
      });
      expect(
        ((await commands.execute('getPluginEntities', {})).data as List)
            .single['state'],
        true,
      );
      final before = settingsUpdates;
      await publish(false);
      expect(settingsUpdates, before);
      expect(catalogs, 1);
      expect(states.last.value, false);
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'switches',
      });
      expect((await commands.execute('getPluginEntities', {})).data, isEmpty);
      expect(
        (await commands.execute('pluginEntityCommand', {
          'objectId': id,
          'value': true,
        })).ok,
        false,
      );
      await publish(true);
      expect((await commands.execute('getPluginEntities', {})).data, isEmpty);
      await catalogSub.cancel();
      await stateSub.cancel();
    },
  );

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
      if (call.method == 'shizukuState' ||
          call.method == 'requestShizukuPermission') {
        return {
          'status': 'permission_required',
          'available': true,
          'granted': false,
        };
      }
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
      if (call.method == 'configure') {
        final args = call.arguments as Map;
        installed = [
          for (final plugin in installed)
            if (plugin['id'] == args['id'])
              {
                ...plugin,
                'values': Map<String, Object?>.from(args['values'] as Map),
              }
            else
              plugin,
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
      expect(find.text('Show window'), findsOneWidget);
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
        'type': 'light',
        'value': {'on': false},
      });
      final light = (installed[0]['lights'] as List).single as Map;
      (light['state'] as Map)['brightness'] = 0.75;
      await plugins.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(catalogs, 1);
      expect((states.last.value as Map)['brightness'], 0.75);
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
  testWidgets(
    'switches save immediately and failed saves restore the stored value',
    (tester) async {
      installed[0]['settings'] = [
        {
          'key': 'automatic',
          'title': 'Show automatically',
          'type': 'boolean',
          'default': false,
        },
      ];
      installed[0]['values'] = {'automatic': false};
      await plugins.refresh();
      final completion = Completer<Object?>();
      messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
        calls.add(call);
        if (call.method == 'configure') return completion.future;
        return {'enabled': masterEnabled, 'plugins': installed};
      });
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
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(
        (calls.lastWhere((c) => c.method == 'configure').arguments
            as Map)['values'],
        {'automatic': true},
      );
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      completion.completeError(
        PlatformException(code: 'plugin_error', message: 'Setting rejected'),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, false);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
      expect(find.textContaining('Setting rejected'), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle();
      expect(find.text('Save settings'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('SDK 1 controls retain edits during runtime status updates', (
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
    expect(calls.where((c) => c.method == 'configure'), isEmpty);
    tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(75);
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      {'brightness': 75.0, 'effect': 'None', 'color': '#123456'},
    );
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulse').last);
    await tester.pumpAndSettle();
    expect(find.text('Save settings'), findsNothing);
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      {'brightness': 75.0, 'effect': 'Pulse', 'color': '#123456'},
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'settings save values and configure action placements without executing them',
    (tester) async {
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
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Hello'), findsOneWidget);
      await tester.tap(find.text('Greeting'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Canceled greeting');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
      expect(calls.where((c) => c.method == 'configure'), isEmpty);
      await tester.tap(find.text('Greeting'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Edited greeting');
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'editing',
        'capabilities': [],
      });
      await native('charts', {
        'id': 'hello-world',
        'session': 'editing',
        'charts': [
          {
            'key': 'cpu',
            'title': 'CPU',
            'timestamps': [1000],
            'series': [
              {
                'name': 'CPU',
                'values': [12],
              },
            ],
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('Edited greeting'), findsOneWidget);

      installed[0]['status'] = 'Connected';
      await plugins.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Edited greeting'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      final configure = calls.lastWhere((c) => c.method == 'configure');
      expect(configure.arguments, {
        'id': 'hello-world',
        'values': {'message': 'Edited greeting'},
      });
      expect(find.widgetWithText(FilledButton, 'Save settings'), findsNothing);
      expect(find.text('Edited greeting'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.ensureVisible(find.text('Show window'));
      await tester.tap(find.text('Show window'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.tap(find.byType(Switch).last);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(calls.last.arguments, {
        'id': 'hello-world',
        'command': 'show',
        'drawer': true,
        'homeAssistant': true,
      });
      expect(calls.last.method, 'configureAction');
      expect(calls.where((call) => call.method == 'execute'), isEmpty);
    },
  );

  test(
    'action placements publish buttons and disappear when plugins stop',
    () async {
      expect(plugins.actions.single['available'], isTrue);
      expect(plugins.drawerActions, isEmpty);
      expect((await commands.execute('getPluginEntities', {})).data, isEmpty);
      installed[0]['actionOptions'] = {
        'show': {'drawer': true, 'homeAssistant': true},
      };
      installed.add({
        'id': 'action-hello-world',
        'name': 'Other plugin',
        'running': true,
        'enabled': true,
        'lights': [
          {
            'key': 'show',
            'name': 'Light',
            'effects': [],
            'state': {'on': false},
          },
        ],
      });
      await plugins.refresh();
      expect(plugins.drawerActions.single['command'], 'show');
      final entities =
          (await commands.execute('getPluginEntities', {})).data as List;
      expect(entities.map((e) => (e as Map)['objectId']).toSet(), hasLength(2));
      final button =
          entities.firstWhere((e) => (e as Map)['type'] == 'button') as Map;
      expect(button['type'], 'button');
      expect(button['objectId'], 'plugin_hello_world___show');
      await commands.execute('pluginEntityCommand', {
        'objectId': button['objectId'],
        'value': true,
      });
      expect(calls.last.method, 'execute');
      expect(calls.last.arguments, {'id': 'hello-world', 'command': 'show'});
      await plugins.update('disable', {'id': 'hello-world'});
      expect(plugins.actions.single['available'], isFalse);
      expect(plugins.drawerActions, isEmpty);
      expect((await commands.execute('getPluginEntities', {})).data, isEmpty);
      expect(
        (await commands.execute('pluginEntityCommand', {
          'objectId': button['objectId'],
          'value': true,
        })).ok,
        isFalse,
      );
    },
  );
}
