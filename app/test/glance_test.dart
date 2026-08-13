import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/glance/glance_manager.dart';
import 'package:kiosk_satellite/ui/glance_row.dart';
import 'package:flutter/material.dart';

void main() {
  GlanceEntity entity(
    String id, {
    String? state,
    String? icon,
    String? deviceClass,
    String? unit,
    int? precision,
  }) =>
      GlanceEntity(
        entityId: id,
        name: 'Test',
        state: state,
        icon: icon,
        deviceClass: deviceClass,
        unit: unit,
        precision: precision,
      );

  group('state text', () {
    test('reads as a person would say it, not as a slug', () {
      expect(glanceStateText(entity('cover.g', state: 'open')), 'Open');
      expect(glanceStateText(entity('lock.f', state: 'locked')), 'Locked');
      expect(
        glanceStateText(entity('alarm_control_panel.a', state: 'armed_away')),
        'Armed Away',
      );
    });

    test('a measurement carries its unit', () {
      expect(
        glanceStateText(entity('sensor.t', state: '21.5', unit: '°C')),
        '21.5 °C',
      );
    });

    test('display precision rounds the way the entity card would (#74)', () {
      expect(
        glanceStateText(
          entity('sensor.t', state: '69.44', unit: '°F', precision: 0),
        ),
        '69 °F',
      );
      expect(
        glanceStateText(
          entity('sensor.t', state: '69.44', unit: '°F', precision: 1),
        ),
        '69.4 °F',
      );
      // Padded, not just truncated: Home Assistant shows 69.0 at
      // precision 1, so the row does too.
      expect(
        glanceStateText(entity('sensor.t', state: '69', precision: 1)),
        '69.0',
      );
    });

    test('a fetched precision survives later state updates', () {
      final before = entity('sensor.t', state: '69.44', unit: '°F', precision: 0);
      final after = before.merge(state: '70.12');
      expect(glanceStateText(after), '70 °F');
    });

    test('precision leaves everything non-numeric alone', () {
      // No precision known: the raw state, exactly as before.
      expect(
        glanceStateText(entity('sensor.t', state: '69.44', unit: '°F')),
        '69.44 °F',
      );
      // A precision on a non-numeric state changes nothing.
      expect(
        glanceStateText(entity('cover.g', state: 'open', precision: 1)),
        'Open',
      );
      expect(
        glanceStateText(entity('sensor.t', state: 'unavailable', precision: 0)),
        'Unavailable',
      );
    });

    test('the states nobody wants to read raw are spelled out', () {
      expect(glanceStateText(entity('x.y', state: 'unavailable')), 'Unavailable');
      expect(glanceStateText(entity('x.y', state: 'unknown')), 'Unknown');
      // Nothing has reported yet: a placeholder, not an empty row.
      expect(glanceStateText(entity('x.y')), '…');
    });
  });

  group('attribute display (#132)', () {
    GlanceEntity weather({String? value, String? state}) => GlanceEntity(
          entityId: 'weather.home',
          name: 'Weather',
          attribute: 'temperature',
          attributeValue: value,
          state: state ?? 'sunny',
        );

    test('shows the attribute value instead of the state', () {
      expect(glanceStateText(weather(value: '92')), '92');
    });

    test('slug-like attribute values prettify like states', () {
      expect(glanceStateText(weather(value: 'partly_cloudy')),
          'Partly Cloudy');
    });

    test('waits with a placeholder until the value arrives', () {
      expect(glanceStateText(weather()), '…');
    });

    test('an unavailable entity reads unavailable, not a stale value', () {
      expect(glanceStateText(weather(value: '92', state: 'unavailable')),
          'Unavailable');
    });

    test('state unit and precision never leak onto an attribute', () {
      final e = GlanceEntity(
        entityId: 'weather.home',
        name: 'Weather',
        attribute: 'humidity',
        attributeValue: '47.25',
        state: '21.5',
        unit: '°C',
        precision: 0,
      );
      expect(glanceStateText(e), '47.25');
    });

    test('attribute values flatten to display text', () {
      expect(glanceAttributeText(92.0), '92');
      expect(glanceAttributeText(92.06), '92.06');
      expect(glanceAttributeText(15), '15');
      expect(glanceAttributeText('sunny'), 'sunny');
      expect(glanceAttributeText(null), '');
    });

    test('the chosen attribute survives a storage round trip', () {
      final stored = weather().toJson();
      expect(stored['attribute'], 'temperature');
      final loaded = GlanceEntity.fromJson(stored);
      expect(loaded.attribute, 'temperature');
      // No attribute chosen: the key stays out of storage entirely.
      final plain =
          const GlanceEntity(entityId: 'x.y', name: 'X').toJson();
      expect(plain.containsKey('attribute'), isFalse);
      expect(GlanceEntity.fromJson(plain).attribute, isNull);
    });

    test('merge keeps the value across unrelated updates', () {
      final before = weather(value: '92');
      final after = before.merge(state: 'cloudy');
      expect(after.attributeValue, '92');
      expect(after.attribute, 'temperature');
    });
  });

  group('custom names (#206)', () {
    test('a custom name wins over the Home Assistant name', () {
      const renamed = GlanceEntity(
        entityId: 'cover.g',
        name: 'Garage Door Left Side',
        customName: 'Garage',
      );
      expect(renamed.displayName, 'Garage');
      expect(
        const GlanceEntity(entityId: 'cover.g', name: 'Garage Door')
            .displayName,
        'Garage Door',
      );
    });

    test('a friendly_name update does not overwrite a custom name', () {
      const renamed = GlanceEntity(
        entityId: 'cover.g',
        name: 'Garage Door',
        customName: 'Garage',
      );
      final after = renamed.merge(name: 'Garage Door Left Side', state: 'open');
      expect(after.displayName, 'Garage');
      // The live name is still tracked, so clearing the custom name later
      // falls back to the current one, not the one saved at pick time.
      expect(after.name, 'Garage Door Left Side');
    });

    test('the custom name survives a storage round trip', () {
      const renamed = GlanceEntity(
        entityId: 'cover.g',
        name: 'Garage Door',
        customName: 'Garage',
      );
      final loaded = GlanceEntity.fromJson(renamed.toJson());
      expect(loaded.customName, 'Garage');
      expect(loaded.displayName, 'Garage');
      // No custom name: the key stays out of storage entirely.
      final plain = const GlanceEntity(entityId: 'x.y', name: 'X').toJson();
      expect(plain.containsKey('custom_name'), isFalse);
      expect(GlanceEntity.fromJson(plain).customName, isNull);
    });
  });

  group('icons', () {
    test("an icon set in Home Assistant wins", () {
      expect(
        glanceIcon(entity('light.x', icon: 'mdi:garage-open', state: 'on')),
        Icons.garage,
      );
    });

    test('an unknown mdi name falls back instead of showing nothing', () {
      expect(
        glanceIcon(entity('lock.x', icon: 'mdi:not-a-real-icon', state: 'locked')),
        Icons.lock,
      );
    });

    test('state picks the icon apart, so open and shut differ', () {
      expect(
        glanceIcon(entity('cover.x', deviceClass: 'garage', state: 'open')),
        Icons.garage,
      );
      expect(
        glanceIcon(entity('cover.x', deviceClass: 'garage', state: 'closed')),
        Icons.garage,
      );
      expect(glanceIcon(entity('lock.x', state: 'unlocked')),
          Icons.lock_open);
      expect(glanceIcon(entity('lock.x', state: 'locked')), Icons.lock);
    });

    test('an unmapped domain still gets something', () {
      expect(glanceIcon(entity('counter.x', state: '3')), Icons.sensors);
    });
  });
}
