import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';

import '../app_container.dart';
import 'screensaver_view.dart';
import '../core/events.dart';
import '../managers/browser/no_cache_script.dart';
import '../managers/home_assistant/kiosk_mode.dart';
import '../managers/settings/definitions.dart' as defs;
import 'kiosk_drawer.dart';
import 'settings_screen.dart';
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

class _KioskScreenState extends State<KioskScreen>
    with SingleTickerProviderStateMixin {
  AppContainer get c => widget.container;

  bool _consoleOpen = false;
  StreamSubscription<SettingChanged>? _settingsSub;

  /// The push drawer: the kiosk content slides right in step with the pane,
  /// so the menu reads as sharing the kiosk's plane instead of floating over
  /// it. 0 = closed, 1 = fully open; dragged directly during edge swipes.
  /// Narrow on purpose — the widest thing in it is "Exit Application".
  static const _drawerWidth = 300.0;
  late final AnimationController _drawer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  void _closeDrawer() => _drawer.fling(velocity: -1);

  void _drawerDragUpdate(DragUpdateDetails details) {
    _drawer.value += details.delta.dx / _drawerWidth;
  }

  void _drawerDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx / _drawerWidth;
    if (velocity.abs() > 1) {
      _drawer.fling(velocity: velocity.sign);
    } else {
      _drawer.fling(velocity: _drawer.value > 0.5 ? 1 : -1);
    }
  }

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
    // Mixed-content / SSL / cache are read only at WebView creation — rebuild
    // it (preserving the current URL) so the change applies without a restart.
    // The rebuild is storage-safe: localStorage is per-origin and outlives the
    // widget, so a page's saved config is not lost.
    if (e.key == defs.allowMixedContent.key ||
        e.key == defs.ignoreSslErrors.key ||
        e.key == defs.disableCache.key) {
      setState(() => _webViewEpoch++);
      return;
    }
    // Wake word detection is negotiated with the Voice Satellite card at page
    // load (it asks whether we can run its engine natively, and we answer with
    // our own enabled setting). Reload so that handoff is re-evaluated:
    // turning it on hands detection to us, turning it off gives it back to the
    // browser engine.
    if (e.key == defs.wakeWordEnabled.key) {
      await c.browser.runJs('location.reload();');
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
        await ensureOsPermission(permission);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tip: swipe from the left edge to open the menu'),
            duration: Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
  List<UserScript> get _userScripts => [
    c.jsApi.buildUserScript(c.device.os),
    // "Disable cache" must also defeat the page's service worker, which
    // caches above the HTTP layer (HA always registers one).
    if (c.settings.get(defs.disableCache))
      UserScript(
        source: noCachePurgeScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
  ];

  /// Apply or tear down the CSS kiosk mode against the current page.
  Future<void> _applyKioskMode() async {
    await c.browser.runJs(kioskModeScript(apply: _useCss));
  }

  /// Open the settings screen (One UI-style split view on wide screens).
  Future<void> _openSettings() async {
    // Hold the screensaver while settings are open. Otherwise the idle timer
    // keeps firing behind the route: it dims the backlight and, with motion
    // on, opens the camera while someone is configuring. Re-arm on return.
    await c.commands.execute('pauseScreensaver', {'paused': true});
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SettingsScreen(container: c)),
      );
    }
    await c.commands.execute('pauseScreensaver', {'paused': false});
  }

  /// Whether a WebView permission request may be granted: its Web Content
  /// toggle must be on and the OS runtime grant must be held (requested
  /// lazily here — never all-at-once at launch).
  Future<bool> _resourceAllowed(PermissionResourceType resource) async {
    if (resource == PermissionResourceType.MICROPHONE) {
      return c.settings.get(defs.webMicrophone) &&
          await ensureOsPermission(Permission.microphone);
    }
    if (resource == PermissionResourceType.CAMERA) {
      return c.settings.get(defs.webCamera) &&
          await ensureOsPermission(Permission.camera);
    }
    if (resource == PermissionResourceType.GEOLOCATION) {
      return c.settings.get(defs.webGeolocation) &&
          await ensureOsPermission(Permission.location);
    }
    // Anything else the page asks for (e.g. protected media id) follows the
    // camera/mic decision conservatively: deny unless explicitly handled.
    return false;
  }

  @override
  void dispose() {
    _drawer.dispose();
    _settingsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) =>
            c.bus.publish(const ActivityDetected(source: 'touch')),
        child: AnimatedBuilder(
          animation: _drawer,
          builder: (context, _) {
            final dx = _drawerWidth * _drawer.value;
            final open = _drawer.value > 0;
            return PopScope(
              // System back closes the drawer first; only a closed kiosk
              // keeps the default back behavior.
              canPop: !open,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) _closeDrawer();
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The kiosk plane, pushed right in step with the drawer.
                  // It keeps its full size — it slides, it is never squeezed
                  // (resizing the platform view would reflow the page).
                  Positioned(
                    left: dx,
                    top: 0,
                    bottom: 0,
                    width: size.width,
                    child: Stack(
                      // Expand: the Stack takes its size from its parent,
                      // never from its children — the overlays are positioned
                      // or zero-sized and would collapse a child-sized Stack.
                      fit: StackFit.expand,
                      children: [
                        _webView(),
                        if (_consoleOpen)
                          WebConsolePanel(
                            browser: c.browser,
                            onClose: () => setState(() => _consoleOpen = false),
                          ),
                      ],
                    ),
                  ),
                  // The drawer plane, sliding in from the same seam. A
                  // horizontal drag anywhere on it moves the drawer too —
                  // swiping the menu itself closed is the intuitive gesture,
                  // not just swiping the kiosk. Taps and vertical scrolling
                  // inside the menu are untouched (different gesture axes).
                  Positioned(
                    left: dx - _drawerWidth,
                    top: 0,
                    bottom: 0,
                    width: _drawerWidth,
                    child: GestureDetector(
                      onHorizontalDragUpdate: _drawerDragUpdate,
                      onHorizontalDragEnd: _drawerDragEnd,
                      child: KioskDrawer(
                        container: c,
                        onClose: _closeDrawer,
                        onWebConsole: () => setState(() => _consoleOpen = true),
                        onSettings: _openSettings,
                      ),
                    ),
                  ),
                  // While open, the visible slice of the kiosk closes the
                  // drawer on tap or drag — no scrim: dimming the content
                  // would put the drawer visually "above" it again.
                  if (open)
                    Positioned(
                      left: dx,
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeDrawer,
                        onHorizontalDragUpdate: _drawerDragUpdate,
                        onHorizontalDragEnd: _drawerDragEnd,
                      ),
                    ),
                  // Closed: the edge strip that swipes it open.
                  if (!open)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 48,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate: _drawerDragUpdate,
                        onHorizontalDragEnd: _drawerDragEnd,
                      ),
                    ),
                  // The screensaver covers both planes — it owns the whole
                  // display, drawer open or not.
                  ScreensaverOverlay(container: c),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _webView() => InAppWebView(
    key: ValueKey(_webViewEpoch),
    initialUrlRequest: URLRequest(
      url: WebUri(
        _webViewEpoch == 0 || c.browser.currentUrl.isEmpty
            ? _initialUrl
            : c.browser.currentUrl,
      ),
    ),
    initialUserScripts: UnmodifiableListView(_userScripts),
    initialSettings: InAppWebViewSettings(
      // Hybrid composition, decided twice. Virtual display (false) freed
      // Flutter animations from syncing with the Android UI thread, but it
      // paced the WebView itself badly: a constantly-animating dashboard
      // pushes every frame through an extra texture copy, dropping frames
      // on the page and stuttering the whole UI. The kiosk *is* the
      // WebView — its scrolling wins. Flutter animates over the live view
      // only for the brief drawer slide; settings is an opaque route, so
      // the view is not even composited while it is open.
      useHybridComposition: true,
      mediaPlaybackRequiresUserGesture: !c.settings.get(defs.webAutoplay),
      allowsInlineMediaPlayback: true,
      iframeAllow: 'camera; microphone',
      transparentBackground: true,
      geolocationEnabled: c.settings.get(defs.webGeolocation),
      javaScriptCanOpenWindowsAutomatically: c.settings.get(defs.webPopups),
      // Android: let HTTPS pages pull in HTTP subresources.
      mixedContentMode: c.settings.get(defs.allowMixedContent)
          ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
          : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      // Dev aid: always hit the network so an edited dashboard or
      // card bundle is never served from a stale cache. This only
      // bypasses the HTTP cache — it does NOT touch localStorage /
      // DOM storage (kept alive by domStorageEnabled, which stays
      // on), so a page's saved config survives. Nothing is cleared;
      // only "Log out" deliberately wipes storage.
      cacheEnabled: !c.settings.get(defs.disableCache),
      cacheMode: c.settings.get(defs.disableCache)
          ? CacheMode.LOAD_NO_CACHE
          : CacheMode.LOAD_DEFAULT,
    ),
    onReceivedServerTrustAuthRequest: (controller, challenge) async {
      // Accept untrusted/self-signed certs only when the user opted
      // in (e.g. a local HA instance without proper SSL). Otherwise
      // fall through to the platform's default validation.
      if (c.settings.get(defs.ignoreSslErrors)) {
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      }
      return ServerTrustAuthResponse(
        action: ServerTrustAuthResponseAction.CANCEL,
      );
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
      c.browser.onConsoleMessage(switch (message.messageLevel) {
        ConsoleMessageLevel.ERROR => 'error',
        ConsoleMessageLevel.WARNING => 'warn',
        ConsoleMessageLevel.DEBUG => 'debug',
        ConsoleMessageLevel.TIP => 'tip',
        _ => 'log',
      }, message.message);
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
  );
}
