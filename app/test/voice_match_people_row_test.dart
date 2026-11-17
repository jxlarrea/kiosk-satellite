import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/entity_picker.dart';
import 'package:kiosk_satellite/ui/ground_control_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ground Control Voice Match > People: the chosen people by name, everyone
/// enrolled in the picker and a chosen person Ground Control no longer has
/// kept under the stored name.
void main() {
  late AppContainer c;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PickCatalog.reset();
    c = AppContainer();
    await c.settings.init();
    c.groundControl.people = [
      {'id': 'a', 'name': 'Ana', 'color': '#56814F', 'has_voice': true},
      {'id': 'l', 'name': 'Leo', 'color': '#7A5BA6', 'has_voice': true},
    ];
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VoiceMatchPeopleRow(container: c)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nobody chosen reads as anyone enrolled', (tester) async {
    await pump(tester);
    expect(find.text('People'), findsOneWidget);
    expect(find.text('Anyone enrolled'), findsOneWidget);
  });

  testWidgets('the chosen people show by the name Ground Control has now', (
    tester,
  ) async {
    await c.settings.set(
      defs.voiceMatchPeople,
      '[{"id": "a", "name": "Old name"}, {"id": "gone", "name": "Mia"}]',
    );
    await pump(tester);
    expect(find.text('Ana, Mia'), findsOneWidget);
  });

  testWidgets('picking saves each person by id and name', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Anyone enrolled'));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsWidgets);
    expect(find.text('Leo'), findsWidgets);
    await tester.tap(find.text('Leo').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(defs.decodeVoiceMatchPeople(c.settings.get(defs.voiceMatchPeople)), [
      (id: 'l', name: 'Leo'),
    ]);
    expect(find.text('Leo'), findsOneWidget);
  });
}
