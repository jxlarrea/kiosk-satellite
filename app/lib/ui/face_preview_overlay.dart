import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../managers/motion/motion_manager.dart';
import '../managers/motion/native_motion.dart';
import '../managers/settings/definitions.dart' as defs;
import '../managers/settings/settings_manager.dart';
import 'theme.dart';

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
  });

  final MotionManager motion;
  final SettingsManager settings;

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
    _onFrame();
  }

  @override
  void dispose() {
    widget.motion.facePreview.removeListener(_onFrame);
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
    final corner = _cornerAlignment(settings.get(defs.facePreviewPosition));
    final turned = _rotation % 180 != 0;
    final width = (turned ? image.height : image.width).toDouble();
    final height = (turned ? image.width : image.height).toDouble();
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
                child: Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: FacePreviewOverlay.rimColor,
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
              ),
            ),
          ),
        ),
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
