import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings_en.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/ui/entity_picker.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart'
    show screensaverMode;
import 'package:kiosk_satellite/ui/plugin_overlay.dart';
import 'package:kiosk_satellite/ui/ui_scale.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/plugin_settings.dart';

class _WindowMessages extends UiStringsEn {
  @override
  String pluginCloseWindow(String name) => 'Cerrar $name';
}

class _WindowDelegate extends LocalizationsDelegate<UiStrings> {
  const _WindowDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<UiStrings> load(Locale locale) => SynchronousFuture(
    locale.languageCode == 'es' ? _WindowMessages() : UiStringsEn(),
  );
  @override
  bool shouldReload(_WindowDelegate old) => false;
}

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

  test(
    'screensaver mode options notify remote admin only when the list changes',
    () async {
      final keys = <String>[];
      final sub = bus.on<SettingOptionsChanged>().listen(
        (event) => keys.add(event.key),
      );
      Future<void> publish(String title, String html) =>
          native('screensavers', {
            'id': 'hello-world',
            'session': 'first',
            'screensavers': [
              {'key': 'dvd', 'title': title, 'html': html},
            ],
          });
      await native('hostSession', {
        'id': 'hello-world',
        'session': 'first',
        'capabilities': ['screensaver'],
      });
      await publish('DVD Logo', '<p>1</p>');
      await Future<void>.delayed(Duration.zero);
      expect(keys, [screensaverMode.key]);
      await publish('DVD Logo', '<p>2</p>');
      await Future<void>.delayed(Duration.zero);
      expect(keys, hasLength(1));
      await publish('Bouncing Logo', '<p>2</p>');
      await Future<void>.delayed(Duration.zero);
      expect(keys, hasLength(2));
      await plugins.setEnabled(false);
      await Future<void>.delayed(Duration.zero);
      expect(keys, hasLength(3));
      await sub.cancel();
    },
  );

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

  test('status tiles are session scoped and list the owning plugin', () async {
    var settingsUpdates = 0;
    plugins.installed.addListener(() => settingsUpdates++);
    await native('hostSession', {
      'id': 'hello-world',
      'session': 'first',
      'capabilities': [],
    });
    final tile = {
      'key': 'webview',
      'title': 'WebView responsiveness',
      'level': 'on',
      'text': 'smooth',
    };
    await native('statusTiles', {
      'id': 'hello-world',
      'session': 'first',
      'statusTiles': [tile],
    });
    expect(plugins.statusTiles.value['hello-world'], [tile]);
    expect(settingsUpdates, 0);
    final response = await commands.execute('getPluginStatusTiles', {});
    expect(response.data, [
      {...tile, 'pluginId': 'hello-world', 'pluginName': 'Hello World'},
    ]);
    await native('statusTiles', {
      'id': 'hello-world',
      'session': 'stale',
      'statusTiles': [tile],
    });
    expect(plugins.statusTiles.value['hello-world'], [tile]);
    await native('hostSessionClosed', {
      'id': 'hello-world',
      'session': 'first',
    });
    expect(plugins.statusTiles.value, isEmpty);
    expect((await commands.execute('getPluginStatusTiles', {})).data, []);
    await native('hostSession', {
      'id': 'hello-world',
      'session': 'second',
      'capabilities': [],
    });
    await native('statusTiles', {
      'id': 'hello-world',
      'session': 'second',
      'statusTiles': [tile],
    });
    expect(plugins.statusTiles.value['hello-world'], [tile]);
    await plugins.setEnabled(false);
    expect(plugins.statusTiles.value, isEmpty);
    expect(plugins.installed.value.first.containsKey('statusTiles'), false);
  });

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
        'triggers': [
          {'id': 'hardwareKey', 'title': 'Hardware key'},
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
                // A patch writes over the saved values, like the host.
                'values': <String, Object?>{
                  if (args['patch'] == true) ...plugin['values'] as Map,
                  ...args['values'] as Map,
                },
              }
            else
              plugin,
        ];
      }
      if (call.method == 'remove') installed = [];
      if (call.method == 'setupRun') return {'run': 'run-${calls.length}'};
      if (call.method == 'setupCancel' || call.method == 'setupConfirm') {
        return null;
      }
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
    'remote plugin settings notify changes without a read feedback loop',
    () async {
      await Future<void>.delayed(Duration.zero);
      final topics = <String>[];
      final sub = bus.on<RemoteStatusChanged>().listen(
        (event) => topics.add(event.topic),
      );
      await plugins.getState();
      await Future<void>.delayed(Duration.zero);
      expect(topics.where((topic) => topic == 'plugin-settings'), isEmpty);
      await plugins.update('configure', {
        'id': 'hello-world',
        'values': {'message': 'Changed on device'},
      });
      await Future<void>.delayed(Duration.zero);
      expect(topics.where((topic) => topic == 'plugin-settings'), hasLength(1));
      await plugins.getState();
      await Future<void>.delayed(Duration.zero);
      expect(topics.where((topic) => topic == 'plugin-settings'), hasLength(1));
      await sub.cancel();
    },
  );

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
  testWidgets(
    'window close follows language without changing plugin content or events',
    (tester) async {
      final language = ValueNotifier(const Locale('en'));
      addTearDown(language.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: language,
          builder: (_, locale, _) => MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('es')],
            localizationsDelegates: const [
              _WindowDelegate(),
              ...appLocalizationsDelegates,
            ],
            home: Scaffold(body: PluginOverlay(plugins: plugins)),
          ),
        ),
      );
      await window(message: 'Original plugin text');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close Hello World'), findsOneWidget);
      await tester.drag(find.text('Hello World'), const Offset(-40, 30));
      await tester.pumpAndSettle();
      final position = tester.getTopLeft(find.text('Hello World'));
      final count = calls.length;
      language.value = const Locale('es');
      await tester.pumpAndSettle();
      expect(find.text('Original plugin text'), findsOneWidget);
      expect(find.text('Say hello'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Hello World')), position);
      expect(calls.length, count);
      await tester.tap(find.byTooltip('Cerrar Hello World'));
      await tester.pumpAndSettle();
      expect(plugins.windows.value, isEmpty);
      expect(calls.last.arguments, {
        'id': 'hello-world',
        'event': 'window.closed',
      });
      expect(tester.takeException(), isNull);
    },
  );
  Future<void> overlaySession(String token) => native('hostSession', {
    'id': 'hello-world',
    'session': token,
    'capabilities': ['overlay'],
  });
  Map<String, Object?> overlay(
    String key,
    int generation, {
    String anchor = 'top',
    int width = PluginNativeOverlay.wrap,
    int height = PluginNativeOverlay.wrap,
    int inset = 0,
    List<int>? insets,
    int offsetX = 0,
    int offsetY = 0,
    bool closeOnBack = true,
    bool onTop = false,
    bool touchable = true,
    bool closeOnOutsideTouch = false,
    bool passOutsideTouch = false,
    String enter = 'none',
    String exit = 'none',
    int duration = 200,
  }) => {
    'key': key,
    'generation': generation,
    'anchor': anchor,
    'width': width,
    'height': height,
    'insets': insets ?? [inset, inset, inset, inset],
    'offsetX': offsetX,
    'offsetY': offsetY,
    'closeOnBack': closeOnBack,
    'onTop': onTop,
    'touchable': touchable,
    'closeOnOutsideTouch': closeOnOutsideTouch,
    'passOutsideTouch': passOutsideTouch,
    'enter': enter,
    'exit': exit,
    'duration': duration,
  };
  Future<void> overlays(String token, List<Map<String, Object?>> list) =>
      native('overlays', {
        'id': 'hello-world',
        'session': token,
        'overlays': list,
      });

  test(
    'content insets merge across plugins and clear with their session',
    () async {
      Future<void> session(String id, String token) => native('hostSession', {
        'id': id,
        'session': token,
        'capabilities': ['overlay'],
      });
      Future<void> insets(String id, String token, List<int> sides) => native(
        'contentInsets',
        {'id': id, 'session': token, 'insets': sides},
      );
      await session('hello-world', 'first');
      await insets('hello-world', 'first', [0, 0, 0, 80]);
      expect(plugins.contentInsets.value, const EdgeInsets.only(bottom: 80));
      await session('navbar', 'one');
      await insets('navbar', 'one', [72, 0, 0, 64]);
      // Each edge keeps the largest.
      expect(
        plugins.contentInsets.value,
        const EdgeInsets.fromLTRB(72, 0, 0, 80),
      );
      // A stale session is ignored.
      await insets('navbar', 'old', [0, 300, 0, 0]);
      expect(plugins.contentInsets.value.top, 0);
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'first',
      });
      expect(
        plugins.contentInsets.value,
        const EdgeInsets.fromLTRB(72, 0, 0, 64),
      );
      await insets('navbar', 'one', [0, 0, 0, 0]);
      expect(plugins.contentInsets.value, EdgeInsets.zero);
      // A restarted session starts with none.
      await insets('navbar', 'one', [0, 0, 0, 48]);
      await session('navbar', 'two');
      expect(plugins.contentInsets.value, EdgeInsets.zero);
    },
  );

  test(
    'setup runs and choices are session scoped and reach remote commands',
    () async {
      Future<void> open(String token) => native('hostSession', {
        'id': 'hello-world',
        'session': token,
        'capabilities': <String>[],
      });
      Future<void> publish(String token, Map setup) => native('setup', {
        'id': 'hello-world',
        'session': token,
        'setup': setup,
      });
      const state = {
        'runs': {
          'button:test': {
            'run': 'r1',
            'state': 'running',
            'message': 'Connecting',
            'code': '',
            'origin': 'remote',
            'confirm': null,
          },
        },
        'choices': {
          'device': [
            {'id': 'lamp-1', 'label': 'Kitchen'},
          ],
        },
      };
      await open('first');
      await publish('first', state);
      final read = await commands.execute('getPluginSetup', {
        'id': 'hello-world',
      });
      expect(
        ((read.data as Map)['runs'] as Map)['button:test']['message'],
        'Connecting',
      );
      // A stale session changes nothing, and a new one starts empty.
      await open('second');
      expect(plugins.setup.value, isEmpty);
      await publish('first', state);
      expect(plugins.setup.value, isEmpty);
      expect(
        (await commands.execute('getPluginSetup', {'id': 'hello-world'})).data,
        {'runs': {}, 'choiceRevisions': {}, 'choicesOff': [], 'choices': {}},
      );
      final run = await commands.execute('runPluginSetup', {
        'id': 'hello-world',
        'target': 'button',
        'key': 'test',
      });
      expect(run.ok, isTrue);
      expect(calls.last.method, 'setupRun');
      expect(calls.last.arguments, {
        'id': 'hello-world',
        'target': 'button',
        'key': 'test',
        'origin': 'remote',
      });
      await commands.execute('cancelPluginSetup', {
        'id': 'hello-world',
        'run': 'r1',
      });
      expect(calls.last.method, 'setupCancel');
      await commands.execute('answerPluginSetup', {
        'id': 'hello-world',
        'run': 'r1',
        'accepted': true,
      });
      expect(calls.last.arguments, {
        'id': 'hello-world',
        'run': 'r1',
        'accepted': true,
      });
      await publish('second', state);
      await native('hostSessionClosed', {
        'id': 'hello-world',
        'session': 'second',
      });
      expect(plugins.setup.value, isEmpty);
    },
  );

  test(
    'choice lists arrive once per revision and stay through run updates',
    () async {
      await native('hostSession', {
        'id': 'hello-world',
        'session': 's',
        'capabilities': <String>[],
      });
      Future<void> publish(Map runs, Map revisions, [Map choices = const {}]) =>
          native('setup', {
            'id': 'hello-world',
            'session': 's',
            'setup': {
              'runs': runs,
              'choiceRevisions': revisions,
              'choices': choices,
            },
          });
      const lamps = [
        {'id': 'lamp-1', 'label': 'Kitchen'},
      ];
      const sensors = [
        {'id': 'cpu', 'label': 'CPU', 'group': 'Board', 'detail': '40 °C'},
      ];
      await publish(
        const {},
        {'device': 1, 'panels.sensor': 1},
        {'device': lamps, 'panels.sensor': sensors},
      );
      var notified = 0;
      void count() => notified++;
      plugins.setup.addListener(count);
      // A run update without lists keeps the ones held.
      const running = {
        'button:test': {
          'run': 'r1',
          'state': 'running',
          'message': 'Scanning',
          'code': '',
          'origin': 'remote',
          'confirm': null,
        },
      };
      await publish(running, {'device': 1, 'panels.sensor': 1});
      expect(notified, 1);
      await publish(running, {'device': 1, 'panels.sensor': 1});
      expect(notified, 1);
      plugins.setup.removeListener(count);
      expect(plugins.setup.value['hello-world']!['choices'], {
        'device': lamps,
        'panels.sensor': sensors,
      });
      // The remote page asks only for the lists that changed.
      Future<Map> read([Map? held]) async =>
          (await commands.execute('getPluginSetup', {
                'id': 'hello-world',
                'choiceRevisions': ?held,
              })).data
              as Map;
      expect((await read())['choices'], {
        'device': lamps,
        'panels.sensor': sensors,
      });
      expect((await read({'device': 1, 'panels.sensor': 1}))['choices'], {});
      await publish(
        running,
        {'device': 1, 'panels.sensor': 2},
        {'panels.sensor': lamps},
      );
      final changed = await read({'device': 1, 'panels.sensor': 1});
      expect(changed['choiceRevisions'], {'device': 1, 'panels.sensor': 2});
      expect(changed['choices'], {'panels.sensor': lamps});
      // A key the plugin no longer names is dropped.
      await publish(running, {'panels.sensor': 2});
      expect((await read())['choices'], {'panels.sensor': lamps});
    },
  );

  testWidgets('settings buttons and plugin choices run through the host', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {
        'key': 'host',
        'title': 'Host',
        'type': 'string',
        'default': '',
        'group': 'Connection',
      },
      {
        'key': 'device',
        'title': 'Device',
        'type': 'string',
        'default': '',
        'choices': 'plugin',
        'group': 'Connection',
        'emptyText': 'Press the button on the bridge, then Refresh.',
      },
    ];
    installed[0]['buttons'] = [
      {
        'id': 'test',
        'title': 'Test connection',
        'label': 'Test',
        'group': 'Connection',
        'visibleWhen': {'key': 'host', 'notEmpty': true},
      },
      {
        'id': 'pair',
        'title': 'Pair with the bridge',
        'label': 'Pair',
        'group': 'Connection',
        'confirm': {
          'title': 'Pair now?',
          'message': 'Press the button on the bridge first.',
          'confirmLabel': 'Pair now',
        },
      },
    ];
    installed[0]['values'] = {'host': '', 'device': 'lamp-2'};
    await plugins.refresh();
    await native('hostSession', {
      'id': 'hello-world',
      'session': 's',
      'capabilities': <String>[],
    });
    Future<void> publish(Map runs, [Map choices = const {}]) =>
        native('setup', {
          'id': 'hello-world',
          'session': 's',
          'setup': {'runs': runs, 'choices': choices},
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
    // The test button waits for a host. The pair button asks first.
    expect(find.text('Test connection'), findsNothing);
    expect(find.text('Connection'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Pair'));
    await tester.pumpAndSettle();
    expect(find.text('Press the button on the bridge first.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls.where((c) => c.method == 'setupRun'), isEmpty);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Pair'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pair now'));
    await tester.pumpAndSettle();
    expect(calls.lastWhere((c) => c.method == 'setupRun').arguments, {
      'id': 'hello-world',
      'target': 'button',
      'key': 'pair',
      'origin': 'device',
    });
    // While it runs the row shows its progress and Cancel.
    final pairing = {
      'run': 'p1',
      'state': 'running',
      'message': 'Waiting for the bridge',
      'code': '',
      'origin': 'device',
      'confirm': null,
    };
    await publish({'button:pair': pairing});
    await tester.pump();
    expect(find.text('Waiting for the bridge'), findsOneWidget);
    // A question from the plugin opens on the device that started the run.
    await publish({
      'button:pair': {
        ...pairing,
        'confirm': {
          'title': 'Trust this bridge?',
          'message': 'SHA-256 AB:CD',
          'confirmLabel': 'Trust',
        },
      },
    });
    // The spinner keeps running, so pump past the dialog's entrance.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('SHA-256 AB:CD'), findsOneWidget);
    await tester.tap(find.text('Trust'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls.lastWhere((c) => c.method == 'setupConfirm').arguments, {
      'id': 'hello-world',
      'run': 'p1',
      'accepted': true,
    });
    await publish({'button:pair': pairing});
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pump();
    expect(calls.lastWhere((c) => c.method == 'setupCancel').arguments, {
      'id': 'hello-world',
      'run': 'p1',
    });
    await publish({
      'button:pair': {
        ...pairing,
        'state': 'error',
        'message': '',
        'code': 'timeout',
      },
    });
    await tester.pump();
    expect(find.text('The plugin did not answer in time.'), findsOneWidget);
    // Before the plugin lists any, the picker says what the plugin's
    // manifest tells it to instead of a Home Assistant connection error.
    await tester.tap(find.byType(PickField));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(ItemPicker),
        matching: find.text('Press the button on the bridge, then Refresh.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Could not reach Home Assistant'), findsNothing);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    // The choice shows its label once the plugin lists it, and a saved one
    // the list lacks is flagged.
    await publish(const {}, {
      'device': [
        {'id': 'lamp-1', 'label': 'Kitchen'},
      ],
    });
    await tester.pump();
    expect(find.text('This choice is no longer listed.'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(calls.lastWhere((c) => c.method == 'setupRun').arguments, {
      'id': 'hello-world',
      'target': 'choices',
      'key': 'device',
      'origin': 'device',
    });
    await tester.tap(find.byType(PickField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kitchen').last);
    await tester.pumpAndSettle();
    final save =
        calls.lastWhere((c) => c.method == 'configure').arguments as Map;
    expect(save['values'], {'device': 'lamp-1'});
    expect(save['patch'], isTrue);
    expect(find.text('This choice is no longer listed.'), findsNothing);
    expect(find.text('Kitchen'), findsOneWidget);
    // The plugin can turn the choice off, such as while its device is
    // unreachable: the picker and Refresh stop opening, the choice stays.
    await native('setup', {
      'id': 'hello-world',
      'session': 's',
      'setup': {
        'runs': const {},
        'choices': {
          'device': [
            {'id': 'lamp-1', 'label': 'Kitchen'},
          ],
        },
        'choicesOff': ['device'],
      },
    });
    await tester.pump();
    expect(tester.widget<PickField>(find.byType(PickField)).enabled, isFalse);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.refresh))
          .onPressed,
      isNull,
    );
    expect(find.text('Kitchen'), findsOneWidget);
    await native('setup', {
      'id': 'hello-world',
      'session': 's',
      'setup': {
        'runs': const {},
        'choices': {
          'device': [
            {'id': 'lamp-1', 'label': 'Kitchen'},
          ],
        },
        'choicesOff': [],
      },
    });
    await tester.pump();
    expect(tester.widget<PickField>(find.byType(PickField)).enabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the plugin hears when its settings page opens and closes', (
    tester,
  ) async {
    const opened = {'id': 'hello-world', 'open': true};
    const closed = {'id': 'hello-world', 'open': false};
    List<Object?> sent() => [
      for (final call in calls)
        if (call.method == 'settingsPage') call.arguments,
    ];
    Future<void> poll(String viewer, {bool open = true}) async {
      final result = await commands.execute('setPluginPageOpen', {
        'id': 'hello-world',
        'viewer': viewer,
        if (!open) 'open': false,
      });
      expect(result.ok, isTrue);
    }

    Future<void> session(String token) => native('hostSession', {
      'id': 'hello-world',
      'session': token,
      'capabilities': <String>[],
    });
    final page = MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PluginDetailPanel(plugins: plugins, id: 'hello-world'),
        ),
      ),
    );
    calls.clear();
    // The kiosk page is open while it shows, a dialog over it included.
    await tester.pumpWidget(page);
    await tester.pump();
    expect(sent(), [opened]);
    final context = tester.element(find.byType(PluginDetailPanel));
    unawaited(
      showDialog<void>(context: context, builder: (_) => const Text('Dialog')),
    );
    await tester.pumpAndSettle();
    expect(sent(), [opened]);
    Navigator.of(context, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    // A full page over it closes it until it shows again.
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const Text('Other page'))),
    );
    await tester.pumpAndSettle();
    expect(sent(), [opened, closed]);
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(sent(), [opened, closed, opened]);
    await tester.pumpWidget(const SizedBox());
    expect(sent(), [opened, closed, opened, closed]);
    // A remote admin page stays open while it checks in and closes about
    // 5 seconds after the last time.
    calls.clear();
    await poll('a');
    await tester.pump(const Duration(seconds: 4));
    await poll('a');
    await tester.pump(const Duration(seconds: 4));
    expect(sent(), [opened]);
    await tester.pump(const Duration(seconds: 2));
    expect(sent(), [opened, closed]);
    // Viewers together open the page once and close it once.
    calls.clear();
    await tester.pumpWidget(page);
    await tester.pump();
    await poll('a');
    await poll('b');
    await tester.pumpWidget(const SizedBox());
    await poll('a', open: false);
    expect(sent(), [opened]);
    await tester.pump(const Duration(seconds: 6));
    expect(sent(), [opened, closed]);
    // A session that starts while the page is open hears it open. One that
    // starts while it is closed hears nothing.
    calls.clear();
    await poll('a');
    await session('next');
    expect(sent(), [opened, opened]);
    await tester.pump(const Duration(seconds: 6));
    await session('last');
    expect(sent(), [opened, opened, closed]);
    expect(
      (await commands.execute('setPluginPageOpen', {
        'id': 'missing',
        'viewer': 'a',
      })).ok,
      isFalse,
    );
    expect(sent(), [opened, opened, closed]);
  });

  test('native overlays are session scoped and keep their stacking', () async {
    await overlaySession('first');
    await overlays('first', [overlay('bar', 1), overlay('full', 2)]);
    expect(plugins.overlays.value.map((o) => o.key), ['bar', 'full']);
    await native('overlaySize', {
      'id': 'hello-world',
      'session': 'first',
      'key': 'bar',
      'generation': 1,
      'width': 300,
      'height': 64,
    });
    expect(plugins.overlays.value.first.measured, const Size(300, 64));
    // A replacement is a new view on top. The others keep their place and
    // their measured size.
    await overlays('first', [overlay('bar', 1), overlay('full', 3)]);
    expect(plugins.overlays.value.map((o) => o.id), [
      'hello-world/bar/1',
      'hello-world/full/3',
    ]);
    expect(plugins.overlays.value.first.measured, const Size(300, 64));
    // A stale session changes nothing, and a new one starts empty.
    await overlaySession('second');
    expect(plugins.overlays.value, isEmpty);
    await overlays('first', [overlay('bar', 1)]);
    expect(plugins.overlays.value, isEmpty);
    await overlays('second', [overlay('bar', 1)]);
    await native('hostSessionClosed', {
      'id': 'hello-world',
      'session': 'second',
    });
    expect(plugins.overlays.value, isEmpty);
  });

  test('a re-created Activity rebuilds the overlay views', () async {
    bus.publish(const ActivityAttached());
    await pumpEventQueue();
    // Nothing to rebuild without overlays.
    expect(plugins.overlayEpoch.value, 0);
    await overlaySession('first');
    await overlays('first', [overlay('bar', 1)]);
    bus.publish(const ActivityAttached());
    await pumpEventQueue();
    expect(plugins.overlayEpoch.value, 1);
  });

  test('back closes the topmost overlay that allows it', () async {
    await overlaySession('first');
    await overlays('first', [
      overlay('bar', 1),
      overlay('pinned', 2, closeOnBack: false),
    ]);
    final target = plugins.backOverlay!;
    expect(target.key, 'bar');
    calls.clear();
    await plugins.closeOverlay(target);
    expect(plugins.overlays.value.map((o) => o.key), ['pinned']);
    expect(plugins.backOverlay, isNull);
    final call = calls.singleWhere((c) => c.method == 'overlayClosed');
    expect(call.arguments, {
      'id': 'hello-world',
      'session': 'first',
      'key': 'bar',
      'generation': 1,
    });
  });

  testWidgets(
    'native overlays take per-edge insets, offsets, outside touches and transitions',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
        call,
      ) async {
        final args = call.arguments;
        return switch (call.method) {
          'create' => 0,
          'resize' => {
            'width': (args as Map)['width'],
            'height': args['height'],
          },
          _ => null,
        };
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          SystemChannels.platform_views,
          null,
        ),
      );
      var dashboardTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => dashboardTaps++,
                child: const SizedBox.expand(),
              ),
              PluginNativeOverlays(plugins: plugins),
            ],
          ),
        ),
      );
      await overlaySession('first');
      Rect rect() => tester.getRect(find.byType(AndroidView));
      // Clear of a 80 dp bar at the bottom, moved along it.
      await overlays('first', [
        overlay(
          'menu',
          1,
          anchor: 'bottom-left',
          width: 200,
          height: 120,
          insets: [0, 0, 0, 80],
          offsetX: 150,
        ),
      ]);
      await tester.pump();
      expect(rect(), const Rect.fromLTWH(150, 400, 200, 120));
      // An offset past the edge keeps the overlay on screen.
      await overlays('first', [
        overlay(
          'menu',
          2,
          anchor: 'bottom-left',
          width: 200,
          height: 120,
          insets: [0, 0, 0, 80],
          offsetX: 5000,
          offsetY: -40,
        ),
      ]);
      await tester.pump();
      expect(rect(), const Rect.fromLTWH(600, 360, 200, 120));

      // A touch outside closes it and goes no further.
      await overlays('first', [
        overlay('menu', 3, width: 200, height: 120, closeOnOutsideTouch: true),
      ]);
      await tester.pump();
      calls.clear();
      await tester.tapAt(const Offset(700, 500));
      await tester.pump();
      expect(find.byType(AndroidView), findsNothing);
      expect(dashboardTaps, 0);
      expect(
        (calls.singleWhere((c) => c.method == 'overlayClosed').arguments
            as Map)['generation'],
        3,
      );
      // Passed through, the same touch also reaches the dashboard.
      await overlays('first', [
        overlay(
          'menu',
          4,
          width: 200,
          height: 120,
          closeOnOutsideTouch: true,
          passOutsideTouch: true,
        ),
      ]);
      await tester.pump();
      await tester.tapAt(const Offset(700, 500));
      await tester.pump();
      expect(find.byType(AndroidView), findsNothing);
      expect(dashboardTaps, 1);

      // A fade in starts clear, and a fade out keeps the view until it ends.
      await overlays('first', [
        overlay(
          'card',
          5,
          anchor: 'center',
          width: 200,
          height: 120,
          enter: 'fade',
          exit: 'fade',
          duration: 300,
        ),
      ]);
      await tester.pump();
      double opacity() => tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(AndroidView),
                  matching: find.byType(Opacity),
                )
                .last,
          )
          .opacity;
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 150));
      expect(opacity(), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(), 1);
      await overlays('first', []);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(AndroidView), findsOneWidget);
      expect(opacity(), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(AndroidView), findsNothing);

      // An ended session leaves at once.
      await overlays('first', [
        overlay('card', 6, width: 200, height: 120, exit: 'slide'),
      ]);
      await tester.pump();
      await overlaySession('second');
      await tester.pump();
      expect(find.byType(AndroidView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hybrid overlays sit in the view tree and are painted while measured',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final views = <MethodCall>[];
      messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
        call,
      ) async {
        views.add(call);
        final args = call.arguments;
        return switch (call.method) {
          'create' => 0,
          'resize' => {
            'width': (args as Map)['width'],
            'height': args['height'],
          },
          _ => null,
        };
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(
          SystemChannels.platform_views,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            fit: StackFit.expand,
            children: [PluginOverlay(plugins: plugins, hybrid: true)],
          ),
        ),
      );
      await overlaySession('first');
      await overlays('first', [
        overlay('bar', 1),
        overlay(
          'full',
          2,
          width: PluginNativeOverlay.fill,
          height: PluginNativeOverlay.fill,
          enter: 'slide',
        ),
      ]);
      await tester.pump();
      expect(find.byType(AndroidView), findsNothing);
      expect(find.byType(PlatformViewLink), findsNWidgets(2));
      // Flutter only attaches a hybrid view it paints, and a wrapped one
      // has to be attached to be measured, so nothing on the way is at 0.
      final opacities = tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byType(PlatformViewLink),
              matching: find.byType(Opacity),
            ),
          )
          .map((o) => o.opacity);
      expect(opacities, everyElement(greaterThan(0)));
      await tester.pump(const Duration(seconds: 1));
      final creates = views.where((c) => c.method == 'create');
      expect(creates, hasLength(2));
      expect(creates.map((c) => (c.arguments as Map)['hybrid']), [true, true]);
    },
  );

  testWidgets('native overlays wait for their size and follow their anchor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final views = <MethodCall>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      views.add(call);
      final args = call.arguments;
      return switch (call.method) {
        'create' => 0,
        'resize' => {'width': (args as Map)['width'], 'height': args['height']},
        _ => null,
      };
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Stack(
          fit: StackFit.expand,
          children: [
            PluginOverlay(plugins: plugins),
            PluginNativeOverlays(plugins: plugins, onTop: true),
          ],
        ),
      ),
    );
    await overlaySession('first');
    await overlays('first', [
      overlay('bar', 1, inset: 12),
      overlay('full', 2, width: PluginNativeOverlay.fill, height: 100),
      overlay(
        'saver',
        3,
        anchor: 'bottom-right',
        onTop: true,
        touchable: false,
      ),
    ]);
    await tester.pump();
    final opacity = find.ancestor(
      of: find.byType(AndroidView),
      matching: find.byType(Opacity),
    );
    expect(find.byType(AndroidView), findsNWidgets(3));
    // Wrapped overlays stay invisible at one pixel until measured.
    expect(tester.widget<Opacity>(opacity.at(0)).opacity, 0);
    expect(tester.widget<Opacity>(opacity.at(1)).opacity, 1);
    expect(
      tester.getRect(find.byType(AndroidView).at(1)),
      const Rect.fromLTWH(0, 0, 400, 100),
    );
    // The creation params carry the placement and the theme.
    final create = views.firstWhere((c) => c.method == 'create');
    final params =
        const StandardMessageCodec().decodeMessage(
              ByteData.sublistView(
                (create.arguments as Map)['params'] as Uint8List,
              ),
            )
            as Map;
    expect(params['key'], 'bar');
    expect(params['insets'], [12, 12, 12, 12]);
    expect((params['theme'] as Map)['dark'], isTrue);
    expect(
      calls.where((c) => c.method == 'overlayTheme').single.arguments,
      params['theme'],
    );
    await native('overlaySize', {
      'id': 'hello-world',
      'session': 'first',
      'key': 'bar',
      'generation': 1,
      'width': 300,
      'height': 64,
    });
    await native('overlaySize', {
      'id': 'hello-world',
      'session': 'first',
      'key': 'saver',
      'generation': 3,
      'width': 200,
      'height': 100,
    });
    await tester.pump();
    expect(tester.widget<Opacity>(opacity.at(0)).opacity, 1);
    // 300 x 64 physical pixels at a ratio of 2, centered under a 12 inset.
    expect(
      tester.getRect(find.byType(AndroidView).at(0)),
      const Rect.fromLTWH(125, 12, 150, 32),
    );
    expect(
      tester.getRect(find.byType(AndroidView).at(2)),
      const Rect.fromLTWH(300, 250, 100, 50),
    );
    // A visual-only overlay lets every touch through.
    bool ignoring(int index) => tester
        .widget<IgnorePointer>(
          find
              .ancestor(
                of: find.byType(AndroidView).at(index),
                matching: find.byType(IgnorePointer),
              )
              .first,
        )
        .ignoring;
    expect(ignoring(0), isFalse);
    expect(ignoring(2), isTrue);
  });
  testWidgets('native overlays follow the Scale UI factor', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final views = <MethodCall>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      views.add(call);
      final args = call.arguments;
      return switch (call.method) {
        'create' => 0,
        'resize' => {'width': (args as Map)['width'], 'height': args['height']},
        _ => null,
      };
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        SystemChannels.platform_views,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => UiScaler(scale: 1.25, child: child!),
        home: PluginOverlay(plugins: plugins),
      ),
    );
    await overlaySession('first');
    await overlays('first', [
      overlay('bar', 1, inset: 12),
      overlay(
        'panel',
        2,
        anchor: 'top-left',
        width: 100,
        height: 40,
        offsetX: 8,
        offsetY: 4,
      ),
    ]);
    await tester.pump();
    final params =
        const StandardMessageCodec().decodeMessage(
              ByteData.sublistView(
                (views.firstWhere((c) => c.method == 'create').arguments
                        as Map)['params']
                    as Uint8List,
              ),
            )
            as Map;
    expect(params['scale'], 1.25);
    expect(params['insets'], [12, 12, 12, 12]);
    // Sizes, insets and offsets in dp grow by the factor.
    expect(
      tester.getRect(find.byType(AndroidView).at(1)),
      const Rect.fromLTWH(10, 5, 125, 50),
    );
    await native('overlaySize', {
      'id': 'hello-world',
      'session': 'first',
      'key': 'bar',
      'generation': 1,
      'width': 300,
      'height': 64,
    });
    await tester.pump();
    // A wrapped view already drew at the scaled density, so its measured
    // pixels map one to one onto the screen: 300 x 64 at a ratio of 2,
    // centered under a 15 dp inset.
    expect(
      tester.getRect(find.byType(AndroidView).at(0)),
      const Rect.fromLTWH(125, 15, 150, 32),
    );
  });

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

  testWidgets(
    'entity settings use the shared picker and save selection or clear',
    (tester) async {
      installed[0]['settings'] = [
        {
          'key': 'entity',
          'title': 'Home Assistant entity',
          'type': 'entity',
          'default': '',
        },
      ];
      installed[0]['values'] = {'entity': ''};
      PickCatalog.reset();
      commands.register(
        Command(
          name: 'haListEntities',
          description: 'test',
          handler: (_) async => const CommandResult.ok([
            {
              'entity_id': 'sensor.room',
              'name': 'Room temperature',
              'state': '21 °C',
              'domain': 'sensor',
            },
            {
              'entity_id': 'light.porch',
              'name': 'Porch light',
              'state': 'On',
              'domain': 'light',
            },
          ]),
        ),
      );
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
      expect(find.byType(TextField), findsNothing);
      final field = find.byType(ControlBox);
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'room');
      await tester.pumpAndSettle();
      expect(find.text('Porch light'), findsNothing);
      await tester.tap(find.text('Room temperature'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: field, matching: find.text('Room temperature')),
        findsOneWidget,
      );
      expect((installed[0]['values'] as Map)['entity'], 'sensor.room');
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect((installed[0]['values'] as Map)['entity'], '');
      expect(find.text('Save settings'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('list rows show entity fields the way the entity picker does', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {
        'key': 'sensors',
        'title': 'Sensors',
        'type': 'list',
        'row': {'title': 'entity'},
        'default': [],
        'fields': [
          {'key': 'entity', 'title': 'Entity', 'type': 'entity'},
        ],
      },
      {
        'key': 'buttons',
        'title': 'Buttons',
        'type': 'list',
        'row': {'title': 'label', 'subtitle': 'target'},
        'default': [],
        'fields': [
          {'key': 'label', 'title': 'Label', 'type': 'string'},
          {'key': 'target', 'title': 'Target', 'type': 'entity'},
        ],
      },
    ];
    installed[0]['values'] = {
      'sensors': [
        {'entity': 'sensor.room'},
        {'entity': 'sensor.gone'},
      ],
      'buttons': [
        {'label': 'Porch', 'target': 'light.porch'},
      ],
    };
    PickCatalog.reset();
    commands.register(
      Command(
        name: 'haListEntities',
        description: 'test',
        handler: (_) async => const CommandResult.ok([
          {
            'entity_id': 'sensor.room',
            'name': 'Room temperature',
            'state': '21 °C',
            'icon': 'mdi:thermometer',
            'domain': 'sensor',
          },
          {
            'entity_id': 'light.porch',
            'name': 'Porch light',
            'state': 'On',
            'domain': 'light',
          },
        ]),
      ),
    );
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
    expect(find.text('Room temperature'), findsOneWidget);
    expect(find.text('21 °C · sensor.room'), findsOneWidget);
    expect(find.text('sensor.gone'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Porch'), findsOneWidget);
    expect(find.text('Porch light · On'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo output follows its settings with charts before readings', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {
        'key': 'chart',
        'title': 'Chart option',
        'type': 'boolean',
        'default': true,
        'group': 'Chart demo',
      },
      {
        'key': 'ha',
        'title': 'Home Assistant entity',
        'type': 'entity',
        'default': '',
        'group': 'Home Assistant demo',
      },
      {
        'key': 'shizuku',
        'title': 'Shizuku option',
        'type': 'boolean',
        'default': false,
        'group': 'Shizuku demo',
      },
    ];
    installed[0]['groups'] = [
      {
        'title': 'Chart demo',
        'charts': ['demo'],
        'readingsTitle': 'Chart readings',
        'readings': ['sensor.wave'],
      },
      {
        'title': 'Home Assistant demo',
        'readingsTitle': 'Home Assistant readings',
        'readings': ['text_sensor.ha_state'],
      },
      {
        'title': 'Shizuku demo',
        'readingsTitle': 'Shizuku readings',
        'readings': ['text_sensor.shizuku_status'],
      },
    ];
    await plugins.refresh();
    plugins.charts.value = {
      'hello-world': [
        {
          'key': 'demo',
          'title': 'Activity chart',
          'type': 'line',
          'timestamps': [1000, 2000],
          'series': [
            {
              'name': 'Wave',
              'values': [1, 2],
            },
          ],
        },
      ],
    };
    plugins.readings.value = {
      'hello-world': [
        {'type': 'sensor', 'key': 'wave', 'name': 'Wave reading', 'state': 2},
        {
          'type': 'text_sensor',
          'key': 'ha_state',
          'name': 'HA reading',
          'state': 'on',
        },
        {
          'type': 'text_sensor',
          'key': 'shizuku_status',
          'name': 'Shizuku reading',
          'state': 'Ready',
        },
      ],
    };
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
    final labels = [
      'Chart demo',
      'Chart option',
      'Activity chart',
      'Chart readings',
      'Wave reading',
      'Home Assistant demo',
      'Home Assistant entity',
      'Home Assistant readings',
      'HA reading',
      'Shizuku demo',
      'Shizuku option',
      'Shizuku readings',
      'Shizuku reading',
    ];
    double previous = -1;
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
      final y = tester.getTopLeft(find.text(label)).dy;
      expect(y, greaterThan(previous), reason: label);
      previous = y;
    }
    final row = find.ancestor(
      of: find.text('Home Assistant entity'),
      matching: find.byType(SettingsRow),
    );
    // The entity field, the picker's control box.
    expect(
      find.descendant(of: row, matching: find.byType(ControlBox)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.byIcon(Icons.chevron_right)),
      findsNothing,
    );
    expect(find.text('Readings'), findsNothing);
    plugins.readings.value = {
      'hello-world': [
        {'type': 'sensor', 'key': 'wave', 'name': 'Wave reading', 'state': 3},
      ],
    };
    await tester.pump();
    expect(find.text('Home Assistant readings'), findsNothing);
    expect(find.text('Shizuku readings'), findsNothing);
    expect(find.text('Chart readings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the plugin page shows the icon the plugin names', (
    tester,
  ) async {
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );
    messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
      calls.add(call);
      if (call.method == 'icon') return png;
      return {'enabled': true, 'plugins': installed};
    });
    Future<Finder> open() async {
      await plugins.refresh();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PluginDetailPanel(
                key: UniqueKey(),
                plugins: plugins,
                id: 'hello-world',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return find.byType(IntroRow);
    }

    // Without an icon the page keeps the generic glyph and never asks.
    var intro = await open();
    expect(
      find.descendant(
        of: intro,
        matching: find.byIcon(Icons.extension_rounded),
      ),
      findsOneWidget,
    );
    expect(calls.where((c) => c.method == 'icon'), isEmpty);

    installed[0] = {
      ...installed[0],
      'icon': 'assets/icon.png',
      'sha256': 'a' * 64,
    };
    intro = await open();
    expect(
      find.descendant(of: intro, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: intro,
        matching: find.byIcon(Icons.extension_rounded),
      ),
      findsNothing,
    );
    expect(calls.where((c) => c.method == 'icon').single.arguments, {
      'id': 'hello-world',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('secret settings stay masked and are only replaced', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {'key': 'token', 'title': 'Token', 'type': 'secret', 'default': ''},
      {'key': 'host', 'title': 'Host', 'type': 'string', 'default': ''},
    ];
    installed[0]['values'] = {'token': '__set__', 'host': 'nas.local'};
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
    expect(find.text('••••••••'), findsOneWidget);
    expect(find.text('__set__'), findsNothing);
    await tester.tap(find.text('Token'));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.byTooltip('Show password'), findsNothing);
    await tester.enterText(field, 'rotated');
    await tester.pump();
    // The eye shows what is typed and hides it again.
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).obscureText, isFalse);
    expect(tester.widget<TextField>(field).controller!.text, 'rotated');
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      // Only the replaced secret. The host keeps the rest.
      {'token': 'rotated'},
    );
    // Editing another setting sends only that one, so the secret stays.
    installed[0]['values'] = {'token': '__set__', 'host': 'nas.local'};
    await plugins.refresh();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Host'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show password'), findsNothing);
    await tester.enterText(field, 'nas.lan');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      {'host': 'nas.lan'},
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('select settings use the app dropdown and save the choice', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {
        'key': 'position',
        'title': 'Position',
        'type': 'select',
        'options': ['Bottom', 'Top'],
        'default': 'Bottom',
      },
    ];
    installed[0]['values'] = {'position': 'Bottom'};
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
    expect(find.byType(DropdownRow<String>), findsOneWidget);
    expect(find.byType(KsDropdown<String>), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.tap(find.text('Bottom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Top').last);
    await tester.pumpAndSettle();
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      {'position': 'Top'},
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('typed number settings save only a value the setting takes', (
    tester,
  ) async {
    const limit = {
      'key': 'limit',
      'title': 'Hot above',
      'description': 'Turns the tile red.',
      'type': 'number',
      'input': 'field',
      'min': -50,
      'max': 150,
      'step': 0.5,
      'default': 85,
      'unit': '°C',
    };
    installed[0]['settings'] = [
      limit,
      {
        'key': 'alerts',
        'title': 'Alerts',
        'type': 'list',
        'group': 'Alerts',
        'addTitle': 'Add alert',
        'row': {'title': 'name', 'subtitle': 'above'},
        'default': [],
        'fields': [
          {'key': 'name', 'title': 'Name', 'type': 'string', 'required': true},
          {
            'key': 'above',
            'title': 'Above',
            'type': 'number',
            'input': 'field',
            'min': 0,
            'max': 100000,
            'unit': 'fps',
          },
        ],
      },
    ];
    installed[0]['values'] = {'limit': 85, 'alerts': []};
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
    Object? saved(String key) =>
        ((calls.lastWhere((c) => c.method == 'configure').arguments
                as Map)['values']
            as Map)[key];
    FilledButton save() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
    // The value shows like a text setting's, with no slider.
    expect(find.byType(Slider), findsNothing);
    expect(find.text('85 °C'), findsOneWidget);

    await tester.tap(find.text('Hot above'));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    // A sign for the range below zero, a decimal point for the half steps.
    final keyboard = tester.widget<TextField>(field).keyboardType;
    expect(keyboard.signed, isTrue);
    expect(keyboard.decimal, isTrue);
    expect(find.text('°C'), findsOneWidget);
    expect(find.text('Turns the tile red.'), findsOneWidget);
    for (final (text, error) in [
      ('hot', 'Expected a numeric setting'),
      ('151', 'Numeric setting is outside its range'),
      ('90.25', 'Numeric setting does not match its step'),
    ]) {
      await tester.enterText(field, text);
      await tester.pump();
      expect(find.text(error), findsOneWidget);
      expect(save().onPressed, isNull);
    }
    expect(calls.where((c) => c.method == 'configure'), isEmpty);
    await tester.enterText(field, '-12.5');
    await tester.pump();
    expect(save().onPressed, isNotNull);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved('limit'), -12.5);
    // A whole value on a whole step saves as a whole number.
    await tester.tap(find.text('Hot above'));
    await tester.pumpAndSettle();
    await tester.enterText(field, '90');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(saved('limit'), 90);

    // In the row editor, Save waits while the number is not valid.
    await tester.tap(find.text('Add alert'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Frame rate');
    final above = find.byType(TextFormField).last;
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: above, matching: find.byType(TextField)),
          )
          .keyboardType
          .signed,
      isFalse,
    );
    await tester.enterText(above, '100001');
    await tester.pump();
    expect(find.text('Numeric setting is outside its range'), findsOneWidget);
    expect(find.textContaining('Required'), findsNothing);
    expect(save().onPressed, isNull);
    await tester.enterText(above, '60.5');
    await tester.pump();
    expect(
      find.text('Numeric setting does not match its step'),
      findsOneWidget,
    );
    expect(save().onPressed, isNull);
    await tester.enterText(above, '60');
    await tester.pump();
    expect(find.text('Numeric setting does not match its step'), findsNothing);
    expect(save().onPressed, isNotNull);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved('alerts'), [
      {'name': 'Frame rate', 'above': 60},
    ]);
    // The row shows the number with its unit.
    expect(find.text('60 fps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('list row fields pick plugin choices and show their labels', (
    tester,
  ) async {
    installed[0]['settings'] = [
      {
        'key': 'panels',
        'title': 'Panels',
        'type': 'list',
        'group': 'Panels',
        'row': {'title': 'sensor', 'subtitle': 'label'},
        'default': [],
        'fields': [
          {'key': 'label', 'title': 'Label', 'type': 'string'},
          {
            'key': 'sensor',
            'title': 'Sensor',
            'type': 'string',
            'choices': 'plugin',
            'required': true,
          },
          {
            'key': 'tiles',
            'title': 'Tiles',
            'type': 'list',
            'fields': [
              {
                'key': 'sensor',
                'title': 'Tile sensor',
                'type': 'string',
                'choices': 'plugin',
              },
            ],
          },
        ],
      },
    ];
    installed[0]['values'] = {
      'panels': [
        {
          'label': 'Main',
          'sensor': 'cpu.temp',
          'tiles': [
            {'sensor': 'gpu.temp'},
            {'sensor': 'board.temp'},
          ],
        },
      ],
    };
    await plugins.refresh();
    await native('hostSession', {
      'id': 'hello-world',
      'session': 's',
      'capabilities': <String>[],
    });
    Future<void> publish(Map revisions, [Map choices = const {}]) =>
        native('setup', {
          'id': 'hello-world',
          'session': 's',
          'setup': {
            'runs': const {},
            'choiceRevisions': revisions,
            'choices': choices,
          },
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
    // The row shows the raw ID until the plugin lists its choices.
    expect(find.text('cpu.temp'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    await publish(
      {'panels.sensor': 1, 'panels.tiles.sensor': 1},
      {
        'panels.sensor': [
          {
            'id': 'cpu.temp',
            'label': 'CPU temperature',
            'group': 'Processor',
            'detail': '54 °C',
          },
          {'id': 'fan', 'label': 'Fan speed'},
          {
            'id': 'gpu.temp',
            'label': 'GPU temperature',
            'group': 'Graphics',
            'detail': '61 °C',
          },
        ],
        'panels.tiles.sensor': [
          {'id': 'gpu.temp', 'label': 'Graphics heat'},
        ],
      },
    );
    await tester.pump();
    expect(find.text('CPU temperature'), findsOneWidget);
    // A run update without lists keeps the labels.
    await publish({'panels.sensor': 1, 'panels.tiles.sensor': 1});
    await tester.pump();
    expect(find.text('CPU temperature'), findsOneWidget);

    await tester.tap(find.text('CPU temperature'));
    await tester.pumpAndSettle();
    // The editor's title and field show the label too, over the row.
    expect(find.text('CPU temperature'), findsNWidgets(3));
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(calls.lastWhere((c) => c.method == 'setupRun').arguments, {
      'id': 'hello-world',
      'target': 'choices',
      'key': 'panels.sensor',
      'origin': 'device',
    });
    // Groups head their choices in the order they appear, a detail is the
    // second line and a choice without a group has no heading.
    await tester.tap(find.byType(PickField));
    await tester.pumpAndSettle();
    expect(find.text('Processor'), findsOneWidget);
    expect(find.text('Graphics'), findsOneWidget);
    expect(find.text('61 °C'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Processor')).dy,
      lessThan(tester.getTopLeft(find.text('Graphics')).dy),
    );
    await tester.enterText(find.byType(TextField).last, '61');
    await tester.pumpAndSettle();
    expect(find.text('54 °C'), findsNothing);
    await tester.tap(find.text('GPU temperature'));
    await tester.pumpAndSettle();
    expect(find.text('GPU temperature'), findsNWidgets(1));

    // The nested rows show their own field's labels, or the ID it lacks.
    expect(find.text('Graphics heat'), findsOneWidget);
    expect(find.text('board.temp'), findsOneWidget);
    await tester.tap(find.text('board.temp'));
    await tester.pumpAndSettle();
    expect(find.text('This choice is no longer listed.'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pump();
    expect(
      (calls.lastWhere((c) => c.method == 'setupRun').arguments as Map)['key'],
      'panels.tiles.sensor',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved =
        ((calls.lastWhere((c) => c.method == 'configure').arguments
                    as Map)['values']
                as Map)['panels']
            as List;
    expect((saved.single as Map)['sensor'], 'gpu.temp');
    expect(find.text('GPU temperature'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list settings edit rows in a modal and save the whole list', (
    tester,
  ) async {
    const entries = {
      'key': 'entries',
      'title': 'Entries',
      'type': 'list',
      'addTitle': 'Add entry',
      'minItems': 1,
      'visibleWhen': {'key': 'opens', 'equals': 'Menu'},
      'fields': [
        {'key': 'label', 'title': 'Label', 'type': 'string', 'required': true},
        {'key': 'url', 'title': 'Address', 'type': 'string'},
      ],
    };
    installed[0]['settings'] = [
      {
        'key': 'collapse',
        'title': 'Collapse',
        'type': 'select',
        'options': ['Off', 'On'],
        'default': 'Off',
        'group': 'Behavior',
      },
      {
        'key': 'after',
        'title': 'Collapse after',
        'type': 'number',
        'min': 0,
        'max': 60,
        'default': 0,
        'group': 'Behavior',
        'visibleWhen': {'key': 'collapse', 'notEquals': 'Off'},
      },
      {
        'key': 'items',
        'title': 'Items',
        'type': 'list',
        'group': 'Items',
        'addTitle': 'Add item',
        'row': {
          'title': 'label',
          'subtitle': ['url', 'opens'],
        },
        'default': [],
        'fields': [
          {
            'key': 'label',
            'title': 'Label',
            'type': 'string',
            'required': true,
          },
          {
            'key': 'opens',
            'title': 'Opens',
            'type': 'select',
            'options': ['Web address', 'Menu'],
          },
          {
            'key': 'url',
            'title': 'Address',
            'type': 'string',
            'required': true,
            'visibleWhen': {'key': 'opens', 'equals': 'Web address'},
          },
          entries,
        ],
      },
    ];
    installed[0]['values'] = {
      'collapse': 'Off',
      'after': 0,
      'items': [
        {
          'label': 'Home',
          'opens': 'Web address',
          'url': 'https://example.com',
          'entries': [],
        },
      ],
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
    List<Object?> savedItems() =>
        ((calls.lastWhere((c) => c.method == 'configure').arguments
                    as Map)['values']
                as Map)['items']
            as List;
    // A setting whose condition fails stays off the page, and the list,
    // alone in its group, has no title row of its own.
    expect(find.text('Collapse after'), findsNothing);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('https://example.com'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Home'), 'House');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((savedItems().single as Map)['label'], 'House');
    expect(find.text('House'), findsOneWidget);

    // A new row waits for its required fields, including a nested row.
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
    FilledButton save() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
    expect(save().onPressed, isNull);
    expect(find.textContaining('Required'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).first, 'Cameras');
    await tester.pump();
    await tester.tap(find.text('Web address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    expect(find.text('Address'), findsNothing);
    expect(save().onPressed, isNull);
    await tester.tap(find.text('Add entry'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Front door');
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Front door'), findsOneWidget);
    expect(save().onPressed, isNotNull);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(savedItems(), hasLength(2));
    expect(savedItems().last, {
      'label': 'Cameras',
      'opens': 'Menu',
      'url': '',
      'entries': [
        {'label': 'Front door', 'url': ''},
      ],
    });

    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect((savedItems().single as Map)['label'], 'Cameras');

    // Turning the condition's setting on brings its dependent back.
    installed[0]['values'] = {
      ...installed[0]['values'] as Map<String, Object?>,
      'collapse': 'On',
    };
    await plugins.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Collapse after'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
      {'brightness': 75.0},
    );
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pulse').last);
    await tester.pumpAndSettle();
    expect(find.text('Save settings'), findsNothing);
    expect(
      (calls.lastWhere((c) => c.method == 'configure').arguments
          as Map)['values'],
      {'effect': 'Pulse'},
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
        'patch': true,
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

  test('fired triggers reach the bus only from the live session', () async {
    final fired = <PluginTriggerFired>[];
    final sub = bus.on<PluginTriggerFired>().listen(fired.add);
    expect((await commands.execute('getPluginTriggers', {})).data, [
      {
        'pluginId': 'hello-world',
        'pluginName': 'Hello World',
        'trigger': 'hardwareKey',
        'title': 'Hardware key',
        'available': true,
      },
    ]);
    await native('hostSession', {
      'id': 'hello-world',
      'session': 'live',
      'capabilities': [],
    });
    await native('trigger', {
      'id': 'hello-world',
      'session': 'stale',
      'trigger': 'hardwareKey',
    });
    await native('trigger', {
      'id': 'hello-world',
      'session': 'live',
      'trigger': 'hardwareKey',
    });
    await Future<void>.delayed(Duration.zero);
    expect(fired, hasLength(1));
    expect(fired.single.pluginId, 'hello-world');
    expect(fired.single.trigger, 'hardwareKey');
    await plugins.update('disable', {'id': 'hello-world'});
    expect(plugins.triggers.single['available'], isFalse);
    await sub.cancel();
  });

  test('setting actions run only for the live session', () async {
    final ran = <Map<String, Object?>>[];
    plugins.runAction = (action) async {
      ran.add(action);
      return action['type'] == 'refresh'
          ? const CommandResult.ok()
          : const CommandResult.fail('Lockdown Mode is on');
    };
    Future<Object?> run(String session, Object? action) async {
      final reply = Completer<Object?>();
      await messenger.handlePlatformMessage(
        'kiosk_satellite/plugins',
        codec.encodeMethodCall(
          MethodCall('runAction', {
            'id': 'hello-world',
            'session': session,
            'action': action,
          }),
        ),
        (data) => reply.complete(codec.decodeEnvelope(data!)),
      );
      return reply.future;
    }

    await native('hostSession', {
      'id': 'hello-world',
      'session': 'live',
      'capabilities': [],
    });
    expect(await run('stale', {'type': 'refresh'}), {
      'ok': false,
      'error': 'Plugin session has ended',
    });
    expect(ran, isEmpty);
    expect(await run('live', {'type': 'refresh'}), {'ok': true});
    expect(await run('live', {'type': 'app_launcher'}), {
      'ok': false,
      'error': 'Lockdown Mode is on',
    });
    expect(ran, [
      {'type': 'refresh'},
      {'type': 'app_launcher'},
    ]);
    expect(plugins.actionNames('hello-world', 'show'), (
      plugin: 'Hello World',
      title: 'Show window',
    ));
    expect(plugins.actionNames('hello-world', 'gone'), isNull);
    expect(plugins.actionNames('other', 'show'), isNull);
  });
}
