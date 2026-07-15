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

  @override
  void initState() {
    super.initState();
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

  String get _initialUrl {
    var url = c.settings.get(defs.startUrl);
    final kioskMode = c.settings.get(defs.haKioskMode);
    if (kioskMode == 'plugin' || kioskMode == 'auto') {
      url = withKioskParam(url);
    }
    return url;
  }

  List<UserScript> get _userScripts {
    final kioskMode = c.settings.get(defs.haKioskMode);
    return [
      c.jsApi.buildUserScript(c.device.os),
      if (kioskMode == 'css' || kioskMode == 'auto')
        UserScript(
          source: kioskModeCss,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
        ),
    ];
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
