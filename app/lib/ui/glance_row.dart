import 'dart:math';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/glance/glance_manager.dart';

/// The screensaver's At a Glance row: a few entity states, icon over name
/// over value, in one muted tone (issue #37).
///
/// Deliberately colourless. The point is a row you can read across a dark
/// room without it competing with the clock, so state never tints the text —
/// an open garage door reads "Open", it does not glow orange.
class GlanceRow extends StatelessWidget {
  const GlanceRow({
    super.key,
    required this.container,
    this.scale = 1,
    this.tint,
  });

  final AppContainer container;

  /// Shrinks the whole row on small panels, where the clock above it has
  /// already taken what space there is.
  final double scale;

  /// The clock face's digit colour, so the row reads as part of the face —
  /// and stays legible when the face's backdrop is bright (a flip clock
  /// with light cards would swallow the default light grey). Null keeps
  /// the standalone grey-on-black palette.
  final Color? tint;

  /// The width one entity gets. Every entity gets the same, so the row's
  /// geometry depends on how many there are and never on how long their
  /// names happen to be.
  static const _slotWidth = 210.0;

  /// The most entities placed side by side on a portrait panel. Past two
  /// there is no width left for a name.
  static const _portraitColumns = 2;

  /// The most the type is allowed to shrink when the slots are squeezed.
  /// Below this it stops being readable from across a room, which is the
  /// only reason the row exists.
  static const _minFit = 0.72;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<GlanceEntity>>(
        valueListenable: container.glance.entities,
        builder: (context, entities, _) {
          if (entities.isEmpty) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              // Two across at most on a portrait panel, wrapping onto
              // further rows; a landscape one takes them all in a single
              // row. Three squeezed across a portrait screen left every
              // name truncated to a stub.
              final size = MediaQuery.sizeOf(context);
              final perRow = size.height > size.width
                  ? min(_portraitColumns, entities.length)
                  : entities.length;
              final rows = <List<GlanceEntity>>[
                for (var i = 0; i < entities.length; i += perRow)
                  entities.sublist(i, min(i + perRow, entities.length)),
              ];
              // Widths here are LOGICAL pixels: a 540px portrait panel at
              // this density is only 443 of them. The slot is shared by
              // every row so the columns line up down the grid.
              final slot = min(
                _slotWidth * scale,
                constraints.maxWidth / perRow,
              );
              // How much the slot had to give up, floored so the type never
              // shrinks past reading distance; past that point the names
              // truncate rather than the row becoming unreadable.
              final fit = (slot / (_slotWidth * scale)).clamp(_minFit, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, row) in rows.indexed) ...[
                    if (index > 0) SizedBox(height: 16 * scale * fit),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      // Explicit, because this row is handed a full-width
                      // box when pinned to the bottom of the clock
                      // screensaver: left to the default it would lay the
                      // slots out from the left edge and the centre entity
                      // would no longer meet the clock. A short final row
                      // centres under the ones above it.
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Equal-width slots, each entity centred in its own.
                        // Sizing them to their content instead let a long
                        // name drag the row sideways, so its centre stopped
                        // agreeing with the clock's above it.
                        for (final entity in row)
                          SizedBox(
                            width: slot,
                            child: Center(
                              child: _GlanceItem(
                                entity: entity,
                                scale: scale * fit,
                                tint: tint,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          );
        },
      );
}

class _GlanceItem extends StatelessWidget {
  const _GlanceItem({required this.entity, required this.scale, this.tint});

  final GlanceEntity entity;
  final double scale;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    // The date's tone for the name, a brighter one for the value: the value
    // is the thing being checked, the label only says what it belongs to.
    // A tinted row keeps the same two-tone reading in the face's colour.
    final label = tint?.withValues(alpha: 0.65) ?? const Color(0xFF9E9E9E);
    final value = tint ?? const Color(0xFFE8E8E8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          glanceIcon(entity),
          size: 34 * scale,
          color: label,
        ),
        SizedBox(width: 12 * scale),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entity.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label,
                  fontSize: 15 * scale,
                  height: 1.15,
                  fontFamily: 'Rubik',
                ),
              ),
              Text(
                glanceStateText(entity),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value,
                  fontSize: 19 * scale,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The state as a person reads it: Home Assistant's raw values are lowercase
/// slugs, and a numeric sensor means nothing without its unit.
String glanceStateText(GlanceEntity entity) {
  final state = entity.state;
  if (state == null || state.isEmpty) return '…';
  if (state == 'unavailable') return 'Unavailable';
  if (state == 'unknown') return 'Unknown';
  final pretty = state
      .split('_')
      .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
      .join(' ');
  final unit = entity.unit;
  return unit == null || unit.isEmpty ? pretty : '$pretty $unit';
}


/// The entity's icon.
///
/// Home Assistant computes icons in its frontend, so a state carries one only
/// when somebody set it by hand. Those are Material Design Icon names, and
/// this maps the ones people actually pin to a status row onto their Material
/// equivalents; everything else falls through to a per-domain default that
/// mirrors what Home Assistant itself would draw. A row of identical dots
/// would defeat the point of glancing at it.
///
/// Deliberately not the Material Design Icons package: its IconData subclass
/// does not compile against this Flutter version.
IconData glanceIcon(GlanceEntity entity) {
  final explicit = entity.icon;
  if (explicit != null && explicit.startsWith('mdi:')) {
    final mapped = _mdiAliases[explicit.substring(4)];
    if (mapped != null) return mapped;
  }
  final domain = entity.entityId.split('.').first;
  final deviceClass = entity.deviceClass;
  final state = entity.state;
  final open = state == 'on' || state == 'open' || state == 'unlocked';
  return switch (domain) {
    'lock' => state == 'unlocked' ? Icons.lock_open : Icons.lock,
    'cover' => switch (deviceClass) {
      'garage' => Icons.garage,
      'gate' => Icons.fence,
      'door' => Icons.sensor_door,
      'window' => Icons.sensor_window,
      _ => Icons.blinds,
    },
    'binary_sensor' => switch (deviceClass) {
      'garage_door' => Icons.garage,
      'door' => Icons.sensor_door,
      'window' => Icons.sensor_window,
      'motion' => open ? Icons.directions_run : Icons.sensors_off,
      'moisture' => Icons.water_drop,
      'smoke' => Icons.local_fire_department,
      'lock' => open ? Icons.lock_open : Icons.lock,
      'presence' || 'occupancy' => open ? Icons.person : Icons.person_outline,
      'battery' => Icons.battery_alert,
      _ => open ? Icons.check_circle : Icons.circle_outlined,
    },
    'light' => open ? Icons.lightbulb : Icons.lightbulb_outline,
    'switch' => open ? Icons.toggle_on : Icons.toggle_off,
    'fan' => Icons.mode_fan_off,
    'climate' => Icons.thermostat,
    'water_heater' => Icons.water_damage,
    'alarm_control_panel' =>
      state == 'disarmed' ? Icons.shield_outlined : Icons.shield,
    'person' || 'device_tracker' =>
      state == 'home' ? Icons.home : Icons.directions_walk,
    'vacuum' => Icons.cleaning_services,
    'media_player' => Icons.speaker,
    'camera' => Icons.videocam,
    'sun' => state == 'above_horizon' ? Icons.wb_sunny : Icons.nights_stay,
    'weather' => Icons.cloud,
    'automation' || 'script' => Icons.play_circle_outline,
    'input_boolean' => open ? Icons.toggle_on : Icons.toggle_off,
    'sensor' => switch (deviceClass) {
      'temperature' => Icons.thermostat,
      'humidity' => Icons.water_drop,
      'battery' => Icons.battery_full,
      'power' || 'energy' => Icons.bolt,
      'illuminance' => Icons.light_mode,
      'pressure' => Icons.speed,
      'carbon_dioxide' || 'carbon_monoxide' => Icons.cloud_queue,
      'timestamp' => Icons.schedule,
      _ => Icons.sensors,
    },
    _ => Icons.sensors,
  };
}

/// Material Design Icon names commonly set on the kinds of entity that end up
/// on a status row, mapped to their closest Material equivalent. A name that
/// is not here falls through to the domain default, which is nearly always
/// the same icon anyway.
const _mdiAliases = <String, IconData>{
  'garage': Icons.garage,
  'garage-open': Icons.garage,
  'garage-variant': Icons.garage,
  'garage-open-variant': Icons.garage,
  'door': Icons.sensor_door,
  'door-open': Icons.sensor_door,
  'door-closed': Icons.sensor_door,
  'door-closed-lock': Icons.lock,
  'gate': Icons.fence,
  'gate-open': Icons.fence,
  'fence': Icons.fence,
  'lock': Icons.lock,
  'lock-open': Icons.lock_open,
  'lock-open-variant': Icons.lock_open,
  'lock-outline': Icons.lock_outline,
  'window-closed': Icons.sensor_window,
  'window-open': Icons.sensor_window,
  'window-closed-variant': Icons.sensor_window,
  'window-open-variant': Icons.sensor_window,
  'window-shutter': Icons.blinds,
  'window-shutter-open': Icons.blinds,
  'blinds': Icons.blinds,
  'blinds-open': Icons.blinds,
  'motion-sensor': Icons.directions_run,
  'motion-sensor-off': Icons.sensors_off,
  'run': Icons.directions_run,
  'walk': Icons.directions_walk,
  'lightbulb': Icons.lightbulb,
  'lightbulb-on': Icons.lightbulb,
  'lightbulb-outline': Icons.lightbulb_outline,
  'ceiling-light': Icons.light,
  'lamp': Icons.light,
  'power-plug': Icons.power,
  'power-plug-off': Icons.power_off,
  'toggle-switch': Icons.toggle_on,
  'toggle-switch-off': Icons.toggle_off,
  'fan': Icons.mode_fan_off,
  'air-conditioner': Icons.ac_unit,
  'thermometer': Icons.thermostat,
  'thermostat': Icons.thermostat,
  'water': Icons.water_drop,
  'water-percent': Icons.water_drop,
  'water-off': Icons.water_damage,
  'flash': Icons.bolt,
  'lightning-bolt': Icons.bolt,
  'battery': Icons.battery_full,
  'battery-alert': Icons.battery_alert,
  'shield': Icons.shield,
  'shield-home': Icons.shield,
  'shield-lock': Icons.shield,
  'shield-off': Icons.shield_outlined,
  'home': Icons.home,
  'home-outline': Icons.home_outlined,
  'account': Icons.person,
  'account-outline': Icons.person_outline,
  'cctv': Icons.videocam,
  'cctv-off': Icons.videocam_off,
  'speaker': Icons.speaker,
  'robot-vacuum': Icons.cleaning_services,
  'weather-sunny': Icons.wb_sunny,
  'weather-night': Icons.nights_stay,
  'weather-partly-cloudy': Icons.cloud,
  'weather-cloudy': Icons.cloud,
  'weather-rainy': Icons.water_drop,
  'washing-machine': Icons.local_laundry_service,
  'fridge': Icons.kitchen,
  'car': Icons.directions_car,
  'wifi': Icons.wifi,
  'wifi-off': Icons.wifi_off,
  'gauge': Icons.speed,
  'clock-outline': Icons.schedule,
  'calendar': Icons.calendar_today,
  'bell': Icons.notifications,
  'bell-off': Icons.notifications_off,
  'eye': Icons.visibility,
  'eye-off': Icons.visibility_off,
  'check-circle': Icons.check_circle,
  'alert': Icons.warning_amber,
  'smoke-detector': Icons.sensors,
  'fire': Icons.local_fire_department,
};
