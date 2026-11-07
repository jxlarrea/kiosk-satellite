import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart' as defs;
import 'package:kiosk_satellite/ui/calendar_overlay.dart';
import 'package:kiosk_satellite/ui/clock_setting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings > Calendar > 24-hour clock and Settings > Alarms > 24-hour
/// clock: the times follow them instead of Android's clock, and a 12-hour
/// time stays 12-hour in a language that writes 24 hours by default.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initializeDateFormatting);

  final afternoon = DateTime(2026, 11, 7, 16, 5);
  final fourPm = DateTime(2026, 11, 7, 16);

  Future<Map<String, String>> times(
    WidgetTester tester, {
    required bool use24h,
    required String locale,
  }) async {
    late Map<String, String> seen;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(alwaysUse24HourFormat: use24h),
        child: Builder(
          builder: (context) {
            seen = Intl.withLocale(
              locale,
              () => {
                'full': calendarTime(context, afternoon),
                'short': calendarTime(context, fourPm, short: true),
              },
            );
            return const SizedBox();
          },
        ),
      ),
    );
    return seen;
  }

  testWidgets('a 12-hour clock stays 12-hour in every language', (
    tester,
  ) async {
    expect(await times(tester, use24h: false, locale: 'en'), {
      'full': '4:05 PM',
      'short': '4 PM',
    });
    // Spanish writes 24 hours by default. CLDR puts a narrow no-break
    // space inside its period.
    expect(await times(tester, use24h: false, locale: 'es'), {
      'full': '4:05 p.\u202fm.',
      'short': '4 p.\u202fm.',
    });
    // Chinese puts the period first.
    expect(await times(tester, use24h: false, locale: 'zh_CN'), {
      'full': '下午4:05',
      'short': '下午4时',
    });
  });

  testWidgets('a 24-hour clock is 24-hour in every language', (tester) async {
    for (final locale in ['en', 'es', 'zh_CN']) {
      expect(await times(tester, use24h: true, locale: locale), {
        'full': '16:05',
        'short': '16:00',
      }, reason: locale);
    }
  });

  Future<AppContainer> container(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final c = AppContainer();
    await c.settings.init();
    return c;
  }

  testWidgets('the setting wins over Android and applies at once', (
    tester,
  ) async {
    final c = await container({'ks.calendar.clock_24h': true});
    late String seen;
    await tester.pumpWidget(
      MediaQuery(
        // Android on a 12-hour clock.
        data: const MediaQueryData(alwaysUse24HourFormat: false),
        child: ClockSetting(
          setting: defs.calendarClock24h,
          container: c,
          child: Builder(
            builder: (context) {
              seen = Intl.withLocale(
                'en',
                () => calendarTime(context, afternoon),
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(seen, '16:05');
    await c.settings.set(defs.calendarClock24h, false);
    // The change arrives on the bus, then the frame it asked for.
    await tester.pump();
    await tester.pump();
    expect(seen, '4:05 PM');
  });

  test('the first start keeps the clock Android showed', () async {
    final fresh = await container({});
    final prefs = await SharedPreferences.getInstance();
    // Written, not left to the default, so a later Android change does not
    // move the calendar.
    final android =
        WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat;
    for (final clock in [defs.calendarClock24h, defs.alarmsClock24h]) {
      expect(prefs.containsKey('ks.${clock.key}'), isTrue, reason: clock.key);
      expect(fresh.settings.get(clock), android, reason: clock.key);
    }
    final chosen = await container({
      'ks.calendar.clock_24h': !android,
      'ks.alarms.clock_24h': !android,
    });
    expect(chosen.settings.get(defs.calendarClock24h), !android);
    expect(chosen.settings.get(defs.alarmsClock24h), !android);
  });
}
