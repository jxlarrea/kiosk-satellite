import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/messages.dart';

/// Shared temperature selection for the weather widget and Weather Mood bar.
class WeatherTemperatureReading {
  const WeatherTemperatureReading(
    this.primary, {
    this.apparent,
    this.apparentOnly = false,
  });

  final String primary;
  final String? apparent;
  final bool apparentOnly;

  static WeatherTemperatureReading? fromAttributes(
    Map<String, Object?> attributes, {
    required bool feelsLike,
    required bool feelsLikeOnly,
  }) {
    num? number(String key) {
      final value = attributes[key];
      return value is num && value.isFinite ? value : null;
    }

    String degrees(num value) =>
        '${value.round()}${attributes['temperature_unit'] ?? '°'}';
    final actual = number('temperature');
    final apparent = number('apparent_temperature');
    if (apparent != null && (feelsLikeOnly || (feelsLike && actual == null))) {
      return WeatherTemperatureReading(degrees(apparent), apparentOnly: true);
    }
    if (actual == null) return null;
    return WeatherTemperatureReading(
      degrees(actual),
      apparent: feelsLike && apparent != null ? degrees(apparent) : null,
    );
  }
}

class WeatherTemperature extends StatelessWidget {
  const WeatherTemperature({
    super.key,
    required this.reading,
    required this.primaryStyle,
    required this.secondaryStyle,
    this.alignment = CrossAxisAlignment.start,
  });

  final WeatherTemperatureReading reading;
  final TextStyle primaryStyle;
  final TextStyle secondaryStyle;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final secondary = reading.apparentOnly
        ? strings.screensaverOverlayFeelsLike
        : reading.apparent != null
        ? strings.screensaverWeatherFeelsLikeValue(reading.apparent!)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        Text(reading.primary, style: primaryStyle),
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Text(secondary, style: secondaryStyle),
        ],
      ],
    );
  }
}

/// Monochrome Material glyphs for the conditions, tinted with the widget
/// color exactly like the text.
IconData weatherConditionIcon(String condition) => switch (condition) {
  'clear-night' => Icons.nights_stay,
  'cloudy' => Icons.cloud,
  'exceptional' => Icons.storm,
  'fog' => Icons.foggy,
  'hail' => Icons.grain,
  'lightning' => Icons.bolt,
  'lightning-rainy' => Icons.thunderstorm,
  'partlycloudy' => Icons.wb_cloudy,
  'pouring' || 'rainy' => Icons.water_drop,
  'snowy' => Icons.ac_unit,
  'snowy-rainy' => Icons.ac_unit,
  'sunny' => Icons.wb_sunny,
  'windy' || 'windy-variant' => Icons.air,
  _ => Icons.cloud,
};

/// Material Icons has no rain cloud, so rain uses the Material Design Icons
/// Home Assistant shows for these states, embedded to skip loading the
/// whole icon shard.
const _mdiWeatherPaths = {
  // mdi:weather-rainy
  'rainy':
      'M6,14.03A1,1 0 0,1 7,15.03C7,15.58 6.55,16.03 6,16.03C3.24,16.03 1,13.79 1,11.03C1,8.27 3.24,6.03 6,6.03C7,3.68 9.3,2.03 12,2.03C15.43,2.03 18.24,4.69 18.5,8.06L19,8.03A4,4 0 0,1 23,12.03C23,14.23 21.21,16.03 19,16.03H18C17.45,16.03 17,15.58 17,15.03C17,14.47 17.45,14.03 18,14.03H19A2,2 0 0,0 21,12.03A2,2 0 0,0 19,10.03H17V9.03C17,6.27 14.76,4.03 12,4.03C9.5,4.03 7.45,5.84 7.06,8.21C6.73,8.09 6.37,8.03 6,8.03A3,3 0 0,0 3,11.03A3,3 0 0,0 6,14.03M12,14.15C12.18,14.39 12.37,14.66 12.56,14.94C13,15.56 14,17.03 14,18C14,19.11 13.1,20 12,20A2,2 0 0,1 10,18C10,17.03 11,15.56 11.44,14.94C11.63,14.66 11.82,14.4 12,14.15M12,11.03L11.5,11.59C11.5,11.59 10.65,12.55 9.79,13.81C8.93,15.06 8,16.56 8,18A4,4 0 0,0 12,22A4,4 0 0,0 16,18C16,16.56 15.07,15.06 14.21,13.81C13.35,12.55 12.5,11.59 12.5,11.59',
  // mdi:weather-night-partly-cloudy
  'partlycloudy-night':
      'M22,10.28C21.74,10.3 21.5,10.31 21.26,10.31C19.32,10.31 17.39,9.57 15.91,8.09C14.25,6.44 13.5,4.19 13.72,2C13.77,1.53 13.22,1 12.71,1C12.57,1 12.44,1.04 12.32,1.12C12,1.36 11.66,1.64 11.36,1.94C9.05,4.24 8.55,7.66 9.84,10.46C8.31,11.11 7.13,12.43 6.69,14.06L6,14A4,4 0 0,0 2,18A4,4 0 0,0 6,22H19A3,3 0 0,0 22,19A3,3 0 0,0 19,16C18.42,16 17.88,16.16 17.42,16.45L17.5,15.5C17.5,15.28 17.5,15.05 17.46,14.83C19.14,14.67 20.77,13.94 22.06,12.64C22.38,12.34 22.64,12 22.88,11.68C23.27,11.13 22.65,10.28 22.04,10.28M19,18A1,1 0 0,1 20,19A1,1 0 0,1 19,20H6A2,2 0 0,1 4,18A2,2 0 0,1 6,16H8.5V15.5C8.5,13.94 9.53,12.64 10.94,12.18C11.1,12.13 11.26,12.09 11.43,12.06C11.61,12.03 11.8,12 12,12C12.23,12 12.45,12.03 12.66,12.07C12.73,12.08 12.8,12.1 12.87,12.13C13,12.16 13.15,12.2 13.28,12.25C13.36,12.28 13.44,12.32 13.5,12.36C13.63,12.41 13.74,12.47 13.84,12.54C13.92,12.59 14,12.64 14.07,12.7C14.17,12.77 14.25,12.84 14.34,12.92C14.41,13 14.5,13.05 14.55,13.12C14.63,13.2 14.69,13.29 14.76,13.37C14.82,13.45 14.89,13.53 14.94,13.62C15,13.71 15.04,13.8 15.09,13.9C15.14,14 15.2,14.08 15.24,14.18C15.41,14.59 15.5,15.03 15.5,15.5V18M16.83,12.86C15.9,11.16 14.08,10 12,10H11.87C11.41,9.19 11.14,8.26 11.14,7.29C11.14,6.31 11.39,5.37 11.86,4.55C12.21,6.41 13.12,8.14 14.5,9.5C15.86,10.88 17.58,11.79 19.45,12.14C18.66,12.6 17.76,12.84 16.83,12.86Z',
  // mdi:weather-pouring
  'pouring':
      'M9,12C9.53,12.14 9.85,12.69 9.71,13.22L8.41,18.05C8.27,18.59 7.72,18.9 7.19,18.76C6.65,18.62 6.34,18.07 6.5,17.54L7.78,12.71C7.92,12.17 8.47,11.86 9,12M13,12C13.53,12.14 13.85,12.69 13.71,13.22L11.64,20.95C11.5,21.5 10.95,21.8 10.41,21.66C9.88,21.5 9.56,20.97 9.7,20.43L11.78,12.71C11.92,12.17 12.47,11.86 13,12M17,12C17.53,12.14 17.85,12.69 17.71,13.22L16.41,18.05C16.27,18.59 15.72,18.9 15.19,18.76C14.65,18.62 14.34,18.07 14.5,17.54L15.78,12.71C15.92,12.17 16.47,11.86 17,12M17,10V9A5,5 0 0,0 12,4C9.5,4 7.45,5.82 7.06,8.19C6.73,8.07 6.37,8 6,8A3,3 0 0,0 3,11C3,12.11 3.6,13.08 4.5,13.6V13.59C5,13.87 5.14,14.5 4.87,14.96C4.59,15.43 4,15.6 3.5,15.32V15.33C2,14.47 1,12.85 1,11A5,5 0 0,1 6,6C7,3.65 9.3,2 12,2C15.43,2 18.24,4.66 18.5,8.03L19,8A4,4 0 0,1 23,12C23,13.5 22.2,14.77 21,15.46V15.46C20.5,15.73 19.91,15.57 19.63,15.09C19.36,14.61 19.5,14 20,13.72V13.73C20.6,13.39 21,12.74 21,12A2,2 0 0,0 19,10H17Z',
};

/// The condition the icons draw for [condition]: at [night], the two
/// conditions whose icons show a sun take their moon versions, since Home
/// Assistant only has a night state for clear skies.
String _iconCondition(String condition, bool night) => !night
    ? condition
    : switch (condition) {
        'sunny' => 'clear-night',
        'partlycloudy' => 'partlycloudy-night',
        _ => condition,
      };

/// The colored icon file for each Home Assistant condition, the mapping
/// Voice Satellite LLM Tools uses for its weather results.
const _coloredWeatherIcons = {
  'clear-night': 'clear_night',
  'cloudy': 'cloudy',
  'exceptional': 'tropical_storm_hurricane',
  'fog': 'haze_fog_dust_smoke',
  'hail': 'mixed_rain_hail_sleet',
  'lightning': 'isolated_thunderstorms',
  'lightning-rainy': 'strong_thunderstorms',
  'partlycloudy': 'partly_cloudy_day',
  'partlycloudy-night': 'partly_cloudy_night',
  'pouring': 'heavy_rain',
  'rainy': 'showers_rain',
  'snowy': 'heavy_snow',
  'snowy-rainy': 'mixed_rain_snow',
  'sunny': 'clear_day',
  'windy': 'windy',
  'windy-variant': 'windy',
};

/// A weather condition in its own colors, from the bundled set. A
/// condition the set does not cover falls back to the monochrome
/// [WeatherConditionIcon] in [fallbackColor]. At [night] no icon shows a
/// sun.
class ColoredWeatherConditionIcon extends StatelessWidget {
  const ColoredWeatherConditionIcon(
    this.condition, {
    super.key,
    required this.size,
    required this.fallbackColor,
    this.night = false,
  });

  final String condition;
  final double size;
  final Color fallbackColor;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final name = _coloredWeatherIcons[_iconCondition(condition, night)];
    if (name == null) {
      return WeatherConditionIcon(
        condition,
        size: size,
        color: fallbackColor,
        night: night,
      );
    }
    return SvgPicture.asset(
      'assets/weather_icons/$name.svg',
      width: size,
      height: size,
    );
  }
}

/// The icon for a weather condition, drawn like [Icon] including its text
/// shadows.
class WeatherConditionIcon extends StatelessWidget {
  const WeatherConditionIcon(
    this.condition, {
    super.key,
    required this.size,
    required this.color,
    this.shadows = const [],
    this.night = false,
  });

  final String condition;
  final double size;
  final Color color;
  final List<Shadow> shadows;

  /// Whether the sun is down: no icon then shows a sun.
  final bool night;

  @override
  Widget build(BuildContext context) {
    final drawn = _iconCondition(condition, night);
    final path = _mdiWeatherPaths[drawn];
    if (path == null) {
      return Icon(
        weatherConditionIcon(drawn),
        size: size,
        color: color,
        shadows: shadows,
      );
    }
    Widget glyph(Color color) => SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$path"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
    if (shadows.isEmpty) return glyph(color);
    return Stack(
      children: [
        for (final shadow in shadows)
          Transform.translate(
            offset: shadow.offset,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: shadow.blurSigma,
                sigmaY: shadow.blurSigma,
              ),
              child: glyph(shadow.color),
            ),
          ),
        glyph(color),
      ],
    );
  }
}

String weatherMoodConditionText(BuildContext context, String condition) {
  final strings = l10n(context);
  return switch (condition) {
    'sunny' || 'clear-night' => strings.screensaverWeatherPreviewSunny,
    'partlycloudy' => strings.screensaverWeatherPreviewPartlycloudy,
    'cloudy' => strings.screensaverWeatherPreviewCloudy,
    'rainy' => strings.screensaverWeatherPreviewRainy,
    'pouring' => strings.screensaverWeatherPreviewPouring,
    'snowy' => strings.screensaverWeatherPreviewSnowy,
    'snowy-rainy' => strings.screensaverWeatherPreviewSnowyRainy,
    'fog' => strings.screensaverWeatherPreviewFog,
    'hail' => strings.screensaverWeatherPreviewHail,
    'lightning' => strings.screensaverWeatherPreviewLightning,
    'lightning-rainy' => strings.screensaverWeatherPreviewLightningRainy,
    'windy' => strings.screensaverWeatherPreviewWindy,
    'windy-variant' => strings.screensaverWeatherPreviewWindyVariant,
    _ => strings.screensaverWeatherPreviewExceptional,
  };
}
