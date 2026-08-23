import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Material Design Icons by name, the way Home Assistant names them.
///
/// Home Assistant's own icons are MDI, so anything a user types into an
/// automation or an entity's icon field ("mdi:washing-machine") has to
/// resolve here or the app is guessing at lookalikes. The whole set is
/// bundled as path data under assets/mdi, one file per first letter (see
/// tool/generate_mdi.py); a shard is read when an icon from that letter
/// is first asked for and thrown away again, leaving only the handful of
/// resolved paths a kiosk actually draws.
///
/// Paths rather than an icon font on purpose: the font would be a second
/// megabyte-plus asset AND it would cost the app its icon tree shaking,
/// because looking an icon up by name means a non-const IconData, and
/// that turns the Material font from 25KB into the whole 1.6MB of it.
/// Paths draw through flutter_svg, which is already here for the app's
/// own artwork, and scale to any size (a notification can ask to be drawn
/// four times over).
abstract final class MdiIcons {
  /// Where a shard is read from. Swapped in tests, which cannot wait on
  /// the asset channel from outside a pumping widget test.
  @visibleForTesting
  static Future<String> Function(String assetKey) readShard = (key) =>
      rootBundle.loadString(key, cache: false);

  /// Resolved name to path. Small: only what has actually been drawn.
  static final _resolved = <String, String?>{};

  /// In-flight lookups, so a stack of cards asking for the same icon at
  /// once reads the shard once.
  static final _pending = <String, Future<String?>>{};

  /// Whether [name] looks like an icon name this can resolve. Accepts the
  /// Home Assistant spelling with or without the prefix.
  static bool looksLikeIcon(String name) {
    final trimmed = normalize(name);
    return trimmed.isNotEmpty &&
        RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(trimmed);
  }

  /// The bare icon name: "mdi:washing-machine" and "Washing-Machine" both
  /// become "washing-machine".
  static String normalize(String name) {
    var value = name.trim().toLowerCase();
    if (value.startsWith('mdi:')) value = value.substring(4);
    return value;
  }

  /// The SVG path for [name] on a 24 by 24 grid, or null when no such
  /// icon exists. Cached after the first call.
  static Future<String?> path(String name) {
    final key = normalize(name);
    if (_resolved.containsKey(key)) return Future.value(_resolved[key]);
    // The braces matter: whenComplete waits on whatever its callback
    // returns, and Map.remove hands back the very future being awaited,
    // which is a future waiting on itself.
    return _pending[key] ??= _load(key).whenComplete(() {
      _pending.remove(key);
    });
  }

  static Future<String?> _load(String key, {bool followAlias = true}) async {
    if (!looksLikeIcon(key)) return _remember(key, null);
    final letter = key.codeUnitAt(0) >= 0x61 && key.codeUnitAt(0) <= 0x7a
        ? key[0]
        : '_';
    Map<String, dynamic> shard;
    try {
      // The read is uncached because the shard is up to half a megabyte
      // of JSON and this is the only look at it; the resolved paths below
      // are the part worth keeping.
      final raw = await readShard('assets/mdi/$letter.json');
      shard = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return _remember(key, null);
    }
    final value = shard[key] as String?;
    if (value == null) return _remember(key, null);
    // Renamed icons point at their current name rather than carrying a
    // second copy of the path, and the target can be under any letter.
    if (value.startsWith('@')) {
      if (!followAlias) return _remember(key, null);
      final target = await _load(value.substring(1), followAlias: false);
      return _remember(key, target);
    }
    return _remember(key, value);
  }

  static String? _remember(String key, String? path) {
    _resolved[key] = path;
    return path;
  }
}

/// Draws a Material Design Icon by name, falling back to [fallback] while
/// the path is being read and when the name is not an icon at all.
class MdiIcon extends StatefulWidget {
  const MdiIcon({
    required this.name,
    required this.size,
    required this.color,
    required this.fallback,
    super.key,
  });

  final String name;
  final double size;
  final Color color;

  /// What to draw instead: an unknown name must still leave something in
  /// the circle, and the kind icon is the honest answer.
  final IconData fallback;

  @override
  State<MdiIcon> createState() => _MdiIconState();
}

class _MdiIconState extends State<MdiIcon> {
  String? _path;
  bool _looked = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(MdiIcon old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name) {
      _looked = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final name = widget.name;
    final path = await MdiIcons.path(name);
    if (!mounted || widget.name != name) return;
    setState(() {
      _path = path;
      _looked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    if (!_looked || path == null) {
      return Icon(widget.fallback, size: widget.size, color: widget.color);
    }
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$path"/></svg>',
      width: widget.size,
      height: widget.size,
      colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
    );
  }
}
