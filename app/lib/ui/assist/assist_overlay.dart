import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show FramePhase;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../app_container.dart';
import '../../core/events.dart';
import '../../l10n/messages.dart';
import '../../managers/device/screen_capture.dart';
import '../../managers/settings/definitions.dart' as defs;
import '../../managers/voice/assist_view.dart';
import '../../managers/voice/voice_manager.dart';
import '../../managers/voice/voice_notice.dart';
import '../theme.dart';
import '../toast.dart';
import 'art_ink_blobs.dart';
import 'art_jarvis.dart';
import 'art_lens_flares.dart';
import 'art_logo.dart';
import 'art_waveform.dart';
import 'assist_art.dart';
import 'assist_panels.dart';
import 'assist_skins.dart';

/// Native Voice Satellite's overlay: the skin's backdrop and art, the
/// command, the thinking indicator, the answer, and announcements, over
/// whatever the screen shows. Sits in the kiosk screen's announcement slot:
/// above the screensaver and the camera views, below Lockdown Mode's
/// shield. A double tap anywhere ends the turn or takes a lingering answer
/// down.
class AssistOverlay extends StatefulWidget {
  const AssistOverlay({super.key, required this.container});

  final AppContainer container;

  @override
  State<AssistOverlay> createState() => _AssistOverlayState();
}

class _AssistOverlayState extends State<AssistOverlay>
    with SingleTickerProviderStateMixin {
  AppContainer get c => widget.container;

  StreamSubscription<SettingChanged>? _settingsSub;
  StreamSubscription<VoiceNotice>? _errorSub;
  StreamSubscription<String>? _clearedSub;

  /// One clock for the bar and the dots, so their phases stay locked the
  /// way the skins' animations share a start time.
  late final ArtClock _clock;
  late final LevelGlide _glide = LevelGlide(c.voice.level);

  /// The last view with something on it, kept while the overlay fades out.
  AssistView _shown = AssistView.hidden;

  /// An opened result: ('image', url) or ('video', YouTube id).
  (String, String)? _lightbox;

  /// Where the docked bubble sits, fractions of the room around it.
  double _dockX = .5, _dockY = 1;
  final _dockKey = GlobalKey();

  void _readDockPosition() {
    final parts = c.settings.get(defs.voiceDockPosition).split(',');
    double part(int i, double fallback) {
      final v = i < parts.length ? double.tryParse(parts[i]) : null;
      return v != null && v.isFinite ? v.clamp(0, 1) : fallback;
    }

    _dockX = part(0, .5);
    _dockY = part(1, 1);
  }

  /// What was under the overlay when it opened, blurred once: the
  /// see-through skins' backdrop-filter. The browser keeps a blurred
  /// backdrop until what is under it changes; Impeller would blur the
  /// screen again every frame the bar or the dots move, which cost those
  /// skins a quarter of their frame rate. Until the capture lands the
  /// live filter stands in.
  ui.Image? _frozen;
  int _frozenGen = 0;

  /// Frame timings while the overlay is up, reported through voiceStatus
  /// so a skin's cost on a device can be read remotely.
  final _timings = <FrameTiming>[];
  bool _timing = false;

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
    final now = _timings.last.timestampInMicroseconds(FramePhase.rasterFinish);
    _timings.removeWhere(
      (t) => now - t.timestampInMicroseconds(FramePhase.rasterFinish) > 3e6,
    );
    if (_timings.length < 2) return;
    final span =
        (now -
            _timings.first.timestampInMicroseconds(FramePhase.rasterFinish)) /
        1e6;
    double avg(Duration Function(FrameTiming) of) =>
        _timings.fold<int>(0, (a, t) => a + of(t).inMicroseconds) /
        _timings.length /
        1000;
    c.voice.overlayFrames = {
      'fps': span > 0 ? ((_timings.length - 1) / span).toStringAsFixed(1) : '0',
      'buildMs': avg((t) => t.buildDuration).toStringAsFixed(1),
      'rasterMs': avg((t) => t.rasterDuration).toStringAsFixed(1),
      'vsyncMs': avg((t) => t.vsyncOverhead).toStringAsFixed(1),
      'totalMs': avg((t) => t.totalSpan).toStringAsFixed(1),
      'skin': c.settings.get(defs.voiceSkin),
      'artStepMs': ArtCost.stepMs.toStringAsFixed(1),
      'artPaintMs': ArtCost.paintMs.toStringAsFixed(1),
      'artSnapshotMs': ArtCost.snapshotMs.toStringAsFixed(1),
    };
  }

  void _watchFrames(bool on) {
    if (on == _timing) return;
    _timing = on;
    if (on) {
      _timings.clear();
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    } else {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
  }

  @override
  void initState() {
    super.initState();
    _clock = ArtClock(this, running: false);
    c.voice.view.addListener(_onView);
    _readDockPosition();
    _settingsSub = c.bus.on<SettingChanged>().listen((e) {
      if (!e.key.startsWith('voice.') || !mounted) return;
      setState(() {
        if (e.key == defs.voiceDockPosition.key) _readDockPosition();
      });
    });
    _errorSub = c.voice.notices.stream.listen(_onNotice);
    _clearedSub = c.voice.clearedNotices.stream.listen(_onCleared);
  }

  @override
  void dispose() {
    c.voice.view.removeListener(_onView);
    _watchFrames(false);
    _frozenGen++;
    _frozen?.dispose();
    _settingsSub?.cancel();
    _errorSub?.cancel();
    _clearedSub?.cancel();
    _clock.dispose();
    _glide.dispose();
    super.dispose();
  }

  void _onView() {
    final next = c.voice.view.value;
    if (!mounted) return;
    _watchFrames(next.visible);
    if (next.visible) _clock.running = true;
    // A docked conversation has no backdrop to blur.
    if (next.visible && !_shown.visible && !next.docked) {
      unawaited(_freezeBackdrop());
    } else if (!next.visible) {
      _frozenGen++;
    }
    setState(() {
      if (next.visible) {
        _shown = next;
      } else {
        _lightbox = null;
      }
    });
  }

  Future<void> _freezeBackdrop() async {
    final gen = ++_frozenGen;
    final skin = assistSkinById(c.settings.get(defs.voiceSkin));
    final chosen = c.settings.get(defs.voiceBackgroundOpacity).toDouble();
    final opacity = chosen < 0 ? skin.light.opacity : chosen / 100;
    if (skin.blur <= 0 || opacity >= 0.99) return;
    if (skin.art == SkinArt.lensFlares) return;
    final width = MediaQuery.sizeOf(context).width;
    // Small: it is about to be blurred, and the backdrop covers most of it.
    final bytes = await ScreenCapture.capture(width: 640, quality: 85);
    if (bytes == null || gen != _frozenGen || !mounted) return;
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final source = frame.image;
    final sigma = skin.blur * source.width / width;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImage(
      source,
      Offset.zero,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
    );
    final picture = recorder.endRecording();
    final blurred = picture.toImageSync(source.width, source.height);
    picture.dispose();
    source.dispose();
    if (gen != _frozenGen || !mounted) {
      blurred.dispose();
      return;
    }
    setState(() {
      _frozen?.dispose();
      _frozen = blurred;
    });
  }

  void _onNotice(VoiceNotice notice) {
    if (!mounted) return;
    final error = notice.severity == VoiceSeverity.error;
    final tag = 'voice-${notice.id}';
    // An error still up is not shown again, as Voice Satellite refreshes
    // one rather than re-animating it.
    if (error && currentToastTag == tag) return;
    // Voice Satellite's toasts: the title from the severity, the source
    // before the message, errors up for 10 seconds or until closed.
    // The kiosk's own wording is translated; an error Home Assistant sent
    // stays as it came.
    final pipeline = RegExp(r'^Pipeline "(.*)"$').firstMatch(notice.category);
    final category = pipeline != null
        ? l10n(context).voiceNoticePipeline(pipeline.group(1)!)
        : voiceText(context, notice.category);
    showToast(
      context,
      title: voiceText(context, switch (notice.severity) {
        VoiceSeverity.error => 'Voice Satellite error',
        VoiceSeverity.warning => 'Voice Satellite warning',
        VoiceSeverity.notice => 'Voice Satellite notice',
      }),
      message: '$category: ${voiceText(context, notice.message)}',
      kind: switch (notice.severity) {
        VoiceSeverity.error => ToastKind.error,
        VoiceSeverity.warning => ToastKind.warning,
        VoiceSeverity.notice => ToastKind.info,
      },
      duration: switch (notice.severity) {
        VoiceSeverity.error => const Duration(seconds: 10),
        VoiceSeverity.warning => const Duration(seconds: 8),
        VoiceSeverity.notice => const Duration(seconds: 4),
      },
      actionLabel: error ? 'Close' : null,
      onAction: error ? () {} : null,
      tag: tag,
    );
  }

  /// The problem behind a notice cleared: its toast comes down, if it is
  /// still the one on screen.
  void _onCleared(String id) => dismissToast(tag: 'voice-$id');

  @override
  Widget build(BuildContext context) {
    final visible = c.voice.view.value.visible;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(milliseconds: visible ? 300 : 400),
        curve: Curves.ease,
        onEnd: () {
          if (!c.voice.view.value.visible && mounted) {
            _clock.running = false;
            setState(() {
              _shown = AssistView.hidden;
              _frozen?.dispose();
              _frozen = null;
            });
          }
        },
        child: !_shown.visible
            ? const SizedBox.shrink()
            // Docked, touches reach the screen under it: only the caption
            // and the close button take them.
            : _shown.docked
            ? _docked(context, _shown)
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: c.voice.dismiss,
                child: _content(context, _localizedPreview(context, _shown)),
              ),
      ),
    );
  }

  /// Preview's sample turn in the kiosk's language. A real turn's words
  /// are never looked up: an answer that happens to read like one of the
  /// app's strings stays as the assistant said it.
  AssistView _localizedPreview(BuildContext context, AssistView view) =>
      view.command == VoiceManager.previewCommand &&
          view.answer == VoiceManager.previewAnswer
      ? view.copyWith(
          command: l10n(context).voicePreviewCommand,
          answer: l10n(context).voicePreviewAnswer,
        )
      : view;

  Widget _content(BuildContext context, AssistView view) {
    final settings = c.settings;
    final skin = assistSkinById(settings.get(defs.voiceSkin));
    final theme = settings.get(defs.voiceTheme);
    final dark =
        skin.darkOnly ||
        switch (theme) {
          'dark' => true,
          'light' => false,
          _ => Theme.of(context).brightness == Brightness.dark,
        };
    final palette = skin.palette(dark);
    final chosen = settings.get(defs.voiceBackgroundOpacity).toDouble();
    final opacity = (chosen < 0 ? palette.opacity : chosen / 100).clamp(
      0.0,
      1.0,
    );
    final scale = settings.get(defs.voiceTextScale).toDouble() / 100;
    final mode = switch (view.phase) {
      _ when view.lingering => ArtMode.idle,
      AssistPhase.thinking => ArtMode.thinking,
      AssistPhase.speaking || AssistPhase.announcement => ArtMode.speaking,
      AssistPhase.listening => ArtMode.listening,
      AssistPhase.hidden => ArtMode.idle,
    };
    // The bar's .reactive (and the page's reactive-mode): listening or
    // speaking with the reactive bar on.
    final reactive =
        settings.get(defs.voiceReactiveBar) &&
        view.reactive &&
        mode != ArtMode.thinking;
    // Voice Only's light screen takes the app's own full screen ground (the
    // launcher's and the intercom's), drawn over the backdrop: the flat
    // paper tone alone reads as white.
    final ground = skin.voiceOnly && !dark;
    final color = ground
        ? const Color(0x00000000)
        : palette.backdrop.withValues(alpha: opacity);
    // backdrop-filter: blur shows only where the backdrop lets the screen
    // through: the frozen blurred screen under it once captured, the live
    // filter until then.
    final frozen = _frozen;
    final blurs = skin.blur > 0 && opacity < 0.99;
    Widget backdrop = SkinBackdrop(
      skin: skin,
      color: color,
      under: blurs ? frozen : null,
      cache: true,
    );
    if (blurs && frozen == null) {
      backdrop = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: skin.blur, sigmaY: skin.blur),
        child: backdrop,
      );
    }
    if (skin.voiceOnly) {
      // The mark alone, as large as the screen allows.
      final size = MediaQuery.sizeOf(context);
      return Stack(
        fit: StackFit.expand,
        children: [
          backdrop,
          if (ground)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    for (final c in ksGroundGradient(
                      palette.backdrop,
                      Brightness.light,
                    ).colors)
                      c.withValues(alpha: opacity),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(math.min(size.width, size.height) * 0.08),
            child: LogoArt(
              mode: mode,
              reactive: reactive,
              level: _glide,
              clock: _clock,
            ),
          ),
        ],
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        // Lens Flares paints its own black over everything under it.
        if (skin.art != SkinArt.lensFlares) backdrop,
        if (skin.art == SkinArt.waveform)
          WaveformArt(
            dark: dark,
            mode: mode,
            reactive: reactive,
            level: c.voice.level,
          ),
        if (skin.art == SkinArt.inkBlobs)
          InkBlobsArt(
            dark: dark,
            mode: mode,
            reactive: reactive,
            level: c.voice.level,
          ),
        if (skin.art == SkinArt.lensFlares)
          LensFlaresArt(mode: mode, reactive: reactive, level: c.voice.level),
        if (skin.art == SkinArt.jarvis)
          IgnorePointer(
            child: JarvisArt(
              mode: mode,
              reactive: reactive,
              level: _glide,
              clock: _clock,
              inset: _beside(context, view),
            ),
          ),
        SkinBarLayer(
          skin: skin,
          mode: mode,
          reactive: reactive,
          level: _glide,
          clock: _clock,
        ),
        if (view.phase == AssistPhase.announcement)
          _announcement(context, skin, palette, scale, view)
        else ...[
          _chat(context, skin, palette, scale, view, reactive),
          if (primaryResult(view.results) case final result?)
            _panel(context, skin, dark, scale, result),
        ],
        if (_lightbox case (final kind, final value))
          Positioned.fill(child: _lightboxView(context, kind, value)),
      ],
    );
  }

  /// The chat's side insets while a result panel stands beside it, for
  /// art that keeps to the chat's column. None in portrait, where the
  /// panel sits above the chat.
  EdgeInsets _beside(BuildContext context, AssistView view) {
    final size = MediaQuery.sizeOf(context);
    final result = primaryResult(view.results);
    if (result == null || size.height > size.width) return EdgeInsets.zero;
    return EdgeInsets.only(
      left: size.width * 0.075,
      right: chatRightInset(size, result),
    );
  }

  /// A realtime conversation: the skin's bar along the edge for the whole
  /// of it, a caption card with the current exchange that fades while the
  /// room is quiet, and a close button. No backdrop, no art: the dashboard
  /// under it stays visible and usable.
  Widget _docked(BuildContext context, AssistView view) {
    final settings = c.settings;
    final skin = assistSkinById(settings.get(defs.voiceSkin));
    final theme = settings.get(defs.voiceTheme);
    final dark =
        skin.darkOnly ||
        switch (theme) {
          'dark' => true,
          'light' => false,
          _ => Theme.of(context).brightness == Brightness.dark,
        };
    final palette = skin.palette(dark);
    final scale =
        settings.get(defs.voiceTextScale).toDouble() / 100 * dockedTextScale;
    final mode = switch (view.phase) {
      AssistPhase.thinking => ArtMode.thinking,
      AssistPhase.speaking || AssistPhase.announcement => ArtMode.speaking,
      AssistPhase.listening => ArtMode.listening,
      AssistPhase.hidden => ArtMode.idle,
    };
    final reactive =
        settings.get(defs.voiceReactiveBar) &&
        view.reactive &&
        mode != ArtMode.thinking;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    // The skin's backdrop, which its text colors are made for, solid
    // enough to read over any dashboard.
    final bubble = palette.backdrop.withValues(
      alpha: math.max(0.94, palette.opacity),
    );
    final width = math.min(560.0, size.width - 32);
    final showCommand = settings.get(defs.voiceShowCommand);
    final showAnswer = settings.get(defs.voiceShowAnswer);
    final tools = settings.get(defs.voiceShowTools) ? view.tools : const [];
    final thinking = view.phase == AssistPhase.thinking && view.answer.isEmpty;
    final said =
        (showCommand && view.command.isNotEmpty) ||
        (showAnswer && view.answer.isNotEmpty) ||
        tools.isNotEmpty;
    final lines = <Widget>[
      // The bubble says it hears before anything is said.
      if (!said && !thinking && view.phase == AssistPhase.listening)
        Text(
          voiceText(context, 'Listening…'),
          style: _text(
            skin,
            palette.user,
            skin.userSize * scale,
            skin.userWeight,
            palette.userShadows,
          ),
        ),
      if (showCommand && view.command.isNotEmpty)
        Text(
          '${skin.prefix}${view.command}',
          style: _text(
            skin,
            palette.user,
            skin.userSize * scale,
            skin.userWeight,
            palette.userShadows,
          ),
        ),
      for (final tool in tools) _toolLine(skin, palette, scale, tool),
      if (thinking && tools.isEmpty)
        ThinkingDots(
          skin: skin,
          colors: palette.dots,
          shadows: palette.toolShadows,
          scale: scale,
          clock: _clock,
        ),
      if (showAnswer && view.answer.isNotEmpty)
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.textScalerOf(
                  context,
                ).scale(skin.answerSize * scale) *
                1.3 *
                4,
          ),
          child: _RevealText(
            text: view.answer,
            streaming: view.streaming,
            current: true,
            playback: () => null,
            style: _text(
              skin,
              palette.answer,
              skin.answerSize * scale,
              skin.answerWeight,
              palette.answerShadows,
            ),
            textAlign: TextAlign.left,
          ),
        ),
    ];
    // The bubble: the exchange, and the skin's bar docked along its
    // bottom. Up for the whole conversation, a slim pill with just the bar
    // while nothing has been said. Voice Only shows the mark alone, no
    // bubble around it, fading as the conversation ends. Jarvis puts its
    // reactor beside the exchange instead of a bar, its outer ring
    // unwinding as the conversation ends.
    final logoSide = (math.min(size.width, size.height) * 0.24).clamp(
      72.0,
      140.0,
    );
    final decoration = BoxDecoration(
      color: bubble,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: palette.answer.withValues(alpha: 0.16)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
    const reactorSide = 64.0;
    final card = skin.art == SkinArt.jarvis
        ? AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            alignment: Alignment.bottomLeft,
            child: Container(
              width: lines.isEmpty ? null : width,
              padding: const EdgeInsets.all(12),
              decoration: decoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 14,
                children: [
                  SizedBox.square(
                    dimension: reactorSide,
                    child: IgnorePointer(
                      child: JarvisArt(
                        mode: mode,
                        reactive: reactive,
                        level: _glide,
                        clock: _clock,
                        compact: true,
                        countdown: c.voice.dockCountdown,
                      ),
                    ),
                  ),
                  if (lines.isNotEmpty)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 6,
                          children: lines,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        : skin.voiceOnly
        ? SizedBox.square(
            dimension: logoSide,
            child: IgnorePointer(
              child: LogoArt(
                mode: mode,
                reactive: reactive,
                level: _glide,
                clock: _clock,
                fade: c.voice.dockCountdown,
              ),
            ),
          )
        : AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.ease,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: width,
              clipBehavior: Clip.antiAlias,
              decoration: decoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (lines.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: lines,
                      ),
                    ),
                  IgnorePointer(
                    child: DockedBarLayer(
                      bar: skin.barDocked,
                      mode: mode,
                      reactive: reactive,
                      level: _glide,
                      clock: _clock,
                      countdown: c.voice.dockCountdown,
                    ),
                  ),
                ],
              ),
            ),
          );
    // Anywhere on screen, where it was last dragged: its position is a
    // fraction of the room left around it, so a bubble that grows as the
    // answer comes in keeps to the edge it was put against.
    final placed = Padding(
      padding: EdgeInsets.fromLTRB(
        16 + padding.left,
        16 + padding.top,
        16 + padding.right,
        24 + padding.bottom,
      ),
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Align(
              alignment: Alignment(_dockX * 2 - 1, _dockY * 2 - 1),
              child: GestureDetector(
                key: _dockKey,
                behavior: HitTestBehavior.opaque,
                // Ends it, as a double tap on the full screen overlay does.
                onDoubleTap: c.voice.dismiss,
                onPanUpdate: (d) {
                  final size = _dockKey.currentContext?.size;
                  if (size == null) return;
                  final freeX = box.maxWidth - size.width;
                  final freeY = box.maxHeight - size.height;
                  setState(() {
                    if (freeX > 0) {
                      _dockX = (_dockX + d.delta.dx / freeX).clamp(0, 1);
                    }
                    if (freeY > 0) {
                      _dockY = (_dockY + d.delta.dy / freeY).clamp(0, 1);
                    }
                  });
                },
                onPanEnd: (_) => c.settings.set(
                  defs.voiceDockPosition,
                  '${_dockX.toStringAsFixed(4)},${_dockY.toStringAsFixed(4)}',
                ),
                child: card,
              ),
            ),
          ],
        ),
      ),
    );
    // What is under it holds its last frame while the conversation runs.
    // A touch there wants it back: the first one wakes it and goes no
    // further, since a paused screensaver would let it through to the
    // dashboard and a paused page would take it without redrawing.
    return ValueListenableBuilder<bool>(
      valueListenable: c.voice.underlayPaused,
      child: placed,
      builder: (context, paused, child) => Stack(
        fit: StackFit.expand,
        children: [
          if (paused)
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => c.voice.wakeUnderlay(),
            ),
          child!,
        ],
      ),
    );
  }

  /// Home Assistant hands out some media as paths on its own address.
  String _resolve(String url) {
    if (url.isEmpty || url.contains('://')) return url;
    final base = c.settings
        .get(defs.haUrl)
        .trim()
        .replaceFirst(RegExp(r'/+$'), '');
    return '$base${url.startsWith('/') ? '' : '/'}$url';
  }

  void _open(String kind, String value) {
    if (value.isEmpty) return;
    // Looking at a result keeps it up, and a video talks over nothing.
    c.voice.holdResults(silence: kind == 'video');
    setState(() => _lightbox = (kind, value));
  }

  Widget _panel(
    BuildContext context,
    AssistSkin skin,
    bool dark,
    double scale,
    AssistResult result,
  ) {
    final size = MediaQuery.sizeOf(context);
    final portrait = size.height > size.width;
    final panel = _FadeIn(
      child: AssistResultPanel(
        result: result,
        skin: skin,
        dark: dark,
        scale: scale,
        resolve: _resolve,
        onOpen: _open,
      ),
    );
    if (portrait) {
      return Positioned(
        top: size.height * panelTop,
        left: 0,
        right: 0,
        child: Align(alignment: Alignment.topCenter, child: panel),
      );
    }
    return Positioned(
      top: 0,
      bottom: 0,
      right: size.width * 0.075,
      child: Align(alignment: Alignment.centerRight, child: panel),
    );
  }

  /// An opened image, or a YouTube video playing, over everything; a tap
  /// outside it goes back to the panel.
  Widget _lightboxView(BuildContext context, String kind, String value) {
    final size = MediaQuery.sizeOf(context);
    final close = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _lightbox = null),
      child: const ColoredBox(color: Color(0xEB000000)),
    );
    if (kind == 'image') {
      return Stack(
        fit: StackFit.expand,
        children: [
          close,
          IgnorePointer(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: size.width * 0.9,
                  maxHeight: size.height * 0.9,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    value,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final width = (size.width * 0.9).clamp(0.0, 1200.0);
    final height = (width * 9 / 16).clamp(0.0, size.height * 0.9);
    final id = Uri.encodeComponent(value);
    // An embed needs a page around it with a real origin (YouTube refuses
    // one without a referrer): Home Assistant's address, as the
    // integration's page had.
    final html =
        '<!doctype html><html><head><meta name="viewport" '
        'content="width=device-width,initial-scale=1"></head>'
        '<body style="margin:0;background:#000;overflow:hidden">'
        '<iframe src="https://www.youtube-nocookie.com/embed/$id?autoplay=1" '
        'style="border:0;width:100vw;height:100vh" '
        'allow="autoplay; encrypted-media; picture-in-picture" '
        'allowfullscreen></iframe></body></html>';
    return Stack(
      fit: StackFit.expand,
      children: [
        close,
        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InAppWebView(
                key: ValueKey(value),
                initialData: InAppWebViewInitialData(
                  data: html,
                  baseUrl: WebUri(_resolve('/')),
                ),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  transparentBackground: true,
                  supportZoom: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A line of chat text, as the skin's .vs-chat-msg rule draws it:
  /// line-height normal, the skin's font, weight and shadows.
  TextStyle _text(
    AssistSkin skin,
    Color color,
    double size,
    FontWeight weight,
    List<CssShadow> shadows, {
    bool italic = false,
  }) => TextStyle(
    fontFamily: skin.font,
    fontSize: size,
    fontWeight: weight,
    fontVariations: fontVariationsFor(skin.font, size, weight),
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    height: skin.lineHeight,
    leadingDistribution: TextLeadingDistribution.even,
    color: color,
    shadows: shadows.isEmpty ? null : [for (final s in shadows) s.shadow],
  );

  /// A message box: padding 4px 0, max-width of the chat's width.
  Widget _msg(
    AssistSkin skin,
    double chatWidth,
    Widget child, {
    double padding = 4,
    Key? key,
  }) => _FadeIn(
    key: key,
    dy: skin.fadeDy,
    ms: skin.fadeMs,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: chatWidth * skin.msgMaxWidth),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: child,
      ),
    ),
  );

  Widget _announcement(
    BuildContext context,
    AssistSkin skin,
    SkinPalette palette,
    double scale,
    AssistView view,
  ) {
    final size = MediaQuery.sizeOf(context);
    // .announcement-mode: centered on announcementTop, 85% wide; the
    // message keeps its own alignment inside it.
    final width = size.width * 0.85;
    return Positioned(
      left: (size.width - width) / 2,
      width: width,
      top: 0,
      height: size.height * skin.announcementTop * 2,
      child: Align(
        alignment: Alignment(skin.centered ? 0 : -1, 0),
        child: _msg(
          skin,
          width,
          Text(
            view.answer,
            textAlign: skin.centered ? TextAlign.center : TextAlign.left,
            style: _text(
              skin,
              palette.answer,
              skin.answerSize * scale,
              skin.answerWeight,
              palette.answerShadows,
            ),
          ),
        ),
      ),
    );
  }

  /// The tool line: the frozen dots and the tool's name beside them. The
  /// first reuses the thinking line (its padding), later ones are
  /// .tool-call lines (2px).
  Widget _toolLine(
    AssistSkin skin,
    SkinPalette palette,
    double scale,
    String name,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ThinkingDots(
        skin: skin,
        colors: palette.dots,
        shadows: palette.toolShadows,
        scale: scale,
        clock: _clock,
        idle: true,
      ),
      SizedBox(width: skin.toolMargin),
      Flexible(
        child: Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Text(
            name,
            style: _text(
              skin,
              palette.tool,
              skin.toolSize * scale,
              skin.toolWeight,
              palette.toolShadows,
              italic: skin.toolItalic,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _chat(
    BuildContext context,
    AssistSkin skin,
    SkinPalette palette,
    double scale,
    AssistView view,
    bool reactive,
  ) {
    final settings = c.settings;
    final size = MediaQuery.sizeOf(context);
    final result = primaryResult(view.results);
    final portrait = size.height > size.width;
    final left = size.width * 0.075;
    final right = chatRightInset(size, result);
    final chatWidth = size.width - left - right;
    final textAlign = skin.centered ? TextAlign.center : TextAlign.left;
    final thinkingPad = skin.dots == DotsStyle.logoBars ? 2.0 : 4.0;
    final showTools = settings.get(defs.voiceShowTools);
    final showCommand = settings.get(defs.voiceShowCommand);
    final showAnswer = settings.get(defs.voiceShowAnswer);
    final answerStyle = _text(
      skin,
      palette.answer,
      skin.answerSize * scale,
      skin.answerWeight,
      palette.answerShadows,
    );
    final userStyle = _text(
      skin,
      palette.user,
      skin.userSize * scale,
      skin.userWeight,
      palette.userShadows,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final bottom = reactive ? skin.chatBottomReactive : skin.chatBottom;
    // In portrait a result panel stands at the top, down to half the
    // screen at most: the chat stays under it rather than running across.
    final underPanel = portrait && result != null;
    final top = underPanel
        ? math.max(
            skin.chatTop,
            size.height * (panelTop + panelMaxPortrait) + 16,
          )
        : skin.chatTop;

    /// How tall the lines above a turn's answer stand: its command and
    /// tool lines, each with its padding and the gap after it.
    double aboveAnswer(AssistTurn turn) {
      var height = 0.0;
      if (showCommand && turn.command.isNotEmpty) {
        final painter = TextPainter(
          text: TextSpan(
            text: '${skin.prefix}${turn.command}',
            style: userStyle,
          ),
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout(maxWidth: chatWidth * skin.msgMaxWidth);
        height += painter.height + 8 + skin.gap;
        painter.dispose();
      }
      if (showTools) {
        final line = textScaler.scale(skin.toolSize * scale) * 1.3;
        height += turn.tools.length * (line + 8 + skin.gap);
      }
      return height;
    }

    // Every turn's lines, the earlier ones above the one in progress, as
    // Voice Satellite keeps a conversation on screen. Keys follow the turn
    // so a line keeps its state (and does not fade in again) as later
    // turns come in below it.
    List<Widget> turnLines(
      int n,
      AssistTurn turn, {
      required bool current,
      required bool dimmed,
    }) {
      final tools = showTools ? turn.tools : const <String>[];
      return [
        if (showCommand && turn.command.isNotEmpty)
          _msg(
            skin,
            chatWidth,
            key: ValueKey('$n.user'),
            Text(
              '${skin.prefix}${turn.command}',
              textAlign: textAlign,
              style: userStyle,
            ),
          ),
        // Frozen indicator lines dim once a later turn starts thinking.
        for (final (i, tool) in tools.indexed)
          _msg(
            skin,
            chatWidth,
            key: ValueKey('$n.tool$i'),
            padding: i == 0 ? thinkingPad : 2,
            AnimatedOpacity(
              opacity: dimmed ? 0.4 : 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.ease,
              child: _toolLine(skin, palette, scale, tool),
            ),
          ),
        if (current && view.phase == AssistPhase.thinking && tools.isEmpty)
          _msg(
            skin,
            chatWidth,
            key: ValueKey('$n.thinking'),
            padding: thinkingPad,
            ThinkingDots(
              skin: skin,
              colors: palette.dots,
              shadows: palette.toolShadows,
              scale: scale,
              clock: _clock,
            ),
          ),
        if (showAnswer && turn.answer.isNotEmpty)
          _msg(
            skin,
            chatWidth,
            key: ValueKey('$n.answer'),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: () {
                  final cap =
                      size.height * (result != null && portrait ? 0.4 : 0.7);
                  if (!current) return cap;
                  // The turn in progress keeps its command on screen: the
                  // answer scrolls in what is left under the skin's top.
                  final room =
                      size.height - bottom - top - aboveAnswer(turn) - 8;
                  final line = textScaler.scale(skin.answerSize * scale) * 1.3;
                  return math.max(line, math.min(cap, room));
                }(),
              ),
              child: _RevealText(
                text: turn.answer,
                streaming: current && view.streaming,
                current: current,
                playback: () => c.voice.playback,
                style: answerStyle,
                textAlign: textAlign,
              ),
            ),
          ),
      ];
    }

    final current = view.earlier.length;
    final thinkingOn = view.phase != AssistPhase.listening;
    final lines = <Widget>[
      for (final (n, turn) in view.earlier.indexed)
        ...turnLines(
          n,
          turn,
          current: false,
          dimmed: n < current - 1 || thinkingOn,
        ),
      ...turnLines(current, view.turn, current: true, dimmed: false),
    ];
    // The chat grows up from its bottom edge; a long conversation's first
    // lines leave the top of the screen, as they do in Voice Satellite.
    Widget chat = OverflowBox(
      alignment: skin.centered ? Alignment.bottomCenter : Alignment.bottomLeft,
      minHeight: 0,
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: skin.centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        spacing: skin.gap,
        children: lines,
      ),
    );
    if (underPanel) {
      // Under a portrait panel they leave at its edge instead, fading out
      // over the first lines' worth below it.
      chat = ClipRect(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0x00000000), Color(0xFF000000)],
            stops: [0, bounds.height > 0 ? math.min(1, 24 / bounds.height) : 0],
          ).createShader(bounds),
          child: chat,
        ),
      );
    }
    return Positioned(
      left: left,
      right: right,
      top: underPanel ? top : 0,
      bottom: bottom,
      child: chat,
    );
  }
}

/// The docked caption's text against the skin's full-screen sizes.
const dockedTextScale = 0.55;

/// A line's entry, as the skins animate new messages: opacity 0 to 1 while
/// it rises [dy] px, over [ms] with CSS's ease.
class _FadeIn extends StatelessWidget {
  const _FadeIn({super.key, required this.child, this.dy = 8, this.ms = 300});
  final Widget child;
  final double dy;
  final int ms;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: ms),
    curve: Curves.ease,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(offset: Offset(0, dy * (1 - t)), child: child),
    ),
    child: child,
  );
}

/// The answer's text as Voice Satellite streams it in: the newest eight
/// characters fading, in four pairs from full to a quarter opacity, and the
/// whole of it solid once it is complete. Home Assistant sends a voice
/// turn's answer whole, so it is revealed at about the pace an assistant
/// streams; a vs_show's arrives in pieces and is revealed as they come.
/// A long answer scrolls inside its box ([_PacedScroll]).
class _RevealText extends StatefulWidget {
  const _RevealText({
    required this.text,
    required this.streaming,
    required this.current,
    required this.playback,
    required this.style,
    required this.textAlign,
  });

  final String text;

  /// More text is coming.
  final bool streaming;

  /// The turn in progress: an earlier turn's answer stops scrolling.
  final bool current;
  final Playback Function() playback;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  State<_RevealText> createState() => _RevealTextState();
}

/// Characters revealed a second.
const _revealRate = 120.0;

/// Voice Satellite's fade: four groups of two characters.
const _fadeGroups = 4;
const _charsPerGroup = 2;
const _fadeLength = _fadeGroups * _charsPerGroup;

class _RevealTextState extends State<_RevealText>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  double _shown = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void didUpdateWidget(_RevealText old) {
    super.didUpdateWidget(old);
    // A replaced text (a show's final answer) keeps what was revealed of
    // it, no more than its length.
    _shown = math.min(_shown, widget.text.length.toDouble());
    if (!_ticker.isActive && _shown < widget.text.length) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final target = widget.text.length.toDouble();
    setState(() => _shown = math.min(target, _shown + _revealRate * dt));
    if (_shown >= target) {
      _ticker.stop();
      _last = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final count = _shown.floor().clamp(0, text.length);
    final complete = count >= text.length && !widget.streaming;
    final shown = text.substring(0, count);
    final Widget child;
    if (complete || shown.length <= _fadeLength) {
      child = Text(shown, textAlign: widget.textAlign, style: widget.style);
    } else {
      final solid = shown.substring(0, shown.length - _fadeLength);
      final tail = shown.substring(shown.length - _fadeLength);
      child = Text.rich(
        TextSpan(
          style: widget.style,
          children: [
            TextSpan(text: solid),
            for (var g = 0; g < _fadeGroups; g++)
              TextSpan(
                text: tail.substring(
                  g * _charsPerGroup,
                  (g + 1) * _charsPerGroup,
                ),
                style: _faded(widget.style, (_fadeGroups - g) / _fadeGroups),
              ),
          ],
        ),
        textAlign: widget.textAlign,
      );
    }
    return _PacedScroll(
      text: text,
      complete: !widget.streaming,
      active: widget.current,
      playback: widget.playback,
      fade: (widget.style.fontSize ?? 36) * 1.25,
      child: child,
    );
  }

  /// [style] at [opacity], its shadows too, as a span's CSS opacity does.
  static TextStyle _faded(TextStyle style, double opacity) {
    final color = style.color ?? const Color(0xFF000000);
    return style.copyWith(
      color: color.withValues(alpha: color.a * opacity),
      shadows: [
        for (final s in style.shadows ?? const <Shadow>[])
          Shadow(
            color: s.color.withValues(alpha: s.color.a * opacity),
            offset: s.offset,
            blurRadius: s.blurRadius,
          ),
      ],
    );
  }
}

/// Seconds into the answer playing now and its length, or null.
typedef Playback = ({double elapsed, double duration})?;

/// Voice Satellite's reading-paced scroll (paced-scroll.js) for an answer
/// taller than its box: the text reaches its end about when the speech
/// does. Each frame the speed eases toward the pixels left over the
/// seconds of speech left, between 10 and 200 px/s. The seconds left come
/// from the player while it knows the answer's length (a streamed answer's
/// only once all of it has arrived), else from the script's estimate from
/// the words, counted from when the text is complete. Until the text is
/// complete or the speech has a clock, the scroll holds, since speech
/// starts at the top. The text fades out at an edge it runs past: at the
/// top once it has scrolled, at the bottom while more is below.
class _PacedScroll extends StatefulWidget {
  const _PacedScroll({
    required this.text,
    required this.complete,
    required this.active,
    required this.playback,
    required this.fade,
    required this.child,
  });

  /// How tall each edge's fade is, about a line of the text.
  final double fade;

  final String text;
  final bool complete;

  /// The turn in progress. A later turn's answer takes over the pacing.
  final bool active;
  final Playback Function() playback;
  final Widget child;

  @override
  State<_PacedScroll> createState() => _PacedScrollState();
}

const _minSpeed = 10.0;
const _maxSpeed = 200.0;
const _startSpeed = 30.0;
// Per 60 Hz frame, as the script eases.
const _ease = 0.12;
const _maxFrame = Duration(milliseconds: 100);

class _PacedScrollState extends State<_PacedScroll>
    with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  late final Ticker _ticker = createTicker(_tick);

  /// How far in each edge's fade is, 0..1: it grows over the first line
  /// scrolled (top) and shrinks over the last line left (bottom).
  double _top = 0;
  double _bottom = 0;
  Duration _last = Duration.zero;
  double _speed = 0;
  double _estimate = 0;

  /// Runs from the first frame the estimate paces, across the ticker's
  /// stops and starts.
  final _estimateClock = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (widget.complete) {
      _finalize();
    } else {
      _nudge();
    }
    _fadeAfterLayout();
  }

  /// The fades once the text is laid out: its first layout sends no
  /// notification.
  void _fadeAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      if (position.hasContentDimensions) _onScroll(position);
    });
  }

  @override
  void didUpdateWidget(_PacedScroll old) {
    super.didUpdateWidget(old);
    if (widget.text != old.text) _fadeAfterLayout();
    if (!widget.active) {
      _stop();
    } else if (widget.complete && (!old.complete || widget.text != old.text)) {
      _finalize();
    } else {
      _nudge();
    }
  }

  void _finalize() {
    _estimate = estimateSpeechSeconds(widget.text);
    _estimateClock
      ..stop()
      ..reset();
    _nudge();
  }

  /// The content may have grown: run, once it overflows, if the text is
  /// complete or the speech has a clock.
  void _nudge() {
    if (!widget.active || _ticker.isActive) return;
    if (!widget.complete && widget.playback() == null) return;
    _last = Duration.zero;
    _ticker.start();
  }

  /// Seconds of speech left: the player's, or the estimate's.
  double _remaining() {
    final playback = widget.playback();
    if (playback != null && playback.duration > 0) {
      // A live clock replaces the estimate: re-base it, so that if the
      // speech ends early the estimate does not resume midway.
      _estimateClock
        ..stop()
        ..reset();
      return playback.duration - playback.elapsed;
    }
    if (_estimate == 0) return 0;
    if (!_estimateClock.isRunning) _estimateClock.start();
    return _estimate - _estimateClock.elapsedMicroseconds / 1e6;
  }

  void _stop() {
    _ticker.stop();
    _last = Duration.zero;
  }

  void _tick(Duration elapsed) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final max = position.maxScrollExtent;
    // Nothing overflows (yet): growth nudges it again.
    if (max <= 0) return _stop();
    if (_last == Duration.zero) {
      _last = elapsed;
      if (_speed == 0) _speed = _startSpeed;
      return;
    }
    var frame = elapsed - _last;
    if (frame > _maxFrame) frame = _maxFrame;
    _last = elapsed;
    final dt = frame.inMicroseconds / 1e6;
    final remaining = _remaining();
    final pos = position.pixels;
    final left = max - pos;
    if (remaining > 0.1 && left > 0) {
      final target = (left / remaining).clamp(_minSpeed, _maxSpeed);
      final ease = 1 - math.pow(1 - _ease, dt * 60).toDouble();
      _speed += (target - _speed) * ease;
    }
    final next = math.min(max, pos + _speed * dt);
    _controller.jumpTo(next);
    // At the end; text that grows past it restarts the scroll.
    if (next >= max) _stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollMetrics metrics) {
    final fade = math.max(1.0, widget.fade);
    final top = (metrics.pixels / fade).clamp(0.0, 1.0);
    final bottom = ((metrics.maxScrollExtent - metrics.pixels) / fade).clamp(
      0.0,
      1.0,
    );
    if (top != _top || bottom != _bottom) {
      setState(() {
        _top = top;
        _bottom = bottom;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) => _onScroll(n.metrics),
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (n) => _onScroll(n.metrics),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              final edge = bounds.height > 0
                  ? (widget.fade / bounds.height).clamp(0.0, 0.5)
                  : 0.0;
              // Opacity rises with the square of the distance from the
              // edge: a straight ramp leaves the outer rows at a visible
              // tenth or so, a faint line of the next row's tops.
              const steps = [0.0, 0.25, 0.5, 0.75, 1.0];
              Color at(double amount, double t) =>
                  Color.fromRGBO(0, 0, 0, 1 - amount * (1 - t * t));
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  for (final t in steps) at(_top, t),
                  for (final t in steps.reversed) at(_bottom, t),
                ],
                stops: [
                  for (final t in steps) edge * t,
                  for (final t in steps.reversed) 1 - edge * t,
                ],
              ).createShader(bounds);
            },
            // The mask covers the box exactly, and where its edge falls
            // inside a pixel (a fractional device scale) that row is only
            // partly masked: the text stops a pixel short of it.
            child: ClipRect(
              clipper: const _InsetClip(),
              child: SingleChildScrollView(
                controller: _controller,
                physics: const ClampingScrollPhysics(),
                child: widget.child,
              ),
            ),
          ),
        ),
      );
}

/// A box's rect less a pixel at the top and the bottom.
class _InsetClip extends CustomClipper<Rect> {
  const _InsetClip();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 1, size.width, math.max(1, size.height - 1));

  @override
  bool shouldReclip(_InsetClip oldClipper) => false;
}
