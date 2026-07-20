import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/manager.dart';
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

  /// Methods pages may call, mapped to registry command names. Anything not
  /// listed here is not reachable from page JS regardless of registry
  /// contents (pages are less trusted than the authenticated remote API).
  static const _exposedMethods = <String, String>{
    'getDeviceInfo': 'getDeviceInfo',
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
    'setWakeWordConfig': 'setWakeWordConfig',
    'setWakeWordActive': 'setWakeWordActive',
    'releaseWakeWord': 'releaseWakeWord',
    'setStopWordActive': 'setStopWordActive',
    'getWakeWordState': 'getWakeWordState',
    'startAudioStream': 'startAudioStream',
    'stopAudioStream': 'stopAudioStream',
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
          bus.publish(VoiceInteractionChanged(
            active: p['active'] == true,
            reason: p['reason'] is String ? p['reason'] as String : '',
          ));
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
  }

  /// The script the UI layer injects at document start.
  UserScript buildUserScript(String os) => UserScript(
        source: buildKioskSatelliteScript(version: appVersion, os: os),
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      );

  /// Called by the UI layer from onWebViewCreated.
  void attach(InAppWebViewController controller) {
    _controller = controller;
    controller.addJavaScriptHandler(
      handlerName: 'ksApi',
      callback: (args) => _onCall(args),
    );
  }

  Future<Object?> _onCall(List<dynamic> args) async {
    if (args.isEmpty || args.first is! String) return null;
    final method = args.first as String;
    final params = args.length > 1 && args[1] is Map
        ? (args[1] as Map).cast<String, Object?>()
        : <String, Object?>{};

    final commandName = _exposedMethods[method];
    if (commandName == null) {
      log.warn(name, 'page called unknown method $method');
      return null;
    }
    final result = await commands.execute(commandName, params);
    // Queries resolve to their data; commands resolve to true/false. Never
    // reject — matching the defensive style of the VS kiosk wrapper.
    if (!result.ok) return result.data == null ? false : null;
    return result.data ?? true;
  }

  void _dispatchToPage(String wireName, Map<String, Object?> detail) {
    final controller = _controller;
    if (controller == null) return;
    final js = 'window.dispatchEvent(new CustomEvent('
        '${jsonEncode('kiosksatellite:$wireName')}, '
        '{detail: ${jsonEncode(detail)}}));';
    controller.evaluateJavascript(source: js).catchError((Object e) {
      log.debug(name, 'event dispatch failed: $e');
      return null;
    });
  }
}
