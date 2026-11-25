import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
import '../audio/mic_hub.dart';
import 'page_ha_socket.dart';
import 'user_script.dart';

/// The `window.kioskSatellite` bridge (see docs/js-api.md).
///
/// Page → app: the injected user script forwards method calls to the
/// `ksApi` JavaScript handler; every method resolves through the
/// [CommandRegistry], so the JS API automatically exposes exactly what the
/// remote API exposes.
///
/// App → page: bus events with a [AppEvent.wireName] are dispatched into the
/// page as `kiosksatellite:<name>` CustomEvents.
class JsApiManager extends Manager {
  JsApiManager(super.bus, super.commands, super.log, this.appVersion);

  final String appVersion;

  @override
  String get name => 'js_api';

  InAppWebViewController? _controller;
  final _pageInteractions = <String>{};

  /// The managed Home Assistant connection custom pages open through
  /// `kioskSatellite.ha` (see page_ha_socket.dart). Set by the composition
  /// root; without it the page hears `not_allowed`.
  PageHaSockets? get haSockets => _haSockets;
  set haSockets(PageHaSockets? value) {
    _haSockets?.dispose();
    _haSockets = value;
    value?.run = _controller == null ? null : _runInPage;
  }

  PageHaSockets? _haSockets;
  final _browserMicrophones = <String>{};

  /// The origins that may learn who Face Recognition sees at the kiosk
  /// (BrowserManager.faceRecognitionOrigins). Set by the composition root.
  /// Without it no page does.
  Set<String> Function()? faceRecognitionOrigins;

  /// Methods pages may call, mapped to registry command names. Anything not
  /// listed here is not reachable from page JS regardless of registry
  /// contents (pages are less trusted than the authenticated remote API).
  static const _exposedMethods = <String, String>{
    'setVoiceTimers': 'setVoiceTimers',
    'getVoiceChimeDurations': 'getVoiceChimeDurations',
    'setVoiceTimerAlert': 'setVoiceTimerAlert',
    'voiceTimerActionFailed': 'voiceTimerActionFailed',
    'getVoiceTimers': 'voiceTimers',
    'controlVoiceTimer': 'voiceTimerControl',
    'getDeviceInfo': 'getDeviceInfo',
    'getTheme': 'getTheme',
    'getKioskState': 'getKioskState',
    'getBrightness': 'getBrightness',
    'setBrightness': 'setBrightness',
    'screenOn': 'screenOn',
    'screenOff': 'screenOff',
    'isScreenOn': 'isScreenOn',
    'stopScreensaver': 'stopScreensaver',
    'pauseScreensaver': 'pauseScreensaver',
    'setInteractionActive': 'setInteractionActive',
    'getScreensaverSuppressed': 'getScreensaverSuppressed',
    'bringToFront': 'bringToFront',
    'getMotionEnabled': 'getMotionEnabled',
    'getFaceEnabled': 'getFaceEnabled',
    'getProximityEnabled': 'getProximityEnabled',
    'setWakeWordConfig': 'setWakeWordConfig',
    'setWakeWordActive': 'setWakeWordActive',
    'releaseWakeWord': 'releaseWakeWord',
    'setStopWordActive': 'setStopWordActive',
    'getWakeWordState': 'getWakeWordState',
    'startAudioStream': 'startAudioStream',
    'stopAudioStream': 'stopAudioStream',
    'pipelineRun': 'pipelineRun',
    'pipelineStop': 'pipelineStop',
    'pipelineOpenMic': 'pipelineOpenMic',
    'pipelineCloseMic': 'pipelineCloseMic',
    'pipelineSetMuted': 'pipelineSetMuted',
    'pipelineStartBuffering': 'pipelineStartBuffering',
    'pipelineStopBuffering': 'pipelineStopBuffering',
    'pipelineClearBuffer': 'pipelineClearBuffer',
    'pipelineStartSending': 'pipelineStartSending',
    'pipelineStopSending': 'pipelineStopSending',
    'playSound': 'playSound',
    'prefetchSound': 'prefetchSound',
    'stopSound': 'stopSound',
    'setSoundVolume': 'setSoundVolume',
  };

  @override
  Future<void> init() async {
    // The page's generic "an interaction is running" signal. Voice Satellite
    // brackets voice turns, ringing timer alerts and media playback with it;
    // every ambient feature (view rotation, the screensaver) listens for the
    // resulting event and stands down. Registered here, on the bridge, because
    // it is an app-wide signal that belongs to no single feature — it used to
    // be smuggled through pauseScreensaver, which stays as a fallback for
    // older Voice Satellite versions.
    commands.register(
      Command(
        name: 'setInteractionActive',
        description:
            'Signal that a page interaction (voice turn, timer alert, media '
            'playback) started or ended; ambient features stand down while '
            'one is active',
        params: const {
          'active': 'true while the interaction runs',
          'reason':
              "what kind: 'voice', 'announcement', 'ask_question', "
              "'start_conversation', 'timer', 'media' (optional)",
        },
        handler: (p) async {
          _setPageInteraction(
            p['active'] == true,
            p['reason'] is String ? p['reason'] as String : '',
          );
          return const CommandResult.ok();
        },
      ),
    );
    bus.stream.listen((event) {
      final wireName = event.wireName;
      if (wireName != null) _dispatchToPage(wireName, event.toJson());
    });
    // Mic audio for the page. AudioChunk has no wireName (it must not reach
    // the remote admin feed), so it is dispatched here explicitly.
    bus.on<AudioChunk>().listen((e) => _dispatchToPage('audio', e.toJson()));
    // Native pipeline transport events, explicit for the same reason:
    // streaming intent-progress deltas and ~15/s mic levels have no
    // business on the remote admin WebSocket.
    bus.on<PipelineEvent>().listen(
      (e) => _dispatchToPage('pipeline', e.toJson()),
    );
    bus.on<PipelineClosed>().listen(
      (e) => _dispatchToPage('pipeline-closed', e.toJson()),
    );
    bus.on<PipelineMicLevel>().listen(
      (e) => _dispatchToPage('pipeline-level', e.toJson()),
    );
    // Who is at the kiosk, explicit like the pipeline: only Home
    // Assistant and custom pages hear it, and never the remote admin feed
    // through a wireName.
    bus.on<FaceRecognitionChanged>().listen(
      (e) =>
          _dispatchToPage('face-recognition', e.state, origins: _faceOrigins()),
    );
    bus.on<FaceArrivalReported>().listen(
      (e) =>
          _dispatchToPage('face-arrival', e.toJson(), origins: _faceOrigins()),
    );
  }

  /// The origins allowed to hear Face Recognition, empty without a source.
  Set<String> _faceOrigins() => faceRecognitionOrigins?.call() ?? const {};

  /// The script the UI layer injects at document start.
  UserScript buildUserScript(String os) => UserScript(
    source: buildKioskSatelliteScript(version: appVersion, os: os),
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );

  /// Called by the UI layer from onWebViewCreated.
  void attach(InAppWebViewController controller) {
    detach();
    _controller = controller;
    _haSockets?.run = _runInPage;
    controller.addJavaScriptHandler(
      handlerName: 'ksApi',
      callback: (JavaScriptHandlerFunctionData data) =>
          identical(_controller?.platform, controller.platform)
          ? _onCall(
              data.args,
              origin: data.isMainFrame ? data.origin.toString() : null,
            )
          : null,
    );
    // The managed Home Assistant connection, on a handler of its own: its
    // answers are not the ksApi call shapes, and only the top document of
    // the page may use it.
    controller.addJavaScriptHandler(
      handlerName: 'ksHaSocket',
      callback: (JavaScriptHandlerFunctionData data) =>
          identical(_controller?.platform, controller.platform) &&
              data.isMainFrame
          ? handleHaSocket(data.args)
          : null,
    );
  }

  void _runInPage(String js) {
    final controller = _controller;
    if (controller == null) return;
    controller.evaluateJavascript(source: js).catchError((Object e) {
      log.debug(name, 'page socket delivery failed: $e');
      return null;
    });
  }

  /// The ksHaSocket handler body: `[op, doc, sid, frame?]` with op `open`,
  /// `send` or `close`.
  @visibleForTesting
  Future<Object?> handleHaSocket(List<dynamic> args) async {
    if (args.length < 3) return null;
    final op = args[0], doc = args[1], sid = args[2];
    if (op is! String || doc is! String || sid is! String) return null;
    if (doc.isEmpty || doc.length > 64 || sid.isEmpty || sid.length > 64) {
      return null;
    }
    final sockets = _haSockets;
    switch (op) {
      case 'open':
        return sockets == null
            ? {'ok': false, 'error': 'not_allowed'}
            : await sockets.open(doc, sid);
      case 'send':
        final frame = args.length > 3 ? args[3] : null;
        return frame is String && (sockets?.send(doc, sid, frame) ?? false);
      case 'close':
        sockets?.close(doc, sid);
        return true;
    }
    return null;
  }

  void _setPageInteraction(bool active, String reason) {
    if (!active && reason.isEmpty && _pageInteractions.isNotEmpty) {
      final pendingReasons = _pageInteractions.toList();
      _pageInteractions.clear();
      for (final pending in pendingReasons) {
        _setPageInteraction(false, pending);
      }
      return;
    }
    if (active) {
      _pageInteractions.add(reason);
    } else {
      _pageInteractions.remove(reason);
    }
    bus.publish(
      VoiceInteractionChanged(
        active: active,
        reason: reason,
        source: InteractionSource.page,
      ),
    );
  }

  /// A full navigation replaces the document. SPA view switches do not.
  void onPageStarted() {
    // The document's Home Assistant sockets go with it. The page is told,
    // in case the new document already opened one before this news
    // arrived: it opens it again.
    _haSockets?.closeAll('navigation', notify: true);
    bus.publish(const VoiceTimersCleared());
    _browserMicrophones.clear();
    unawaited(MicHub.instance.setBrowserCapturing(false));
    if (_pageInteractions.isEmpty) return;
    log.info(
      name,
      'page replaced, releasing interactions: '
      '${_pageInteractions.map((reason) => reason.isEmpty ? "legacy" : reason).join(", ")}',
    );
    final pending = _pageInteractions.toList();
    _pageInteractions.clear();
    for (final reason in pending) {
      bus.publish(
        VoiceInteractionChanged(
          active: false,
          reason: reason,
          source: InteractionSource.page,
        ),
      );
    }
  }

  /// Stop dispatching to a discarded WebView and release its holds.
  void detach() {
    _haSockets?.closeAll('webview detached');
    _haSockets?.run = null;
    _controller = null;
    onPageStarted();
  }

  @override
  Future<void> dispose() async {
    detach();
    _haSockets?.dispose();
  }

  /// The ksApi handler body, reachable for tests (attach needs a live
  /// WebView controller).
  @visibleForTesting
  Future<Object?> handleCall(List<dynamic> args, {String? origin}) =>
      _onCall(args, origin: origin);

  /// Whether the top document on [origin] may learn who is at the kiosk.
  bool _mayKnowFaces(String? origin) {
    if (origin == null) return false;
    final uri = Uri.tryParse(origin);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      return false;
    }
    return _faceOrigins().contains(uri.origin);
  }

  /// [origin] is the calling document's when it is the top one, null for
  /// a frame inside it.
  Future<Object?> _onCall(List<dynamic> args, {String? origin}) async {
    if (args.isEmpty || args.first is! String) return null;
    final method = args.first as String;
    final params = args.length > 1 && args[1] is Map
        ? (args[1] as Map).cast<String, Object?>()
        : <String, Object?>{};

    if (method == 'remoteSettingsChanged') {
      bus.publish(const RemoteStatusChanged('voice'));
      return true;
    }

    // Who is at the kiosk, for Home Assistant and custom pages only. Any
    // other page, and any frame inside one, reads null.
    if (method == 'getFaceRecognition') {
      if (!_mayKnowFaces(origin)) return null;
      final result = await commands.execute('faceRecognitionState', const {});
      return result.ok ? result.data : null;
    }

    if (method == 'browserMicrophone') {
      final id = params['id'];
      if (id is! String || id.length > 64) return false;
      if (params['active'] == true) {
        _browserMicrophones.add(id);
      } else {
        _browserMicrophones.remove(id);
      }
      await MicHub.instance.setBrowserCapturing(_browserMicrophones.isNotEmpty);
      return true;
    }
    var commandName = _exposedMethods[method];
    if (commandName == null) {
      log.warn(name, 'page called unknown method $method');
      return null;
    }
    if (method == 'pauseScreensaver') {
      // Legacy page calls need the same document ownership as the modern API.
      commandName = 'setInteractionActive';
      params['active'] = params.remove('paused') == true;
      params.remove('reason');
    }
    // Assistant loudness belongs to this app, not the page (issue #294):
    // Voice Satellite scales every sound it delegates by its own HA
    // media_player entity volume, a slider nothing on the device surfaces,
    // and stacked under the Assistant volume fader it turned "everything
    // at 100%" into near-silence. Sounds the page hands over play at the
    // Assistant volume alone; its volume opinion is dropped here at the
    // bridge, so the command log records what actually plays. The remote
    // API keeps the explicit volume parameter for testing.
    if (method == 'playSound' || method == 'setSoundVolume') {
      params.remove('volume');
    }
    final result = await commands.execute(
      commandName,
      method == 'bringToFront' ? {...params, 'voiceInteraction': true} : params,
    );
    // Queries resolve to their data; commands resolve to true/false. Never
    // reject — matching the defensive style of the VS kiosk wrapper.
    if (!result.ok) return result.data == null ? false : null;
    return result.data ?? true;
  }

  /// With [origins], the event reaches the page only while the document
  /// that runs it is on one of them, checked in the page itself, so a
  /// navigation between the check and the delivery cannot leak it.
  void _dispatchToPage(
    String wireName,
    Map<String, Object?> detail, {
    Set<String>? origins,
  }) {
    final controller = _controller;
    if (controller == null) return;
    if (origins != null && origins.isEmpty) return;
    final dispatch =
        'window.dispatchEvent(new CustomEvent('
        '${jsonEncode('kiosksatellite:$wireName')}, '
        '{detail: ${jsonEncode(detail)}}));';
    final js = origins == null
        ? dispatch
        : 'if (${jsonEncode(origins.toList())}.indexOf(location.origin) >= 0) '
              '{ $dispatch }';
    controller.evaluateJavascript(source: js).catchError((Object e) {
      log.debug(name, 'event dispatch failed: $e');
      return null;
    });
  }
}
