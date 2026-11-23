import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/home_assistant/custom_pages.dart';
import 'package:kiosk_satellite/ui/compass/compass_controller.dart';

// Compass follows the page to the place in its layout that holds what the
// page moved to: a dashboard view or a Custom Page (issue #1567).
void main() {
  const pages = [
    CustomPage(name: 'Wall', path: 'http://192.168.1.20/'),
    CustomPage(name: 'Den', path: 'https://pages.lan/wall.html#den'),
    CustomPage(name: 'Kitchen', path: '/local/kitchen.html#lights'),
  ];

  String? url(String u) => compassRouteOfUrl(u, pages);

  test('an external page matches the view that holds it', () {
    final view = compassRouteOfPath('local/http://192.168.1.20/');
    expect(view, isNotNull);
    expect(url('http://192.168.1.20/'), view);
    // The WebView reports the bare origin with "/" as its path.
    expect(url('http://192.168.1.20'), view);
  });

  test('an external page keeps its fragment', () {
    expect(
      url('https://pages.lan/wall.html#den'),
      compassRouteOfPath('local/https://pages.lan/wall.html#den'),
    );
    expect(
      url('https://pages.lan/wall.html#porch'),
      isNot(compassRouteOfPath('local/https://pages.lan/wall.html#den')),
    );
  });

  test('a page in Home Assistant matches by its navigation path', () {
    expect(
      url('https://ha.lan/local/kitchen.html#lights'),
      compassRouteOfPath('local/kitchen.html#lights'),
    );
    // Served by the secure context proxy, on another origin.
    expect(
      url('http://127.0.0.1:8124/local/kitchen.html#lights'),
      compassRouteOfPath('local/kitchen.html#lights'),
    );
    expect(
      url('https://ha.lan/local/kitchen.html#ac'),
      isNot(compassRouteOfPath('local/kitchen.html#lights')),
    );
  });

  test('a dashboard view still goes by its route alone', () {
    expect(compassRouteOfPath('lovelace/home?x=1#popup'), 'lovelace/home');
    expect(url('https://ha.lan/lovelace/home?edit=1'), 'lovelace/home');
    expect(url('https://ha.lan/'), isNull);
    expect(compassRouteOfPath(''), isNull);
  });

  test('an unknown external page is no Custom Page', () {
    expect(url('https://elsewhere.lan/'), isNull);
  });
}
