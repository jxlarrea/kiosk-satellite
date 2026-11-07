import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_container.dart';
import '../core/app_locales.dart';
import '../core/events.dart';
import '../core/lifecycle.dart';
import '../l10n/messages.dart';
import '../managers/settings/definitions.dart' as defs;
import 'celestial_astronomy.dart';
import 'celestial_controls.dart';
import 'celestial_renderer.dart';
import 'weather_mood_information.dart' show weatherMoodLowPower;

typedef CelestialPlace = ({double latitude, double longitude});

/// The night sky over the kiosk, drawn from a star catalog and computed
/// planet and Moon positions. A drag looks around, a pinch zooms and a
/// double tap closes it, so a single touch never dismisses it. With Point
/// at the sky on and a compass, the view turns with the device instead.
/// The GPS source follows the device's position live. A touch brings up
/// chips at the bottom for five seconds.
class CelestialScreensaver extends StatefulWidget {
  const CelestialScreensaver({super.key, required this.container});
  final AppContainer container;

  @override
  State<CelestialScreensaver> createState() => _CelestialScreensaverState();
}

class _CelestialScreensaverState extends State<CelestialScreensaver>
    with WidgetsBindingObserver {
  AppContainer get c => widget.container;

  late final ValueNotifier<CelestialView> _view;
  bool _viewSet = false;
  CelestialView? _gestureStart;
  Timer? _saveView;

  CelestialPlace? _place;
  bool _placeResolved = false;

  /// Why the chosen location source has no position, once asked.
  String? _placeProblem;
  int _placeAsk = 0;
  StreamSubscription<SettingChanged>? _settings;
  StreamSubscription<ScreenStateChanged>? _screen;
  StreamSubscription<LocationChanged>? _location;
  bool _screenOn = true, _foreground = true;

  // Black until the first frame is ready and Flutter has settled on its own
  // surface over the paused dashboard, as Weather Mood does.
  bool _revealed = false, _sceneDone = false, _surfaceSettled = false;
  Timer? _surfaceTimer, _revealTimeout;

  bool _hint = false;
  Timer? _hintTimer;

  /// The chips at the bottom, up for a few seconds after each touch.
  bool _controls = false;
  Timer? _controlsTimer;
  final _clock = CelestialClock();

  /// Whether the device has a compass, for the Point at the sky chip.
  bool _compass = false;

  static const _orientation = EventChannel(
    'kiosk_satellite/orientation_stream',
  );
  static const _orientationMethods = MethodChannel(
    'kiosk_satellite/orientation',
  );

  /// The device's orientation while the view follows it.
  StreamSubscription<Object?>? _pose;

  /// The device has no compass to follow: the view stays on touch.
  bool _noCompass = false;

  /// The screen's forward and up directions, smoothed.
  SkyVector? _forward, _up;

  /// Whether the compass needs a figure eight, with the accuracies last
  /// logged and when the reading last changed side.
  bool _calibrate = false;
  String _accuracy = '';
  DateTime? _accuracySince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = Lifecycle.onScreen;
    _screenOn = c.screen.isScreenOn;
    final saved = CelestialView.decode(
      c.settings.get(defs.screensaverCelestialView),
    );
    _viewSet = saved != null;
    _view = ValueNotifier(
      saved ??
          const CelestialView(
            azimuth: 180,
            altitude: 20,
            fov: CelestialView.defaultFov,
          ),
    );
    final frozen = c.browser.renderingFrozenState;
    frozen.addListener(_dashboardFrozen);
    _surfaceTimer = Timer(const Duration(seconds: 2), _settleSurface);
    _dashboardFrozen();
    _revealTimeout = Timer(const Duration(seconds: 5), () {
      if (mounted && !_revealed) setState(() => _revealed = true);
    });
    _screen = c.bus.on<ScreenStateChanged>().listen((event) {
      if (mounted) setState(() => _screenOn = event.on);
      _syncFollow();
    });
    _location = c.bus.on<LocationChanged>().listen((_) {
      if (_place == null) _resolvePlace();
    });
    _settings = c.bus.on<SettingChanged>().listen((event) {
      if (!mounted) return;
      if (event.key == defs.screensaverCelestialView.key) {
        final view = CelestialView.decode(
          c.settings.get(defs.screensaverCelestialView),
        );
        if (view != null && _gestureStart == null && view != _view.value) {
          _view.value = view;
        }
      } else if (event.key == defs.screensaverCelestialLocation.key ||
          event.key == defs.screensaverCelestialEntity.key ||
          event.key == defs.screensaverCelestialCoordinates.key) {
        _syncFollow();
        _resolvePlace();
      } else if (event.key == defs.screensaverCelestialFollowDevice.key) {
        _syncFollow();
      } else if (event.key.startsWith('screensaver.celestial_') ||
          event.key == defs.screensaverFollowAnimationScale.key) {
        setState(() {});
      }
    });
    _resolvePlace();
    _syncFollow();
    unawaited(_checkCompass());
  }

  Future<void> _checkCompass() async {
    try {
      final result = await _orientationMethods.invokeMapMethod<String, Object?>(
        'support',
      );
      if (mounted && result?['supported'] == true) {
        setState(() => _compass = true);
      }
    } on PlatformException catch (_) {
    } on MissingPluginException catch (_) {}
  }

  /// Brings the chips up, or keeps them up, for five more seconds.
  void _touched() {
    if (!celestialControlsEnabled(c, compass: _compass && !_noCompass)) {
      return;
    }
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _controls = false);
      c.screensaver.modeControlsShown.value = false;
    });
    if (_controls) return;
    setState(() => _controls = true);
    c.screensaver.modeControlsShown.value = true;
  }

  void _resolvePlace() {
    final ask = ++_placeAsk;
    // The GPS can take half a minute for a first fix, or have none
    // indoors: the sky starts where it last was and moves with the fix.
    final last = c.celestial.lastGpsFix;
    if (_place == null &&
        last != null &&
        c.settings.get(defs.screensaverCelestialLocation) == 'gps') {
      _setPlace(last);
    }
    unawaited(
      c.celestial.resolve().then((status) {
        if (!mounted || ask != _placeAsk) return;
        final lat = status.latitude, lon = status.longitude;
        if (lat != null && lon != null) {
          _setPlace((latitude: lat, longitude: lon));
        } else {
          setState(() {
            _place = null;
            _placeProblem = status.message;
            _placeResolved = true;
          });
        }
      }),
    );
  }

  void _setPlace(CelestialPlace place) {
    if (!mounted) return;
    setState(() {
      _place = place;
      _placeResolved = true;
    });
    if (!_viewSet) {
      // Face the equator, where most of the sky turns.
      _view.value = _view.value.copyWith(
        azimuth: place.latitude >= 0 ? 180 : 0,
      );
    }
    _syncFollow();
  }

  /// The GPS source follows the device live while the sky is on screen.
  bool get _wantsLive =>
      _screenOn &&
      _foreground &&
      c.settings.get(defs.screensaverCelestialLocation) == 'gps';

  bool _watching = false;

  /// Starts or stops following the GPS, and the device's compass for Point
  /// at the sky, to match the settings, the screen and the app being in
  /// front.
  void _syncFollow() {
    if (!mounted) return;
    final live = _wantsLive;
    if (live && !_watching) {
      _watching = true;
      c.location.watchLive();
      c.location.live.addListener(_moved);
    } else if (!live && _watching) {
      _watching = false;
      c.location.live.removeListener(_moved);
      c.location.unwatchLive();
    }
    // The compass needs the position for true north.
    final pose =
        _screenOn &&
        _foreground &&
        _place != null &&
        !_noCompass &&
        c.settings.get(defs.screensaverCelestialFollowDevice);
    if (pose && _pose == null) {
      final place = _place!;
      c.screensaver.holdSensorDismiss = true;
      _pose = _orientation
          .receiveBroadcastStream({
            'latitude': place.latitude,
            'longitude': place.longitude,
          })
          .listen(
            _turned,
            onError: (Object error) {
              c.log.warn(
                'screensaver',
                'Celestial cannot follow the device: '
                    '${error is PlatformException ? error.message : error}',
              );
              _noCompass = true;
              _stopFollow();
            },
          );
    } else if (!pose && _pose != null) {
      _stopFollow();
    }
  }

  /// Stops following the device's orientation, back to touch.
  void _stopFollow({bool settle = true}) {
    final pose = _pose;
    if (pose == null) return;
    _pose = null;
    unawaited(pose.cancel());
    c.screensaver.holdSensorDismiss = false;
    _forward = _up = null;
    _accuracySince = null;
    if (_calibrate && settle) setState(() => _calibrate = false);
    if (settle) _view.value = _view.value.copyWith(clearFrame: true);
  }

  /// A new GPS fix while the view follows the device. The first one also
  /// places a sky that had no position yet.
  void _moved() {
    final fix = c.location.live.value;
    final place = _place;
    if (fix == null || !mounted) return;
    c.celestial.remember(fix.latitude, fix.longitude);
    if (place == null) {
      _placeAsk++;
      _placeProblem = null;
      _setPlace((latitude: fix.latitude, longitude: fix.longitude));
      return;
    }
    if ((fix.latitude - place.latitude).abs() < 1e-4 &&
        (fix.longitude - place.longitude).abs() < 1e-4) {
      return;
    }
    setState(() => _place = (latitude: fix.latitude, longitude: fix.longitude));
  }

  /// The screen's axes from the orientation sensor: right, up and forward,
  /// three floats each, eased so the sky does not shake in the hand.
  void _turned(Object? event) {
    if (event is! List || event.length < 9 || !mounted) return;
    final v = [for (final e in event) (e as num).toDouble()];
    if (v.length >= 11) _compassAccuracy(v[9].round(), v[10].round());
    final up = SkyVector(v[3], v[4], v[5]);
    final forward = SkyVector(v[6], v[7], v[8]);
    const ease = 0.2;
    final f = _forward == null
        ? forward
        : (_forward! + (forward - _forward!) * ease).unit;
    final u = _up == null ? up : (_up! + (up - _up!) * ease).unit;
    final right = f.cross(u).unit;
    _forward = f;
    _up = right.cross(f).unit;
    _view.value = _view.value.copyWith(frame: CelestialFrame(right, _up!, f));
  }

  void _dashboardFrozen() {
    if (!mounted || _surfaceSettled) return;
    if (c.browser.renderingFrozenState.value) {
      _surfaceTimer?.cancel();
      _surfaceTimer = Timer(const Duration(milliseconds: 250), _settleSurface);
    }
  }

  void _settleSurface() {
    if (!mounted) return;
    _surfaceSettled = true;
    _maybeReveal();
  }

  void _sceneReady() {
    if (!mounted) return;
    _sceneDone = true;
    _maybeReveal();
  }

  void _maybeReveal() {
    if (_revealed || !_sceneDone || !_surfaceSettled) return;
    setState(() => _revealed = true);
  }

  /// SensorManager accuracies, 0 (unreliable) to 3 (high). The
  /// magnetometer's calibration speaks for the compass when the device
  /// reports one; the rotation vector's own value otherwise. The note
  /// comes after a second of low accuracy and goes after two of good, so
  /// it does not flicker at the edge.
  void _compassAccuracy(int rotation, int magnetometer) {
    final text = 'rotation vector $rotation, magnetometer $magnetometer';
    if (text != _accuracy) {
      _accuracy = text;
      c.log.debug('screensaver', 'Celestial compass accuracy: $text');
    }
    final low = (magnetometer >= 0 ? magnetometer : rotation) <= 1;
    if (low == _calibrate) {
      _accuracySince = null;
      return;
    }
    final now = DateTime.now();
    final since = _accuracySince ??= now;
    final wait = low ? 1000 : 2000;
    if (now.difference(since).inMilliseconds >= wait) {
      _accuracySince = null;
      setState(() => _calibrate = low);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = !Lifecycle.offScreen(state);
    if (foreground != _foreground && mounted) {
      setState(() => _foreground = foreground);
      _syncFollow();
    }
  }

  /// Puts the horizon a fifth of the way up the screen, until someone
  /// moves the view themselves.
  void _fitDefault(Size size) {
    if (_viewSet || size.isEmpty || _pose != null) return;
    final long = math.max(size.width, size.height);
    final scale = long / (4 * math.tan(_view.value.fov * math.pi / 720));
    final below = 0.3 * size.height / scale;
    final altitude = 2 * math.atan(below / 2) * 180 / math.pi;
    if ((altitude - _view.value.altitude).abs() > 0.05) {
      _view.value = _view.value.copyWith(altitude: altitude);
    }
  }

  void _scaleStart(ScaleStartDetails details) {
    _gestureStart = _view.value;
  }

  void _scaleUpdate(ScaleUpdateDetails details, Size size) {
    final start = _gestureStart;
    if (start == null) return;
    final view = _view.value;
    // Following the device, the hand turns the view: a pinch still zooms.
    if (view.frame != null) {
      if (details.pointerCount > 1) {
        _view.value = view.copyWith(fov: start.fov / details.scale);
      }
      return;
    }
    final long = math.max(size.width, size.height);
    final degreesPerPixel = view.fov / long;
    final dx = details.focalPointDelta.dx * degreesPerPixel;
    final dy = details.focalPointDelta.dy * degreesPerPixel;
    // Near the zenith a drag sweeps more azimuth for the same distance.
    final stretch = 1 / math.max(math.cos(view.altitude * math.pi / 180), 0.3);
    _view.value = view.copyWith(
      azimuth: view.azimuth - dx * stretch,
      altitude: view.altitude + dy,
      fov: details.pointerCount > 1 ? start.fov / details.scale : null,
    );
    _viewSet = true;
  }

  void _scaleEnd(ScaleEndDetails details) {
    _gestureStart = null;
    _saveView?.cancel();
    _saveView = Timer(const Duration(milliseconds: 600), () {
      unawaited(
        c.settings.set(defs.screensaverCelestialView, _view.value.encode()),
      );
    });
  }

  /// A lone tap shows how to close the screensaver.
  void _tap() {
    _hintTimer?.cancel();
    setState(() => _hint = true);
    _hintTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopFollow(settle: false);
    if (_watching) {
      c.location.live.removeListener(_moved);
      c.location.unwatchLive();
    }
    _settings?.cancel();
    _screen?.cancel();
    _location?.cancel();
    _surfaceTimer?.cancel();
    _revealTimeout?.cancel();
    _hintTimer?.cancel();
    _controlsTimer?.cancel();
    if (_controls) c.screensaver.modeControlsShown.value = false;
    final pending = _saveView;
    if (pending != null && pending.isActive) {
      pending.cancel();
      unawaited(
        c.settings.set(defs.screensaverCelestialView, _view.value.encode()),
      );
    }
    c.browser.renderingFrozenState.removeListener(_dashboardFrozen);
    _view.dispose();
    super.dispose();
  }

  CelestialOptions get _options {
    final s = c.settings;
    return CelestialOptions(
      lines: s.get(defs.screensaverCelestialLines),
      constellationNames: s.get(defs.screensaverCelestialConstellationNames),
      objectNames: s.get(defs.screensaverCelestialNames),
      planets: s.get(defs.screensaverCelestialPlanets),
      milkyWay: s.get(defs.screensaverCelestialMilkyWay),
      deepSky: s.get(defs.screensaverCelestialDeepSky),
      twinkle: s.get(defs.screensaverCelestialTwinkle),
      daytime: s.get(defs.screensaverCelestialDaytime),
      largeMoon: s.get(defs.screensaverCelestialLargeMoon),
      compass: s.get(defs.screensaverCelestialCompass),
      terrain: s.get(defs.screensaverCelestialTerrain),
      lightPollution: (s.get(defs.screensaverCelestialLightPollution) / 100)
          .clamp(0, 1)
          .toDouble(),
      labelScale: (s.get(defs.screensaverCelestialLabelScale) / 100)
          .clamp(.5, 2)
          .toDouble(),
    );
  }

  CelestialNames _names(BuildContext context) {
    String t(String english) => screensaverText(context, english);
    return CelestialNames(
      language: appLocaleName(context).split('_').first,
      bodies: {
        SkyBody.sun: t('Sun'),
        SkyBody.moon: t('Moon'),
        SkyBody.mercury: t('Mercury'),
        SkyBody.venus: t('Venus'),
        SkyBody.mars: t('Mars'),
        SkyBody.jupiter: t('Jupiter'),
        SkyBody.saturn: t('Saturn'),
        SkyBody.uranus: t('Uranus'),
        SkyBody.neptune: t('Neptune'),
      },
      deepSky: {
        'andromedaGalaxy': t('Andromeda Galaxy'),
        'triangulumGalaxy': t('Triangulum Galaxy'),
        'largeMagellanicCloud': t('Large Magellanic Cloud'),
        'smallMagellanicCloud': t('Small Magellanic Cloud'),
        'orionNebula': t('Orion Nebula'),
        'lagoonNebula': t('Lagoon Nebula'),
        'carinaNebula': t('Carina Nebula'),
        'pleiades': t('Pleiades'),
        'beehiveCluster': t('Beehive Cluster'),
        'doubleCluster': t('Double Cluster'),
        'omegaCentauri': t('Omega Centauri'),
        'tucanae47': t('47 Tucanae'),
      },
      compass: [t('N'), t('E'), t('S'), t('W')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;
    if (place == null) {
      return ColoredBox(
        color: Colors.black,
        child: _placeResolved
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      [
                        screensaverText(
                          context,
                          'Choose a location in Settings > Screensaver > Celestial.',
                        ),
                        if (_placeProblem case final problem?)
                          screensaverError(context, problem),
                      ].join('\n'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
              )
            // A first GPS fix can take half a minute: say so rather than
            // leave the screen black.
            : c.settings.get(defs.screensaverCelestialLocation) == 'gps'
            ? Center(
                child: Text(
                  screensaverText(context, 'Waiting for a GPS fix...'),
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 15,
                    letterSpacing: .3,
                    color: Color(0x99D5DCE6),
                  ),
                ),
              )
            : const SizedBox.expand(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _fitDefault(size);
        return Listener(
          // Every finger here belongs to the sky: the kiosk's own report
          // of the touch must not wake the dashboard.
          onPointerDown: (_) {
            c.screensaver.markControlTouch();
            _touched();
          },
          onPointerMove: (_) => _touched(),
          onPointerUp: (_) => _touched(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _scaleStart,
                onScaleUpdate: (d) => _scaleUpdate(d, size),
                onScaleEnd: _scaleEnd,
                onTap: _tap,
                onDoubleTap: () =>
                    c.screensaver.notifyActivity('screensaver_touch'),
                child: CelestialRenderer(
                  latitude: place.latitude,
                  longitude: place.longitude,
                  options: _options,
                  names: _names(context),
                  view: _view,
                  // A still sky while Android's animations are off, when
                  // asked to follow them, as Weather Mood does.
                  active:
                      _screenOn &&
                      _foreground &&
                      !(c.settings.get(defs.screensaverFollowAnimationScale) &&
                          MediaQuery.disableAnimationsOf(context)),
                  lowPower: weatherMoodLowPower(c),
                  clock: _clock.now,
                  timeRate: _clock.rate,
                  timeVersion: _clock.version,
                  onReady: _sceneReady,
                  onError: (error) => c.log.warn(
                    'screensaver',
                    'Celestial renderer stopped: $error',
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _revealed ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  child: const ColoredBox(color: Colors.black),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 24,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _calibrate && _pose != null ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Center(
                      child: _Note(
                        screensaverText(
                          context,
                          'Move the device in a figure eight to calibrate '
                          'the compass.',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The hint sits over the controls, which a tap brings up
              // with it, in the same quiet type.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _hint ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          screensaverText(context, 'Double tap to close'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize:
                                13 *
                                (c.settings.get(
                                          defs.screensaverCelestialControlScale,
                                        ) /
                                        100)
                                    .clamp(.5, 2),
                            letterSpacing: .3,
                            color: const Color(0x99D5DCE6),
                            shadows: const [Shadow(blurRadius: 6)],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      ignoring: !_controls,
                      child: AnimatedOpacity(
                        opacity: _controls ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: CelestialControls(
                          container: c,
                          latitude: place.latitude,
                          longitude: place.longitude,
                          view: _view,
                          clock: _clock,
                          compass: _compass && !_noCompass,
                          visible: _controls,
                          onClock: () => setState(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A short line over the sky in a dark pill, for the compass note.
class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    ),
  );
}
