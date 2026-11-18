import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_container.dart';
import '../l10n/generated/ui_strings.dart';
import '../l10n/messages.dart';
import '../managers/voice/voice_match_enroll.dart';

/// A Voice Match enrollment on this kiosk: the full screen reading view
/// while the person reads aloud, then a card over the dashboard with the
/// result, which goes on its own.
///
/// The reading view shows the sentence to read large, the ones before and
/// after it, the progress ring in the person's color, a level meter, tips
/// and Stop. The text moves on as speech is counted, not by recognizing
/// the words, so it keeps pace with whoever reads.
class VoiceMatchEnrollOverlay extends StatelessWidget {
  const VoiceMatchEnrollOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<VoiceMatchEnrollment?>(
        valueListenable: container.voice.enrollment,
        builder: (context, state, _) {
          if (state == null) return const SizedBox.shrink();
          if (state.active) {
            return Positioned.fill(
              child: _Reading(container: container, state: state),
            );
          }
          return Positioned.fill(child: _ResultCard(state: state));
        },
      );
}

/// A person's ring color (`#RRGGBB`), or [fallback].
Color personColor(String? hex, Color fallback) {
  final v = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

class _Reading extends StatefulWidget {
  const _Reading({required this.container, required this.state});

  final AppContainer container;
  final VoiceMatchEnrollment state;

  @override
  State<_Reading> createState() => _ReadingState();
}

class _ReadingState extends State<_Reading> {
  /// The last few levels for the meter, oldest first.
  final _levels = List<double>.filled(_bars, 0, growable: true);
  static const _bars = 24;
  double _lastLevelAt = -1;
  Timer? _bannerTimer;
  bool _banner = false;
  DateTime? _bannerFor;

  @override
  void didUpdateWidget(_Reading old) {
    super.didUpdateWidget(old);
    final s = widget.state;
    if (s.speechS != _lastLevelAt || s.level != old.state.level) {
      _lastLevelAt = s.speechS;
      _levels
        ..removeAt(0)
        ..add(((s.level + 60) / 50).clamp(0.0, 1.0));
    }
    final other = s.otherVoiceAt;
    if (other != null && other != _bannerFor) {
      _bannerFor = other;
      _banner = true;
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _banner = false);
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = widget.state;
    final color = personColor(s.color, scheme.primary);
    final passage = enrollPassage(t);
    // Ground Control says which sentence to read and how much of it was
    // spoken. An older one doesn't, and the kiosk paces it by speech.
    final at = s.sentence != null
        ? s.sentence! % passage.length
        : sentenceAt(passage, s.speechS, s.targetS);
    final reading = s.phase == EnrollPhase.recording;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final small = box.maxHeight < 440;
            final portrait = box.maxHeight > box.maxWidth * 1.1;
            final pad = small ? 16.0 : 28.0;
            // Text and ring grow with the screen, so a tablet read from
            // across the room isn't set in phone sizes.
            final unit = math.min(box.maxWidth, box.maxHeight);
            final ringSize = math.min(
              portrait ? box.maxWidth * 0.42 : box.maxHeight * 0.38,
              small ? 120.0 : (unit * 0.36).clamp(200.0, 300.0),
            );
            final progress = _Progress(
              state: s,
              color: color,
              size: ringSize,
              levels: _levels,
            );
            final text = _Passage(
              passage: passage,
              at: at,
              fill: s.sentence != null ? s.sentenceFill : null,
              color: color,
              phase: s.phase,
              small: small,
              unit: unit,
            );
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
                          t.voiceMatchEnrollTitle(s.name),
                          style:
                              (small
                                      ? theme.textTheme.titleMedium
                                      : theme.textTheme.titleLarge)
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: small
                                        ? null
                                        : (unit * 0.032).clamp(22.0, 30.0),
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: s.phase == EnrollPhase.saving
                            ? null
                            : () => unawaited(
                                widget.container.commands.execute(
                                  'voiceMatchEnrollStop',
                                  const {},
                                ),
                              ),
                        child: Text(t.voiceMatchEnrollStop),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _banner && reading
                        ? Padding(
                            padding: EdgeInsets.only(top: small ? 8 : 16),
                            child: _OtherVoiceBanner(
                              text: t.voiceMatchEnrollOtherVoice,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: portrait
                            ? Column(
                                children: [
                                  SizedBox(height: pad),
                                  progress,
                                  SizedBox(height: pad),
                                  Expanded(child: text),
                                ],
                              )
                            : Row(
                                children: [
                                  progress,
                                  SizedBox(width: pad * 2),
                                  Expanded(child: text),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (!small) _Tips(t: t, unit: unit),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The ring filling toward the target in the person's color, with the
/// seconds inside, and the level meter under it.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.state,
    required this.color,
    required this.size,
    required this.levels,
  });

  final VoiceMatchEnrollment state;
  final Color color;
  final double size;
  final List<double> levels;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stroke = math.max(6.0, size * 0.07);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(stroke / 2),
                child: SizedBox.expand(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: state.progress),
                    duration: const Duration(milliseconds: 450),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: state.phase == EnrollPhase.starting ? null : value,
                      strokeWidth: stroke,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(stroke * 2),
                child: FittedBox(
                  child: Text(
                    t.voiceMatchEnrollSeconds(
                      '${state.speechS.floor()}',
                      '${state.targetS.round()}',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: math.max(16, size * 0.12),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: size * 0.12),
        _LevelMeter(levels: levels, color: color, width: size),
      ],
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({
    required this.levels,
    required this.color,
    required this.width,
  });

  final List<double> levels;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = math.max(16.0, width * 0.16);
    final bar = width / levels.length;
    return SizedBox(
      width: width,
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final v in levels)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: bar * 0.18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: bar * 0.64,
                height: math.max(3, v * height),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.35 + 0.65 * v),
                  borderRadius: BorderRadius.circular(bar),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The sentence to read large, with the one before and the one after it,
/// and under it a bar that fills in the person's color as it is spoken.
class _Passage extends StatelessWidget {
  const _Passage({
    required this.passage,
    required this.at,
    required this.fill,
    required this.color,
    required this.phase,
    required this.small,
    required this.unit,
  });

  final List<String> passage;
  final int at;

  /// How much of the sentence was spoken, 0 to 1. Null without pacing.
  final double? fill;
  final Color color;
  final EnrollPhase phase;
  final bool small;

  /// The screen's shorter side, which the text sizes follow.
  final double unit;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = small ? 24.0 : (unit * 0.06).clamp(28.0, 56.0);
    final muted = theme.textTheme.titleMedium?.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      fontSize: small ? null : size * 0.58,
      height: 1.3,
    );
    final big = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w500,
      fontSize: size,
      height: 1.25,
    );
    final waiting = switch (phase) {
      EnrollPhase.starting => t.voiceMatchEnrollStarting,
      EnrollPhase.saving => t.voiceMatchEnrollSaving,
      _ => null,
    };
    final before = at > 0 ? passage[at - 1] : '';
    final after = passage[(at + 1) % passage.length];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.voiceMatchEnrollReading.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            fontSize: small ? null : size * 0.32,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: small ? 8 : 16),
        if (!small && waiting == null)
          Text(before, style: muted, maxLines: 2, overflow: TextOverflow.fade),
        if (!small && waiting == null) const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, if (current != null) current],
          ),
          child: Text(
            waiting ?? passage[at],
            key: ValueKey(waiting ?? 'line$at'),
            style: big,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (fill != null && waiting == null) ...[
          SizedBox(height: small ? 8 : 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              // A new sentence starts its bar empty.
              key: ValueKey('fill$at'),
              tween: Tween(begin: 0, end: fill!.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: small ? 5 : (size * 0.16).clamp(6.0, 10.0),
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ],
        SizedBox(height: small ? 8 : 12),
        if (waiting == null)
          Text(after, style: muted, maxLines: 2, overflow: TextOverflow.fade),
      ],
    );
  }
}

class _OtherVoiceBanner extends StatelessWidget {
  const _OtherVoiceBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips({required this.t, required this.unit});

  final UiStrings t;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = (unit * 0.024).clamp(14.0, 22.0);
    Widget tip(IconData icon, String text) => Expanded(
      child: Row(
        children: [
          Icon(icon, size: size * 1.5, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: size,
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        spacing: 16,
        children: [
          tip(Icons.directions_walk, t.voiceMatchEnrollTipWalk),
          tip(Icons.rotate_left, t.voiceMatchEnrollTipTurn),
          tip(Icons.record_voice_over_outlined, t.voiceMatchEnrollTipTalk),
        ],
      ),
    );
  }
}

/// The result over the dashboard: enrolled, or why nothing was saved.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state});

  final VoiceMatchEnrollment state;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saved = state.phase == EnrollPhase.saved;
    final color = personColor(state.color, scheme.primary);
    final detail = saved
        ? t.voiceMatchEnrollDoneDetail(state.addedS.toStringAsFixed(0))
        : switch (state.code) {
            'too_short' => t.voiceMatchEnrollTooShort,
            'lost' => t.voiceMatchEnrollLost,
            'no_mic' || 'muted' => t.voiceMatchEnrollNoMic,
            'stopped' => t.voiceMatchEnrollStopped,
            _ => state.message ?? '',
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
                              Text(
                                saved
                                    ? t.voiceMatchEnrollDone(state.name)
                                    : t.voiceMatchEnrollFailed,
                                style: theme.textTheme.titleMedium,
                              ),
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
