import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/ui/kit.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/update_helper_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const installer = MethodChannel('kiosk_satellite/installer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var nativeSilent = false;
  var helper = 'unavailable';
  late AppContainer container;

  setUp(() {
    nativeSilent = false;
    helper = 'unavailable';
    container = AppContainer();
    messenger.setMockMethodCallHandler(
      installer,
      (_) async => {
        'nativeSilent': nativeSilent,
        'helper': helper,
        'startCommand': 'adb shell helper-start',
      },
    );
  });
  tearDown(() => messenger.setMockMethodCallHandler(installer, null));

  Future<void> show(WidgetTester tester, {WidgetBuilder? entryBuilder}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: UpdateHelperSettings(
              container: container,
              entryBuilder: entryBuilder,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('native silent devices hide the entry even with a ready helper', (
    tester,
  ) async {
    nativeSilent = true;
    helper = 'ready';
    await show(
      tester,
      entryBuilder: (_) => const Text('Optional update helper'),
    );
    expect(find.text('Optional update helper'), findsNothing);
    expect(find.text('Start through ADB'), findsNothing);
  });

  testWidgets('the Device entry opens the helper subpage and Back returns', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await container.settings.init();
    await tester.pumpWidget(
      MaterialApp(
        home: CategorySettingsScreen(
          container: container,
          title: 'Device',
          category: 'Device',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final entry = find.widgetWithText(ListTile, 'Optional update helper');
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    expect(find.text('Helper status'), findsNothing);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(SubpageSettingsScreen), findsOneWidget);
    expect(find.text('Helper status'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(entry, findsOneWidget);
    expect(find.text('Helper status'), findsNothing);
  });

  testWidgets(
    'the page refreshes status with its introductory hint outside the card and no Stop action',
    (tester) async {
      await show(tester);
      final intro = find.textContaining(
        'This device currently needs confirmation',
      );
      expect(intro, findsOneWidget);
      expect(
        find.ancestor(of: intro, matching: find.byType(SettingsCard)),
        findsNothing,
      );
      expect(find.text('Setup guide'), findsOneWidget);
      expect(find.text('adb shell helper-start'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);

      helper = 'ready';
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(
        find.text('Ready. Updates install without confirmation.'),
        findsOneWidget,
      );
      expect(find.text('Stop'), findsNothing);
    },
  );

  testWidgets('the setup guide opens in the external websites WebView', (
    tester,
  ) async {
    String? opened;
    container.commands.register(
      Command(
        name: 'showLinkPage',
        description: '',
        handler: (params) async {
          opened = params['url'] as String;
          return const CommandResult.ok();
        },
      ),
    );
    await show(tester);
    await tester.ensureVisible(find.text('Setup guide'));
    await tester.tap(find.text('Setup guide'));
    await tester.pumpAndSettle();
    expect(
      opened,
      'https://github.com/jxlarrea/kiosk-satellite/blob/main/docs/updates.md#optional-update-helper',
    );
  });

  testWidgets('a failed initial status check offers a working retry', (
    tester,
  ) async {
    messenger.setMockMethodCallHandler(installer, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    await show(tester);
    expect(find.text('Could not check the update helper.'), findsOneWidget);
    messenger.setMockMethodCallHandler(
      installer,
      (_) async => {'nativeSilent': false, 'helper': 'ready'},
    );
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ready. Updates install without confirmation.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'native silent installation becoming available keeps the open page informative',
    (tester) async {
      await show(tester);
      nativeSilent = true;
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Android can now install updates silently. The helper is not needed.',
        ),
        findsOneWidget,
      );
      expect(find.text('Start through ADB'), findsNothing);
    },
  );
}
