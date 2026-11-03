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
///      AM/PM), ampm (AM or PM after a 12-hour time; on when missing),
///      date (short date under the time)
///    - weather: entity (a weather.* entity id), name (its friendly name,
///      cached for the editors), label (the location text shown over the
///      temperature; the entity name when empty — weather entities carry
///      no city attribute, so the place is named by hand), color ("r,g,b"
///      text and icon color), feels_like (the apparent temperature after
///      the real one, "30°C / 33°C", collapsed to one number when both
///      round the same; off by default), feels_like_only (the apparent
///      temperature in the real one's place; off by default, wins over
///      feels_like), and the line
///      toggles location, forecast, high_low (today's high and low from
///      the daily forecast, issue #1262), humidity, wind, visibility. The
///      temperature always shows, with the condition icon to its left;
///      every line needs its toggle on AND the entity to actually carry
///      the reading. colored_icons draws that icon in its own colors
///      instead of the widget color (on by default).
///    - forecast: the coming days of a weather entity's daily forecast,
///      one row each with the day, the condition icon, the high and the
///      low (issue #1277). Config keys: entity (a weather.* entity id),
///      name (its friendly name, cached for the editors), color ("r,g,b"
///      text and icon color), days (how many rows, one of
///      [forecastDayOptions]) and today (whether the list starts with
///      today; tomorrow otherwise, for a corner beside a Weather widget
///      that already shows today) and colored_icons (the condition icons
///      in their own colors instead of the widget color).
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
///      show_states (a comma separated list of values; when set, the
///      widget only shows while its value matches one, issue #1066),
///      show_name (the name line under the value), show_icon (the icon
///      beside the value, issue #912) and color ("r,g,b" icon and text
///      color). A blank value hides the whole widget, vignette
///      included (issue #691).
/// - config: the type's own settings; missing keys read as the type's
///   defaults, so entries survive new keys being added. Every type also
///   carries scale, this widget's own size correction in percent from
///   -50 to 50 (0 by default), applied on top of the Global widget
///   scaling slider: see [screensaverWidgetScaleFactor]. Every type also
///   carries font and font_weight, the clock screensaver's font family
///   and weight vocabulary plus "default", which follows the Global font
///   family and Global font weight settings: see
///   [screensaverWidgetFontValue] and [screensaverWidgetFontWeightValue].
///
/// The remote admin UI carries its own copy of the type and corner labels;
/// keep the two word-for-word (see the gestures precedent).
library;

import 'dart:convert';

import '../settings/definitions.dart'
    show cornerOptions, fontFamilyOptions, fontWeightOptions;

class ScreensaverWidget {
  const ScreensaverWidget({
    required this.position,
    required this.type,
    required this.config,
  });

  final String position;
  final String type;
  final Map<String, Object?> config;

  Map<String, Object?> toJson() => {
    'position': position,
    'type': type,
    'config': config,
  };
}

/// Every widget type, in the order the pickers offer them.
const screensaverWidgetTypes = [
  'clock',
  'weather',
  'forecast',
  'battery',
  'entity',
  'alarm',
  'calendar',
];

String describeScreensaverWidgetType(String type) => switch (type) {
  'clock' => 'Small clock',
  'weather' => 'Weather',
  'forecast' => 'Weather forecast',
  'battery' => 'Battery',
  'entity' => 'Entity',
  'alarm' => 'Next alarm',
  'calendar' => 'Up next',
  _ => type,
};

/// A fresh entry's config, also the fallback for keys an entry is missing.
Map<String, Object?> screensaverWidgetDefaults(String type) => switch (type) {
  'clock' => {
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
    'h24': false,
    'ampm': true,
    'date': false,
  },
  'weather' => {
    'entity': '',
    'name': '',
    'label': '',
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
    'feels_like': false,
    'feels_like_only': false,
    'location': true,
    'forecast': true,
    'high_low': true,
    'humidity': true,
    'wind': true,
    'visibility': true,
    'colored_icons': true,
  },
  'forecast' => {
    'entity': '',
    'name': '',
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
    'days': 5,
    'today': true,
    'colored_icons': true,
  },
  'battery' => {
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
    'percent': true,
    'low': false,
  },
  'alarm' => {
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
  },
  // The family calendar's next events, up to [count], over [days] days
  // starting today, each marked with its calendars' pictures, or with a
  // dot in their colors when [dots] is on (issue #1285).
  'calendar' => {
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
    'count': 3,
    'days': 1,
    'dots': false,
  },
  'entity' => {
    'entity': '',
    'name': '',
    'label': '',
    'attribute': '',
    'show_states': '',
    'show_name': true,
    'show_icon': true,
    'color': '250,250,250',
    'scale': screensaverWidgetScaleDefault,
    'font': screensaverWidgetFontDefault,
    'font_weight': screensaverWidgetFontDefault,
  },
  _ => const {},
};

/// How many days the Up next widget looks ahead: today, today and tomorrow
/// or the next 7 days.
const upNextDayOptions = [1, 2, 7];

/// How many days the Weather forecast widget lists.
const forecastDayOptions = [3, 5, 7];

/// A widget's own font family or weight left at Default: the widget
/// follows the Global font family or Global font weight setting.
const screensaverWidgetFontDefault = 'default';

/// What the per-widget Font family picker offers: Default, then the
/// clock screensaver's families.
const screensaverWidgetFontOptions = [
  screensaverWidgetFontDefault,
  ...fontFamilyOptions,
];

/// What the per-widget Font weight picker offers: the clock screensaver's
/// list, whose own first entry is already Default.
const screensaverWidgetFontWeightOptions = fontWeightOptions;

/// The font family value a widget draws in: its own when it names one of
/// the families, else [global], the Global font family setting. An
/// unknown value falls to the global too, so a backup from another build
/// cannot hand a widget a family nobody mapped.
String screensaverWidgetFontValue(Map<String, Object?> config, String global) {
  final own = '${config['font'] ?? ''}';
  return fontFamilyOptions.contains(own) ? own : global;
}

/// The font weight value a widget draws in: its own when it names a
/// weight, else [global], the Global font weight setting. Default on both
/// leaves each line its own weight.
String screensaverWidgetFontWeightValue(
  Map<String, Object?> config,
  String global,
) {
  final own = '${config['font_weight'] ?? ''}';
  return fontWeightOptions.contains(own) && own != screensaverWidgetFontDefault
      ? own
      : global;
}

/// The per-widget scale slider's range, in percent: a widget can shrink to
/// half its size or grow half again, and the Global widget scaling slider
/// then scales all of them together from there.
const screensaverWidgetScaleMin = -50;
const screensaverWidgetScaleMax = 50;
const screensaverWidgetScaleDefault = 0;

/// The widget's own scale as a factor: 1.0 for the default, 0.5 at -50
/// and 1.5 at 50. A missing or unreadable value is the default, and one
/// outside the slider's range is clamped to it, so a hand-edited backup
/// cannot blow a widget up past the screen.
double screensaverWidgetScaleFactor(Map<String, Object?> config) {
  final raw = config['scale'];
  final percent = switch (raw) {
    num n => n,
    String s => num.tryParse(s) ?? screensaverWidgetScaleDefault,
    _ => screensaverWidgetScaleDefault,
  };
  final clamped = percent
      .clamp(screensaverWidgetScaleMin, screensaverWidgetScaleMax)
      .toDouble();
  return 1 + clamped / 100;
}

/// Whether [type] renders over the [mode] screensaver. Everything stays
/// off the calendar, whose top bar and views fill the screen, and off the
/// camera grid, where an overlay sits in the way of a live feed;
/// the clock widget also stays off the Clock mode, which is one already —
/// the weather widget is exactly what a clock face wants next to it.
bool screensaverWidgetAllowedOnMode(String type, String mode) => switch (type) {
  _ when mode == 'calendar' => false,
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
  final sorted = [...widgets]
    ..sort(
      (a, b) => cornerOptions
          .indexOf(a.position)
          .compareTo(cornerOptions.indexOf(b.position)),
    );
  return jsonEncode([for (final w in sorted) w.toJson()]);
}
