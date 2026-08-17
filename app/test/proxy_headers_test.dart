import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/proxy/proxy_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #230: the secure context proxy served the dashboard until, after a
/// few thousand requests, every page load failed with
/// ERR_RESPONSE_HEADERS_TOO_BIG. Both causes live in the response path, and
/// both are only visible on the wire, so these tests speak raw HTTP to the
/// proxy and read the bytes it writes back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProxyManager proxy;
  late ServerSocket upstream;

  /// A Home Assistant stand-in, raw so the bytes are exactly aiohttp's: the
  /// security headers HA puts on every response, and a revalidated asset
  /// answered with a 304 that carries no content-length at all.
  Future<void> startUpstream() async {
    // Bound on every address, addressed as 127.0.0.2: the proxy only maps a
    // non-loopback host, and the whole 127/8 range lands on this listener.
    upstream = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    upstream.listen((sock) {
      final pending = StringBuffer();
      sock.cast<List<int>>().transform(latin1.decoder).listen((chunk) {
        pending.write(chunk);
        var text = pending.toString();
        while (text.contains('\r\n\r\n')) {
          final end = text.indexOf('\r\n\r\n') + 4;
          final head = text.substring(0, end);
          text = text.substring(end);
          const common =
              'x-frame-options: SAMEORIGIN\r\nx-content-type-options: nosniff';
          final revalidated = head.startsWith('GET /asset.js ') &&
              head.toLowerCase().contains('if-none-match: "v1"');
          sock.add(latin1.encode(revalidated
              ? 'HTTP/1.1 304 Not Modified\r\netag: "v1"\r\n$common\r\n\r\n'
              : 'HTTP/1.1 200 OK\r\ncontent-type: text/html\r\n'
                  'content-length: 5\r\n$common\r\n\r\nhello'));
        }
        pending
          ..clear()
          ..write(text);
      });
    });
  }

  Future<void> startProxy() async {
    // The test binding swaps in an HttpClient that answers 400 without
    // touching the network; the proxy's upstream leg is a real socket.
    HttpOverrides.global = null;
    await startUpstream();
    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://127.0.0.2:${upstream.port}/',
      'ks.browser.secure_proxy': true,
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    final settings = SettingsManager(bus, commands, log);
    await settings.init();
    proxy = ProxyManager(bus, commands, log, settings);
    await proxy.init();
    expect(proxy.running, isTrue);
  }

  setUp(startProxy);

  tearDown(() async {
    await proxy.dispose();
    await upstream.close();
  });

  /// Sends [requests] down one keep-alive connection and returns everything
  /// the proxy wrote back, verbatim.
  Future<String> exchange(List<String> requests) async {
    final sock = await Socket.connect('127.0.0.1', proxy.port);
    final out = StringBuffer();
    sock.cast<List<int>>().transform(latin1.decoder).listen(out.write);
    for (final r in requests) {
      sock.add(latin1.encode(r));
      await sock.flush();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    sock.destroy();
    return out.toString();
  }

  String get(String path, {String? ifNoneMatch}) =>
      'GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\n'
      '${ifNoneMatch == null ? '' : 'If-None-Match: $ifNoneMatch\r\n'}\r\n';

  test('a forwarded header never accumulates across responses', () async {
    // Dart seeds every response from the server's default headers *by
    // reference*, so adding a name it already holds (x-frame-options and
    // nosniff, which Home Assistant sends on every response) used to append
    // to the shared list: one extra copy per proxied response, forever,
    // until the header block passed the browser's 256 KB cap.
    final wire = await exchange([for (var i = 0; i < 5; i++) get('/')]);
    final counts = RegExp(r'x-frame-options: ([^\r]*)', caseSensitive: false)
        .allMatches(wire)
        .map((m) => m.group(1)!.split(',').length)
        .toList();
    expect(counts, hasLength(5));
    expect(counts, everyElement(1));
  });

  test('a 304 carries no body, so the connection stays in sync', () async {
    // Home Assistant answers every cached frontend asset with a bare 304.
    // Forwarded with an unknown length it went out chunked, and the page,
    // which knows a 304 has no body, left the terminating `0\r\n\r\n` in the
    // socket to be read as the head of the next response.
    final wire = await exchange([
      get('/asset.js', ifNoneMatch: '"v1"'),
      get('/'),
    ]);
    expect(wire, startsWith('HTTP/1.1 304 Not Modified\r\n'));
    final second = wire.indexOf('HTTP/1.1 200 OK');
    expect(second, greaterThan(0));
    expect(
      wire.substring(0, second).toLowerCase(),
      isNot(contains('transfer-encoding')),
    );
    // Nothing between the end of the 304's headers and the next status line.
    expect(wire.substring(0, second), endsWith('\r\n\r\n'));
    expect(wire, endsWith('hello'));
  });

  test('the page sees Home Assistant headers, not the proxy defaults',
      () async {
    final wire = await exchange([get('/')]);
    expect(wire, contains('x-frame-options: SAMEORIGIN'));
    expect(wire.toLowerCase(), isNot(contains('x-xss-protection')));
  });
}
