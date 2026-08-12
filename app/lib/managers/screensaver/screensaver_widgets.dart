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
///      text and icon color), and the line toggles location, forecast,
///      humidity, wind, visibility. The temperature always shows; every
///      line needs its toggle on AND the entity to actually carry the
///      reading.
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
const screensaverWidgetTypes = ['clock', 'weather'];

String describeScreensaverWidgetType(String type) => switch (type) {
  'clock' => 'Small clock',
  'weather' => 'Weather',
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
    'location': true,
    'forecast': true,
    'humidity': true,
    'wind': true,
    'visibility': true,
  },
  _ => const {},
};

/// Whether [type] renders over the [mode] screensaver. Widgets stay off
/// the Clock mode (whose face owns the layout) and the camera grid, where
/// an overlay sits in the way of a live feed.
bool screensaverWidgetAllowedOnMode(String type, String mode) =>
    switch (type) {
      'clock' || 'weather' => mode != 'clock' && mode != 'camera',
      _ => true,
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
