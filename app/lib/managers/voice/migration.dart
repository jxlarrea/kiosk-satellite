import 'dart:convert';

import 'package:http/http.dart' as http;

import '../settings/definitions.dart' as defs;
import '../settings/settings_manager.dart';
import 'ha_socket.dart';
import 'wake_catalog.dart';

/// Moving a kiosk from the Voice Satellite integration (its engine in the
/// dashboard) to native Voice Satellite: reads the old satellite's settings
/// (its entities in Home Assistant and the integration's settings profile,
/// the page's stored copy under it), maps them onto the kiosk's own, and
/// finds the automations and scripts still pointing at the old satellite.
/// The switch itself is the voice manager's (it owns the runtime).
///
/// This is the only place the app talks to the integration, and only to
/// read: nothing on the integration's side changes, so going back is
/// lossless while it stays installed.
class VoiceMigration {
  VoiceMigration(this._settings, this._ha);

  final SettingsManager _settings;
  final HaSocket _ha;

  /// The groups the wizard offers, in order.
  static const groups = [
    'voice',
    'appearance',
    'conversation',
    'assistant',
    'timers',
  ];

  /// The satellite picked in the wizard, over the one the dashboard page
  /// assigned: a pick there must not change the page's own until the
  /// migration goes through.
  String picked = '';

  String get oldSatellite =>
      picked.isNotEmpty ? picked : _settings.get(defs.haSatelliteEntity).trim();

  // ── reading the old satellite ──────────────────────────────────────────

  /// The old satellite's sibling entities by translation key, with their
  /// state: {'pipeline': {'entity_id': ..., 'state': ...}, ...}.
  Future<Map<String, Map<String, Object?>>> oldEntities() async {
    final satellite = oldSatellite;
    if (satellite.isEmpty) return const {};
    final entry = await _ha.request({
      'type': 'config/entity_registry/get',
      'entity_id': satellite,
    });
    final device = entry is Map ? entry['device_id'] : null;
    if (device is! String) return const {};
    final list = await _ha.request({'type': 'config/entity_registry/list'});
    final out = <String, Map<String, Object?>>{};
    if (list is! List) return out;
    for (final raw in list) {
      if (raw is! Map || raw['device_id'] != device) continue;
      final key = '${raw['translation_key'] ?? ''}';
      if (key.isEmpty) continue;
      final entityId = '${raw['entity_id']}';
      final state = await _state(entityId);
      out[key] = {
        'entity_id': entityId,
        'state': state?['state'],
        'attributes': state?['attributes'],
      };
    }
    return out;
  }

  /// One entity's state from Home Assistant's REST API, or null.
  Future<Map<String, Object?>?> stateOf(String entityId) => _state(entityId);

  Future<Map<String, Object?>?> _state(String entityId) async {
    final base = _settings
        .get(defs.haUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    try {
      final response = await http
          .get(
            Uri.parse('$base/api/states/$entityId'),
            headers: {'Authorization': 'Bearer ${_settings.get(defs.haToken)}'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      return body is Map ? body.cast<String, Object?>() : null;
    } catch (_) {
      return null;
    }
  }

  /// The integration's browser settings for the old satellite: the page's
  /// stored copy ([localStorage], `vs-panel-config`) with the server profile
  /// over it, the same merge the engine makes.
  Future<Map<String, Object?>> oldBrowserConfig(String? localStorage) async {
    final merged = <String, Object?>{};
    if (localStorage != null && localStorage.isNotEmpty) {
      try {
        final storage = jsonDecode(localStorage);
        final raw = storage is Map ? storage['vs-panel-config'] : null;
        final config = raw is String ? jsonDecode(raw) : raw;
        if (config is Map) merged.addAll(config.cast<String, Object?>());
      } catch (_) {}
    }
    if (oldSatellite.isNotEmpty) {
      try {
        final profile = await _ha.request({
          'type': 'voice_satellite/get_panel_settings',
          'entity_id': oldSatellite,
        });
        final config = profile is Map ? profile['config'] : null;
        if (config is Map) merged.addAll(config.cast<String, Object?>());
      } catch (_) {
        // An integration without the profile: the page's copy is it.
      }
    }
    return merged;
  }

  // ── mapping ────────────────────────────────────────────────────────────

  static String? _engineFrom(Object? state) => switch ('$state') {
    'On Device (vsWakeWord)' => 'vswakeword',
    'On Device (microWakeWord)' || 'On Device' => 'microwakeword',
    'On Device (openWakeWord)' => 'openwakeword',
    _ => null,
  };

  static String? _sensitivityFrom(Object? state) => switch ('$state') {
    'Slightly sensitive' => 'slightly',
    'Moderately sensitive' => 'moderately',
    'Very sensitive' => 'very',
    _ => null,
  };

  static bool? _switch(Map<String, Map<String, Object?>> entities, String key) {
    final state = entities[key]?['state'];
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }

  static num? _number(Map<String, Map<String, Object?>> entities, String key) =>
      num.tryParse('${entities[key]?['state']}');

  /// The kiosk settings each group carries, by setting key.
  static Map<String, Map<String, Object>> mapSettings(
    Map<String, Map<String, Object?>> entities,
    Map<String, Object?> browser,
  ) {
    T? pick<T>(String key) => browser[key] is T ? browser[key] as T : null;
    final voice = <String, Object>{};
    final engine = _engineFrom(entities['wake_word_detection']?['state']);
    if (engine != null) voice[defs.voiceWakeWordEngine.key] = engine;
    final wake1 = '${entities['wake_word_model']?['state'] ?? ''}';
    final wake2 = '${entities['wake_word_model_2']?['state'] ?? ''}';
    final words = [
      if (wake1.isNotEmpty && wake1 != 'unavailable') wake1,
      if (wake2.isNotEmpty && wake2 != 'Disabled' && wake2 != 'unavailable')
        wake2,
    ];
    if (words.isNotEmpty) voice[defs.voiceWakeWords.key] = jsonEncode(words);
    final sensitivity = _sensitivityFrom(
      entities['wake_word_sensitivity']?['state'],
    );
    if (sensitivity != null) {
      voice[defs.voiceWakeWordSensitivity.key] = sensitivity;
    }
    for (final (key, def) in [
      ('noise_gate', defs.voiceNoiseGate),
      ('stop_word', defs.voiceStopWord),
      ('mute', defs.voiceMute),
      ('wake_sound', defs.voiceWakeSound),
    ]) {
      final on = _switch(entities, key);
      if (on != null) voice[def.key] = on;
    }

    final appearance = <String, Object>{};
    final skin = pick<String>('skin');
    if (skin != null &&
        (defs.voiceSkin.options ?? const <String>[]).contains(skin)) {
      // The integration has one skin, for both assistants.
      appearance[defs.voiceSkin.key] = skin;
      appearance[defs.voiceSkin2.key] = skin;
    }
    final theme = pick<String>('theme_mode');
    if (theme != null && const ['auto', 'light', 'dark'].contains(theme)) {
      appearance[defs.voiceTheme.key] = theme;
    }
    final opacity = browser['background_opacity'];
    appearance[defs.voiceBackgroundOpacity.key] = opacity is num
        ? opacity.clamp(0, 100)
        : -1;
    final scale = pick<num>('text_scale');
    if (scale != null) {
      appearance[defs.voiceTextScale.key] = scale.clamp(50, 200);
    }
    final reactive = pick<bool>('reactive_bar');
    if (reactive != null) appearance[defs.voiceReactiveBar.key] = reactive;

    final conversation = <String, Object>{};
    for (final (from, def) in [
      ('chat_show_user_command', defs.voiceShowCommand),
      ('chat_show_assistant_response', defs.voiceShowAnswer),
      ('chat_show_tool_usage', defs.voiceShowTools),
      ('chat_hide_sentiment_tags', defs.voiceHideSentimentTags),
    ]) {
      final value = pick<bool>(from);
      if (value != null) conversation[def.key] = value;
    }
    final results = pick<num>('media_panel_linger_s');
    if (results != null) {
      conversation[defs.voiceResultsLinger.key] = results.clamp(0, 180);
    }
    final answer = _number(entities, 'overlay_linger');
    if (answer != null) {
      conversation[defs.voiceAnswerLinger.key] = answer.clamp(0, 15);
    }
    final announcement = _number(entities, 'announcement_display_duration');
    if (announcement != null) {
      conversation[defs.voiceAnnouncementLinger.key] = announcement.clamp(
        1,
        60,
      );
    }

    final assistant = <String, Object>{};
    final seamless = pick<bool>('seamless_wake_command');
    if (seamless != null) assistant[defs.voiceSeamlessWake.key] = seamless;
    final delay = pick<num>('stt_followup_delay_ms');
    if (delay != null) {
      assistant[defs.voiceFollowupDelayMs.key] = delay.clamp(0, 1000);
    }
    final chime = pick<bool>('stt_followup_chime');
    if (chime != null) assistant[defs.voiceFollowupChime.key] = chime;
    // TTS output: the select shows the player's name and keeps its entity
    // in an attribute. "Browser" (no attribute) is this kiosk.
    final output = entities['tts_output'];
    if (output != null) {
      final attributes = output['attributes'];
      final target = attributes is Map ? attributes['entity_id'] : null;
      assistant[defs.voiceTtsOutput.key] =
          target is String && target.startsWith('media_player.') ? target : '';
    }
    final mode = '${entities['tts_output_mode_remote']?['state'] ?? ''}';
    if (mode == 'announcement' || mode == 'normal_playback') {
      assistant[defs.voiceTtsOutputMode.key] = mode;
    }

    final timers = <String, Object>{};
    // The integration's pills switch is not carried over: timers open the
    // full screen view here and pills are opt in.
    final nameInPill = pick<bool>('show_timer_name_in_pill');
    if (nameInPill != null) timers[defs.voiceTimerNameInPill.key] = nameInPill;
    final hideName = pick<bool>('hide_timer_name_on_alert');
    if (hideName != null) timers[defs.voiceTimerNameOnAlert.key] = !hideName;
    final speak = pick<bool>('timer_tts_enabled');
    if (speak != null) timers[defs.voiceTimerSpeak.key] = speak;
    final phrase = pick<String>('timer_tts_text');
    if (phrase != null && phrase.trim().isNotEmpty) {
      timers[defs.voiceTimerPhrase.key] = phrase;
    }
    final named = pick<String>('timer_named_tts_text');
    if (named != null && named.trim().isNotEmpty) {
      timers[defs.voiceTimerNamedPhrase.key] = named.replaceAll(
        '%%TIMER_NAME%%',
        '{name}',
      );
    }
    final muteTimers = _switch(entities, 'mute_timers');
    if (muteTimers != null) timers[defs.voiceMuteTimers.key] = muteTimers;

    return {
      'voice': voice,
      'appearance': appearance,
      'conversation': conversation,
      'assistant': assistant,
      'timers': timers,
    };
  }

  /// Home Assistant's selects on the kiosk the voice group sets after the
  /// switch: pipeline, pipeline_2, vad_sensitivity by option; wake_word and
  /// wake_word_2 by the phrase the kiosk offers for the old model.
  static Map<String, String> mapSelects(
    Map<String, Map<String, Object?>> entities,
  ) {
    final out = <String, String>{};
    for (final key in ['pipeline', 'pipeline_2', 'vad_sensitivity']) {
      final state = '${entities[key]?['state'] ?? ''}';
      if (state.isEmpty || state == 'unavailable' || state == 'unknown') {
        continue;
      }
      // The integration writes "Preferred" on its second pipeline, Home
      // Assistant's own select says "preferred".
      out[key] = state == 'Preferred' ? 'preferred' : state;
    }
    final wake1 = '${entities['wake_word_model']?['state'] ?? ''}';
    final wake2 = '${entities['wake_word_model_2']?['state'] ?? ''}';
    if (wake1.isNotEmpty) out['wake_word'] = wakeWordPhraseFor(wake1);
    out['wake_word_2'] = wake2.isEmpty || wake2 == 'Disabled'
        ? 'no_wake_word'
        : wakeWordPhraseFor(wake2);
    return out;
  }

  /// What each group carries, in a line for the wizard.
  static Map<String, String> describe(Map<String, Map<String, Object>> mapped) {
    String onOff(Object? v) => v == true ? 'on' : 'off';
    final out = <String, String>{};
    final voice = mapped['voice'] ?? const {};
    final words = voice[defs.voiceWakeWords.key];
    final wordList = words is String
        ? [for (final w in (jsonDecode(words) as List)) wakeWordPhraseFor('$w')]
        : const <String>[];
    out['voice'] = [
      if (wordList.isNotEmpty) wordList.join(' and '),
      if (voice[defs.voiceWakeWordEngine.key] != null)
        'on ${defs.voiceWakeWordEngine.optionLabels?[voice[defs.voiceWakeWordEngine.key]]}',
      if (voice[defs.voiceWakeWordSensitivity.key] case final String level)
        (defs.voiceWakeWordSensitivity.optionLabels?[level] ?? level)
            .toLowerCase(),
      if (voice[defs.voiceStopWord.key] != null)
        'stop word ${onOff(voice[defs.voiceStopWord.key])}',
      if (voice[defs.voiceWakeSound.key] != null)
        'chimes ${onOff(voice[defs.voiceWakeSound.key])}',
    ].join(', ');
    final appearance = mapped['appearance'] ?? const {};
    final skin = appearance[defs.voiceSkin.key];
    out['appearance'] = [
      if (skin != null) '${defs.voiceSkin.optionLabels?[skin] ?? skin} skin',
      if (appearance[defs.voiceTheme.key] != null)
        '${appearance[defs.voiceTheme.key]} theme',
      if (appearance[defs.voiceTextScale.key] != null)
        'text ${appearance[defs.voiceTextScale.key]}%',
      if (appearance[defs.voiceReactiveBar.key] != null)
        'reactive bar ${onOff(appearance[defs.voiceReactiveBar.key])}',
    ].join(', ');
    final conversation = mapped['conversation'] ?? const {};
    out['conversation'] = [
      if (conversation[defs.voiceShowCommand.key] != null)
        'what you said ${onOff(conversation[defs.voiceShowCommand.key])}',
      if (conversation[defs.voiceShowTools.key] != null)
        'tool use ${onOff(conversation[defs.voiceShowTools.key])}',
      if (conversation[defs.voiceResultsLinger.key] != null)
        'results stay ${conversation[defs.voiceResultsLinger.key]} s',
    ].join(', ');
    final assistant = mapped['assistant'] ?? const {};
    out['assistant'] = [
      if (assistant[defs.voiceSeamlessWake.key] != null)
        'talk right after the wake word ${onOff(assistant[defs.voiceSeamlessWake.key])}',
      if (assistant[defs.voiceFollowupDelayMs.key] != null)
        'follow-up delay ${assistant[defs.voiceFollowupDelayMs.key]} ms',
      if ('${assistant[defs.voiceTtsOutput.key] ?? ''}'.isNotEmpty)
        'sounds on ${assistant[defs.voiceTtsOutput.key]}',
    ].join(', ');
    final timers = mapped['timers'] ?? const {};
    out['timers'] = [
      if (timers[defs.voiceTimerSpeak.key] != null)
        'spoken alerts ${onOff(timers[defs.voiceTimerSpeak.key])}',
    ].join(', ');
    return out;
  }

  // ── automations ────────────────────────────────────────────────────────

  /// Every automation and script referencing the old satellite's device or
  /// entities: [{kind, id, name, refs}]. Listed only, never changed.
  Future<List<Map<String, Object?>>> automations(
    Map<String, Map<String, Object?>> entities,
  ) async {
    final satellite = oldSatellite;
    if (satellite.isEmpty) return const [];
    final found = <String, Set<String>>{};
    Future<void> related(String type, String id) async {
      try {
        final result = await _ha.request({
          'type': 'search/related',
          'item_type': type,
          'item_id': id,
        });
        if (result is! Map) return;
        for (final kind in ['automation', 'script']) {
          final ids = result[kind];
          if (ids is! List) continue;
          for (final item in ids) {
            (found['$item'] ??= <String>{}).add(id);
          }
        }
      } catch (_) {}
    }

    await related('entity', satellite);
    for (final entity in entities.values) {
      final id = '${entity['entity_id'] ?? ''}';
      if (id.isNotEmpty) await related('entity', id);
    }
    try {
      final entry = await _ha.request({
        'type': 'config/entity_registry/get',
        'entity_id': satellite,
      });
      final device = entry is Map ? entry['device_id'] : null;
      if (device is String) await related('device', device);
    } catch (_) {}
    final out = <Map<String, Object?>>[];
    for (final e in found.entries) {
      final state = await _state(e.key);
      final attributes = state?['attributes'];
      out.add({
        'kind': e.key.startsWith('script.') ? 'Script' : 'Automation',
        'id': e.key,
        'name': attributes is Map
            ? '${attributes['friendly_name'] ?? e.key}'
            : e.key,
        'refs': [
          for (final ref in e.value)
            if (ref.contains('.')) ref else 'device',
        ],
      });
    }
    out.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    return out;
  }
}
