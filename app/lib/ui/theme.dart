import 'package:flutter/material.dart';

/// Kiosk Satellite visual identity: modern flat, light + dark, built from the
/// shared brand palette (the remote admin UI's CSS carries the same values —
/// see assets/remote-ui/static/app.css):
///
///   teal        #5DA3A6  primary (the mark's keyline)
///   teal        #558387  secondary accent
///   sage green  #749C6F  success
///   ochre       #CE9C3E  warning / tertiary
///   rust        #C7642A  error / danger
///   light bg    #F5F4F2  warm paper
///   dark bg     #202124  charcoal
///
/// The exact palette values are used on the dark background, where they have
/// comfortable contrast. On the light background each accent is darkened just
/// enough to stay legible as text — same hue, deeper tone.
const _teal = Color(0xFF5DA3A6);

/// The brand sage: no longer the primary, but still the green of the settings
/// rail's accent cycle and of success states (the remote admin's --ok).
/// Exact value on dark, darkened a step for light surfaces.
const ksSage = Color(0xFF749C6F);
const ksSageOnLight = Color(0xFF56814F);
const _lightBg = Color(0xFFF5F4F2);
const _darkBg = Color(0xFF202124);

/// The shared spacing and shape scale. Every screen draws from these instead
/// of inventing its own values; if a number is not on this scale it should
/// not appear in layout code.
abstract final class Ks {
  /// Outer padding of every settings/content page.
  static const pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 24);

  /// The one left inset shared by everything that sits in a card column:
  /// section headings, row content, dividers, hint rows, group notes.
  static const double inset = 20;

  /// Vertical gap between a card and the next section heading.
  static const double cardGap = 16;

  /// Cards, dialogs and other primary surfaces.
  static const double radiusCard = 24;

  /// Row ink splashes and small tappable surfaces inside a card.
  static const double radiusRow = 14;

  /// Text fields and other input controls.
  static const double radiusControl = 12;

  /// The one typeface for every piece of app text: page titles, dialog
  /// titles, list rows, buttons, body copy and the clock faces alike. Bundled
  /// in the APK, so it renders the same on every device.
  static const String displayFont = 'Rubik';

  /// Height of the fade-out an [EdgeFade] paints over a scroll edge that
  /// still hides content. The remote admin's --fade-size matches.
  static const double fadeEdge = 28;
}

ColorScheme _lightScheme() =>
    ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF488284), // teal, darkened for light surfaces
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD4E3E4),
      onPrimaryContainer: const Color(0xFF1B3437),
      secondary: const Color(0xFF44686C), // teal, darkened
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD4E3E4),
      onSecondaryContainer: const Color(0xFF1B3437),
      tertiary: const Color(0xFF9C742A), // ochre, darkened
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFF1E0BB),
      onTertiaryContainer: const Color(0xFF3D2D06),
      error: const Color(0xFFA9501F), // rust, darkened
      onError: Colors.white,
      errorContainer: const Color(0xFFF6DBCB),
      onErrorContainer: const Color(0xFF54250A),
      surface: _lightBg,
      onSurface: const Color(0xFF212327),
      onSurfaceVariant: const Color(0xFF5D6066),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFBFAF9),
      surfaceContainer: Colors.white,
      surfaceContainerHigh: const Color(0xFFEFEDE9),
      surfaceContainerHighest: const Color(0xFFE8E6E1),
      outline: const Color(0xFFB4B1AB),
      outlineVariant: const Color(0xFFE3E0DA),
    );

ColorScheme _darkScheme() =>
    ColorScheme.fromSeed(
      seedColor: _teal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _teal, // exact brand values carry the dark theme
      // Dark ink, not white: the keyline teal is too light to carry white
      // text, and it is how the palette already inks teal fills in the dark
      // (onSecondary).
      onPrimary: const Color(0xFF102A2C),
      primaryContainer: const Color(0xFF2F4649),
      onPrimaryContainer: const Color(0xFFD0E3E5),
      secondary: const Color(0xFF6C9B9F), // teal, lifted a step for text
      onSecondary: const Color(0xFF102A2C),
      secondaryContainer: const Color(0xFF2F4649),
      onSecondaryContainer: const Color(0xFFD0E3E5),
      tertiary: const Color(0xFFCE9C3E),
      onTertiary: const Color(0xFF261C04),
      tertiaryContainer: const Color(0xFF4A3A12),
      onTertiaryContainer: const Color(0xFFEFDFB5),
      error: const Color(0xFFD97E4C), // rust, lifted for dark surfaces
      onError: const Color(0xFF2E1204),
      errorContainer: const Color(0xFF5A2A0E),
      onErrorContainer: const Color(0xFFF4D7C5),
      surface: _darkBg,
      onSurface: const Color(0xFFE8EAED),
      onSurfaceVariant: const Color(0xFFB6BABF),
      surfaceContainerLowest: const Color(0xFF1A1B1E),
      surfaceContainerLow: const Color(0xFF26272B),
      surfaceContainer: const Color(0xFF2A2B2F),
      surfaceContainerHigh: const Color(0xFF303136),
      surfaceContainerHighest: const Color(0xFF37383D),
      outline: const Color(0xFF5F6368),
      outlineVariant: const Color(0xFF3C3E43),
    );

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = dark ? _darkScheme() : _lightScheme();
  // Pill-shaped, compact One UI buttons. Filled carries the affirmative
  // action, text the quiet one; both share the same metrics so dialog action
  // rows line up.
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(100),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  const buttonText = TextStyle(
    fontFamily: Ks.displayFont,
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
  );
  // A shared floor keeps dialog action pairs balanced: "Save" never renders
  // visibly narrower than the "Cancel" beside it.
  const buttonMinSize = Size(96, 44);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    // Every text theme style inherits Rubik. Theme-level TextStyles below
    // that replace the text theme rather than merge with it (list rows,
    // buttons) name the family explicitly so nothing falls back to Roboto.
    fontFamily: Ks.displayFont,
    scaffoldBackgroundColor: scheme.surface,
    // Flat: nothing floats, nothing tints on scroll. Depth comes from surface
    // tone and hairline outlines, not shadows.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      // The title sits right after the back arrow, as it does in the wide
      // settings pane, instead of Material's 16 further along: every bar
      // here is a pushed page with a leading arrow, and on a phone the
      // default gap read as a hole between the arrow and the page glyph.
      titleSpacing: 0,
      // One UI-weight headers: bold titles carry the hierarchy.
      titleTextStyle: TextStyle(
        fontFamily: Ks.displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    // Borderless rounded section masks, One UI style: cards read as soft
    // panels lifted from the background by tone alone.
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: Ks.cardGap),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ks.radiusCard),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Ks.radiusCard),
      ),
      titleTextStyle: TextStyle(
        fontFamily: Ks.displayFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    // One UI list rhythm: taller rows, a readable medium-weight title over a
    // clearly quieter subtitle. The weight gap is what makes rows scannable.
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Ks.inset,
        vertical: 4,
      ),
      titleTextStyle: TextStyle(
        fontFamily: Ks.displayFont,
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: Ks.displayFont,
        fontSize: 13,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surfaceContainerHigh : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ks.radiusControl),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ks.radiusControl),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ks.radiusControl),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: buttonText,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    ),
  );
}
