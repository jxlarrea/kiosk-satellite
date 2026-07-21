import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'no_cache_script.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../device/screen_capture.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// One line of the page's JavaScript console.
class ConsoleEntry {
  ConsoleEntry(this.time, this.level, this.message);

  final DateTime time;

  /// 'log' | 'debug' | 'warn' | 'error' | 'tip'
  final String level;
  final String message;
}

/// WebView lifecycle: navigation, current URL, error recovery, screenshots.
///
/// The manager does not build the widget — the UI layer owns the
/// [InAppWebView] and calls [attach] from `onWebViewCreated`. Everything else
/// (commands, events) flows through the attached controller.
class BrowserManager extends Manager {
  BrowserManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'browser';

  InAppWebViewController? _controller;
  String _currentUrl = '';

  String get currentUrl => _currentUrl;

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

  @override
  Future<void> init() async {
    commands
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
            overlayUrl.value = url;
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
            overlayUrl.value = null;
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
            await _controller?.reload();
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
            if (code == null || controller == null) {
              return const CommandResult.fail('code required / no webview');
            }
            final result = await controller.evaluateJavascript(source: code);
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
            // The window, via a GPU blit on a background thread (see
            // ScreenCapture.kt). The WebView's own capture below draws the
            // view into a bitmap on the UI thread — with the admin's
            // auto-refresh ticked that was a visible stutter every few
            // seconds — and it can only ever show the page, never the
            // screensaver or menu actually on screen.
            final native = await ScreenCapture.capture(
              width: width,
              quality: quality,
            );
            if (native != null) return CommandResult.ok(base64Encode(native));
            // No Activity window (app backgrounded, or Android < 8): the
            // WebView outlives the Activity, so its page capture still works.
            final controller = _controller;
            if (controller == null) {
              return const CommandResult.fail('no webview attached');
            }
            final bytes = await controller.takeScreenshot(
              screenshotConfiguration: ScreenshotConfiguration(
                compressFormat: CompressFormat.JPEG,
                quality: quality,
                snapshotWidth: width > 0 ? width.toDouble() : null,
              ),
            );
            if (bytes == null) {
              return const CommandResult.fail('screenshot failed');
            }
            return CommandResult.ok(base64Encode(bytes));
          },
        ),
      );
  }

  void attach(InAppWebViewController controller) {
    _controller = controller;
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

  /// Called by the UI layer from the WebView's onLoadStop.
  void onPageLoaded(String url) {
    _currentUrl = url;
    log.info(name, 'loaded $url');
    bus.publish(PageChanged(url: url));
    unawaited(_applyPendingLocalStorage());
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

  /// Called by the UI layer on load errors and render-process crashes.
  Future<void> onLoadError(String description) async {
    log.warn(name, 'load error: $description');
    if (_settings.get(defs.autoReloadOnError)) {
      await Future<void>.delayed(const Duration(seconds: 5));
      await _controller?.reload();
    }
  }

  /// Set by the composition root (see AppContainer): rewrites a URL to its
  /// loopback-proxied form when the secure context proxy is on. Every load
  /// funnels through here, so callers keep passing the real HA URLs.
  String Function(String url)? urlMapper;

  Future<void> loadUrl(String url) async {
    // An explicit navigation targets the main WebView; an overlay page
    // sitting above it would make the navigation invisible.
    overlayUrl.value = null;
    final mapped = urlMapper?.call(url) ?? url;
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(mapped)));
  }

  /// Evaluate JavaScript and return its stringified result — the REPL in
  /// the console panels. Null when no WebView is attached.
  Future<String?> eval(String code) async {
    final controller = _controller;
    if (controller == null) return null;
    final result = await controller.evaluateJavascript(source: code);
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
    final controller = _controller;
    if (controller == null) return;
    final result = await controller.evaluateJavascript(source: '''
      (function () {
        try {
          var ha = document.querySelector('home-assistant');
          var conn = ha && ha.hass && ha.hass.connection;
          if (!conn) return 'no-connection';
          if (typeof conn.reconnect === 'function') {
            conn.reconnect(true);
            return 'reconnect';
          }
          if (conn.socket) {
            conn.socket.close();
            return 'socket-closed';
          }
          return 'no-socket';
        } catch (e) { return 'error: ' + e; }
      })()
    ''');
    log.info(name, 'HA socket nudge: $result');
  }

  /// True when the Home Assistant frontend's websocket is live right now.
  Future<bool> _haConnected() async {
    final controller = _controller;
    if (controller == null) return false;
    final r = await controller.evaluateJavascript(source: '''
      (function () {
        try {
          var c = document.querySelector('home-assistant');
          c = c && c.hass && c.hass.connection;
          return !!(c && c.connected && c.socket && c.socket.readyState === 1);
        } catch (e) { return false; }
      })()
    ''');
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
    if (_controller == null) return false;
    if (await _haConnected()) return true;
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
  /// UI layer, e.g. applying/removing kiosk-mode CSS).
  Future<void> runJs(String source) async {
    try {
      await _controller?.evaluateJavascript(source: source);
    } catch (e) {
      log.debug(name, 'runJs failed: $e');
    }
  }

  static String _stripSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
