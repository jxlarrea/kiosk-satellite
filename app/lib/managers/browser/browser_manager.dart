import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/widgets.dart'
    show AppLifecycleState, WidgetsBinding, WidgetsBindingObserver;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'color_scheme_script.dart';
import 'content_insets_script.dart';
import 'no_cache_script.dart';
import 'url_filter.dart';
import 'dashboard_camera_script.dart';
import 'dashboard_state.dart';
import 'visibility_mask_script.dart';
import 'webview_snapshot_width.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../analytics/usage_counters.dart';
import '../device/device_details.dart';
import '../device/screen_capture.dart';
import '../device/webview_freeze.dart';
import '../device/webview_recovery.dart';
import '../home_assistant/custom_pages.dart';
import '../sendspin/music_assistant_api.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'package:kiosk_satellite/core/lifecycle.dart';

/// One line of the page's JavaScript console.
class ConsoleEntry {
  ConsoleEntry(this.time, this.level, this.message);

  final DateTime time;

  /// 'log' | 'debug' | 'warn' | 'error' | 'tip'
  final String level;
  final String message;
}

/// Whether loading [target] over [current] leaves the document in place.
/// Chromium treats a load of a URL with a fragment over that same URL as a
/// jump to the fragment, not a new document. The WebView plugin cancels every
/// navigation it is asked about and issues it again as such a load, so a
/// page's own `location.reload()` ends up here too.
bool _loadKeepsDocument(String target, String current) =>
    target == current && target.contains('#');

/// WebView lifecycle: navigation, current URL, error recovery, screenshots.
///
/// The manager does not build the widget — the UI layer owns the
/// [InAppWebView] and calls [attach] from `onWebViewCreated`. Everything else
/// (commands, events) flows through the attached controller.
class BrowserManager extends Manager with WidgetsBindingObserver {
  BrowserManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'browser';

  InAppWebViewController? _controller;
  String _currentUrl = '';

  String get currentUrl => _currentUrl;

  /// The URL of the document in the dashboard WebView right now, as the
  /// WebView reports it. [currentUrl] only moves when a load finishes, and
  /// a page's own scripts run before that.
  Future<String> liveUrl() async {
    try {
      final url = await _controller?.getUrl();
      if (url != null) return url.toString();
    } catch (_) {}
    return _currentUrl;
  }

  /// Whether a live WebView is attached. A configured, foregrounded kiosk
  /// always has one; the frame watchdog treats its prolonged absence as
  /// the wedged-renderer signal.
  bool get hasWebView => _controller != null;

  /// Whether this device has no WebView provider at all. A ROM without
  /// Android System WebView (a repurposed smart display, a stripped
  /// tablet) can never show a dashboard, and the frame watchdog's answer
  /// to "no WebView while in front" is a process restart: one such device
  /// restarted every 37 seconds for hours, straight through an update.
  /// Learned from the platform where it can say (API 26+), or from the
  /// MissingWebViewPackageException the platform view creation throws.
  bool get webViewMissing => _webViewMissing;
  bool _webViewMissing = false;

  void markWebViewMissing(String why) {
    if (_webViewMissing) return;
    _webViewMissing = true;
    log.error(
      name,
      'no WebView provider is installed ($why): the dashboard cannot be '
      'shown and restarts would not help',
    );
    bus.publish(const WebViewMissing());
  }

  /// A provider that is installed but failed to start: the creation threw
  /// AndroidRuntimeException around an InvocationTargetException. Seen
  /// while Android System WebView updates itself (over in a minute) and
  /// on a board whose WebView build does not run at all. The watchdog's
  /// restart every minute changes nothing either way, so the dashboard
  /// slot shows the WebView notice and the build is tried again after
  /// [retryAfter]; a provider that came good takes over on that retry, a
  /// broken one lands here again for another wait.
  Timer? _webViewRetry;

  void markWebViewBroken(
    String why, {
    Duration retryAfter = const Duration(minutes: 5),
  }) {
    if (_webViewMissing) return;
    _webViewMissing = true;
    log.error(
      name,
      'the WebView provider failed to start ($why): the dashboard cannot '
      'be shown; trying again in ${retryAfter.inMinutes} minutes',
    );
    bus.publish(const WebViewMissing());
    _webViewRetry?.cancel();
    _webViewRetry = Timer(retryAfter, () {
      _webViewRetry = null;
      _webViewMissing = false;
      log.info(name, 'retrying the WebView after the provider failure');
      bus.publish(const WebViewMissing());
    });
  }

  Future<void> _probeWebView() async {
    final details = await DeviceDetails.read();
    if (details.webviewAvailable == false) {
      markWebViewMissing('Android reports no WebView package');
    }
  }

  /// JavaScript console ring buffer for the Web Console panel. Bumping
  /// [consoleRevision] notifies listeners of new entries.
  static const _consoleCapacity = 300;
  final List<ConsoleEntry> consoleEntries = [];
  final ValueNotifier<int> consoleRevision = ValueNotifier(0);

  String get startUrl => _settings.get(defs.startUrl);

  /// External page shown OVER the dashboard during its rotation slot (null
  /// when none). The kiosk screen builds and tears down an overlay WebView
  /// from this; the dashboard underneath stays loaded, so the Voice
  /// Satellite session and the wake word never pay for the excursion.
  final ValueNotifier<String?> overlayUrl = ValueNotifier(null);

  /// Whether the current overlay carries its own close button. Rotation
  /// overlays do not (the rotation moves on by itself); an overlay opened by
  /// tapping a dashboard link does — a close control and the back button are
  /// the only ways back from it.
  final ValueNotifier<bool> overlayDismissible = ValueNotifier(false);

  /// Show a dashboard link's target over the dashboard (issue #86). Letting
  /// the link replace the dashboard page fires pagehide: the Voice Satellite
  /// session tears down, the wake word dies with it, and the entities drop
  /// unavailable. The overlay gives the tap the same fullscreen page while
  /// the dashboard — and everything living in it — stays loaded underneath.
  void showLinkOverlay(String url, {bool hold = false}) {
    log.info(name, 'link opens over the dashboard: $url');
    // Hold mode for the page's stay (the open_url action's hold_mode):
    // engaged here, released when the page goes, whichever way it goes.
    // A hold the user already had on is theirs and stays.
    if (hold && !_settings.get(defs.haHoldMode)) {
      _overlayHold = true;
      unawaited(_settings.set(defs.haHoldMode, true));
    }
    overlayDismissible.value = true;
    overlayUrl.value = url;
  }

  /// Whether the overlay up now turned hold mode on for its stay.
  bool _overlayHold = false;

  /// Drop the overlay, whoever put it up.
  void dismissOverlay() {
    overlayDismissible.value = false;
    overlayUrl.value = null;
  }

  /// Whether [url] belongs to the dashboard's own web origin — the page
  /// currently loaded (its proxied loopback form when the secure context
  /// proxy is on) or the configured start URL. Navigations inside these keep
  /// the main WebView; anything else is an external link.
  bool isDashboardOrigin(Uri url) {
    bool sameOrigin(String other) {
      final uri = Uri.tryParse(other);
      return uri != null &&
          uri.hasScheme &&
          uri.scheme == url.scheme &&
          uri.host == url.host &&
          uri.port == url.port;
    }

    return sameOrigin(_currentUrl) || sameOrigin(startUrl);
  }

  /// Whether [url] is served by this Home Assistant — the dashboard's own
  /// origin, or the configured base URL's. The second is what the dashboard
  /// origin is not when the secure context proxy is on: the page runs on
  /// loopback, while a screensaver or link URL names the real host.
  bool isHomeAssistantOrigin(Uri url) {
    // A custom page on another server can be the page on screen, which
    // makes it the dashboard's origin for links, but it never gets Home
    // Assistant's session.
    if (isCustomPageOrigin(url)) return false;
    if (isDashboardOrigin(url)) return true;
    final base = Uri.tryParse(_settings.get(defs.haUrl).trim());
    return base != null &&
        base.hasScheme &&
        base.scheme == url.scheme &&
        base.host == url.host &&
        base.port == url.port;
  }

  /// The Home Assistant session the dashboard is signed in with, as the
  /// frontend keeps it (localStorage `hassTokens`), or null before the
  /// dashboard has loaded one. Re-read on every dashboard load, so a
  /// refreshed or re-authenticated session is the one that gets shared.
  ///
  /// External WebViews seed themselves from this (see ha_session_script.dart).
  String? get haSession => _haSession;
  String? _haSession;

  Future<void> _captureHaSession() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      final value = await controller.evaluateJavascript(
        source: "localStorage.getItem('hassTokens')",
      );
      if (value is String && value.trim().isNotEmpty) _haSession = value;
    } catch (_) {
      // A page that denies storage access (or none loaded yet): nothing to
      // share, and the previous session stays as it was.
    }
  }

  @override
  Future<void> init() async {
    unawaited(_probeWebView());
    // The freeze state rides the Activity: see _reassertFreeze.
    WidgetsBinding.instance.addObserver(this);
    // Rendering freeze (browser.freeze_on_screensaver): while the screensaver
    // covers the dashboard, Chromium keeps compositing at full rate — the
    // occlusion lives in Flutter's layer tree, which Android knows nothing
    // about. Hiding the native view (WebViewFreeze) stops that: the page
    // drops to ordinary hidden-document behavior, where rendering halts but
    // timers, events and the websocket all keep running. WebView.onPause()
    // is deliberately not used — it suspends the page's task queues
    // wholesale, so the unread HA socket gets dropped by the server as a
    // slow consumer within minutes (and a dormant page would miss Voice
    // Satellite announcements and timer alerts anyway).
    //
    // Hiding is further gated on an overlay actually covering the dashboard:
    // the Dim screensaver shows none — the page IS its display — so freezing
    // there blanks the screen (issue #82). Coverage arrives on its own event
    // because it can flip mid-session (a schedule boundary swapping Dim for
    // a content mode, or the Now Playing takeover).
    bus.on<ScreensaverStateChanged>().listen((e) {
      _screensaverActive = e.active;
      // A page someone opened and walked away from gives way to the
      // screensaver, exactly as an abandoned app launcher does: what
      // returns when the screensaver lifts is the dashboard, not a
      // stranger's half-browsed album page. It also stops that page
      // rendering behind the screensaver, which the dashboard freeze
      // cannot do for it (it hides the dashboard's origin, not this).
      //
      // Only the dismissible kind — a rotation excursion belongs to the
      // rotation, which moves it along and pauses under the screensaver
      // on its own.
      if (e.active && overlayDismissible.value) {
        log.info(name, 'screensaver takes over from the overlay page');
        dismissOverlay();
      }
      _scheduleFreezeSync();
    });
    // The native voice overlay draws over the dashboard, which shows
    // through its backdrop: the page is paused (its own onPause, which
    // stops its scripts, animations and video) and keeps its last frame on
    // screen, instead of repainting under every overlay frame.
    // Docked, it is a bubble and the page stays live under it.
    bus.on<AssistOverlayVisibility>().listen((e) {
      if (e.covers == _underAssist) return;
      _underAssist = e.covers;
      unawaited(_syncAssistPause());
    });
    bus.on<ScreensaverViewChanged>().listen((e) {
      // The Home Assistant Dashboard screensaver's layer is clear: like
      // Dim, the page IS the display, so it is neither frozen nor stripped
      // of its camera streams. So is Dim's own beside a shared player.
      final covers = e.view != null && e.view != 'dashboard' && e.view != 'dim';
      _screensaverHasOverlay = covers;
      _dashboardCovered = covers && !_screensaverIsOwnOrigin(e.view);
      _scheduleFreezeSync();
    });
    // When the panel last woke, for the screenshot command: a capture
    // racing a fresh wake lands before the first real redraw and comes
    // back all black, so it waits the transition out (see the handler).
    bus.on<ScreenStateChanged>().listen((e) {
      if (e.on) _screenOnAt = DateTime.now();
      _screenIsOn = e.on;
      // Renderer timeouts only count two in a row on a lit panel (see
      // _checkDashboardHealth), so either edge starts the count over.
      _rendererDeadChecks = 0;
      _unresponsiveStrikes = 0;
      // The freeze follows the panel: thaw when it powers off (see
      // _wantFrozen for why a frozen page cannot survive a dark panel),
      // freeze again when it lights back up under a screensaver.
      _scheduleFreezeSync();
    });
    // An overlay page is an opaque full-screen surface over the dashboard —
    // a tapped link, a rotation excursion, the Music Assistant shortcut — so
    // it reports itself like the camera view and DLNA media do and the
    // dashboard stops compositing underneath it. The page on top gets the
    // whole frame budget, and the page below keeps its timers, its socket
    // and its JS: hiding the native view is not onPause.
    //
    // Not for an overlay on the dashboard's OWN origin: the native side
    // finds views by URL prefix, so it cannot tell the two apart and would
    // blank the overlay along with the page under it.
    overlayUrl.addListener(() {
      final url = overlayUrl.value;
      final uri = url == null ? null : Uri.tryParse(url);
      setCovered(
        'overlay page',
        covered: uri != null && uri.hasScheme && !isDashboardOrigin(uri),
      );
      // The page that engaged hold mode is gone: let the hold go with it,
      // unless something released it in the meantime.
      if (url == null && _overlayHold) {
        _overlayHold = false;
        if (_settings.get(defs.haHoldMode)) {
          log.info(name, 'the page is gone; hold mode released with it');
          unawaited(_settings.set(defs.haHoldMode, false));
        }
      }
    });
    // A hold released by anyone else (the switch, the drawer notice, the
    // auto-release timer) is no longer the page's to release.
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haHoldMode.key && e.value == false) {
        _overlayHold = false;
      }
    });
    // The network came back from an outage: check what the page actually is
    // and repair it now, instead of leaving it to timers that may sit for
    // minutes (the HA shell's own retry countdown) or never fire at all (a
    // half-open socket on a kiosk that never backgrounds).
    bus.on<NetworkStateChanged>().listen((e) {
      if (e.up) unawaited(onNetworkAvailable());
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.haUrl.key) unawaited(_migrateStartUrlOrigin(e));
    });
    bus.on<SettingChanged>().listen((e) {
      // The start page is one of the allow list's exemptions.
      if (e.key == defs.browserUrlFilter.key || e.key == defs.startUrl.key) {
        unawaited(_applyUrlFilter());
      }
    });
    bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.pauseDashboardCameras.key) {
        _scheduleDashboardCameraSync();
      }
      if (e.key != defs.freezeOnScreensaver.key) return;
      // A paused page reports itself hidden, and Home Assistant suspends a
      // hidden page's connection after a few minutes — so freezing requires
      // the suspend-disabling script (its own change triggers the usual
      // WebView rebuild).
      if (e.value == true && !_settings.get(defs.disableSuspend)) {
        unawaited(_settings.set(defs.disableSuspend, true));
      }
      unawaited(_syncFreeze());
    });
    commands
      ..register(
        Command(
          name: 'getDashboardState',
          description:
              'Read configured dashboard and current main WebView URLs without credentials, queries or fragments',
          handler: (_) async => CommandResult.ok(
            DashboardState.fromUrls(
              homeAssistantUrl: _settings.get(defs.haUrl),
              startUrl: startUrl,
              currentUrl: currentUrl,
            ),
          ),
        ),
      )
      ..register(
        Command(
          name: 'unfreezeRendering',
          description:
              'Restore the dashboard WebView rendering paused under the '
              'screensaver (the screensaver runs this before lifting its '
              'overlay, so the page is drawing again by the time it shows)',
          handler: (_) async {
            _screensaverActive = false;
            _freezeDelay?.cancel();
            await _syncFreeze();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'saveUrlFilterRule',
          description:
              'Add a URL Filter rule or change one. Backs Save in the URL '
              'Filter editors on both settings surfaces. Fails with name, '
              'pattern or regex when that field is not usable.',
          params: const {
            'name': 'the name the list and the blocked notice show',
            'pattern': 'a wildcard pattern or a regular expression',
            'type': 'wildcard (default) or regex',
            'scope': 'all (default), dashboard or external',
            'action':
                'block (default), or allow to let only matching addresses '
                'open where the rule applies',
            'index':
                'optional: the position of the rule being changed, absent '
                'for a new one',
          },
          handler: (p) async {
            final rule = UrlFilterRule(
              name: '${p['name'] ?? ''}'.trim(),
              pattern: '${p['pattern'] ?? ''}'.trim(),
              type: urlFilterTypes.contains(p['type'])
                  ? p['type'] as String
                  : urlFilterWildcard,
              scope: urlFilterScopes.contains(p['scope'])
                  ? p['scope'] as String
                  : urlFilterAll,
              action: urlFilterActions.contains(p['action'])
                  ? p['action'] as String
                  : urlFilterBlock,
            );
            final error = urlFilterRuleError(rule);
            if (error != null) return CommandResult.fail(error);
            final rules = [...urlFilter];
            final index = p['index'] is num ? (p['index'] as num).toInt() : -1;
            if (index >= 0 && index < rules.length) {
              rules[index] = rule;
            } else {
              rules.add(rule);
            }
            await _settings.setFromJson(
              defs.browserUrlFilter.key,
              encodeUrlFilter(rules),
            );
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'removeUrlFilterRule',
          description: 'Remove a URL Filter rule.',
          params: const {'index': 'the position of the rule in the list'},
          handler: (p) async {
            final rules = [...urlFilter];
            final index = p['index'] is num ? (p['index'] as num).toInt() : -1;
            if (index < 0 || index >= rules.length) {
              return const CommandResult.fail('no such rule');
            }
            rules.removeAt(index);
            await _settings.setFromJson(
              defs.browserUrlFilter.key,
              encodeUrlFilter(rules),
            );
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'showOverlayPage',
          description:
              'Show an external page in an overlay WebView above the '
              'dashboard (used by the view rotation for external URLs)',
          params: const {'url': 'Absolute URL to show'},
          handler: (p) async {
            final url = p['url'] as String?;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail('url required');
            }
            overlayDismissible.value = false;
            overlayUrl.value = url;
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'showLinkPage',
          description:
              'Show an external page in the overlay WebView with its close '
              'button, the same surface a tapped dashboard link gets (used '
              'by gesture actions, issue #99)',
          params: const {
            'url': 'Absolute URL to show',
            'hold':
                'true turns hold mode on for the page and off again when '
                'the page goes; a hold already on is left alone',
          },
          handler: (p) async {
            final url = p['url'] as String?;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail('url required');
            }
            showLinkOverlay(url, hold: p['hold'] == true);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'showMusicAssistant',
          description:
              'Show the Music Assistant web interface over the dashboard, '
              'waking the screen first — the remote face of the kiosk menu '
              'entry. Fails when no server address is configured.',
          handler: (_) async {
            final url = musicAssistantWebUrl(
              _settings.get(defs.sendspinMaUrl),
              // The same landing the kiosk menu entry uses: the followed
              // remote player, or this device's own.
              player: maLandingPlayer(
                remotePlayerName: maFollowedPlayerName(_settings),
                localPlayerName: _settings.get(defs.sendspinLocalPlayerName),
                localPlayerEnabled: _settings.get(defs.sendspinEnabled),
              ),
              fullscreen: _settings.get(defs.sendspinMaOpenFullscreen),
            );
            if (url == null) {
              return const CommandResult.fail(
                'no Music Assistant server address configured',
              );
            }
            // Same wake-up a camera view gets: pressed from Home Assistant
            // the device may be dark, backgrounded, or on the screensaver,
            // and the page must land somewhere visible.
            await commands.execute('screenOn', const {});
            await commands.execute('bringToFront', const {});
            await commands.execute('stopScreensaver', const {});
            showLinkOverlay(url);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'hideOverlayPage',
          description:
              'Dismiss the overlay page and reveal the dashboard again',
          handler: (_) async {
            dismissOverlay();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'loadUrl',
          description: 'Navigate to a URL',
          params: const {'url': 'Absolute URL to load'},
          handler: (p) async {
            final url = p['url'] as String?;
            if (url == null || url.isEmpty) {
              return const CommandResult.fail('url required');
            }
            await loadUrl(url);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'loadDashboard',
          description: 'Navigate to a Home Assistant dashboard',
          params: const {'dashboard': 'Dashboard url_path, e.g. lovelace'},
          handler: (p) async {
            final dashboard = p['dashboard'] as String?;
            final base = _settings.get(defs.haUrl);
            if (dashboard == null || base.isEmpty) {
              return const CommandResult.fail(
                'dashboard required and Home Assistant URL must be configured',
              );
            }
            await loadUrl('${_stripSlash(base)}/$dashboard');
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'loadStartUrl',
          description:
              "Navigate back to the configured Start URL, the device's own "
              'dashboard (discussion #110). Unlike reload, this leaves '
              'whatever page is currently shown.',
          handler: (_) async {
            final target = _settings.get(defs.startUrl);
            if (target.isEmpty) {
              return const CommandResult.fail('no Start URL configured');
            }
            // Nobody touched the screen, so without this the next rotation
            // tick navigates straight back off the page (issue #719).
            await commands.execute('haPauseRotation', const {});
            await loadUrl(target);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'getLocalStorage',
          description:
              "The page's localStorage as a JSON string (current origin).",
          handler: (_) async {
            final controller = _controller;
            if (controller == null) {
              return const CommandResult.fail('no page loaded');
            }
            final result = await controller.evaluateJavascript(
              source: 'JSON.stringify(localStorage)',
            );
            if (result is! String) {
              return const CommandResult.fail('localStorage unavailable');
            }
            return CommandResult.ok(result);
          },
        ),
      )
      ..register(
        Command(
          name: 'setLocalStorage',
          description:
              'Write entries into the page\'s localStorage (applied on the '
              'next page load if none is up yet), then reload.',
          params: const {'data': 'JSON object string of key/value pairs'},
          handler: (p) async {
            final data = p['data'];
            if (data is! String || data.isEmpty) {
              return const CommandResult.fail('data must be a JSON string');
            }
            await _settings.setInternal('pending_local_storage', data);
            if (_currentUrl.isNotEmpty) await _applyPendingLocalStorage();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'reload',
          description: 'Reload the current page',
          handler: (_) async {
            // A custom page reloads its edited files too, not the copies
            // Home Assistant's service worker kept.
            if (isCustomPage(_currentUrl)) await _dropCustomPageCopies();
            await _controller?.reload();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'resumeWebTimers',
          description:
              'Resume the WebView JavaScript timers (diagnostic: WebView '
              'suspends them globally while the app has no visible window)',
          handler: (_) async {
            await _controller?.resumeTimers();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'ensureHaConnected',
          description:
              'Reconnect the Home Assistant websocket if it is down and wait '
              'until it is live again, before a wake interaction runs on it',
          handler: (_) async {
            final ok = await ensureHaConnected();
            return ok
                ? const CommandResult.ok()
                : const CommandResult.fail('HA socket not live');
          },
        ),
      )
      ..register(
        Command(
          name: 'getConsole',
          description: 'Current JavaScript console buffer',
          handler: (_) async => CommandResult.ok([
            for (final e in consoleEntries)
              {
                'level': e.level,
                'message': e.message,
                'time': e.time.millisecondsSinceEpoch,
              },
          ]),
        ),
      )
      ..register(
        Command(
          name: 'clearConsole',
          description: 'Clear the JavaScript console buffer',
          handler: (_) async {
            clearConsole();
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'evalJs',
          description: 'Evaluate JavaScript in the page and return the result',
          params: const {'code': 'JavaScript source'},
          handler: (p) async {
            final code = p['code'] as String?;
            final controller = _controller;
            if (code == null || (controller == null && evalOverride == null)) {
              return const CommandResult.fail('code required / no webview');
            }
            final result = await _eval(code).timeout(javaScriptTimeout);
            return CommandResult.ok('$result');
          },
        ),
      )
      ..register(
        Command(
          name: 'clearWebCache',
          description:
              'Drop the HTTP cache, Cache Storage and any service worker, then '
              'reload, so a redeployed dashboard or card is picked up. Keeps '
              'localStorage and cookies (you stay logged in).',
          handler: (_) async {
            // NOT WebStorageManager.deleteAllData(): that would wipe
            // localStorage, and pages keep real config there (the Voice
            // Satellite card stores its per-browser satellite settings).
            await InAppWebViewController.clearAllCache();
            await runJs(clearWebCacheScript); // SW + Cache Storage, then reload
            log.info(name, 'web cache cleared (localStorage preserved)');
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'logout',
          description:
              'Clear cookies and web storage, then reload the start URL',
          handler: (_) async {
            await CookieManager.instance().deleteAllCookies();
            await WebStorageManager.instance().deleteAllData();
            await InAppWebViewController.clearAllCache();
            if (startUrl.isNotEmpty) await loadUrl(startUrl);
            return const CommandResult.ok();
          },
        ),
      )
      ..register(
        Command(
          name: 'screenshot',
          description:
              'Capture the screen as a base64 JPEG of what the display shows: '
              'page, menus, screensaver. `quality` 1-100 (default 60); `width` '
              'scales the capture down (default 720).',
          params: const {
            'quality': 'JPEG quality 1-100, default 80',
            'width': 'scale the capture to this width, default 1280',
          },
          handler: (p) async {
            // Generous defaults: captures are one-shot (the dashboard has no
            // auto-refresh), so quality can win over bandwidth.
            final quality = ((p['quality'] as num?)?.toInt() ?? 80).clamp(
              1,
              100,
            );
            final width = (p['width'] as num?)?.toInt() ?? 1280;
            // A capture can race the panel: asked the instant a dismiss
            // wakes the screen (the admin overview refreshes its preview on
            // dismiss), the logical state already says on but the first
            // composited frame is still a few hundred ms out, so both
            // capture paths come up empty. Brief retries cover that
            // transition; a panel that is (still) off short-circuits to the
            // placeholder on the first check, paying nothing.
            InAppWebViewController? controller;
            const attempts = 4;
            for (var attempt = 1; attempt <= attempts; attempt++) {
              // A truly dark panel composites no frames, so there is
              // nothing real to copy: PixelCopy fails or hands back a
              // half-drawn page depending on the Android version. A
              // generated "Screen off" card is the honest picture of the
              // display.
              final on = await commands.execute('isScreenOn', const {});
              if (on.ok && on.data == false) {
                return CommandResult.ok(
                  base64Encode(await screenOffPlaceholder(width: width)),
                );
              }
              // A panel that JUST woke reports on while the overlay
              // teardown and the WebView's first redraw are still in
              // flight, and PixelCopy happily returns that as an all-black
              // frame. Black is also a legitimate capture (the Black
              // screensaver), so no pixel-guessing: a fresh wake simply
              // gets its transition waited out. A panel that has been on
              // for a while pays nothing.
              final onAt = _screenOnAt;
              if (onAt != null) {
                final settle =
                    const Duration(milliseconds: 1500) -
                    DateTime.now().difference(onAt);
                if (settle > Duration.zero) {
                  await Future<void>.delayed(settle);
                }
              }
              // The window, via a GPU blit on a background thread (see
              // ScreenCapture.kt). The WebView's own capture below draws
              // the view into a bitmap on the UI thread — with the admin's
              // auto-refresh ticked that was a visible stutter every few
              // seconds — and it can only ever show the page, never the
              // screensaver or menu actually on screen.
              final native = await ScreenCapture.capture(
                width: width,
                quality: quality,
              );
              if (native != null) {
                return CommandResult.ok(base64Encode(native));
              }
              // No Activity window (app backgrounded, or Android < 8): the
              // WebView outlives the Activity, so its page capture still
              // works.
              controller = _controller;
              if (controller != null) {
                final view =
                    WidgetsBinding.instance.platformDispatcher.implicitView;
                final bytes = await controller.takeScreenshot(
                  screenshotConfiguration: ScreenshotConfiguration(
                    compressFormat: CompressFormat.JPEG,
                    quality: quality,
                    snapshotWidth: webViewSnapshotWidth(
                      width: width,
                      physicalWidth: view?.physicalSize.width ?? 0,
                      devicePixelRatio: view?.devicePixelRatio ?? 0,
                    ),
                  ),
                );
                if (bytes != null) {
                  return CommandResult.ok(base64Encode(bytes));
                }
              }
              if (attempt < attempts) {
                await Future<void>.delayed(const Duration(milliseconds: 400));
              }
            }
            return CommandResult.fail(
              controller == null ? 'no webview attached' : 'screenshot failed',
            );
          },
        ),
      );

    // Seed the freeze gate from reality: a device that boots with its panel
    // already dark must not freeze the page it needs alive (_wantFrozen).
    // Best-effort — a failure keeps the lit default and the next
    // ScreenStateChanged corrects it.
    final on = await commands.execute('isScreenOn', const {});
    if (on.ok && on.data is bool) _screenIsOn = on.data as bool;

    _healthTimer = Timer.periodic(
      healthCheckEvery,
      (_) => unawaited(checkDashboardHealth()),
    );
  }

  void attach(InAppWebViewController controller, {bool freshLoads = false}) {
    _freshLoads = freshLoads;
    // The WebView took its own cache mode at creation; the service worker's
    // follows it here (no view matches yet, so only that part applies).
    unawaited(WebViewFreeze.setCacheMode(noCache: freshLoads, urlPrefix: '-'));
    _rendererRecovery?.cancel();
    _rendererRecovery = null;
    _rendererRebuildPending = false;
    _unresponsiveStrikes = 0;
    _rendererDeadChecks = 0;
    _webViewGeneration++;
    _controller = controller;
    // A rebuilt WebView is a fresh, visible native view. Its URL is not up
    // yet (the freeze matches by URL, so this sync usually finds nothing);
    // onPageLoaded retries once the page — and its URL — exist.
    _frozen = false;
    unawaited(_syncFreeze());
    if (_underAssist) unawaited(_syncAssistPause());
  }

  /// Whether the native voice overlay is up over the dashboard.
  bool _underAssist = false;

  Future<void> _syncAssistPause() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (_underAssist) {
        await controller.pause();
      } else {
        await controller.resume();
      }
      log.debug(
        name,
        'dashboard ${_underAssist ? 'paused under' : 'resumed after'} the '
        'voice overlay',
      );
    } catch (e) {
      log.debug(name, 'dashboard pause for the voice overlay failed: $e');
    }
  }

  bool isAttached(InAppWebViewController controller) =>
      identical(_controller?.platform, controller.platform);

  @visibleForTesting
  Duration javaScriptTimeout = const Duration(seconds: 5);

  @visibleForTesting
  Duration rendererRecoveryGrace = const Duration(seconds: 5);

  Timer? _rendererRecovery;
  int _unresponsiveStrikes = 0;
  int _rendererDeadChecks = 0;
  int _webViewGeneration = 0;
  bool _rendererRebuildPending = false;

  /// Termination can fail without delivering onRenderProcessGone. Give it
  /// a short grace period then replace the WebView even without a callback.
  ///
  /// Not on a dark panel: Android can stop a backgrounded renderer while
  /// the screen is off (a Lenovo Tab M8 on Android 13 does), and that
  /// renderer answers again once the screen is back.
  bool onRendererUnresponsive() {
    if (_rendererRebuildPending || _rendererRecovery != null) return false;
    if (!_screenIsOn) return false;
    _unresponsiveStrikes++;
    log.warn(
      name,
      'WebView renderer unresponsive (strike $_unresponsiveStrikes)',
    );
    if (_unresponsiveStrikes < 2) return false;
    _rendererRecovery = Timer(rendererRecoveryGrace, () {
      unawaited(
        rebuildFailedRenderer(
          'renderer termination did not restore the WebView',
        ),
      );
    });
    return true;
  }

  void onRendererResponsive() {
    _rendererRecovery?.cancel();
    _rendererRecovery = null;
    _unresponsiveStrikes = 0;
    _rendererDeadChecks = 0;
    _clearDuraSpeedNotice();
  }

  /// Android only reports a renderer responsive again after it reported it
  /// unresponsive, so a rebuilt renderer that simply works never calls
  /// [onRendererResponsive]. Any answer to the health probe clears the
  /// notice too.
  void _clearDuraSpeedNotice() {
    if (!duraSpeedBlocking.value) return;
    duraSpeedBlocking.value = false;
    log.info(name, 'the dashboard renderer answers again');
  }

  /// MediaTek's DuraSpeed is refusing the dashboard's renderer, as far as
  /// the kiosk can tell: a renderer that never answered, now being
  /// rebuilt, on a device with DuraSpeed installed and on. Android logs the
  /// refusal ("Unable to launch app ... SandboxedProcessService ... process
  /// is bad") but the app is never told, and some tablets ship DuraSpeed
  /// with no settings page, so the dashboard shows what to do instead. One
  /// rebuild is enough there: it means the page never answered the health
  /// probe twice over, and the first renderer that answers clears it.
  final duraSpeedBlocking = ValueNotifier<bool>(false);

  /// Whether DuraSpeed is installed and on; the device details, unless a
  /// test says otherwise.
  @visibleForTesting
  Future<bool> Function() duraSpeedInstalled = () async =>
      (await DeviceDetails.read()).duraSpeed;

  /// The command the notice shows: the only way to turn DuraSpeed off on a
  /// tablet that hides it.
  static const duraSpeedCommand =
      'adb shell settings put global setting.duraspeed.enabled 0';

  Future<void> rebuildFailedRenderer(String reason) async {
    if (_rendererRebuildPending) return;
    _rendererRebuildPending = true;
    _rendererRecovery?.cancel();
    _rendererRecovery = null;
    final viewId = _controller?.getViewId();
    _controller = null;
    _webViewGeneration++;
    _rendererDeadChecks = 0;
    _unresponsiveStrikes = 0;
    log.warn(name, '$reason; rebuilding the WebView');
    if (!duraSpeedBlocking.value && await duraSpeedInstalled()) {
      duraSpeedBlocking.value = true;
      unawaited(UsageCounters.bump(_settings, 'duraspeed_blocked'));
      log.error(
        name,
        'the dashboard renderer never answers and this device runs '
        "MediaTek's DuraSpeed, which refuses to start it: turn DuraSpeed "
        'off with `$duraSpeedCommand` and restart Kiosk Satellite',
      );
    }
    final generation = _webViewGeneration;
    if (viewId is int) await WebViewRecovery.prepare(viewId);
    if (generation != _webViewGeneration) return;
    bus.publish(const WebViewRebuildRequested());
  }

  bool _screensaverActive = false;
  bool _dashboardCovered = false;
  bool _screensaverHasOverlay = false;
  Timer? _cameraPauseDelay;

  /// Camera suspension belongs to the main dashboard document. It also works
  /// with rendering pause disabled and with a website screensaver on HA's
  /// origin. A visible Dim dashboard keeps its streams playing.
  bool get dashboardCameraStreamsPaused =>
      _settings.get(defs.pauseDashboardCameras) &&
      _screensaverActive &&
      (_screensaverHasOverlay || !_screenIsOn);

  void _scheduleDashboardCameraSync() {
    _cameraPauseDelay?.cancel();
    if (dashboardCameraStreamsPaused) {
      _cameraPauseDelay = Timer(const Duration(seconds: 1), () {
        unawaited(runJs(pauseDashboardCamerasJs(dashboardCameraStreamsPaused)));
      });
    } else {
      unawaited(runJs(pauseDashboardCamerasJs(false)));
    }
  }

  /// Whether the screensaver on screen is a website screensaver showing a
  /// page from the dashboard's own origin — a Home Assistant page set as the
  /// screensaver, which is what a wall clock dashboard is (discussion #225).
  ///
  /// Such a screensaver cannot be frozen over: the native side finds the
  /// views to hide by URL prefix, so it cannot tell the screensaver's page
  /// from the dashboard underneath and hides both, leaving a black screen
  /// where the screensaver should be. The same reason overlay pages on the
  /// dashboard's origin do not report themselves as covering it.
  bool _screensaverIsOwnOrigin(String? view) {
    if (view != 'website') return false;
    final url = Uri.tryParse(_settings.get(defs.screensaverWebsiteUrl).trim());
    return url != null && url.hasScheme && isDashboardOrigin(url);
  }

  /// When the panel last turned on; null while it has never woken during
  /// this process. The screenshot command waits out a fresh wake before
  /// capturing (a too-early PixelCopy returns an all-black frame).
  DateTime? _screenOnAt;

  /// Whether the panel is lit, for the freeze gate in [_wantFrozen].
  bool _screenIsOn = true;
  final _coveredBy = <String>{};
  final _renderingFrozenState = ValueNotifier<bool>(false);
  bool get _frozen => _renderingFrozenState.value;
  set _frozen(bool value) => _renderingFrozenState.value = value;

  /// What the last sync wanted, so the next one can tell a thaw edge from
  /// a steady "not frozen" (see _syncFreeze).
  bool _wantedFrozen = false;
  Timer? _freezeDelay;

  /// Whether the dashboard should be hidden right now: covered by a
  /// screensaver overlay with the freeze optimization on, or covered by an
  /// always-opaque surface (the settings route, a camera view, DLNA media)
  /// that reported itself through [setCovered] — pausing compositing under
  /// those hands the whole frame budget to whatever is on top, and unlike
  /// the screensaver's Dim mode they never show the page through.
  ///
  /// Never while the screen is off. The freeze makes the page report itself
  /// hidden, and a hidden page inside an app with no resumed Activity is
  /// the combination that makes the WebView suspend the page's timers and
  /// task queues outright (measured on an Echo Show 8: a 50ms setTimeout
  /// that simply never fires). With its event loop stopped, the Home
  /// Assistant frontend cannot answer keepalives or finish reconnects, so
  /// the websocket dies within a couple of minutes of the panel powering
  /// off and everything riding it — Voice Satellite's availability first
  /// of all — dies with it (discussion #186). A dark panel composites
  /// nothing anyway, so unfreezing costs no frames; the freeze comes back
  /// the moment the screen does.
  bool get _wantFrozen =>
      _screenIsOn &&
      ((_screensaverActive &&
              _dashboardCovered &&
              _settings.get(defs.freezeOnScreensaver)) ||
          _coveredBy.isNotEmpty);

  /// An opaque full-screen surface reporting that it covers the dashboard
  /// (or stopped covering it). Freezing waits _scheduleFreezeSync's beat so
  /// the surface has painted first (an INVISIBLE view draws nothing, and
  /// blanking the dashboard while it still shows is a visible black flash);
  /// thawing applies immediately, on the same synchronous edge that starts
  /// the reveal, so the page is compositing again within a frame.
  void setCovered(String reason, {required bool covered}) {
    final changed = covered
        ? _coveredBy.add(reason)
        : _coveredBy.remove(reason);
    if (!changed) return;
    _scheduleFreezeSync();
  }

  /// Every freeze edge from the bus lands here: freezing waits a beat so the
  /// overlay has had time to paint (or the dashboard blinks to black just
  /// before the screensaver appears), thawing applies immediately — the
  /// dashboard must be drawing again by the time it is uncovered.
  void _scheduleFreezeSync() {
    _scheduleDashboardCameraSync();
    _freezeDelay?.cancel();
    final want = _wantFrozen;
    if (want && !_frozen) {
      _freezeDelay = Timer(
        const Duration(seconds: 1),
        () => unawaited(_syncFreeze()),
      );
    } else {
      unawaited(_syncFreeze());
    }
  }

  /// Keepalive while frozen: a hidden page's timers are throttled (hard,
  /// after ~5 minutes), which can starve the HA websocket's own keepalive
  /// until the server drops it — the same failure the backgrounded-app
  /// keepalive in main.dart covers; freezing is a second way to be hidden
  /// while the Dart isolate stays fully alive. JS pushed in from Dart is not
  /// throttled, so the same ping keeps the socket warm. Best-effort like its
  /// sibling: the wake path's ensureHaConnected stays the guarantee.
  Timer? _freezeKeepAlive;
  static const _freezeKeepAliveEvery = Duration(seconds: 20);

  /// Whether the WebView's rendering is currently paused under the
  /// screensaver.
  bool get renderingFrozen => _frozen;

  /// Lets native overlays skip the covered platform view's paint work while
  /// preserving the existing screen-off, connection and user preference rules.
  ValueListenable<bool> get renderingFrozenState => _renderingFrozenState;

  final _returned = ReturnWatch();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_returned.returned(state)) unawaited(_reassertFreeze());
  }

  /// Re-applies the wanted freeze state after every resume, retrying until
  /// the dashboard view is found.
  ///
  /// The native side hides and reveals the view through the Activity's
  /// window, and the Activity can be destroyed and re-created under the
  /// process-wide engine (Back on a Portal's system bar finishes it, a tile
  /// tap re-creates it). A thaw that ran while the old Activity was going
  /// away (the screensaver standing down as the app lost the foreground)
  /// reached no window, the books here still said "resumed", and the same
  /// WebView came back into the new Activity INVISIBLE: a black dashboard
  /// until the next screensaver cycle happened to hide and reveal it. The
  /// platform view is re-attached a beat after the resume, so this asks a
  /// few times; revealing a visible view is a no-op, so a healthy resume
  /// costs nothing.
  Future<void> _reassertFreeze() async {
    for (final delay in const [0, 1, 2]) {
      if (delay > 0) await Future<void>.delayed(Duration(seconds: delay));
      final want = _wantFrozen;
      final prefix = _origin(_currentUrl) ?? 'http';
      final n = await WebViewFreeze.setHidden(hidden: want, urlPrefix: prefix);
      if (n == 0) continue;
      if (_frozen != want) {
        log.info(
          name,
          want
              ? 'rendering paused again after the Activity came back'
              : 'rendering revealed again after the Activity came back',
        );
        _frozen = want;
      }
      if (!want) unawaited(runJs(maskVisibilityJs(false)));
      return;
    }
  }

  /// Reconcile the WebView's native visibility with (screensaver up) AND
  /// (an overlay covering the dashboard) AND (the freeze optimization on).
  /// Called from every edge that can change any of the three. Only the
  /// dashboard is touched — the native side matches views by this page's
  /// origin, leaving the screensaver's own media WebView and rotation
  /// overlays alone.
  Future<void> _syncFreeze() async {
    final want = _wantFrozen;
    final wasWanted = _wantedFrozen;
    _wantedFrozen = want;
    final prefix = _origin(_currentUrl);
    if (want == _frozen) {
      // Nothing to do by our own books, but the edge from wanted to not
      // wanted still reveals: a freeze that was asked for and (by these
      // books) never took can still have left the native view hidden (it
      // falls out of step through a rebuild or a navigation while hidden),
      // and with this flag false every path here used to return early,
      // leaving a dashboard that never came back (a dead WebView after a
      // screensaver dismissal, seen on a Tab S8). Revealing a visible view
      // is a no-op, so the edge costs nothing.
      if (!want && wasWanted) {
        unawaited(
          WebViewFreeze.setHidden(hidden: false, urlPrefix: prefix ?? 'http'),
        );
      }
      return;
    }
    if (prefix == null) {
      // No dashboard origin to match on; a thaw still reveals whatever is
      // hidden (every page is meant to be visible now), a freeze waits for
      // the URL.
      if (_frozen) {
        await WebViewFreeze.setHidden(hidden: false, urlPrefix: 'http');
        await runJs(maskVisibilityJs(false));
      }
      _frozen = false;
      return;
    }
    if (want) {
      // Mask first: the page must never see the hidden edge this is about to
      // create, and the event follows the view change immediately.
      await runJs(maskVisibilityJs(true));
      final n = await WebViewFreeze.setHidden(hidden: true, urlPrefix: prefix);
      if (n == 0) {
        // Dashboard not found (mid-rebuild); retried on load. Nothing was
        // hidden, so the mask has to come back off or a genuine background
        // would be masked too.
        await runJs(maskVisibilityJs(false));
        return;
      }
      _frozen = true;
      _freezeKeepAlive?.cancel();
      _freezeKeepAlive = Timer.periodic(
        _freezeKeepAliveEvery,
        (_) => pingHaConnection(),
      );
      log.info(
        name,
        'rendering paused under '
        '${_coveredBy.isNotEmpty ? _coveredBy.join(', ') : 'screensaver'}',
      );
    } else {
      _frozen = false;
      _freezeKeepAlive?.cancel();
      _freezeKeepAlive = null;
      await WebViewFreeze.setHidden(hidden: false, urlPrefix: prefix);
      // The mask lifts itself once the page is really visible again, so the
      // thaw's own visibilitychange is swallowed whichever order it arrives in.
      await runJs(maskVisibilityJs(false));
      log.info(name, 'rendering resumed');
      if (_repairOnResume) {
        // The outage check a freeze deferred (see onNetworkAvailable):
        // the page is visible and unthrottled now, so the probe and the
        // liveness wait mean something. Bypasses the repair rate limit —
        // this IS the follow-up the deferral promised.
        _repairOnResume = false;
        _lastNetworkRepair = DateTime.fromMillisecondsSinceEpoch(0);
        unawaited(onNetworkAvailable());
      }
    }
  }

  /// Carousel drag edges: the native scrollbars sleep while the strip
  /// animates (drift and the parked preview's content extent awaken them
  /// over an animation that is not a scroll), and wake back after.
  Future<void> setDragScrollBars({required bool hidden}) async {
    final prefix = _origin(_currentUrl);
    if (prefix == null) return;
    await WebViewFreeze.setScrollBars(hidden: hidden, urlPrefix: prefix);
  }

  /// scheme://host[:port] of [url], or null when it has none (no page yet).
  String? _origin(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
  }

  /// Step the page's history back if it can. Returns whether it moved.
  Future<bool> goBack() async {
    final controller = _controller;
    if (controller == null) return false;
    if (!await controller.canGoBack()) return false;
    await controller.goBack();
    return true;
  }

  /// Called by the UI layer from the WebView's onConsoleMessage.
  void onConsoleMessage(String level, String message) {
    final now = DateTime.now();
    // The ring caps entries, not bytes: a dashboard dumping serialized
    // state objects could pin 300 megabyte-strings (and push each one to
    // every remote admin client). 8KB keeps any real diagnostic readable.
    if (message.length > 8192) {
      message = '${message.substring(0, 8192)}… [truncated]';
    }
    if (consoleEntries.length >= _consoleCapacity) {
      consoleEntries.removeAt(0);
    }
    consoleEntries.add(ConsoleEntry(now, level, message));
    consoleRevision.value++;
    bus.publish(
      ConsoleLine(
        level: level,
        message: message,
        timeMs: now.millisecondsSinceEpoch,
      ),
    );
  }

  void clearConsole() {
    consoleEntries.clear();
    consoleRevision.value++;
  }

  /// Called by the UI layer from the WebView's onUpdateVisitedHistory,
  /// which fires on SPA navigations (pushState) that never reach
  /// onLoadStop. Deduped: a pushState with an unchanged URL says nothing.
  void onUrlChanged(String url) {
    if (url == _currentUrl) return;
    _currentUrl = url;
    bus.publish(UrlChanged(url: url));
  }

  /// Called by the UI layer from the WebView's onLoadStop.
  void onPageLoaded(String url) {
    _lastLoadHadHttpError = _httpErrorThisLoad;
    // The error page Chromium commits for a failed load reaches here too,
    // announced by the onReceivedError that always precedes it — so a load
    // that arrives without one is the real page, and the offline notice
    // covering it can come down. Nothing else clears this: a retry that
    // fails again lands right back here with the flag set.
    //
    // A server error counts as a failed load for this purpose even though
    // it committed a document: the proxy's 502 while Home Assistant is
    // unreachable has an empty body, which is a blank screen with no more
    // to say for itself than Chromium's error page.
    loadFailed.value = _loadErrorThisLoad || _httpErrorThisLoad;
    _loadErrorThisLoad = false;
    _httpErrorThisLoad = false;
    if (!loadFailed.value) _clearErrorReload();
    if (!loadFailed.value && isCustomPage(url)) {
      unawaited(UsageCounters.bump(_settings, 'custom_page_loads'));
    }
    _currentUrl = url;
    log.info(name, 'loaded $url');
    // A page reached without passing through prepareLoad (Back, a reload
    // the renderer started on its own) sets the cache for what follows,
    // and a custom page's own files leave the service worker's cache so a
    // reload nobody prepared for still finds the edited ones.
    unawaited(prepareLoad(url));
    bus.publish(PageChanged(url: url));
    unawaited(_applyPendingLocalStorage());
    final loaded = Uri.tryParse(url);
    if (loaded != null && isHomeAssistantOrigin(loaded)) {
      unawaited(_captureHaSession());
    }
    // A page that loaded while the freeze was already up starts unmasked (the
    // script's default), and would see the thaw's visible edge without ever
    // having been told it went hidden. Re-assert, as the flag-gated scripts do.
    if (_frozen) unawaited(runJs(maskVisibilityJs(true)));
    unawaited(runJs(pauseDashboardCamerasJs(dashboardCameraStreamsPaused)));
    // A WebView rebuilt under an active screensaver reappears visible, and
    // attach() could not re-hide it (no URL to match yet). Now there is one.
    unawaited(_syncFreeze());
  }

  /// Imported localStorage waits (persisted) until a page is up to receive
  /// it, then is written and the page re-navigated so it takes effect.
  /// Cleared before the write — the next load lands back here, and a
  /// still-pending payload would loop forever.
  Future<void> _applyPendingLocalStorage() async {
    final pending = _settings.internal('pending_local_storage');
    if (pending.isEmpty) return;
    await _settings.setInternal('pending_local_storage', '');
    log.info(name, 'restoring imported localStorage');
    await runJs('''
      (function () {
        try {
          var entries = JSON.parse(${jsonEncode(pending)});
          Object.keys(entries).forEach(function (k) {
            localStorage.setItem(k, entries[k]);
          });
        } catch (e) {}
      })();
    ''');
    // Navigate to the start URL rather than reload: an unauthenticated
    // first load has already been redirected to the HA login page, and a
    // reload there re-shows the login form — the frontend only reads the
    // just-restored auth tokens when it loads a real dashboard URL.
    final target = _settings.get(defs.startUrl);
    if (target.isEmpty) {
      await runJs('location.reload()');
    } else {
      await loadUrl(target);
    }
  }

  /// Whether the page on screen is Chromium's own error page — the main
  /// document failed to load at all (no route, DNS, connection refused),
  /// which is what an outage looks like from here.
  ///
  /// The UI covers it while this holds: WebView's built-in error page is a
  /// dark slab with a fallen Android robot, which on a wall panel reads as a
  /// broken app rather than a missing network. It also survives the reload
  /// attempts underneath, since only a load that finishes cleanly clears it.
  final ValueNotifier<bool> loadFailed = ValueNotifier(false);

  /// What the failed load was trying to reach, for the notice's detail line.
  String lastErrorDescription = '';

  /// Set when the current load's main document failed outright; shifted into
  /// [loadFailed] when the load finishes, because Chromium follows the error
  /// with an onLoadStop for the error page it commits.
  bool _loadErrorThisLoad = false;

  /// Called by the UI layer on load errors and render-process crashes.
  Future<void> onLoadError(String description) async {
    log.warn(name, 'load error: $description');
    lastErrorDescription = description;
    _loadErrorThisLoad = true;
    loadFailed.value = true;
    _scheduleErrorReload();
  }

  /// Set when the current load's main document came back with a server
  /// error, shifted into [_lastLoadHadHttpError] when the load finishes
  /// (the error always precedes its onLoadStop). Together they let the
  /// network-return probe tell a committed 502 page from a healthy non-HA
  /// page, which look identical from JavaScript.
  bool _httpErrorThisLoad = false;
  bool _lastLoadHadHttpError = false;

  /// Called by the UI layer on a main-frame HTTP failure (>= 500).
  ///
  /// Chromium commits these as successful navigations — the proxy's 502
  /// when Home Assistant is unreachable, a reverse proxy's 502/504 during
  /// an outage — so onReceivedError never fires and, without this path,
  /// the error body sat on screen until an app restart (wifi-resilience
  /// review). Same policy as [onLoadError]: the reload re-requests the
  /// same URL, and a still-failing answer lands back here, so the retry
  /// chain keeps itself alive until one succeeds.
  Future<void> onHttpError(int statusCode) async {
    _httpErrorThisLoad = true;
    log.warn(name, 'main-frame HTTP $statusCode');
    lastErrorDescription = 'HTTP $statusCode';
    loadFailed.value = true;
    _scheduleErrorReload();
  }

  /// The pending retry of a failed load, and how long the next wait is.
  Timer? _errorReload;
  int _errorReloadAttempt = 0;

  /// Retry a failed load, backing off 5s → 10 → 20 → 40 → 60 and holding
  /// there.
  ///
  /// A fixed five seconds was fine for a page that fails once, and wrong for
  /// the case that prompted this: a kiosk left offline overnight retried
  /// twelve times a minute until morning, every attempt a failed DNS lookup
  /// and a fresh error page, and the log full of nothing else. The network
  /// coming back does not wait for this timer either — [onNetworkAvailable]
  /// re-navigates the moment the interface is up, so the backoff only
  /// governs how often we guess in the dark.
  void _scheduleErrorReload() {
    if (!_settings.get(defs.autoReloadOnError)) return;
    if (_errorReload?.isActive ?? false) return;
    const ladder = [5, 10, 20, 40, 60];
    final seconds = ladder[_errorReloadAttempt.clamp(0, ladder.length - 1)];
    _errorReloadAttempt++;
    _errorReload = Timer(Duration(seconds: seconds), () {
      unawaited(_controller?.reload());
    });
  }

  /// A load succeeded (or the page is being replaced deliberately): drop the
  /// pending retry and start the backoff over, so the next outage gets the
  /// same quick first attempt this one did.
  void _clearErrorReload() {
    _errorReload?.cancel();
    _errorReload = null;
    _errorReloadAttempt = 0;
  }

  @override
  Future<void> dispose() async {
    _errorReload?.cancel();
    _freezeDelay?.cancel();
    _freezeKeepAlive?.cancel();
    _cameraPauseDelay?.cancel();
    _healthTimer?.cancel();
    _rendererRecovery?.cancel();
    _webViewGeneration++;
    _closeRepair?.cancel();
  }

  /// Set by the composition root (see AppContainer): rewrites a URL to its
  /// loopback-proxied form when the secure context proxy is on. Every load
  /// funnels through here, so callers keep passing the real HA URLs.
  String Function(String url)? urlMapper;

  /// Follow a Home Assistant base URL change with the stored start URL
  /// (issue #216). The dashboard picker bakes an absolute URL at pick time,
  /// so without this the WebView keeps loading the dashboard from whatever
  /// origin the base URL had back then — and every URL the page derives
  /// from its own origin (wake word model manifests, TTS proxy) keeps that
  /// old host too, while the app's own clients follow the new one.
  ///
  /// Only a start URL sitting on the *old* base origin moves; a custom page
  /// on some other host is the user's own business and stays put.
  Future<void> _migrateStartUrlOrigin(SettingChanged e) async {
    final old = Uri.tryParse(((e.previous as String?) ?? '').trim());
    final now = Uri.tryParse(((e.value as String?) ?? '').trim());
    final start = Uri.tryParse(startUrl);
    if (old == null || now == null || start == null) return;
    // Uri.origin throws for anything without one; a first-time setup
    // (previous value empty) falls out here too.
    for (final u in [old, now, start]) {
      if (!u.isScheme('http') && !u.isScheme('https')) return;
    }
    if (old.origin == now.origin || start.origin != old.origin) return;
    final full = start.toString();
    if (!full.startsWith(start.origin)) return;
    final rewritten = now.origin + full.substring(start.origin.length);
    log.info(name, 'start URL follows the new HA base URL: $rewritten');
    await _settings.set(defs.startUrl, rewritten);
    await loadUrl(rewritten);
  }

  Future<void> loadUrl(String url) async {
    // An explicit navigation targets the main WebView; an overlay page
    // sitting above it would make the navigation invisible.
    dismissOverlay();
    final mapped = urlMapper?.call(url) ?? url;
    await prepareLoad(mapped);
    if (await reloadIfOwnFragmentUrl(mapped)) return;
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(mapped)));
  }

  /// Reload the page when [url] is the address it is already on and that
  /// address has a fragment, and answer whether it did. A load would change
  /// nothing there (see [_loadKeepsDocument]), which left a dead dashboard
  /// with a hash in its URL unrecoverable (issue #1311).
  Future<bool> reloadIfOwnFragmentUrl(String url) async {
    if (!_loadKeepsDocument(url, await liveUrl())) return false;
    await _controller?.reload();
    return true;
  }

  /// The document-start script group that hands every page the space
  /// plugins keep clear of their bars (see contentInsetsJs).
  static const contentInsetsGroup = 'ks-content-insets';

  /// The insets the page last heard, in CSS pixels.
  EdgeInsets get contentInsets => _contentInsets;
  EdgeInsets _contentInsets = EdgeInsets.zero;

  /// The page on screen pads by [css] at once, and the document-start
  /// script is swapped so the next page starts with it too.
  Future<void> setContentInsets(EdgeInsets css) async {
    if (css == _contentInsets) return;
    _contentInsets = css;
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.removeUserScriptsByGroupName(
        groupName: contentInsetsGroup,
      );
      await controller.addUserScript(
        userScript: UserScript(
          groupName: contentInsetsGroup,
          source: contentInsetsSource,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    } catch (e) {
      log.debug(name, 'content insets script not swapped: $e');
    }
    await runJs(contentInsetsSource);
  }

  /// [contentInsets] as page script.
  String get contentInsetsSource => contentInsetsJs(
    left: _contentInsets.left,
    top: _contentInsets.top,
    right: _contentInsets.right,
    bottom: _contentInsets.bottom,
  );

  /// The document-start script group that hands every page the URL
  /// Filter rules for the dashboard (see urlFilterJs).
  static const urlFilterGroup = 'ks-url-filter';

  String _urlFilterRaw = '';
  List<UrlFilterRule> _urlFilter = const [];

  /// The URL Filter rules, parsed once per change of the setting.
  List<UrlFilterRule> get urlFilter {
    final raw = _settings.get(defs.browserUrlFilter);
    if (raw != _urlFilterRaw) {
      _urlFilterRaw = raw;
      _urlFilter = parseUrlFilter(raw);
    }
    return _urlFilter;
  }

  /// Whether [url] is blocked on any of [surfaces] (urlFilterDashboard,
  /// urlFilterExternal): null when it may open, the Block rule's name, or ''
  /// when an allow list leaves it out (see urlFilterBlockedBy). Logged when
  /// it is blocked, so the reason for a dead link is in the log.
  String? urlBlockedBy(String url, Set<String> surfaces) {
    final rule = urlFilterBlockedBy(
      urlFilter,
      url,
      surfaces,
      exemptions: urlFilterExemptions(startUrl),
    );
    if (rule != null) logUrlBlocked(url, rule);
    return rule;
  }

  /// One line in the log for a navigation the URL Filter stopped, by the
  /// Block rule's [rule] name or '' for the allow list.
  void logUrlBlocked(String url, String rule) {
    log.info(
      name,
      rule.isEmpty
          ? 'blocked $url (not on the URL Filter allow list)'
          : 'blocked $url (URL Filter rule "$rule")',
    );
    unawaited(UsageCounters.bump(_settings, 'url_filter_blocked'));
  }

  /// The page script for the rules covering [surface].
  String urlFilterSource(String surface) => urlFilterJs([
    for (final r in urlFilter)
      if (r.appliesTo({surface})) r,
  ], exemptions: urlFilterExemptions(startUrl));

  /// The rules changed: the page on screen follows at once, and the
  /// document-start script is swapped so the next page starts with them.
  Future<void> _applyUrlFilter() async {
    final controller = _controller;
    if (controller == null) return;
    final source = urlFilterSource(urlFilterDashboard);
    try {
      await controller.removeUserScriptsByGroupName(groupName: urlFilterGroup);
      await controller.addUserScript(
        userScript: UserScript(
          groupName: urlFilterGroup,
          source: source,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    } catch (e) {
      log.debug(name, 'URL Filter script not swapped: $e');
    }
    await runJs(source);
  }

  /// The document-start script group that answers a custom page's
  /// `prefers-color-scheme` (see customPageColorSchemeJs).
  static const customPageSchemeGroup = 'ks-custom-page-scheme';

  /// A custom page's `prefers-color-scheme` follows [dark] from now on:
  /// the page on screen flips at once, and the document-start script is
  /// swapped so the next page starts on it too. Called again when the pages
  /// change, since the script names the servers of the external ones.
  Future<void> setCustomPageDark(bool dark) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.removeUserScriptsByGroupName(
        groupName: customPageSchemeGroup,
      );
      await controller.addUserScript(
        userScript: UserScript(
          groupName: customPageSchemeGroup,
          source: customPageColorSchemeJs(
            dark: dark,
            origins: customPageOrigins,
          ),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    } catch (e) {
      log.debug(name, 'custom page color scheme not swapped: $e');
    }
    await runJs(colorSchemeSetJs(dark: dark));
  }

  /// Whether the dashboard WebView skips the HTTP cache right now: always
  /// with Disable cache on, otherwise while a custom page is the target.
  bool _freshLoads = false;

  /// Whether [url] is a custom page in Home Assistant, a file under its
  /// /local/. The dashboard WebView holds no other origin's /local/ unless
  /// the person added that server's pages, so the path says it all.
  static bool isCustomPageUrl(String url) =>
      Uri.tryParse(url)?.path.startsWith('/local/') ?? false;

  /// The origins of the custom pages on other servers.
  Set<String> get customPageOrigins =>
      externalPageOrigins(parseCustomPages(_settings.get(defs.haCustomPages)));

  /// Whether [url] is on the server of a custom page someone added. Every
  /// page there counts as theirs: links between their own pages stay in
  /// the dashboard WebView, and the managed Home Assistant connection
  /// serves them.
  bool isCustomPageOrigin(Uri url) =>
      url.hasAuthority && customPageOrigins.contains(url.origin);

  /// Whether [url] is a custom page, in Home Assistant or on another
  /// server.
  bool isCustomPage(String url) {
    if (isCustomPageUrl(url)) return true;
    final uri = Uri.tryParse(url);
    return uri != null && isCustomPageOrigin(uri);
  }

  /// Prepare the dashboard WebView for loading [target]. Home Assistant
  /// keeps /local/ files twice over: its service worker answers them from
  /// its `file-cache` and refreshes that copy in the background, through an
  /// HTTP cache told to keep them for a month. Either way an edited custom
  /// page stays stale. So the copies of a custom page the service worker
  /// holds are dropped before it loads or is left. The WebView and the
  /// service worker skip the HTTP cache while a custom page is up. Home
  /// Assistant's own frontend keeps both caches, which its quick start
  /// depends on.
  Future<void> prepareLoad(String target) async {
    final entering = isCustomPage(target);
    if (entering || isCustomPage(_currentUrl)) {
      await _dropCustomPageCopies(target: entering ? target : null);
    }
    final want = _settings.get(defs.disableCache) || entering;
    if (want == _freshLoads) return;
    final prefix = _origin(_currentUrl) ?? _origin(target);
    if (prefix == null) return;
    final n = await WebViewFreeze.setCacheMode(
      noCache: want,
      urlPrefix: prefix,
    );
    if (n > 0) _freshLoads = want;
  }

  /// Every copy of a custom page's files the kiosk could load again without
  /// asking Home Assistant: the service worker's, then the renderer's
  /// in-memory ones, which a reload or a revisit otherwise reuses.
  Future<void> _dropCustomPageCopies({String? target}) async {
    await _purgeCustomPageCache(target: target);
    final prefix = _origin(_currentUrl);
    if (prefix != null) await WebViewFreeze.clearMemoryCache(urlPrefix: prefix);
  }

  /// Drop custom page files from the service worker's `file-cache`, run in
  /// the page on screen (Cache Storage belongs to its origin): everything in
  /// [target]'s folder, where a page keeps its scripts and data. When a
  /// custom page is on screen, also that page and every /local/ file it
  /// loaded.
  /// A dashboard file caught in the sweep is only read again from the HTTP
  /// cache. Best effort: a page without Cache Storage or one too busy to
  /// answer simply keeps them.
  Future<void> _purgeCustomPageCache({String? target}) async {
    final path = target == null ? null : Uri.tryParse(target)?.path;
    final body =
        '''
const target = ${jsonEncode(path)};
if (!self.caches) return 0;
const drop = new Set();
const folder = target ? target.slice(0, target.lastIndexOf('/') + 1) : null;
if (location.pathname.indexOf('/local/') === 0) {
  drop.add(location.pathname);
  for (const e of performance.getEntriesByType('resource')) {
    try {
      const u = new URL(e.name);
      if (u.origin === location.origin && u.pathname.indexOf('/local/') === 0) {
        drop.add(u.pathname);
      }
    } catch (_) {}
  }
}
if (!(await caches.has('file-cache'))) return 0;
const cache = await caches.open('file-cache');
let n = 0;
for (const request of await cache.keys()) {
  const path = new URL(request.url).pathname;
  const gone = drop.has(path) || (folder && path.indexOf(folder) === 0);
  if (gone && await cache.delete(request)) n++;
}
return n;
''';
    try {
      final override = evalOverride;
      if (override != null) {
        await override(body);
      } else {
        await _controller
            ?.callAsyncJavaScript(functionBody: body)
            .timeout(const Duration(seconds: 2));
      }
    } catch (_) {}
  }

  /// Evaluate JavaScript and return its stringified result — the REPL in
  /// the console panels. Null when no WebView is attached.
  Future<String?> eval(String code) async {
    final controller = _controller;
    if (controller == null) return null;
    final result = await _eval(code).timeout(javaScriptTimeout);
    return '$result';
  }

  /// Force the Home Assistant frontend to re-establish its WebSocket.
  ///
  /// After the WebView is frozen (screen off, Doze, backgrounded) it can thaw
  /// holding a half-open socket: the client still reads it as OPEN, so the HA
  /// frontend never reconnects. Everything riding that one connection then
  /// silently stops — live entity state, the Voice Satellite pipeline, and
  /// integrations like browser_mod (whose backend has long since dropped the
  /// browser, so its navigate/popup commands go nowhere). Closing the socket
  /// makes home-assistant-js-websocket reconnect and every subscription
  /// re-register, with no page reload — the page, the VS session and the wake
  /// word all stay loaded. A no-op on non-HA pages.
  Future<void> reconnectHaSocket() async {
    if (_controller == null && evalOverride == null) return;
    final result = await _eval('''
      (function () {
        try {
          var ha = document.querySelector('home-assistant');
          var conn = ha && ha.hass && ha.hass.connection;
          if (!conn) return 'no-connection';
          // A connection with no socket at all is not merely disconnected: the
          // frontend suspends reconnects for as long as it believes the page
          // is in the background, and it only lifts that on a visible or focus
          // event. If one of those went missing the reconnect never happens —
          // no timer is pending, nothing is retrying, and the page sits on
          // "Connection lost. Reconnecting…" indefinitely (issue #228).
          // Cycling the socket cannot fix it either: the frontend's own
          // reconnect() returns immediately when there is no socket to cycle.
          // Firing the focus event the frontend is waiting for does, and it is
          // a no-op on a connection that is not waiting for one.
          if (!conn.socket) {
            try { window.dispatchEvent(new Event('focus')); } catch (e) {}
            return 'unblocked';
          }
          if (typeof conn.reconnect === 'function') {
            conn.reconnect(true);
            return 'reconnect';
          }
          conn.socket.close();
          return 'socket-closed';
        } catch (e) { return 'error: ' + e; }
      })()
    ''').timeout(javaScriptTimeout, onTimeout: () => 'renderer-unresponsive');
    log.info(name, 'HA socket nudge: $result');
  }

  /// Test seam for the JS round trips above and below; production always
  /// asks the live controller.
  @visibleForTesting
  Future<Object?> Function(String source)? evalOverride;

  Future<Object?> _eval(String source) async {
    final override = evalOverride;
    if (override != null) return override(source);
    return _controller?.evaluateJavascript(source: source);
  }

  /// The resume-path recovery: cycle the HA socket only when it fails a
  /// liveness check.
  ///
  /// [reconnectHaSocket] exists for the half-open socket a long freeze
  /// leaves behind, which still reads OPEN and connected — no state
  /// inspection can clear it, so the resume path used to cycle the socket
  /// unconditionally. But on a panel whose process the foreground service
  /// keeps alive, the background keepalive usually kept the socket genuinely
  /// healthy, and the blind cycle made every wake cost a "connection lost"
  /// flash and a from-scratch rebuild of every camera card's stream — which
  /// reads as the dashboard reloading itself.
  ///
  /// The one signal a zombie cannot fake is a round trip, so this sends a
  /// ping through the frontend's connection and waits for the pong. An
  /// answer within [timeout] means the socket is provably alive and it is
  /// left untouched; no answer, an errored send, or a page with no
  /// connection at all falls through to [reconnectHaSocket], exactly the
  /// recovery the resume path always had.
  Future<void> nudgeHaSocketIfDead({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_controller == null && evalOverride == null) return;
    final started = await _eval('''
      (function () {
        try {
          var ha = document.querySelector('home-assistant');
          var conn = ha && ha.hass && ha.hass.connection;
          if (!conn || !conn.connected || !conn.socket ||
              conn.socket.readyState !== 1) {
            return 'no-connection';
          }
          window.__ksPingCheck = 'pending';
          conn.sendMessagePromise({ type: 'ping' }).then(
            function () { window.__ksPingCheck = 'alive'; },
            function () { window.__ksPingCheck = 'dead'; });
          return 'pending';
        } catch (e) { return 'no-connection'; }
      })()
    ''').timeout(javaScriptTimeout, onTimeout: () => 'renderer-unresponsive');
    if ('$started' == 'pending') {
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final state = await _eval(
          'window.__ksPingCheck',
        ).timeout(javaScriptTimeout, onTimeout: () => 'dead');
        if ('$state' == 'alive') {
          log.info(name, 'HA socket answered the resume ping; leaving it be');
          return;
        }
        if ('$state' == 'dead') break;
      }
    }
    await reconnectHaSocket();
  }

  /// How often the dashboard's connection is checked, and how many checks in
  /// a row have to find it down before anything is done about it.
  @visibleForTesting
  Duration healthCheckEvery = const Duration(seconds: 60);

  /// How long the repair waits for the connection to come back before giving
  /// up on it; derived from the freeze state in production.
  @visibleForTesting
  Duration? healthRepairTimeout;
  static const _deadChecksBeforeRepair = 3;
  Timer? _healthTimer;
  bool _healthCheckBusy = false;
  int _deadChecks = 0;
  DateTime _lastHealthReload = DateTime.fromMillisecondsSinceEpoch(0);
  static const _healthReloadCooldown = Duration(minutes: 15);

  /// The dashboard connection watchdog (issue #228).
  ///
  /// Every other recovery here is driven by an edge: the network came back,
  /// the app resumed from the background, a wake word is about to need the
  /// socket. A wall panel that is never backgrounded, on a network that never
  /// drops, produces none of them — so a dashboard whose connection dies for
  /// its own reasons had nothing at all coming for it, and sat on Home
  /// Assistant's "Connection lost. Reconnecting…" screen behind the
  /// screensaver until someone walked up to it (seven hours, in the report).
  /// The frontend does not always retry: it blocks its own reconnects while
  /// it believes the page is hidden, and it gives up outright on an auth
  /// failure — both leave a page that is loaded, running, and finished.
  ///
  /// So the connection is polled instead. Repair only after several checks in
  /// a row find it down, because a page that is merely mid-reconnect looks
  /// identical to a dead one for a few seconds and must not be interrupted.
  Future<void> checkDashboardHealth() async {
    if (_healthCheckBusy || _rendererRebuildPending) return;
    _healthCheckBusy = true;
    try {
      await _checkDashboardHealth();
    } finally {
      _healthCheckBusy = false;
    }
  }

  Future<void> _checkDashboardHealth() async {
    if (_controller == null && evalOverride == null) return;
    // A load that failed has its own retry ladder, and an outage repair in
    // flight is already doing this.
    if (loadFailed.value || _networkRepairBusy) return;
    final generation = _webViewGeneration;
    final lit = _screenIsOn;
    final state = await _probePageState();
    if (generation != _webViewGeneration) return;
    if (state == 'unresponsive') {
      _deadChecks = 0;
      // A dark, locked panel can leave the page too backgrounded to answer
      // in time, and a renderer rebuilt for that is not a failed one.
      if (!lit || !_screenIsOn) return;
      _rendererDeadChecks++;
      if (_rendererDeadChecks >= 2 && _settings.get(defs.autoReloadOnError)) {
        await rebuildFailedRenderer('dashboard JavaScript timed out twice');
      }
      return;
    }
    _rendererDeadChecks = 0;
    if (state != 'none') _clearDuraSpeedNotice();
    // Only a Home Assistant page that is not talking to Home Assistant is
    // this watchdog's business: the loaded frontend with a dead connection,
    // and the launch screen that never got one. Anything else is somebody
    // else's page and nobody's to reload.
    if (state != 'stale' && state != 'shell') {
      _deadChecks = 0;
      return;
    }
    _deadChecks++;
    if (_deadChecks < _deadChecksBeforeRepair) return;
    log.warn(
      name,
      'dashboard connection down for '
      '${_deadChecks * healthCheckEvery.inSeconds}s; repairing',
    );
    // The nudge covers both the half-open socket and the suspended-reconnect
    // block; a frozen page gets longer, since its timers are throttled and
    // the frontend's re-subscribe runs on them.
    if (await ensureHaConnected(
      timeout:
          healthRepairTimeout ?? Duration(seconds: renderingFrozen ? 20 : 10),
    )) {
      log.info(name, 'dashboard connection recovered');
      _deadChecks = 0;
      return;
    }
    // Nothing short of a reload is left — which is what recovering these by
    // hand has always meant. Gated on the same setting as every other reload
    // this app does on its own, and rate limited so a dashboard that cannot
    // connect at all (Home Assistant down for the night) reloads occasionally
    // instead of every few minutes.
    if (!_settings.get(defs.autoReloadOnError)) {
      log.warn(name, 'dashboard still down; auto-reload is off, leaving it');
      _deadChecks = 0;
      return;
    }
    if (DateTime.now().difference(_lastHealthReload) < _healthReloadCooldown) {
      return;
    }
    _lastHealthReload = DateTime.now();
    _deadChecks = 0;
    log.warn(name, 'dashboard still down after the nudge; reloading');
    await _renavigate(reason: 'a dead dashboard connection');
  }

  /// How long a closed Home Assistant socket is given to come back on its own
  /// before the unblock is sent (see [onHaSocketClosed]).
  @visibleForTesting
  Duration socketCloseGrace = const Duration(seconds: 10);
  Timer? _closeRepair;

  /// The page's Home Assistant socket just closed (reported by
  /// socket_watch_script).
  ///
  /// Closing is ordinary — Home Assistant restarts, Wi-Fi blips, and the
  /// server drops any client that falls behind its outgoing queue — and the
  /// frontend reconnects on its own every time it is allowed to. This exists
  /// for when it is not allowed to: a frontend that believes the page is in
  /// the background blocks its own reconnects indefinitely, and a close that
  /// lands in that state is never retried. Waiting for the poll to notice
  /// takes three minutes, and the page knows now.
  ///
  /// So after a grace period, a connection that has not come back is sent the
  /// event that lifts the block. Nothing more: a reconnect that is merely
  /// slow (Home Assistant still starting) must not cost a page reload, and
  /// the watchdog is still there to escalate if this does not take.
  void onHaSocketClosed() {
    if (_closeRepair?.isActive ?? false) return;
    _closeRepair = Timer(socketCloseGrace, () async {
      if (await _haConnected()) return;
      log.warn(name, 'the dashboard socket closed and has not come back');
      await reconnectHaSocket();
    });
  }

  /// The page reported that the dashboard set may have moved (see
  /// dashboards_watch_script): relayed as is, the listeners coalesce.
  void onHaDashboardsChanged(String reason) {
    bus.publish(HaDashboardsChanged(reason: reason));
  }

  /// Serializes and rate-limits [onNetworkAvailable]: a flapping network
  /// must not stack probes or reload in a loop.
  bool _networkRepairBusy = false;
  DateTime _lastNetworkRepair = DateTime.fromMillisecondsSinceEpoch(0);

  /// The network just returned from an outage: diagnose the page and fix
  /// what the outage broke. Four outcomes, from cheapest up:
  ///
  ///  - a healthy page with a live HA socket: nothing to do;
  ///  - an HA page whose socket died (or went half-open — a socket that
  ///    reads OPEN but is dead, which nothing else on a never-backgrounded
  ///    kiosk ever notices): [ensureHaConnected] nudges it and waits;
  ///  - the HA shell without a connection (the "Unable to connect,
  ///    retrying in Ns" screen, whose countdown grows and is never
  ///    short-circuited by the frontend when the network returns), or a
  ///    Chromium error page: re-navigate now;
  ///  - anything else (a healthy non-HA page): left alone.
  Future<void> onNetworkAvailable() async {
    if ((_controller == null && evalOverride == null) || _networkRepairBusy) {
      return;
    }
    if (DateTime.now().difference(_lastNetworkRepair).inSeconds < 10) return;
    _networkRepairBusy = true;
    _lastNetworkRepair = DateTime.now();
    try {
      // Let routes and DNS settle: onAvailable fires when the interface is
      // up, which is a beat before connections actually succeed.
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_controller == null && evalOverride == null) return;
      // A failed load needs no diagnosis: there is no page to interrogate,
      // and the probe cannot even run — Chromium's error page answers no
      // JavaScript, so the probe would come back 'none' and this would
      // decide to leave a dead kiosk alone. This is the whole outage case:
      // the network dropped, the page (or its reload) failed, and now the
      // network is back.
      if (loadFailed.value) {
        await _renavigate();
        return;
      }
      final state = await _probePageState();
      log.info(name, 'network returned; page state: $state');
      switch (state) {
        case 'connected':
          return;
        case 'stale':
          // A frozen page cannot pass the liveness wait below no matter how
          // healthy the network is: Chromium hard-throttles a long-hidden
          // page's timers to about once a minute, so the frontend's
          // reconnect cannot finish inside any reasonable window. Judging
          // it now produced a false "dead" and a reload nobody saw start —
          // it sat pending under the frozen view and committed the moment
          // the screen came on, reading as the kiosk reloading itself at
          // every wake that followed a Wi-Fi blip. Nudge the socket (the
          // connect attempt itself is not timer-driven, so it can succeed
          // while hidden) and leave the verdict to the resume, where the
          // unthrottled page reconnects in seconds and the re-run below
          // finds it healthy.
          if (renderingFrozen) {
            unawaited(reconnectHaSocket());
            _repairOnResume = true;
            log.info(name, 'page frozen; deferring the outage check to resume');
            return;
          }
          // Nudges the frontend's reconnect and polls; a page mid-boot
          // (connection object present, socket still opening) passes here
          // without a disruptive reload.
          if (!await ensureHaConnected(timeout: const Duration(seconds: 8))) {
            await _renavigate();
          }
        case 'shell':
        case 'error-page':
          await _renavigate();
        case 'other' when _lastLoadHadHttpError:
          // Looks like an ordinary non-HA page to the probe, but the last
          // load's main document was a server error (a 502 body commits as
          // a perfectly normal page). Re-navigate now that upstream may be
          // back.
          await _renavigate();
        default:
          // A non-HA page that probes healthy, or a probe that failed:
          // reloading might destroy real state, so leave it be.
          return;
      }
    } finally {
      _networkRepairBusy = false;
    }
  }

  /// Where a recovery should aim: the last real URL, else the start URL —
  /// the fallback that matters when the very first load failed and there is
  /// nothing committed to reload.
  ///
  /// Chromium's own pages are not targets. A failed navigation can leave
  /// `chrome-error://chromewebdata/` (or `about:blank`) as the committed
  /// URL, and re-navigating to that would "recover" the kiosk onto the
  /// error page it is already showing.
  String get _recoveryUrl {
    final last = _currentUrl;
    final usable =
        last.isNotEmpty &&
        !last.startsWith('chrome-error') &&
        !last.startsWith('about:');
    return usable ? last : startUrl;
  }

  /// Load the dashboard again, now — the offline notice's Retry button, and
  /// what an operator means by "try again" from the remote admin.
  Future<void> retryLoad() async {
    _clearErrorReload();
    final target = _recoveryUrl;
    if (target.isEmpty) return;
    log.info(name, 'retrying $target');
    await loadUrl(target);
  }

  /// Outage reloads issued, for the tests that assert one did NOT happen.
  @visibleForTesting
  int renavigations = 0;

  /// A network blip was diagnosed while the page was frozen; re-run the
  /// repair when rendering resumes, on a page that can actually answer.
  bool _repairOnResume = false;

  Future<void> _renavigate({String reason = 'network outage'}) async {
    renavigations++;
    final target = _recoveryUrl;
    if (target.isEmpty) return;
    log.info(name, 'reloading after $reason: $target');
    // This attempt replaces the pending blind retry, and its failure should
    // start the backoff fresh rather than resume it mid-ladder.
    _clearErrorReload();
    await loadUrl(target);
  }

  /// One JS round trip classifying the current document. Error pages
  /// commit as chrome-error://, so location tells them apart from any real
  /// page; the HA element split mirrors [_haConnected].
  Future<String> _probePageState() async {
    if (_controller == null && evalOverride == null) return 'none';
    try {
      final r = await _eval('''
        (function () {
          try {
            if (location.href.indexOf('chrome-error') === 0) {
              return 'error-page';
            }
            var ha = document.querySelector('home-assistant');
            if (ha) {
              var c = ha.hass && ha.hass.connection;
              if (c && c.connected && c.socket &&
                  c.socket.readyState === 1) {
                return 'connected';
              }
              return 'stale';
            }
            if (document.querySelector('ha-init-page, ha-launch-screen')) {
              return 'shell';
            }
            return 'other';
          } catch (e) { return 'other'; }
        })()
      ''').timeout(javaScriptTimeout);
      return '$r'.replaceAll('"', '');
    } on TimeoutException {
      return 'unresponsive';
    } catch (_) {
      return 'none';
    }
  }

  /// True when the Home Assistant frontend's websocket is live right now.
  Future<bool> _haConnected() async {
    if (_controller == null && evalOverride == null) return false;
    final r = await _eval('''
      (function () {
        try {
          var c = document.querySelector('home-assistant');
          c = c && c.hass && c.hass.connection;
          return !!(c && c.connected && c.socket && c.socket.readyState === 1);
        } catch (e) { return false; }
      })()
    ''').timeout(javaScriptTimeout, onTimeout: () => false);
    return r == true || r == 'true' || r == 1;
  }

  /// Keep the HA websocket from dying while the app is in the background.
  ///
  /// Chromium throttles a hidden WebView's timers (hard, after ~5 minutes),
  /// which starves the connection's own keepalive until the server drops it.
  /// The Dart isolate stays alive on the foreground service though, so a timer
  /// there can poke the page on demand: running any JS flushes the renderer's
  /// pending socket messages, and an explicit ping keeps the server seeing
  /// traffic. Best-effort — [ensureHaConnected] is the guarantee.
  Future<void> pingHaConnection() async {
    await runJs('''
      (function () {
        try {
          var c = document.querySelector('home-assistant');
          c = c && c.hass && c.hass.connection;
          if (c && c.connected && c.socket && c.socket.readyState === 1) {
            c.sendMessagePromise({ type: 'ping' }).catch(function () {});
          }
        } catch (e) {}
      })()
    ''');
  }

  /// Make sure the HA websocket is live before something runs on it — the
  /// wake path calls this before handing a wake to Voice Satellite, so its
  /// pipeline never starts on a socket Chromium let die in the background
  /// (which came back as a duplicate wake-up, or a broken, reload-only page).
  ///
  /// A no-op when the socket is already up (foreground wakes, or the keepalive
  /// held): one quick check and return. Otherwise force a reconnect and wait,
  /// up to [timeout], for it to come back live and re-subscribed.
  Future<bool> ensureHaConnected({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (_controller == null && evalOverride == null) return false;
    if (await _haConnected()) return true;
    // A page with no Home Assistant frontend on it (a custom page, the
    // login form) has no socket here to bring back, and waiting out the
    // timeout for one held every wake word on a custom page for seconds.
    // The launch screen still waits: its frontend is on the way.
    switch (await _probePageState()) {
      case 'other':
        return true;
      case 'error-page':
        return false;
    }
    await reconnectHaSocket();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (await _haConnected()) return true;
    }
    log.warn(name, 'HA socket did not come back within ${timeout.inSeconds}s');
    return false;
  }

  /// Evaluate JavaScript in the current page (fire-and-forget helper for the
  /// UI layer, e.g. applying or lifting HA kiosk mode).
  Future<void> runJs(String source) async {
    try {
      await _controller
          ?.evaluateJavascript(source: source)
          .timeout(javaScriptTimeout);
    } catch (e) {
      log.debug(name, 'runJs failed: $e');
    }
  }

  static String _stripSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
