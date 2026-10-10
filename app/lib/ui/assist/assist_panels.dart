import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/messages.dart';
import '../../managers/voice/assist_view.dart';
import '../weather_readings.dart';
import 'assist_skins.dart';

/// The result panel's look in one skin and theme, from the skin's CSS
/// (its .vs-image-panel, weather, financial and video rules).
class PanelStyle {
  const PanelStyle({
    required this.surface,
    required this.text,
    required this.secondary,
    required this.muted,
    required this.divider,
    required this.badge,
    required this.badgeText,
    required this.up,
    required this.down,
    this.border,
    this.shadow,
  });

  final Color surface;
  final Color text;

  /// The weather condition and the video channel.
  final Color secondary;

  /// Humidity, forecast times, financial details.
  final Color muted;
  final Color divider;
  final Color badge;
  final Color badgeText;
  final Color up;
  final Color down;
  final Color? border;
  final Color? shadow;
}

/// The parts of the panel that do not change with the theme.
class PanelShape {
  const PanelShape({
    this.radius = 20,
    this.imageRadius = 12,
    this.blur = 0,
    this.borderWidth = 1,
    this.weight = FontWeight.w500,
    this.glass = false,
    this.glow,
  });

  final double radius;
  final double imageRadius;

  /// A frosted panel blurs what is under it.
  final double blur;
  final double borderWidth;

  /// The weight of the big numbers (temperature, price).
  final FontWeight weight;

  /// Glass panels keep their surface behind weather and stock results;
  /// the others draw those straight on the backdrop.
  final bool glass;

  /// The terminal's green bloom on the big numbers.
  final Color? glow;
}

const _googleLight = PanelStyle(
  surface: Color(0xFFFFFFFF),
  text: Color(0xFF202124),
  secondary: Color(0xFF5F6368),
  muted: Color(0xFF80868B),
  divider: Color(0x1F3C4043),
  badge: Color(0x143C4043),
  badgeText: Color(0xFF5F6368),
  up: Color(0xFF0F9D58),
  down: Color(0xFFEA4335),
  shadow: Color(0x263C4043),
);
const _googleDark = PanelStyle(
  surface: Color(0xFF303134),
  text: Color(0xFFE8EAED),
  secondary: Color(0xFF9AA0A6),
  muted: Color(0xFF9AA0A6),
  divider: Color(0x1FFFFFFF),
  badge: Color(0x1AFFFFFF),
  badgeText: Color(0xFF9AA0A6),
  up: Color(0xFF0F9D58),
  down: Color(0xFFEA4335),
  shadow: Color(0x4D000000),
);

const _panels = <String, (PanelShape, PanelStyle, PanelStyle?)>{
  'kiosk-satellite': (
    PanelShape(radius: 24),
    PanelStyle(
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF212327),
      secondary: Color(0xFF5D6066),
      muted: Color(0xFF7D8087),
      divider: Color(0xFFE3E0DA),
      badge: Color(0xFFD4E3E4),
      badgeText: Color(0xFF1B3437),
      up: Color(0xFF56814F),
      down: Color(0xFFA9501F),
      shadow: Color(0x1F000000),
    ),
    PanelStyle(
      surface: Color(0xFF2A2B2F),
      text: Color(0xFFE8EAED),
      secondary: Color(0xFFB6BABF),
      muted: Color(0xFF9A9EA4),
      divider: Color(0xFF3C3E43),
      badge: Color(0xFF2F4649),
      badgeText: Color(0xFFD0E3E5),
      up: Color(0xFF749C6F),
      down: Color(0xFFD97E4C),
      shadow: Color(0x66000000),
    ),
  ),
  'default': (
    PanelShape(),
    PanelStyle(
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF121212),
      secondary: Color(0xFF5F6368),
      muted: Color(0xFF80868B),
      divider: Color(0x1F3C4043),
      badge: Color(0x143C4043),
      badgeText: Color(0xFF5F6368),
      up: Color(0xFF0F9D58),
      down: Color(0xFFEA4335),
      shadow: Color(0x263C4043),
    ),
    _googleDark,
  ),
  'google-home': (PanelShape(), _googleLight, _googleDark),
  'home-assistant': (
    PanelShape(radius: 12, imageRadius: 8),
    PanelStyle(
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF212121),
      secondary: Color(0xFF03A9F4),
      muted: Color(0x8A000000),
      divider: Color(0x1F000000),
      badge: Color(0x0F000000),
      badgeText: Color(0x8A000000),
      up: Color(0xFF4CAF50),
      down: Color(0xFFDB4437),
      shadow: Color(0x1A000000),
    ),
    PanelStyle(
      surface: Color(0xFF1C1C1C),
      text: Color(0xFFE1E1E1),
      secondary: Color(0xFF03A9F4),
      muted: Color(0x8AFFFFFF),
      divider: Color(0x1FFFFFFF),
      badge: Color(0x1AFFFFFF),
      badgeText: Color(0x8AFFFFFF),
      up: Color(0xFF4CAF50),
      down: Color(0xFFDB4437),
      shadow: Color(0x1A000000),
    ),
  ),
  'alexa': (
    PanelShape(radius: 16, imageRadius: 8, weight: FontWeight.w700),
    PanelStyle(
      surface: Color(0xCC000814),
      text: Color(0xFFFFFFFF),
      secondary: Color(0xCC00CAFF),
      muted: Color(0x80FFFFFF),
      divider: Color(0x2600CAFF),
      badge: Color(0x2600CAFF),
      badgeText: Color(0xCC00CAFF),
      up: Color(0xFF00E676),
      down: Color(0xFFFF5252),
      border: Color(0x4000CAFF),
      shadow: Color(0x66000000),
    ),
    null,
  ),
  'siri': (
    PanelShape(imageRadius: 10, blur: 10, weight: FontWeight.w600),
    PanelStyle(
      surface: Color(0x14FFFFFF),
      text: Color(0xFFFFFFFF),
      secondary: Color(0xCC8B5CF6),
      muted: Color(0x80FFFFFF),
      divider: Color(0x4D8B5CF6),
      badge: Color(0x1AFFFFFF),
      badgeText: Color(0xB3FFFFFF),
      up: Color(0xFF34D399),
      down: Color(0xFFF87171),
      border: Color(0x1FFFFFFF),
      shadow: Color(0x4D000000),
    ),
    null,
  ),
  'retro-terminal': (
    PanelShape(
      radius: 0,
      imageRadius: 0,
      borderWidth: 2,
      weight: FontWeight.w700,
      glow: Color(0x6633FF33),
    ),
    PanelStyle(
      surface: Color(0xE6000A00),
      text: Color(0xFF33FF33),
      secondary: Color(0xFF1A8C1A),
      muted: Color(0x8033FF33),
      divider: Color(0x3333FF33),
      badge: Color(0x1A33FF33),
      badgeText: Color(0xB333FF33),
      up: Color(0xFF33FF33),
      down: Color(0xFFFF3333),
      border: Color(0x6633FF33),
    ),
    null,
  ),
  'waveform': (
    PanelShape(radius: 14, blur: 12, glass: true),
    PanelStyle(
      surface: Color(0x59FFFFFF),
      text: Color(0xFF1A1A2E),
      secondary: Color(0xFF6E6E88),
      muted: Color(0xFF6E6E88),
      divider: Color(0x14000000),
      badge: Color(0x0F000000),
      badgeText: Color(0xFF6E6E88),
      up: Color(0xFF0F9D58),
      down: Color(0xFFEA4335),
    ),
    PanelStyle(
      surface: Color(0x661A1A1A),
      text: Color(0xFFE4E4EC),
      secondary: Color(0xFF8888A0),
      muted: Color(0xFF8888A0),
      divider: Color(0x14FFFFFF),
      badge: Color(0x14FFFFFF),
      badgeText: Color(0xFF8888A0),
      up: Color(0xFF0F9D58),
      down: Color(0xFFEA4335),
    ),
  ),
  'lens-flares': (
    PanelShape(radius: 14, blur: 12, glass: true),
    PanelStyle(
      surface: Color(0x730A0E1A),
      text: Color(0xFFE6ECFF),
      secondary: Color(0xFFB8C4DC),
      muted: Color(0xFFB8C4DC),
      divider: Color(0x1AB4C8FF),
      badge: Color(0x1AB4C8FF),
      badgeText: Color(0xFFB8C4DC),
      up: Color(0xFF4DDC94),
      down: Color(0xFFFF6480),
    ),
    null,
  ),
  'jarvis': (
    PanelShape(radius: 4, imageRadius: 2, blur: 12, glass: true),
    PanelStyle(
      surface: Color(0x99041A22),
      text: Color(0xFFE6FCFF),
      secondary: Color(0xFF7CCAD4),
      muted: Color(0xFF7CCAD4),
      divider: Color(0x334EE6F0),
      badge: Color(0x1A4EE6F0),
      badgeText: Color(0xFF8FE3EC),
      up: Color(0xFF4DDC94),
      down: Color(0xFFFF6480),
      border: Color(0x804EE6F0),
    ),
    null,
  ),
  'ink-blobs': (
    PanelShape(radius: 14, blur: 12, glass: true),
    PanelStyle(
      surface: Color(0x59FFFFFF),
      text: Color(0xFF161A26),
      secondary: Color(0xFF5C6478),
      muted: Color(0xFF5C6478),
      divider: Color(0x14000000),
      badge: Color(0x0F000000),
      badgeText: Color(0xFF5C6478),
      up: Color(0xFF0F9D58),
      down: Color(0xFFEA4335),
    ),
    PanelStyle(
      surface: Color(0x6614161E),
      text: Color(0xFFEEF0F6),
      secondary: Color(0xFF8A90A4),
      muted: Color(0xFF8A90A4),
      divider: Color(0x14FFFFFF),
      badge: Color(0x14FFFFFF),
      badgeText: Color(0xFF8A90A4),
      up: Color(0xFF0F9D58),
      down: Color(0xFFEA4335),
    ),
  ),
};

(PanelShape, PanelStyle) panelStyleFor(AssistSkin skin, bool dark) {
  final entry = _panels[skin.id] ?? _panels['kiosk-satellite']!;
  return (entry.$1, dark ? (entry.$3 ?? entry.$2) : entry.$2);
}

/// The one result a turn shows, as Voice Satellite picks it: videos, then
/// images, then the weather, a quote, or a search's featured image.
AssistResult? primaryResult(List<AssistResult> results) {
  for (final kind in ['videos', 'images', 'weather', 'financial', 'featured']) {
    for (final r in results) {
      if (r.kind == kind) return r;
    }
  }
  return null;
}

/// Weather, a quote and a featured image take the narrower column.
bool isFeaturedResult(AssistResult r) =>
    r.kind == 'weather' || r.kind == 'financial' || r.kind == 'featured';

/// A portrait panel's top and its tallest, of the screen's height: the chat
/// keeps below the two together.
const panelTop = 0.03;
const panelMaxPortrait = 0.47;

/// The right edge the chat keeps clear of the panel, from the right.
double chatRightInset(Size screen, AssistResult? result) {
  if (result == null || screen.height > screen.width) {
    return screen.width * 0.075;
  }
  return screen.width * (isFeaturedResult(result) ? 0.325 : 0.375) + 40;
}

/// The result panel: a grid of images, a list of videos, the weather or a
/// quote, in the skin's look. Taps open the lightbox through [onOpen].
class AssistResultPanel extends StatelessWidget {
  const AssistResultPanel({
    super.key,
    required this.result,
    required this.skin,
    required this.dark,
    required this.scale,
    required this.resolve,
    required this.onOpen,
  });

  final AssistResult result;
  final AssistSkin skin;
  final bool dark;
  final double scale;

  /// Turns a Home Assistant relative path into a full URL.
  final String Function(String) resolve;

  /// An image URL (kind 'image') or a video id (kind 'video') to open.
  final void Function(String kind, String value) onOpen;

  @override
  Widget build(BuildContext context) {
    final (shape, style) = panelStyleFor(skin, dark);
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height > size.width;
    final featured = isFeaturedResult(result);
    final bare =
        (result.kind == 'weather' || result.kind == 'financial') &&
        !shape.glass;
    final maxHeight = size.height * (portrait ? panelMaxPortrait : 0.70);
    final double width = portrait
        ? (featured
              ? (size.width * 0.9).clamp(0, 460).toDouble()
              : size.width * 0.9)
        : size.width * (featured ? 0.25 : 0.30);
    final content = switch (result.kind) {
      'weather' => _weather(context, style, shape),
      'financial' => _financial(context, style, shape),
      'videos' => _videos(style, shape),
      _ => _images(style, shape, maxHeight - 24),
    };
    Widget panel = Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: bare ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: bare
          ? null
          : BoxDecoration(
              color: style.surface,
              borderRadius: BorderRadius.circular(shape.radius),
              border: style.border == null || result.kind == 'weather'
                  ? null
                  : Border.all(color: style.border!, width: shape.borderWidth),
              boxShadow: style.shadow == null || shape.glass
                  ? null
                  : [
                      BoxShadow(
                        color: style.shadow!,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                      BoxShadow(
                        color: style.shadow!,
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(right: 8),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontFamily: skin.font, color: style.text),
          child: content,
        ),
      ),
    );
    if (!bare && shape.blur > 0) {
      panel = ClipRRect(
        borderRadius: BorderRadius.circular(shape.radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: shape.blur, sigmaY: shape.blur),
          child: panel,
        ),
      );
    }
    return panel;
  }

  TextStyle _t(double size, Color color, {FontWeight? weight, Color? glow}) =>
      TextStyle(
        fontSize: size * scale,
        color: color,
        fontWeight: weight,
        height: 1.2,
        shadows: glow == null ? null : [Shadow(color: glow, blurRadius: 8)],
      );

  Widget _weather(BuildContext context, PanelStyle style, PanelShape shape) {
    final data = result.data;
    final forecast = [
      for (final f in (data['forecast'] as List? ?? const []))
        if (f is Map) f.cast<String, Object?>(),
    ];
    final icon = '${data['condition_icon'] ?? ''}';
    final condition = forecast.isEmpty
        ? ''
        : '${forecast.first['condition'] ?? ''}';
    final type = '${data['forecast_type'] ?? 'daily'}';
    final locale = Localizations.localeOf(context).toLanguageTag();
    String when(Map<String, Object?> f) {
      if (type == 'hourly') return '${f['time'] ?? ''}';
      final raw = '${f['date'] ?? ''}';
      final parsed = DateTime.tryParse(raw);
      final short = parsed == null
          ? (raw.length > 3 ? raw.substring(0, 3) : raw)
          : DateFormat.E(locale).format(parsed);
      if (type != 'twice_daily') return short;
      return '$short ${voiceText(context, f['is_daytime'] == false ? 'Night' : 'Day')}';
    }

    String label(String c) =>
        c.isEmpty ? '' : weatherMoodConditionText(context, c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
          child: Row(
            spacing: 20,
            children: [
              if (icon.isNotEmpty)
                Image.network(
                  resolve(icon),
                  width: 96,
                  height: 96,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    if ('${data['current_temperature'] ?? ''}'.isNotEmpty)
                      Text(
                        '${data['current_temperature']}',
                        style: _t(
                          52,
                          style.text,
                          weight: shape.weight,
                          glow: shape.glow,
                        ),
                      ),
                    if (condition.isNotEmpty)
                      Text(label(condition), style: _t(22, style.secondary)),
                    if ('${data['current_humidity'] ?? ''}'.isNotEmpty)
                      Text(
                        '${l10nHumidity(context)}: ${data['current_humidity']}',
                        style: _t(18, style.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (forecast.isNotEmpty) ...[
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: style.divider,
          ),
          for (final f in forecast)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(when(f), style: _t(18, style.muted)),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(
                      label('${f['condition'] ?? ''}'),
                      style: _t(18, style.secondary),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 56),
                    child: Text(
                      f['temperature'] == null ? '' : '${f['temperature']}°',
                      textAlign: TextAlign.right,
                      style: _t(
                        22,
                        style.text,
                        weight: shape.weight,
                        glow: shape.glow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _financial(BuildContext context, PanelStyle style, PanelShape shape) {
    final d = result.data;
    final currency = '${d['currency'] ?? 'USD'}';
    num? n(String key) => d[key] is num ? d[key] as num : null;
    if (d['query_type'] == 'currency') {
      final from = '${d['from_currency'] ?? ''}';
      final to = '${d['to_currency'] ?? ''}';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
            child: Text(
              '${d['amount'] ?? ''} $from = ${d['converted_amount'] ?? ''} $to',
              style: _t(42, style.text, weight: shape.weight, glow: shape.glow),
            ),
          ),
          if (d['rate'] != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                '1 $from = ${d['rate']} $to',
                style: _t(20, style.muted),
              ),
            ),
        ],
      );
    }
    final change = n('change');
    final crypto = d['query_type'] == 'crypto';
    final strings = l10n(context);
    final details = [
      if (crypto) ...[
        if (n('high') != null)
          strings.voiceFinancialHigh24h(formatPrice(n('high')!, currency)),
        if (n('low') != null)
          strings.voiceFinancialLow24h(formatPrice(n('low')!, currency)),
        if (n('market_cap') != null)
          strings.voiceFinancialMarketCap(
            formatLargeNumber(n('market_cap')!, currency),
          ),
      ] else ...[
        if (n('open') != null)
          strings.voiceFinancialOpen(formatPrice(n('open')!, currency)),
        if (n('high') != null)
          strings.voiceFinancialHigh(formatPrice(n('high')!, currency)),
        if (n('low') != null)
          strings.voiceFinancialLow(formatPrice(n('low')!, currency)),
      ],
    ];
    final logo = '${d['featured_image'] ?? ''}';
    final exchange = '${d['exchange'] ?? ''}'.split(' - ').first.trim();
    final symbol = '${d['symbol'] ?? ''}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            spacing: 12,
            children: [
              if (logo.isNotEmpty)
                ClipOval(
                  child: Image.network(
                    resolve(logo),
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              Expanded(
                child: Text(
                  '${d['name'] ?? ''} ${symbol.isEmpty ? '' : '($symbol)'}'
                      .trim(),
                  style: _t(20, style.text),
                ),
              ),
              if (exchange.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: style.badge,
                    borderRadius: BorderRadius.circular(
                      shape.radius == 0 ? 0 : 6,
                    ),
                  ),
                  child: Text(exchange, style: _t(12, style.badgeText)),
                ),
            ],
          ),
        ),
        if (n('current_price') != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Text(
              formatPrice(n('current_price')!, currency),
              style: _t(48, style.text, weight: shape.weight, glow: shape.glow),
            ),
          ),
        if (change != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              '${change >= 0 ? '▲' : '▼'} '
              '${formatChange(change, n('percent_change'), currency)}',
              style: _t(22, change >= 0 ? style.up : style.down),
            ),
          ),
        if (details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(details.join(' · '), style: _t(16, style.muted)),
          ),
      ],
    );
  }

  Widget _images(PanelStyle style, PanelShape shape, double maxHeight) {
    final items = result.kind == 'featured'
        ? [result.data]
        : [
            for (final i in (result.data['items'] as List? ?? const []))
              if (i is Map) i.cast<String, Object?>(),
          ];
    final single = items.length == 1;
    Widget tile(Map<String, Object?> item) {
      final full = resolve('${item['image_url'] ?? ''}');
      final thumb = '${item['thumbnail_url'] ?? ''}';
      final image = Image.network(
        thumb.isEmpty ? full : resolve(thumb),
        fit: single ? BoxFit.contain : BoxFit.cover,
        frameBuilder: _fadeIn,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
      return GestureDetector(
        onTap: () => onOpen('image', full),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(shape.imageRadius),
          child: single
              ? ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: image,
                )
              : AspectRatio(aspectRatio: 4 / 3, child: image),
        ),
      );
    }

    if (single) return tile(items.first);
    return LayoutBuilder(
      builder: (context, box) {
        final w = (box.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items) SizedBox(width: w, child: tile(item)),
          ],
        );
      },
    );
  }

  Widget _videos(PanelStyle style, PanelShape shape) {
    final items = [
      for (final i in (result.data['items'] as List? ?? const []))
        if (i is Map) i.cast<String, Object?>(),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final item in items)
          GestureDetector(
            onTap: () => onOpen('video', '${item['video_id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(shape.imageRadius),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          resolve('${item['thumbnail_url'] ?? ''}'),
                          fit: BoxFit.cover,
                          frameBuilder: _fadeIn,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: style.badge),
                        ),
                      ),
                    ),
                    if ('${item['duration'] ?? ''}'.isNotEmpty)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item['duration']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        '${item['title'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: style.text,
                        ),
                      ),
                      if ('${item['channel'] ?? ''}'.isNotEmpty)
                        Text(
                          '${item['channel']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: style.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Widget _fadeIn(
    BuildContext context,
    Widget child,
    int? frame,
    bool sync,
  ) => sync
      ? child
      : AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
}

/// "Humidity", as the screensaver's weather overlay says it.
String l10nHumidity(BuildContext context) =>
    l10n(context).screensaverOverlayHumidity;

final _priceFormats = <String, NumberFormat>{};

/// Voice Satellite's price format: the currency's symbol, six decimals
/// under one, two otherwise, en-US grouping.
String formatPrice(num value, String currency) {
  final decimals = value.abs() < 1 ? 6 : 2;
  final format = _priceFormats.putIfAbsent(
    '$currency-$decimals',
    () => NumberFormat.simpleCurrency(
      locale: 'en_US',
      name: currency,
      decimalDigits: decimals,
    ),
  );
  return format.format(value);
}

String formatLargeNumber(num value, String currency) {
  final symbol = currency == 'USD' ? r'$' : '';
  if (value >= 1e12) return '$symbol${(value / 1e12).toStringAsFixed(2)}T';
  if (value >= 1e9) return '$symbol${(value / 1e9).toStringAsFixed(2)}B';
  if (value >= 1e6) return '$symbol${(value / 1e6).toStringAsFixed(2)}M';
  return formatPrice(value, currency);
}

String formatChange(num change, num? percent, String currency) {
  final sign = change >= 0 ? '+' : '-';
  final price = formatPrice(change.abs(), currency);
  final pct = percent == null
      ? ''
      : ' ($sign${percent.abs().toStringAsFixed(2)}%)';
  return '$sign$price$pct';
}
