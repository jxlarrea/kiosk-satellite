import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../managers/camera/camera_manager.dart';
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
    this.onPlaying,
  });

  final AppContainer container;
  final CameraViewConfig? view;
  final bool interactive;
  final VoidCallback? onDismiss;

  /// Called each time a camera in the mounted view starts decoding; see
  /// [CameraPlayer.onPlaying].
  final VoidCallback? onPlaying;

  /// How long a closing player stays mounted offstage for its streams to
  /// stop before it is dropped. Public for the camera screensaver, which
  /// waits it out between two views so the next grid never overlaps the
  /// last one's teardown.
  static const shutdownGrace = Duration(milliseconds: 600);

  @override
  State<ClosingCameraPlayer> createState() => _ClosingCameraPlayerState();
}

class _ClosingCameraPlayerState extends State<ClosingCameraPlayer>
    with SingleTickerProviderStateMixin {
  /// The view still mounted, which lags [widget.view] while one closes.
  CameraViewConfig? _mounted;
  bool _closing = false;
  Timer? _drop;

  /// Bumped when the same view is re-shown after its exit already tore the
  /// player down: the torn-down player (dead page, [_CameraPlayerState]
  /// with its teardown latched) can only be replaced, and the key is what
  /// replaces it.
  int _generation = 0;

  /// The opened camera view rises from the bottom edge and leaves the same
  /// way, like every other page brought up over the dashboard.
  ///
  /// Only the opened view. The screensaver builds the same grid as its own
  /// content ([ClosingCameraPlayer.interactive] off), where it is scenery
  /// the screensaver fades in on its own terms — sliding it would make the
  /// panel appear to move by itself.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
    value: widget.interactive && widget.view != null ? 0 : 1,
  )..addStatusListener(_onSlideStatus);

  late final Animation<Offset> _slideOffset = Tween(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _slide,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _mounted = widget.view;
    // A view already open when this mounts (the overlay is built with one,
    // or the app restored into one) still gets its entrance.
    if (widget.interactive && widget.view != null) _slide.forward();
  }

  @override
  void didUpdateWidget(ClosingCameraPlayer old) {
    super.didUpdateWidget(old);
    final next = widget.view;
    if (next?.id == _mounted?.id && (next == null) == (_mounted == null)) {
      // The same view re-shown while it is on its way out. Without this,
      // the exit keeps running underneath the "open" view and finishes
      // with the player mounted but off screen: a black panel with every
      // stream still decoding behind it, which no later close can reach
      // (reversing an already-dismissed animation fires no status).
      if (next != null) {
        _drop?.cancel();
        _drop = null;
        if (_closing) {
          // The exit already tore this player down; only a fresh player
          // can bring the view back.
          setState(() {
            _closing = false;
            _generation++;
          });
          if (widget.interactive) _slide.forward(from: 0);
        } else if (widget.interactive &&
            (_slide.status == AnimationStatus.reverse ||
                _slide.status == AnimationStatus.dismissed)) {
          // Caught mid-exit before the teardown: play it back in.
          _slide.forward(from: _slide.value);
        }
      }
      return;
    }
    _drop?.cancel();
    if (next == null) {
      if (_mounted == null) return;
      if (!widget.interactive) {
        // The screensaver's grid: hide it now, let it shut down, drop it
        // shortly after.
        setState(() => _closing = true);
        _startDropTimer();
      } else {
        // The opened view slides out first, still playing — the teardown
        // and the offstage hide wait for [_onSlideStatus], so what leaves
        // the screen is the grid rather than a black rectangle.
        _slide.reverse();
      }
    } else {
      final wasOpen = _mounted != null;
      setState(() {
        _mounted = next;
        _closing = false;
      });
      // From the bottom edge when a view is opening, from wherever it has
      // got to when one is caught on its way out, and with no movement at
      // all when a view simply replaces another already on screen.
      if (widget.interactive) {
        _slide.forward(from: wasOpen ? _slide.value : 0);
      }
    }
  }

  /// The exit finished: shut the streams down from a still-mounted widget
  /// (the whole point of this wrapper) and let the grace period run.
  void _onSlideStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !mounted) return;
    if (widget.view != null || _mounted == null) return;
    setState(() => _closing = true);
    _startDropTimer();
  }

  void _startDropTimer() {
    _drop?.cancel();
    _drop = Timer(ClosingCameraPlayer.shutdownGrace, () {
      if (mounted) setState(() => _mounted = null);
    });
  }

  @override
  void dispose() {
    _drop?.cancel();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = _mounted;
    if (view == null) return const SizedBox.shrink();
    return Offstage(
      offstage: _closing,
      child: IgnorePointer(
        // On its way out it is scenery, not a view: a touch belongs to what
        // is coming back underneath.
        ignoring: widget.interactive && widget.view == null,
        child: SlideTransition(
          position: _slideOffset,
          child: CameraPlayer(
            key: ValueKey('${view.id}-${widget.interactive}-$_generation'),
            container: widget.container,
            view: view,
            interactive: widget.interactive,
            onDismiss: widget.onDismiss,
            onPlaying: widget.onPlaying,
            closing: _closing,
          ),
        ),
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
    this.onPlaying,
    this.closing = false,
  });

  final AppContainer container;
  final CameraViewConfig view;
  final bool interactive;

  /// Called for a touch while [interactive] is false.
  final VoidCallback? onDismiss;

  /// Called each time a camera in the view starts decoding, whichever
  /// transport carried it: the page's "playing" report, which is the only
  /// point at which the grid is known to show video rather than a black
  /// tile. The camera screensaver times its dwell from the first one.
  final VoidCallback? onPlaying;

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

  /// Whether the page has committed its first visible frame; until then a
  /// black cover hides the WebView (see [build]).
  bool _pageVisible = false;

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
    widget.container.camera.closeRelaySessions();
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

  /// The transports this camera can use, in the order the page should try
  /// them. A Go2RTC server serves the same stream over WebRTC and MSE
  /// (issue #160, "Prefer MSE" flips that order); an `ha` camera offers
  /// what Home Assistant reported at import — WebRTC signaling (issue
  /// #124), HLS, or both, with "Prefer HLS" flipping that order — and one
  /// added by hand (unknown types) is offered both; WHEP is WebRTC by
  /// definition.
  List<String> _transportsFor(CameraSource camera) {
    switch (camera.kind) {
      case 'go2rtc':
        if (camera.missing) return const ['webrtc'];
        return widget.container.settings.get(defs.cameraPreferMse)
            ? const ['mse', 'webrtc']
            : const ['webrtc', 'mse'];
      case 'ha':
        final types = camera.streamTypes;
        // MJPEG closes every list: Home Assistant's camera proxy serves
        // it for every camera entity, so a stills-only camera (empty
        // types) plays over it alone and everything else keeps it as the
        // rung of last resort.
        final transports = [
          if (types == null || types.contains('web_rtc')) 'webrtc',
          if (types == null || types.contains('hls')) 'hls',
          'mjpeg',
        ];
        if (widget.container.settings.get(defs.cameraPreferHls) &&
            transports.remove('hls')) {
          transports.insert(0, 'hls');
        }
        return transports;
      default:
        return const ['webrtc'];
    }
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
      // The screensaver's grid is scenery and has its own mute over the
      // single-camera sound switch; an opened view keeps the switch as is.
      'singleAudio':
          widget.container.settings.get(defs.cameraSingleAudio) &&
          (widget.interactive ||
              !widget.container.settings.get(defs.screensaverCameraMute)),
      'pinchZoom': widget.container.settings.get(defs.cameraPinchZoom),
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
              'transports': _transportsFor(camera),
            },
      ],
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Stack(
      fit: StackFit.expand,
      children: [
        _buildWebView(),
        // Android composites a fresh WebView surface before the page's
        // first frame exists, and what it composites is white — a visible
        // flash as the view slides up. Cover the WebView in black until
        // the page reports its first frame committed; the page paints
        // black immediately (hls.js is deferred off the parse path), so
        // the cover lifts within the entrance animation.
        if (!_pageVisible)
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
      ],
    ),
  );

  Widget _buildWebView() => InAppWebView(
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
        // The cover comes back for the fresh surface's own white phase.
        if (mounted) {
          setState(() {
            _epoch++;
            _pageVisible = false;
          });
        }
      },
      onPageCommitVisible: (controller, url) {
        if (mounted && !_pageVisible) setState(() => _pageVisible = true);
      },
      initialFile: 'assets/camera-view/index.html',
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: 'window.__ksCameraView = $_configJson;',
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      initialSettings: InAppWebViewSettings(
        // Transparent, with the black ColoredBox behind showing through:
        // an opaque WebView composites its default white background for
        // the first frame or two before the page paints, which flashed
        // white as the view slid up (worse once hls.js sat in the parse
        // path, but present without it).
        transparentBackground: true,
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
              // What the tile is allowed to claim: a server that answered and
              // refused is not a network problem, and saying so sends people
              // hunting the wrong thing (issue #160).
              return {
                'ok': false,
                'error': '$error',
                'kind': error is SocketException || error is TimeoutException
                    ? 'network'
                    : 'server',
                if (error is CameraSignalingException) 'status': error.statusCode,
              };
            }
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraMse',
          callback: (args) async {
            try {
              final request = (args.first as Map).cast<String, Object?>();
              return await widget.container.camera.mseEndpoint(
                cameraId: '${request['cameraId'] ?? ''}',
                fullscreen: request['fullscreen'] == true,
              );
            } catch (error) {
              return {'ok': false, 'error': '$error'};
            }
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraHls',
          callback: (args) async {
            try {
              final request = (args.first as Map).cast<String, Object?>();
              return await widget.container.camera.hlsEndpoint(
                cameraId: '${request['cameraId'] ?? ''}',
              );
            } catch (error) {
              return {'ok': false, 'error': '$error'};
            }
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'cameraMjpeg',
          callback: (args) async {
            try {
              final request = (args.first as Map).cast<String, Object?>();
              return await widget.container.camera.mjpegEndpoint(
                cameraId: '${request['cameraId'] ?? ''}',
              );
            } catch (error) {
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
          handlerName: 'cameraPlaying',
          callback: (args) {
            widget.onPlaying?.call();
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
    );
}
