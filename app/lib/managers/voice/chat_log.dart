import 'assist_view.dart';

/// Turns Home Assistant's chat log into what the overlay shows: a line per
/// tool the assistant called and the results worth a panel. The rules are
/// Voice Satellite's (its tool-name humanizer and pipeline tool results).

/// "HassTurnOn" reads "Turn on", "weather__get_weather_forecast" reads "Get
/// weather forecast", "search_images" reads "Search images".
String humanizeToolName(String raw) {
  if (raw.isEmpty) return raw;
  var name = raw.contains('__') ? raw.split('__').last : raw;
  final hass = RegExp(r'^Hass([A-Z][a-zA-Z]+)$').firstMatch(name);
  if (hass != null) {
    final words = hass
        .group(1)!
        .replaceAllMapped(RegExp('([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .toLowerCase();
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
  name = name.replaceAll('_', ' ').trim();
  if (name.isEmpty) return raw;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

/// The panels one tool result makes, if any.
List<AssistResult> resultsFromTool(String toolName, Object? result) {
  if (result is! Map) return const [];
  final data = result.cast<String, Object?>();
  if (data['error'] != null && data['error'] != false) return const [];
  if (toolName.endsWith('get_weather_forecast') && data['forecast'] != null) {
    return [AssistResult('weather', data)];
  }
  if (toolName.contains('financial-data__get_financial_data') &&
      data['query_type'] != null) {
    return [AssistResult('financial', data)];
  }
  final out = <AssistResult>[];
  final items = data['results'];
  if (items is List) {
    final maps = [
      for (final r in items)
        if (r is Map) r.cast<String, Object?>(),
    ];
    final videos = [
      for (final r in maps)
        if (r['video_id'] != null) r,
    ];
    if (videos.isNotEmpty) {
      out.add(
        AssistResult('videos', {
          'items': videos,
          'autoPlay': data['auto_play'] == true,
        }),
      );
    }
    final images = [
      for (final r in maps)
        if (r['video_id'] == null && r['image_url'] != null) r,
    ];
    if (images.isNotEmpty) {
      out.add(
        AssistResult('images', {
          'items': images,
          'autoDisplay': data['auto_display'] == true,
        }),
      );
    }
  }
  final featured = data['featured_image'];
  if (featured is String && featured.isNotEmpty) {
    out.add(AssistResult('featured', {'image_url': featured}));
  }
  return out;
}

/// What the latest turn of a conversation did.
class ChatDigest {
  const ChatDigest({
    this.tools = const [],
    this.results = const [],
    this.answer = '',
  });

  final List<String> tools;
  final List<AssistResult> results;
  final String answer;
}

/// The latest turn out of a chat log's `content` (everything after the last
/// user message).
ChatDigest digestLatestTurn(List<Object?> content) {
  var start = 0;
  for (var i = content.length - 1; i >= 0; i--) {
    final item = content[i];
    if (item is Map && item['role'] == 'user') {
      start = i + 1;
      break;
    }
  }
  final tools = <String>[];
  final results = <AssistResult>[];
  final toolNames = <String, String>{};
  var answer = '';
  for (final item in content.skip(start)) {
    if (item is! Map) continue;
    switch (item['role']) {
      case 'assistant':
        final calls = item['tool_calls'];
        if (calls is List) {
          for (final call in calls) {
            if (call is! Map) continue;
            final name = '${call['tool_name'] ?? call['name'] ?? ''}';
            if (name.isEmpty) continue;
            toolNames['${call['id'] ?? ''}'] = name;
            tools.add(humanizeToolName(name));
          }
        }
        final text = item['content'];
        if (text is String && text.trim().isNotEmpty) answer = text;
      case 'tool_result':
        final name =
            '${item['tool_name'] ?? toolNames['${item['tool_call_id']}'] ?? ''}';
        results.addAll(
          resultsFromTool(name, item['tool_result'] ?? item['result']),
        );
    }
  }
  return ChatDigest(tools: tools, results: results, answer: answer);
}

/// Sentiment tags some assistants put in their answers (`[happy]`) and the
/// audio tags Gemini's speech reads (`<laugh>`, `<short pause>`), left out
/// of what the overlay shows when the setting says so. Angle tags are only
/// short lowercase words, so `a < b` stays, and never a common HTML tag
/// (`<b>`, `<br>`), so an answer's markup stays as it came. While the
/// answer is still [streaming], a tag cut off at its end (`<chuck`) goes
/// too.
String stripSentimentTags(String text, {bool streaming = false}) {
  var out = text
      .replaceAll(RegExp(r'\[[^\[\]\n]{1,40}\]'), '')
      .replaceAll(_audioTag, '');
  if (streaming) {
    out = out.replaceFirst(
      RegExp(r'(\[[^\[\]\n]{0,40}|<[a-z][a-z _-]{0,30})$'),
      '',
    );
  }
  return out.replaceAll(RegExp(r'[ \t]{2,}'), ' ').trim();
}

const _htmlNames =
    'a|abbr|b|big|blockquote|br|center|cite|code|dd|del|div|dl|dt|em|font|'
    'h[1-6]|hr|i|img|ins|kbd|li|mark|ol|p|pre|q|s|samp|small|span|strike|'
    'strong|sub|sup|table|tbody|td|th|thead|time|tr|tt|u|ul|var';

final _audioTag = RegExp('<(?!(?:$_htmlNames)\\b)[a-z][a-z _-]{0,30}>');
