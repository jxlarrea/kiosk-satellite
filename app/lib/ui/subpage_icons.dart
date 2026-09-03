import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../managers/settings/definitions.dart' show subpageHints;

/// The glyph each second-level settings page wears: on its entry row, where
/// it sits ahead of the name, and again in the page's own title. Keyed by
/// [subpageHints]' names; the remote admin draws the same glyphs from its
/// icons module, so a page reads alike on both surfaces.
///
/// A Material [IconData], or the path of an SVG asset for a page named
/// after a product with a mark of its own (the shape the category rail
/// uses). Bare outlined glyphs, no disc: the rail already spends the
/// colored discs on the first level, and a second level that repeated them
/// would flatten the hierarchy.
const Map<String, Object> subpageIcons = {
  // Home Assistant.
  'User Interface': Icons.dashboard_customize_outlined,
  'Theme': Icons.palette_outlined,
  'Dashboard View Rotation': Icons.autorenew,
  'Return to home dashboard view': Icons.home_outlined,
  'Hold mode': Icons.push_pin_outlined,
  'Optimizations': Icons.speed_outlined,
  // Voice Satellite.
  'Wake Word': Icons.hearing_outlined,
  'Appearance': Icons.brush_outlined,
  // Screen & Audio.
  'Microphone settings': Icons.mic_none_outlined,
  'Adaptive brightness': Icons.brightness_auto_outlined,
  // Screensaver.
  'Clock screensaver': Icons.schedule_outlined,
  'Home Assistant Media screensaver': Icons.play_circle_outline,
  'Local Media screensaver': Icons.folder_outlined,
  'Photo Gallery screensaver': Icons.photo_library_outlined,
  // The one page named after a product: it wears the Immich mark, drawn
  // in the glyph color like the product marks in the rail.
  'Immich Media screensaver': 'assets/svg/immich.svg',
  'Camera Streams screensaver': Icons.videocam_outlined,
  'Widgets': Icons.widgets_outlined,
  'At a Glance': Icons.visibility_outlined,
  'Motion Detection': Icons.directions_walk,
  'Face Detection': Icons.face_outlined,
  'Proximity Detection': Icons.sensors,
  'Person Detection': Icons.sensor_occupied_outlined,
  'Scheduled Screensavers': Icons.calendar_today_outlined,
  // Media Player. Music Assistant is the one page named after a product
  // here; it wears the mark the category rail used to.
  'Sendspin Player': 'assets/svg/sendspin.svg',
  'Music Assistant': 'assets/svg/music-assistant.svg',
  'Sonos': Icons.speaker_outlined,
  'Floating Player': Icons.picture_in_picture_alt_outlined,
  'Now Playing': Icons.fullscreen,
  // ESPHome.
  'Notifications': Icons.notifications_outlined,
  'Bluetooth Proxy': Icons.bluetooth,
  'GPS Sensor': Icons.location_on_outlined,
  'Advanced settings': Icons.tune_outlined,
  // Kiosk.
  'Allowed Actions': Icons.checklist,
  // Device.
  'Kiosk Satellite Service': Icons.bolt_outlined,
  'Remote Administration': Icons.computer_outlined,
};

/// The names in [subpageHints] the device never draws: read-only reports
/// the remote admin shows about the tablet. They have glyphs on that side
/// only, and the coverage test skips them here.
const Set<String> remoteOnlySubpages = {
  'Hardware',
  'Home Assistant',
  'WebView',
};

/// The glyph for [subpage], or a neutral one for a page the map has not met,
/// so a new page still draws a row rather than throwing.
Object subpageIcon(String subpage) =>
    subpageIcons[subpage] ?? Icons.article_outlined;

/// [subpageIcon] drawn: an [Icon] for Material glyphs, and for an SVG mark
/// a picture in the ambient icon color, so it takes the same ink as the
/// glyph beside it wherever it sits (a ListTile's leading slot, an app bar,
/// the wide pane's title row).
class SubpageGlyph extends StatelessWidget {
  const SubpageGlyph(this.subpage, {super.key, this.size});

  final String subpage;

  /// Defaults to the ambient icon size, like [Icon].
  final double? size;

  @override
  Widget build(BuildContext context) {
    final icon = subpageIcon(subpage);
    if (icon is IconData) return Icon(icon, size: size);
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    return SvgPicture.asset(
      icon as String,
      width: side,
      height: side,
      colorFilter: ColorFilter.mode(
        theme.color ?? Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }
}
