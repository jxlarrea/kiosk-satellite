import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'weather_mood_renderer.dart';
import 'weather_mood_information.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../core/lifecycle.dart';
import '../l10n/messages.dart';
import '../managers/calendar/calendar_manager.dart' show parseForecast;
import '../managers/home_assistant/home_assistant_manager.dart'
    show GlanceSubscription;
import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';

/// The sun entity takes precedence over a weather provider's day/night label.
bool weatherMoodNight(String? sun, DateTime localTime) => switch (sun) {
  'above_horizon' => false,
  'below_horizon' => true,
  _ => localTime.hour < 6 || localTime.hour >= 18,
};

/// Warmth peaks near the horizon and fades into the existing day/night scenes.
double weatherMoodTwilight(
  String? sun,
  DateTime localTime, {
  double? elevation,
}) {
  final validSun = sun == 'above_horizon' || sun == 'below_horizon';
  if (validSun &&
      elevation != null &&
      elevation.isFinite &&
      elevation.abs() <= 90) {
    final fade = ((elevation.abs() - 2) / 4).clamp(0.0, 1.0);
    return 1 - fade * fade * (3 - 2 * fade);
  }
  // Without elevation, use one hour around the local 6 AM / 6 PM fallback.
  // A valid sun state still prevents a warm scene in the wrong half of the day.
  final minutes =
      localTime.hour * 60 + localTime.minute + localTime.second / 60;
  final morning = (minutes - 360).abs();
  final evening = (minutes - 1080).abs();
  final distance = morning < evening ? morning : evening;
  if (validSun &&
      weatherMoodNight(sun, localTime) != weatherMoodNight(null, localTime)) {
    return 0;
  }
  final fade = ((distance - 10) / 20).clamp(0.0, 1.0);
  return 1 - fade * fade * (3 - 2 * fade);
}

bool weatherMoodHasScene(SettingsManager settings) =>
    settings.get(defs.screensaverWeatherPreview) ||
    settings.get(defs.screensaverWeatherEntity).trim().isNotEmpty;

({String condition, bool night, double twilight}) weatherMoodScene(
  SettingsManager settings,
  String condition,
  String? sun,
  DateTime localTime, {
  double? elevation,
}) => settings.get(defs.screensaverWeatherPreview)
    ? (
        condition: settings.get(defs.screensaverWeatherPreviewCondition),
        night: settings.get(defs.screensaverWeatherPreviewPeriod) == 'night',
        twilight:
            settings.get(defs.screensaverWeatherPreviewPeriod) == 'twilight'
            ? 1.0
            : 0.0,
      )
    : (
        condition: condition,
        night: weatherMoodNight(sun, localTime),
        twilight: weatherMoodTwilight(sun, localTime, elevation: elevation),
      );

const weatherMoodConditions = {
  'sunny',
  'clear-night',
  'partlycloudy',
  'cloudy',
  'rainy',
  'pouring',
  'snowy',
  'snowy-rainy',
  'fog',
  'hail',
  'lightning',
  'lightning-rainy',
  'windy',
  'windy-variant',
  'exceptional',
};

class WeatherMoodScreensaver extends StatefulWidget {
  const WeatherMoodScreensaver({super.key, required this.container});
  final AppContainer container;

  @override
  State<WeatherMoodScreensaver> createState() => _WeatherMoodScreensaverState();
}

class _WeatherMoodScreensaverState extends State<WeatherMoodScreensaver>
    with WidgetsBindingObserver {
  GlanceSubscription? _live;
  StreamSubscription<SettingChanged>? _settings;
  StreamSubscription<ScreenStateChanged>? _screen;
  Timer? _retry;
  Timer? _clock;
  int _generation = 0;
  String _condition = 'exceptional';
  String? _sun;
  double? _sunElevation;
  WeatherMoodReadings _readings = WeatherMoodReadings();
  Map<String, String> _translations = const {};
  bool _screenOn = true;
  bool _foreground = true;
  bool _immediate = false;
  // The scene stays black until the first weather reaches it and its
  // first full frame is ready, so it never morphs out of a placeholder.
  bool _dataReady = false, _revealed = false;
  // Flutter switches from its image view back to its own surface once the
  // dashboard stops rendering behind the screensaver, and that switch can
  // show one blank frame. Revealing only after it keeps that frame black.
  bool _sceneDone = false, _surfaceSettled = false;
  Timer? _surfaceTimer;
  bool _gotEntity = false, _gotSun = false;
  int _revealToken = 0;
  Timer? _sunGrace, _revealTimeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = Lifecycle.onScreen;
    // Previews and missing entities have nothing to wait for.
    _dataReady =
        widget.container.settings.get(defs.screensaverWeatherPreview) ||
        widget.container.settings
            .get(defs.screensaverWeatherEntity)
            .trim()
            .isEmpty;
    // Without Home Assistant, the neutral scene appears after a moment.
    _revealTimeout = Timer(const Duration(seconds: 4), () {
      if (mounted && !_revealed) setState(() => _revealed = true);
    });
    final frozen = widget.container.browser.renderingFrozenState;
    frozen.addListener(_dashboardFrozen);
    // Without a dashboard to pause there is no switch to wait for.
    _surfaceTimer = Timer(const Duration(seconds: 2), _settleSurface);
    _dashboardFrozen();
    _screenOn = widget.container.screen.isScreenOn;
    _screen = widget.container.bus.on<ScreenStateChanged>().listen((event) {
      _screenOn = event.on;
      unawaited(_activity());
    });
    _settings = widget.container.bus.on<SettingChanged>().listen((event) {
      if (event.key == defs.screensaverWeatherEntity.key ||
          event.key == defs.haUrl.key ||
          event.key == defs.haToken.key) {
        if (event.key == defs.screensaverWeatherEntity.key) {
          setState(() {});
        }
        unawaited(_subscribe(reset: true));
      } else if (event.key == defs.screensaverWeatherPreview.key) {
        setState(() {});
        unawaited(_update(immediate: true));
      } else if (event.key == defs.screensaverWeatherPreviewCondition.key ||
          event.key == defs.screensaverWeatherPreviewPeriod.key) {
        unawaited(_update(immediate: true));
      } else if (event.key == defs.screensaverWeatherLightning.key) {
        unawaited(_update());
      } else if (event.key == defs.screensaverFollowAnimationScale.key ||
          event.key.startsWith('screensaver.weather_') ||
          event.key.startsWith('screensaver.glance_')) {
        setState(() {});
      }
    });
    _clock = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_update()),
    );
    unawaited(_subscribe());
  }

  Future<void> _subscribe({bool reset = false}) async {
    final generation = ++_generation;
    _retry?.cancel();
    final previous = _live;
    _live = null;
    await previous?.close();
    if (!mounted || generation != _generation) return;
    if (reset) {
      _condition = 'exceptional';
      _sun = null;
      _sunElevation = null;
      _readings = WeatherMoodReadings();
      unawaited(_update());
    }
    final entity = widget.container.settings
        .get(defs.screensaverWeatherEntity)
        .trim();
    if (entity.isEmpty) return;
    final live = await widget.container.homeAssistant.subscribeEntities(
      [if (entity.startsWith('weather.')) entity, 'sun.sun'],
      (id, state) {
        if (!mounted || generation != _generation) return;
        final value = state['state'];
        if (id == 'sun.sun') {
          if (value is String) _sun = value;
          final attrs = state['attributes'];
          if (_sun != 'above_horizon' && _sun != 'below_horizon') {
            _sunElevation = null;
          } else if (attrs is Map && attrs.containsKey('elevation')) {
            final elevation = attrs['elevation'];
            _sunElevation = elevation is num && elevation.isFinite
                ? elevation.toDouble()
                : null;
          }
        } else if (id == entity) {
          _readings.update(state);
          if (weatherMoodConditions.contains(value)) {
            _condition = value as String;
          }
        }
        if (_dataReady) {
          unawaited(_update());
          return;
        }
        if (id == 'sun.sun') _gotSun = true;
        if (id == entity) _gotEntity = true;
        if (_gotEntity && _gotSun) {
          _markDataReady();
        } else if (_gotEntity) {
          // The sun usually follows at once; not every install has one.
          _sunGrace ??= Timer(const Duration(seconds: 1), _markDataReady);
        }
      },
      // For the weather bar's condition label.
      translationDomain: 'weather',
      onTranslations: (translations) {
        if (!mounted || generation != _generation) return;
        setState(() => _translations = translations);
      },
      // For the weather bar's high and low.
      forecastEntity: entity.startsWith('weather.') ? entity : null,
      onForecast: (forecast) {
        if (!mounted || generation != _generation) return;
        setState(() => _readings.daily = parseForecast(forecast));
      },
    );
    if (!mounted || generation != _generation) {
      await live?.close();
      return;
    }
    _live = live;
    void retry() {
      if (!mounted || generation != _generation) return;
      _sun = null;
      _sunElevation = null;
      unawaited(_update());
      _retry?.cancel();
      _retry = Timer(
        const Duration(seconds: 10),
        () => unawaited(_subscribe()),
      );
    }

    if (live == null || live.isClosed) {
      retry();
    } else {
      live.onClosed = retry;
    }
  }

  /// The first real weather lands at once instead of transitioning from
  /// the placeholder scene.
  void _markDataReady() {
    if (!mounted || _dataReady) return;
    _sunGrace?.cancel();
    _dataReady = true;
    _revealToken++;
    unawaited(_update(immediate: true));
  }

  void _sceneFinished(int token) {
    // A placeholder scene finishing before the weather arrives carries an
    // older token, or arrives while the data is still missing.
    if (!mounted || token != _revealToken || !_dataReady) return;
    _sceneDone = true;
    _maybeReveal();
  }

  void _dashboardFrozen() {
    if (!mounted || _surfaceSettled) return;
    if (widget.container.browser.renderingFrozenState.value) {
      // The switch completes within a couple of frames of the freeze.
      _surfaceTimer?.cancel();
      _surfaceTimer = Timer(const Duration(milliseconds: 250), _settleSurface);
    }
  }

  void _settleSurface() {
    if (!mounted) return;
    _surfaceSettled = true;
    _maybeReveal();
  }

  void _maybeReveal() {
    if (_revealed || !_sceneDone || !_surfaceSettled) return;
    setState(() => _revealed = true);
  }

  Future<void> _update({bool immediate = false}) async {
    if (!mounted) return;
    setState(() => _immediate = immediate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = !Lifecycle.offScreen(state);
    unawaited(_activity());
  }

  Future<void> _activity() async {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _settings?.cancel();
    _screen?.cancel();
    _retry?.cancel();
    _clock?.cancel();
    _sunGrace?.cancel();
    _revealTimeout?.cancel();
    _surfaceTimer?.cancel();
    widget.container.browser.renderingFrozenState.removeListener(
      _dashboardFrozen,
    );
    unawaited(_live?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!weatherMoodHasScene(widget.container.settings)) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                screensaverText(
                  context,
                  'Select a weather entity in Settings > Screensaver > Weather Mood.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
        ),
      );
    }
    final scene = weatherMoodScene(
      widget.container.settings,
      _condition,
      _sun,
      DateTime.now(),
      elevation: _sunElevation,
    );
    final blur = widget.container.settings
        .get(defs.screensaverWeatherBlur)
        .toDouble()
        .clamp(0.0, 30.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            enabled: blur > 0,
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blur,
              sigmaY: blur,
              tileMode: TileMode.clamp,
            ),
            child: WeatherMoodRenderer(
              condition: scene.condition,
              night: scene.night,
              twilight: scene.twilight,
              lightning: widget.container.settings.get(
                defs.screensaverWeatherLightning,
              ),
              active: _screenOn && _foreground,
              immediate: _immediate,
              revealed: _revealed,
              revealToken: _revealToken,
              onReady: _sceneFinished,
              lowPower: weatherMoodLowPower(widget.container),
              followAnimationScale: widget.container.settings.get(
                defs.screensaverFollowAnimationScale,
              ),
              onError: (error) => widget.container.log.warn(
                'screensaver',
                'Weather Mood renderer stopped: $error',
              ),
            ),
          ),
        ),
        // Black until the scene is ready, then a quick fade into it. The
        // clock and weather chips join the scene, so the screen stays fully
        // black through the surface switch.
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _revealed ? 0 : 1,
            duration: const Duration(milliseconds: 350),
            child: const ColoredBox(color: Colors.black),
          ),
        ),
        AnimatedOpacity(
          opacity: _revealed ? 1 : 0,
          duration: const Duration(milliseconds: 350),
          child: WeatherMoodInformation(
            container: widget.container,
            readings: _readings,
            translations: _translations,
            // Day and dawn overcast: bright cloud from edge to edge.
            brightSky: scene.condition == 'cloudy' && !scene.night,
          ),
        ),
      ],
    );
  }
}
