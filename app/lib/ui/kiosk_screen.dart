import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

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
  StreamSubscription<SettingChanged>? _settingsSub;

  /// Bumped to force a WebView rebuild for settings that are only read at
  /// creation (mixed content, SSL trust). Rebuilding re-reads initialSettings.
  int _webViewEpoch = 0;

  Future<void> _onSettingChanged(SettingChanged e) async {
    // HA kiosk mode is applied live (no app restart).
    if (e.key == defs.haKioskMode.key) {
      if (e.value == 'auto' && c.homeAssistant.configured) {
        await c.homeAssistant.detectKioskModePlugin();
      }
      await _applyKioskMode();
      await c.browser.loadUrl(_initialUrl); // reload so ?kiosk takes/drops
      return;
    }
    // Mixed-content / SSL are read only at WebView creation — rebuild it
    // (preserving the current URL) so the change applies without a restart.
    if (e.key == defs.allowMixedContent.key ||
        e.key == defs.ignoreSslErrors.key) {
      setState(() => _webViewEpoch++);
      return;
    }
    // Enabling a media toggle proactively requests its OS grant (Fully-style),
    // then reloads so the page can re-request now that access is allowed.
    if (e.value == true) {
      Permission? permission;
      if (e.key == defs.webMicrophone.key) permission = Permission.microphone;
      if (e.key == defs.webCamera.key) permission = Permission.camera;
      if (e.key == defs.webGeolocation.key) permission = Permission.location;
      if (permission != null) {
        await _ensureOsPermission(permission);
        await c.browser.runJs('location.reload();');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _settingsSub = c.bus.on<SettingChanged>().listen(_onSettingChanged);

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

  /// Whether a WebView permission request may be granted: its Web Content
  /// toggle must be on and the OS runtime grant must be held (requested
  /// lazily here — never all-at-once at launch).
  Future<bool> _resourceAllowed(PermissionResourceType resource) async {
    if (resource == PermissionResourceType.MICROPHONE) {
      return c.settings.get(defs.webMicrophone) &&
          await _ensureOsPermission(Permission.microphone);
    }
    if (resource == PermissionResourceType.CAMERA) {
      return c.settings.get(defs.webCamera) &&
          await _ensureOsPermission(Permission.camera);
    }
    if (resource == PermissionResourceType.GEOLOCATION) {
      return c.settings.get(defs.webGeolocation) &&
          await _ensureOsPermission(Permission.location);
    }
    // Anything else the page asks for (e.g. protected media id) follows the
    // camera/mic decision conservatively: deny unless explicitly handled.
    return false;
  }

  Future<bool> _ensureOsPermission(Permission permission) async {
    var status = await permission.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    status = await permission.request();
    return status.isGranted;
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
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
              key: ValueKey(_webViewEpoch),
              initialUrlRequest: URLRequest(
                url: WebUri(_webViewEpoch == 0 ||
                        c.browser.currentUrl.isEmpty
                    ? _initialUrl
                    : c.browser.currentUrl),
              ),
              initialUserScripts: UnmodifiableListView(_userScripts),
              initialSettings: InAppWebViewSettings(
                mediaPlaybackRequiresUserGesture:
                    !c.settings.get(defs.webAutoplay),
                allowsInlineMediaPlayback: true,
                iframeAllow: 'camera; microphone',
                transparentBackground: true,
                geolocationEnabled: c.settings.get(defs.webGeolocation),
                javaScriptCanOpenWindowsAutomatically:
                    c.settings.get(defs.webPopups),
                // Android: let HTTPS pages pull in HTTP subresources.
                mixedContentMode: c.settings.get(defs.allowMixedContent)
                    ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
                    : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
              ),
              onReceivedServerTrustAuthRequest: (controller, challenge) async {
                // Accept untrusted/self-signed certs only when the user opted
                // in (e.g. a local HA instance without proper SSL). Otherwise
                // fall through to the platform's default validation.
                if (c.settings.get(defs.ignoreSslErrors)) {
                  return ServerTrustAuthResponse(
                      action: ServerTrustAuthResponseAction.PROCEED);
                }
                return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.CANCEL);
              },
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
                // Fully-Kiosk-style: grant a resource only if its Web Content
                // toggle is on, ensuring the OS runtime grant lazily.
                final granted = <PermissionResourceType>[];
                for (final resource in request.resources) {
                  if (await _resourceAllowed(resource)) granted.add(resource);
                }
                return PermissionResponse(
                  resources: granted,
                  action: granted.isEmpty
                      ? PermissionResponseAction.DENY
                      : PermissionResponseAction.GRANT,
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
