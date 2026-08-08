import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../managers/camera/models.dart';
import '../managers/settings/definitions.dart' as defs;

class CameraViewOverlay extends StatelessWidget {
  const CameraViewOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: container.camera.activeViewId,
    builder: (context, viewId, _) {
      final view = viewId == null
          ? null
          : container.camera.config.views
                .where((item) => item.id == viewId)
                .firstOrNull;
      return Positioned.fill(
        child: ClosingCameraPlayer(container: container, view: view),
      );
    },
  );
}

/// Renders [view], and when it goes away keeps the player alive offstage
/// just long enough to shut its streams down.
///
/// Dropping the player the instant the view closes looks right and is
/// wrong: the teardown calls it makes on the way out are asynchronous
/// platform-channel messages, and a platform view destroyed in the same
/// frame never receives them. The page then survives the widget with every
/// peer connection and decoder still running (measured on an Echo Show:
/// four live sessions and four decoding videos long after the grid left
/// the screen). Offstage the WebView keeps running JavaScript but paints
/// nothing, so the close is instant on screen and the streams still get a
/// real chance to stop.
class ClosingCameraPlayer extends StatefulWidget {
  const ClosingCameraPlayer({
    super.key,
    required this.container,
    required this.view,
    this.interactive = true,
    this.onDismiss,
  });

  final AppContainer container;
  final CameraViewConfig? view;
  final bool interactive;
  final VoidCallback? onDismiss;

  @override
  State<ClosingCameraPlayer> createState() => _ClosingCameraPlayerState();
}

class _ClosingCameraPlayerState extends State<ClosingCameraPlayer> {
  /// The view still mounted, which lags [widget.view] while one closes.
  CameraViewConfig? _mounted;
  bool _closing = false;
  Timer? _drop;

  static const _shutdownGrace = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _mounted = widget.view;
  }

  @override
  void didUpdateWidget(ClosingCameraPlayer old) {
    super.didUpdateWidget(old);
    final next = widget.view;
    if (next?.id == _mounted?.id && (next == null) == (_mounted == null)) {
      return;
    }
    _drop?.cancel();
    if (next == null) {
      // Closing: hide it now, let it shut down, drop it shortly after.
      if (_mounted == null) return;
      setState(() => _closing = true);
      _drop = Timer(_shutdownGrace, () {
        if (mounted) setState(() => _mounted = null);
      });
    } else {
      setState(() {
        _mounted = next;
        _closing = false;
      });
    }
  }

  @override
  void dispose() {
    _drop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = _mounted;
    if (view == null) return const SizedBox.shrink();
    return Offstage(
      offstage: _closing,
      child: CameraPlayer(
        key: ValueKey('${view.id}-${widget.interactive}'),
        container: widget.container,
        view: view,
        interactive: widget.interactive,
        onDismiss: widget.onDismiss,
        closing: _closing,
      ),
    );
  }
}

/// The WebRTC grid itself: one WebView playing every camera in [view].
///
/// Interactive by default (tap to focus, double tap or edge swipe to close),
/// which is what an opened camera view is. The screensaver builds the same
/// player with [interactive] off, where the grid is scenery and any touch
/// wakes the kiosk instead.
class CameraPlayer extends StatefulWidget {
  const CameraPlayer({
    super.key,
    required this.container,
    required this.view,
    this.interactive = true,
    this.onDismiss,
    this.closing = false,
  });

  final AppContainer container;
  final CameraViewConfig view;
  final bool interactive;

  /// Called for a touch while [interactive] is false.
  final VoidCallback? onDismiss;

  /// The view is on its way out: stop the streams now, while this widget is
  /// still mounted and its channel still delivers. See [ClosingCameraPlayer].
  final bool closing;

  @override
  State<CameraPlayer> createState() => _CameraPlayerState();
}

class _CameraPlayerState extends State<CameraPlayer> {
  late final String _configJson = _buildConfig();
  InAppWebViewController? _controller;
  bool _tornDown = false;

  /// Bumped to recreate the WebView after its renderer dies (WebRTC video
  /// decoding is exactly the kind of load that kills renderers on low-RAM
  /// devices). An unhandled renderer death here would take the whole app
  /// down; a rebuilt WebView just renegotiates its streams.
  int _epoch = 0;

  @override
  void initState() {
    super.initState();
    if (widget.interactive) {
      widget.container.camera.focusedCameraId.addListener(_syncFocus);
    }
  }

  /// Stop the streams from inside the page.
  ///
  /// Disposing the widget does NOT do this on its own: the Android WebView
  /// outlives the platform view long enough to keep every peer connection
  /// and decoder running (measured: four live sessions and four decoding
  /// videos after the view had already left the screen). Worse, whether the
  /// teardown lands is a race — closing from an async path gave the channel
  /// call time to arrive, closing synchronously did not.
  ///
  /// So it runs from deactivate(), while the element is still in the tree
  /// and the channel is certainly live, and again from dispose() for the
  /// paths that skip deactivate. shutdown() is idempotent; the about:blank
  /// navigation is the backstop that fires pagehide for anything it missed.
  void _teardown() {
    final controller = _controller;
    if (controller == null || _tornDown) return;
    _tornDown = true;
    // The page's peers are about to die; the HA signaling sessions feeding
    // them candidates die with them, and the candidate route is unhooked
    // so a later surface starts clean.
    if (widget.container.camera.onRemoteCandidate != null) {
      widget.container.camera.onRemoteCandidate = null;
    }
    widget.container.camera.closeHaSessions();
    controller.evaluateJavascript(source: 'shutdown();');
    controller.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
  }

  @override
  void didUpdateWidget(CameraPlayer old) {
    super.didUpdateWidget(old);
    if (widget.closing && !old.closing) _teardown();
  }

  @override
  void deactivate() {
    _teardown();
    super.deactivate();
  }

  @override
  void dispose() {
    if (widget.interactive) {
      widget.container.camera.focusedCameraId.removeListener(_syncFocus);
    }
    _teardown();
    super.dispose();
  }

  void _syncFocus() {
    final cameraId = widget.container.camera.focusedCameraId.value;
    _controller?.evaluateJavascript(
      source: 'setFocus(${jsonEncode(cameraId)}, false);',
    );
  }

  String _buildConfig() {
    final camerasById = {
      for (final camera in widget.container.camera.config.cameras)
        camera.id: camera,
    };
    return jsonEncode({
      'viewId': widget.view.id,
      'viewName': widget.view.name,
      'showCameraNames': widget.view.showCameraNames,
      'grid': widget.view.effectiveGrid,
      'allowH265': widget.container.settings.get(defs.cameraAllowH265),
      'interactive': widget.interactive,
      'focusedCameraId': widget.interactive
          ? widget.container.camera.focusedCameraId.value
          : null,
      'cameras': [
        for (final id in widget.view.cameraIds)
          if (camerasById[id] case final camera?)
            {
              'id': camera.id,
              'name': camera.name,
              'missing': camera.missing,
              // Whether focusing this camera is worth a renegotiation: only
              // a genuinely different stream changes what is on screen.
              'hasFullscreen':
                  camera.fullscreenStreamName != null &&
                  camera.fullscreenStreamName!.isNotEmpty &&
                  camera.fullscreenStreamName != camera.streamName,
            },
      ],
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: InAppWebView(
      key: ValueKey(_epoch),
      onRenderProcessGone: (controller, detail) {
        widget.container.log.warn(
          'camera',
          'WebView renderer gone (crashed: ${detail.didCrash}) — '
              'rebuilding the camera view',
        );
        // The old renderer took its streams with it; a fresh page
        // renegotiates from the injected config. _tornDown stays false so
        // the eventual real teardown still runs against the new page.
        if (mounted) setState(() => _epoch++);
      },
      initialFile: 'assets/camera-view/index.html',
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: 'window.__ksCameraView = $_configJson;',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      initialSettings: InAppWebViewSettings(
        transparentBackground: false,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        supportZoom: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        // This player is the camera surface: Home Assistant's trickled ICE
        // candidates (issue #124) land on the manager and are pushed into
        // the page's matching peer connection from here.
        widget.container.camera.onRemoteCandidate = (cameraId, candidate) {
          _controller?.evaluateJavascript(
            source:
                'window.ksAddCandidate && ksAddCandidate('
                '${jsonEncode(cameraId)}, ${jsonEncode(candidate)});',
          );
        };
        controller.addJavaScriptHandler(
          handlerName: 'cameraRtcConfig',
          callback: (args) async {
            try {
              final request = (args.first as Map).cast<String, Object?>();
              return await widget.container.camera.rtcConfigFor(
                '${request['cameraId'] ?? ''}',
              );
            } catch (_) {
              return null;
            }
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraOffer',
          callback: (args) async {
            try {
              final request = (args.first as Map).cast<String, Object?>();
              final answer = await widget.container.camera.negotiate(
                cameraId: '${request['cameraId'] ?? ''}',
                offer: '${request['offer'] ?? ''}',
                fullscreen: request['fullscreen'] == true,
              );
              return {'ok': true, 'answer': answer};
            } catch (error) {
              widget.container.log.warn(
                'camera',
                'WebRTC signaling failed: $error',
              );
              return {'ok': false, 'error': '$error'};
            }
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraFocus',
          callback: (args) {
            final request = (args.first as Map).cast<String, Object?>();
            final id = '${request['cameraId'] ?? ''}';
            widget.container.camera.focusCamera(id.isEmpty ? null : id);
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraClose',
          callback: (_) {
            widget.container.camera.hideView();
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraDismiss',
          callback: (_) {
            widget.onDismiss?.call();
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraLog',
          callback: (args) {
            final first = args.isEmpty ? null : args.first;
            final entry = first is Map
                ? first.cast<String, Object?>()
                : const <String, Object?>{};
            final message = '${entry['message'] ?? first ?? ''}';
            // A stream that connects and then decodes nothing is the one
            // camera failure with no error behind it, so the page reports it
            // as a warning and it shows up in About > App Logs (issue #160).
            if (entry['level'] == 'warn') {
              widget.container.log.warn('camera', message);
            } else {
              widget.container.log.debug('camera', message);
            }
            return null;
          },
        );
      },
    ),
  );
}
