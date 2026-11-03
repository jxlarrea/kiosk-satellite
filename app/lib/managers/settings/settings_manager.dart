import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/command_registry.dart';
import '../../core/events.dart';
import '../../core/headless.dart';
import '../../core/tls_identity.dart';
import '../../core/manager.dart';
import '../device_camera/camera_resolutions.dart';
import '../kiosk/drawer_items.dart';
import '../wake_word/pryon/pryon_catalog.dart';
import 'definitions.dart';

export 'definitions.dart';

/// Owns persistence and change notification for every declared setting.
class SettingsManager extends Manager {
  SettingsManager(super.bus, super.commands, super.log);

  @override
  String get name => 'settings';

  late SharedPreferences _prefs;
  late final tls = TlsIdentity(this);

  /// Live renderer names, supplied by the plugin runtime without persisting HTML.
  Map<String, String> Function() pluginScreensavers = () => const {};

  /// Installed plugins that offer a voice skin: `plugin:ID` to the plugin's
  /// name. Supplied by the plugin runtime.
  Map<String, String> Function() pluginVoiceSkins = () => const {};
  List<String>? _cameraStreamResolutions;
  List<String>? get cameraStreamResolutions => _cameraStreamResolutions;
  CameraStreamingCapabilities? _cameraStreamingCapabilities;
  String get cameraResolutionNotice =>
      _cameraStreamingCapabilities?.notice(get(cameraRtspAnalysis)) ??
      'Checking camera and H.264 encoder support...';

  void updateCameraStreamingCapabilities(
    CameraStreamingCapabilities? capabilities,
  ) {
    final previousNotice = cameraResolutionNotice;
    final previousSizes = _cameraStreamResolutions?.join(',');
    _cameraStreamingCapabilities = capabilities;
    _cameraStreamResolutions = capabilities == null
        ? null
        : List.unmodifiable(capabilities.sizes(get(cameraRtspAnalysis)));
    if (previousNotice != cameraResolutionNotice ||
        previousSizes != _cameraStreamResolutions?.join(',')) {
      bus.publish(SettingOptionsChanged(cameraRtspResolution.key));
    }
  }

  void refreshCameraStreamingMode() {
    _cameraStreamResolutions = _cameraStreamingCapabilities == null
        ? null
        : List.unmodifiable(
            _cameraStreamingCapabilities!.sizes(get(cameraRtspAnalysis)),
          );
    bus.publish(SettingOptionsChanged(cameraRtspResolution.key));
  }

  void updateCameraStreamResolutions(List<String>? sizes) {
    if (_cameraStreamResolutions?.join(',') == sizes?.join(',')) return;
    _cameraStreamResolutions = sizes == null ? null : List.unmodifiable(sizes);
    bus.publish(SettingOptionsChanged(cameraRtspResolution.key));
  }

  /// Each realtime provider's models and voices: fetched from it when the
  /// kiosk talks to it directly, else the ones built in (VoiceManager).
  final _realtimeCatalog =
      <String, ({List<String> models, List<String> voices})>{};

  /// The Model and Voice settings of each provider, and which list each
  /// takes: (provider, models).
  static final _realtimeLists = <String, (String, bool)>{
    voiceRealtimeOpenAiModel.key: ('openai', true),
    voiceRealtimeOpenAiVoice.key: ('openai', false),
    voiceRealtimeXaiModel.key: ('xai', true),
    voiceRealtimeXaiVoice.key: ('xai', false),
    voiceRealtimeGeminiModel.key: ('gemini', true),
    voiceRealtimeGeminiVoice.key: ('gemini', false),
  };

  void updateRealtimeCatalog(
    String provider, {
    required List<String> models,
    required List<String> voices,
  }) {
    final before = _realtimeCatalog[provider];
    _realtimeCatalog[provider] = (
      models: List.unmodifiable(models),
      voices: List.unmodifiable(voices),
    );
    for (final entry in _realtimeLists.entries) {
      final (owner, isModels) = entry.value;
      if (owner != provider) continue;
      final was = isModels ? before?.models : before?.voices;
      final now = isModels ? models : voices;
      if (was?.join(',') != now.join(',')) {
        bus.publish(SettingOptionsChanged(entry.key));
      }
    }
  }

  /// '' (the provider's default) first, then the catalog, and the value
  /// set when the catalog no longer lists it. Null for any other setting.
  List<String>? _realtimeOptions(SettingDef<Object> def) {
    final list = _realtimeLists[def.key];
    if (list == null) return null;
    final (provider, isModels) = list;
    final catalog = _realtimeCatalog[provider];
    final entries = (isModels ? catalog?.models : catalog?.voices) ?? const [];
    final current = get(def) as String;
    return [
      '',
      ...entries,
      if (current.isNotEmpty && !entries.contains(current)) current,
    ];
  }

  /// Automatic and the two cancellers, the one Automatic settled on in
  /// place of its own entry (shown as "GTCRN (detected)"). Picking
  /// Automatic again drops the verdict.
  List<String> _echoMethodOptions() {
    final current = get(micEchoCancellationMethod);
    return [
      'auto',
      for (final method in ['gtcrn', 'aec3'])
        current == 'auto:$method' ? current : method,
    ];
  }

  List<String> optionsFor(SettingDef<Object> def) =>
      def.key == cameraRtspResolution.key
      ? _cameraStreamResolutions ?? const []
      : def.key == voiceAmazonLocale.key
      ? ['', ...PryonCatalog.locales]
      : def.key == micEchoCancellationMethod.key
      ? _echoMethodOptions()
      : _realtimeOptions(def) ??
            [
              for (final option in def.options ?? const <String>[])
                if (!(deviceHiddenOptions[def.key]?.contains(option) ?? false))
                  option,
              if (def.key == screensaverMode.key) ...{
                ...pluginScreensavers().keys,
                if (isPluginScreensaver(get(def))) get(def) as String,
              },
              if (isVoiceSkinSetting(def.key)) ...{
                ...pluginVoiceSkins().keys,
                if (isPluginVoiceSkin(get(def))) get(def) as String,
              },
            ];
  String? optionLabel(SettingDef<Object> def, String value) =>
      def.key == cameraRtspResolution.key
      ? cameraResolutionLabel(value)
      : def.key == voiceAmazonLocale.key && value.isNotEmpty
      ? PryonCatalog.localeLabel(value)
      // Model ids read as they are; voices are names.
      : _realtimeLists[def.key] != null && value.isNotEmpty
      ? (_realtimeLists[def.key]!.$2
            ? value
            : value[0].toUpperCase() + value.substring(1))
      : def.optionLabels?[value] ??
            (def.key == screensaverMode.key
                ? pluginScreensavers()[value] ??
                      (isPluginScreensaver(value)
                          ? 'Unavailable plugin screensaver'
                          : null)
                : isVoiceSkinSetting(def.key)
                ? pluginVoiceSkins()[value] ??
                      (isPluginVoiceSkin(value)
                          ? 'Unavailable plugin skin'
                          : null)
                : null);

  static const _prefix = 'ks.';

  /// True while an onboarding import's detached tail (permission prompts on
  /// the device, then the deferred start URL) is still running. Surfaced in
  /// the remote setup status so its UI can say "finish on the device"
  /// instead of presenting an empty wizard.
  bool importFinishing = false;

  /// True while an import batch is applying (and briefly after, until its
  /// asynchronously delivered SettingChanged events have settled).
  /// Derived-state listeners that INVALIDATE things when their inputs
  /// change (the Immich validation reset) must stand down during it: an
  /// imported validation flag arrives together with the very credentials
  /// it validated, and the reset would stomp it after the fact.
  bool importing = false;

  /// Whether this is the first start of a fresh install: nothing the app
  /// keeps was stored when [init] began. An upgrade, a restored backup and
  /// a data import all arrive with stored settings. Read before the
  /// migrations below write theirs.
  bool firstRun = false;

  /// Settings the native side can write before Dart first starts (the
  /// renderer guards), which a fresh install may already hold.
  static final _nativeWritten = {disableImpeller.key, legacyWebView.key};

  bool _storedNothing() {
    final keys = _prefs.getKeys();
    if (keys.any(
      (k) =>
          k.startsWith('${_prefix}internal.') ||
          k.startsWith('${_prefix}secret.'),
    )) {
      return false;
    }
    return !allSettings.any(
      (def) =>
          !_nativeWritten.contains(def.key) && keys.contains(_prefix + def.key),
    );
  }

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    firstRun = _storedNothing();
    await _migrate();

    commands
      ..register(
        Command(
          name: 'exportConfig',
          description:
              'Full configuration for backup or cloning: every setting '
              '(secrets included) plus the page\'s localStorage.',
          handler: (_) async {
            // Browser-owned; fails harmlessly when no page is up.
            final local = await commands.execute('getLocalStorage', const {});
            return CommandResult.ok({
              'kind': 'kiosk-satellite-config',
              'version': 1,
              // Which device this came from and when. Both UIs put them in
              // the filename, and they keep the file identifiable after
              // someone renames it. Ignored on import.
              'deviceName': get(deviceName),
              'exportedAt': DateTime.now().toIso8601String(),
              'settings': export(withSecrets: true),
              if (local.ok && local.data is String) 'localStorage': local.data,
            });
          },
        ),
      )
      ..register(
        Command(
          name: 'importConfig',
          description: 'Apply a configuration produced by exportConfig.',
          params: const {
            'config': 'The exported JSON object',
            'adoptIdentity':
                "take over the backup's device identity (device name, "
                'ESPHome node name) as a replacement device; false keeps this '
                "device's own so the two can run side by side (default true)",
            'importLocalStorage':
                "apply the backup's page localStorage, which carries the "
                'Voice Satellite selection; false leaves it (and the '
                'satellite entity setting) alone so this device answers as '
                'its own satellite (default true)',
          },
          secretParams: const {'config'},
          handler: (p) async {
            final config = p['config'];
            if (config is! Map) {
              return const CommandResult.fail('config must be an object');
            }
            if (config['kind'] != 'kiosk-satellite-config') {
              return const CommandResult.fail(
                'not a Kiosk Satellite configuration file',
              );
            }
            final settings = config['settings'];
            if (settings is! Map) {
              return const CommandResult.fail('no settings in file');
            }
            final adoptIdentity = p['adoptIdentity'] != false;
            final importLocal = p['importLocalStorage'] != false;
            // Whether this device was still unconfigured, read before the
            // import flips it: it decides the permission pass below.
            final firstSetup = get(startUrl).isEmpty;
            final map = settings.map((k, v) => MapEntry(k.toString(), v));
            // Side-by-side clone: the backup's identity must not come
            // along (issues #25, #136); see shedImportedIdentity.
            if (!adoptIdentity) {
              await shedImportedIdentity(map);
            }
            // Same idea for the satellite: the entity selection lives in
            // the page's localStorage plus this seed setting, and two
            // devices answering as one assist_satellite displace each
            // other mid-turn.
            if (!importLocal) {
              map.remove(haSatelliteEntity.key);
            }
            // Backups from builds before the Camera section carry motion
            // detection but no camera master switch; enable the camera for
            // them (carrying the old camera pick along) so motion detection
            // still works after the restore.
            if (map[screensaverDismissOnMotion.key] == true &&
                !map.containsKey(cameraEnabled.key)) {
              map[cameraEnabled.key] = true;
              final legacy = map[motionCamera.key];
              if (legacy is String && !map.containsKey(cameraDevice.key)) {
                map[cameraDevice.key] = legacy;
              }
            }
            // On a first setup the start URL is held back until the very
            // end, like the wizard does: it is what flips the app to
            // configured and loads the page, whose wake-word engine
            // immediately runs its own microphone check. Android allows one
            // permission request at a time, so a page racing the prompts
            // below gets some of them silently rejected ("A request for
            // permissions is already running").
            // A device without a screen has no page to race and no prompts
            // to show: its grants come over adb, so the import finishes at
            // once.
            final prompts = firstSetup && !Headless.active;
            final heldStartUrl = prompts ? map.remove(startUrl.key) : null;
            var applied = await import(map);
            // A stale backup can carry Immich credentials with the
            // validated flag off (exported after something reset it).
            // The user's remedy was a manual re-validate that a machine
            // can do: same check the settings button runs, and the flag
            // ends up honest either way.
            if (get(screensaverImmichUrl).isNotEmpty &&
                get(screensaverImmichApiKey).isNotEmpty &&
                !get(screensaverImmichValidated)) {
              unawaited(commands.execute('immichValidate', const {}));
            }
            // Stash localStorage BEFORE the reload below, so the fresh page
            // load picks it up (see BrowserManager.onPageLoaded).
            final local = config['localStorage'];
            if (importLocal && local is String && local.isNotEmpty) {
              await commands.execute('setLocalStorage', {'data': local});
            }
            // An onboarding import IS the setup, so it also does the
            // wizard's last chore: fire the OS permission prompts the
            // imported settings need (the backup carries grants only as
            // settings; the OS ones must be asked for on this device).
            // Post-setup imports skip this — that device already ran a
            // wizard, and permission Activities on every restore would be
            // noise.
            //
            // Detached, NOT awaited: the prompts are answered by a human
            // at the DEVICE, and an import that came over the remote API
            // must not hold its HTTP response hostage to them — that reads
            // as "Importing…" forever in a browser while the tablet sits
            // on a system dialog. The start URL stays sequenced after the
            // prompts (see above); callers see pendingSetup and wait for
            // the device to become configured instead.
            if (prompts) {
              importFinishing = true;
              unawaited(
                Future(() async {
                  try {
                    await commands.execute('requestOsPermissions', {
                      'which': [
                        if (get(wakeWordEnabled) || get(webMicrophone))
                          'microphone',
                        if (get(cameraEnabled) || get(webCamera)) 'camera',
                        // Unconditional like the setup wizard's: the Home
                        // Assistant and ESPHome connections are held open with
                        // the screen off whatever else is configured, and
                        // Doze is what stops them (issue #156).
                        'batteryOptimizations',
                        if (get(wakeWordBackground)) 'notifications',
                        if (get(wakeWordBackground) ||
                            get(kioskStartOnBoot) ||
                            get(autoReloadOnError))
                          'overlay',
                        'writeSettings',
                        'deviceAdmin',
                      ],
                    });
                    if (heldStartUrl != null) {
                      await setFromJson(startUrl.key, heldStartUrl);
                      await commands.execute('loadUrl', {'url': get(startUrl)});
                    }
                    log.info(
                      name,
                      'imported setup finished (permissions done)',
                    );
                  } finally {
                    importFinishing = false;
                  }
                }),
              );
              log.info(
                name,
                'imported configuration ($applied settings); permission '
                'prompts continue on the device',
              );
              return CommandResult.ok({
                'applied': applied,
                'pendingSetup': heldStartUrl != null,
              });
            }
            // The imported start URL should be what ends up on screen.
            if (settings.containsKey(startUrl.key)) {
              await commands.execute('loadUrl', {'url': get(startUrl)});
            }
            log.info(name, 'imported configuration ($applied settings)');
            return CommandResult.ok({'applied': applied});
          },
        ),
      );
  }

  /// Settings whose stored shape changed between releases. A value that no
  /// longer matches its definition's type is invisible to [get] — it falls
  /// back to the default — so a rename in place has to be rewritten once,
  /// here, before anything reads it.
  Future<void> _migrate() async {
    // Native Voice Satellite: a kiosk that already runs Voice Satellite in
    // the dashboard (a satellite assigned) keeps doing so until its owner
    // migrates; every other install starts native. Written once, the first
    // time this version starts, so a later assignment never flips it.
    if (_prefs.get(_prefix + voiceRuntime.key) == null) {
      final assigned =
          (_prefs.get(_prefix + haSatelliteEntity.key) as String? ?? '')
              .trim()
              .isNotEmpty;
      await _prefs.setString(
        _prefix + voiceRuntime.key,
        assigned ? 'dashboard' : 'native',
      );
      log.info(
        name,
        'Voice Satellite runtime set to ${assigned ? 'dashboard' : 'native'}',
      );
    }
    // The preview's automatic language choice is now explicit English.
    if (_prefs.get(_prefix + uiLanguage.key) == 'system') {
      await _prefs.setString(_prefix + uiLanguage.key, 'en');
    }
    // The platform's echo canceller, capture mode, noise suppression and
    // gain control are gone: the capture is the raw microphone with the
    // app's own canceller over it, which an install from the days of the
    // switch may have turned off to try. On once for everyone.
    const softwareEchoMigration =
        'audio.software_echo_cancellation_on.migrated';
    if (internal(softwareEchoMigration).isEmpty) {
      if (!get(micSoftwareEchoCancellation)) {
        await _prefs.setBool(_prefix + micSoftwareEchoCancellation.key, true);
        log.info(name, 'turned echo cancellation on on upgrade');
      }
      await setInternal(softwareEchoMigration, '1');
    }
    // Expose kiosk entities used to be off by default. A configured kiosk
    // that never chose keeps it off, so ESPHome running only for the
    // Bluetooth proxy does not suddenly serve every entity. New installs
    // take the new default.
    const entitiesDefaultMigration = 'esphome.entities_default_on.migrated';
    if (internal(entitiesDefaultMigration).isEmpty) {
      if (_prefs.get(_prefix + esphomeEntities.key) == null &&
          get(startUrl).isNotEmpty) {
        await _prefs.setBool(_prefix + esphomeEntities.key, false);
        log.info(name, 'kept Expose kiosk entities off on upgrade');
      }
      await setInternal(entitiesDefaultMigration, '1');
    }
    // The music duck used to go up to 25%, more than the software echo
    // canceller keeps out of the microphone. Bring existing installs down
    // to the new ceiling once.
    const duckCapMigration = 'sendspin.duck_percent_10.migrated';
    if (internal(duckCapMigration).isEmpty) {
      if (get(sendspinDuckPercent) > sendspinDuckMax) {
        await _prefs.setInt(_prefix + sendspinDuckPercent.key, sendspinDuckMax);
        log.info(
          name,
          'lowered the music duck to $sendspinDuckMax% on upgrade',
        );
      }
      await setInternal(duckCapMigration, '1');
    }
    // HA kiosk mode was a strategy choice (off/auto/plugin/css) while the
    // hiding could be handed to the kiosk-mode resource. It does the hiding
    // itself now, so the setting is a plain switch: anything that was not
    // 'off' was kiosk mode being on.
    final kiosk = _prefs.get('${_prefix}ha.kiosk_mode');
    if (kiosk is String) {
      await _prefs.setBool('${_prefix}ha.kiosk_mode', kiosk != 'off');
      log.info(name, 'migrated ha.kiosk_mode ($kiosk)');
    }
    // The strategy the drawer toggle used to restore. Nothing to restore now.
    await _prefs.remove('${_prefix}ha.kiosk_mode_last');
    // The app launcher's Layout and Show icons settings configured the old
    // modal; the full-screen tile view (the Portal-launcher look) is the
    // one design now, so the rows are gone and stored values with them.
    await _prefs.remove('${_prefix}launcher.layout');
    await _prefs.remove('${_prefix}launcher.show_icons');
    // The locked kiosk offered every launcher app before it had its own
    // list (issue #1067). Seeded once with all of them, so the quick menu
    // keeps what it offered and later additions wait to be allowed.
    if (_prefs.get(_prefix + kioskAllowedApps.key) == null) {
      var packages = const <Object?>[];
      try {
        final apps = jsonDecode(get(launcherApps));
        if (apps is List) {
          packages = [
            for (final app in apps)
              if (app is Map && app['package'] is String) app['package'],
          ];
        }
      } catch (_) {}
      await _prefs.setString(
        _prefix + kioskAllowedApps.key,
        jsonEncode(packages),
      );
    }
    // The kiosk menu's rows each had their own Show in the kiosk menu
    // switch before Drawer menu items decided them all (issue #1194).
    // Seeded once from those switches, in the menu's old order, and the
    // old values go: the switches are links now and hold nothing.
    if (_prefs.get(_prefix + uiDrawerItems.key) == null) {
      final hidden = <String>{
        for (final MapEntry(key: key, value: id) in drawerItemLinks.entries)
          if (!(_prefs.get(_prefix + key) as bool? ??
              !drawerItemsOffByDefault.contains(id)))
            id,
      };
      final items = DrawerItems(
        shown: [
          for (final id in drawerItemOrder)
            if (!hidden.contains(id)) id,
        ],
        hidden: hidden,
      );
      await _prefs.setString(_prefix + uiDrawerItems.key, items.encode());
      for (final key in drawerItemLinks.keys) {
        await _prefs.remove(_prefix + key);
      }
      log.info(name, 'seeded the drawer menu items from the menu switches');
    }
    // The Sonos page's own lyrics switch: the Lyrics page's Enable lyrics
    // covers every source now.
    await _prefs.remove('${_prefix}sendspin.sonos_lyrics');
    // The Bluetooth proxy toggle used to be the master switch for the whole
    // ESPHome server; now esphome.enabled is. An install that ran the proxy
    // must keep its server (and its Home Assistant config entry) across the
    // update without anyone touching a setting.
    if (_prefs.get('${_prefix}esphome.enabled') == null &&
        _prefs.get('${_prefix}btproxy.enabled') == true) {
      await _prefs.setBool('${_prefix}esphome.enabled', true);
      log.info(name, 'migrated btproxy.enabled -> esphome.enabled');
    }
    // The ESPHome Person sensor followed Dismiss on person and has its own
    // switch now (issue #734). A kiosk that exposed it keeps the entity
    // across the update. Once only, so turning Dismiss on person on later
    // never turns the sensor on with it.
    const personSensorMigration = 'person.sensor.migrated';
    if (internal(personSensorMigration).isEmpty) {
      if (_prefs.get(_prefix + personSensorEnabled.key) == null &&
          _prefs.get(_prefix + screensaverDismissOnPerson.key) == true) {
        await _prefs.setBool(_prefix + personSensorEnabled.key, true);
        log.info(
          name,
          'migrated screensaver.dismiss_on_person -> person.sensor',
        );
      }
      await setInternal(personSensorMigration, '1');
    }
    // The HA base URL is normalized to its origin on write now, but a value
    // saved with a trailing slash by an older version keeps breaking the
    // pipeline socket ('http://ha:8123//api/websocket') until rewritten.
    final ha = _prefs.getString('${_prefix}ha.url');
    if (ha != null && ha.isNotEmpty && ha != normalizeBaseUrl(ha)) {
      await _prefs.setString('${_prefix}ha.url', normalizeBaseUrl(ha));
      log.info(name, 'migrated ha.url to its origin form');
    }
    // The Now Playing surfaces can follow a Home Assistant media player
    // or a Sonos as well as a Music Assistant player now, so the pick is
    // one key with a source prefix. A Music Assistant pick stored under
    // the old key carries over with its name.
    final maPlayer = _prefs.getString('${_prefix}sendspin.ma_player');
    if (maPlayer != null) {
      if (maPlayer.trim().isNotEmpty &&
          (_prefs.getString('${_prefix}sendspin.player') ?? '').isEmpty) {
        await _prefs.setString(
          '${_prefix}sendspin.player',
          'ma:${maPlayer.trim()}',
        );
        final maName = _prefs.getString('${_prefix}sendspin.ma_player_name');
        if (maName != null && maName.isNotEmpty) {
          await _prefs.setString('${_prefix}sendspin.player_name', maName);
        }
        log.info(name, 'migrated sendspin.ma_player -> sendspin.player');
      }
      await _prefs.remove('${_prefix}sendspin.ma_player');
      await _prefs.remove('${_prefix}sendspin.ma_player_name');
    }
    // The pick is filtered by a source now: a pick stored before the
    // source existed names its own. The Local Media Session and the
    // AirPlay receiver are this device's own picks and belong under the
    // empty source.
    final picked = _prefs.getString('${_prefix}sendspin.player') ?? '';
    if (picked.trim().isNotEmpty &&
        !picked.startsWith('session:') &&
        picked != 'airplay' &&
        (_prefs.getString('${_prefix}sendspin.player_source') ?? '').isEmpty) {
      final source = picked.startsWith('ha:')
          ? 'ha'
          : picked.startsWith('sonos:')
          ? 'sonos'
          : 'ma';
      await _prefs.setString('${_prefix}sendspin.player_source', source);
      log.info(name, 'migrated sendspin.player_source = $source');
    }
    // The wake word master switch is retired (hidden, forced on): with the
    // switch gone from the UI, a stored false would strand detection off
    // with no way back, so it is rewritten once.
    if (_prefs.get('${_prefix}wake_word.enabled') == false) {
      await _prefs.setBool('${_prefix}wake_word.enabled', true);
      log.info(name, 'migrated wake_word.enabled to always-on');
    }
    // "Fill the screen" was a switch in the four photo modes and is now a
    // choice of how far a photo may be cropped. The switch on is what
    // 'smart' does, so a stored bool carries straight over and nobody's
    // screensaver changes shape on update.
    for (final key in const [
      'screensaver.media_fill',
      'screensaver.gallery_fill',
      'screensaver.local_fill',
      'screensaver.immich_fill',
    ]) {
      final fill = _prefs.get(_prefix + key);
      if (fill is bool) {
        await _prefs.setString(_prefix + key, fill ? 'smart' : 'off');
        log.info(name, 'migrated $key ($fill)');
      }
    }
    // Wake to screensaver was a switch and is now a pick of what wakes to
    // the screensaver (issue #954). On stood for every detection and the
    // power button, never touch, so nobody's kiosk wakes differently.
    final wakeKey = _prefix + screensaverScreenOffWakeToScreensaver.key;
    final wake = _prefs.get(wakeKey);
    if (wake is bool) {
      await _prefs.setString(wakeKey, wakeToScreensaverFromSwitch(wake));
      log.info(
        name,
        'migrated ${screensaverScreenOffWakeToScreensaver.key} ($wake)',
      );
    }
    // Horizontal mode was a switch and is now a pick of three layouts. Off
    // was the vertical layout and on the horizontal one.
    final horizontalKey = '${_prefix}sendspin.fullscreen_horizontal';
    final horizontal = _prefs.get(horizontalKey);
    if (horizontal is bool) {
      if (_prefs.get(_prefix + sendspinFullscreenLayout.key) == null) {
        await _prefs.setString(
          _prefix + sendspinFullscreenLayout.key,
          sendspinLayoutFromSwitch(horizontal),
        );
      }
      await _prefs.remove(horizontalKey);
      log.info(
        name,
        'migrated sendspin.fullscreen_horizontal -> '
        '${sendspinFullscreenLayout.key} ($horizontal)',
      );
    }
    // Full screen (issue #1076) split into a switch per bar (issue #1102).
    // A kiosk that showed both bars keeps showing them.
    final fullScreenKey = '${_prefix}screen.full_screen';
    final fullScreen = _prefs.get(fullScreenKey);
    if (fullScreen is bool) {
      for (final def in [screenHideStatusBar, screenHideNavigationBar]) {
        if (_prefs.get(_prefix + def.key) == null) {
          await _prefs.setBool(_prefix + def.key, fullScreen);
        }
      }
      await _prefs.remove(fullScreenKey);
      log.info(name, 'migrated screen.full_screen ($fullScreen)');
    }
    // Assistant 2 got its own skin (issue #1121). Its turns keep the skin
    // they wore before.
    const skin2Migration = 'voice.skin_2.migrated';
    if (internal(skin2Migration).isEmpty) {
      final skin = _prefs.get(_prefix + voiceSkin.key);
      if (skin is String && _prefs.get(_prefix + voiceSkin2.key) == null) {
        await _prefs.setString(_prefix + voiceSkin2.key, skin);
        log.info(name, 'migrated ${voiceSkin2.key} ($skin)');
      }
      await setInternal(skin2Migration, '1');
    }
  }

  T get<T>(SettingDef<T> def) {
    final raw = _prefs.get(_prefix + def.key);
    // The `raw != null` guard matters: when T is inferred nullable (e.g.
    // Object? from a caller's ternary), `null is T` is true, which would
    // wrongly return null for an unstored setting instead of its default.
    if (raw != null && raw is T) return raw as T;
    // num settings may come back as int or double depending on what was set.
    if (raw is num && def.defaultValue is num) return raw as T;
    return def.defaultValue;
  }

  /// [source] names who asked for the write when it was not the device's
  /// own UI (the ESPHome entity in Home Assistant, the remote admin
  /// page, a settings import), so the log says which caller flipped a
  /// setting rather than leaving it to be guessed from the lines around it.
  Future<void> set<T>(SettingDef<T> def, T value, {String? source}) async {
    final normalizer = def.normalizer;
    if (normalizer != null) value = normalizer(value as Object) as T;
    final previous = get(def);
    if (value == true &&
        (def.key == remoteTls.key ||
            def.key == cameraRtspTls.key ||
            def.key == intercomTls.key)) {
      (await tls.load()).securityContext();
    }
    switch (value) {
      case final bool v:
        await _prefs.setBool(_prefix + def.key, v);
      case final String v:
        await _prefs.setString(_prefix + def.key, v);
      case final num v:
        // A whole value is an int, not 10.0 — SharedPreferences keeps the two
        // apart, and get() reads back whichever was stored.
        if (v is int || v == v.roundToDouble()) {
          await _prefs.setInt(_prefix + def.key, v.toInt());
        } else {
          await _prefs.setDouble(_prefix + def.key, v.toDouble());
        }
      default:
        throw ArgumentError('unsupported setting type: $value');
    }
    // The renderer guard records when it turned Legacy renderer on by
    // itself (RendererGuard.kt, render.disabled_by) so it can undo its own
    // flips later. A change made here, by a person on either UI or through
    // an import, makes the value theirs: the record goes with it.
    if (def.key == 'render.disable_impeller') {
      await _prefs.remove('${_prefix}render.disabled_by');
    }
    log.info(
      name,
      'set ${def.key}${def.secret ? '' : ' = $value'}'
      '${source == null ? '' : ' [$source]'}',
    );
    bus.publish(SettingChanged(key: def.key, value: value, previous: previous));
  }

  /// Internal string value with no settings row (state, not preference).
  /// Empty string and absent are the same thing: nothing pending.
  String internal(String key) =>
      _prefs.getString('${_prefix}internal.$key') ?? '';

  Future<void> setInternal(String key, String value) async {
    if (value.isEmpty) {
      await _prefs.remove('${_prefix}internal.$key');
    } else {
      await _prefs.setString('${_prefix}internal.$key', value);
    }
  }

  /// Persisted internal value not exposed in the settings UI (e.g. the
  /// remote-auth signing secret). Returns [orElse] and stores it when absent.
  Future<String> secret(String key, String Function() orElse) async {
    final existing = _prefs.getString('${_prefix}secret.$key');
    if (existing != null && existing.isNotEmpty) return existing;
    final value = orElse();
    await _prefs.setString('${_prefix}secret.$key', value);
    return value;
  }

  SettingDef<Object>? defByKey(String key) {
    for (final def in allSettings) {
      if (def.key == key) return def;
    }
    return null;
  }

  /// What is wrong with [value] for [def], or null when nothing is: the
  /// definition's own validator, then its cross validator with the other
  /// settings in view. [batch] is the rest of a multi-key write, which a
  /// sibling is read from ahead of the stored value, so two ends of a
  /// range can move together past each other's old positions.
  String? validate(
    SettingDef<Object> def,
    Object? value, {
    Map<String, Object?> batch = const {},
  }) {
    final own = def.validator?.call(value);
    if (own != null) return own;
    final cross = def.crossValidator;
    if (cross == null) return null;
    return cross(value, (key) {
      if (batch.containsKey(key)) return batch[key];
      final other = defByKey(key);
      return other == null ? null : get(other);
    });
  }

  /// Set from an untyped (JSON) value — used by the remote API and import.
  Future<bool> setFromJson(
    String key,
    Object? value, {
    String? source,
    Map<String, Object?> batch = const {},
  }) async {
    // The same callers from before Layout mode replaced Horizontal mode.
    if (key == 'sendspin.fullscreen_horizontal' && value is bool) {
      key = sendspinFullscreenLayout.key;
      value = sendspinLayoutFromSwitch(value);
    }
    // A backup, a fleet leader or an API caller from before Full screen
    // became a switch per bar still sends it; it sets both.
    if (key == 'screen.full_screen' && value is bool) {
      await setFromJson(
        screenHideStatusBar.key,
        value,
        source: source,
        batch: batch,
      );
      key = screenHideNavigationBar.key;
    }
    // A backup, a fleet leader or an API caller from before Drawer menu
    // items still sends a row's own switch; it turns that row on or off.
    // A batch that carries the list itself already says it all.
    if (drawerItemLinks[key] case final id? when value is bool) {
      if (batch[uiDrawerItems.key] is String) return true;
      final items = DrawerItems.decode(get(uiDrawerItems));
      await set(
        uiDrawerItems,
        items.withItem(id, value).encode(),
        source: source,
      );
      return true;
    }
    final def = defByKey(key);
    if (def == null) return false;
    // A backup, a fleet leader or an API caller from before Wake to
    // screensaver became a pick still sends the switch.
    if (def.key == screensaverScreenOffWakeToScreensaver.key && value is bool) {
      value = wakeToScreensaverFromSwitch(value);
    }
    if (validate(def, value, batch: batch) != null) return false;
    switch (def.type) {
      case SettingType.boolean when value is bool:
        await set(def, value, source: source);
      case SettingType.number when value is num:
        await set(def, value, source: source);
      case SettingType.string || SettingType.password when value is String:
        await set(def, value, source: source);
      case SettingType.select
          when value is String &&
              (optionsFor(def).contains(value) ||
                  (def.key == cameraRtspResolution.key &&
                      isCameraStreamResolution(value)) ||
                  (def.key == screensaverMode.key &&
                      isPluginScreensaver(value)) ||
                  (isVoiceSkinSetting(def.key) && isPluginVoiceSkin(value))):
        await set(def, value, source: source);
      default:
        return false;
    }
    return true;
  }

  /// Snapshot of definitions + values for the remote API and settings UI.
  /// Secrets report whether they are set, never their value.
  /// Whether [def] should be shown at all: its [SettingDef.dependsOn] switch
  /// is on, or it has none.
  bool visible(SettingDef<Object> def) {
    // Both gates must hold, each through its own chain; a row with one
    // gate has the second trivially satisfied.
    return _gateHolds(def.dependsOn, def.dependsSatisfiedBy) &&
        _gateHolds(def.alsoDependsOn, def.alsoDependsSatisfiedBy);
  }

  bool _gateHolds(String? key, bool Function(Object?) satisfied) {
    if (key == null) return true;
    final dep = allSettings.where((d) => d.key == key).firstOrNull;
    // A dependency that does not exist is a typo in the definitions, and
    // hiding the row would hide the evidence.
    if (dep == null) return true;
    // Transitive: the dependency must both hold *and* itself be visible, so a
    // setting can gate on a hidden flag that gates on the mode (folder
    // playlist settings → media_is_folder → mode == media).
    return satisfied(get(dep)) && visible(dep);
  }

  List<Map<String, Object?>> describe({Set<String>? keys}) => [
    for (final def in allSettings.where(
      (def) => keys == null || keys.contains(def.key),
    ))
      {
        'key': def.key,
        'type': def.type.name,
        'title': def.title,
        'description': def.description,
        if (def.titleMessageId != null) 'titleMessageId': def.titleMessageId,
        if (def.descriptionMessageId != null)
          'descriptionMessageId': def.descriptionMessageId,
        if (def.optionMessageIds != null)
          'optionMessageIds': def.optionMessageIds,
        if (def.placeholderMessageId != null)
          'placeholderMessageId': def.placeholderMessageId,
        'category': def.category,
        if (def.section != null) 'section': def.section,
        // The remote admin folds these into the same second-level page the
        // device shows; their hints come from subpageHints, served beside
        // the definitions (a page can have no settings of its own).
        if (def.subpage != null) 'subpage': def.subpage,
        // The remote admin renders these too, and must hide what the
        // device hides.
        if (def.dependsOn != null) 'dependsOn': def.dependsOn,
        if (def.dependsOn != null) 'dependsOnValue': def.dependsOnValue,
        if (def.alsoDependsOn != null) 'alsoDependsOn': def.alsoDependsOn,
        if (def.alsoDependsOn != null)
          'alsoDependsOnValue': def.alsoDependsOnValue,
        if (def.hidden || deviceHiddenKeys.contains(def.key)) 'hidden': true,
        if (def.multiline) 'multiline': true,
        if (def.linksTo != null) 'linksTo': def.linksTo,
        if (def.placeholder != null) 'placeholder': def.placeholder,
        if (def.options != null) 'options': optionsFor(def),
        if (def.key == cameraRtspResolution.key)
          'notice': cameraResolutionNotice,
        if (def.optionLabels != null)
          'optionLabels': {
            ...?def.optionLabels,
            if (def.key == cameraRtspResolution.key)
              for (final size in optionsFor(def))
                size: cameraResolutionLabel(size),
            if (def.key == screensaverMode.key) ...pluginScreensavers(),
            if (_realtimeLists.containsKey(def.key))
              for (final option in optionsFor(def))
                if (option.isNotEmpty) option: optionLabel(def, option)!,
            if (def.key == screensaverMode.key &&
                isPluginScreensaver(get(def)) &&
                !pluginScreensavers().containsKey(get(def)))
              get(def) as String: 'Unavailable plugin screensaver',
            if (isVoiceSkinSetting(def.key)) ...pluginVoiceSkins(),
            if (def.key == voiceAmazonLocale.key)
              for (final locale in PryonCatalog.locales)
                locale: PryonCatalog.localeLabel(locale),
            if (isVoiceSkinSetting(def.key) &&
                isPluginVoiceSkin(get(def)) &&
                !pluginVoiceSkins().containsKey(get(def)))
              get(def) as String: 'Unavailable plugin skin',
          },
        // Number ranges: with min+max present the remote renders a
        // slider, exactly as the device does.
        if (def.min != null) 'min': def.min,
        if (def.max != null) 'max': def.max,
        if (def.step != null) 'step': def.step,
        if (def.unit != null) 'unit': def.unit,
        'default': def.secret ? null : def.defaultValue,
        'value': def.secret
            ? ((get(def) as String).isNotEmpty ? '__set__' : '')
            : get(def),
        'secret': def.secret,
        // What Fleet Management never pushes to another kiosk.
        if (def.perDevice) 'perDevice': true,
      },
  ];

  /// Full config for provisioning. Secrets included only when [withSecrets].
  Map<String, Object?> export({bool withSecrets = false}) => {
    for (final def in allSettings)
      if ((!def.secret || withSecrets) && def.linksTo == null)
        def.key: get(def),
  };

  /// Drops one specific device's identity from an incoming settings [map],
  /// for imports that clone a device to run side by side rather than
  /// replace it: the device name, which two devices would otherwise
  /// share in Home Assistant (issue #25), and the Sendspin player id, under which two devices kick each other off Music
  /// Assistant in a reconnect loop so neither ever syncs (issue #136).
  /// Shared by the importConfig command and the raw /api/settings/import
  /// endpoint, which used to apply the dump verbatim (issue #221). The
  /// ESPHome node name goes with them: it is the mDNS instance and the
  /// `<name>.local` host, so two kiosks answering to it is a name clash
  /// on the network (the next start names this one after its own device
  /// name, or falls back to its generated identity). The hostname is the
  /// same kind of thing, and goes the same way.
  ///
  /// A device that inherited one of these identities from an older
  /// verbatim clone would keep colliding by "keeping its own"; equality
  /// with the incoming value is that inheritance, so it is shed too (the
  /// ids regenerate at the next Sendspin connect, the name is the user's
  /// to re-set).
  Future<void> shedImportedIdentity(Map<String, Object?> map) async {
    // A kiosk's place in a fleet is its own too: a clone must not lead the
    // original's followers (their tokens name the original) or believe it
    // follows the original's leader.
    final importedFleetId = map[fleetId.key];
    map.removeWhere((k, _) => k.startsWith('fleet.'));
    if (importedFleetId is String &&
        importedFleetId.isNotEmpty &&
        get(fleetId) == importedFleetId) {
      // The fleet manager writes this device's Android ID back.
      await set(fleetId, '');
    }
    final importedName = map.remove(deviceName.key);
    final importedPlayer = map.remove(sendspinClientId.key);
    final importedNode = map.remove(esphomeNodeName.key);
    final importedHost = map.remove(deviceHostname.key);
    if (importedName is String &&
        importedName.isNotEmpty &&
        get(deviceName) == importedName) {
      await set(deviceName, '');
    }
    if (importedPlayer is String &&
        importedPlayer.isNotEmpty &&
        get(sendspinClientId) == importedPlayer) {
      await set(sendspinClientId, '');
    }
    if (importedNode is String &&
        importedNode.isNotEmpty &&
        get(esphomeNodeName) == importedNode) {
      await set(esphomeNodeName, '');
    }
    if (importedHost is String &&
        importedHost.isNotEmpty &&
        get(deviceHostname) == importedHost) {
      await set(deviceHostname, '');
    }
  }

  /// [source] names who the batch came from on the log lines: a backup
  /// import by default, the fleet leader for a push.
  Future<int> import(
    Map<String, Object?> config, {
    String source = 'import',
  }) async {
    importing = true;
    try {
      var applied = 0;
      for (final entry in config.entries) {
        if (await setFromJson(
          entry.key,
          entry.value,
          source: source,
          batch: config,
        )) {
          applied++;
        }
      }
      return applied;
    } finally {
      // The bus delivers SettingChanged asynchronously, so listeners for
      // this batch can still be running when the loop ends; hold the flag
      // through a generous settle window rather than dropping it on a
      // microtask boundary nobody can reason about.
      unawaited(
        Future<void>.delayed(
          const Duration(seconds: 1),
          () => importing = false,
        ),
      );
    }
  }
}
