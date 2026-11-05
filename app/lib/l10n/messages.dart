import 'generated/setup_text_ids.dart';
import 'generated/voice_text_ids.dart';
import 'generated/esphome_text_ids.dart';
import 'generated/support_text_ids.dart';
import 'generated/fleet_text_ids.dart';
import 'generated/plugin_text_ids.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../managers/alarms/alarm_model.dart';
import '../managers/settings/definitions.dart';
import 'generated/message_lookup.dart';
import 'generated/media_text_ids.dart';
import 'generated/intercom_text_ids.dart';
import 'generated/kiosk_text_ids.dart';
import 'generated/launcher_text_ids.dart';
import 'generated/gesture_text_ids.dart';
import 'generated/navigation_ids.dart';
import 'generated/device_text_ids.dart';
import 'generated/ha_text_ids.dart';
import 'generated/screensaver_text_ids.dart';
import 'generated/camera_text_ids.dart';
import 'generated/camera_streams_text_ids.dart';
import 'generated/screen_audio_text_ids.dart';
import 'generated/setting_option_ids.dart';
import 'generated/ui_strings.dart';

final _english = lookupUiStrings(const Locale('en'));

/// Standalone widgets and untranslated font locales use English messages.
UiStrings l10n(BuildContext context) => UiStrings.of(context) ?? _english;

String? localizeBaseUrlError(UiStrings strings, String? error) {
  final english = lookupUiStrings(const Locale('en'));
  if (error == english.baseUrlInvalid) return strings.baseUrlInvalid;
  if (error == english.baseUrlPath) return strings.baseUrlPath;
  if (error == english.baseUrlQuery) return strings.baseUrlQuery;
  return error;
}

/// Keep the framework locale for CJK glyphs while messages fall back separately.
class MessageDelegate extends LocalizationsDelegate<UiStrings> {
  const MessageDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<UiStrings> load(Locale locale) => SynchronousFuture(
    lookupUiStrings(
      basicLocaleListResolution(
        [locale],
        const [
          // Generated locales are alphabetical. Keep English as the fallback.
          Locale('en'),
          ...UiStrings.supportedLocales,
        ],
      ),
    ),
  );

  @override
  bool shouldReload(MessageDelegate old) => false;
}

extension LocalizedSetting on SettingDef<Object> {
  String localizedTitle(BuildContext context) => switch (key) {
    'voice.timer_named_phrase' => l10n(
      context,
    ).settingVoiceTimerNamedPhraseTitle,
    'alarms.phrase' => l10n(context).alarmsPhrase,
    _ => messageById(l10n(context), titleMessageId, title),
  };

  String localizedDescription(BuildContext context) => switch (key) {
    // Its description shows the {name} token itself, which a settings
    // message cannot carry: the token goes in as the placeholder's value.
    'voice.timer_named_phrase' => l10n(
      context,
    ).settingVoiceTimerNamedPhraseDescription('{name}'),
    'alarms.phrase' => l10n(
      context,
    ).alarmsPhraseVariables(alarmPhraseVariables),
    _ => messageById(l10n(context), descriptionMessageId, description),
  };
}

/// Translate menu presentation while keeping category and route keys stable.
String navigationText(BuildContext context, String english) =>
    messageById(l10n(context), navigationMessageIds[english], english);

/// Resolve fixed Device page wording without translating supplied values.
String deviceText(BuildContext context, String english) =>
    messageById(l10n(context), deviceTextMessageIds[english], english);

/// Translate known device failures while preserving unknown diagnostic details.
String deviceOperationError(BuildContext context, String error) {
  final strings = l10n(context);
  String? translate(String text, int depth) {
    if (depth > 8) return null;
    for (final prefix in ['Bad state: ', 'Exception: ']) {
      if (text.startsWith(prefix)) {
        return translate(text.substring(prefix.length), depth + 1);
      }
    }
    final platform = RegExp(
      r'^(PlatformException\([^,]+, )([\s\S]*)(, null, null\))$',
    ).firstMatch(text);
    if (platform != null) {
      final detail = translate(platform.group(2)!, depth + 1);
      return detail == null
          ? null
          : '${platform.group(1)}$detail${platform.group(3)}';
    }
    const aliases = <String, String>{
      "the device admin permission is not active":
          "The device admin permission is not active.",
      "restart is Android-only": "Restart is only available on Android.",
      "a download is already running":
          "A download is running. Wait for it to finish.",
      "an install is already running":
          "An install is running. Wait for it to finish.",
      "An update is being installed. Try again when it finishes.":
          "An install is running. Wait for it to finish.",
      "no update available": "No update is available.",
      "no uploaded APK is waiting": "No uploaded APK is waiting.",
      "Shizuku command timed out": "Command timed out",
    };
    text = aliases[text] ?? text;
    final id = deviceTextMessageIds[text];
    if (id != null) return messageById(strings, id, text);
    RegExpMatch? match;
    match = RegExp(r'^restart failed: ([\s\S]*)$').firstMatch(text);
    if (match != null) {
      return strings.deviceRestartFailed(
        translate(match.group(1)!, depth + 1) ?? match.group(1)!,
      );
    }
    match = RegExp(
      r'^Not enough free space: the APK is (.+) MB and the install needs about (.+) MB, but the device has (.+) MB free\.$',
    ).firstMatch(text);
    if (match != null) {
      return strings.updateUploadSpace(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
      );
    }
    match = RegExp(
      r'^The upload was interrupted after (.+) MB: ([\s\S]*)$',
    ).firstMatch(text);
    if (match != null) {
      return strings.updateUploadInterrupted(
        match.group(1)!,
        translate(match.group(2)!, depth + 1) ?? match.group(2)!,
      );
    }
    match = RegExp(
      r'^The upload ended early: (.+) of (.+) MB arrived\.$',
    ).firstMatch(text);
    if (match != null) {
      return strings.updateUploadEarly(match.group(1)!, match.group(2)!);
    }
    match = RegExp(
      r'^The APK is (.+), not Kiosk Satellite \((.+)\)\.$',
    ).firstMatch(text);
    if (match != null) {
      return strings.updateWrongPackage(
        match.group(1) == 'another package'
            ? strings.updateAnotherPackage
            : match.group(1)!,
        match.group(2)!,
      );
    }
    match = RegExp(
      r'^The APK is version (.+) \(build (.+)\), older than the running (.+) \(build (.+)\). Downgrades are refused: Android would not install one either\.$',
    ).firstMatch(text);
    if (match != null) {
      return strings.updateOlderBuild(
        match.group(1)!,
        match.group(2)!,
        match.group(3)!,
        match.group(4)!,
      );
    }
    match = RegExp(r'^Download failed \(HTTP ([0-9]+)\)\.$').firstMatch(text);
    if (match != null) {
      return strings.updateDownloadHttpFailed(match.group(1)!);
    }
    match = RegExp(
      r'^The download stalled: no data arrived for ([0-9]+) seconds\.$',
    ).firstMatch(text);
    if (match != null) {
      return strings.updateDownloadStalled(match.group(1)!);
    }
    match = RegExp(r'^Update failed: ([\s\S]*)$').firstMatch(text);
    if (match != null) {
      return strings.deviceUpdateFailedDetail(
        translate(match.group(1)!, depth + 1) ?? match.group(1)!,
      );
    }
    match = RegExp(r'^Install failed: ([\s\S]*)$').firstMatch(text);
    if (match != null) {
      return strings.deviceInstallFailedDetail(
        translate(match.group(1)!, depth + 1) ?? match.group(1)!,
      );
    }
    return null;
  }

  return translate(error, 0) ?? error;
}

/// Resolve fixed Home Assistant settings wording, never supplied names or paths.
String haText(BuildContext context, String english) =>
    messageById(l10n(context), haTextMessageIds[english], english);

/// Resolve Screen & Audio wording while keeping hardware names unchanged.
String screenAudioText(BuildContext context, String english) =>
    messageById(l10n(context), screenAudioTextMessageIds[english], english);

/// Resolve fixed screensaver wording without translating supplied values.
String screensaverText(BuildContext context, String english) =>
    messageById(l10n(context), screensaverTextMessageIds[english], english);

/// Translate playback notices when rendered, preserving paths and server details.
String screensaverPlaybackNotice(BuildContext context, String error) {
  final strings = l10n(context);
  const retry = ' Retrying automatically.';
  if (error.endsWith(retry)) {
    return strings.screensaverRetryNotice(
      immichError(context, error.substring(0, error.length - retry.length)),
    );
  }
  const empty = 'No photos or videos in ';
  if (error.startsWith(empty)) {
    return strings.screensaverFolderEmpty(error.substring(empty.length));
  }
  const unreadable = 'Could not read ';
  const permission = '. Is the media permission granted?';
  if (error.startsWith(unreadable) && error.endsWith(permission)) {
    return strings.screensaverFolderUnreadable(
      error.substring(unreadable.length, error.length - permission.length),
    );
  }
  return immichError(context, error);
}

/// Resolve camera presentation while preserving addresses and hardware names.
String cameraText(BuildContext context, String english) =>
    messageById(l10n(context), cameraTextMessageIds[english], english);

/// Translate media settings without changing player names or saved values.
String mediaText(BuildContext context, String english) =>
    messageById(l10n(context), mediaTextMessageIds[english], english);

/// App Launcher presentation, preserving app names and package identifiers.
String launcherText(BuildContext context, String english) =>
    messageById(l10n(context), launcherTextMessageIds[english], english);

/// Gesture editor labels, preserving stored action and trigger values.
String gestureText(BuildContext context, String english) =>
    messageById(l10n(context), gestureTextMessageIds[english], english);

/// Fixed Kiosk Mode, Lockdown Mode and Home Launcher labels.
String kioskText(BuildContext context, String english) =>
    messageById(l10n(context), kioskTextMessageIds[english], english);

/// Fixed Intercom labels. Kiosk names and message content bypass this helper.
String intercomText(BuildContext context, String english) =>
    messageById(l10n(context), intercomTextMessageIds[english], english);

String intercomError(
  BuildContext context,
  String error, {
  Map<String, Object?>? status,
}) {
  final call = status?['call'];
  final targets = call is Map ? call['targets'] : null;
  if (targets is List && targets.isNotEmpty && targets.every((t) => t is Map)) {
    String label(Object? value) =>
        const <String, String>{
          'listening': 'listening',
          'busy': 'busy',
          'dnd': 'do not disturb',
          'off': 'intercom off',
          'refused': 'announcements off',
          'key': 'a different key',
          'tls':
              'Encryption mismatch. Enable Encrypt communications on all kiosks in the call.',
          'unreachable': 'unreachable',
          'left': 'done',
        }['$value'] ??
        '$value';
    final original = targets
        .map((t) => "${t['name']}: ${label(t['status'])}")
        .join(', ');
    if (error == original) {
      return targets
          .map(
            (t) =>
                "${t['name']}: ${intercomError(context, label(t['status']))}",
          )
          .join(', ');
    }
  }
  return intercomText(context, intercomErrorLabel(error));
}

String intercomErrorLabel(String error) =>
    const <String, String>{
      'ended': 'Call ended',
      'declined': 'Declined',
      'cancelled': 'Cancelled',
      'busy': 'Busy',
      'do not disturb': 'Do not disturb',
      'its intercom is off': 'Its intercom is off',
      'a different intercom key': 'Different intercom key',
      'no answer': 'No answer',
      'missed': 'Missed call',
      'did not answer': 'Did not answer',
      'the voice link failed': 'The voice link failed',
      'the page took the microphone': 'The page took the microphone',
      'nobody could take it': 'Nobody could take it',
      'the broadcast ended': 'Done',
      'listening': 'Listening',
      'intercom off': 'Intercom off',
      'announcements off': 'Announcements off',
      'a different key': 'Different key',
      'unreachable': 'Unreachable',
      'done': 'Done',
    }[error] ??
    error;

String intercomAnnouncing(BuildContext context, int count) => count == 1
    ? l10n(context).intercomAnnouncingOne
    : l10n(context).intercomAnnouncingMany('$count');

String mediaError(BuildContext context, String error) {
  final sonos = RegExp(
    r'^No Sonos answered at (.*)\.$',
    dotAll: true,
  ).firstMatch(error);
  if (sonos != null) return l10n(context).mediaSonosUnreachable(sonos[1]!);
  const ha = 'Home Assistant did not answer: ';
  if (error.startsWith(ha)) {
    return l10n(context).mediaHaFailed(error.substring(ha.length));
  }
  const connected = 'Connected to Music Assistant ';
  if (error.startsWith(connected)) {
    return l10n(
      context,
    ).mediaConnectedVersion(error.substring(connected.length));
  }
  final unreachable = RegExp(
    r'^Could not reach (.+?): (.*)$',
    dotAll: true,
  ).firstMatch(error);
  if (unreachable != null) {
    return l10n(context).mediaUnreachable(unreachable[1]!, unreachable[2]!);
  }
  return mediaText(context, error);
}

String cameraStreamsText(BuildContext context, String english) =>
    messageById(l10n(context), cameraStreamsTextMessageIds[english], english);

String cameraStreamsError(BuildContext context, String error) {
  final http = RegExp(r'^Go2RTC returned HTTP (\d+)$').firstMatch(error);
  if (http != null) return l10n(context).cameraStreamsHttpError(http[1]!);
  const haPrefix = 'could not read Home Assistant: ';
  if (error.startsWith(haPrefix)) {
    return l10n(
      context,
    ).cameraStreamsHaReadFailed(error.substring(haPrefix.length));
  }
  final connection = RegExp(
    r'^could not connect to (.+?): (.*)$',
    dotAll: true,
  ).firstMatch(error);
  if (connection != null) {
    return l10n(
      context,
    ).cameraStreamsConnectFailed(connection[1]!, connection[2]!);
  }
  return cameraStreamsText(context, error);
}

String cameraError(BuildContext context, String error) =>
    error.startsWith('Snapshot failed: ')
    ? l10n(
        context,
      ).cameraSnapshotError(error.substring('Snapshot failed: '.length))
    : cameraText(context, error);

String cameraResolutionNotice(BuildContext context, String notice) {
  final strings = l10n(context);
  notice = notice.replaceAll(
    'Motion detection, face detection and hand gestures pause while viewers are connected. Snapshots use video frames at the streaming resolution.',
    strings.cameraAnalysisOff,
  );
  return notice
      .split(RegExp(r'(?<=\.) '))
      .map((part) {
        final extra = RegExp(
          r'^Turn off Motion analysis while streaming to also use (.+)\.$',
        ).firstMatch(part);
        if (extra != null) return strings.cameraExtraSizes(extra[1]!);
        final rejected = RegExp(
          r'^The encoder cannot use (.+) at these settings\.$',
        ).firstMatch(part);
        if (rejected != null) return strings.cameraRejectedSizes(rejected[1]!);
        final count = RegExp(
          r'^(\d+) camera sizes are excluded because the encoder cannot use them at these settings\.$',
        ).firstMatch(part);
        if (count != null) return strings.cameraRejectedCount(count[1]!);
        return cameraText(context, part);
      })
      .join(' ');
}

String screensaverError(BuildContext context, String error) {
  final match = RegExp(r'^Use at most ([0-9]+) characters$').firstMatch(error);
  return match == null
      ? screensaverText(context, error)
      : l10n(context).screensaverMaxCharacters(match[1]!);
}

String settingsPageText(
  BuildContext context,
  String category,
  String english,
) => switch (category) {
  'About' => supportText(context, english),
  'Voice Satellite' => voiceText(context, english),
  'ESPHome' => esphomeText(context, english),
  'Device' => deviceText(context, english),
  'Home Assistant' => haText(context, english),
  'Screen & Audio' => screenAudioText(context, english),
  'Screensaver' => screensaverText(context, english),
  'Camera' => cameraText(context, english),
  'Sendspin' => mediaText(context, english),
  'Launcher' => launcherText(context, english),
  'Gestures' => gestureText(context, english),
  // Its groups are named after the pages of the features they light up.
  'LED Control' => navigationText(context, english),
  'Kiosk' || 'Home' || 'Lockdown' => kioskText(context, english),
  // Its groups reuse the settings rail's group names.
  'Calendar' => switch (english) {
    'Display' || 'Kiosk' => navigationText(context, english),
    'Editing' => l10n(context).calendarEditingSection,
    // The hand-built rows search finds.
    'Open calendar' => l10n(context).calendarOpen,
    'Show the calendar on this kiosk.' => l10n(context).calendarOpenHint,
    'Add a calendar' => l10n(context).calendarAdd,
    'Add the Home Assistant calendars to show in Settings > Calendar.' => l10n(
      context,
    ).calendarEmptyHint,
    'Voice Calendar' => l10n(context).calendarVoiceSection,
    'Manage the calendar using Voice Satellite' => l10n(
      context,
    ).calendarVoiceManage,
    'Needs the Kiosk Satellite calendar blueprint and an LLM conversation '
        'agent in Home Assistant.' =>
      l10n(context).calendarVoiceHint,
    _ => english,
  },
  'Alarms' => switch (english) {
    'Defaults' => l10n(context).alarmsDefaultsSection,
    'Text to Speech' => l10n(context).alarmsTtsSection,
    'Voice Alarms' => l10n(context).alarmsVoiceSection,
    'Manage alarms using Voice Satellite' => l10n(context).alarmsVoiceManage,
    'Needs the Kiosk Satellite alarms blueprint and an LLM conversation '
        'agent in Home Assistant.' =>
      l10n(context).alarmsVoiceHint,
    _ => english,
  },
  'Browser' => switch (english) {
    'URL Filter' => l10n(context).urlFilterTitle,
    'Block or allow pages by address pattern or regular expression' => l10n(
      context,
    ).urlFilterHint,
    'Add rule' => l10n(context).urlFilterAdd,
    'Show blocked page notice' => l10n(
      context,
    ).settingBrowserUrlFilterNoticeTitle,
    "Show a short notice with the rule's name when a page is blocked." => l10n(
      context,
    ).settingBrowserUrlFilterNoticeDescription,
    "Links or pages that match a Block rule don't load. Add an Allow only rule to load only the pages it matches." =>
      l10n(context).urlFilterIntroSub,
    _ => english,
  },
  'Intercom' => switch (english) {
    'Answer' => l10n(context).intercomAnswerSection,
    'Talk' => l10n(context).intercomTalkSection,
    'Video' => l10n(context).intercomVideoSection,
    _ => intercomText(context, english),
  },
  _ => english,
};

String haConnectionError(BuildContext context, String error) =>
    error.startsWith('unreachable: ')
    ? l10n(context).haUnreachable(error.substring('unreachable: '.length))
    : haText(context, error);

extension LocalizedSettingChoices on SettingDef<Object> {
  String localizedOption(BuildContext context, String value, String fallback) =>
      messageById(
        l10n(context),
        settingOptionMessageIds[key]?[value],
        fallback,
      );
  String? localizedPlaceholder(BuildContext context) => placeholder == null
      ? null
      : messageById(
          l10n(context),
          settingPlaceholderMessageIds[key],
          placeholder!,
        );
}

String localizedRemoteReason(BuildContext context, String reason) {
  final match = RegExp(
    r'^Could not listen on port ([0-9]+): ([\s\S]*)$',
  ).firstMatch(reason);
  return match == null
      ? deviceText(context, reason)
      : l10n(context).devicePortError(match[1]!, match[2]!);
}

String commonColorName(BuildContext context, String english) =>
    switch (english) {
      'White' => l10n(context).commonColorWhite,
      'Warm' => l10n(context).commonColorWarm,
      'Amber' => l10n(context).commonColorAmber,
      'Red' => l10n(context).commonColorRed,
      'Green' => l10n(context).commonColorGreen,
      'Blue' => l10n(context).commonColorBlue,
      'Cyan' => l10n(context).commonColorCyan,
      'Dim' => l10n(context).commonColorDim,
      _ => english,
    };

String immichError(BuildContext context, String error) {
  final strings = l10n(context);
  if (error == 'Could not reach the Immich server.') {
    return strings.screensaverImmichUnreachable;
  }
  final scope = RegExp(
    r'^The API key is missing the (.+) permission\.$',
  ).firstMatch(error);
  if (scope != null) return strings.screensaverMediaScopeMissing(scope[1]!);
  const permission = 'The API key is missing a permission: ';
  if (error.startsWith(permission)) {
    return strings.screensaverMediaPermissionMissing(
      error.substring(permission.length),
    );
  }
  final status = RegExp(
    r'^The server answered ([0-9]+): ([\s\S]*)$',
  ).firstMatch(error);
  if (status != null) {
    return strings.screensaverMediaServerError(status[1]!, status[2]!);
  }
  final url = RegExp(r'^Could not reach ([\s\S]+)\.$').firstMatch(error);
  if (url != null) return strings.screensaverMediaUnreachable(url[1]!);
  const talk = 'Could not talk to the server: ';
  if (error.startsWith(talk)) {
    return strings.screensaverMediaTalkError(error.substring(talk.length));
  }
  return screensaverText(context, error);
}

/// Fleet labels. Stored profile names and identifiers stay unchanged.
String fleetText(BuildContext context, String english) =>
    messageById(l10n(context), fleetTextMessageIds[english], english);

/// Application-owned plugin labels. Community content stays unchanged.
String pluginText(BuildContext context, String english) =>
    messageById(l10n(context), pluginTextMessageIds[english], english);

/// App-owned Logs and About labels, excluding diagnostic and provider data.
String supportText(BuildContext context, String english) =>
    messageById(l10n(context), supportTextMessageIds[english], english);

/// ESPHome setup labels, excluding entity names and network identifiers.
String esphomeText(BuildContext context, String english) =>
    messageById(l10n(context), esphomeTextMessageIds[english], english);

String esphomeError(BuildContext context, String english) =>
    english.startsWith('GPS unavailable: ')
    ? l10n(
        context,
      ).esphomeLocationError(english.substring('GPS unavailable: '.length))
    : esphomeText(context, english);

String esphomeDeviceIdentity(
  BuildContext context,
  Map<String, Object?> device,
) {
  final identity = '${device['identity'] ?? 'Unknown device'}';
  if ('${device['name'] ?? ''}'.trim().isNotEmpty) return identity;
  final vendor = device['vendor'];
  if (vendor != null && identity == '$vendor device') {
    return l10n(context).esphomeIdentityVendor('$vendor');
  }
  return esphomeText(context, identity);
}

/// App-owned Voice Satellite labels. Provider names and identifiers stay raw.
String voiceText(BuildContext context, String english) =>
    messageById(l10n(context), voiceTextMessageIds[english], english);

String voiceVadOption(BuildContext context, String value) => switch (value) {
  'default' => voiceText(context, 'Default'),
  'relaxed' => voiceText(context, 'Relaxed'),
  'aggressive' => voiceText(context, 'Aggressive'),
  _ => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1),
};

/// Translate only integration-defined options, never user model names.
String voiceEntityOption(BuildContext context, String key, String value) {
  if (key == 'vad_sensitivity') return voiceVadOption(context, value);
  if (key == 'wake_word_sensitivity' &&
      const [
        'Slightly sensitive',
        'Moderately sensitive',
        'Very sensitive',
      ].contains(value)) {
    return voiceText(context, value);
  }
  if (key == 'wake_word_detection') {
    if (value == 'Disabled' || value == 'On Device') {
      return voiceText(context, value);
    }
    for (final engine in const [
      'microWakeWord',
      'openWakeWord',
      'vsWakeWord',
    ]) {
      if (value == 'On Device ($engine)') {
        return l10n(context).voiceOnDeviceEngine(engine);
      }
    }
  }
  if (key == 'wake_word_model_2' && value == 'Disabled') {
    return voiceText(context, value);
  }
  return value;
}

/// Setup instructions and built-in options, excluding Home Assistant names.
String setupText(BuildContext context, String english) =>
    messageById(l10n(context), setupTextMessageIds[english], english);

String setupImportError(BuildContext context, String error) {
  final english = const {
    'config must be an object': 'The backup must contain a JSON object.',
    'not a Kiosk Satellite configuration file':
        'This is not a Kiosk Satellite configuration file.',
    'no settings in file': 'The backup contains no settings.',
  }[error];
  return english == null ? error : setupText(context, english);
}

/// Unwrap only recognized application errors and preserve other diagnostics.
String _ownedError(String error, String? Function(String) lookup) {
  String? translate(String text, int depth) {
    if (depth > 8) return null;
    final direct = lookup(text);
    if (direct != null) return direct;
    for (final prefix in [
      'Bad state: ',
      'FormatException: ',
      'Exception: ',
      'Error: ',
    ]) {
      if (text.startsWith(prefix)) {
        return translate(text.substring(prefix.length), depth + 1);
      }
    }
    final platform = RegExp(
      r'^(PlatformException\([^,]+, )([\s\S]*)(, null, null\))$',
    ).firstMatch(text);
    if (platform != null) {
      final detail = translate(platform.group(2)!, depth + 1);
      return detail == null
          ? null
          : '${platform.group(1)}$detail${platform.group(3)}';
    }
    return null;
  }

  return translate(error, 0) ?? error;
}

String launcherError(BuildContext context, String error) => _ownedError(error, (
  text,
) {
  final strings = l10n(context);
  final id = launcherTextMessageIds[text] ?? deviceTextMessageIds[text];
  if (id != null) return messageById(strings, id, text);
  final match = RegExp(r'^could not list apps: ([\s\S]*)$').firstMatch(text);
  return match == null
      ? null
      : strings.launcherErrorListDetail(match.group(1)!);
});

String pluginError(BuildContext context, String error) => _ownedError(error, (
  text,
) {
  final strings = l10n(context);
  final id = pluginTextMessageIds[text] ?? deviceTextMessageIds[text];
  if (id != null) return messageById(strings, id, text);

  final update = RegExp(
    r'^Plugin update failed: ([\s\S]*?)\. (The previous version [\s\S]*)$',
  ).firstMatch(text);
  if (update != null) {
    final recovery = update.group(2)!;
    final failed = RegExp(
      r'^The previous version could not restart: ([\s\S]*)$',
    ).firstMatch(recovery);
    return strings.pluginErrorUpdateFailed(
      update.group(1)!,
      failed == null
          ? pluginText(context, recovery)
          : strings.pluginErrorPreviousRestart(failed.group(1)!),
    );
  }
  final read = RegExp(
    r'^Cannot read installed plugin: ([\s\S]*)$',
  ).firstMatch(text);
  if (read != null) return strings.pluginErrorReadInstalled(read.group(1)!);
  RegExpMatch? match;
  match = RegExp(r'^GitHub request failed \(([0-9]+)\)$').firstMatch(text);
  if (match != null) return strings.pluginErrorGithubRequest(match.group(1)!);
  match = RegExp(
    r'^Release needs exactly one uploaded (.+) asset$',
  ).firstMatch(text);
  if (match != null) return strings.pluginErrorReleaseAsset(match.group(1)!);
  match = RegExp(
    r'^Release asset (.+) must be published by GitHub Actions\. Manually uploaded files are not supported\.$',
  ).firstMatch(text);
  if (match != null) return strings.pluginErrorAssetPublisher(match.group(1)!);
  match = RegExp(
    r'^Release asset (.+) exceeds the size limit or is empty$',
  ).firstMatch(text);
  if (match != null) return strings.pluginErrorAssetSize(match.group(1)!);
  match = RegExp(r'^Invalid release URL for (.+)$').firstMatch(text);
  if (match != null) return strings.pluginErrorAssetUrl(match.group(1)!);
  match = RegExp(r'^Plugin needs Android API ([0-9]+)$').firstMatch(text);
  if (match != null) return strings.pluginErrorAndroidApi(match.group(1)!);
  match = RegExp(
    r'^Plugin needs Kiosk Satellite (\S+) or newer\. This kiosk runs (\S*)\.$',
  ).firstMatch(text);
  if (match != null) {
    return strings.pluginErrorAppVersion(match.group(1)!, match.group(2)!);
  }
  match = RegExp(
    r'^Invalid (id|name|version|entryClass|description|author|license|key|title|group|readingsTitle|input|minAppVersion)$',
  ).firstMatch(text);
  if (match != null) return strings.pluginErrorInvalidField(match.group(1)!);
  match = RegExp(
    r'^Unexpected or duplicate ZIP entry: ([\s\S]*)$',
  ).firstMatch(text);
  if (match != null) return strings.pluginErrorZipEntry(match.group(1)!);
  return null;
});
