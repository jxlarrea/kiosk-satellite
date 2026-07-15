import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
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
      ..register(Command(
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
      ))
      ..register(Command(
        name: 'loadDashboard',
        description: 'Navigate to a Home Assistant dashboard',
        params: const {'dashboard': 'Dashboard url_path, e.g. lovelace'},
        handler: (p) async {
          final dashboard = p['dashboard'] as String?;
          final base = _settings.get(defs.haUrl);
          if (dashboard == null || base.isEmpty) {
            return const CommandResult.fail(
                'dashboard required and Home Assistant URL must be configured');
          }
          await loadUrl('${_stripSlash(base)}/$dashboard');
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
        name: 'reload',
        description: 'Reload the current page',
        handler: (_) async {
          await _controller?.reload();
          return const CommandResult.ok();
        },
      ))
      ..register(Command(
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
      ))
      ..register(Command(
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
      ))
      ..register(Command(
        name: 'screenshot',
        description: 'Capture the current page as a base64 PNG',
        handler: (_) async {
          final controller = _controller;
          if (controller == null) {
            return const CommandResult.fail('no webview attached');
          }
          final bytes = await controller.takeScreenshot();
          if (bytes == null) {
            return const CommandResult.fail('screenshot failed');
          }
          return CommandResult.ok(base64Encode(bytes));
        },
      ));
  }

  void attach(InAppWebViewController controller) {
    _controller = controller;
  }

  /// Called by the UI layer from the WebView's onConsoleMessage.
  void onConsoleMessage(String level, String message) {
    if (consoleEntries.length >= _consoleCapacity) {
      consoleEntries.removeAt(0);
    }
    consoleEntries.add(ConsoleEntry(DateTime.now(), level, message));
    consoleRevision.value++;
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

  static String _stripSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
