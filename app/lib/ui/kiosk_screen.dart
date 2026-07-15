import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/settings/definitions.dart' as defs;
import 'settings_screen.dart';

/// The kiosk itself: a fullscreen WebView with the JS bridge, the
/// screensaver overlay, and a hidden settings gesture (5 taps in the
/// top-left corner).
class KioskScreen extends StatefulWidget {
  const KioskScreen({super.key, required this.container});

  final AppContainer container;

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  AppContainer get c => widget.container;

  int _cornerTaps = 0;
  DateTime _lastCornerTap = DateTime.fromMillisecondsSinceEpoch(0);

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

  void _onPointerDown(PointerDownEvent event) {
    c.bus.publish(const ActivityDetected(source: 'touch'));

    // Hidden settings gesture: 5 quick taps in the top-left corner.
    final inCorner = event.position.dx < 100 && event.position.dy < 100;
    final now = DateTime.now();
    if (inCorner && now.difference(_lastCornerTap).inSeconds < 2) {
      _cornerTaps++;
      if (_cornerTaps >= 5) {
        _cornerTaps = 0;
        _openSettings();
      }
    } else {
      _cornerTaps = inCorner ? 1 : 0;
    }
    _lastCornerTap = now;
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(container: c),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: _onPointerDown,
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
