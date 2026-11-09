import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'alarm_ring_overlay.dart';
import '../app_container.dart';
import '../core/locale_dates.dart';
import '../l10n/messages.dart';
import '../managers/calendar/calendar_manager.dart' show DayForecast;
import '../managers/calendar/calendar_model.dart' show dateOnly;
import '../managers/settings/definitions.dart' as defs;
import 'clock_faces.dart';
import 'digital_clock_face.dart';
import 'glance_row.dart';
import 'glass_chip.dart';
import 'text_snapshot.dart';
import 'weather_readings.dart';

/// A soft shadow for text over the open sky, sized to the text: a faint
/// contact shadow that holds the edges and a wide, light one for depth. A
/// hard shadow read as a dark copy under every glyph.
///
/// [bright] is for a sky of bright cloud from edge to edge, where the light
/// version leaves white text with nothing to stand on: darker layers and a
/// broad halo that dims the cloud around the text.
List<Shadow> _skyShadows(double size, {bool bright = false}) => [
  Shadow(
    color: Color(bright ? 0x73000000 : 0x40000000),
    offset: Offset(0, size * .006),
    blurRadius: size * (bright ? .02 : .014),
  ),
  Shadow(
    color: Color(bright ? 0x73000000 : 0x4D000000),
    offset: Offset(0, size * .02),
    blurRadius: size * .08,
  ),
  if (bright)
    Shadow(
      color: const Color(0x80000000),
      offset: Offset(0, size * .03),
      blurRadius: size * .3,
    ),
];

/// The date's version: small, thin text needs more around it than the
/// digits do to stay readable over bright clouds.
List<Shadow> _dateShadows(double size, {bool bright = false}) => [
  Shadow(
    color: Color(bright ? 0x8C000000 : 0x66000000),
    offset: Offset(0, size * .015),
    blurRadius: size * .05,
  ),
  Shadow(
    color: Color(bright ? 0x66000000 : 0x4D000000),
    offset: Offset(0, size * .03),
    blurRadius: size * .15,
  ),
  Shadow(
    color: Color(bright ? 0x59000000 : 0x40000000),
    offset: Offset(0, size * .05),
    blurRadius: size * .4,
  ),
];

/// The chips' lighter version at text scale [scale]: the glass already
/// darkens behind their text, so the shadow only needs to hold the edges
/// where Background opacity leaves little tint.
List<Shadow> _chipShadows(double scale) => [
  Shadow(
    color: const Color(0x33000000),
    offset: Offset(0, 1 * scale),
    blurRadius: 2 * scale,
  ),
  Shadow(
    color: const Color(0x33000000),
    offset: Offset(0, 2 * scale),
    blurRadius: 10 * scale,
  ),
];

/// Whether Weather Mood runs its low-power path: devices without a 64-bit
/// ABI, such as the Echo Show 8. Their clouds take fewer samples and their
/// glass chips skip the backdrop blur.
bool weatherMoodLowPower(AppContainer container) {
  final abis = container.device.abis;
  return abis.isNotEmpty && !abis.any((abi) => abi.contains('64'));
}

/// The glass of Weather Mood's chips, shared by the weather chips and At a
/// Glance: tinted by Background opacity and blurring the scene behind them
/// except on low-power devices, where a blur costs a quarter of the frames.
GlassPalette weatherMoodGlass(AppContainer container) => GlassPalette(
  (container.settings.get(defs.screensaverWeatherBarOpacity) / 100).clamp(
    0.0,
    1.0,
  ),
  blur: weatherMoodLowPower(container) ? 0 : 20,
);

Color _color(String value) {
  final parts = value.split(',').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((v) => v == null)) {
    return const Color(0xFFFAFAFA);
  }
  return Color.fromARGB(
    255,
    parts[0]!.clamp(0, 255),
    parts[1]!.clamp(0, 255),
    parts[2]!.clamp(0, 255),
  );
}

class WeatherMoodReadings {
  String condition = '';
  final attributes = <String, Object?>{};

  /// The entity's daily forecast by local date, for today's high and low.
  /// Empty when the integration has no daily forecast.
  Map<DateTime, DayForecast> daily = const {};

  /// Today's high and low as the weather widget shows them, or null
  /// unless the forecast has both.
  String? highLow([DateTime? now]) {
    final today = daily[dateOnly(now ?? DateTime.now())];
    final high = today?.high, low = today?.low;
    if (high == null || low == null) return null;
    return '${high.round()}° / ${low.round()}°';
  }

  bool get available =>
      condition.isNotEmpty &&
      condition != 'unknown' &&
      condition != 'unavailable';

  void update(Map<String, Object?> state) {
    final value = state['state'];
    if (value is String) condition = value;
    final attrs = state['attributes'];
    if (attrs is Map) attributes.addAll(attrs.map((k, v) => MapEntry('$k', v)));
  }

  num? number(String key) {
    final value = attributes[key];
    return value is num && value.isFinite ? value : null;
  }

  String reading(num value, String unitKey) {
    final unit = '${attributes[unitKey] ?? ''}';
    return unit.isEmpty ? '${value.round()}' : '${value.round()} $unit';
  }

  String? temperature({required bool feelsLike}) =>
      WeatherTemperatureReading.fromAttributes(
        attributes,
        feelsLike: false,
        feelsLikeOnly: feelsLike,
      )?.primary;
}

/// Static text repaints independently of the animated GPU background.
class WeatherMoodInformation extends StatefulWidget {
  const WeatherMoodInformation({
    super.key,
    required this.container,
    required this.readings,
    this.translations = const {},
    this.brightSky = false,
  });
  final AppContainer container;
  final WeatherMoodReadings readings;
  final Map<String, String> translations;

  /// Bright cloud fills the sky behind the clock, so its shadow needs to
  /// be heavier.
  final bool brightSky;

  @override
  State<WeatherMoodInformation> createState() => _WeatherMoodInformationState();
}

class _WeatherMoodInformationState extends State<WeatherMoodInformation> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _schedule();
    widget.container.screensaver.alarmTakeover.addListener(_onTakeover);
  }

  void _onTakeover() {
    if (mounted) setState(() {});
  }

  bool get _ringing =>
      widget.container.screensaver.alarmTakeover.value == 'ringing';

  @override
  void didUpdateWidget(WeatherMoodInformation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A settings change rebuilds this widget, and Show seconds changes how
    // often the clock needs to tick.
    _schedule();
  }

  bool get _seconds =>
      widget.container.settings.get(defs.screensaverWeatherClock) &&
      widget.container.settings.get(defs.screensaverWeatherClockSeconds);

  /// Wakes at the next second while seconds show, the next minute
  /// otherwise.
  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    _timer = Timer(
      _seconds
          ? Duration(milliseconds: 1000 - now.millisecond)
          : Duration(milliseconds: 60000 - now.second * 1000 - now.millisecond),
      () {
        if (!mounted) return;
        final previous = _now;
        setState(() {
          _now = DateTime.now();
          // Pixel shift still moves once a minute, not with every second.
          if (_now.minute != previous.minute || _now.hour != previous.hour) {
            if (widget.container.settings.get(defs.screensaverPixelShift)) {
              final random = math.Random();
              _offset = Offset(
                random.nextDouble() * 20 - 10,
                random.nextDouble() * 20 - 10,
              );
            } else {
              _offset = Offset.zero;
            }
          }
        });
        _schedule();
      },
    );
  }

  @override
  void dispose() {
    widget.container.screensaver.alarmTakeover.removeListener(_onTakeover);
    _timer?.cancel();
    super.dispose();
  }

  /// Snooze and Stop in the weather chips' glass and text shadow, the
  /// label on the date line: a ringing alarm taking the scene over.
  Widget _alarmControls(double dateSize, Color color, String? fontFamily) {
    final s = widget.container.settings;
    final glass = weatherMoodGlass(widget.container);
    final shadow = s.get(defs.screensaverWeatherBarShadow);
    return AlarmTakeoverControls(
      container: widget.container,
      color: color,
      ink: const Color(0xFF1C1C1E),
      glass: glass.fill,
      edge: Colors.white.withValues(alpha: math.max(.18, glass.edge.a)),
      labelSize: dateSize,
      labelColor: color,
      labelWeight: FontWeight.w500,
      fontFamily: fontFamily,
      shadows: shadow ? _chipShadows(1) : const [],
    );
  }

  Widget _clock(Size size, bool glance) {
    final s = widget.container.settings;
    if (!s.get(defs.screensaverWeatherClock)) {
      if (!_ringing) return const SizedBox.expand();
      return Center(
        child: _alarmControls(
          math.min(size.width * .05, size.height * .07),
          _color(s.get(defs.screensaverWeatherClockColor)),
          null,
        ),
      );
    }
    final use24h = s.get(defs.screensaverWeatherClock24h);
    final hour = use24h
        ? _now.hour
        : (_now.hour % 12 == 0 ? 12 : _now.hour % 12);
    final hours = use24h ? '$hour'.padLeft(2, '0') : '$hour';
    final showSeconds = s.get(defs.screensaverWeatherClockSeconds);
    final seconds = showSeconds ? ':${'${_now.second}'.padLeft(2, '0')}' : '';
    final period = use24h || !s.get(defs.screensaverWeatherClockAmPm)
        ? ''
        : _now.hour < 12
        ? ' AM'
        : ' PM';
    final time = '$hours:${'${_now.minute}'.padLeft(2, '0')}$seconds$period';
    final font = s.get(defs.screensaverWeatherClockFont);
    final scale =
        (s.get(defs.screensaverWeatherClockScale) / 100).clamp(.5, 3.0) *
        (glance ? .72 : 1);
    final vertical = s.get(defs.screensaverWeatherClockVertical);
    final lines = DigitalClockFace.linesFor(seconds: showSeconds);
    final clockSize =
        DigitalClockFace.sizeFor(size, vertical: vertical, lines: lines) *
        scale;
    final dateSize =
        DigitalClockFace.dateSizeFor(size, vertical: vertical, lines: lines) *
        scale;
    final shadow = s.get(defs.screensaverWeatherClockShadow);
    final bright = widget.brightSky;
    final ringing = _ringing;
    final date = !ringing && s.get(defs.screensaverWeatherClockDate)
        ? fullDate(_now)
        : null;
    final color = _color(s.get(defs.screensaverWeatherClockColor));
    final weight =
        clockWeightOverride(s.get(defs.screensaverWeatherClockFontWeight)) ??
        clockFontWeight(font);
    final face = DigitalClockFace(
      time: time,
      vertical: vertical,
      dateGapFactor: .015,
      dateOpacity: 1,
      date: date,
      color: color,
      clockSize: clockSize,
      dateSize: dateSize,
      fontFamily: clockFontFamily(font),
      weight: weight,
      opticalSize: clockOpticalSize(font),
      // Each line's shadow is sized to its own text.
      shadows: shadow ? _skyShadows(clockSize, bright: bright) : const [],
      dateShadows: shadow ? _dateShadows(dateSize, bright: bright) : const [],
      // A step heavier than the Clock screensaver's, so the thin
      // strokes hold up over white clouds.
      dateWeight: FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Transform.translate(
          offset: _offset,
          child: ringing
              // The face gives way to the label and the buttons, which keep
              // their full size. Fitted together, a small screen shrank the
              // buttons along with the clock.
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: FittedBox(fit: BoxFit.scaleDown, child: face),
                    ),
                    SizedBox(height: clockSize * .08),
                    _alarmControls(dateSize, color, clockFontFamily(font)),
                  ],
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  // Blurred shadows redraw every frame on Impeller unless
                  // the face is kept as an image until the time changes.
                  child: shadow
                      ? TextSnapshot(
                          // The soft shadows reach this far past the text.
                          bleed: math.max(
                            clockSize * (bright ? .55 : .16),
                            dateSize * .8,
                          ),
                          content: (
                            bright,
                            time,
                            date,
                            color,
                            clockSize,
                            dateSize,
                            font,
                            weight,
                            vertical,
                          ),
                          child: face,
                        )
                      : face,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.container;
    final size = MediaQuery.sizeOf(context);
    final ringing = _ringing;
    return IgnorePointer(
      // A ringing alarm's Snooze and Stop are the one thing here to touch.
      ignoring: !ringing,
      child: RepaintBoundary(
        child: ValueListenableBuilder<bool?>(
          valueListenable: c.screensaver.scheduleGlance,
          builder: (context, scheduled, _) => ValueListenableBuilder(
            valueListenable: c.glance.entities,
            builder: (context, entities, _) {
              final glance =
                  !ringing &&
                  (scheduled ??
                      c.settings.get(defs.screensaverGlanceEnabled)) &&
                  entities.isNotEmpty;
              return Column(
                children: [
                  Expanded(child: _clock(size, glance)),
                  if (glance)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            !ringing &&
                                c.settings.get(defs.screensaverWeatherBar) &&
                                widget.readings.available
                            ? 24
                            : size.height * .06,
                      ),
                      // The pills wear the weather chips' glass at the same
                      // Background opacity, so both rows match.
                      child: GlanceRow(
                        container: c,
                        scale: math.min(1.0, size.height / 480).clamp(.75, 1.0),
                        glass: weatherMoodGlass(c),
                        // And the same Text drop shadow.
                        shadows:
                            c.settings.get(defs.screensaverWeatherBarShadow)
                            ? _chipShadows(
                                c.settings.get(defs.screensaverGlanceScale) /
                                    100,
                              )
                            : const [],
                      ),
                    ),
                  if (!ringing &&
                      c.settings.get(defs.screensaverWeatherBar) &&
                      widget.readings.available)
                    WeatherMoodBar(
                      container: c,
                      readings: widget.readings,
                      translations: widget.translations,
                      offset: _offset,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Weather readings as chips floating over the scene: a large chip with
/// the conditions and temperature at the bottom left and one small chip
/// per reading at the bottom right. Translucent dark pills with a faint
/// edge read against every sky, from bright day to dusk to night, and
/// match the At a Glance pills.
class WeatherMoodBar extends StatelessWidget {
  const WeatherMoodBar({
    super.key,
    required this.container,
    required this.readings,
    this.translations = const {},
    this.offset = Offset.zero,
  });
  final AppContainer container;
  final WeatherMoodReadings readings;
  final Map<String, String> translations;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final s = container.settings, size = MediaQuery.sizeOf(context);
    final scale = (s.get(defs.screensaverWeatherBarScale) / 100).clamp(.5, 2.0);
    final color = _color(s.get(defs.screensaverWeatherBarColor));
    final shadows = s.get(defs.screensaverWeatherBarShadow)
        ? _chipShadows(scale)
        : const <Shadow>[];
    final glass = weatherMoodGlass(container);
    TextStyle style(
      double fontSize, {
      FontWeight weight = FontWeight.w400,
      double alpha = 1,
    }) => TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize * scale,
      color: color.withValues(alpha: alpha),
      fontWeight: weight,
      shadows: shadows,
      height: 1.2,
    );
    // A StadiumBorder keeps the radius at half the chip's own height; an
    // oversized corner radius once froze Impeller's raster thread.
    // [content] is everything the chip shows, so the snapshot that keeps
    // its shadowed text from redrawing every frame refreshes when it does.
    Widget chip(Widget child, EdgeInsets padding, Object content) {
      final body = shadows.isEmpty
          ? child
          : TextSnapshot(
              content: (content, scale, color),
              bleed: 20 * scale,
              child: child,
            );
      return GlassChip(
        palette: glass,
        fallback: Container(
          padding: padding * scale,
          decoration: glass.decoration,
          child: body,
        ),
        child: Padding(padding: padding * scale, child: body),
      );
    }

    Widget disc(double diameter, Widget icon) => Container(
      width: diameter * scale,
      height: diameter * scale,
      alignment: Alignment.center,
      decoration: glass.disc(scale),
      child: icon,
    );
    // Without titles a reading shows its value alone, at the size of the
    // temperature in the main chip.
    final titles = s.get(defs.screensaverWeatherBarTitles);
    Widget metric(String title, String value, IconData icon) => chip(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          disc(
            40,
            Icon(icon, color: color, size: 22 * scale, shadows: shadows),
          ),
          SizedBox(width: 10 * scale),
          Flexible(
            child: titles
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        screensaverText(context, title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(13, alpha: .8),
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(17, weight: FontWeight.w600),
                      ),
                    ],
                  )
                : Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style(24, weight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      const EdgeInsets.fromLTRB(6, 6, 18, 6),
      (screensaverText(context, title), value, icon, titles),
    );
    final highLow = readings.highLow();
    final metrics = <Widget>[
      if (s.get(defs.screensaverWeatherBarHighLow) && highLow != null)
        metric('High and low', highLow, Icons.thermostat),
      if (s.get(defs.screensaverWeatherBarHumidity) &&
          readings.number('humidity') != null)
        metric(
          'Humidity',
          '${readings.number('humidity')!.round()}%',
          Icons.water_drop_outlined,
        ),
      if (s.get(defs.screensaverWeatherBarWind) &&
          readings.number('wind_speed') != null)
        metric(
          'Wind speed',
          readings.reading(readings.number('wind_speed')!, 'wind_speed_unit'),
          Icons.air,
        ),
      if (s.get(defs.screensaverWeatherBarVisibility) &&
          readings.number('visibility') != null)
        metric(
          'Visibility',
          readings.reading(readings.number('visibility')!, 'visibility_unit'),
          Icons.visibility_outlined,
        ),
    ];
    final location = s.get(defs.screensaverWeatherBarLocation).trim();
    final condition =
        translations[readings.condition] ??
        weatherMoodConditionText(context, readings.condition);
    final temperature = readings.temperature(
      feelsLike: s.get(defs.screensaverWeatherBarFeelsLike),
    );
    final forecast = s.get(defs.screensaverWeatherBarForecast);
    // The same height and type as the reading chips, so every chip in
    // the row matches. The temperature takes the value size and the
    // location and conditions stack beside it like a reading's title.
    final main = chip(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Holds the chip at the reading chips' height without an icon.
          SizedBox(height: 40 * scale),
          if (forecast)
            disc(
              40,
              WeatherConditionIcon(
                readings.condition,
                size: 24 * scale,
                color: color,
                shadows: shadows,
              ),
            ),
          if (temperature != null) ...[
            SizedBox(width: (forecast ? 10 : 6) * scale),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  temperature,
                  style: style(24, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
          if (location.isNotEmpty || forecast) ...[
            SizedBox(width: 12 * scale),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (location.isNotEmpty)
                    Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(13, alpha: .8),
                    ),
                  if (forecast)
                    Text(
                      condition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style(17, weight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
      const EdgeInsets.fromLTRB(6, 6, 18, 6),
      (temperature, condition, location, forecast, readings.condition),
    );
    final gap = 12 * scale;
    // One row when the chips' real widths fit: conditions at the left and
    // readings at the right. Otherwise the readings stack above the main
    // chip and wrap as needed.
    final content = Padding(
      padding: EdgeInsets.fromLTRB(12 * scale, 0, 12 * scale, 12 * scale),
      child: Transform.translate(
        offset: offset,
        // A lone conditions chip sits centered; with readings it anchors
        // the bottom left.
        child: metrics.isEmpty
            ? Center(child: main)
            : OverflowBar(
                spacing: gap * 2,
                overflowSpacing: gap,
                alignment: MainAxisAlignment.spaceBetween,
                overflowAlignment: OverflowBarAlignment.start,
                overflowDirection: VerticalDirection.up,
                children: [
                  main,
                  Wrap(spacing: gap, runSpacing: gap, children: metrics),
                ],
              ),
      ),
    );
    // The chips take their natural height, so the clock above keeps all
    // the room they leave. They shrink only when many wrapped readings on a
    // small screen would take more than a third of it.
    // The width the chips actually get. Under a UI scale exemption the
    // MediaQuery size is the scaled one, not the space laid out here.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : size.width;
        return _ReportHeight(
          key: const ValueKey('weather-mood-bar'),
          onHeight: (height) =>
              container.screensaver.weatherChipsHeight.value = height,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size.height * width / size.width * .38,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: BackdropGroup(
                child: SizedBox(width: width, child: content),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reports its child's laid-out height after the frame, for layouts that
/// depend on it elsewhere.
class _ReportHeight extends SingleChildRenderObjectWidget {
  const _ReportHeight({super.key, required this.onHeight, super.child});
  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderReportHeight(onHeight);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReportHeight renderObject,
  ) => renderObject.onHeight = onHeight;
}

class _RenderReportHeight extends RenderProxyBox {
  _RenderReportHeight(this.onHeight);
  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _reported) return;
    _reported = height;
    // Listeners rebuild other widgets, which cannot happen mid-layout.
    SchedulerBinding.instance.addPostFrameCallback((_) => onHeight(height));
  }

  @override
  void detach() {
    if (_reported != null) {
      _reported = null;
      SchedulerBinding.instance.addPostFrameCallback((_) => onHeight(0));
    }
    super.detach();
  }
}
