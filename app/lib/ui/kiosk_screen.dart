import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/permissions.dart';

import '../app_container.dart';
import 'screensaver_view.dart';
import '../core/events.dart';
import '../managers/browser/no_cache_script.dart';
import '../managers/browser/pull_to_refresh_script.dart';
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
  StreamSubscription<KioskExitGesture>? _gestureSub;
  StreamSubscription<KioskBackPressed>? _backSub;

  /// Guards the exit gesture while the settings route sits on top.
  bool _settingsOpen = false;

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

  /// Pull-to-refresh, Fully style. The native wrapper handles pages that fit
  /// the screen; scrollable pages never hand it the gesture (Chromium claims
  /// every vertical drag), so those report their pulls through the JS probe
  /// (see pull_to_refresh_script.dart) into [_triggerRefresh]. The spinner is
  /// ended from onLoadStop / onReceivedError — the reload's own completion —
  /// never on a timer.
  late final PullToRefreshController _pullToRefresh = PullToRefreshController(
    settings: PullToRefreshSettings(
      enabled: c.settings.get(defs.pullToRefresh),
      color: const Color(0xFF749C6F), // brand sage on the stock spinner
    ),
    onRefresh: _triggerRefresh,
  );

  /// One refresh at a time, whichever side asked for it: the guard keeps the
  /// native gesture and the JS probe from doubling up on pages where both
  /// fire. Reset when the reload settles — and by [_refreshingFailsafe],
  /// because the reload is not guaranteed to settle: a pull racing an
  /// in-flight navigation runs the reload script in a dying document, no
  /// onLoadStop ever follows, and a guard with no way back would silently
  /// swallow every pull from then on.
  bool _refreshing = false;
  Timer? _refreshingFailsafe;

  Future<void> _triggerRefresh() async {
    c.log.info(
      'kiosk',
      'pull trigger: refreshing=$_refreshing '
          'enabled=${c.settings.get(defs.pullToRefresh)}',
    );
    if (_refreshing || !c.settings.get(defs.pullToRefresh)) return;
    _refreshing = true;
    _refreshingFailsafe?.cancel();
    _refreshingFailsafe = Timer(const Duration(seconds: 8), () {
      _refreshing = false;
    });
    // No beginRefreshing here: the native gesture already shows its spinner,
    // and the JS probe draws (and keeps) its own — awaiting the platform
    // spinner from a bridge callback is what once held the reload hostage.
    //
    // The cache-clearing pull is NOT the menu's Clear web cache: it empties
    // the HTTP cache and Cache Storage but leaves the service worker
    // registered (see pullRefreshClearScript — unregistering it mid-session
    // is what made pages reload themselves half a minute later). A plain
    // pull is just the reload.
    if (c.settings.get(defs.pullToRefreshClearCache)) {
      await InAppWebViewController.clearAllCache();
      // The wake word models are cached by URL too — a model re-published
      // on Home Assistant under the same name is invisible until its cache
      // is dropped, and a clearing pull should mean all the caches. Dropped
      // before the reload so the page's wake-word handshake re-downloads.
      await c.commands.execute('clearWakeWordModels', const {});
      await c.browser.runJs(pullRefreshClearScript);
    } else {
      await c.commands.execute('reload', const {});
    }
  }

  Future<void> _onSettingChanged(SettingChanged e) async {
    // HA kiosk mode is applied live (no app restart). The hide choices
    // ride the same path: re-resolve, re-style, reload for the params.
    if (e.key == defs.haKioskMode.key ||
        e.key == defs.haKioskHideHeader.key ||
        e.key == defs.haKioskHideSidebar.key) {
      if (e.value == 'auto' && c.homeAssistant.configured) {
        await c.homeAssistant.detectKioskModePlugin();
      }
      await _applyKioskMode();
      await c.browser.loadUrl(_initialUrl); // reload so ?kiosk takes/drops
      return;
    }
    // Mixed-content / SSL / cache / zoom are read only at WebView creation —
    // rebuild it (preserving the current URL) so the change applies without
    // a restart. The rebuild is storage-safe: localStorage is per-origin and
    // outlives the widget, so a page's saved config is not lost.
    if (e.key == defs.allowMixedContent.key ||
        e.key == defs.ignoreSslErrors.key ||
        e.key == defs.disableCache.key ||
        e.key == defs.pinchToZoom.key ||
        e.key == defs.kioskDisableContextMenus.key) {
      setState(() => _webViewEpoch++);
      return;
    }
    // Kiosk mode swaps the drawer swipe for the exit gesture (KioskManager
    // pushes the native flags itself; this re-renders the gate — and
    // rebuilds the WebView when the master switch changes whether the
    // context-menu suppression is in force).
    if (e.key == defs.kioskEnabled.key) {
      setState(() {
        if (c.settings.get(defs.kioskDisableContextMenus)) _webViewEpoch++;
      });
      return;
    }
    // Pull-to-refresh toggles live on the existing WebView; the clear-cache
    // companion is read at pull time and needs nothing here.
    if (e.key == defs.pullToRefresh.key) {
      await _pullToRefresh.setEnabled(e.value == true);
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
    // Voice Satellite reads getScreensaverSuppressed once per page load, so
    // anything that changes the answer re-negotiates with a reload. The
    // screensaver toggle only matters while suppression is on.
    if (e.key == defs.vsSuppressScreensaver.key ||
        (e.key == defs.screensaverEnabled.key &&
            c.settings.get(defs.vsSuppressScreensaver))) {
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
    _gestureSub = c.bus.on<KioskExitGesture>().listen(_onExitGesture);
    _backSub = c.bus.on<KioskBackPressed>().listen((_) {
      if (!mounted || _settingsOpen) return;
      if (_drawer.value > 0) {
        _closeDrawer();
      } else {
        c.browser.goBack();
      }
    });

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

  /// `auto` hedges instead of choosing: the plugin params ride the URL when
  /// the plugin was detected, and the CSS fallback is injected regardless.
  /// Detection only proves the plugin file exists on the server, not that it
  /// still works against this HA release (its resource can be served while
  /// its frontend hook silently fails, as HA's new drawer generation showed),
  /// and the styles are idempotent so doubling up when the plugin does work
  /// changes nothing visible.
  String get _kioskMode => c.settings.get(defs.haKioskMode);

  bool get _usePlugin =>
      _kioskMode == 'plugin' ||
      (_kioskMode == 'auto' && c.homeAssistant.kioskPluginDetected);
  bool get _useCss => _kioskMode == 'css' || _kioskMode == 'auto';

  String get _initialUrl {
    final url = c.settings.get(defs.startUrl);
    return _usePlugin
        ? withKioskParam(
            url,
            hideHeader: c.settings.get(defs.haKioskHideHeader),
            hideSidebar: c.settings.get(defs.haKioskHideSidebar),
          )
        : url;
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
    // Always injected, acted on only while the setting is on (checked in
    // _triggerRefresh) — so the toggle needs no page reload to take effect.
    UserScript(
      source: pullToRefreshProbeScript,
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    ),
    // The wizard's satellite choice, handed to Voice Satellite before its
    // code runs: VS reads localStorage['vs-satellite-entity'], selects that
    // assist_satellite, hydrates its server-side profile and starts. Only
    // seeded while the key is absent — a satellite changed in the page
    // afterwards must win over a stale wizard choice.
    if (c.settings.get(defs.haSatelliteEntity).isNotEmpty)
      UserScript(
        source:
            '''
          try {
            if (!localStorage.getItem('vs-satellite-entity')) {
              localStorage.setItem('vs-satellite-entity',
                ${jsonEncode(c.settings.get(defs.haSatelliteEntity))});
            }
          } catch (_) {}
        ''',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
    // Belt to disableContextMenu's braces: the native flag stops the action
    // mode, this stops the selection ever forming (and the web contextmenu).
    if (c.kiosk.locked && c.settings.get(defs.kioskDisableContextMenus))
      UserScript(
        source: '''
          document.addEventListener('contextmenu', (e) => e.preventDefault(), true);
          const s = document.createElement('style');
          s.textContent = '* { -webkit-user-select: none !important; user-select: none !important; }';
          document.addEventListener('DOMContentLoaded', () => document.head.appendChild(s));
        ''',
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
  ];

  /// Apply or tear down the CSS kiosk mode against the current page.
  Future<void> _applyKioskMode() async {
    await c.browser.runJs(
      kioskModeScript(
        apply: _useCss,
        hideHeader: c.settings.get(defs.haKioskHideHeader),
        hideSidebar: c.settings.get(defs.haKioskHideSidebar),
      ),
    );
  }

  /// Open the settings screen (One UI-style split view on wide screens).
  Future<void> _openSettings() async {
    // Hold the screensaver while settings are open. Otherwise the idle timer
    // keeps firing behind the route: it dims the backlight and, with motion
    // on, opens the camera while someone is configuring. Re-arm on return.
    await c.commands.execute('pauseScreensaver', {'paused': true});
    _settingsOpen = true;
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SettingsScreen(container: c)),
      );
    }
    _settingsOpen = false;
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

  /// The kiosk exit gesture: N fast taps, counted natively so they land
  /// even though the WebView swallows its pointers. PIN first when one is
  /// set; the prize is just the menu — every escape route stays behind its
  /// own confirmation.
  Future<void> _onExitGesture(KioskExitGesture _) async {
    if (!mounted || _settingsOpen || _drawer.value > 0) return;
    if (c.kiosk.pinRequired) {
      final ok = await _askPin();
      if (!ok || !mounted) return;
    }
    _drawer.fling(velocity: 1);
  }

  Future<bool> _askPin() async {
    final controller = TextEditingController();
    var failed = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kiosk PIN'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'PIN',
              errorText: failed ? 'Wrong PIN' : null,
            ),
            onSubmitted: (v) {
              if (c.kiosk.pinMatches(v)) {
                Navigator.pop(context, true);
              } else {
                setDialogState(() => failed = true);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (c.kiosk.pinMatches(controller.text)) {
                  Navigator.pop(context, true);
                } else {
                  setDialogState(() => failed = true);
                }
              },
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return ok ?? false;
  }

  @override
  void dispose() {
    _refreshingFailsafe?.cancel();
    _drawer.dispose();
    _settingsSub?.cancel();
    _gestureSub?.cancel();
    _backSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Built once per build(), NOT once per animation tick. The
    // AnimatedBuilder below runs its builder every frame of the drawer
    // slide; the planes themselves never change during it — only their
    // positions do. Rebuilding the WebView widget (and re-reading every
    // initialSettings value) per frame would be pure waste, spent at the
    // exact moment the platform view is being moved.
    final kioskPlane = Stack(
      // Expand: the Stack takes its size from its parent, never from its
      // children — the overlays are positioned or zero-sized and would
      // collapse a child-sized Stack.
      fit: StackFit.expand,
      children: [
        _webView(),
        if (_consoleOpen)
          WebConsolePanel(
            browser: c.browser,
            onClose: () => setState(() => _consoleOpen = false),
          ),
      ],
    );
    // A horizontal drag anywhere on the drawer moves it too — swiping the
    // menu itself closed is the intuitive gesture, not just swiping the
    // kiosk. Taps and vertical scrolling inside the menu are untouched
    // (different gesture axes).
    final drawerPane = GestureDetector(
      onHorizontalDragUpdate: _drawerDragUpdate,
      onHorizontalDragEnd: _drawerDragEnd,
      child: KioskDrawer(
        container: c,
        onClose: _closeDrawer,
        onWebConsole: () => setState(() => _consoleOpen = true),
        onSettings: _openSettings,
      ),
    );
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
              // System back closes the drawer first. A closed kiosk keeps
              // the default behavior — except in kiosk mode, where back must
              // never background the app: it steps the page's history
              // instead. This is the predictive-back path; devices that
              // still deliver Back as a KeyEvent are caught in KioskLock
              // before it ever reaches here, and land in the same handling
              // via KioskBackPressed.
              canPop: !open && !c.kiosk.locked,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (open) {
                  _closeDrawer();
                } else {
                  c.browser.goBack();
                }
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
                    child: kioskPlane,
                  ),
                  // The drawer plane, sliding in from the same seam.
                  Positioned(
                    left: dx - _drawerWidth,
                    top: 0,
                    bottom: 0,
                    width: _drawerWidth,
                    child: drawerPane,
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
                  // Closed: the edge strip that swipes it open — unless
                  // kiosk mode holds the door; then only the exit gesture
                  // (and its PIN) opens the menu.
                  if (!open && !c.kiosk.locked)
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
    pullToRefreshController: _pullToRefresh,
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
      // Long-press menus and text selection, when kiosk mode says so.
      disableContextMenu:
          c.kiosk.locked && c.settings.get(defs.kioskDisableContextMenus),
      // Pinch zoom needs both flags on Android; the on-screen +/- buttons
      // stay off regardless — a kiosk shows no browser chrome.
      supportZoom: c.settings.get(defs.pinchToZoom),
      builtInZoomControls: c.settings.get(defs.pinchToZoom),
      displayZoomControls: false,
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
      // Scrollable pages report their pulls here (see _pullToRefresh).
      controller.addJavaScriptHandler(
        handlerName: 'ksPullToRefresh',
        callback: (_) => _triggerRefresh(),
      );
    },
    onLoadStop: (controller, url) {
      _refreshing = false;
      _refreshingFailsafe?.cancel();
      _pullToRefresh.endRefreshing();
      if (url != null) c.browser.onPageLoaded(url.toString());
      // Re-apply CSS kiosk mode on every navigation (only does
      // work when the effective mode is 'css').
      if (_useCss) _applyKioskMode();
    },
    onReceivedError: (controller, request, error) {
      if (request.isForMainFrame ?? true) {
        _refreshing = false;
        _refreshingFailsafe?.cancel();
        _pullToRefresh.endRefreshing();
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
