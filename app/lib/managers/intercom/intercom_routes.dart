import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';

/// Only the intercom wire, shared by its listener and legacy admin routes.
class IntercomRoutes {
  IntercomRoutes(this.commands, {required this.requiresTls});
  final CommandRegistry commands;
  final bool Function() requiresTls;
  final _identityAt = <String, DateTime>{};

  Future<Response> call(Request request) async {
    final path = request.url.path;
    if (path == 'api/intercom/identity' && request.method == 'GET') {
      final ip = _clientIp(request);
      final last = _identityAt[ip];
      final now = DateTime.now();
      if (last != null && now.difference(last) < const Duration(seconds: 1)) {
        return _json(429, {'error': 'too many probes'});
      }
      _identityAt[ip] = now;
      final r = await commands.execute('intercomIdentity', const {});
      return r.ok
          ? _json(200, (r.data as Map).cast<String, Object?>())
          : _json(503, {'error': r.error});
    }
    if (requiresTls() && request.requestedUri.scheme != 'https') {
      return _json(426, {'status': 'tls', 'error': 'Intercom requires HTTPS'});
    }
    if (path == 'api/intercom/call' && request.method == 'POST') {
      final body = await _body(request);
      if (body == null) return _json(400, {'error': 'invalid JSON'});
      final r = await commands.execute('intercomIncoming', {
        ...body,
        'token': _bearerToken(request),
        'address': _clientIp(request),
      });
      if (!r.ok) return _json(400, r.toJson());
      final data = (r.data as Map?)?.cast<String, Object?>() ?? const {};
      final code = data['code'];
      return _json(code is int ? code : 200, data);
    }
    if (path.startsWith('api/intercom/call/') && request.method == 'POST') {
      final body = await _body(request);
      if (body == null) return _json(400, {'error': 'invalid JSON'});
      final r = await commands.execute('intercomSignal', {
        ...body,
        'call': path.substring('api/intercom/call/'.length),
        'token': _bearerToken(request),
        'address': _clientIp(request),
      });
      return _json(r.ok ? 200 : 403, r.toJson());
    }
    if (path.startsWith('api/intercom/audio/')) {
      final callId = path.substring('api/intercom/audio/'.length);
      final verified = await commands.execute('intercomVerify', {
        'call': callId,
        'token': request.url.queryParameters['token'],
      });
      if (!verified.ok) return _json(403, {'error': 'refused'});
      return webSocketHandler((WebSocketChannel channel, String? protocol) {
        // Handed over whole: the manager reads and writes the frames,
        // binary voice and text control alike. In-process, so an object
        // rides the command's parameters where the wire never sees it.
        commands.execute('intercomAttachSocket', {
          'call': callId,
          'channel': channel,
        });
      })(request);
    }

    if (path.startsWith('api/intercom/video/')) {
      final callId = path.substring('api/intercom/video/'.length);
      final verified = await commands.execute('intercomVerifyVideo', {
        'call': callId,
        'token': request.url.queryParameters['token'],
      });
      if (!verified.ok) return _json(403, {'error': 'refused'});
      return webSocketHandler((WebSocketChannel channel, String? protocol) {
        commands.execute('intercomAttachVideo', {
          'call': callId,
          'channel': channel,
        });
      })(request);
    }

    return Response.notFound('not found');
  }

  static String _clientIp(Request request) =>
      (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
          ?.remoteAddress
          .address ??
      'unknown';

  static String? _bearerToken(Request request) {
    final value = request.headers['authorization'];
    return value?.startsWith('Bearer ') == true ? value!.substring(7) : null;
  }

  static Future<Map<String, Object?>?> _body(Request request) async {
    try {
      final bytes = <int>[];
      await for (final chunk in request.read().timeout(
        const Duration(seconds: 6),
      )) {
        if (bytes.length + chunk.length > 65536) return null;
        bytes.addAll(chunk);
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  static Response _json(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}
