/// Amazon's wake word engine on the Echo images.
///
/// The Kiosk Satellite Edition images for the Echo Dot and the Echo Shows
/// run Amazon's own engine (Pryon), with the models the Dot shipped with, as
/// a service: biscuit-pryond, on a local socket. When an app connects, the
/// service first lists every model it has and the keywords each one spots. This
/// reads that list once at boot, so the wake word selects offer exactly what
/// the service has, and leaves the engine out on every other device.
///
/// Amazon's models are per locale. The service names the locales that listen
/// with each one, and the Wake word language setting picks among them.
///
/// The engine is off for now ([PryonCatalog.enabled]): the service is never
/// asked, so the engine and its language setting stay hidden on every device
/// and a kiosk that had it set listens with vsWakeWord (SettingsManager moves
/// it there once).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../../core/logging.dart';
import '../../settings/definitions.dart' as defs;
import 'pryon_isolate.dart';

/// One keyword the service spots: a wake word, or the stop word.
class PryonWord {
  const PryonWord({
    required this.id,
    required this.model,
    required this.keyword,
    this.stop = false,
    this.acceptThreshold,
    this.locales = const [],
  });

  /// The keyword in lower case, the id the wake word selects use: 'alexa'.
  final String id;

  /// The model that spots it, as the service names it: 'ALEXA'.
  final String model;

  /// The keyword as the service reports it: 'ALEXA'.
  final String keyword;

  final bool stop;

  /// The score the service accepts it at before a client property lowers
  /// it, or null when the service did not say.
  final double? acceptThreshold;

  /// The locales that listen with its model, as the service lists them.
  final List<String> locales;

  /// Where the engine finds it, in place of a manifest URL.
  String get url => 'pryon:$model/$keyword';

  @override
  bool operator ==(Object other) =>
      other is PryonWord &&
      other.id == id &&
      other.model == model &&
      other.keyword == keyword &&
      other.stop == stop &&
      other.acceptThreshold == acceptThreshold &&
      other.locales.join(',') == locales.join(',');

  @override
  int get hashCode =>
      Object.hash(id, model, keyword, stop, acceptThreshold, locales.join(','));
}

abstract final class PryonCatalog {
  static const _channel = MethodChannel('kiosk_satellite/background');

  /// Whether Kiosk Satellite offers Amazon's engine at all. Off, [init]
  /// leaves the service alone even on an Echo image, so nothing is offered.
  /// Tests turn it on.
  static bool enabled = false;

  /// The service's socket. Tests point it at a fake one.
  static String socketPath = pryonSocketPath;

  static List<PryonWord> _words = const [];

  /// The word a config's manifest URL names, or null.
  static PryonWord? byUrl(String url) {
    for (final w in _words) {
      if (w.url == url) return w;
    }
    return null;
  }

  /// Every locale a model listens with, in the service's order (en-US
  /// first).
  static List<String> get locales => {
    for (final w in _words) ...w.locales,
  }.toList();

  /// The wake words [locale] listens with. A keyword two of its models spot
  /// is offered once, from the first.
  static List<PryonWord> wakeWordsFor(String locale) {
    final byId = <String, PryonWord>{};
    for (final w in _words) {
      if (!w.stop && w.locales.contains(locale)) byId.putIfAbsent(w.id, () => w);
    }
    return byId.values.toList();
  }

  /// The stop word of [model], which only that model spots.
  static PryonWord? stopWordFor(String model) {
    for (final w in _words) {
      if (w.stop && w.model == model) return w;
    }
    return null;
  }

  /// The service answered with at least one wake word.
  static bool get available => _words.any((w) => !w.stop);

  // The locale an app language falls back to when it has several.
  static const _languageDefaults = {
    'en': 'en-US',
    'es': 'es-US',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'it': 'it-IT',
    'pt': 'pt-BR',
    'ja': 'ja-JP',
    'nl': 'nl-NL',
    'ar': 'ar-SA',
    'hi': 'hi-IN',
  };

  /// The locale to listen with: [setting] when the service has it, else the
  /// one matching [appLanguage] (`es`, `zh-CN`), else en-US, else the first.
  static String resolveLocale(String setting, String appLanguage) {
    final all = locales;
    if (all.isEmpty) return '';
    if (all.contains(setting)) return setting;
    final language = appLanguage.split(RegExp('[-_]')).first;
    final preferred = _languageDefaults[language];
    if (preferred != null && all.contains(preferred)) return preferred;
    for (final l in all) {
      if (l.startsWith('$language-')) return l;
    }
    return all.contains('en-US') ? 'en-US' : all.first;
  }

  static const _localeNames = {
    'en-US': 'English (United States)',
    'en-CA': 'English (Canada)',
    'en-GB': 'English (United Kingdom)',
    'en-AU': 'English (Australia)',
    'en-IN': 'English (India)',
    'hi-IN': 'हिन्दी (भारत)',
    'es-US': 'Español (Estados Unidos)',
    'es-MX': 'Español (México)',
    'es-ES': 'Español (España)',
    'fr-FR': 'Français (France)',
    'fr-CA': 'Français (Canada)',
    'de-DE': 'Deutsch (Deutschland)',
    'it-IT': 'Italiano (Italia)',
    'pt-BR': 'Português (Brasil)',
    'ja-JP': '日本語 (日本)',
    'nl-NL': 'Nederlands (Nederland)',
    'ar-SA': 'العربية (السعودية)',
  };

  /// A locale by its own name, as the app's language picker names languages.
  static String localeLabel(String locale) => _localeNames[locale] ?? locale;

  /// Whether the image says it runs the service (PryonService.kt), with a
  /// screen or without one.
  static Future<bool> _imageHasService() async {
    try {
      return await _channel.invokeMethod<bool>('pryon') ?? false;
    } catch (_) {
      // No native side (a test): no image.
      return false;
    }
  }

  /// Read the service's list on the image, then hide the engine wherever
  /// there is nothing to listen with. Before the settings render: both
  /// settings UIs and the ESPHome select read the hidden options.
  static Future<void> init(Logger log) async {
    if (enabled && await _imageHasService()) {
      try {
        _words = parseHello(await _hello());
        log.info(
          'pryon',
          'Amazon wake word models for ${locales.length} locales: '
              '${{for (final w in _words) w.model}.length} models',
        );
      } catch (e) {
        _words = const [];
        log.warn('pryon', 'the wake word service did not answer: $e');
      }
    }
    if (!available) {
      defs.deviceHiddenOptions[defs.voiceWakeWordEngine.key] = {'pryon'};
      defs.deviceHiddenKeys.add(defs.voiceAmazonLocale.key);
    }
  }

  static Future<String> _hello() async {
    final socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
      timeout: const Duration(seconds: 2),
    );
    try {
      return await socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first
          .timeout(const Duration(seconds: 3));
    } finally {
      socket.destroy();
    }
  }

  /// The words in the service's first line, model by model in its order:
  /// each model's wake words, then its stop word.
  static List<PryonWord> parseHello(String line) {
    final hello = jsonDecode(line);
    if (hello is! Map || hello['event'] != 'hello') {
      throw const FormatException('not a hello');
    }
    final words = <PryonWord>[];
    for (final m in hello['models'] as List? ?? const []) {
      if (m is! Map) continue;
      final model = '${m['model'] ?? ''}';
      if (model.isEmpty) continue;
      final accept = m['accept_thresholds'];
      final locales = [
        for (final l in m['locales'] as List? ?? const [])
          if ('$l'.isNotEmpty) '$l',
      ];
      for (final (list, isStop) in [
        (m['wake_words'], false),
        (m['stop_words'], true),
      ]) {
        for (final k in list as List? ?? const []) {
          final keyword = '$k';
          if (keyword.isEmpty) continue;
          words.add(
            PryonWord(
              id: keyword.toLowerCase(),
              model: model,
              keyword: keyword,
              stop: isStop,
              acceptThreshold: accept is Map && accept[keyword] is num
                  ? (accept[keyword] as num).toDouble()
                  : null,
              locales: locales,
            ),
          );
        }
      }
    }
    return words;
  }

  /// Tests only.
  static set debugWords(List<PryonWord> words) => _words = words;
}
