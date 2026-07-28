import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/mqtt/mqtt_manager.dart';

void main() {
  const options = [
    'home/main',
    'home/energy',
    'dashboard-cameras/front-door',
    'dashboard-cameras/1',
    'overview',
  ];

  group('matchDashboardView', () {
    test('exact view path matches', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/home/energy', options),
        'home/energy',
      );
    });

    test('numeric route (view with no declared path) matches', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/dashboard-cameras/1', options),
        'dashboard-cameras/1',
      );
    });

    test('bare dashboard url maps to its first view', () {
      expect(
        MqttManager.matchDashboardView('http://ha.local:8123/home', options),
        'home/main',
      );
    });

    test('bare path option matches itself (strategy dashboard)', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/overview', options),
        'overview',
      );
    });

    test('proxy loopback origin still matches by path', () {
      expect(
        MqttManager.matchDashboardView(
            'http://127.0.0.1:8317/home/main', options),
        'home/main',
      );
    });

    test('trailing slash is ignored', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/home/main/', options),
        'home/main',
      );
    });

    test('query string is ignored', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/home/main?edit=1', options),
        'home/main',
      );
    });

    test('non-dashboard pages match nothing', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/config/dashboard', options),
        isNull,
      );
      expect(
        MqttManager.matchDashboardView('https://example.com/news', options),
        isNull,
      );
      expect(
        MqttManager.matchDashboardView('http://ha.local:8123/', options),
        isNull,
      );
    });

    test('unknown deep path matches nothing', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/home/main/extra', options),
        isNull,
      );
    });

    test('empty options match nothing', () {
      expect(
        MqttManager.matchDashboardView(
            'http://ha.local:8123/home/main', const []),
        isNull,
      );
    });
  });
}
