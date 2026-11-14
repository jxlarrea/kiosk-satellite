import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/app_container.dart';
import 'package:kiosk_satellite/core/app_locales.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/events.dart';
import 'package:kiosk_satellite/l10n/generated/ui_strings.dart';
import 'package:kiosk_satellite/managers/settings/definitions.dart';
import 'package:kiosk_satellite/ui/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Chimes page and its four selectors use shipped catalogs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final c = AppContainer();
    await c.settings.init();
    final calls = <String>[];
    for (final name in ['previewVoiceChime', 'stopSound']) {
      c.commands.register(
        Command(
          name: name,
          description: '',
          handler: (p) async {
            calls.add('$name:${p['kind'] ?? p['id']}');
            if (name == 'stopSound') {
              c.bus.publish(const SoundEnded(id: 'voice-preview'));
            }
            return const CommandResult.ok();
          },
        ),
      );
    }
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final size in [const Size(390, 1000), const Size(1000, 800)]) {
      tester.view.physicalSize = size;
      for (final language in ['en', 'es']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: UiStrings.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            home: SubpageSettingsScreen(
              container: c,
              category: 'Voice Satellite',
              subpage: 'Chimes',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(language == 'en' ? 'Chimes' : 'Sonidos'),
          findsOneWidget,
        );
        for (final title
            in language == 'en'
                ? [
                    'Wake sound',
                    'Done sound',
                    'Error sound',
                    'Announcement sound',
                  ]
                : [
                    'Sonido de activación',
                    'Sonido de finalización',
                    'Sonido de error',
                    'Sonido de anuncio',
                  ]) {
          expect(find.text(title), findsOneWidget);
        }
        final preview = find.byTooltip(
          language == 'en' ? 'Preview on kiosk' : 'Reproducir en el kiosco',
        );
        expect(preview, findsNWidgets(4));
        await tester.tap(preview.first);
        await tester.pump();
        expect(calls.last, 'previewVoiceChime:wake');
        expect(
          find.byTooltip(language == 'en' ? 'Stop' : 'Detener'),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip(language == 'en' ? 'Stop' : 'Detener'));
        await tester.pump();
        expect(calls.last, 'stopSound:voice-preview');
        expect(preview, findsNWidgets(4));
        await tester.tap(preview.first);
        await tester.pump();
        c.bus.publish(const SoundEnded(id: 'voice-preview'));
        await tester.pump();
        expect(preview, findsNWidgets(4));
        expect(
          find.text(language == 'en' ? 'Add a sound' : 'Añadir un sonido'),
          findsNothing,
        );
        for (final setting in voiceChimeSettings.values) {
          expect(setting.titleMessageId, isNotNull);
          expect(setting.descriptionMessageId, isNotNull);
          expect(setting.perDevice, isTrue);
        }
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await c.settings.dispose();
    await c.bus.dispose();
    await c.log.dispose();
  });
}
