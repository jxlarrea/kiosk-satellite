import 'dart:math';

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../managers/glance/glance_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import 'mdi_icon.dart';

/// The screensaver's At a Glance row: a few entity states (issue #37).
///
/// Two styles. The default draws each entity as a chip: a stadium pill in
/// one translucent dark grey, the icon in its own circle leading the name
/// with the value bold under it. Chips sharing a single line hug their
/// text; the moment they wrap, every chip takes the widest one's width,
/// so a stacked grid lines up instead of reading as rags. The pill
/// carries its own contrast, so the row reads over the photo modes as
/// well as the plain ones, and the circle takes the entity's state color
/// unless "Monochromatic icons" keeps it grey. "Floating text style"
/// keeps the original floating text, icon beside name over value in one
/// muted tone.
///
/// The text never colors in either style. The point is a row you can read
/// across a dark room without it competing with the clock, so state may
/// light the icon's circle but never tints the words: an open garage door
/// reads "Open", it does not glow orange.
class GlanceRow extends StatelessWidget {
  const GlanceRow({
    super.key,
    required this.container,
    this.scale = 1,
    this.tint,
    this.narrow = false,
  });

  final AppContainer container;

  /// Shrinks the whole row on small panels, where the clock above it has
  /// already taken what space there is.
  final double scale;

  /// The clock face's digit color, so the row reads as part of the face —
  /// and stays legible when the face's backdrop is bright (a flip clock
  /// with light cards would swallow the default light grey). Null keeps
  /// the standalone grey-on-black palette. Floating-text style only; the
  /// chips bring their own backdrop and palette.
  final Color? tint;

  /// Wraps the row into a narrow centred block even on a landscape panel,
  /// for the modes whose bottom corners are spoken for (the Immich
  /// metadata panels): the chips cap their line width, the text style
  /// caps at portrait's two columns, and either way the row stays clear
  /// of the corners instead of spreading into them.
  final bool narrow;

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

  /// The widest a narrowed chip wrap may run: two chips at their 250 cap
  /// plus the gutter, with a little slack, so the narrowed grid lands on
  /// two columns even when every name runs to the cap. The chips size to
  /// content, so narrowing is a width cap rather than a column count.
  static const _narrowWidth = 520.0;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<GlanceEntity>>(
    valueListenable: container.glance.entities,
    builder: (context, entities, _) {
      if (entities.isEmpty) return const SizedBox.shrink();
      final cards = !container.settings.get(defs.screensaverGlanceTextOnly);
      // The Row scaling slider, on top of the caller's own computed
      // scale, so every placement of the row follows it alike (the
      // Widget scaling precedent). Shadowing the field keeps the whole
      // build reading one corrected scale.
      final scale =
          this.scale *
          (container.settings.get(defs.screensaverGlanceScale).toDouble() /
              100);
      return LayoutBuilder(
        builder: (context, constraints) {
          if (cards) {
            // Narrow caps the line width so the chips break clear of a
            // mode's claimed bottom corners; a portrait screen narrows
            // itself by running out of width.
            final bw = container.settings.get(defs.screensaverGlanceBwIcons);
            final maxWidth = narrow
                ? min(constraints.maxWidth, _narrowWidth * scale)
                : constraints.maxWidth;
            final spacing = 10 * scale;
            // Each chip's natural width, measured up front so the layout
            // can be decided in one pass: chips that share a single line
            // hug their text, the reference look, but the moment they
            // wrap they take one shared width — the widest chip's — so
            // the grid's edges line up instead of reading as rags.
            final widths = [
              for (final entity in entities) _chipWidth(entity, scale),
            ];
            final total =
                widths.fold(0.0, (a, b) => a + b) +
                spacing * (entities.length - 1);
            if (total <= maxWidth) {
              // One line, content-hugging. heightFactor 1: hug the chips'
              // height. An expanding Center filled whatever box the caller
              // gave, so the bottom-pinned overlay's row floated to the
              // middle of the screen.
              return Center(
                heightFactor: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (index, entity) in entities.indexed) ...[
                      if (index > 0) SizedBox(width: spacing),
                      _GlanceCard(entity: entity, scale: scale, bw: bw),
                    ],
                  ],
                ),
              );
            }
            // Wrapped: the uniform grid. As many shared-width chips per
            // line as the width takes, the last line centred short.
            final chip = min(widths.reduce(max), maxWidth);
            final columns = max(
              1,
              min(entities.length, (maxWidth + spacing) ~/ (chip + spacing)),
            );
            final lines = <List<GlanceEntity>>[
              for (var i = 0; i < entities.length; i += columns)
                entities.sublist(i, min(i + columns, entities.length)),
            ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, line) in lines.indexed) ...[
                  if (index > 0) SizedBox(height: spacing),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final (column, entity) in line.indexed) ...[
                        if (column > 0) SizedBox(width: spacing),
                        SizedBox(
                          width: chip,
                          child: _GlanceCard(
                            entity: entity,
                            scale: scale,
                            bw: bw,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          }
          // Two across at most on a portrait panel, wrapping onto
          // further rows; a landscape one takes them all in a single
          // row. Three squeezed across a portrait screen left every
          // name truncated to a stub. A narrowed landscape row wraps
          // the same way portrait does.
          final size = MediaQuery.sizeOf(context);
          final perRow = narrow || size.height > size.width
              ? min(_portraitColumns, entities.length)
              : entities.length;
          final rows = <List<GlanceEntity>>[
            for (var i = 0; i < entities.length; i += perRow)
              entities.sublist(i, min(i + perRow, entities.length)),
          ];
          // Widths here are LOGICAL pixels: a 540px portrait panel at
          // this density is only 443 of them. The slot is shared by
          // every row so the columns line up down the grid.
          final slot = min(_slotWidth * scale, constraints.maxWidth / perRow);
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

/// The width a chip wants: its widest text line plus the fixed chrome
/// (padding, icon circle, gap, the hairline border Container folds into
/// its padding), capped exactly like the chip itself. Measured with a
/// TextPainter so GlanceRow can pick between the content-hugging line and
/// the uniform grid without laying anything out twice; keep the sizes here
/// in lockstep with _GlanceCard's.
double _chipWidth(GlanceEntity entity, double scale) {
  double line(String text, double size, FontWeight weight) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          fontFamily: 'Rubik',
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  final text = max(
    line(entity.displayName, 13 * scale, FontWeight.w400),
    line(glanceStateText(entity), 17 * scale, FontWeight.w600),
  );
  // 6 + 40 + 10 + 18: left pad, circle, gap, right pad; +2 for the border.
  return min(text + 74 * scale + 2, 250 * scale);
}

/// The accent behind an entity's icon in the chip style: the pastel of its
/// active state, null for the neutral circle. Approximates the way Home
/// Assistant lights up an active tile, so color means "something is going
/// on" and never decoration: a lit light glows amber, an unlocked lock
/// warns red, and everything idle (and every plain sensor) stays grey.
Color? glanceIconAccent(GlanceEntity entity) {
  // Material 300-level pastels: solid circles in the reference style,
  // light enough that the dark icon glyph stays readable on all of them.
  const amber = Color(0xFFFFD54F);
  const red = Color(0xFFE57373);
  const green = Color(0xFF81C784);
  const blue = Color(0xFF64B5F6);
  const purple = Color(0xFFB39DDB);
  const orange = Color(0xFFFF8A65);
  const indigo = Color(0xFF9FA8DA);
  const cyan = Color(0xFF4DD0E1);
  final domain = entity.entityId.split('.').first;
  final state = entity.state;
  final on = state == 'on';
  return switch (domain) {
    'light' || 'switch' || 'input_boolean' => on ? amber : null,
    'fan' => on ? cyan : null,
    'lock' => switch (state) {
      'unlocked' => red,
      'locked' => green,
      _ => null,
    },
    'cover' => switch (state) {
      'open' || 'opening' || 'closing' => purple,
      _ => null,
    },
    'binary_sensor' =>
      !on
          ? null
          : switch (entity.deviceClass) {
              'moisture' ||
              'smoke' ||
              'gas' ||
              'carbon_monoxide' ||
              'problem' ||
              'safety' ||
              'tamper' ||
              'battery' => red,
              _ => amber,
            },
    'climate' => switch (state) {
      'heat' => orange,
      'cool' => blue,
      'heat_cool' || 'auto' => green,
      'dry' => amber,
      'fan_only' => cyan,
      _ => null,
    },
    'media_player' => state == 'playing' ? indigo : null,
    'person' || 'device_tracker' => state == 'home' ? green : null,
    'alarm_control_panel' => switch (state) {
      'triggered' => red,
      'arming' || 'pending' => amber,
      'armed_away' ||
      'armed_home' ||
      'armed_night' ||
      'armed_vacation' ||
      'armed_custom_bypass' => green,
      _ => null,
    },
    'vacuum' => state == 'cleaning' || state == 'returning' ? blue : null,
    'sun' => state == 'above_horizon' ? amber : null,
    _ => null,
  };
}

/// One entity as a chip: a stadium pill in one translucent dark grey,
/// sized to its content, the icon in its own circle leading the name with
/// the value bold under it. The circle takes the entity's state color
/// ([glanceIconAccent]) unless Monochromatic icons keeps it in the
/// neutral grey; the text never colors either way, and the clock tint
/// never reaches the chip, because the pill, not the backdrop, is what
/// the text has to stay legible against.
class _GlanceCard extends StatelessWidget {
  const _GlanceCard({
    required this.entity,
    required this.scale,
    required this.bw,
  });

  final GlanceEntity entity;
  final double scale;

  /// Monochromatic icons: keep the circle in the neutral grey even for an
  /// active entity.
  final bool bw;

  /// Dark enough to hold white text over a bright photo, translucent
  /// enough that the photo still shows the chip is sitting on it.
  static const _background = Color(0xB31C1C1E);

  /// The circle behind an idle entity's icon, a step lighter than the
  /// pill so the circle reads even without an accent.
  static const _circleNeutral = Color(0x24FFFFFF);

  /// The icon glyph on a colored circle: dark on the pastel, the way the
  /// reference chips draw a black bulb on the amber circle.
  static const _iconOnAccent = Color(0xDE212121);

  /// The hairline around the pill, a touch of white so the chip's edge
  /// reads even where the photo behind it is as dark as the pill.
  static const _border = Color(0x30FFFFFF);

  @override
  Widget build(BuildContext context) {
    // Full white for name and value both: the pill provides the
    // contrast, so the hierarchy lives in size and weight alone.
    const label = Colors.white;
    const value = Colors.white;
    final accent = bw ? null : glanceIconAccent(entity);
    return Container(
      // Capped so one long name cannot stretch its pill across the
      // screen; the name inside truncates instead.
      constraints: BoxConstraints(maxWidth: 250 * scale),
      padding: EdgeInsets.fromLTRB(6 * scale, 6 * scale, 18 * scale, 6 * scale),
      // A StadiumBorder, not a BoxDecoration with a large corner radius:
      // the stadium's radius is always half the pill's own height. A
      // radius bigger than the box (40 * scale on a ~52px pill) is an
      // over-sized RRect the engine must renormalize, and re-rasterizing
      // that shape at a new size froze Impeller's raster thread on the
      // Tab S8 — the whole app kept running behind a stuck last frame.
      decoration: const ShapeDecoration(
        color: _background,
        shape: StadiumBorder(side: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40 * scale,
            height: 40 * scale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent ?? _circleNeutral,
              shape: BoxShape.circle,
            ),
            // Full white on the neutral circle; the dark glyph only on a
            // pastel, where white would wash out.
            child: GlanceIcon(
              entity: entity,
              size: 22 * scale,
              color: accent != null ? _iconOnAccent : Colors.white,
            ),
          ),
          SizedBox(width: 10 * scale),
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
                    fontSize: 13 * scale,
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
                    fontSize: 17 * scale,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
    .map(
      (word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
    )
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
