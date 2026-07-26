import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/dlna/dlna_manager.dart';
import 'package:shelf/shelf.dart';

void main() {
  Response ok(Request _) => Response.ok('');

  /// A port nothing else is on, found by taking one and giving it back.
  Future<int> freePort() async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    await probe.close();
    return port;
  }

  test('takes the preferred port when it is free', () async {
    final port = await freePort();
    final server = await serveWithFallback(ok, port);
    addTearDown(() => server.close(force: true));
    expect(server.port, port);
  });

  test('steps past a port held on loopback only', () async {
    // Issue #49 exactly: the secure context proxy holds 127.0.0.1:2325 while
    // the renderer binds every interface, and a wildcard bind loses to a
    // loopback one. The renderer used to die here.
    final port = await freePort();
    final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    addTearDown(() => proxy.close());

    final server = await serveWithFallback(ok, port);
    addTearDown(() => server.close(force: true));
    expect(server.port, port + 1);
  });

  test('keeps stepping while ports stay taken', () async {
    final port = await freePort();
    final held = <ServerSocket>[
      await ServerSocket.bind(InternetAddress.loopbackIPv4, port),
      await ServerSocket.bind(InternetAddress.loopbackIPv4, port + 1),
    ];
    addTearDown(() async {
      for (final s in held) {
        await s.close();
      }
    });

    final server = await serveWithFallback(ok, port);
    addTearDown(() => server.close(force: true));
    expect(server.port, port + 2);
  });

  test('gives up rather than drifting far from the configured port', () async {
    final port = await freePort();
    final held = <ServerSocket>[
      for (var i = 0; i < 2; i++)
        await ServerSocket.bind(InternetAddress.loopbackIPv4, port + i),
    ];
    addTearDown(() async {
      for (final s in held) {
        await s.close();
      }
    });

    // Only two attempts allowed, both taken: the caller gets the real
    // SocketException and reports it, instead of the renderer landing
    // somewhere nobody configured.
    await expectLater(
      serveWithFallback(ok, port, tries: 2),
      throwsA(isA<SocketException>()),
    );
  });
}
