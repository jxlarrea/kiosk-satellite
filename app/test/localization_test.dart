import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/l10n/generated/message_lookup.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings_en.dart';
import 'package:kiosk_satellite/l10n/messages.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_search.dart';

class TestMessages extends UiStringsEn {
  @override
  String get settingHaUrlTitle => 'Localized address';
}

class TestDelegate extends LocalizationsDelegate<UiStrings> {
  const TestDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<UiStrings> load(Locale locale) => SynchronousFuture(TestMessages());
  @override
  bool shouldReload(TestDelegate old) => false;
}

Map<String, dynamic> readSourceMessages() {
  final source = <String, dynamic>{};
  for (final file in Directory('l10n/source').listSync().whereType<File>()) {
    if (!file.path.endsWith('_en.arb')) continue;
    final bundle = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    for (final entry in bundle.entries) {
      if (entry.key.startsWith('@')) continue;
      expect(source.containsKey(entry.key), isFalse, reason: entry.key);
      source[entry.key] = entry.value;
    }
  }
  expect(source, isNotEmpty);
  return source;
}

void main() {
  test('generated English messages match the current source catalog', () {
    final source = readSourceMessages();
    for (final key in source.keys.cast<String>()) {
      if (key.startsWith('@') || (source[key] as String).contains('{')) {
        continue;
      }
      expect(messageById(UiStringsEn(), key, ''), source[key], reason: key);
    }
  });

  test('exported setting messages match canonical definitions', () {
    final source = readSourceMessages();
    final strings = UiStringsEn();
    for (final def in allSettings) {
      if (def.titleMessageId == null) continue;
      // The MAC override is rendered by both interfaces after a failed
      // hardware read, although it is hidden from the generic settings list.
      // Home Assistant's mirrored selects show in the fleet exclusion list.
      // Share Home Assistant connection is drawn by hand on the Custom Pages
      // page of both interfaces, Show blocked page notice on the URL Filter
      // page.
      if (def.key != esphomeMacOverride.key &&
          def.key != haCustomPagesSocket.key &&
          def.key != browserUrlFilterNotice.key &&
          !voiceHaSelectSettings.values.contains(def)) {
        expect(
          def.hidden,
          isFalse,
          reason: '${def.key} has no visible setting',
        );
      }
      expect(source[def.titleMessageId], def.title, reason: def.key);
      expect(
        source[def.descriptionMessageId],
        def.description,
        reason: def.key,
      );
      expect(messageById(strings, def.titleMessageId, ''), def.title);
    }
  });

  test('every visible setting has messages', () {
    // These two show a {token} in their text, which a settings message
    // cannot carry, so LocalizedSetting picks their messages by key.
    const byKey = {'voice.timer_named_phrase', 'alarms.phrase'};
    for (final setting in allSettings.where(
      (s) => !s.hidden && !byKey.contains(s.key),
    )) {
      expect(setting.titleMessageId, isNotNull, reason: setting.key);
      expect(setting.descriptionMessageId, isNotNull, reason: setting.key);
    }
  });

  test('unreviewed Spanish has not been activated', () {
    // This becomes an enabled language only after the first complete import.
    if (!File('l10n/localization.lock.json').existsSync()) {
      expect(UiStrings.supportedLocales, [const Locale('en')]);
    }
  });

  testWidgets('CJK rendering locale survives English message fallback', (
    tester,
  ) async {
    late Locale locale;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja', 'JP'),
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: Builder(
          builder: (context) {
            locale = Localizations.localeOf(context);
            return Text(l10n(context).setupWelcome);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(locale, const Locale('ja', 'JP'));
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('translated settings remain searchable by their English labels', (
    tester,
  ) async {
    late List<SettingsSearchEntry> index;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [TestDelegate()],
        home: Builder(
          builder: (context) {
            index = buildSettingsSearchIndex(
              [('Home Assistant', 'Home Assistant', '')],
              titleFor: (def) => def.localizedTitle(context),
              descriptionFor: (def) => def.localizedDescription(context),
            );
            return Text(haUrl.localizedTitle(context));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Localized address'), findsOneWidget);
    for (final query in ['Localized address', 'Home Assistant base URL']) {
      expect(
        searchSettings(query, index, [
          'Home Assistant',
        ]).any((entry) => entry.defKey == haUrl.key),
        isTrue,
      );
    }
  });

  test('named placeholders are substituted once', () {
    expect(
      UiStringsEn().setupUnexpectedResponse('HTTP {error}'),
      'Unexpected response (HTTP {error})',
    );
  });
}
