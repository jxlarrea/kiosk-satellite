import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/remote/remote_manager.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The remote admin UI's static file pipeline: index.html references its
/// stylesheet and ES modules under /static/ with a ?v= content hash, the
/// server substitutes that hash and serves the files with far-future
/// caching, and the page itself is never cached.
///
/// The reference walk below is the load-bearing guard: a module file that
/// exists on disk but is missing from the asset bundle (or a typo in an
/// import path) fails here instead of as a blank admin page on a wall
/// tablet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null);

  late SettingsManager settings;
  late RemoteManager remote;
  late int port;

  setUp(() async {
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    port = probe.port;
    await probe.close();

    SharedPreferences.setMockInitialValues({
      'ks.browser.start_url': 'http://ha.local:8123/lovelace/0',
      'ks.remote.enabled': true,
      'ks.remote.password': 'secret',
      'ks.remote.port': port,
    });
    final bus = EventBus();
    final log = Logger();
    final commands = CommandRegistry(log);
    settings = SettingsManager(bus, commands, log);
    await settings.init();
    remote = RemoteManager(bus, commands, log, settings);
    await remote.init();
  });

  tearDown(() async {
    await settings.set(defs.remoteEnabled, false);
    await remote.dispose();
  });

  Future<HttpClientResponse> get(String path) async {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:$port$path'),
    );
    return request.close();
  }

  Future<String> body(HttpClientResponse response) =>
      utf8.decodeStream(response);

  test('index is version-stamped and never cached', () async {
    final response = await get('/');
    expect(response.statusCode, 200);
    expect(response.headers.value('cache-control'), 'no-store');
    final html = await body(response);
    expect(html, isNot(contains('__KSV__')));
    expect(html, contains('static/app.css?v='));
  });

  test('every static reference in the page resolves', () async {
    final html = await body(await get('/'));
    final refs = RegExp(
      r'''static/([A-Za-z0-9._-]+)\?v=([0-9a-f]+)''',
    ).allMatches(html).toList();
    expect(refs, isNotEmpty);
    final versions = refs.map((m) => m.group(2)).toSet();
    expect(versions, hasLength(1), reason: 'one hash stamps every file');
    for (final ref in refs) {
      final response = await get('/static/${ref.group(1)}?v=${ref.group(2)}');
      expect(response.statusCode, 200, reason: 'static/${ref.group(1)}');
      await response.drain<void>();
    }
  });

  test('served modules import only version-stamped, resolvable files', () async {
    final html = await body(await get('/'));
    final version = RegExp(
      r'static/main\.js\?v=([0-9a-f]+)',
    ).firstMatch(html)!.group(1);
    // Walk the import graph as the browser would, starting from the page's
    // entry module. Bare './x.js' imports (no ?v=) fail here: with the
    // immutable cache header they would pin stale modules across updates.
    final queue = ['main.js'];
    final seen = <String>{};
    while (queue.isNotEmpty) {
      final name = queue.removeLast();
      if (!seen.add(name)) continue;
      final response = await get('/static/$name?v=$version');
      expect(response.statusCode, 200, reason: name);
      final source = await body(response);
      for (final m in RegExp(
        r"from\s+'\./([^']+)'",
      ).allMatches(source)) {
        final spec = m.group(1)!;
        expect(
          spec,
          endsWith('?v=$version'),
          reason: 'unstamped import in $name: $spec',
        );
        queue.add(spec.substring(0, spec.indexOf('?')));
      }
    }
    expect(seen.length, greaterThan(15), reason: 'the whole graph resolves');
  });

  test('static files carry type and immutable caching', () async {
    final response = await get('/static/app.css');
    expect(response.statusCode, 200);
    expect(response.headers.value('content-type'), startsWith('text/css'));
    expect(
      response.headers.value('cache-control'),
      'public, max-age=31536000, immutable',
    );
    final css = await body(response);
    expect(css, contains('.wizard-pane'));
  });

  test('unknown static paths 404 without touching the api gate', () async {
    final response = await get('/static/nope.js');
    expect(response.statusCode, 404);
    await response.drain<void>();
  });
}
