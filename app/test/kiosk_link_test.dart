import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_satellite/managers/kiosk/kiosk_link.dart';

void main() {
  group('kioskLinkAction', () {
    test('names the kiosk features a gesture can', () {
      expect(kioskLinkAction('ks://apps'), {'type': 'app_launcher'});
      expect(kioskLinkAction('ks://launcher'), {'type': 'app_launcher'});
      expect(kioskLinkAction('ks://now-playing'), {'type': 'now_playing'});
      expect(kioskLinkAction('ks://player'), {'type': 'sendspin_player'});
      expect(kioskLinkAction('ks://music-assistant'), {
        'type': 'music_assistant',
      });
      expect(kioskLinkAction('ks://screensaver'), {'type': 'screensaver'});
      expect(kioskLinkAction('ks://screensaver/stop'), {
        'type': 'screensaver_stop',
      });
      expect(kioskLinkAction('ks://intercom'), {'type': 'intercom_open'});
      expect(kioskLinkAction('ks://hold'), {'type': 'hold_mode'});
      expect(kioskLinkAction('ks://ha-kiosk'), {'type': 'ha_kiosk'});
      expect(kioskLinkAction('ks://android-settings'), {
        'type': 'android_settings',
      });
      expect(kioskLinkAction('ks://alarms'), {'type': 'alarms'});
      expect(kioskLinkAction('ks://alarms/next'), {'type': 'alarm_next'});
      expect(kioskLinkAction('ks://calendar'), {'type': 'calendar'});
      expect(kioskLinkAction('ks://calendar/month'), {
        'type': 'calendar',
        'view': 'month',
      });
      expect(kioskLinkAction('ks://calendar/year'), isNull);
      expect(kioskLinkAction('ks://music-library'), {'type': 'music_library'});
      expect(kioskLinkAction('ks://music-library/albums'), isNull);
      expect(kioskLinkAction('ks://voice'), {'type': 'voice_wake'});
      expect(kioskLinkAction('ks://voice/stop'), {'type': 'voice_stop'});
      expect(kioskLinkAction('ks://voice/mute'), {'type': 'voice_mute'});
      expect(kioskLinkAction('ks://voice/unmute'), isNull);
    });

    test('camera links pick a view, the default view or close', () {
      expect(kioskLinkAction('ks://camera'), {
        'type': 'camera_view',
        'mode': 'show',
        'viewId': '',
      });
      expect(kioskLinkAction('ks://camera/front-door'), {
        'type': 'camera_view',
        'mode': 'show',
        'viewId': 'front-door',
      });
      expect(kioskLinkAction('ks://camera/close'), {
        'type': 'camera_view',
        'mode': 'hide',
      });
    });

    test('an intercom link with a kiosk id calls that kiosk', () {
      expect(kioskLinkAction('ks://intercom/kitchen'), {
        'type': 'intercom_call',
        'kioskId': 'kitchen',
      });
    });

    test('an intercom link ending in /video places a video call', () {
      expect(kioskLinkAction('ks://intercom/kitchen/video'), {
        'type': 'intercom_video_call',
        'kioskId': 'kitchen',
      });
      expect(kioskLinkAction('ks://intercom/Kiosk-A/Video/'), {
        'type': 'intercom_video_call',
        'kioskId': 'Kiosk-A',
      });
      expect(kioskLinkAction('ks://intercom/kitchen/voice'), isNull);
      expect(kioskLinkAction('ks://intercom/kitchen/video/x'), isNull);
      expect(kioskLinkAction('ks://intercom//video'), isNull);
    });

    test('tolerates the hostless form, a trailing slash and space', () {
      expect(kioskLinkAction('ks:apps'), {'type': 'app_launcher'});
      expect(kioskLinkAction(' ks://apps/ '), {'type': 'app_launcher'});
      expect(kioskLinkAction('KS://Apps'), {'type': 'app_launcher'});
    });

    test('keeps the case of an id and decodes it', () {
      expect(
        kioskLinkAction('ks://camera/Front%20Door')!['viewId'],
        'Front Door',
      );
      expect(kioskLinkAction('ks://intercom/Kiosk-A')!['kioskId'], 'Kiosk-A');
    });

    test('leaves other schemes alone', () {
      expect(kioskLinkAction('https://home.example/lovelace'), isNull);
      expect(kioskLinkAction('app://com.android.deskclock'), isNull);
      expect(kioskLinkAction('intent://scan/#Intent;end'), isNull);
      expect(kioskLinkAction(''), isNull);
    });

    test('refuses what the scheme does not offer', () {
      expect(kioskLinkAction('ks://'), isNull);
      expect(kioskLinkAction('ks://exit'), isNull);
      expect(kioskLinkAction('ks://restart'), isNull);
      expect(kioskLinkAction('ks://settings'), isNull);
      expect(kioskLinkAction('ks://apps/extra'), isNull);
      expect(kioskLinkAction('ks://alarms/new'), isNull);
      expect(kioskLinkAction('ks://screensaver/pause'), isNull);
      expect(kioskLinkAction('ks://camera/a/b'), isNull);
      expect(kioskLinkAction('ks://apps?x=1'), isNull);
      expect(kioskLinkAction('ks://apps#top'), isNull);
      expect(kioskLinkAction('ks://camera/%E0%A4%A'), isNull);
    });
  });
}
