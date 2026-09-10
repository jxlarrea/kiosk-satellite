import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/esphome_entity_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsManager settings;
  late CommandRegistry commands;
  var failCatalog = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final log = Logger();
    commands = CommandRegistry(log);
    settings = SettingsManager(EventBus(), commands, log);
    await settings.init();
    failCatalog = false;
    commands.register(
      Command(
        name: 'getEspHomeEntities',
        description: 'test catalog',
        handler: (_) async => failCatalog
            ? const CommandResult.fail('Unavailable')
            : const CommandResult.ok([
                {
                  'objectId': 'screen',
                  'name': 'Screen',
                  'type': 'light',
                  'categoryLabel': 'Control',
                },
                {
                  'objectId': 'battery',
                  'name': 'Battery',
                  'type': 'sensor',
                  'categoryLabel': 'Diagnostics',
                },
                {
                  'objectId': 'kiosk',
                  'name': 'Kiosk mode',
                  'type': 'switch',
                  'categoryLabel': 'Configuration',
                },
              ]),
      ),
    );
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return EspHomeExcludedEntitiesRow(
                settings: settings,
                commands: commands,
                onChanged: () => setState(() {}),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Excluded entities'));
    await tester.pumpAndSettle();
  }

  testWidgets('search and save exclusions while preserving unavailable IDs', (
    tester,
  ) async {
    await settings.set(esphomeExcludedEntities, '["missing"]');
    await open(tester);
    expect(find.text('Currently unavailable'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'battery');
    await tester.pumpAndSettle();
    expect(find.text('Screen'), findsNothing);
    await tester.tap(find.text('Battery'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      decodeEspHomeExcludedEntities(settings.get(esphomeExcludedEntities)),
      {'battery', 'missing'},
    );
    expect(find.text('2 excluded'), findsOneWidget);

    await tester.tap(find.text('Excluded entities'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Battery'),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.text('Clear'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(settings.get(esphomeExcludedEntities), '[]');
    expect(find.text('All available entities exposed'), findsOneWidget);
  });

  testWidgets('cancel discards the edited selection', (tester) async {
    await open(tester);
    await tester.tap(find.text('Screen'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(settings.get(esphomeExcludedEntities), '[]');
  });

  testWidgets('Select all includes entities outside the search results', (
    tester,
  ) async {
    await open(tester);
    await tester.enterText(find.byType(TextField), 'battery');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      decodeEspHomeExcludedEntities(settings.get(esphomeExcludedEntities)),
      {'battery', 'screen', 'kiosk'},
    );
  });

  testWidgets('category appears before type and can be searched', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Control · light'), findsOneWidget);
    expect(find.text('Diagnostics · sensor'), findsOneWidget);
    expect(find.text('Configuration · switch'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'configuration');
    await tester.pumpAndSettle();
    expect(find.text('Kiosk mode'), findsOneWidget);
    expect(find.text('Battery'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('catalog failure cannot overwrite saved exclusions', (
    tester,
  ) async {
    failCatalog = true;
    await settings.set(esphomeExcludedEntities, '["screen"]');
    await open(tester);
    expect(find.textContaining('Could not load entities'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(settings.get(esphomeExcludedEntities), '["screen"]');
  });
}
