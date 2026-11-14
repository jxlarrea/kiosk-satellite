import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../voice/ha_socket.dart';

/// The `tts_get_url` body: the engine and message, plus the language and
/// voice when they are set. Home Assistant refuses a voice option an engine
/// does not take, so an empty one is left out, not sent blank.
Map<String, Object?> ttsRequestBody({
  required String engine,
  required String message,
  String language = '',
  String voice = '',
}) => {
  'engine_id': engine,
  'message': message,
  if (language.trim().isNotEmpty) 'language': language.trim(),
  if (voice.trim().isNotEmpty) 'options': {'voice': voice.trim()},
};

/// Home Assistant's text to speech as plain audio bytes: `tts_get_url` with
/// an engine entity, then the file it points at. [engine] empty takes the
/// first `tts.` entity Home Assistant has, the Announcements rule. Null
/// when Home Assistant is not set up, not reachable or has no engine; a
/// caller treats speech as a bonus and carries on without it. A [language]
/// or [voice] the engine no longer has fails in Home Assistant, so a miss
/// with either is tried once more with the engine's own.
Future<Uint8List?> haSpeak({
  required String base,
  required String token,
  required String engine,
  required String message,
  String language = '',
  String voice = '',
  http.Client Function() client = http.Client.new,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final audio = await _haSpeak(
    base: base,
    token: token,
    engine: engine,
    message: message,
    language: language,
    voice: voice,
    client: client,
    timeout: timeout,
  );
  // First available never sends either, so it has nothing to retry.
  if (audio != null ||
      engine.trim().isEmpty ||
      (language.trim().isEmpty && voice.trim().isEmpty)) {
    return audio;
  }
  return _haSpeak(
    base: base,
    token: token,
    engine: engine,
    message: message,
    client: client,
    timeout: timeout,
  );
}

/// The address of [message] spoken by Home Assistant, for a player that
/// fetches the audio itself and for the kiosks a timer is shared with. The
/// same rules as [haSpeak], which downloads it.
Future<String?> haSpeakUrl({
  required String base,
  required String token,
  required String engine,
  required String message,
  String language = '',
  String voice = '',
  http.Client Function() client = http.Client.new,
  Duration timeout = const Duration(seconds: 15),
}) async {
  Future<String?> ask(String language, String voice) async {
    final c = client();
    try {
      return await _haSpeakUrl(
        c,
        base: base,
        token: token,
        engine: engine,
        message: message,
        language: language,
        voice: voice,
        timeout: timeout,
      );
    } catch (_) {
      return null;
    } finally {
      c.close();
    }
  }

  final url = await ask(language, voice);
  if (url != null ||
      engine.trim().isEmpty ||
      (language.trim().isEmpty && voice.trim().isEmpty)) {
    return url;
  }
  return ask('', '');
}

Future<Uint8List?> _haSpeak({
  required String base,
  required String token,
  required String engine,
  required String message,
  String language = '',
  String voice = '',
  required http.Client Function() client,
  required Duration timeout,
}) async {
  final c = client();
  try {
    final url = await _haSpeakUrl(
      c,
      base: base,
      token: token,
      engine: engine,
      message: message,
      language: language,
      voice: voice,
      timeout: timeout,
    );
    if (url == null) return null;
    final root = base.trim().replaceAll(RegExp(r'/+$'), '');
    final audio = await c
        .get(
          Uri.parse(url),
          headers: url.startsWith(root)
              ? {'Authorization': 'Bearer $token'}
              : const {},
        )
        .timeout(timeout);
    if (audio.statusCode != 200 || audio.bodyBytes.isEmpty) return null;
    return audio.bodyBytes;
  } catch (_) {
    return null;
  } finally {
    c.close();
  }
}

Future<String?> _haSpeakUrl(
  http.Client c, {
  required String base,
  required String token,
  required String engine,
  required String message,
  String language = '',
  String voice = '',
  required Duration timeout,
}) async {
  base = base.trim().replaceAll(RegExp(r'/+$'), '');
  if (base.isEmpty || token.isEmpty || message.trim().isEmpty) return null;
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  {
    var entity = engine.trim();
    if (entity.isEmpty) {
      final states = await c
          .get(Uri.parse('$base/api/states'), headers: headers)
          .timeout(timeout);
      if (states.statusCode != 200) return null;
      final list = jsonDecode(states.body);
      if (list is! List) return null;
      entity =
          [
            for (final e in list)
              if (e is Map && '${e['entity_id']}'.startsWith('tts.'))
                '${e['entity_id']}',
          ].firstOrNull ??
          '';
      if (entity.isEmpty) return null;
    }
    final res = await c
        .post(
          Uri.parse('$base/api/tts_get_url'),
          headers: headers,
          body: jsonEncode(
            ttsRequestBody(
              engine: entity,
              message: message,
              language: engine.trim().isEmpty ? '' : language,
              voice: engine.trim().isEmpty ? '' : voice,
            ),
          ),
        )
        .timeout(timeout);
    if (res.statusCode != 200) return null;
    final url = (jsonDecode(res.body) as Map?)?['url'];
    if (url is! String || url.isEmpty) return null;
    return url;
  }
}

/// A text to speech engine's languages, the one its voices were listed
/// for and those voices, `{voice_id, name}` each. Empty voices for an
/// engine that has none to pick, Google Translate's case.
class HaTtsVoices {
  const HaTtsVoices({
    required this.languages,
    required this.language,
    required this.voices,
  });

  final List<String> languages;
  final String language;
  final List<Map<String, String>> voices;

  Map<String, Object?> toJson() => {
    'languages': languages,
    'language': language,
    'voices': voices,
  };
}

/// The engine's voices for [language], or for Home Assistant's own
/// language when it is empty, over one websocket. Null when Home Assistant
/// is not set up or not reachable. Listing voices needs no admin token.
Future<HaTtsVoices?> haTtsVoices({
  required String base,
  required String token,
  required String engine,
  String language = '',
  HaSocket Function(String base, String token)? socket,
}) async {
  if (base.trim().isEmpty || token.isEmpty || engine.trim().isEmpty) {
    return null;
  }
  final ha = (socket ?? (b, t) => HaSocket(baseUrl: () => b, token: () => t))(
    base,
    token,
  );
  try {
    final got = await ha.request({
      'type': 'tts/engine/get',
      'engine_id': engine.trim(),
    });
    final provider = got is Map ? got['provider'] : null;
    final raw = provider is Map ? provider['supported_languages'] : null;
    final languages = [
      if (raw is List)
        for (final l in raw)
          if ('$l'.isNotEmpty) '$l',
    ];
    var wanted = language.trim();
    if (wanted.isEmpty) {
      final config = await ha.request({'type': 'get_config'});
      if (config is Map) {
        wanted = pickTtsLanguage(
          languages,
          '${config['language'] ?? ''}',
          '${config['country'] ?? ''}',
        );
      }
    }
    if (wanted.isEmpty) {
      return HaTtsVoices(languages: languages, language: '', voices: const []);
    }
    final listed = await ha.request({
      'type': 'tts/engine/voices',
      'engine_id': engine.trim(),
      'language': wanted,
    });
    final list = listed is Map ? listed['voices'] : null;
    return HaTtsVoices(
      languages: languages,
      language: wanted,
      voices: [
        if (list is List)
          for (final v in list)
            if (v is Map && '${v['voice_id'] ?? ''}'.isNotEmpty)
              {
                'voice_id': '${v['voice_id']}',
                'name': '${v['name'] ?? v['voice_id']}',
              },
      ],
    );
  } catch (_) {
    return null;
  } finally {
    await ha.close();
  }
}

/// The engine language closest to Home Assistant's: its language with the
/// country, then the language alone, then its home region the way Home
/// Assistant prefers them (en-US, fr-FR), then any region of it. Engines
/// spell their tags differently (en-US, en_US, en-us), so those compare
/// alike. Empty when the engine speaks none of it.
String pickTtsLanguage(
  List<String> supported,
  String language,
  String country,
) {
  String norm(String tag) => tag.trim().toLowerCase().replaceAll('_', '-');
  final lang = norm(language);
  if (lang.isEmpty) return '';
  final primary = lang.split('-').first;
  final wanted = [
    if (!lang.contains('-') && country.trim().isNotEmpty)
      '$lang-${norm(country)}',
    lang,
    primary,
    primary == 'en' ? 'en-us' : '$primary-$primary',
  ];
  for (final w in wanted) {
    for (final s in supported) {
      if (norm(s) == w) return s;
    }
  }
  for (final s in supported) {
    if (norm(s).split('-').first == primary) return s;
  }
  return '';
}
