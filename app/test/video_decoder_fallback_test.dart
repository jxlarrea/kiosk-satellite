import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/core/command_registry.dart';
import 'package:kiosk_satellite/core/event_bus.dart';
import 'package:kiosk_satellite/core/logging.dart';
import 'package:kiosk_satellite/managers/dlna/dlna_manager.dart';
import 'package:kiosk_satellite/managers/settings/settings_manager.dart';
import 'package:kiosk_satellite/ui/video_surface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Issue #374: a MediaTek AVC decoder that cannot allocate buffers against
/// Flutter's texture surface, and what the player does about it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isVideoDecoderFailure', () {
    // The exact string an Echo Show 8 produced, through the plugin.
    const echoShow =
        'PlatformException(VideoError, Video player had error l2.k: '
        'MediaCodecVideoRenderer error, index=0, format=Format(1, null, '
        'video/mp4, video/avc, avc1.64001F, 3200000, und, [1280, 720, '
        '25.0, ColorInfo(...)], [-1, -1]), format_supported=YES, null, '
        'null)';

    test('matches a decoder that refused to start', () {
      expect(isVideoDecoderFailure(echoShow), isTrue);
      expect(
        isVideoDecoderFailure('Decoder init failed: OMX.MTK.VIDEO.DECODER.AVC'),
        isTrue,
      );
      expect(
        isVideoDecoderFailure('DecoderInitializationException: ...'),
        isTrue,
      );
    });

    test('leaves a URL or a network failure alone', () {
      expect(
        isVideoDecoderFailure(
          'PlatformException(VideoError, Video player had error l2.k: '
          'Source error, null, null)',
        ),
        isFalse,
      );
      expect(
        isVideoDecoderFailure('UnrecognizedInputFormatException'),
        isFalse,
      );
    });
  });

  group('openVideo', () {
    test('takes the texture surface when it works', () async {
      final asked = <VideoViewType>[];
      final controller = await openVideo((viewType) {
        asked.add(viewType);
        return FakeVideoController();
      });
      expect(asked, [VideoViewType.textureView]);
      expect((controller as FakeVideoController).disposed, isFalse);
    });

    test('retries once on a platform view after a decoder failure', () async {
      final asked = <VideoViewType>[];
      Object? reported;
      final controller = await openVideo((viewType) {
        asked.add(viewType);
        return FakeVideoController(
          failure: viewType == VideoViewType.textureView
              ? 'MediaCodecVideoRenderer error'
              : null,
        );
      }, onFallback: (e) => reported = e);
      expect(asked, [VideoViewType.textureView, VideoViewType.platformView]);
      expect(reported.toString(), contains('MediaCodecVideoRenderer'));
      expect((controller as FakeVideoController).disposed, isFalse);
    });

    test('does not retry a failure that is not the decoder', () async {
      final asked = <VideoViewType>[];
      await expectLater(
        openVideo((viewType) {
          asked.add(viewType);
          return FakeVideoController(failure: 'Source error');
        }),
        throwsA(isA<String>()),
      );
      expect(asked, [VideoViewType.textureView]);
    });

    test('gives up when the platform view fails too', () async {
      final built = <FakeVideoController>[];
      await expectLater(
        openVideo((viewType) {
          final c = FakeVideoController(failure: 'Decoder init failed');
          built.add(c);
          return c;
        }),
        throwsA(isA<String>()),
      );
      expect(built.length, 2);
      // Neither attempt is left holding a codec.
      expect(built.every((c) => c.disposed), isTrue);
    });
  });

  group('DlnaManager failure reporting', () {
    late DlnaManager dlna;
    late Logger log;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final bus = EventBus();
      log = Logger();
      final commands = CommandRegistry(log);
      final settings = SettingsManager(bus, commands, log);
      await settings.init();
      dlna = DlnaManager(bus, commands, log, settings);
      dlna.media.value = const DlnaMedia(
        uri: 'http://x/y.mp4',
        kind: 'video',
        metadata: '',
      );
      dlna.transportState.value = 'PLAYING';
    });

    test('logs the reason a player failed', () {
      dlna.reportPlaybackFailure('http://x/y.mp4', 'Decoder init failed');
      expect(
        log.recent.any(
          (e) => e.message.contains('playback failed: Decoder init failed'),
        ),
        isTrue,
      );
    });

    test('a failure stops the transport so the controller lets go', () {
      fakeAsync((async) {
        dlna.reportPlaybackFailure('http://x/y.mp4', 'Decoder init failed');
        // The card stays up long enough to be read.
        async.elapse(const Duration(seconds: 3));
        expect(dlna.transportState.value, 'PLAYING');
        async.elapse(const Duration(seconds: 4));
        expect(dlna.transportState.value, 'STOPPED');
        expect(dlna.media.value, isNull);
      });
    });

    test('a stale failure never stops the media that replaced it', () {
      fakeAsync((async) {
        dlna.reportPlaybackFailure('http://x/old.mp4', 'Decoder init failed');
        async.elapse(const Duration(seconds: 10));
        expect(dlna.transportState.value, 'PLAYING');
      });
    });

    test('the fallback is logged, and only for the live media', () {
      dlna.reportDecoderFallback('http://x/y.mp4', 'MediaCodecVideoRenderer');
      dlna.reportDecoderFallback(
        'http://x/gone.mp4',
        'MediaCodecVideoRenderer',
      );
      expect(
        log.recent
            .where((e) => e.message.contains('retrying on a platform view'))
            .length,
        1,
      );
    });
  });
}

/// A controller that never touches the platform: [initialize] either
/// succeeds or throws whatever [failure] says, which is all openVideo
/// looks at.
class FakeVideoController extends VideoPlayerController {
  FakeVideoController({this.failure})
    : super.networkUrl(Uri.parse('http://example.invalid/v.mp4'));

  final String? failure;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    if (failure != null) throw failure!;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }
}
