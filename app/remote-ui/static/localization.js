import { isHeadless } from './headless.js';
import { setupTextMessageIds } from './setup_text_ids.js';
import { overviewTextMessageIds } from './overview_text_ids.js';
import { voiceTextMessageIds } from './voice_text_ids.js';
import { esphomeTextMessageIds } from './esphome_text_ids.js';
import { supportTextMessageIds } from './support_text_ids.js';
import { fleetTextMessageIds } from './fleet_text_ids.js';
import { pluginTextMessageIds } from './plugin_text_ids.js';
import { launcherTextMessageIds } from './launcher_text_ids.js';
import { gestureTextMessageIds } from './gesture_text_ids.js';
import { kioskTextMessageIds } from './kiosk_text_ids.js';
import { intercomTextMessageIds } from './intercom_text_ids.js';
import { mediaTextMessageIds } from './media_text_ids.js';
import { screensaverTextMessageIds } from './screensaver_text_ids.js';
import { cameraTextMessageIds } from './camera_text_ids.js';
import { cameraStreamsTextMessageIds } from './camera_streams_text_ids.js';
import { screenAudioTextMessageIds } from './screen_audio_text_ids.js';
import { catalogs } from './catalogs.js';
import { navigationMessageIds } from './navigation_ids.js';
import { deviceTextMessageIds } from './device_text_ids.js';
import { haTextMessageIds } from './ha_text_ids.js';

export function launcherText(english) {
  return t(launcherTextMessageIds[english], {}, english);
}

export function gestureText(english) {
  return t(gestureTextMessageIds[english], {}, english);
}

export function haText(english) {
  return t(haTextMessageIds[english], {}, english);
}

export function screenAudioText(english) {
  return t(screenAudioTextMessageIds[english], {}, english);
}

export function screensaverText(english) {
  return t(screensaverTextMessageIds[english], {}, english);
}

export function cameraText(english) {
  return t(cameraTextMessageIds[english], {}, english);
}

export function mediaText(english) {
  return t(mediaTextMessageIds[english], {}, english);
}

export function mediaError(error) {
  const sonos = /^No Sonos answered at (.*)\.$/s.exec(error);
  if (sonos) return t('mediaSonosUnreachable', {host: sonos[1]});
  const ha = 'Home Assistant did not answer: ';
  if (error.startsWith(ha)) return t('mediaHaFailed', {error: error.slice(ha.length)});
  const connected = 'Connected to Music Assistant ';
  if (error.startsWith(connected)) return t('mediaConnectedVersion', {version: error.slice(connected.length)});
  const unreachable = /^Could not reach (.+?): (.*)$/s.exec(error);
  if (unreachable) return t('mediaUnreachable', {host: unreachable[1], error: unreachable[2]});
  return mediaText(error);
}

export function cameraStreamsText(english) {
  return t(cameraStreamsTextMessageIds[english], {}, english);
}

export function cameraStreamsError(error) {
  const http = /^Go2RTC returned HTTP (\d+)$/.exec(error);
  if (http) return t('cameraStreamsHttpError', {status: http[1]});
  const haPrefix = 'could not read Home Assistant: ';
  if (error.startsWith(haPrefix)) return t('cameraStreamsHaReadFailed', {error: error.slice(haPrefix.length)});
  const connection = /^could not connect to (.+?): (.*)$/s.exec(error);
  if (connection) return t('cameraStreamsConnectFailed', {server: connection[1], error: connection[2]});
  return cameraStreamsText(error);
}

export function cameraError(error) {
  return error.startsWith('Snapshot failed: ')
    ? t('cameraSnapshotError', {error: error.slice('Snapshot failed: '.length)}) : cameraText(error);
}

export function cameraResolutionNotice(notice) {
  notice = notice.replace('Motion detection, face detection and hand gestures pause while viewers are connected. Snapshots use video frames at the streaming resolution.', t('cameraAnalysisOff'));
  return notice.split(/(?<=\.) /).map((part) => {
    const extra = /^Turn off Motion analysis while streaming to also use (.+)\.$/.exec(part);
    if (extra) return t('cameraExtraSizes', {sizes: extra[1]});
    const rejected = /^The encoder cannot use (.+) at these settings\.$/.exec(part);
    if (rejected) return t('cameraRejectedSizes', {sizes: rejected[1]});
    const count = /^(\d+) camera sizes are excluded because the encoder cannot use them at these settings\.$/.exec(part);
    if (count) return t('cameraRejectedCount', {count: count[1]});
    return cameraText(part);
  }).join(' ');
}

export function screensaverError(error) {
  const match = /^Use at most ([0-9]+) characters$/.exec(error);
  return match ? t('screensaverMaxCharacters', {count: match[1]}) : screensaverText(error);
}

export function settingsPageText(category, english) {
  return ['About', 'about'].includes(category) ? supportText(english)
    : ['Voice Satellite', 'voicesatellite'].includes(category) ? voiceText(english)
    : ['ESPHome', 'esphome'].includes(category) ? esphomeText(english)
    : category === 'Device' || category === 'device' ? deviceText(english)
    : category === 'Home Assistant' || category === 'homeassistant' ? haText(english)
    : category === 'Screen & Audio' || category === 'screenaudio' ? screenAudioText(english)
    : category === 'Screensaver' || category === 'screensaver' ? screensaverText(english)
    : category === 'Camera' || category === 'camera' ? cameraText(english)
    : ['Cameras', 'cameras'].includes(category) ? cameraStreamsText(english)
    : ['Launcher', 'launcher'].includes(category) ? launcherText(english)
    : ['Gestures', 'gestures'].includes(category) ? gestureText(english)
    : ['LED Control', 'leds'].includes(category) ? navigationText(english)
    : ['Fleet', 'fleet'].includes(category) ? fleetText(english)
    : ['Plugins', 'plugins'].includes(category) ? pluginText(english)
    : ['Kiosk', 'kiosk', 'Home', 'home', 'Lockdown', 'lockdown'].includes(category) ? kioskText(english)
    : category === 'Intercom' || category === 'intercom' ? (english === 'Answer' ? t('intercomAnswerSection') : english === 'Talk' ? t('intercomTalkSection') : intercomText(english))
    : category === 'Alarms' || category === 'alarms' ? alarmsPageText(english)
    // Its groups reuse the sidebar's group names.
    : category === 'Calendar' || category === 'calendar' ? calendarPageText(english)
    : category === 'Browser' || category === 'browser' ? browserPageText(english)
    : category === 'Sendspin' || category === 'sendspin' ? mediaText(english) : english;
}

// The URL Filter page's name, hint and hand-built rows, Settings > Web
// Browsing on the device (settingsPageText in messages.dart).
const BROWSER_PAGE_TEXT = {
  'URL Filter': 'urlFilterTitle',
  'Block or allow pages by address pattern or regular expression': 'urlFilterHint',
  'Add rule': 'urlFilterAdd',
  'Show blocked page notice': 'settingBrowserUrlFilterNoticeTitle',
  "Show a short notice with the rule's name when a page is blocked.": 'settingBrowserUrlFilterNoticeDescription',
  "Links or pages that match a Block rule don't load. Add an Allow only rule to load only the pages it matches.": 'urlFilterIntroSub',
};

function browserPageText(english) {
  const id = BROWSER_PAGE_TEXT[english];
  return id ? t(id) : english;
}

// The Calendar page's groups (the sidebar's group names) and the hand-built
// row search finds, Settings > Calendar on the device (settingsPageText in
// messages.dart).
const CALENDAR_PAGE_TEXT = {
  'Editing': 'calendarEditingSection',
  'Add a calendar': 'calendarAdd',
  'Add the Home Assistant calendars to show in Settings > Calendar.': 'calendarEmptyHint',
  'Voice Calendar': 'calendarVoiceSection',
  'Manage the calendar using Voice Satellite': 'calendarVoiceManage',
  'Needs the Kiosk Satellite calendar blueprint and an LLM conversation agent in Home Assistant.': 'calendarVoiceHint',
};

function calendarPageText(english) {
  if (english === 'Display' || english === 'Kiosk') return navigationText(english);
  const id = CALENDAR_PAGE_TEXT[english];
  return id ? t(id, {}, english) : english;
}

// The Alarms page's own headings and hand-built rows, Settings > Alarms
// on the device (settingsPageText in messages.dart).
const ALARMS_PAGE_TEXT = {
  'Defaults': 'alarmsDefaultsSection',
  'Text to Speech': 'alarmsTtsSection',
  'Voice Alarms': 'alarmsVoiceSection',
  'Manage alarms using Voice Satellite': 'alarmsVoiceManage',
  'Needs the Kiosk Satellite alarms blueprint and an LLM conversation agent in Home Assistant.': 'alarmsVoiceHint',
};

function alarmsPageText(english) {
  const id = ALARMS_PAGE_TEXT[english];
  return id ? t(id, {}, english) : english;
}

export function haConnectionError(error) {
  return error.startsWith('unreachable: ')
    ? t('haUnreachable', {error: error.slice('unreachable: '.length)}) : haText(error);
}

// The kiosk and remote administration share one explicit language choice.
let languagePreference = 'en';

export function setLanguagePreference(value) {
  languagePreference = Object.hasOwn(catalogs, value) ? value : 'en';
  if (globalThis.document) {
    document.documentElement.lang = languagePreference;
    localizeFooter();
  }
}

// Keep the linked author and heart as nodes while translators order the sentence.
function localizeFooter() {
  const credit = document.querySelector('.made-by-credit');
  if (!credit || credit.dataset.language === languagePreference) return;
  const focused = credit.contains(document.activeElement) ? document.activeElement : null;
  const heart = credit.querySelector('.heart');
  const author = credit.querySelector('a');
  const parts = t('settingsMadeBy', {heart: '{heart}', author: '{author}'})
    .split(/(\{heart\}|\{author\})/);
  credit.replaceChildren(...parts.map(part => part === '{heart}' ? heart
    : part === '{author}' ? author : document.createTextNode(part)));
  document.querySelector('.made-by > a').textContent = t('settingsBuyCoffee');
  credit.dataset.language = languagePreference;
  focused?.focus({preventScroll: true});
}

export function formatMessage(pattern, values = {}) {
  return pattern.replace(/\{([a-z][A-Za-z0-9]*)\}/g, (match, name) => {
    if (!Object.hasOwn(values, name)) throw new Error(`Missing message placeholder: ${name}`);
    return String(values[name]);
  });
}

export function t(id, values = {}, fallback = id) {
  const locale = languagePreference;
  const pattern = catalogs[locale]?.[id] ?? catalogs.en[id] ?? fallback;
  return formatMessage(pattern, values);
}

export function localizeSetting(setting) {
  const englishTitle = setting.englishTitle ?? setting.title;
  const englishDescription = setting.englishDescription ?? setting.description;
  return {
    ...setting,
    englishOptionLabels: setting.englishOptionLabels ?? setting.optionLabels,
    englishPlaceholder: setting.englishPlaceholder ?? setting.placeholder,
    optionLabels: setting.optionMessageIds ? Object.fromEntries(
      Object.entries(setting.englishOptionLabels ?? setting.optionLabels ?? {}).map(([value, label]) =>
        [value, t(setting.optionMessageIds[value], {}, label)])) : setting.optionLabels,
    placeholder: setting.placeholderMessageId ? t(setting.placeholderMessageId, {}, setting.englishPlaceholder ?? setting.placeholder) : setting.placeholder,
    englishTitle,
    englishDescription,
    title: setting.key === 'voice.timer_named_phrase'
      ? t('settingVoiceTimerNamedPhraseTitle', {}, englishTitle)
      : setting.key === 'alarms.phrase' ? t('alarmsPhrase', {}, englishTitle)
      : setting.titleMessageId ? t(setting.titleMessageId, {}, englishTitle) : setting.title,
    // Its description shows the {name} token itself, which a settings
    // message cannot carry: the token goes in as the placeholder's value.
    description: setting.key === 'voice.timer_named_phrase'
      ? t('settingVoiceTimerNamedPhraseDescription', { name: '{name}' }, englishDescription)
      : setting.key === 'alarms.phrase'
        ? t('alarmsPhraseHint', { label: '{label}', time: '{time}', day: '{day}' }, englishDescription)
      : setting.descriptionMessageId
        ? t(setting.descriptionMessageId, {}, englishDescription) : setting.description,
  };
}

// Menu labels are presentation only. Routes and setting categories stay stable.
export function navigationText(english) {
  return t(navigationMessageIds[english], {}, english);
}

export function localizeNavigation() {
  document.querySelectorAll('#tabs .nav-title, #tabs .nav-sub, #tabs .nav-head').forEach(element => {
    element.dataset.englishText ??= element.textContent;
    // A device without a screen names some pages for what is left on them.
    const english = (isHeadless() && element.dataset.headlessText) || element.dataset.englishText;
    element.textContent = navigationText(english);
  });
  const search = document.getElementById('settingsSearch');
  if (search) {
    search.placeholder = t('settingsSearchHint');
    search.setAttribute('aria-label', t('settingsSearchHint'));
  }
  document.getElementById('settingsSearchClear')?.setAttribute('aria-label', t('settingsSearchClear'));
  document.getElementById('navToggle')?.setAttribute('aria-label', t('settingsMenuMenu'));
  document.querySelectorAll('[data-home]').forEach(element => {
    element.title = t('settingsMenuOverview');
    element.setAttribute('aria-label', element.title);
  });
  document.querySelectorAll('.js-fleet-pick').forEach(element => element.setAttribute('aria-label', t('settingsMenuSwitchKiosk')));
  const theme = document.getElementById('themeBtn');
  if (theme) {
    theme.title = themeLabel(localStorage.getItem('ks_theme') || 'light');
    theme.setAttribute('aria-label', theme.title);
  }
  const logout = document.getElementById('logoutBtn');
  if (logout) logout.textContent = t('settingsMenuLogout');
}

export function themeLabel(preference) {
  const theme = preference === 'dark' ? t('drawerThemeDark')
    : preference === 'light' ? t('drawerThemeLight') : t('settingsMenuThemeAuto');
  return t('settingsMenuThemeState', { theme });
}

export function deviceText(english) {
  return typeof english === 'string' ? t(deviceTextMessageIds[english], {}, english) : english;
}

// Resolve owned error messages without translating server or OS diagnostics.
export function deviceOperationError(error) {
  if (typeof error !== 'string') return error;
  function translate(text, depth) {
    if (depth > 8) return null;
    for (const prefix of ['Bad state: ', 'Exception: ']) {
      if (text.startsWith(prefix)) return translate(text.slice(prefix.length), depth + 1);
    }
    const platform = /^(PlatformException\([^,]+, )([\s\S]*)(, null, null\))$/.exec(text);
    if (platform) {
      const detail = translate(platform[2], depth + 1);
      return detail === null ? null : platform[1] + detail + platform[3];
    }
    const aliases = {"the device admin permission is not active": "The device admin permission is not active.", "restart is Android-only": "Restart is only available on Android.", "a download is already running": "A download is running. Wait for it to finish.", "an install is already running": "An install is running. Wait for it to finish.", "An update is being installed. Try again when it finishes.": "An install is running. Wait for it to finish.", "no update available": "No update is available.", "no uploaded APK is waiting": "No uploaded APK is waiting.", "Shizuku command timed out": "Command timed out"};
    text = aliases[text] ?? text;
    const id = deviceTextMessageIds[text];
    if (id) return t(id);
    let match;
    match = /^restart failed: ([\s\S]*)$/.exec(text);
    if (match) return t('deviceRestartFailed', {error: translate(match[1], depth + 1) ?? match[1]});
    match = /^Not enough free space: the APK is (.+) MB and the install needs about (.+) MB, but the device has (.+) MB free\.$/.exec(text);
    if (match) return t('updateUploadSpace', {size: match[1], required: match[2], free: match[3]});
    match = /^The upload was interrupted after (.+) MB: ([\s\S]*)$/.exec(text);
    if (match) return t('updateUploadInterrupted', {size: match[1], error: translate(match[2], depth + 1) ?? match[2]});
    match = /^The upload ended early: (.+) of (.+) MB arrived\.$/.exec(text);
    if (match) return t('updateUploadEarly', {received: match[1], expected: match[2]});
    match = /^The APK is (.+), not Kiosk Satellite \((.+)\)\.$/.exec(text);
    if (match) return t('updateWrongPackage', {package: match[1] === 'another package' ? t('updateAnotherPackage') : match[1], expected: match[2]});
    match = /^The APK is version (.+) \(build (.+)\), older than the running (.+) \(build (.+)\). Downgrades are refused: Android would not install one either\.$/.exec(text);
    if (match) return t('updateOlderBuild', {version: match[1], build: match[2], currentVersion: match[3], currentBuild: match[4]});
    match = /^Download failed \(HTTP ([0-9]+)\)\.$/.exec(text);
    if (match) return t('updateDownloadHttpFailed', {status: match[1]});
    match = /^The download stalled: no data arrived for ([0-9]+) seconds\.$/.exec(text);
    if (match) return t('updateDownloadStalled', {seconds: match[1]});
    match = /^Update failed: ([\s\S]*)$/.exec(text);
    if (match) return t('deviceUpdateFailedDetail', {error: translate(match[1], depth + 1) ?? match[1]});
    match = /^Install failed: ([\s\S]*)$/.exec(text);
    if (match) return t('deviceInstallFailedDetail', {error: translate(match[1], depth + 1) ?? match[1]});
    return null;
  }
  return translate(error, 0) ?? error;
}

export function messageLanguage() { return languagePreference; }

export function immichError(error) {
  let match = /^The API key is missing the (.+) permission\.$/.exec(error);
  if (match) return t('screensaverMediaScopeMissing', {scope: match[1]});
  const permission = 'The API key is missing a permission: ';
  if (error.startsWith(permission)) return t('screensaverMediaPermissionMissing', {error: error.slice(permission.length)});
  match = /^The server answered ([0-9]+): ([\s\S]*)$/.exec(error);
  if (match) return t('screensaverMediaServerError', {status: match[1], error: match[2]});
  match = /^Could not reach ([\s\S]+)\.$/.exec(error);
  if (match) return t('screensaverMediaUnreachable', {url: match[1]});
  const talk = 'Could not talk to the server: ';
  if (error.startsWith(talk)) return t('screensaverMediaTalkError', {error: error.slice(talk.length)});
  return screensaverText(error);
}

export function intercomText(english) {
  return t(intercomTextMessageIds[english], {}, english);
}
export function intercomError(error, status = null) {
  const targets = status?.call?.targets;
  if (Array.isArray(targets) && targets.length) {
    const statuses = {listening:'listening', busy:'busy', dnd:'do not disturb',
      off:'intercom off', refused:'announcements off', key:'a different key',
      tls:'Encryption mismatch. Enable Encrypt communications on all kiosks in the call.',
      unreachable:'unreachable', left:'done'};
    const label = (value) => Object.hasOwn(statuses, value) ? statuses[value] : value;
    const original = targets.map((target) => `${target.name}: ${label(target.status)}`).join(', ');
    if (error === original) return targets.map((target) =>
      `${target.name}: ${intercomError(label(target.status))}`).join(', ');
  }
  const labels = {
    ended: 'Call ended', declined: 'Declined', cancelled: 'Cancelled',
    busy: 'Busy', 'do not disturb': 'Do not disturb',
    'its intercom is off': 'Its intercom is off',
    'a different intercom key': 'Different intercom key',
    'no answer': 'No answer', missed: 'Missed call',
    'did not answer': 'Did not answer', 'the voice link failed': 'The voice link failed',
    'the page took the microphone': 'The page took the microphone',
    'nobody could take it': 'Nobody could take it', 'the broadcast ended': 'Done',
    listening: 'Listening', 'intercom off': 'Intercom off',
    'announcements off': 'Announcements off', 'a different key': 'Different key',
    unreachable: 'Unreachable', done: 'Done',
  };
  return intercomText(Object.hasOwn(labels, error) ? labels[error] : error);
}
export function intercomAnnouncing(count) {
  return count === 1 ? t('intercomAnnouncingOne') : t('intercomAnnouncingMany', {count});
}

export function kioskText(english) {
  return t(kioskTextMessageIds[english], {}, english);
}

export function fleetText(english) { return t(fleetTextMessageIds[english], {}, english); }
export function pluginText(english) { return t(pluginTextMessageIds[english], {}, english); }

export function supportText(english) { return t(supportTextMessageIds[english], {}, english); }

export function esphomeText(english) { return t(esphomeTextMessageIds[english], {}, english); }


export function esphomeError(english) {
  return english.startsWith('GPS unavailable: ')
    ? t('esphomeLocationError', {error: english.slice('GPS unavailable: '.length)})
    : esphomeText(english);
}

export function esphomeDeviceIdentity(device) {
  const identity = device.identity || 'Unknown device';
  if (`${device.name || ''}`.trim()) return identity;
  if (device.vendor && identity === `${device.vendor} device`) {
    return t('esphomeIdentityVendor', {vendor: device.vendor});
  }
  return esphomeText(identity);
}


export function voiceText(english) { return t(voiceTextMessageIds[english], {}, english); }
export function voiceVadOption(value) {
  const labels = {default: 'Default', relaxed: 'Relaxed', aggressive: 'Aggressive'};
  return Object.hasOwn(labels, value) ? voiceText(labels[value])
    : value ? value[0].toUpperCase() + value.slice(1) : value;
}


export function voiceEntityOption(key, value) {
  if (key === 'vad_sensitivity') return voiceVadOption(value);
  if (key === 'wake_word_sensitivity' && ['Slightly sensitive', 'Moderately sensitive', 'Very sensitive'].includes(value)) return voiceText(value);
  if (key === 'wake_word_detection') {
    if (value === 'Disabled' || value === 'On Device') return voiceText(value);
    for (const engine of ['microWakeWord', 'openWakeWord', 'vsWakeWord']) {
      if (value === `On Device (${engine})`) return t('voiceOnDeviceEngine', {engine});
    }
  }
  if (key === 'wake_word_model_2' && value === 'Disabled') return voiceText(value);
  return value;
}

export function overviewText(english) { return t(overviewTextMessageIds[english], {}, english); }
export function overviewStatus(english) {
  if (english === 'Waiting for Voice Satellite. The engine and wake words are configured by the card once this device opens its dashboard.') return t('overviewWakeWaiting');
  let match = /^Watching (\d+) entities$/.exec(english);
  if (match) return t('overviewWatchingMany', {count: match[1]});
  match = /^Filtering disabled, view uses (\d+) entities$/.exec(english);
  if (match) return t('overviewFilterDisabled', {count: match[1]});
  match = /^No native runner for (.+)\. Voice Satellite keeps browser detection\.$/.exec(english);
  if (match) return t('overviewNativeUnavailable', {engine: match[1]});
  return overviewText(english);
}

export function setupText(english) { return t(setupTextMessageIds[english], {}, english); }

export function setupImportError(error) {
  const english = new Map([
    ['config must be an object', 'The backup must contain a JSON object.'],
    ['not a Kiosk Satellite configuration file', 'This is not a Kiosk Satellite configuration file.'],
    ['no settings in file', 'The backup contains no settings.'],
  ]).get(error);
  return english === undefined ? error : setupText(english);
}

function ownedError(error, lookup) {
  if (typeof error !== 'string') return error;
  function translate(text, depth) {
    if (depth > 8) return null;
    const direct = lookup(text);
    if (direct !== null) return direct;
    for (const prefix of ['Bad state: ', 'FormatException: ', 'Exception: ', 'Error: ']) {
      if (text.startsWith(prefix)) return translate(text.slice(prefix.length), depth + 1);
    }
    const platform = /^(PlatformException\([^,]+, )([\s\S]*)(, null, null\))$/.exec(text);
    if (platform) {
      const detail = translate(platform[2], depth + 1);
      return detail === null ? null : platform[1] + detail + platform[3];
    }
    return null;
  }
  return translate(error, 0) ?? error;
}

export function launcherError(error) {
  return ownedError(error, text => {
    const id = launcherTextMessageIds[text] || deviceTextMessageIds[text];
    if (id) return t(id);
    const match = /^could not list apps: ([\s\S]*)$/.exec(text);
    return match ? t('launcherErrorListDetail', {error: match[1]}) : null;
  });
}

export function pluginError(error) {
  return ownedError(error, text => {
    const id = pluginTextMessageIds[text] || deviceTextMessageIds[text];
    if (id) return t(id);

    const update = /^Plugin update failed: ([\s\S]*?)\. (The previous version [\s\S]*)$/.exec(text);
    if (update) {
      const failed = /^The previous version could not restart: ([\s\S]*)$/.exec(update[2]);
      return t('pluginErrorUpdateFailed', {error: update[1], recovery: failed ? t('pluginErrorPreviousRestart', {error: failed[1]}) : pluginText(update[2])});
    }
    const read = /^Cannot read installed plugin: ([\s\S]*)$/.exec(text);
    if (read) return t('pluginErrorReadInstalled', {error: read[1]});
    let match;
    match = /^GitHub request failed \(([0-9]+)\)$/.exec(text);
    if (match) return t('pluginErrorGithubRequest', {status: match[1]});
    match = /^Release needs exactly one uploaded (.+) asset$/.exec(text);
    if (match) return t('pluginErrorReleaseAsset', {name: match[1]});
    match = /^Release asset (.+) must be published by GitHub Actions\. Manually uploaded files are not supported\.$/.exec(text);
    if (match) return t('pluginErrorAssetPublisher', {name: match[1]});
    match = /^Release asset (.+) exceeds the size limit or is empty$/.exec(text);
    if (match) return t('pluginErrorAssetSize', {name: match[1]});
    match = /^Invalid release URL for (.+)$/.exec(text);
    if (match) return t('pluginErrorAssetUrl', {name: match[1]});
    match = /^Plugin needs Android API ([0-9]+)$/.exec(text);
    if (match) return t('pluginErrorAndroidApi', {version: match[1]});
    match = /^Plugin needs Kiosk Satellite (\S+) or newer\. This kiosk runs (\S*)\.$/.exec(text);
    if (match) return t('pluginErrorAppVersion', {required: match[1], current: match[2]});
    match = /^Invalid (id|name|version|entryClass|description|author|license|key|title|group|readingsTitle|headless|input|minAppVersion)$/.exec(text);
    if (match) return t('pluginErrorInvalidField', {field: match[1]});
    match = /^Unexpected or duplicate ZIP entry: ([\s\S]*)$/.exec(text);
    if (match) return t('pluginErrorZipEntry', {name: match[1]});
    return null;
  });
}
