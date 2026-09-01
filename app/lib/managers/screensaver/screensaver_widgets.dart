/// The screensaver.widgets model: parsing, labels, defaults, and the
/// per-type mode rules.
///
/// A widget is one small overlay in one corner of the screensaver:
///
/// ```json
/// {
///   "position": "top_right",
///   "type": "clock",
///   "config": {"color": "250,250,250", "h24": false, "date": false}
/// }
/// ```
///
/// - position: top_left | top_right | bottom_left | bottom_right (the
///   corner vocabulary from definitions.dart). One widget per corner; the
///   decoder keeps the first entry claiming a corner and drops the rest.
/// - type: what the widget shows. Types and their config keys:
///    - clock: color ("r,g,b" text color), h24 (24-hour time instead of
///      AM/PM), date (short date under the time)
///    - weather: entity (a weather.* entity id), name (its friendly name,
///      cached for the editors), label (the location text shown over the
///      temperature; the entity name when empty — weather entities carry
///      no city attribute, so the place is named by hand), color ("r,g,b"
///      text and icon color), feels_like (the apparent temperature after
///      the real one, "30°C / 33°C", collapsed to one number when both
///      round the same; off by default), and the line
///      toggles location, forecast, humidity, wind, visibility. The
///      temperature always shows; every line needs its toggle on AND the
///      entity to actually carry the reading.
///    - battery: the device's own battery, as an icon with an optional
///      percentage. Config keys: color ("r,g,b" icon and text color),
///      percent (the number beside the icon), low (only show once the
///      charge is low, for a widget that stays out of the way until it
///      matters).
///    - entity: one Home Assistant entity, the At a Glance row's reading
///      as a corner widget (issue #336): its icon and value on one line,
///      the name under them. Config keys: entity (the entity id), name
///      (its friendly name, cached for the editors), label (a name chosen
///      by hand; the Home Assistant name when empty), attribute (the
///      attribute shown instead of the state; the state when empty),
///      show_name (the name line under the value) and color ("r,g,b" icon
///      and text color).
/// - config: the type's own settings; missing keys read as the type's
///   defaults, so entries survive new keys being added.
///
/// The remote admin UI carries its own copy of the type and corner labels;
/// keep the two word-for-word (see the gestures precedent).
library;

import 'dart:convert';

import '../settings/definitions.dart' show cornerOptions;

class ScreensaverWidget {
  const ScreensaverWidget({
    required this.position,
    required this.type,
    required this.config,
  });

  final String position;
  final String type;
  final Map<String, Object?> config;

  Map<String, Object?> toJson() =>
      {'position': position, 'type': type, 'config': config};
}

/// Every widget type, in the order the pickers offer them.
const screensaverWidgetTypes = ['clock', 'weather', 'battery', 'entity'];

String describeScreensaverWidgetType(String type) => switch (type) {
  'clock' => 'Small clock',
  'weather' => 'Weather',
  'battery' => 'Battery',
  'entity' => 'Entity',
  _ => type,
};

/// A fresh entry's config, also the fallback for keys an entry is missing.
Map<String, Object?> screensaverWidgetDefaults(String type) => switch (type) {
  'clock' => {'color': '250,250,250', 'h24': false, 'date': false},
  'weather' => {
    'entity': '',
    'name': '',
    'label': '',
    'color': '250,250,250',
    'feels_like': false,
    'location': true,
    'forecast': true,
    'humidity': true,
    'wind': true,
    'visibility': true,
  },
  'battery' => {'color': '250,250,250', 'percent': true, 'low': false},
  'entity' => {
    'entity': '',
    'name': '',
    'label': '',
    'attribute': '',
    'show_name': true,
    'color': '250,250,250',
  },
  _ => const {},
};

/// Whether [type] renders over the [mode] screensaver. Everything stays
/// off the camera grid, where an overlay sits in the way of a live feed;
/// the clock widget also stays off the Clock mode, which is one already —
/// the weather widget is exactly what a clock face wants next to it.
bool screensaverWidgetAllowedOnMode(String type, String mode) =>
    switch (type) {
      'clock' => mode != 'clock' && mode != 'camera',
      _ => mode != 'camera',
    };

/// Decode the screensaver.widgets JSON, dropping anything malformed rather
/// than failing the lot: one bad import line should not blank the rest.
List<ScreensaverWidget> decodeScreensaverWidgets(String json) {
  final out = <ScreensaverWidget>[];
  final taken = <String>{};
  try {
    final list = jsonDecode(json);
    if (list is! List) return out;
    for (final entry in list) {
      if (entry is! Map) continue;
      final position = entry['position'];
      final type = entry['type'];
      final config = entry['config'];
      if (position is! String || !cornerOptions.contains(position)) continue;
      if (type is! String || !screensaverWidgetTypes.contains(type)) continue;
      if (!taken.add(position)) continue;
      out.add(
        ScreensaverWidget(
          position: position,
          type: type,
          config: config is Map
              ? config.map((k, v) => MapEntry('$k', v))
              : screensaverWidgetDefaults(type),
        ),
      );
    }
  } catch (_) {
    // Unparseable JSON reads as no widgets.
  }
  return out;
}

/// Encode for storage, in corner order so the stored list (and every list
/// rendered from it) reads top-left to bottom-right.
String encodeScreensaverWidgets(List<ScreensaverWidget> widgets) {
  final sorted = [...widgets]..sort(
    (a, b) => cornerOptions
        .indexOf(a.position)
        .compareTo(cornerOptions.indexOf(b.position)),
  );
  return jsonEncode([for (final w in sorted) w.toJson()]);
}
