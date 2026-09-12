import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:kiosk_satellite/ui/shizuku_settings.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/managers/wake_word/permission_descriptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/managers/shizuku/shizuku_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'no startup actions, allowlisted requests and verified grant outcomes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final log = Logger(), bus = EventBus();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      final manager = ShizukuManager(bus, commands, log);
      final calls = <MethodCall>[];
      var held = <String, Object?>{
        'batteryUnrestricted': true,
        'notification': true,
      };
      commands.register(
        Command(
          name: 'getSystemPermissions',
          description: 'Fixture',
          handler: (_) async => CommandResult.ok(held),
        ),
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(ShizukuManager.channel, (call) async {
        calls.add(call);
        if (call.method != 'runAction') {
          return {'status': 'ready', 'granted': true, 'uid': 2000};
        }
        final action = (call.arguments as Map)['action'];
        return {
          'results': [
            if (action != 'grantAll') {'key': action, 'ok': true},
          ],
        };
      });
      try {
        await manager.init();
        expect(calls, isEmpty);
        expect((await commands.execute('getShizukuState', {})).ok, true);
        expect(calls.single.method, 'state');
        final count = calls.length;
        expect(
          (await commands.execute('runShizukuAction', {'action': 'shell'})).ok,
          false,
        );
        expect(calls.length, count);
        await manager.run('grantAll');
        final requested = (calls.last.arguments as Map)['permissions'] as List;
        expect(requested, isNot(contains('batteryUnrestricted')));
        expect(requested, isNot(contains('notification')));
        expect(
          requested,
          containsAll([
            'allFiles',
            'usageAccess',
            'uiGuard',
            'deviceAdmin',
            'camera',
            'microphone',
            'bluetooth',
            'location',
          ]),
        );
        expect(requested.length, 10);
        final result = await manager.run('writeSettings');
        expect((result['results'] as List).single['ok'], false);
        held = {...held, 'writeSettings': true};
        final confirmed = await manager.run('writeSettings');
        expect((confirmed['results'] as List).single['ok'], true);
        expect((calls.last.arguments as Map).keys, ['action']);
        expect(settings.export().containsKey('shizuku.enabled'), false);
      } finally {
        await manager.dispose();
        await settings.dispose();
        await bus.dispose();
        messenger.setMockMethodCallHandler(ShizukuManager.channel, null);
      }
    },
  );
  testWidgets(
    'update opt-in saves immediately below Connection and remains local',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = AppContainer();
      await container.settings.init();
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        ShizukuManager.channel,
        (_) async => {'status': 'unavailable'},
      );
      addTearDown(() async {
        messenger.setMockMethodCallHandler(ShizukuManager.channel, null);
        await container.shizuku.dispose();
        await container.settings.dispose();
        await container.bus.dispose();
      });
      expect(container.settings.get(shizukuInstallUpdates), false);
      expect(shizukuInstallUpdates.perDevice, true);
      await tester.pumpWidget(
        MaterialApp(
          home: SubpageSettingsScreen(
            container: container,
            category: 'Device',
            subpage: 'Shizuku',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.widgetWithText(
        SwitchListTile,
        shizukuInstallUpdates.title,
      );
      expect(toggle, findsOneWidget);
      expect(
        tester.getTopLeft(toggle).dy,
        greaterThan(tester.getBottomLeft(find.text('Test connection')).dy),
      );
      expect(
        tester.getBottomLeft(toggle).dy,
        lessThan(tester.getTopLeft(find.text('Permissions')).dy),
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(container.settings.get(shizukuInstallUpdates), true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('ks.shizuku.install_updates'), true);
      expect(find.text('Save settings'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('permission buttons work on wide and narrow screens', (
    tester,
  ) async {
    final log = Logger(), bus = EventBus();
    final manager = ShizukuManager(bus, CommandRegistry(log), log);
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ShizukuManager.channel, (call) async {
      calls.add(call);
      return {'status': 'ready', 'granted': true, 'uid': 2000};
    });
    addTearDown(() async {
      await manager.dispose();
      await bus.dispose();
      messenger.setMockMethodCallHandler(ShizukuManager.channel, null);
      await tester.binding.setSurfaceSize(null);
    });
    for (final width in [1100.0, 390.0]) {
      await tester.binding.setSurfaceSize(Size(width, 1000));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            listTileTheme: const ListTileThemeData(
              titleTextStyle: TextStyle(fontSize: 17),
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShizukuSettingsPanel(
                manager: manager,
                updateSettings: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(13));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      for (final info in devicePermissionDescriptions.values) {
        expect(find.text(info.title), findsOneWidget);
        expect(find.text(info.description), findsOneWidget);
      }
      final connection = tester.widget<SettingsRow>(
        find.ancestor(
          of: find.text('Test connection'),
          matching: find.byType(SettingsRow),
        ),
      );
      expect(connection.onTap, isNull);
      expect(connection.trailing, isA<OutlinedButton>());
      expect(tester.takeException(), isNull);
    }
    expect(calls.every((call) => call.method == 'state'), isTrue);
  });
}
