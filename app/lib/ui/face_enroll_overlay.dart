import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../l10n/messages.dart';
import '../managers/ground_control/face_enroll.dart';
import 'voice_match_enroll_overlay.dart' show personColor;

/// Face Recognition's guided capture on this kiosk: the camera's view in a
/// progress ring, the step to do and what to fix, full screen while it runs,
/// then a card over the dashboard with the result, which goes on its own.
///
/// The steps come from Ground Control, which checks every frame: look at
/// the screen, turn a little to one side, then the other, then step back.
class FaceEnrollOverlay extends StatelessWidget {
  const FaceEnrollOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FaceEnrollState?>(
        valueListenable: container.motion.faceEnrollment,
        builder: (context, state, _) {
          if (state == null) return const SizedBox.shrink();
          if (state.active) {
            return Positioned.fill(
              child: _Capture(container: container, state: state),
            );
          }
          return Positioned.fill(child: _ResultCard(state: state));
        },
      );
}

class _Capture extends StatelessWidget {
  const _Capture({required this.container, required this.state});

  final AppContainer container;
  final FaceEnrollState state;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = state;
    final color = personColor(s.color, scheme.primary);
    final step = switch (s.step) {
      'side_a' => t.faceEnrollStepSideA,
      'side_b' => t.faceEnrollStepSideB,
      'far' => t.faceEnrollStepFar,
      _ => t.faceEnrollStepLook,
    };
    final hint = switch (s.hint) {
      'no_face' => t.faceEnrollHintNoFace,
      'several_faces' => t.faceEnrollHintSeveral,
      'closer' => t.faceEnrollHintCloser,
      'farther' => t.faceEnrollHintFarther,
      'look_at_screen' => t.faceEnrollStepLook,
      'turn_more' => t.faceEnrollHintTurnMore,
      'turn_less' => t.faceEnrollHintTurnLess,
      'other_side' => t.faceEnrollHintOtherSide,
      'too_dark' => t.faceEnrollHintDark,
      'other_face' => t.faceEnrollHintOtherFace,
      _ => '',
    };
    final starting = s.phase == FaceEnrollPhase.starting;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final small = box.maxHeight < 440;
            final unit = math.min(box.maxWidth, box.maxHeight);
            final pad = small ? 16.0 : 28.0;
            final ring = (unit * (small ? 0.5 : 0.56)).clamp(140.0, 420.0);
            final big = (unit * 0.05).clamp(20.0, 40.0);
            return Padding(
              padding: EdgeInsets.fromLTRB(pad, pad * 0.75, pad, pad * 0.75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.faceEnrollTitle(s.name),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: container.motion.stopFaceEnroll,
                        child: Text(t.voiceMatchEnrollStop),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Ring(
                          size: ring,
                          progress: s.progress,
                          color: color,
                          track: scheme.surfaceContainerHighest,
                          child: _Preview(state: s),
                        ),
                        SizedBox(height: small ? 12 : 24),
                        Text(
                          starting
                              ? t.voiceMatchEnrollStarting
                              : t.faceEnrollStepOf(
                                  '${math.min(s.stepIndex + 1, s.steps)}',
                                  '${s.steps}',
                                ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!starting)
                          Text(
                            step,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: big,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        SizedBox(height: small ? 6 : 12),
                        AnimatedOpacity(
                          opacity: hint.isEmpty || starting ? 0 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: Text(
                            hint.isEmpty ? ' ' : hint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The latest camera frame, upright and mirrored like a mirror for the
/// front camera, cut to a circle.
class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final FaceEnrollState state;

  @override
  Widget build(BuildContext context) {
    final frame = state.frame;
    final scheme = Theme.of(context).colorScheme;
    if (frame == null) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.face_retouching_natural,
          size: 64,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    Widget image = Image.memory(
      frame,
      gaplessPlayback: true,
      fit: BoxFit.cover,
    );
    image = RotatedBox(quarterTurns: (state.rotation ~/ 90) % 4, child: image);
    if (state.mirror) {
      image = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1, 1, 1),
        child: image,
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: image,
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.size,
    required this.progress,
    required this.color,
    required this.track,
    required this.child,
  });

  final double size;
  final double progress;
  final Color color;
  final Color track;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stroke = (size * 0.035).clamp(6.0, 14.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.all(stroke * 1.6),
            child: ClipOval(child: child),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 300),
            builder: (context, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: stroke,
              color: color,
              backgroundColor: track,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state});

  final FaceEnrollState state;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saved = state.phase == FaceEnrollPhase.saved;
    final color = personColor(state.color, scheme.primary);
    final title = saved
        ? t.faceEnrollSaved(state.name)
        : t.voiceMatchEnrollFailed;
    final detail = saved
        ? (state.complete ? '' : t.faceEnrollSavedPartly)
        : switch (state.error) {
            'too_short' => t.faceEnrollTooShort,
            'unavailable' || 'vision_unavailable' => t.faceEnrollUnavailable,
            _ => t.faceEnrollLost,
          };
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, (1 - v) * 24),
                  child: child,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Material(
                  color: scheme.surfaceContainerHigh,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: saved
                              ? color
                              : scheme.errorContainer,
                          child: Icon(
                            saved ? Icons.check : Icons.close,
                            color: saved
                                ? Colors.white
                                : scheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: theme.textTheme.titleMedium),
                              if (detail.isNotEmpty)
                                Text(
                                  detail,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
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
