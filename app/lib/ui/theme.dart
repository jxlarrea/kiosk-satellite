import 'package:flutter/material.dart';

/// Kiosk Satellite visual identity: modern flat, light + dark, built from the
/// shared brand palette (the remote admin UI's CSS carries the same values —
/// see assets/remote-ui/index.html):
///
///   sage green  #749C6F  primary / success
///   teal        #558387  secondary accent
///   ochre       #CE9C3E  warning / tertiary
///   rust        #C7642A  error / danger
///   light bg    #F5F4F2  warm paper
///   dark bg     #202124  charcoal
///
/// The exact palette values are used on the dark background, where they have
/// comfortable contrast. On the light background each accent is darkened just
/// enough to stay legible as text — same hue, deeper tone.
const _sage = Color(0xFF749C6F);
const _lightBg = Color(0xFFF5F4F2);
const _darkBg = Color(0xFF202124);

ColorScheme _lightScheme() =>
    ColorScheme.fromSeed(
      seedColor: _sage,
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF56814F), // sage, darkened for light surfaces
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDCE7D8),
      onPrimaryContainer: const Color(0xFF243B20),
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
      seedColor: _sage,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _sage, // exact brand values carry the dark theme
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF3A4A37),
      onPrimaryContainer: const Color(0xFFD9E6D5),
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
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    // Flat: nothing floats, nothing tints on scroll. Depth comes from surface
    // tone and hairline outlines, not shadows.
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      // One UI-weight headers: bold titles carry the hierarchy.
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    // One UI list rhythm: taller rows, a readable medium-weight title over a
    // clearly quieter subtitle. The weight gap is what makes rows scannable.
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: scheme.onSurface,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13.5,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surfaceContainerHigh : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
