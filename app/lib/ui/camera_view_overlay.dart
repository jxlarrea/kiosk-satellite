import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../app_container.dart';
import '../managers/camera/models.dart';

class CameraViewOverlay extends StatelessWidget {
  const CameraViewOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: container.camera.activeViewId,
    builder: (context, viewId, _) {
      if (viewId == null) return const SizedBox.shrink();
      final view = container.camera.config.views
          .where((item) => item.id == viewId)
          .firstOrNull;
      if (view == null) return const SizedBox.shrink();
      return Positioned.fill(
        child: _CameraPlayer(
          key: ValueKey(view.id),
          container: container,
          view: view,
        ),
      );
    },
  );
}

class _CameraPlayer extends StatefulWidget {
  const _CameraPlayer({super.key, required this.container, required this.view});

  final AppContainer container;
  final CameraViewConfig view;

  @override
  State<_CameraPlayer> createState() => _CameraPlayerState();
}

class _CameraPlayerState extends State<_CameraPlayer> {
  late final String _configJson = _buildConfig();
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    widget.container.camera.focusedCameraId.addListener(_syncFocus);
  }

  @override
  void dispose() {
    widget.container.camera.focusedCameraId.removeListener(_syncFocus);
    _controller?.evaluateJavascript(source: 'shutdown();');
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
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
      'focusedCameraId': widget.container.camera.focusedCameraId.value,
      'cameras': [
        for (final id in widget.view.cameraIds)
          if (camerasById[id] case final camera?)
            {'id': camera.id, 'name': camera.name, 'missing': camera.missing},
      ],
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: InAppWebView(
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
          handlerName: 'cameraLog',
          callback: (args) {
            widget.container.log.debug(
              'camera',
              args.isEmpty ? '' : '${args.first}',
            );
            return null;
          },
        );
      },
    ),
  );
}
