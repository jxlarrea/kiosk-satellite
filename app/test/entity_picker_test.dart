import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/ui/entity_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _entities = <Map<String, Object?>>[
  {
    'entity_id': 'light.living_room_lamp',
    'name': 'Living Room Lamp',
    'state': 'On',
    'domain': 'light',
    'domain_title': 'Light',
    'area': 'Living Room',
  },
  {
    'entity_id': 'sensor.living_room_temperature',
    'name': 'Living Room Temperature',
    'state': '22.4 °C',
    'domain': 'sensor',
    'domain_title': 'Sensor',
    'area': 'Living Room',
  },
  {
    'entity_id': 'sensor.kitchen_illuminance',
    'name': 'Kitchen Light Level',
    'state': '312 lx',
    'domain': 'sensor',
    'domain_title': 'Sensor',
    'area': 'Kitchen',
  },
  {
    'entity_id': 'light.all_art_lights',
    'name': 'All Art Lights',
    'state': 'Off',
    'domain': 'light',
    'domain_title': 'Light',
    'area': 'Living Room',
    'hidden': true,
  },
  {
    'entity_id': 'weather.forecast_home',
    'name': 'Forecast Home',
    'state': 'Partly cloudy',
    'domain': 'weather',
    'domain_title': 'Weather',
  },
];

CommandRegistry _commands({bool playersFail = false, CommandRegistry? into}) {
  final commands = into ?? CommandRegistry(Logger());
  commands
    ..register(
      Command(
        name: 'haListEntities',
        description: 'fake',
        handler: (_) async => const CommandResult.ok(_entities),
      ),
    )
    ..register(
      Command(
        name: 'haEntityAttributes',
        description: 'fake',
        handler: (_) async => const CommandResult.ok({
          'unit_of_measurement': '°C',
          'device_class': 'temperature',
          'friendly_name': 'Living Room Temperature',
          'forecast': [1, 2],
        }),
      ),
    )
    ..register(
      Command(
        name: 'mediaPlayers',
        description: 'fake',
        handler: (p) async => CommandResult.ok({
          'players': [
            {'id': 'ma:kitchen', 'name': 'Kitchen', 'group': 'ma'},
            {
              'id': 'ma:office',
              'name': 'Office',
              'group': 'ma',
              'available': false,
            },
            {'id': 'ha:media_player.tv', 'name': 'TV', 'group': 'ha'},
          ],
          'notes': playersFail ? {'ma': 'Music Assistant is not set up'} : {},
        }),
      ),
    );
  return commands;
}

Future<void> _pump(
  WidgetTester tester,
  Size size,
  Widget Function(BuildContext) child,
) async {
  PickCatalog.reset();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Builder(builder: child)),
    ),
  );
}

void main() {
  testWidgets('entities list under their areas, no area last, and the chips '
      'and search narrow them', (tester) async {
    final commands = _commands();
    PickOutcome? outcome;
    await _pump(
      tester,
      const Size(1200, 800),
      (context) => TextButton(
        onPressed: () async => outcome = await showItemPicker(
          context,
          title: 'Entity',
          spec: entitySpec(context, commands),
          selected: 'sensor.living_room_temperature',
          allowClear: true,
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final kitchen = tester.getTopLeft(find.text('Kitchen')).dy;
    final living = tester.getTopLeft(find.text('Living Room')).dy;
    final none = tester.getTopLeft(find.text('No area')).dy;
    expect(kitchen, lessThan(living));
    expect(living, lessThan(none));
    // Weather is a chip of its own; picking it leaves only weather.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Weather'));
    await tester.pumpAndSettle();
    expect(find.text('Forecast Home'), findsOneWidget);
    expect(find.text('Living Room Lamp'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();
    // Search matches names, ids and areas.
    await tester.enterText(find.byType(TextField), 'kitchen');
    await tester.pumpAndSettle();
    expect(find.text('Kitchen Light Level'), findsOneWidget);
    expect(find.text('Living Room Lamp'), findsNothing);
    await tester.tap(find.text('Kitchen Light Level'));
    await tester.pumpAndSettle();
    expect(outcome?.id, 'sensor.kitchen_illuminance');
  });

  testWidgets('hidden entities stay out unless the picker asks for them, '
      'and then carry the hidden mark', (tester) async {
    final commands = _commands();
    for (final includeHidden in [false, true]) {
      await _pump(
        tester,
        const Size(1200, 800),
        (context) => TextButton(
          onPressed: () => showItemPicker(
            context,
            title: 'Entity',
            spec: entitySpec(
              context,
              commands,
              domains: const ['light'],
              includeHidden: includeHidden,
            ),
          ),
          child: const Text('open'),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Living Room Lamp'), findsOneWidget);
      expect(
        find.text('All Art Lights'),
        includeHidden ? findsOneWidget : findsNothing,
      );
      expect(
        find.byIcon(Icons.visibility_off),
        includeHidden ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('Clear reports an empty pick, Cancel nothing', (tester) async {
    final commands = _commands();
    final outcomes = <PickOutcome?>[];
    await _pump(
      tester,
      const Size(400, 800),
      (context) => TextButton(
        onPressed: () async => outcomes.add(
          await showItemPicker(
            context,
            title: 'Entity',
            spec: entitySpec(context, commands),
            allowClear: true,
          ),
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(outcomes, hasLength(2));
    expect(outcomes[0], isNotNull);
    expect(outcomes[0]!.id, isNull);
    expect(outcomes[1], isNull);
  });

  testWidgets('a grid picker shows tiles, searches and picks one', (
    tester,
  ) async {
    final outcomes = <PickOutcome?>[];
    final spec = PickSpec(
      key: 'gridTest',
      loader: () async => PickList([
        for (final name in ['garage', 'garage-open', 'home', 'sofa'])
          PickItem(
            id: 'mdi:$name',
            name: name.replaceAll('-', ' '),
            sub: name,
            icon: 'mdi:$name',
          ),
      ]),
      searchHint: 'Search icons',
      noGroup: '',
      chips: false,
      headings: false,
      grid: true,
      limit: 3,
    );
    await _pump(
      tester,
      const Size(1200, 800),
      (context) => TextButton(
        onPressed: () async => outcomes.add(
          await showItemPicker(
            context,
            title: 'Icon',
            spec: spec,
            selected: 'mdi:home',
          ),
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    // At most three show, the picked one first.
    expect(find.text('home'), findsOneWidget);
    expect(find.text('garage'), findsOneWidget);
    expect(find.text('garage-open'), findsOneWidget);
    expect(find.text('sofa'), findsNothing);
    expect(
      tester.getTopLeft(find.text('home')).dx,
      lessThan(tester.getTopLeft(find.text('garage')).dx),
    );
    // Words find the dashed name.
    await tester.enterText(find.byType(TextField), 'garage open');
    await tester.pumpAndSettle();
    expect(find.text('garage-open'), findsOneWidget);
    expect(find.text('sofa'), findsNothing);
    await tester.tap(find.text('garage-open'));
    await tester.pumpAndSettle();
    expect(outcomes.single?.id, 'mdi:garage-open');
  });

  testWidgets('several picks stop at the limit and come back in order', (
    tester,
  ) async {
    final commands = _commands();
    List<String>? picked;
    await _pump(
      tester,
      const Size(1200, 800),
      (context) => TextButton(
        onPressed: () async => picked = await showItemMultiPicker(
          context,
          title: 'At a Glance',
          spec: entitySpec(context, commands),
          selected: const ['weather.forecast_home'],
          max: 2,
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1 of 2'), findsOneWidget);
    await tester.tap(find.text('Living Room Lamp'));
    await tester.pumpAndSettle();
    expect(find.text('Remove one to add another.'), findsOneWidget);
    // Full: another row does not join.
    await tester.tap(find.text('Kitchen Light Level'));
    await tester.pumpAndSettle();
    // The lamp moves up to first.
    await tester.tap(find.byTooltip('Move up').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(picked, ['light.living_room_lamp', 'weather.forecast_home']);
  });

  testWidgets('picks whose order means nothing show no handle or arrows', (
    tester,
  ) async {
    List<String>? picked;
    final spec = PickSpec(
      key: 'kiosks:test',
      loader: () async => const PickList([
        PickItem(id: 'a', name: 'Bedroom'),
        PickItem(id: 'b', name: 'Kitchen'),
        PickItem(id: 'c', name: 'Office'),
      ]),
      searchHint: 'Search kiosks',
      noGroup: '',
      chips: false,
      headings: false,
      ordered: false,
    );
    await _pump(
      tester,
      const Size(1200, 800),
      (context) => TextButton(
        onPressed: () async => picked = await showItemMultiPicker(
          context,
          title: 'Share with',
          spec: spec,
          selected: const ['a', 'b'],
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsWidgets);
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
    expect(find.byTooltip('Move up'), findsNothing);
    expect(find.byTooltip('Move down'), findsNothing);
    expect(
      find.text('Drag or use the arrows to change the order.'),
      findsNothing,
    );
    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(picked, ['a', 'b', 'c']);
  });

  testWidgets('one source of players, offline dimmed and its note shown', (
    tester,
  ) async {
    final commands = _commands(playersFail: true);
    PickOutcome? outcome;
    await _pump(
      tester,
      const Size(1200, 800),
      (context) => TextButton(
        onPressed: () async => outcome = await showItemPicker(
          context,
          title: 'Music Assistant player',
          spec: playerSpec(context, commands, source: 'ma'),
        ),
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('TV'), findsNothing);
    expect(find.textContaining('Music Assistant'), findsWidgets);
    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();
    expect(outcome?.id, 'ma:office');
  });

  testWidgets('the value step offers the state and scalar attributes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = AppContainer();
    await container.settings.init();
    final commands = _commands(into: container.commands);
    String? picked;
    await _pump(
      tester,
      const Size(1200, 800),
      (context) => TextButton(
        onPressed: () async {
          await loadEntityCatalog(commands);
          if (!context.mounted) return;
          picked = await showEntityValuePicker(
            context,
            container,
            entityId: 'sensor.living_room_temperature',
            current: '',
          );
        },
        child: const Text('open'),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('22.4 °C'), findsOneWidget);
    expect(find.text('unit_of_measurement'), findsOneWidget);
    // Presentation metadata and lists stay out.
    expect(find.text('friendly_name'), findsNothing);
    expect(find.text('forecast'), findsNothing);
    await tester.tap(find.text('device_class'));
    await tester.pumpAndSettle();
    expect(picked, 'device_class');
  });
}
