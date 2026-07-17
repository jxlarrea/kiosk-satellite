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

  @override
  Future<void> init() async {
    commands
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
  /// it, then is written and the page reloaded so it takes effect. Cleared
  /// before the write — the reload lands back here, and a still-pending
  /// payload would loop forever.
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
          location.reload();
        } catch (e) {}
      })();
    ''');
  }

  /// Called by the UI layer on load errors and render-process crashes.
  Future<void> onLoadError(String description) async {
    log.warn(name, 'load error: $description');
    if (_settings.get(defs.autoReloadOnError)) {
      await Future<void>.delayed(const Duration(seconds: 5));
      await _controller?.reload();
    }
  }

  Future<void> loadUrl(String url) async {
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
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
