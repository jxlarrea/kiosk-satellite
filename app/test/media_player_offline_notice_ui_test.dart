import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/ui/mdi_icon.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The notice under the Media Player page's Player row names what the pick
/// turns off on this device: the Sendspin player and the AirPlay receiver,
/// each only while switched on and not the pick itself. The remote admin
/// draws the same (remote_browser_test.dart, remote_live_ui_test.py).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> open(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues({
      'ks.sendspin.player_source': '',
      'ks.sendspin.player': '',
      ...prefs,
    });
    final container = AppContainer();
    await container.settings.init();
    // Tall enough that a page renders whole: off-screen rows do not exist.
    tester.view.physicalSize = const Size(500, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(container: container)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Media Player').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('the Sendspin pick names a switched-on AirPlay receiver', (
    tester,
  ) async {
    await open(tester, {
      'ks.sendspin.enabled': true,
      'ks.airplay.enabled': true,
    });
    expect(
      find.text(
        'The AirPlay receiver stays off while Sendspin Player is picked.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('the Sendspin pick wears its own icon, not the empty one', (
    tester,
  ) async {
    await open(tester, {'ks.sendspin.enabled': true});
    // The empty value is the Sendspin player, drawn like any other pick:
    // the empty field draws no item icon at all.
    expect(
      find.byWidgetPredicate((w) => w is MdiIcon && w.name == 'mdi:speaker'),
      findsOneWidget,
    );
  });

  testWidgets('nothing to say when the pick turns nothing off', (tester) async {
    await open(tester, {'ks.sendspin.enabled': true});
    expect(find.textContaining('is picked.'), findsNothing);
  });

  testWidgets('AirPlay names the Sendspin player', (tester) async {
    await open(tester, {
      'ks.sendspin.enabled': true,
      'ks.airplay.enabled': true,
      'ks.sendspin.player': 'airplay',
      'ks.sendspin.player_name': 'AirPlay',
    });
    expect(
      find.text('The Sendspin player stays offline while AirPlay is picked.'),
      findsOneWidget,
    );
  });

  testWidgets('the Local Media Session names both', (tester) async {
    await open(tester, {
      'ks.sendspin.enabled': true,
      'ks.airplay.enabled': true,
      'ks.sendspin.player': 'session:*',
      'ks.sendspin.player_name': 'Local Media Session',
    });
    expect(
      find.text(
        'The Sendspin player and the AirPlay receiver stay offline while '
        'Local Media Session is picked.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a followed group this device is in keeps the player on', (
    tester,
  ) async {
    await open(tester, {
      'ks.sendspin.enabled': true,
      'ks.sendspin.player_source': 'ma',
      'ks.sendspin.player': 'ma:syncgroup_1',
      'ks.sendspin.player_name': 'Whole House',
      'ks.sendspin.kept_for': 'ma:syncgroup_1',
    });
    expect(find.textContaining('is picked.'), findsNothing);
  });

  testWidgets('a group kept on earlier says nothing for another pick', (
    tester,
  ) async {
    await open(tester, {
      'ks.sendspin.enabled': true,
      'ks.sendspin.player_source': 'ma',
      'ks.sendspin.player': 'ma:kitchen',
      'ks.sendspin.player_name': 'Kitchen',
      'ks.sendspin.kept_for': 'ma:syncgroup_1',
    });
    expect(
      find.text('The Sendspin player stays offline while Kitchen is picked.'),
      findsOneWidget,
    );
  });

  testWidgets('a source with no player picked yet is named itself', (
    tester,
  ) async {
    await open(tester, {
      'ks.sendspin.enabled': true,
      'ks.sendspin.player_source': 'ma',
    });
    expect(
      find.text(
        'The Sendspin player stays offline while Music Assistant is picked.',
      ),
      findsOneWidget,
    );
  });
}
