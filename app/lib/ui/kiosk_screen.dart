import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kiosk_drawer.dart';
import 'web_console_panel.dart';

/// The kiosk itself: a fullscreen WebView with the JS bridge, the
/// screensaver overlay, and a slide-out menu (swipe from the left edge —
/// Fully Kiosk behavior).
class KioskScreen extends StatefulWidget {
  const KioskScreen({
    super.key,
    required this.container,
    this.showMenuHint = false,
  });

  final AppContainer container;

  /// Show the menu-gesture hint once (set when arriving from the wizard).
  final bool showMenuHint;

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  AppContainer get c => widget.container;

  bool _consoleOpen = false;
  StreamSubscription<SettingChanged>? _kioskModeSub;

  @override
  void initState() {
    super.initState();

    // HA kiosk mode is applied live (per navigation + on setting change), so
    // toggling it never needs an app restart.
    _kioskModeSub = c.bus.on<SettingChanged>().listen((e) async {
      if (e.key != defs.haKioskMode.key) return;
      if (e.value == 'auto' && c.homeAssistant.configured) {
        await c.homeAssistant.detectKioskModePlugin();
      }
      await _applyKioskMode();
      // Reload so the plugin's ?kiosk param takes / drops cleanly.
      await c.browser.loadUrl(_initialUrl);
    });

    if (widget.showMenuHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tip: swipe from the left edge to open the menu'),
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ));
      });
    }
  }

  /// Resolve `auto` to a concrete strategy using plugin detection:
  /// `plugin` (defer to the HACS plugin) or `css` (inject our fallback).
  String get _effectiveKioskMode {
    final mode = c.settings.get(defs.haKioskMode);
    if (mode == 'auto') {
      return c.homeAssistant.kioskPluginDetected ? 'plugin' : 'css';
    }
    return mode;
  }

  bool get _usePlugin => _effectiveKioskMode == 'plugin';
  bool get _useCss => _effectiveKioskMode == 'css';

  String get _initialUrl {
    final url = c.settings.get(defs.startUrl);
    return _usePlugin ? withKioskParam(url) : url;
  }

  /// The JS bridge is always injected at document start. The kiosk-mode CSS
  /// is applied per-load in [onLoadStop] (not a fixed initial script) so it
  /// can be toggled live.
  List<UserScript> get _userScripts => [c.jsApi.buildUserScript(c.device.os)];

  /// Apply or tear down the CSS kiosk mode against the current page.
  Future<void> _applyKioskMode() async {
    await c.browser.runJs(kioskModeScript(apply: _useCss));
  }

  @override
  void dispose() {
    _kioskModeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: KioskDrawer(
        container: c,
        onWebConsole: () => setState(() => _consoleOpen = true),
      ),
      drawerEdgeDragWidth: 48,
      body: Listener(
        onPointerDown: (_) =>
            c.bus.publish(const ActivityDetected(source: 'touch')),
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_initialUrl)),
              initialUserScripts: UnmodifiableListView(_userScripts),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllow: 'camera; microphone',
                transparentBackground: true,
              ),
              onWebViewCreated: (controller) {
                c.browser.attach(controller);
                c.jsApi.attach(controller);
              },
              onLoadStop: (controller, url) {
                if (url != null) c.browser.onPageLoaded(url.toString());
                // Re-apply CSS kiosk mode on every navigation (only does
                // work when the effective mode is 'css').
                if (_useCss) _applyKioskMode();
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame ?? true) {
                  c.browser.onLoadError(error.description);
                }
              },
              onConsoleMessage: (controller, message) {
                c.browser.onConsoleMessage(
                  switch (message.messageLevel) {
                    ConsoleMessageLevel.ERROR => 'error',
                    ConsoleMessageLevel.WARNING => 'warn',
                    ConsoleMessageLevel.DEBUG => 'debug',
                    ConsoleMessageLevel.TIP => 'tip',
                    _ => 'log',
                  },
                  message.message,
                );
              },
              onPermissionRequest: (controller, request) async {
                // The Voice Satellite card needs the mic for STT; motion
                // demos may want the camera. Kiosk devices are dedicated,
                // so grant what the page asks for.
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
            ),
            if (_consoleOpen)
              WebConsolePanel(
                browser: c.browser,
                onClose: () => setState(() => _consoleOpen = false),
              ),
            // Screensaver black overlay ('black' mode) — tap to dismiss.
            ValueListenableBuilder<bool>(
              valueListenable: c.screensaver.overlayActive,
              builder: (context, active, _) => active
                  ? GestureDetector(
                      onTap: () => c.screensaver.notifyActivity('touch'),
                      child: Container(color: Colors.black),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
