import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/command_registry.dart';
import '../../core/manager.dart';
import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';

/// Home Assistant connection: long-lived-token auth, connection validation,
/// and the dashboard list used by the dashboard picker.
///
/// Later milestones add MQTT discovery publishing and HA event
/// subscriptions for event-driven navigation.
class HomeAssistantManager extends Manager {
  HomeAssistantManager(super.bus, super.commands, super.log, this._settings);

  final SettingsManager _settings;

  @override
  String get name => 'home_assistant';

  String get baseUrl {
    final url = _settings.get(defs.haUrl);
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  bool get configured =>
      baseUrl.isNotEmpty && _settings.get(defs.haToken).isNotEmpty;

  @override
  Future<void> init() async {
    commands
      ..register(Command(
        name: 'haCheckConnection',
        description: 'Validate the Home Assistant URL and token',
        handler: (_) async {
          final error = await checkConnection();
          return error == null
              ? const CommandResult.ok()
              : CommandResult.fail(error);
        },
      ))
      ..register(Command(
        name: 'haListDashboards',
        description: 'List Home Assistant dashboards',
        handler: (_) async {
          final dashboards = await listDashboards();
          return dashboards == null
              ? const CommandResult.fail('could not list dashboards')
              : CommandResult.ok(dashboards);
        },
      ));
  }

  /// Null when reachable and authorized, otherwise an error description.
  Future<String?> checkConnection() async {
    if (!configured) return 'Home Assistant URL and token not configured';
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/'),
        headers: {'Authorization': 'Bearer ${_settings.get(defs.haToken)}'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) return 'invalid token';
      if (response.statusCode != 200) return 'HTTP ${response.statusCode}';
      return null;
    } catch (e) {
      return 'unreachable: $e';
    }
  }

  /// Dashboards via the websocket API (`lovelace/dashboards/list`), plus the
  /// default `lovelace` which the API does not include.
  Future<List<Map<String, Object?>>?> listDashboards() async {
    if (!configured) return null;
    try {
      final result = await _wsCommand({'type': 'lovelace/dashboards/list'});
      if (result is! List) return null;
      return [
        {'url_path': 'lovelace', 'title': 'Default'},
        for (final d in result.cast<Map>())
          if (d['mode'] == 'storage')
            {'url_path': d['url_path'], 'title': d['title']},
      ];
    } catch (e) {
      log.warn(name, 'listDashboards failed: $e');
      return null;
    }
  }

  /// Single authenticated websocket round-trip.
  Future<Object?> _wsCommand(Map<String, Object?> command) async {
    final wsBase = baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final wsUrl = '$wsBase/api/websocket';
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    try {
      final completer = Completer<Object?>();
      late StreamSubscription<dynamic> sub;
      sub = channel.stream.listen((raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        switch (msg['type']) {
          case 'auth_required':
            channel.sink.add(jsonEncode({
              'type': 'auth',
              'access_token': _settings.get(defs.haToken),
            }));
          case 'auth_ok':
            channel.sink.add(jsonEncode({'id': 1, ...command}));
          case 'auth_invalid':
            completer.completeError(StateError('auth invalid'));
          case 'result':
            if (msg['success'] == true) {
              completer.complete(msg['result']);
            } else {
              completer.completeError(StateError('${msg['error']}'));
            }
        }
      }, onError: completer.completeError);

      final result = await completer.future.timeout(
        const Duration(seconds: 10),
      );
      await sub.cancel();
      return result;
    } finally {
      await channel.sink.close();
    }
  }
}
