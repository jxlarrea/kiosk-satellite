import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../managers/ground_control/recognition_cards.dart';
import '../managers/motion/motion_manager.dart';
import '../managers/motion/native_motion.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';
import 'recognition_card_overlay.dart' show recognitionSubtitle;
import 'theme.dart';
import 'voice_match_enroll_overlay.dart' show personColor;

/// The camera preview (discussion #371): a small round live view of the
/// camera in a corner of the screen for a few seconds after a face woke
/// the kiosk, white-rimmed, over whatever the dashboard shows.
///
/// Draws the frames MotionManager.facePreview hands over (JPEGs of the
/// analysis stream, in sensor orientation) turned upright and, for a
/// front camera, mirrored, so the person in it sees themselves the way a
/// mirror shows them. It answers no touch: it is a glimpse, not a
/// control, and a tap on the dashboard under it must land there. It
/// grows in as the first frame lands and shrinks away when the manager
/// clears the frame, keeping the last picture until the fade is done.
class FacePreviewOverlay extends StatefulWidget {
  const FacePreviewOverlay({
    super.key,
    required this.motion,
    required this.settings,
    this.cards,
    this.pictureOf,
  });

  final MotionManager motion;
  final SettingsManager settings;

  /// The recognition card showing now, drawn beside the preview while it
  /// shows (an action on it in place of Recognized).
  final RecognitionCards? cards;

  /// The recognized person's Home Assistant picture, by Ground Control
  /// person id, for the name card ([GroundControlManager.pictureOf]).
  final Future<String?> Function(String personId)? pictureOf;

  /// The circle's diameter at 100% scaling.
  static const double baseDiameter = 180;

  /// The white rim: its width, and its white, taken a touch down from
  /// pure so it does not glare over a dark dashboard.
  static const double rim = 3;
  static const Color rimColor = Color(0xFFD9D9D9);

  @override
  State<FacePreviewOverlay> createState() => _FacePreviewOverlayState();
}

class _FacePreviewOverlayState extends State<FacePreviewOverlay> {
  ui.Image? _image;
  int _rotation = 0;
  bool _mirror = false;

  /// Whether a preview is up. False keeps [_image] through the fade-out,
  /// then drops it.
  bool _shown = false;

  /// Decodes in flight are ordered; a slow one finishing after a newer
  /// frame is thrown away rather than drawn.
  int _decodeSeq = 0;

  @override
  void initState() {
    super.initState();
    widget.motion.facePreview.addListener(_onFrame);
    widget.motion.atKiosk.addListener(_onPerson);
    widget.cards?.card.addListener(_onPerson);
    _onFrame();
    _onPerson();
  }

  @override
  void dispose() {
    widget.motion.facePreview.removeListener(_onFrame);
    widget.motion.atKiosk.removeListener(_onPerson);
    widget.cards?.card.removeListener(_onPerson);
    _decodeSeq++;
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  void _onFrame() {
    final frame = widget.motion.facePreview.value;
    if (frame == null) {
      _decodeSeq++;
      if (_shown && mounted) setState(() => _shown = false);
      return;
    }
    unawaited(_decode(frame, ++_decodeSeq));
  }

  Future<void> _decode(FacePreviewFrame frame, int seq) async {
    ui.Image image;
    try {
      final codec = await ui.instantiateImageCodec(frame.jpeg);
      final info = await codec.getNextFrame();
      codec.dispose();
      image = info.image;
    } catch (_) {
      // A frame the decoder rejects is a skipped frame.
      return;
    }
    if (!mounted || seq != _decodeSeq) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
      _rotation = frame.rotation;
      _mirror = frame.mirror;
      _shown = true;
    });
  }

  /// Who the card beside the preview names: the recognition card showing
  /// now, else the person at the kiosk with Show arrivals on. Kept through
  /// the card's fade-out so its name doesn't blank while it goes.
  RecognitionCard? _person;
  bool _named = false;
  String? _picture;

  RecognitionCard? _who() {
    final card = widget.cards?.card.value;
    if (card != null) return card;
    final settings = widget.settings;
    final at = widget.motion.atKiosk.value;
    final id = at?.id;
    if (id == null ||
        !settings.visible(defs.visionMatchShowArrivals) ||
        !settings.get(defs.visionMatchShowArrivals)) {
      return null;
    }
    return RecognitionCard(id: id, name: at!.name, color: at.color);
  }

  void _onPerson() {
    final person = _who();
    if (!mounted) return;
    final changed = person != null && person.id != _person?.id;
    setState(() {
      if (person != null) _person = person;
      if (changed) _picture = null;
      _named = person != null;
    });
    final id = person?.id;
    final look = widget.pictureOf;
    if (changed && id != null && look != null) {
      unawaited(
        look(id).then((url) {
          if (mounted && _person?.id == id) setState(() => _picture = url);
        }),
      );
    }
  }

  void _faded() {
    if (_shown || !mounted) return;
    setState(() {
      _image?.dispose();
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) return const SizedBox.shrink();
    final settings = widget.settings;
    final scale = settings.get(defs.facePreviewScale).toDouble() / 100;
    final diameter = FacePreviewOverlay.baseDiameter * scale;
    final cornerKey = settings.get(defs.facePreviewPosition);
    final corner = _cornerAlignment(cornerKey);
    final turned = _rotation % 180 != 0;
    final width = (turned ? image.height : image.width).toDouble();
    final height = (turned ? image.width : image.height).toDouble();
    // Who is recognized: a ring in their color around the preview and their
    // card sliding out from behind it, toward the middle of the screen.
    final named = _named && _shown;
    final person = _person;
    final color = personColor(
      person?.color,
      Theme.of(context).colorScheme.primary,
    );
    final ring = 5.0 * scale;
    final gap = 4.0 * scale;
    final box = diameter + 2 * (ring + gap);
    final left = cornerKey == 'top_left' || cornerKey == 'bottom_left';
    final preview = SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: named ? 1 : 0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            builder: (context, sweep, _) => CustomPaint(
              size: Size.square(box),
              painter: _RingPainter(sweep: sweep, color: color, width: ring),
            ),
          ),
          TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: named ? color : FacePreviewOverlay.rimColor),
            duration: const Duration(milliseconds: 400),
            builder: (context, rim, child) => Container(
              width: diameter,
              height: diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(
                  color: rim ?? FacePreviewOverlay.rimColor,
                  width: FacePreviewOverlay.rim,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
            child: ClipOval(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Transform.flip(
                    flipX: _mirror,
                    child: RotatedBox(
                      quarterTurns: (_rotation ~/ 90) % 4,
                      child: RawImage(
                        image: image,
                        width: image.width.toDouble(),
                        height: image.height.toDouble(),
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final cardHeight = 76.0 * scale;
    final card = person == null
        ? null
        : Positioned(
            top: (box - cardHeight) / 2,
            right: left ? null : box / 2,
            left: left ? box / 2 : null,
            child: AnimatedSlide(
              offset: named ? Offset.zero : Offset(left ? -0.25 : 0.25, 0),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: named ? 1 : 0,
                duration: Duration(milliseconds: named ? 260 : 180),
                child: _NameCard(
                  name: person.name,
                  action: person.action,
                  picture: _picture,
                  token: settings.get(defs.haToken),
                  color: color,
                  height: cardHeight,
                  clear: box / 2 + 12 * scale,
                  left: left,
                  scale: scale,
                ),
              ),
            ),
          );
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Ks.inset),
          child: Align(
            alignment: corner,
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              onEnd: _faded,
              child: AnimatedScale(
                scale: _shown ? 1 : 0.8,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: box,
                  height: box,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [?card, preview],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ring around the preview in the recognized person's color, drawn
/// clockwise from the top as [sweep] goes from 0 to 1.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.sweep,
    required this.color,
    required this.width,
  });

  final double sweep;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep <= 0) return;
    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(width / 2),
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.sweep != sweep || old.color != color || old.width != width;
}

/// The recognized person's name beside the preview: their color and
/// initial, the name and "Recognized". It sits behind the preview, so
/// [clear] keeps its text out from under the circle.
class _NameCard extends StatelessWidget {
  const _NameCard({
    required this.name,
    required this.action,
    required this.picture,
    required this.token,
    required this.color,
    required this.height,
    required this.clear,
    required this.left,
    required this.scale,
  });

  final String name;

  /// What a face made happen while the card is up, shown in place of
  /// Recognized.
  final FaceAction? action;

  /// The person's Home Assistant picture, drawn inside a ring of their
  /// color in place of the initial. Null for none.
  final String? picture;
  final String token;
  final Color color;
  final double height;
  final double clear;
  final bool left;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final disc = 48.0 * scale;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: left
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 260 * scale),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23 * scale,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ),
        recognitionSubtitle(context, action, 13.5 * scale),
      ],
    );
    final letter = Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: 21 * scale,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final url = picture;
    final dot = Container(
      width: disc,
      height: disc,
      padding: url == null ? null : EdgeInsets.all(2.5 * scale),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: url == null
          ? letter
          : ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                headers: {'Authorization': 'Bearer $token'},
                errorBuilder: (_, _, _) => letter,
              ),
            ),
    );
    final gap = SizedBox(width: 14 * scale);
    return Container(
      height: height,
      padding: EdgeInsets.only(
        left: left ? clear : 14 * scale,
        right: left ? 14 * scale : clear,
      ),
      decoration: BoxDecoration(
        color: const Color(0xF0242529),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: const Color(0x14FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: left ? [text, gap, dot] : [dot, gap, text],
      ),
    );
  }
}

/// The same vocabulary as the screensaver's corner overlays, so
/// "top_left" is the same place to both.
Alignment _cornerAlignment(String corner) => switch (corner) {
  'top_left' => Alignment.topLeft,
  'bottom_left' => Alignment.bottomLeft,
  'bottom_right' => Alignment.bottomRight,
  _ => Alignment.topRight,
};
