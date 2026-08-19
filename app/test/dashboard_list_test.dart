import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/home_assistant/dashboard_list.dart';

void main() {
  test('YAML-mode dashboards are listed alongside storage ones', () {
    final dashboards = dashboardsFromWsList([
      {'url_path': 'home-tablet', 'title': 'Home Tablet', 'mode': 'storage'},
      {'url_path': 'test-yaml', 'title': 'YAML Test', 'mode': 'yaml'},
      {'url_path': 'map', 'title': 'Map', 'mode': 'storage'},
    ]);
    expect(dashboards.map((d) => d['url_path']), [
      'lovelace',
      'home-tablet',
      'test-yaml',
      'map',
    ]);
  });

  test('the default entry is prepended when the API omits it', () {
    final dashboards = dashboardsFromWsList([
      {'url_path': 'dashboard-echo', 'title': 'Echo', 'mode': 'storage'},
    ]);
    expect(dashboards.first, {'url_path': 'lovelace', 'title': 'Default'});
  });

  test('a dashboard registered on the default url_path is not doubled', () {
    final dashboards = dashboardsFromWsList([
      {'url_path': 'home-tablet', 'title': 'Home Tablet', 'mode': 'storage'},
      {'url_path': 'lovelace', 'title': 'Overview', 'mode': 'storage'},
    ]);
    expect(
      dashboards.where((d) => d['url_path'] == 'lovelace').length,
      1,
    );
    expect(dashboards.map((d) => d['url_path']), ['home-tablet', 'lovelace']);
  });

  test('entries without a url_path are skipped', () {
    final dashboards = dashboardsFromWsList([
      {'title': 'No path', 'mode': 'storage'},
      {'url_path': '', 'title': 'Empty', 'mode': 'yaml'},
      'not even a map',
      {'url_path': 'dashboard-echo', 'title': 'Echo', 'mode': 'storage'},
    ]);
    expect(dashboards.map((d) => d['url_path']), [
      'lovelace',
      'dashboard-echo',
    ]);
  });
}
