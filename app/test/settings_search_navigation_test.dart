import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/plugins/plugin_manager.dart';
import 'package:kiosk_satellite/managers/shizuku/shizuku_manager.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:kiosk_satellite/ui/settings_search.dart';
import 'package:kiosk_satellite/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [500.0, 1200.0]) {
    testWidgets(
      'search opens custom controls at width $width without running actions',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final container = AppContainer();
        await container.settings.init();
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final calls = <String>[];
        final plugins = <Map<String, Object?>>[
          {
            'id': 'hello',
            'name': 'Hello World',
            'description': 'A sample plugin',
            'version': '1.0.0',
            'enabled': true,
            'settings': [
              {
                'key': 'greeting',
                'title': 'Greeting',
                'description': 'Text shown in the floating window.',
                'type': 'string',
                'default': 'Hello',
              },
            ],
            'values': <String, Object?>{},
          },
        ];
        container.plugins.installed.value = plugins;
        container.plugins.enabled.value = true;
        messenger.setMockMethodCallHandler(PluginManager.channel, (call) async {
          calls.add(call.method);
          return {
            'enabled': container.plugins.enabled.value,
            'plugins': plugins,
          };
        });
        messenger.setMockMethodCallHandler(ShizukuManager.channel, (
          call,
        ) async {
          calls.add(call.method);
          return {'status': 'ready', 'granted': true, 'uid': 2000};
        });
        await container.plugins.init();
        calls.clear();
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(() async {
          messenger.setMockMethodCallHandler(PluginManager.channel, null);
          messenger.setMockMethodCallHandler(ShizukuManager.channel, null);
          await container.plugins.dispose();
          await container.shizuku.dispose();
          await container.settings.dispose();
          await container.bus.dispose();
          tester.view.reset();
        });
        Future<void> openResult(
          String query,
          String title,
          String target, {
          String? page,
        }) async {
          await tester.pumpWidget(
            MaterialApp(
              key: UniqueKey(),
              theme: buildTheme(Brightness.light),
              home: SettingsScreen(container: container),
            ),
          );
          // The initial Home Assistant pane can poll, so advance only the search transition.
          await tester.pump(const Duration(milliseconds: 100));
          final field = find.widgetWithText(TextField, 'Search settings');
          await tester.enterText(field, query);
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text(title).last);
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pump(const Duration(milliseconds: 1800));
          final anchor = find.byWidgetPredicate(
            (widget) => widget is SearchLandingTarget && widget.id == target,
          );
          expect(anchor, findsOneWidget);
          final scope = SearchLandingScope.maybeOf(tester.element(anchor));
          expect(scope?.target, target);
          expect(
            tester.getRect(anchor).overlaps(Offset.zero & Size(width, 1000)),
            true,
          );
          if (width < 720 && page != null) {
            expect(
              tester
                  .widget<SubpageSettingsScreen>(
                    find.byType(SubpageSettingsScreen),
                  )
                  .subpage,
              page,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 11));
        }

        await openResult(
          'Test connection',
          'Test connection',
          'x:shizuku:identity',
          page: 'Shizuku',
        );
        await openResult(
          'floating window',
          'Greeting',
          'plugin:hello:setting:greeting',
          page: 'hello',
        );
        container.plugins.enabled.value = false;
        await openResult(
          'Install from ZIP',
          'Install from ZIP',
          'x:plugins:master',
        );
        expect(container.plugins.enabled.value, false);
        expect(
          calls.every((call) => ['list', 'state'].contains(call)),
          true,
          reason: calls.toString(),
        );
      },
    );
  }
}
