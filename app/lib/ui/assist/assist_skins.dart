import 'package:flutter/material.dart';

/// Voice Satellite's skins, as their stylesheets and scripts define them.
/// Every number here is the skin's CSS value in CSS pixels, drawn as
/// logical pixels (times the Text size setting for font sizes). The
/// overlay, the chat, the bar and the art read these and nothing else, so
/// a skin changes by changing its entry.

/// The canvas-drawn backgrounds four skins add over the backdrop.
enum SkinArt { none, waveform, lensFlares, inkBlobs, jarvis }

/// The thinking indicator: three bouncing bullets, the terminal's blinking
/// bullets, or the Kiosk Satellite mark's four bars.
enum DotsStyle { bounce, blink, logoBars }

/// A CSS text-shadow or box-shadow: offset, blur radius and color.
class CssShadow {
  const CssShadow(this.color, this.blur, {this.dx = 0, this.dy = 0});
  final Color color;
  final double blur;
  final double dx;
  final double dy;

  /// The Flutter shadow that blurs like the CSS one. CSS blurs a shadow
  /// with a standard deviation of half its radius.
  Shadow get shadow => Shadow(
    color: color,
    offset: Offset(dx, dy),
    blurRadius: blurRadiusFor(blur / 2),
  );
}

/// Chrome's font-optical-sizing: auto for the skins' variable fonts. Inter
/// has an optical size axis (14 to 32) the browser sets to the font size,
/// where Flutter would stay at 14 and draw it wider. Naming an axis takes
/// over from the automatic weight mapping, so the weight goes too.
List<FontVariation>? fontVariationsFor(
  String font,
  double size,
  FontWeight weight,
) => font == 'Inter'
    ? [
        FontVariation('opsz', size.clamp(14.0, 32.0)),
        FontVariation('wght', weight.value.toDouble()),
      ]
    : null;

/// The Flutter blur radius for a Gaussian of standard deviation [sigma]
/// (Flutter maps a radius r to sigma 0.57735 r + 0.5).
double blurRadiusFor(double sigma) =>
    sigma <= 0.5 ? 0 : (sigma - 0.5) / 0.57735;

/// One theme's colors: the backdrop and its default opacity, the chat's
/// text colors and shadows, the thinking bullets.
class SkinPalette {
  const SkinPalette({
    required this.backdrop,
    required this.opacity,
    required this.user,
    required this.answer,
    required this.tool,
    required this.pill,
    required this.dots,
    this.userShadows = const [],
    this.answerShadows = const [],
    this.toolShadows = const [],
  });

  final Color backdrop;
  final double opacity;

  /// What was said, dimmed.
  final Color user;
  final Color answer;

  /// The tool name beside the frozen dots.
  final Color tool;

  /// Timer pills and the alert.
  final Color pill;

  /// The three thinking bullets (the logo bars take four).
  final List<Color> dots;
  final List<CssShadow> userShadows;
  final List<CssShadow> answerShadows;

  /// On the thinking and tool lines.
  final List<CssShadow> toolShadows;
}

/// The activity indicator a skin draws.
sealed class BarStyle {
  const BarStyle();
}

/// A thin gradient bar at the bottom center: left and right 20%, 24 px up.
/// Its gradient is twice the bar's width and slides one period left per
/// cycle. Reactive, it stretches from its bottom edge with the level and
/// a blurred copy of the gradient glows around it.
class GradientBar extends BarStyle {
  const GradientBar({
    required this.colors,
    this.stops,
    this.glowColors,
    // Thicker at rest than Voice Satellite's 4 px, which read as a hairline.
    this.height = 6,
    this.glowStrip = 8,
  });

  final List<Color> colors;

  /// Null spreads [colors] evenly.
  final List<double>? stops;

  /// The glow's own gradient (Default's is a shade deeper); null reuses
  /// [colors] and [stops].
  final List<Color>? glowColors;
  final double height;

  /// The height of the blurred strip behind the reactive bar.
  final double glowStrip;
}

/// Alexa's full-width cyan strip along the bottom edge, shimmering right.
class AlexaStrip extends BarStyle {
  const AlexaStrip();
}

/// Siri's rotating conic gradient around the whole screen.
class SiriFrame extends BarStyle {
  const SiriFrame();
}

/// The terminal's green frame inside the CRT bezel.
class RetroFrame extends BarStyle {
  const RetroFrame();
}

/// No bar: the canvas art is the indicator.
class NoBar extends BarStyle {
  const NoBar();
}

/// Hard stops for four even color bands.
const _quarters = [0.0, 0.25, 0.25, 0.5, 0.5, 0.75, 0.75, 1.0];
List<Color> _bands(List<Color> c) => [
  c[0],
  c[0],
  c[1],
  c[1],
  c[2],
  c[2],
  c[3],
  c[3],
];

class AssistSkin {
  const AssistSkin({
    required this.id,
    required this.name,
    required this.light,
    this.dark,
    required this.bar,
    this.dockedBar,
    this.art = SkinArt.none,
    this.font = 'Rubik',
    this.blur = 6,
    this.chatBottom = 72,
    // Closer to the reactive bar than Voice Satellite's 120, still clear of
    // it at full stretch.
    this.chatBottomReactive = 88,
    this.chatTop = 32,
    this.gap = 8,
    this.centered = false,
    this.msgMaxWidth = 0.85,
    this.fadeDy = 8,
    this.fadeMs = 300,
    this.userSize = 32,
    this.answerSize = 36,
    this.userWeight = FontWeight.w400,
    this.answerWeight = FontWeight.w400,
    this.announcementTop = 0.5,
    this.dots = DotsStyle.bounce,
    this.dotSize = 36,
    this.idleDotSize = 24,
    this.dotsGap = 6,
    this.dotGlow,
    this.toolSize = 24,
    this.toolMargin = 8,
    this.toolWeight = FontWeight.w400,
    this.toolItalic = true,
    this.prefix = '',
    this.crt = false,
    this.voiceOnly = false,
  });

  final String id;
  final String name;
  final SkinPalette light;

  /// Null for the skins with one look, which draw [light] always.
  final SkinPalette? dark;
  final BarStyle bar;

  /// The bar a docked conversation shows, for a skin whose indicator is
  /// its full-screen art: the art does not run for the minutes a
  /// conversation lasts. Null uses [bar].
  final BarStyle? dockedBar;

  BarStyle get barDocked => dockedBar ?? bar;
  final SkinArt art;
  final String font;

  /// The backdrop's backdrop-filter blur, seen while it is see-through.
  final double blur;

  /// The chat's bottom edge, and with the reactive bar showing.
  final double chatBottom;
  final double chatBottomReactive;

  /// The room the chat leaves at the top of the screen: a long answer
  /// scrolls within what is left under it, so the command above it stays
  /// on screen and clear of a frame skin's border.
  final double chatTop;
  final double gap;
  final bool centered;

  /// A message's max-width, of the chat's width.
  final double msgMaxWidth;

  /// A new line's entry: it rises this far while fading in.
  final double fadeDy;
  final int fadeMs;
  final double userSize;
  final double answerSize;
  final FontWeight userWeight;
  final FontWeight answerWeight;

  /// The announcement's center, of the screen's height.
  final double announcementTop;
  final DotsStyle dots;

  /// The bullets' size while thinking, and frozen beside a tool name.
  final double dotSize;
  final double idleDotSize;
  final double dotsGap;

  /// The terminal's glow on its blinking bullets.
  final CssShadow? dotGlow;
  final double toolSize;
  final double toolMargin;
  final FontWeight toolWeight;
  final bool toolItalic;

  /// Put before the user's line (the terminal's "> ").
  final String prefix;

  /// The terminal's CRT bezel, scanlines and vignette over the backdrop.
  final bool crt;

  /// Only the Kiosk Satellite mark, its bars moving with the voice: no
  /// text, tool lines or results, for screens too small to read them.
  final bool voiceOnly;

  bool get darkOnly => dark == null;

  /// CSS line-height: normal for the skin's font, as the browser lays it
  /// out (measured at 100 px).
  double get lineHeight => switch (font) {
    'Inter' => 1.21,
    'VT323' => 1.0,
    'Roboto' => 1.17,
    _ => 1.26,
  };

  SkinPalette palette(bool darkTheme) => darkTheme ? (dark ?? light) : light;
}

const kioskSatelliteColors = [
  Color(0xFF18BCF2),
  Color(0xFFF2B705),
  Color(0xFF3FBF5F),
  Color(0xFFE8604C),
];

const _googleColors = [
  Color(0xFF4285F4),
  Color(0xFFEA4335),
  Color(0xFFFBBC05),
  Color(0xFF34A853),
];

const _defaultBar = [
  Color(0xFFFF4444),
  Color(0xFFFF7733),
  Color(0xFFFFBB22),
  Color(0xFF88DD33),
  Color(0xFF33CC77),
  Color(0xFF33BBEE),
  Color(0xFF4488FF),
  Color(0xFF8844FF),
  Color(0xFFFF44AA),
  Color(0xFFFF4444),
];

const _defaultGlow = [
  Color(0xFFFF3333),
  Color(0xFFFF6622),
  Color(0xFFFFAA11),
  Color(0xFF77CC22),
  Color(0xFF22BB66),
  Color(0xFF22AADD),
  Color(0xFF3377FF),
  Color(0xFF7733FF),
  Color(0xFFFF3399),
  Color(0xFFFF3333),
];

/// Home Assistant's primary color and its three oklch variants, as the
/// browser renders them for the default theme.
const _haColors = [
  Color(0xFF006AC0),
  Color(0xFF03A9F4),
  Color(0xFF61C9FF),
  Color(0xFF97E8FF),
];

const _alexaShadow = [CssShadow(Color(0x80000000), 4, dy: 1)];
const _terminalShadow = [CssShadow(Color(0x6633FF33), 8)];
const _flareUserShadow = [
  CssShadow(Color(0xF2000000), 4),
  CssShadow(Color(0xBF000000), 14),
  CssShadow(Color(0xCC000000), 4, dy: 2),
];
const _jarvisShadow = [
  CssShadow(Color(0xE6000000), 4),
  CssShadow(Color(0x9900C8E0), 12),
];
const _jarvisAnswerShadow = [
  CssShadow(Color(0xF2000000), 4),
  CssShadow(Color(0xCC000000), 14),
  CssShadow(Color(0x8000C8E0), 16),
];
const _flareAnswerShadow = [
  CssShadow(Color(0xF2000000), 4),
  CssShadow(Color(0xD9000000), 14),
  CssShadow(Color(0xE6000000), 4, dy: 2),
];

/// Every skin, in the order the picker shows them.
final assistSkins = <AssistSkin>[
  AssistSkin(
    id: 'kiosk-satellite',
    name: 'Kiosk Satellite',
    light: const SkinPalette(
      backdrop: Color(0xFFF5F4F2),
      opacity: 1,
      user: Color(0x80212327),
      answer: Color(0xFF212327),
      tool: Color(0xFF5D6066),
      pill: Color(0xFFFFFFFF),
      dots: kioskSatelliteColors,
    ),
    dark: const SkinPalette(
      backdrop: Color(0xFF121316),
      opacity: 1,
      user: Color(0x80E8EAED),
      answer: Color(0xFFE8EAED),
      tool: Color(0xFFB6BABF),
      pill: Color(0xFF2A2B2F),
      dots: kioskSatelliteColors,
    ),
    bar: GradientBar(colors: _bands(kioskSatelliteColors), stops: _quarters),
    dots: DotsStyle.logoBars,
    toolMargin: 10,
  ),
  const AssistSkin(
    id: 'default',
    name: 'Default',
    light: SkinPalette(
      backdrop: Color(0xFFF5F4F2),
      opacity: 0.85,
      user: Color(0x80202124),
      answer: Color(0xFF121212),
      tool: Color(0xFF5F6368),
      pill: Color(0xFFFFFFFF),
      dots: [Color(0xFFFF0000), Color(0xFF00CC00), Color(0xFF0066FF)],
    ),
    dark: SkinPalette(
      backdrop: Color(0xFF121212),
      opacity: 0.85,
      user: Color(0x80E8EAED),
      answer: Color(0xFFE8EAED),
      tool: Color(0xFF9AA0A6),
      pill: Color(0xFF303134),
      dots: [Color(0xFFFF0000), Color(0xFF00CC00), Color(0xFF0066FF)],
    ),
    bar: GradientBar(
      colors: _defaultBar,
      glowColors: _defaultGlow,
      height: 8,
      glowStrip: 12,
    ),
  ),
  AssistSkin(
    id: 'google-home',
    name: 'Google Home',
    light: const SkinPalette(
      backdrop: Color(0xFFF5F4F2),
      opacity: 1,
      user: Color(0x80202124),
      answer: Color(0xFF202124),
      tool: Color(0xFF5F6368),
      pill: Color(0xFFFFFFFF),
      dots: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05)],
    ),
    dark: const SkinPalette(
      backdrop: Color(0xFF202124),
      opacity: 1,
      user: Color(0x80E8EAED),
      answer: Color(0xFFE8EAED),
      tool: Color(0xFF9AA0A6),
      pill: Color(0xFF303134),
      dots: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05)],
    ),
    bar: GradientBar(colors: _bands(_googleColors), stops: _quarters),
  ),
  AssistSkin(
    id: 'home-assistant',
    name: 'Home Assistant',
    // The backdrop is the card color at 85%.
    light: const SkinPalette(
      backdrop: Color(0xFFFFFFFF),
      opacity: 0.85,
      user: Color(0x8A000000),
      answer: Color(0xFF212121),
      tool: Color(0x8A000000),
      pill: Color(0xFFFFFFFF),
      dots: [Color(0xFF03A9F4), Color(0xFF03A9F4), Color(0xFF03A9F4)],
    ),
    dark: const SkinPalette(
      backdrop: Color(0xFF1C1C1C),
      opacity: 0.85,
      user: Color(0x8AFFFFFF),
      answer: Color(0xFFE1E1E1),
      tool: Color(0x8AFFFFFF),
      pill: Color(0xFF1C1C1C),
      dots: [Color(0xFF03A9F4), Color(0xFF03A9F4), Color(0xFF03A9F4)],
    ),
    bar: GradientBar(colors: _bands(_haColors), stops: _quarters),
    font: 'Roboto',
    blur: 8,
    gap: 12,
    userSize: 30,
    answerSize: 32,
    dotSize: 32,
    idleDotSize: 22,
    toolSize: 22,
  ),
  const AssistSkin(
    id: 'alexa',
    name: 'Alexa',
    light: SkinPalette(
      backdrop: Color(0xFF000814),
      opacity: 0.7,
      user: Color(0x8CFFFFFF),
      answer: Color(0xFFFFFFFF),
      tool: Color(0x73FFFFFF),
      pill: Color(0xFF0B1A33),
      dots: [Color(0xFF00CAFF), Color(0xFF00CAFF), Color(0xFF00CAFF)],
      userShadows: _alexaShadow,
      answerShadows: _alexaShadow,
      toolShadows: _alexaShadow,
    ),
    bar: AlexaStrip(),
    font: 'Roboto',
    chatBottom: 80,
    chatBottomReactive: 104,
    gap: 10,
    centered: true,
    fadeDy: 10,
    fadeMs: 350,
    userWeight: FontWeight.w300,
    answerWeight: FontWeight.w700,
    dotsGap: 8,
    toolWeight: FontWeight.w300,
  ),
  const AssistSkin(
    id: 'siri',
    name: 'Siri',
    light: SkinPalette(
      backdrop: Color(0xFF000000),
      opacity: 0.85,
      user: Color(0x80FFFFFF),
      answer: Color(0xFFFFFFFF),
      tool: Color(0x66FFFFFF),
      pill: Color(0x1AFFFFFF),
      dots: [Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFFEC4899)],
    ),
    bar: SiriFrame(),
    font: 'Inter',
    blur: 8,
    chatBottom: 60,
    chatBottomReactive: 100,
    chatTop: 60,
    gap: 12,
    centered: true,
    fadeMs: 350,
    userSize: 30,
    answerSize: 38,
    userWeight: FontWeight.w300,
    answerWeight: FontWeight.w500,
    dotSize: 38,
    dotsGap: 8,
    toolWeight: FontWeight.w300,
  ),
  const AssistSkin(
    id: 'retro-terminal',
    name: 'Retro Terminal',
    light: SkinPalette(
      backdrop: Color(0xFF000A00),
      opacity: 0.92,
      user: Color(0xFF1A8C1A),
      answer: Color(0xFF33FF33),
      tool: Color(0xFF1A8C1A),
      pill: Color(0xFF000000),
      dots: [Color(0xFF33FF33), Color(0xFF33FF33), Color(0xFF33FF33)],
      userShadows: _terminalShadow,
      answerShadows: _terminalShadow,
      toolShadows: _terminalShadow,
    ),
    bar: RetroFrame(),
    font: 'VT323',
    blur: 4,
    chatBottom: 100,
    chatBottomReactive: 100,
    chatTop: 72,
    gap: 10,
    msgMaxWidth: 0.9,
    fadeDy: 6,
    fadeMs: 250,
    userSize: 42,
    answerSize: 48,
    answerWeight: FontWeight.w700,
    dots: DotsStyle.blink,
    dotSize: 48,
    idleDotSize: 28,
    dotsGap: 4,
    dotGlow: CssShadow(Color(0x9933FF33), 10),
    toolSize: 28,
    toolMargin: 6,
    toolItalic: false,
    prefix: '> ',
    crt: true,
  ),
  const AssistSkin(
    id: 'waveform',
    name: 'Waveform',
    light: SkinPalette(
      backdrop: Color(0xFFF0F0F0),
      opacity: 1,
      user: Color(0x731A1A2E),
      answer: Color(0xFF1A1A2E),
      tool: Color(0xFF6E6E88),
      pill: Color(0xFFFFFFFF),
      dots: [Color(0xFF501EC8), Color(0xFF0064D2), Color(0xFF7828C8)],
    ),
    dark: SkinPalette(
      backdrop: Color(0xFF000000),
      opacity: 1,
      user: Color(0x80E4E4EC),
      answer: Color(0xFFE4E4EC),
      tool: Color(0xFF8888A0),
      pill: Color(0xFF1B1B22),
      dots: [Color(0xFF783CFF), Color(0xFF1EA0FF), Color(0xFFA050FF)],
    ),
    bar: NoBar(),
    dockedBar: GradientBar(
      colors: [Color(0xFF783CFF), Color(0xFF1EA0FF), Color(0xFFA050FF)],
    ),
    art: SkinArt.waveform,
    blur: 0,
    chatBottomReactive: 72,
    announcementTop: 0.72,
    idleDotSize: 22,
    toolSize: 22,
  ),
  const AssistSkin(
    id: 'lens-flares',
    name: 'Lens Flares',
    light: SkinPalette(
      backdrop: Color(0xFF000000),
      opacity: 1,
      user: Color(0xCCE6ECFF),
      answer: Color(0xFFE6ECFF),
      tool: Color(0xFFB8C4DC),
      pill: Color(0xFF0C1224),
      dots: [Color(0xFF50A0FF), Color(0xFFB4D4FF), Color(0xFFFF6480)],
      userShadows: _flareUserShadow,
      answerShadows: _flareAnswerShadow,
    ),
    bar: NoBar(),
    dockedBar: GradientBar(
      colors: [Color(0xFF50A0FF), Color(0xFFB4D4FF), Color(0xFFFF6480)],
    ),
    art: SkinArt.lensFlares,
    blur: 0,
    chatBottomReactive: 72,
    announcementTop: 0.72,
    idleDotSize: 22,
    toolSize: 22,
  ),
  const AssistSkin(
    id: 'ink-blobs',
    name: 'Ink Blobs',
    light: SkinPalette(
      backdrop: Color(0xFFF4F6FA),
      opacity: 1,
      user: Color(0x73161A26),
      answer: Color(0xFF161A26),
      tool: Color(0xFF5C6478),
      pill: Color(0xFFFFFFFF),
      dots: [Color(0xFFD90A0A), Color(0xFF0A24D9), Color(0xFF0A0D12)],
      userShadows: [CssShadow(Color(0x1A000000), 6, dy: 1)],
      answerShadows: [CssShadow(Color(0x1A000000), 8, dy: 1)],
    ),
    dark: SkinPalette(
      backdrop: Color(0xFF000000),
      opacity: 1,
      user: Color(0x80EEF0F6),
      answer: Color(0xFFEEF0F6),
      tool: Color(0xFF8A90A4),
      pill: Color(0xFF15171D),
      dots: [Color(0xFFFF1A1A), Color(0xFF1F66FF), Color(0xFFE0E6F0)],
      userShadows: [CssShadow(Color(0x66000000), 6, dy: 1)],
      answerShadows: [CssShadow(Color(0x66000000), 8, dy: 1)],
    ),
    bar: NoBar(),
    dockedBar: GradientBar(
      colors: [Color(0xFFFF1A1A), Color(0xFF1F66FF), Color(0xFFE0E6F0)],
    ),
    art: SkinArt.inkBlobs,
    blur: 0,
    chatBottomReactive: 72,
    announcementTop: 0.72,
    idleDotSize: 22,
    toolSize: 22,
  ),
  const AssistSkin(
    id: 'jarvis',
    name: 'Jarvis',
    light: SkinPalette(
      backdrop: Color(0xFF02090E),
      opacity: 1,
      user: Color(0xD98FE3EC),
      answer: Color(0xFFE6FCFF),
      tool: Color(0xFF7CCAD4),
      pill: Color(0xFF06222A),
      dots: [Color(0xFF4EE6F0), Color(0xFFA6F8FF), Color(0xFF1FB5C9)],
      userShadows: _jarvisShadow,
      answerShadows: _jarvisAnswerShadow,
      toolShadows: _jarvisShadow,
    ),
    bar: NoBar(),
    art: SkinArt.jarvis,
    font: 'Inter',
    blur: 0,
    centered: true,
    userWeight: FontWeight.w300,
    toolWeight: FontWeight.w300,
    announcementTop: 0.8,
    idleDotSize: 22,
    toolSize: 22,
  ),
  const AssistSkin(
    id: 'voice-only',
    name: 'Voice Only',
    light: SkinPalette(
      backdrop: Color(0xFFF5F4F2),
      opacity: 1,
      user: Color(0x80212327),
      answer: Color(0xFF212327),
      tool: Color(0xFF5D6066),
      pill: Color(0xFFFFFFFF),
      dots: kioskSatelliteColors,
    ),
    dark: SkinPalette(
      backdrop: Color(0xFF121316),
      opacity: 1,
      user: Color(0x80E8EAED),
      answer: Color(0xFFE8EAED),
      tool: Color(0xFFB6BABF),
      pill: Color(0xFF2A2B2F),
      dots: kioskSatelliteColors,
    ),
    bar: NoBar(),
    dots: DotsStyle.logoBars,
    voiceOnly: true,
  ),
];

AssistSkin assistSkinById(String id) =>
    assistSkins.firstWhere((s) => s.id == id, orElse: () => assistSkins.first);
