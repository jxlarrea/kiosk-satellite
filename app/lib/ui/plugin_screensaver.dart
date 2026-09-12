import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../core/events.dart';
import '../managers/settings/definitions.dart' as defs;

/// An isolated rendering document. All input and screensaver policy stays in KS.
String pluginScreensaverDocument(String html) => '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; img-src data: blob:; font-src data:; media-src data: blob:; frame-src about:; connect-src 'none'; form-action 'none'; base-uri 'none'">
<style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#000}iframe{border:0;width:100%;height:100%;pointer-events:none}</style></head>
<body><iframe sandbox="allow-scripts" srcdoc="${const HtmlEscape(HtmlEscapeMode.attribute).convert(html)}"></iframe></body></html>''';

class PluginScreensaver extends StatelessWidget {
  const PluginScreensaver({
    super.key,
    required this.container,
    required this.mode,
  });
  final AppContainer container;
  final String mode;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<Map<String, Map<String, Object?>>>(
        valueListenable: container.plugins.screensavers,
        builder: (context, renderers, _) {
          final html = renderers[mode]?['html'] as String?;
          if (html == null) return const ColoredBox(color: Colors.black);
          return _Document(
            key: ValueKey((mode, html)),
            container: container,
            html: html,
          );
        },
      );
}

class _Document extends StatefulWidget {
  const _Document({super.key, required this.container, required this.html});
  final AppContainer container;
  final String html;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_activity());
  }

  Future<void> _activity() async {
    try {
      if (_foreground && _screenOn) {
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
    _screen?.cancel();
    _settings?.cancel();
    _shift?.cancel();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: _failed
        ? const SizedBox.expand()
        : ClipRect(
            child: Transform.translate(
              offset: _offset,
              child: IgnorePointer(
                child: InAppWebView(
                  initialData: InAppWebViewInitialData(
                    data: pluginScreensaverDocument(widget.html),
                  ),
                  initialSettings: InAppWebViewSettings(
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
                      const [
                        'about:blank',
                        'about:srcdoc',
                      ].contains(action.request.url.toString())
                      ? NavigationActionPolicy.ALLOW
                      : NavigationActionPolicy.CANCEL,
                  onPermissionRequest: (_, request) async => PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.DENY,
                  ),
                  onCreateWindow: (_, action) async => false,
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    unawaited(_activity());
                  },
                  onRenderProcessGone: (_, detail) {
                    if (mounted) setState(() => _failed = true);
                  },
                ),
              ),
            ),
          ),
  );
}
