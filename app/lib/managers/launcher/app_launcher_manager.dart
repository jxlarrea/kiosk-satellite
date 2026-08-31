import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import '../wake_word/background_listening.dart';

/// One entry in the launcher whitelist: the package to open and the label
/// cached at pick time, so both UIs can name it without asking the device.
class LauncherApp {
  const LauncherApp({required this.package, required this.label});

  final String package;
  final String label;

  Map<String, Object?> toJson() => {'package': package, 'label': label};
}

/// Decode launcher.apps, dropping anything malformed rather than failing:
/// the setting is written by the pickers but can arrive over the API.
List<LauncherApp> decodeLauncherApps(String json) {
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map && '${item['package'] ?? ''}'.trim().isNotEmpty)
          LauncherApp(
            package: '${item['package']}'.trim(),
            label: '${item['label'] ?? item['package']}',
          ),
    ];
  } catch (_) {
    return const [];
  }
}

/// The minimal app launcher (issue #114): a whitelisted set of installed
/// apps the kiosk can open, and the clock that brings the kiosk back.
///
/// The overlay itself is AppLauncherOverlay in the kiosk screen's stack;
/// this manager owns its visibility, the installed-apps enumeration the
/// pickers read, the icon cache, and auto-return: after any launchApp
/// (this launcher, a gesture, MQTT), an armed timer calls bringToFront
/// once the configured time has passed with the app still backgrounded
/// and untouched. The "untouched" comes from a native touch watch window
/// (TouchWatchOverlay, issue #317) that reports every touch in the other
/// app; each one restarts the clock, so the return only ever interrupts
/// an app nobody is using. Where the watch cannot be put up the clock
/// runs plain, which is what it always did.
class AppLauncherManager extends Manager with WidgetsBindingObserver {
  AppLauncherManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  static const _channel = MethodChannel('kiosk_satellite/background');

  /// Whether the launcher overlay is up. The overlay widget listens.
  final visible = ValueNotifier<bool>(false);

  /// PNG bytes per package, null cached too (missing app, no icon). Cleared
  /// never: icons are stable and the set is bounded by the whitelist.
  final _icons = <String, Uint8List?>{};

  StreamSubscription<AppLaunched>? _launchSub;
  StreamSubscription<SettingChanged>? _settingSub;
  StreamSubscription<ScreensaverStateChanged>? _saverSub;
  Timer? _returnTimer;

  /// Set by [AppLaunched] and consumed by the pause that follows it. The
  /// window keeps an old launch from arming a return on some unrelated
  /// background trip minutes later (the drawer, a permission screen).
  DateTime? _launchedAt;
  static const _armWindow = Duration(seconds: 15);

  /// Whether the native touch watch is up for the current arm; false also
  /// while nothing is armed. Read by the tests and the logs.
  bool watchingTouches = false;

  @override
  String get name => 'launcher';

  /// The configured whitelist, decoded fresh so setting changes apply live.
  List<LauncherApp> get apps =>
      decodeLauncherApps(_settings.get(defs.launcherApps));

  @override
  Future<void> init() async {
    commands.register(
      Command(
        name: 'installedApps',
        description:
            'Every launchable app on the device, alphabetical: '
            '[{package, label}]. What the whitelist pickers choose from.',
        handler: (_) async {
          try {
            final raw = await _channel.invokeMethod<List<Object?>>('listApps');
            return CommandResult.ok([
              for (final item in raw ?? const [])
                if (item is Map)
                  {
                    'package': '${item['package']}',
                    'label': '${item['label']}',
                  },
            ]);
          } on MissingPluginException {
            return const CommandResult.fail('listing apps is Android-only');
          } on PlatformException catch (e) {
            return CommandResult.fail('could not list apps: $e');
          }
        },
      ),
    );

    commands.register(
      Command(
        name: 'foregroundApp',
        description:
            'The app on screen right now: {package, label}. Naming other '
            'apps needs the Usage access grant; without it the answer is '
            'this app while it is frontmost and {package: null} otherwise.',
        handler: (_) async {
          try {
            final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
              'foregroundApp',
            );
            if (raw != null) {
              return CommandResult.ok({
                'package': '${raw['package']}',
                'label': '${raw['label']}',
              });
            }
          } on MissingPluginException {
            // Not Android; fall through to what the lifecycle knows.
          } on PlatformException catch (e) {
            log.warn(name, 'foregroundApp failed: $e');
          }
          // No grant (or no usage event yet): the one app we can still
          // vouch for is ourselves, while resumed.
          final resumed =
              WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed;
          return CommandResult.ok({
            'package': resumed ? 'me.jxl.kiosk_satellite' : null,
            'label': resumed ? 'Kiosk Satellite' : null,
          });
        },
      ),
    );

    commands.register(
      Command(
        name: 'showAppLauncher',
        description:
            'Open the app launcher overlay. Fails when no apps are '
            'configured, so a caller can say so instead of showing nothing.',
        handler: (_) async {
          // The master switch is a hard gate for every opener — the menu
          // checks it itself, and MQTT and the remote API both land here.
          if (!_settings.get(defs.launcherEnabled)) {
            return const CommandResult.fail('the app launcher is disabled');
          }
          if (apps.isEmpty) {
            return const CommandResult.fail('no launcher apps configured');
          }
          // Same choreography as a camera view: an MQTT open must land on a
          // lit, frontmost kiosk, not behind a dark panel or screensaver.
          await commands.execute('screenOn', const {});
          await commands.execute('bringToFront', const {});
          await commands.execute('stopScreensaver', const {});
          visible.value = true;
          return const CommandResult.ok();
        },
      ),
    );

    commands.register(
      Command(
        name: 'hideAppLauncher',
        description: 'Close the app launcher overlay.',
        handler: (_) async {
          visible.value = false;
          return const CommandResult.ok();
        },
      ),
    );

    _launchSub = bus.on<AppLaunched>().listen((_) {
      _launchedAt = DateTime.now();
      // The overlay's job ended the moment another app came up over it.
      visible.value = false;
    });

    // An abandoned launcher gives way to the screensaver rather than
    // greeting whoever walks past at 3am.
    _saverSub = bus.on<ScreensaverStateChanged>().listen((e) {
      if (e.active) visible.value = false;
    });

    // Auto-return rides on bringToFront, which Android 10+ only honors
    // with the draw-over-apps grant: send the grant screen when the switch
    // goes on without it, the same dance as restartApp and the status-bar
    // shield.
    _settingSub = bus.on<SettingChanged>().listen((e) async {
      // Turning the launcher off closes an overlay already on screen.
      if (e.key == defs.launcherEnabled.key && e.value != true) {
        visible.value = false;
        return;
      }
      // A changed whitelist warms its icons right away, so the next open
      // never waits on them.
      if (e.key == defs.launcherApps.key) {
        warmIcons();
        return;
      }
      if (e.key != defs.launcherAutoReturn.key || e.value != true) return;
      try {
        final can =
            await _channel.invokeMethod<bool>('canBringToFront') ?? false;
        if (!can) {
          unawaited(
            commands.execute('requestOsPermissions', {
              'which': ['overlay'],
            }),
          );
        }
      } on MissingPluginException {
        // Not Android; nothing to grant.
      } on PlatformException catch (e) {
        log.warn(name, 'overlay grant check failed: $e');
      }
    });

    if (Platform.isAndroid) WidgetsBinding.instance.addObserver(this);
    BackgroundListening.onTouchSeen = touchSeen;

    // The whitelist is small and icons are immutable: warm them at boot
    // so the launcher's very first open paints complete.
    if (_settings.get(defs.launcherEnabled)) warmIcons();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final launched = _launchedAt;
      // Both flags at runtime: the stored auto-return switch survives the
      // master switch going off, and must not act while it is.
      if (launched == null ||
          DateTime.now().difference(launched) > _armWindow ||
          !_settings.get(defs.launcherEnabled) ||
          !_settings.get(defs.launcherAutoReturn)) {
        return;
      }
      final seconds = _settings.get(defs.launcherAutoReturnSeconds).toInt();
      log.info(name, 'auto-return armed: ${seconds}s idle');
      _startClock(seconds);
      unawaited(_watchTouches(true));
    } else if (state == AppLifecycleState.resumed) {
      _disarm();
      _launchedAt = null;
    }
  }

  /// (Re)start the idle clock. Armed once on pause, and again on every
  /// touch the watch reports, so the return only fires after [seconds]
  /// with nobody touching the other app.
  void _startClock(int seconds) {
    _returnTimer?.cancel();
    _returnTimer = Timer(Duration(seconds: seconds), () async {
      _returnTimer = null;
      unawaited(_watchTouches(false));
      // The state may have moved since the timer was set; only pull the
      // kiosk forward if it is genuinely still behind the other app.
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        return;
      }
      log.info(name, 'auto-return: bringing the kiosk back');
      final result = await commands.execute('bringToFront', const {});
      if (result.data == false) {
        log.warn(name, 'auto-return needs the draw-over-apps grant');
      }
    });
  }

  void _disarm() {
    if (_returnTimer == null && !watchingTouches) return;
    _returnTimer?.cancel();
    _returnTimer = null;
    unawaited(_watchTouches(false));
  }

  /// The native touch watch's report (issue #317): someone is using the
  /// other app, so the idle clock starts over. Public because it is the
  /// channel callback; ignored while nothing is armed.
  void touchSeen() {
    if (_returnTimer == null) return;
    final seconds = _settings.get(defs.launcherAutoReturnSeconds).toInt();
    log.debug(name, 'auto-return: touch in the other app, ${seconds}s again');
    _startClock(seconds);
  }

  Future<void> _watchTouches(bool on) async {
    try {
      final up =
          await _channel.invokeMethod<bool>('watchTouches', {'on': on}) ??
          false;
      watchingTouches = on && up;
      if (on && !up) {
        // No grant, or an app that hides overlays: the clock runs plain,
        // as it did before the watch existed.
        log.warn(
          name,
          'auto-return: touches in the other app cannot be seen '
          '(draw-over-apps grant missing?), returning after the time '
          'regardless',
        );
      }
    } on MissingPluginException {
      watchingTouches = false;
    } on PlatformException catch (e) {
      watchingTouches = false;
      log.warn(name, 'touch watch failed: $e');
    }
  }

  /// The cached icon without a channel round trip, for the overlay's
  /// synchronous first frame; [hasIcon] tells a missing app's cached null
  /// from a fetch that has not happened yet.
  Uint8List? cachedIcon(String package) => _icons[package];
  bool hasIcon(String package) => _icons.containsKey(package);

  /// Fetch every whitelisted icon into the cache ahead of need, so the
  /// launcher's first open paints its tiles in one frame instead of
  /// flashing placeholders while each icon loads.
  void warmIcons() {
    for (final app in apps) {
      if (!_icons.containsKey(app.package)) unawaited(icon(app.package));
    }
  }

  /// The launcher icon for [package] as PNG bytes, memoized. Null when the
  /// app is gone or the platform cannot render one.
  Future<Uint8List?> icon(String package) async {
    if (_icons.containsKey(package)) return _icons[package];
    Uint8List? bytes;
    try {
      // Typed by hand rather than through invokeMethod's cast: an answer
      // of the wrong shape means no icon, never a throw out of a warm-up.
      final raw = await _channel.invokeMethod<Object?>('appIcon', {
        'package': package,
      });
      bytes = raw is Uint8List ? raw : null;
    } on MissingPluginException {
      bytes = null;
    } on PlatformException catch (e) {
      log.warn(name, 'icon for $package failed: $e');
      bytes = null;
    }
    _icons[package] = bytes;
    return bytes;
  }

  @override
  Future<void> dispose() async {
    if (Platform.isAndroid) WidgetsBinding.instance.removeObserver(this);
    BackgroundListening.onTouchSeen = null;
    _disarm();
    await _launchSub?.cancel();
    await _settingSub?.cancel();
    await _saverSub?.cancel();
    _returnTimer?.cancel();
    visible.dispose();
  }
}
