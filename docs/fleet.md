# Fleet Management

In a fleet setup, one kiosk acts as the leader while the others follow. The leader pushes configuration categories to its followers. If devices are running different software versions, the leader pauses the sync until it can bring the entire fleet onto the same release. A kiosk's core identity, including its name, Home Assistant, Music Assistant, ESPHome profiles, and hardware preferences, never syncs; it always stays local.

You can access these controls via **Settings, Fleet Management** on the kiosk, or the **Fleet Management** tab in the remote admin interface. Both devices must have **Remote management** and **Find other kiosks** enabled (located under Settings, Device, Remote Administration). Kiosks use the remote admin to discover and communicate with each other.

Once a kiosk joins, its membership survives missing mDNS advertisements. The leader keeps follower addresses and shares the member directory with followers so they can list the leader and each other in the remote admin switcher and intercom. The directory survives app restarts and updates separately from settings, including when versions differ. Discovery refreshes addresses when available. Saved addresses still need to be reachable from the device opening them. Fleet membership does not provide a network relay.

## Roles

| Role | How to Assign | Limitations |
| --- | --- | --- |
| Leader | Select **Lead this fleet** on the Fleet Management page. | Cannot follow another kiosk. |
| Follower | Accept a leader's invitation on the kiosk screen or in its remote admin. | Limited to one leader; cannot lead. |
| Standalone | The default state. | None. |

It is perfectly fine to have multiple fleets on a single network. A kiosk that needs to share a different set of settings can simply lead its own distinct fleet.

## Adding a Kiosk

1. On the leader device, tap **Add a kiosk** to view discovered devices. If the kiosk is not discovered, choose **Add by IP**, enter its IP address and remote admin port (2324 by default) then tap **Find kiosk**. This option is also available in remote administration and works without mDNS advertisements. The leader verifies the kiosk before you continue. Kiosks already following another leader must leave that fleet first. A kiosk on a different version can join but settings sync waits until its version matches.
2. Select a kiosk, assign it a profile, and tap **Send invitation**.
3. The invitation will overlay on the target kiosk's screen, staying under its Settings, Fleet Management until answered. Tap **Accept** on that device, or in its remote admin under Overview, Needs attention or on its Fleet Management page. No passwords are required.
4. The leader's dashboard will display **Waiting for its OK** until accepted, after which it syncs immediately.

Accepting an invitation grants the leader a token valid only for fleet endpoints, which is honored as long as the kiosk remains in the fleet. Tapping **Leave the fleet** forgets the leader and revokes the token.

To keep each follower's settings, choose the **Updates only** profile before sending its invitation. Entering an IP address does not skip the follower's acceptance step or make an unreachable address accessible. Both kiosks must be able to reach each other's remote admin ports. IPv4 and IPv6 addresses are supported.

## Profiles

Profiles determine exactly what a follower receives. Two ship with the app. The **Default** profile can be customized. The **Updates only** profile syncs nothing: a kiosk on it keeps every setting of its own and only gets updates pushed by the leader, which is the profile for a fleet you only want to keep on one version. It cannot be changed or deleted, but it can be duplicated as a starting point. The leader can create and assign new ones under **Profiles**. You can assign a profile when adding a kiosk or later from the device row's overflow menu. If a device uses a custom profile, its name appears as a tag on the row. 

Each profile has its own settings page where you can manage categories, plugins, credentials, dashboard inclusion, and excluded settings. Deleting a custom profile simply reverts its assigned kiosks back to the Default profile. Profile names must be unique to the leader.

A profile consists of:

| Component | Description |
| --- | --- |
| Categories | Checkboxes for each sidebar category, indicating which internal settings are excluded. |
| Plugins | The leader's plugins its kiosks install, with their settings. See [Plugins](#plugins). |
| Credentials | Toggles that allow a kiosk to keep its local Home Assistant user while still sharing the Music Assistant and Immich accounts and the [intercom key](intercom.md). |
| Dashboard | Toggles whether the start page and default dashboard are synced. |
| Excluded settings | Specific settings omitted from the sync, with options to re-add them or pick new ones to exclude. |

| Switch | Default | Off Behavior | On Behavior |
| --- | --- | --- | --- |
| Home Assistant token | Off | Kiosk keeps its own (stays as its local user). | Token syncs across fleet. |
| Music Assistant token | On | Kiosk keeps its own. | Token syncs across fleet. |
| Immich API key | On | Kiosk keeps its own. | Token syncs across fleet. |
| OpenAI API key | Off | Kiosk keeps its own. | Key syncs across fleet, and each follower validates it on its own. |
| xAI API key | Off | Kiosk keeps its own. | Key syncs across fleet, and each follower validates it on its own. |
| Gemini API key | Off | Kiosk keeps its own. | Key syncs across fleet, and each follower validates it on its own. |
| MCP server token | Off | Kiosk keeps its own. | Token syncs across fleet. |
| Plugin secrets | Off | Kiosk keeps its own secret plugin settings. | Secret plugin settings sync with their plugins. |
| Include the dashboard | Off | Kiosk keeps its local start page and dashboard. | Start page and dashboard sync. |

The realtime keys are off by default because each provider bills per use. A profile saved before they became credentials keeps them on where it syncs Voice Satellite, as they were before. When a follower receives a realtime key or endpoint, it runs the same connection test as **Save & Validate**. The provider becomes a choice for its wake words once that passes, and the provider's row shows the error if it fails.

### Excluded by Default

Settings that scale the UI, control screen brightness, or manage volume often depend on the specific physical panel or room environment. Therefore, every new profile excludes these hardware-specific settings by default. You can manually bring any of these back into a profile if needed.

| Setting | Page |
| --- | --- |
| `browser.zoom` Zoom level | Web Browsing |
| `screensaver.website_zoom` Zoom level | Screensaver, Website mode |
| `screensaver.clock_scale` Clock size | Clock screensaver |
| `screensaver.widget_scale` Global widget scaling | Widgets |
| `screensaver.immich_metadata_scale` Text scaling | Immich Media screensaver, Metadata |
| `screensaver.glance_scale` Row scaling | At a Glance |
| `face.preview_scale` Preview scaling | Face Detection |
| `sendspin.player_size` Player size | Floating Player |
| `screen.default_brightness` Default brightness | Screen & Audio |
| `screen.adaptive_min_brightness`, `screen.adaptive_max_brightness`, `screen.adaptive_dark_lux`, `screen.adaptive_bright_lux` (the curve's two middle points travel whenever Minimum brightness does) | Adaptive brightness |
| `screen.adaptive_use_entity` Use Home Assistant entity, `screen.adaptive_light_entity` Light sensor entity | Adaptive brightness |
| `motion.use_entity` Use Home Assistant entity, `motion.entity` Motion sensor entity | Screensaver, Motion Detection |
| `screensaver.brightness_level`, `screensaver.dim_level` | Screensaver |
| `audio.media_volume` Media volume, `audio.assistant_volume` Assistant volume | Screen & Audio |
| `notifications.volume` Notification volume | Notifications |
| `ha.tap_sound_volume` Tap sound volume | Home Assistant, User Interface |
| `voice_chimes.wake_volume`, `voice_chimes.done_volume`, `voice_chimes.error_volume`, `voice_chimes.alert_volume`, `voice_chimes.announce_volume` Chime volumes | Voice Satellite, Chimes |
| `screensaver.gallery_items` Photo Gallery selection | Photo Gallery screensaver |
| `screensaver.local_folder` Local media folder | Local Media screensaver |
| `screensaver.clock_background` Clock background photo | Clock screensaver |
| `notifications.chime_file` Notification sound | Notifications |
| `launcher.apps` Apps, which carries `kiosk.allowed_apps` Allowed Apps | App Launcher |
| `motion.sensitivity`, `motion.fps` | Camera |
| `face.sensitivity` | Face Detection |
| `camera.snapshot_resolution` | Camera |
| `browser.cutout_mode` Display cutout | Screen & Audio |
| `screen.orientation` Screen orientation | Screen & Audio |
| `intercom.volume` Intercom volume | Screen & Audio |
| `intercom.answer_mode` Answer mode, which carries Do not disturb | Intercom |
| `voice.mute` Mute, `voice.tts_output` Play sounds on | Voice Satellite |

## How the Sync Runs

| Detail | How it Works |
| --- | --- |
| When | Syncs trigger when a leader's settings change, a profile changes, a follower reconnects, a follower modifies a synced setting locally, or manually via **Sync now**. |
| What | The full set of synced settings is checked. Followers only apply differing values, preventing unnecessary restarts. |
| Versions | Syncing only occurs between kiosks with matching version names (build numbers are ignored). The leader flags required updates and resumes automatically once matched. |
| Drift | If a synced setting is changed locally on a follower, the leader overwrites it during the next sync (a banner warns of this on the category page). |
| Cadence | Devices are polled every 30 seconds if the Fleet Management menu is open, and every 5 minutes otherwise (or instantly on any change). |
| Offline | Followers whose admin endpoints do not answer are marked **Offline** and retried on later polls. |

Every poll tries known followers at their saved addresses even if mDNS has not heard them. Removing a member updates the directory on reachable followers at the next poll. A follower clears its saved directory when it leaves. Older releases keep their discovery behavior until upgraded.

## Plugins

A profile's **Plugins** row picks which of the leader's plugins its kiosks get. Each follower on the profile installs the package the leader runs, then takes its settings, whether it is enabled and where its actions show in the drawer and in Home Assistant. The leader sends the package itself over the local network, so followers get exactly the bytes the leader installed and never download it again. When the leader updates, reinstalls or removes a plugin, its followers do the same at the next sync.

Secret plugin settings, such as a token, travel only when the profile includes **Plugin secrets** under Credentials. Otherwise each follower keeps its own.

| Detail | How it Works |
| --- | --- |
| Enable Plugins | Stays per kiosk. A follower with it off installs and configures the plugins but runs them only once it is switched on. |
| Removal | When a plugin leaves the profile or the leader, a follower removes it only if the fleet installed it. A plugin the kiosk had before stays with its last settings. |
| Local changes | A change to a synced plugin on a follower is replaced at the next sync, and a banner on its Plugin Manager page says so. Its update check is off there, since the leader keeps it up to date. |
| Failures | A package a follower cannot install, for example one that needs a newer Android version or a screen the follower does not have, shows on its row on the leader with the reason. The leader tries again when the plugin changes or with **Sync now**. |
| Earlier installs | The leader keeps a copy of each package it installs. A repository plugin installed on an earlier version is fetched again from its GitHub release and checked against the SHA-256 it was installed with. A plugin installed from a ZIP on an earlier version has to be installed again on the leader before it can sync. |

A plugin that uses Shizuku asks for its permission on each kiosk. Runtime chart data, history and plugin entity declarations and readings are never synchronized. Plugin entity exclusions, a plugin screensaver picked as the screensaver mode and gestures assigned to plugin actions stay local. A fleet token cannot call plugin management commands.

## Updates

Using **Update the fleet** prioritizes installations on followers first, updating the leader last so it stays online to manage the process. If a kiosk has a pinned screen, it will prompt for the update directly on its display. **Keep followers on this version** automatically handles updates if a follower falls behind the leader's current release.

## Restoring the Leader

A configuration export from the leader carries the fleet: **Lead this fleet**, the profiles, the followers and the id the followers know the leader by. To move the leader to a new device or bring it back after a factory reset, import the export and pick **Replace "device name"**. The restored leader takes over the old one's id and its followers keep syncing without new invitations. Turn off or reset the old leader first, since two kiosks with the same id confuse the followers. **Set up as new device** leaves the fleet out, so a kiosk cloned from the leader's export does not take over its followers.

Exports from older versions do not carry the leader's id. If the followers stop syncing after restoring one on a new or reset device, invite them again.

## Never Synced

Certain settings remain unique to each kiosk regardless of the profile configuration. Followers will automatically drop these settings even if a leader attempts to send them.

| Group | Keys |
| --- | --- |
| Identity | `device.name`, `device.hostname`, `esphome.node_name`, `esphome.mac_override`, `esphome.real_mac`, `btproxy.key`, `sendspin.client_id`, `sendspin.local_player_name`, `airplay.name`, `ha.satellite_entity` |
| Shizuku | `shizuku.install_updates` |
| Interface language | `ui.language` |
| Remote admin & fleet | `remote.enabled`, `remote.port`, `remote.tls`, `remote.password`, `remote.fleet_discovery`, `remote.admin_url`, `fleet.*` |
| Intercom encryption, hang up button and camera on auto answer | `intercom.tls`, `intercom.hangup_key`, `intercom.hangup_key_ringing`, `intercom.auto_answer_camera` |
| Alarms | `alarms.list`, `alarms.runtime` |
| Calendar | `calendar.hidden` |
| Hardware picks | `camera.device`, `camera.scan_screen_light`, `camera.rtsp.tls`, `camera.rtsp.resolution`, `camera.rtsp.analysis`, `motion.camera`, `audio.mic_device`, `audio.speaker_device`, `audio.mic_channel`, `audio.mic_capture_mode`, `audio.software_echo_cancellation`, `audio.echo_cancellation_method`, `audio.mic_noise_suppression`, `audio.mic_gain_db`, `audio.mic_capture_format`, `render.disable_impeller`, `render.legacy_webview`, `render.hybrid_plugin_overlays`, `ui.scale`, `screen.ambient_display` |
| Followed player | `sendspin.player`, `sendspin.player_source`, `sendspin.player_name`, `sendspin.handoff`, `sendspin.speaker_pill_players`, `sendspin.kept_for` |
| Weather preview | `screensaver.weather_preview`, `screensaver.weather_preview_condition`, `screensaver.weather_preview_period` |
| Celestial view and last GPS position | `screensaver.celestial_view`, `screensaver.celestial_last_gps` |
| Voice Satellite chimes | `voice_chimes.wake`, `voice_chimes.done`, `voice_chimes.error`, `voice_chimes.alert`, `voice_chimes.announce` |
| Diagnostics | `wake_word.diagnostics` |
| Wake word arbitration offset | `voice.wake_arbitration_offset_db` |
| Wake word fine-tune | `voice.wake_word_fine_tune` |
| Stop word fine-tune | `voice.stop_word_fine_tune` |
| Realtime talk over sensitivity | `voice.realtime_talk_over_sensitivity` |
| Wake words this kiosk listens for | `voice.wake_words`, `voice.pending_selects` |
| Local state | `voice.runtime`, `voice.timer_position`, `voice.dock_position`, `voice.realtime_openai_validated`, `voice.realtime_xai_validated`, `voice.realtime_gemini_validated`, `screensaver.saved_brightness`, `screensaver.immich_validated`, `sendspin.player_active`, `sendspin.player_pos`, `sendspin.sonos_hosts` |

Plugins sync only through a profile's **Plugins** row (see [Plugins](#plugins)). Plugin entity exclusions stay local even when ordinary ESPHome exclusions are synced, and the **Enable Plugins** master switch stays on each kiosk.

Gestures assigned to plugin actions also stay local, even when the profile includes Gestures. The leader omits them from its payload and the follower ignores any received plugin actions while preserving its own. A local plugin gesture takes precedence if an incoming ordinary gesture has the same ID. Adding, editing or removing a local plugin gesture does not mark the follower out of sync. Other gesture mappings still follow the profile.

The Voice Satellite selects Home Assistant keeps for each kiosk travel with the Voice Satellite category: Assistant 1 and 2, Wake word 1 and 2 and Finished speaking detection. A follower sets its own selects in Home Assistant to the leader's picks, so Home Assistant configures it the same way it would for a pick made by hand. A follower keeps its own pick when Home Assistant does not offer the leader's, for example a model the follower lacks. The `voice.wake_words` setting in the table above is the kiosk's copy of what Home Assistant set, so it never travels on its own.

The Alarms category carries the alarm defaults (the volume, the tone, snooze, Silence after and sunrise lengths). The [alarms](alarms.md) themselves, and a ring or snooze in progress, stay on each kiosk.

The Calendar category carries the [calendars](calendar.md) with their names, colors and people, and the Display and Kiosk settings. The calendars hidden with their chips stay on each kiosk.

Custom wake word models are the exception: a leader passes its models to every follower whose profile syncs Voice Satellite, and those followers mirror the leader's set. See [Custom Wake Word Models](custom-wake-words.md).

Files referenced by settings (like notification chimes, alarm tones, gallery photos, or local media folders) do not sync; only their file paths travel. If a follower lacks the corresponding file, it defaults back just as it would for a missing local file. The Voice Satellite selection lives on the page itself and also stays strictly local to the kiosk.

## Remote API

| Endpoint | Method | Token | Description |
| --- | --- | --- | --- |
| `/api/fleet/identity` | GET | none | `{id, name, version, leader, follows}`: Identifies the kiosk to other devices. |
| `/api/fleet/invite` | POST | none | `{invite, leader: {id, name, version, port}}`. Verifies the source kiosk, then displays the invite on-screen. Rate limited. |
| `/api/fleet/invite/<nonce>` | GET | none | `{status}`: Returns `pending`, `accepted` (includes `token` once), `declined`, or `unknown`. |
| `/api/fleet/status` | GET | fleet | Returns the version, applied revision, local changes to synced settings and plugins, the installed plugin packages by SHA-256, the synced plugins that failed, and update status. |
| `/api/fleet/plugins?sha256=` | PUT | fleet | The raw plugin ZIP. Held until the next `/api/fleet/apply` installs it, and refused when its SHA-256 differs. |
| `/api/fleet/apply` | POST | fleet | `{revision, version, settings, plugins}`. Held in queue if versions differ. |
| `/api/fleet/leave` | POST | fleet | Notifies the kiosk that the leader removed it from the fleet. |
| `/api/fleet/roster` | POST | fleet | `{devices: [{id, name, version, address, port}]}`: Replaces the saved member directory independently of settings sync. Contains no fleet tokens. |
| `/api/fleet/export` | GET | admin | Backs up the whole fleet in one file: `{kind, version, exportedAt, devices: [{id, name, self, config}]}`. Each `config` is that kiosk's `/api/config/export`, secrets included. A follower that does not answer carries `error` in place of `config`. Restore a kiosk by posting its `config` to that kiosk's `/api/config/import`. |

The status response includes `rosterRevision` on releases that support the directory. The leader sends a roster only when that revision differs from its current member list.

For manual invitations, call `fleetLookup` with `{address, port}` to verify the target. It returns the kiosk identity and normalized endpoint without saving a member. Pass its `id`, `address` and `port` to `fleetInvite` with the chosen `profile`. The leader verifies the identity again before sending the invitation. Omitting `address` keeps the discovered or saved address path.

A fleet token also grants access to `getUpdateStatus`, `checkUpdateNow`, `installUpdate` and `installUploadedApk` under `/api/commands/`, to `POST /api/update/upload` and to `GET /api/config/export` for the fleet export, but nothing else. Both pages utilize commands like: `fleetStatus`, `fleetCandidates`, `fleetInvite`, `fleetSetProfile`, `fleetDeleteProfile`, `fleetAssignProfile`, `fleetSyncable`, `fleetRemove`, `fleetSyncNow`, `fleetUpdate`, `fleetInstallUploaded`, `fleetExport`, `fleetAccept`, `fleetDecline` and `fleetLeave`. A fleet token cannot run `fleetAccept` or `fleetDecline`, only an admin session can. The WebSocket broadcast includes a `fleetsync` event upon any change.

## Encrypted kiosk connections

Enable **Use HTTPS** under **Device > Remote Administration** on each kiosk you want to encrypt. Existing HTTP kiosks can stay in the same fleet. Discovery and saved fleet directories carry the protocol for each member.

Fleet and intercom connections accept the device's self-signed certificate automatically. There is no certificate pairing or trust list to maintain. These connections encrypt traffic without verifying the peer certificate. Existing fleet tokens and intercom keys still control access. Home Assistant connections and external downloads keep their existing certificate checks.

Renewing, replacing or importing a certificate does not require updating other kiosks. TLS preferences and private keys stay on each device. Fleet synchronization never copies them.

See [TLS encryption](tls.md) for independent admin, camera and intercom settings.
