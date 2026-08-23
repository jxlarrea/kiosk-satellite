import 'dart:math';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/glance/glance_manager.dart';
import 'mdi_icon.dart';

/// The screensaver's At a Glance row: a few entity states, icon over name
/// over value, in one muted tone (issue #37).
///
/// Deliberately colorless. The point is a row you can read across a dark
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

  /// The clock face's digit color, so the row reads as part of the face —
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
    // A tinted row keeps the same two-tone reading in the face's color.
    final label = tint?.withValues(alpha: 0.65) ?? const Color(0xFF9E9E9E);
    final value = tint ?? const Color(0xFFE8E8E8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlanceIcon(entity: entity, size: 34 * scale, color: label),
        SizedBox(width: 12 * scale),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entity.displayName,
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
  // An entity configured to show an attribute (issue #132) shows that
  // instead of the state. Slug-like values get the same prettifying the
  // state would; units and precision do not apply, they are state-only.
  final attribute = entity.attribute;
  if (attribute != null) {
    final value = entity.attributeValue;
    if (value == null || value.isEmpty) return '…';
    if (double.tryParse(value) != null) return value;
    return _pretty(value);
  }
  if (state == 'unknown') return 'Unknown';
  final unit = entity.unit;
  // A numeric state rounds to the entity's Display precision, padded the
  // same way Home Assistant's own cards pad it, so the row and the
  // dashboard never disagree about the same sensor (issue #74). States
  // arrive raw over the socket; the registry is where the setting lives.
  final precision = entity.precision;
  if (precision != null) {
    final number = double.tryParse(state);
    if (number != null) {
      final rounded = number.toStringAsFixed(precision);
      return unit == null || unit.isEmpty ? rounded : '$rounded $unit';
    }
  }
  final pretty = _pretty(state);
  return unit == null || unit.isEmpty ? pretty : '$pretty $unit';
}

String _pretty(String value) => value
    .split('_')
    .map((word) =>
        word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// The icon an entity draws with: the one it carries, when someone set one
/// in Home Assistant, and the domain default otherwise.
///
/// An icon set by hand is a Material Design Icon name, which the app now
/// draws for real from the bundled set (see ui/mdi_icon.dart). The default
/// stays a Material one: Home Assistant computes those in its frontend and
/// never sends them, so it is this app's own guess at what the entity is,
/// and it has to be on screen in the first frame, before any icon file has
/// been read.
class GlanceIcon extends StatelessWidget {
  const GlanceIcon({
    super.key,
    required this.entity,
    required this.size,
    required this.color,
  });

  final GlanceEntity entity;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final own = entity.icon;
    final fallback = glanceIcon(entity);
    if (own == null || !MdiIcons.looksLikeIcon(own)) {
      return Icon(fallback, size: size, color: color);
    }
    return MdiIcon(name: own, size: size, color: color, fallback: fallback);
  }
}

/// The domain default: what this app draws when Home Assistant sends no
/// icon of its own, which is most of the time. A row of identical dots
/// would defeat the point of glancing at it.
IconData glanceIcon(GlanceEntity entity) {
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
    'person' ||
    'device_tracker' => state == 'home' ? Icons.home : Icons.directions_walk,
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
