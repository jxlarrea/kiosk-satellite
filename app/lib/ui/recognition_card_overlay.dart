import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/messages.dart';
import '../managers/ground_control/recognition_cards.dart';
import '../managers/motion/motion_manager.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';
import 'ground_control_tag.dart' show faceRecognitionIconPath;
import 'theme.dart';
import 'voice_match_enroll_overlay.dart' show personColor;

/// What happened, in two or three words, for the action card.
String faceActionText(BuildContext context, FaceAction action) {
  final t = l10n(context);
  return switch (action) {
    FaceAction.pinSkipped => t.recognitionCardPinSkipped,
    FaceAction.lockdownOff => t.recognitionCardLockdownOff,
    FaceAction.voiceConfirmed => t.recognitionCardVoiceConfirmed,
    FaceAction.calendarFocused => t.recognitionCardCalendarFocused,
  };
}

/// The Face Recognition icon, in [color].
Widget faceRecognitionIcon(double size, Color color) => SvgPicture.string(
  '<svg viewBox="0 0 24 24"><path d="$faceRecognitionIconPath"/></svg>',
  width: size,
  height: size,
  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
);

/// Looks up and keeps the Home Assistant pictures of the people on the
/// cards, by Ground Control person id.
class RecognitionPictures {
  RecognitionPictures(this.pictureOf);

  final Future<String?> Function(String personId)? pictureOf;
  final _urls = <String, String?>{};

  String? cached(String id) => _urls[id];

  /// The picture of [id], calling [done] once it is known the first time.
  void load(String id, VoidCallback done) {
    final look = pictureOf;
    if (look == null || _urls.containsKey(id)) return;
    _urls[id] = null;
    unawaited(
      look(id).then((url) {
        _urls[id] = url;
        if (url != null) done();
      }),
    );
  }
}

/// The person's Home Assistant picture inside a ring of their color, or
/// their initial on their color without one. [sweep] draws the ring from
/// the top, 0 to 1.
class PersonDisc extends StatelessWidget {
  const PersonDisc({
    super.key,
    required this.name,
    required this.color,
    required this.size,
    required this.ring,
    this.picture,
    this.token = '',
    this.sweep = 1,
  });

  final String name;
  final Color color;
  final double size;
  final double ring;
  final String? picture;
  final String token;
  final double sweep;

  @override
  Widget build(BuildContext context) {
    final inner = size - 2 * (ring + ring / 2);
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final letter = Container(
      width: inner,
      height: inner,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: inner * 0.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final url = picture;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _Ring(sweep: sweep, color: color, width: ring),
          ),
          SizedBox(
            width: inner,
            height: inner,
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
          ),
        ],
      ),
    );
  }
}

class _Ring extends CustomPainter {
  const _Ring({required this.sweep, required this.color, required this.width});

  final double sweep;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep <= 0) return;
    canvas.drawArc(
      (Offset.zero & size).deflate(width / 2),
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
  bool shouldRepaint(_Ring old) =>
      old.sweep != sweep || old.color != color || old.width != width;
}

/// Under the name on the arrival card: Recognized, or the Face Recognition
/// icon and the action that came while the card is up.
Widget recognitionSubtitle(
  BuildContext context,
  FaceAction? action,
  double fontSize,
) {
  if (action == null) {
    return Text(
      l10n(context).facePreviewRecognized,
      style: TextStyle(color: const Color(0xFFB6BABF), fontSize: fontSize),
    );
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      faceRecognitionIcon(fontSize, const Color(0xFFB6BABF)),
      SizedBox(width: fontSize * 0.45),
      Text(
        faceActionText(context, action),
        style: TextStyle(color: const Color(0xFFE8EAED), fontSize: fontSize),
      ),
    ],
  );
}

/// Vision Match > Recognition cards on screen, over everything: the
/// arrival card and the action card in their corner
/// ([defs.visionMatchCardPosition]). While the camera preview shows, the
/// preview draws the card beside itself instead and this one steps aside.
/// It answers no touch.
class RecognitionCardOverlay extends StatefulWidget {
  const RecognitionCardOverlay({
    super.key,
    required this.cards,
    required this.motion,
    required this.settings,
    this.pictureOf,
  });

  final RecognitionCards cards;
  final MotionManager motion;
  final SettingsManager settings;
  final Future<String?> Function(String personId)? pictureOf;

  @override
  State<RecognitionCardOverlay> createState() => _RecognitionCardOverlayState();
}

class _RecognitionCardOverlayState extends State<RecognitionCardOverlay> {
  late final _pictures = RecognitionPictures(widget.pictureOf);

  /// The last card, kept through the fade-out.
  RecognitionCard? _card;

  @override
  void initState() {
    super.initState();
    widget.cards.card.addListener(_changed);
    widget.motion.facePreview.addListener(_changed);
    _changed();
  }

  @override
  void dispose() {
    widget.cards.card.removeListener(_changed);
    widget.motion.facePreview.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final card = widget.cards.card.value;
    if (card != null) {
      _pictures.load(card.id, () {
        if (mounted) setState(() {});
      });
    }
    if (mounted) setState(() => _card = card ?? _card);
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    if (card == null) return const SizedBox.shrink();
    final shown =
        widget.cards.card.value != null &&
        widget.motion.facePreview.value == null;
    final corner = widget.settings.get(defs.visionMatchCardPosition);
    final top = corner.startsWith('top');
    final left = corner.endsWith('left');
    final color = personColor(
      card.color,
      Theme.of(context).colorScheme.primary,
    );
    final token = widget.settings.get(defs.haToken);
    final picture = _pictures.cached(card.id);
    final body = card.arrival || card.action == null
        ? _ArrivalCard(
            key: ValueKey('arrival:${card.id}'),
            card: card,
            color: color,
            picture: picture,
            token: token,
            shown: shown,
          )
        : _ActionCard(
            key: ValueKey('action:${card.id}'),
            card: card,
            color: color,
            picture: picture,
            token: token,
          );
    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Ks.inset),
          child: Align(
            alignment: Alignment(left ? -1 : 1, top ? -1 : 1),
            child: AnimatedSlide(
              offset: shown ? Offset.zero : Offset(0, top ? -0.3 : 0.3),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: shown ? 1 : 0,
                duration: Duration(milliseconds: shown ? 260 : 200),
                child: Semantics(
                  liveRegion: true,
                  label: card.action == null
                      ? '${card.name}, ${l10n(context).facePreviewRecognized}'
                      : '${card.name}, ${faceActionText(context, card.action!)}',
                  excludeSemantics: true,
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The large card: picture in a ring of the person's color, their name and
/// Recognized, or the action that came while it is up.
class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({
    super.key,
    required this.card,
    required this.color,
    required this.picture,
    required this.token,
    required this.shown,
  });

  final RecognitionCard card;
  final Color color;
  final String? picture;
  final String token;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(10, 0, 28, 0),
      decoration: BoxDecoration(
        color: const Color(0xF2242529),
        borderRadius: BorderRadius.circular(42),
        border: Border.all(color: const Color(0x14FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: shown ? 1 : 0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
            builder: (context, sweep, _) => PersonDisc(
              name: card.name,
              color: color,
              size: 64,
              ring: 4,
              picture: picture,
              token: token,
              sweep: sweep,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  card.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              recognitionSubtitle(context, card.action, 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// The small card for an action on its own: the person's picture, the Face
/// Recognition icon and what happened.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.card,
    required this.color,
    required this.picture,
    required this.token,
  });

  final RecognitionCard card;
  final Color color;
  final String? picture;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.fromLTRB(4, 0, 14, 0),
      decoration: BoxDecoration(
        color: const Color(0xE0242529),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x12FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonDisc(
            name: card.name,
            color: color,
            size: 32,
            ring: 1.5,
            picture: picture,
            token: token,
          ),
          const SizedBox(width: 9),
          faceRecognitionIcon(15, const Color(0xFF9AA0A6)),
          const SizedBox(width: 6),
          Text(
            faceActionText(context, card.action!),
            style: const TextStyle(
              color: Color(0xFFE8EAED),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
