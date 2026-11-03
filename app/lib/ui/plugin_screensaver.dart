import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../core/events.dart';
import 'package:kiosk_satellite/core/lifecycle.dart';
import '../managers/plugins/plugin_manager.dart' show PluginNativeOverlay;
import '../managers/settings/definitions.dart' as defs;
import 'plugin_overlay.dart' show PluginNativeOverlays, pluginOverlayTheme;
import 'ui_scale.dart' show UiScaleScope;

/// An isolated rendering document. All input and screensaver policy stays in KS.
String pluginScreensaverDocument(String html) =>
    '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; font-src data:; media-src data: blob:; frame-src about:; connect-src 'none'; form-action 'none'; base-uri 'none'">
<style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#000}iframe{position:absolute;top:0;left:0;border:0;width:100%;height:100%;pointer-events:none}</style></head>
<body><iframe sandbox="allow-scripts" srcdoc="${const HtmlEscape(HtmlEscapeMode.attribute).convert(html)}"></iframe>
<script>
// A new publication loads in a hidden frame and only replaces the shown one
// once it has painted, so a slideshow never drops to black between photos.
let current = document.querySelector('iframe'), pending;
window.ksUpdateDocument = function(html) {
  if (pending) pending.remove();
  const next = document.createElement('iframe');
  next.setAttribute('sandbox', 'allow-scripts');
  next.style.opacity = '0';
  pending = next;
  next.onload = function() {
    requestAnimationFrame(() => requestAnimationFrame(() => {
      if (pending !== next) return;
      next.style.opacity = '1';
      current.remove();
      current = next;
      pending = null;
    }));
  };
  next.srcdoc = html;
  document.body.appendChild(next);
};
</script></body></html>''';

/// Configuration travels in the fragment, never in the local asset request path.
Uri? pluginScreensaverAssetUrl(Map<String, Object?> renderer) {
  final entry = renderer['entry'] as String?;
  final origin = renderer['assetOrigin'] as String?;
  if (entry == null || origin == null) return null;
  return Uri.parse(origin)
      .resolve('/assets/$entry')
      .replace(fragment: renderer['dataJson'] as String? ?? '{}');
}

/// One rendering document and the renderer publication it shows.
typedef PluginDocument = ({Object key, Map<String, Object?> renderer});

/// The documents a plugin screensaver keeps mounted. Inline HTML updates load
/// into the live WebView. Anything else that changes the document's origin or
/// options needs a new one, which loads beneath the shown document and only
/// replaces it once it has painted. A fresh WebView has nothing to draw until
/// then, so swapping right away blanked the screensaver on every asset
/// publication (#918).
class PluginDocuments {
  PluginDocument? shown;
  PluginDocument? next;

  static Object keyOf(Map<String, Object?> renderer) => (
    renderer['entry'],
    renderer['assetOrigin'],
    renderer['assetDirectory'],
    renderer['dataJson'],
  );

  /// Applies a publication, or its removal. Returns true when it starts
  /// loading a new replacement document.
  bool publish(Map<String, Object?>? renderer) {
    if (renderer == null) {
      shown = next = null;
      return false;
    }
    final key = keyOf(renderer);
    final document = (key: key, renderer: renderer);
    if (shown == null || shown!.key == key) {
      shown = document;
      next = null;
      return false;
    }
    final fresh = next?.key != key;
    next = document;
    return fresh;
  }

  /// The replacement with [key] has painted. Returns true when it took over.
  bool ready(Object key) {
    if (next?.key != key) return false;
    shown = next;
    next = null;
    return true;
  }
}

class PluginScreensaver extends StatefulWidget {
  const PluginScreensaver({
    super.key,
    required this.container,
    required this.mode,
  });
  final AppContainer container;
  final String mode;

  @override
  State<PluginScreensaver> createState() => _PluginScreensaverState();
}

class _PluginScreensaverState extends State<PluginScreensaver> {
  final _documents = PluginDocuments();
  Timer? _fallback;

  ValueNotifier<Map<String, Map<String, Object?>>> get _renderers =>
      widget.container.plugins.screensavers;

  /// The mode's renderer when it is a document. A native renderer has no
  /// document to keep mounted.
  Map<String, Object?>? get _document {
    final renderer = _renderers.value[widget.mode];
    return renderer?['view'] == true ? null : renderer;
  }

  @override
  void initState() {
    super.initState();
    _renderers.addListener(_publish);
    _documents.publish(_document);
  }

  @override
  void didUpdateWidget(covariant PluginScreensaver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _fallback?.cancel();
      _documents.publish(null);
      _documents.publish(_document);
    }
  }

  void _publish() {
    if (!mounted) return;
    setState(() {
      if (_documents.publish(_document)) {
        // Swaps anyway when the replacement never reports its first paint,
        // such as one loading while the screen is off.
        _fallback?.cancel();
        final key = _documents.next!.key;
        _fallback = Timer(const Duration(seconds: 3), () => _ready(key));
      }
    });
  }

  void _ready(Object key) {
    if (!mounted || _documents.next?.key != key) return;
    _fallback?.cancel();
    setState(() => _documents.ready(key));
  }

  @override
  void dispose() {
    _renderers.removeListener(_publish);
    _fallback?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderer = _renderers.value[widget.mode];
    if (renderer?['view'] == true) {
      return _NativeScreensaver(
        // A republication builds a fresh view from the new factory.
        key: ValueKey((widget.mode, renderer!['generation'])),
        container: widget.container,
        renderer: renderer,
      );
    }
    final shown = _documents.shown;
    if (shown == null) return const ColoredBox(color: Colors.black);
    final next = _documents.next;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (next != null)
          _Document(
            key: ValueKey((widget.mode, next.key)),
            container: widget.container,
            renderer: next.renderer,
            onReady: () => _ready(next.key),
          ),
        _Document(
          key: ValueKey((widget.mode, shown.key)),
          container: widget.container,
          renderer: shown.renderer,
        ),
      ],
    );
  }
}

class _Document extends StatefulWidget {
  const _Document({
    super.key,
    required this.container,
    required this.renderer,
    this.onReady,
  });
  final AppContainer container;
  final Map<String, Object?> renderer;

  /// Called once the document has loaded and painted.
  final VoidCallback? onReady;
  @override
  State<_Document> createState() => _DocumentState();
}

class _DocumentState extends State<_Document> with WidgetsBindingObserver {
  InAppWebViewController? _controller;
  StreamSubscription<ScreenStateChanged>? _screen;
  StreamSubscription<SettingChanged>? _settings;
  Timer? _shift;
  Offset _offset = Offset.zero;
  bool _screenOn = true;
  bool _foreground = true;
  bool _failed = false;
  bool _loaded = false;
  bool _visible = false;
  String? _html;

  void _checkReady() {
    if (_loaded && _visible) widget.onReady?.call();
  }

  @override
  void initState() {
    super.initState();
    _html = widget.renderer['html'] as String?;
    WidgetsBinding.instance.addObserver(this);
    _foreground = Lifecycle.onScreen;
    // Paused under the native voice overlay too, which shows a still of the
    // screensaver.
    widget.container.screensaver.renderPaused.addListener(_renderPaused);
    _screen = widget.container.bus.on<ScreenStateChanged>().listen((e) {
      _screenOn = e.on;
      unawaited(_activity());
    });
    _settings = widget.container.bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.screensaverPixelShift.key &&
          !widget.container.settings.get(defs.screensaverPixelShift) &&
          mounted) {
        setState(() => _offset = Offset.zero);
      }
    });
    _shift = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted ||
          !_foreground ||
          !_screenOn ||
          !widget.container.settings.get(defs.screensaverPixelShift)) {
        return;
      }
      final max = min(24.0, MediaQuery.sizeOf(context).width * .015);
      final random = Random();
      setState(
        () => _offset = Offset(
          (random.nextDouble() * 2 - 1) * max,
          (random.nextDouble() * 2 - 1) * max,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(covariant _Document oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new publication brings back a renderer that crashed, since the key no
    // longer changes for inline updates.
    if (_failed && widget.renderer['html'] != oldWidget.renderer['html']) {
      _failed = false;
      _loaded = false;
      _controller = null;
      _html = widget.renderer['html'] as String?;
      return;
    }
    unawaited(_updateDocument());
  }

  /// Hands newer inline HTML to the loaded page. Anything that arrives before
  /// the first load finishes is sent from onLoadStop.
  Future<void> _updateDocument() async {
    final html = widget.renderer['html'] as String?;
    if (!_loaded || html == null || html == _html) return;
    _html = html;
    try {
      await _controller?.evaluateJavascript(
        source: 'window.ksUpdateDocument(${jsonEncode(html)});',
      );
    } catch (e) {
      // Retry with the next publication.
      _html = null;
      widget.container.log.warn('plugins', 'Screensaver update failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = !Lifecycle.offScreen(state);
    unawaited(_activity());
  }

  void _renderPaused() => unawaited(_activity());

  Future<void> _activity() async {
    try {
      if (_foreground &&
          _screenOn &&
          !widget.container.screensaver.renderPaused.value) {
        await _controller?.resume();
      } else {
        await _controller?.pause();
      }
    } catch (_) {
      // The renderer may already be disposed during a mode or session change.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.container.screensaver.renderPaused.removeListener(_renderPaused);
    _screen?.cancel();
    _settings?.cancel();
    _shift?.cancel();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetUrl = pluginScreensaverAssetUrl(widget.renderer);
    return ColoredBox(
      color: Colors.black,
      child: _failed
          ? const SizedBox.expand()
          : ClipRect(
              child: Transform.translate(
                offset: _offset,
                child: IgnorePointer(
                  child: InAppWebView(
                    initialUrlRequest: assetUrl == null
                        ? null
                        : URLRequest(url: WebUri.uri(assetUrl)),
                    initialData: assetUrl != null
                        ? null
                        : InAppWebViewInitialData(
                            data: pluginScreensaverDocument(
                              widget.renderer['html'] as String,
                            ),
                          ),
                    initialSettings: InAppWebViewSettings(
                      // The black ColoredBox shows through until the page
                      // paints, instead of the WebView's default white.
                      transparentBackground: true,
                      webViewAssetLoader: assetUrl == null
                          ? null
                          : WebViewAssetLoader(
                              domain: assetUrl.host,
                              httpAllowed: false,
                              pathHandlers: [
                                InternalStoragePathHandler(
                                  path: '/assets/',
                                  directory:
                                      widget.renderer['assetDirectory']
                                          as String,
                                ),
                              ],
                            ),
                      javaScriptEnabled: true,
                      javaScriptBridgeEnabled: false,
                      blockNetworkLoads: true,
                      allowFileAccess: false,
                      allowContentAccess: false,
                      allowFileAccessFromFileURLs: false,
                      allowUniversalAccessFromFileURLs: false,
                      domStorageEnabled: false,
                      supportZoom: false,
                      disableDefaultErrorPage: true,
                      useShouldOverrideUrlLoading: true,
                      mediaPlaybackRequiresUserGesture: true,
                    ),
                    shouldOverrideUrlLoading: (_, action) async =>
                        (assetUrl == null
                            ? const [
                                'about:blank',
                                'about:srcdoc',
                              ].contains(action.request.url.toString())
                            : action.request.url?.origin == assetUrl.origin &&
                                  action.request.url?.path == assetUrl.path)
                        ? NavigationActionPolicy.ALLOW
                        : NavigationActionPolicy.CANCEL,
                    onPermissionRequest: (_, request) async =>
                        PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.DENY,
                        ),
                    onCreateWindow: (_, action) async => false,
                    onWebViewCreated: (controller) {
                      _controller = controller;
                      unawaited(_activity());
                    },
                    onPageCommitVisible: (_, _) {
                      _visible = true;
                      _checkReady();
                    },
                    onLoadStop: (_, _) {
                      _loaded = true;
                      unawaited(_updateDocument());
                      _checkReady();
                    },
                    onRenderProcessGone: (_, detail) {
                      if (mounted) setState(() => _failed = true);
                      widget.onReady?.call();
                    },
                  ),
                ),
              ),
            ),
    );
  }
}

/// A native renderer: the plugin's Android view, built through the plugin
/// overlay platform view, filling the screensaver at the kiosk's theme and
/// UI scale. Touches stay with KS unless the plugin published it with
/// touch (issue #1282): then single taps reach the view and the manager
/// closes the screensaver on a double tap. It moves with Pixel shift like
/// the documents. Leaving disposes the platform view, which tells the
/// plugin to stop drawing.
class _NativeScreensaver extends StatefulWidget {
  const _NativeScreensaver({
    super.key,
    required this.container,
    required this.renderer,
  });
  final AppContainer container;
  final Map<String, Object?> renderer;

  @override
  State<_NativeScreensaver> createState() => _NativeScreensaverState();
}

class _NativeScreensaverState extends State<_NativeScreensaver> {
  StreamSubscription<ScreenStateChanged>? _screen;
  StreamSubscription<SettingChanged>? _settings;
  StreamSubscription<ActivityAttached>? _attached;
  Timer? _shift;
  Offset _offset = Offset.zero;
  bool _screenOn = true;

  /// A re-created Activity takes the platform view with it, so it is built
  /// again, as overlays are.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    final bus = widget.container.bus;
    _screen = bus.on<ScreenStateChanged>().listen((e) => _screenOn = e.on);
    _attached = bus.on<ActivityAttached>().listen((_) {
      if (mounted) setState(() => _epoch++);
    });
    _settings = bus.on<SettingChanged>().listen((e) {
      if (e.key == defs.screensaverPixelShift.key &&
          !widget.container.settings.get(defs.screensaverPixelShift) &&
          mounted) {
        setState(() => _offset = Offset.zero);
      }
    });
    _shift = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted ||
          !Lifecycle.onScreen ||
          !_screenOn ||
          !widget.container.settings.get(defs.screensaverPixelShift)) {
        return;
      }
      final max = min(24.0, MediaQuery.sizeOf(context).width * .015);
      final random = Random();
      setState(
        () => _offset = Offset(
          (random.nextDouble() * 2 - 1) * max,
          (random.nextDouble() * 2 - 1) * max,
        ),
      );
    });
  }

  @override
  void dispose() {
    _screen?.cancel();
    _settings?.cancel();
    _attached?.cancel();
    _shift?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exempt from the Scale UI factor like the documents: the view gets a
    // density that includes it instead, as overlays do.
    final scale = UiScaleScope.of(context);
    final theme = widget.container.plugins.overlayTheme(
      pluginOverlayTheme(Theme.of(context)),
    );
    final renderer = widget.renderer;
    return ColoredBox(
      color: Colors.black,
      child: ClipRect(
        child: Transform.translate(
          offset: _offset,
          child: IgnorePointer(
            ignoring: renderer['touch'] != true,
            child: AndroidView(
              // The density is fixed when the view is built, so a new Scale
              // UI factor builds it again.
              key: ValueKey((scale, _epoch)),
              viewType: PluginNativeOverlays.viewType,
              creationParams: {
                'kind': 'screensaver',
                'id': renderer['pluginId'],
                'session': renderer['session'],
                'key': renderer['key'],
                'generation': renderer['generation'],
                'width': PluginNativeOverlay.fill,
                'height': PluginNativeOverlay.fill,
                'insets': const [0, 0, 0, 0],
                'scale': scale,
                'theme': theme,
              },
              creationParamsCodec: const StandardMessageCodec(),
              // Every touch on a touch renderer is the plugin's, as on
              // an overlay.
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  EagerGestureRecognizer.new,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}
