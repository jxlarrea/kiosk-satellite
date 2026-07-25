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
  }) =>
      GlanceEntity(
        entityId: id,
        name: 'Test',
        state: state,
        icon: icon,
        deviceClass: deviceClass,
        unit: unit,
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

    test('the states nobody wants to read raw are spelled out', () {
      expect(glanceStateText(entity('x.y', state: 'unavailable')), 'Unavailable');
      expect(glanceStateText(entity('x.y', state: 'unknown')), 'Unknown');
      // Nothing has reported yet: a placeholder, not an empty row.
      expect(glanceStateText(entity('x.y')), '…');
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
