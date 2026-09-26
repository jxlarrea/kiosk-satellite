# Fleet Management

In a fleet setup, one kiosk acts as the leader while the others follow. The leader pushes configuration categories to its followers. If devices are running different software versions, the leader pauses the sync until it can bring the entire fleet onto the same release. A kiosk's core identity, including its name, Home Assistant, Music Assistant, ESPHome profiles, and hardware preferences, never syncs; it always stays local.

You can access these controls via **Settings, Fleet Management** on the kiosk, or the **Fleet Management** tab in the remote admin interface. Both devices must have **Remote management** and **Find other kiosks** enabled (located under Settings, Device, Remote Administration). Kiosks use the remote admin to discover and communicate with each other.

Once a kiosk joins, its membership survives missing mDNS advertisements. The leader keeps follower addresses and shares the member directory with followers so they can list the leader and each other in the remote admin switcher and intercom. The directory survives app restarts and updates separately from settings, including when versions differ. Discovery refreshes addresses when available. Saved addresses still need to be reachable from the device opening them. Fleet membership does not provide a network relay.

## Roles

| Role | How to Assign | Limitations |
| --- | --- | --- |
| Leader | Select **Lead this fleet** on the Fleet Management page. | Cannot follow another kiosk. |
| Follower | Accept a leader's invitation directly on the screen. | Limited to one leader; cannot lead. |
| Standalone | The default state. | None. |

It is perfectly fine to have multiple fleets on a single network. A kiosk that needs to share a different set of settings can simply lead its own distinct fleet.

## Adding a Kiosk

1. On the leader device, tap **Add a kiosk** to view discovered devices. If the kiosk is not discovered, choose **Add by IP**, enter its IP address and remote admin port (2324 by default) then tap **Find kiosk**. This option is also available in remote administration and works without mDNS advertisements. The leader verifies the kiosk before you continue. Kiosks already following another leader must leave that fleet first. A kiosk on a different version can join but settings sync waits until its version matches.
2. Select a kiosk, assign it a profile, and tap **Send invitation**.
3. The invitation will overlay on the target kiosk's screen, staying under its Settings, Fleet Management until answered. You must tap **Accept** directly on that device. (While the remote admin shows the invite, it cannot accept it. No passwords are required.)
4. The leader's dashboard will display **Waiting for its OK** until accepted, after which it syncs immediately.

Accepting an invitation grants the leader a token valid only for fleet endpoints, which is honored as long as the kiosk remains in the fleet. Tapping **Leave the fleet** forgets the leader and revokes the token.

To keep each follower's settings, choose the **Updates only** profile before sending its invitation. Entering an IP address does not bypass the on-device acceptance step or make an unreachable address accessible. Both kiosks must be able to reach each other's remote admin ports. IPv4 and IPv6 addresses are supported.

## Profiles

Profiles determine exactly what a follower receives. Two ship with the app. The **Default** profile can be customized. The **Updates only** profile syncs nothing: a kiosk on it keeps every setting of its own and only gets updates pushed by the leader, which is the profile for a fleet you only want to keep on one version. It cannot be changed or deleted, but it can be duplicated as a starting point. The leader can create and assign new ones under **Profiles**. You can assign a profile when adding a kiosk or later from the device row's overflow menu. If a device uses a custom profile, its name appears as a tag on the row. 

Each profile has its own settings page where you can manage categories, credentials, dashboard inclusion, and excluded settings. Deleting a custom profile simply reverts its assigned kiosks back to the Default profile. Profile names must be unique to the leader.

A profile consists of:

| Component | Description |
| --- | --- |
| Categories | Checkboxes for each sidebar category, indicating which internal settings are excluded. |
| Credentials | Toggles that allow a kiosk to keep its local Home Assistant user while still sharing the Music Assistant and Immich accounts and the [intercom key](intercom.md). |
| Dashboard | Toggles whether the start page and default dashboard are synced. |
| Excluded settings | Specific settings omitted from the sync, with options to re-add them or pick new ones to exclude. |

| Switch | Default | Off Behavior | On Behavior |
| --- | --- | --- | --- |
| Home Assistant token | Off | Kiosk keeps its own (stays as its local user). | Token syncs across fleet. |
| Music Assistant token | On | Kiosk keeps its own. | Token syncs across fleet. |
| Immich API key | On | Kiosk keeps its own. | Token syncs across fleet. |
| Include the dashboard | Off | Kiosk keeps its local start page and dashboard. | Start page and dashboard sync. |

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
| `screen.adaptive_min_brightness`, `screen.adaptive_max_brightness`, `screen.adaptive_dark_lux`, `screen.adaptive_bright_lux` | Adaptive brightness |
| `screensaver.brightness_level`, `screensaver.dim_level` | Screensaver |
| `audio.media_volume` Media volume, `audio.assistant_volume` Assistant volume | Screen & Audio |
| `notifications.volume` Notification volume | Notifications |
| `ha.tap_sound_volume` Tap sound volume | Home Assistant Setup, User Interface |
| `screensaver.gallery_items` Photo Gallery selection | Photo Gallery screensaver |
| `screensaver.local_folder` Local media folder | Local Media screensaver |
| `screensaver.clock_background` Clock background photo | Clock screensaver |
| `notifications.chime_file` Notification sound | Notifications |
| `launcher.apps` Apps | App Launcher |
| `motion.sensitivity`, `motion.fps` | Camera |
| `face.sensitivity` | Face Detection |
| `camera.snapshot_resolution` | Camera |
| `browser.cutout_mode` Display cutout | Screen & Audio |
| `screen.orientation` Screen orientation | Screen & Audio |
| `intercom.volume` Intercom volume | Screen & Audio |
| `intercom.answer_mode` Answer mode, which carries Do not disturb | Intercom |

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

## Updates

Using **Update the fleet** prioritizes installations on followers first, updating the leader last so it stays online to manage the process. If a kiosk has a pinned screen, it will prompt for the update directly on its display. **Keep followers on this version** automatically handles updates if a follower falls behind the leader's current release.

## Never Synced

Certain settings remain unique to each kiosk regardless of the profile configuration. Followers will automatically drop these settings even if a leader attempts to send them.

| Group | Keys |
| --- | --- |
| Identity | `device.name`, `device.hostname`, `esphome.node_name`, `esphome.mac_override`, `esphome.real_mac`, `btproxy.key`, `sendspin.client_id`, `sendspin.local_player_name`, `ha.satellite_entity` |
| Shizuku | `shizuku.install_updates` |
| Interface language | `ui.language` |
| Remote admin & fleet | `remote.enabled`, `remote.port`, `remote.tls`, `remote.password`, `remote.fleet_discovery`, `fleet.*` |
| Intercom encryption | `intercom.tls` |
| Hardware picks | `camera.device`, `camera.rtsp.tls`, `camera.rtsp.resolution`, `camera.rtsp.analysis`, `motion.camera`, `audio.mic_device`, `audio.speaker_device`, `audio.mic_channel`, `audio.mic_source`, `audio.mic_echo_cancellation`, `audio.mic_gain_db`, `audio.mic_agc`, `audio.mic_noise_suppression`, `audio.mic_capture_format`, `render.disable_impeller`, `render.legacy_webview`, `ui.scale`, `screen.ambient_display` |
| Followed player | `sendspin.player`, `sendspin.player_source`, `sendspin.player_name` |
| Weather preview | `screensaver.weather_preview`, `screensaver.weather_preview_condition`, `screensaver.weather_preview_period` |
| Voice Satellite chimes | `voice_chimes.wake`, `voice_chimes.done`, `voice_chimes.error`, `voice_chimes.alert`, `voice_chimes.announce` |
| Wake word diagnostics | `wake_word.diagnostics` |
| Local state | `voice.timer_position`, `screensaver.saved_brightness`, `screensaver.immich_validated`, `sendspin.player_active`, `sendspin.player_pos`, `sendspin.sonos_hosts` |

Plugin Manager stays entirely local. Runtime chart data, history and plugin entity declarations and readings are never synchronized. Plugin entity exclusions stay local even when ordinary ESPHome exclusions are synced. Fleet sync does not copy installed plugins, packages, plugin settings, per-plugin enabled states, drawer or Home Assistant action placements or the **Enable Plugins** master switch. A fleet token cannot call plugin management commands.

Gestures assigned to plugin actions also stay local, even when the profile includes Gestures. The leader omits them from its payload and the follower ignores any received plugin actions while preserving its own. A local plugin gesture takes precedence if an incoming ordinary gesture has the same ID. Adding, editing or removing a local plugin gesture does not mark the follower out of sync. Other gesture mappings still follow the profile.

Files referenced by settings (like notification chimes, gallery photos, or local media folders) do not sync; only their file paths travel. If a follower lacks the corresponding file, it defaults back just as it would for a missing local file. The Voice Satellite selection lives on the page itself and also stays strictly local to the kiosk.

## Remote API

| Endpoint | Method | Token | Description |
| --- | --- | --- | --- |
| `/api/fleet/identity` | GET | none | `{id, name, version, leader, follows}`: Identifies the kiosk to other devices. |
| `/api/fleet/invite` | POST | none | `{invite, leader: {id, name, version, port}}`. Verifies the source kiosk, then displays the invite on-screen. Rate limited. |
| `/api/fleet/invite/<nonce>` | GET | none | `{status}`: Returns `pending`, `accepted` (includes `token` once), `declined`, or `unknown`. |
| `/api/fleet/status` | GET | fleet | Returns the version, applied revision, local changes to synced settings, and update status. |
| `/api/fleet/apply` | POST | fleet | `{revision, version, settings}`. Held in queue if versions differ. |
| `/api/fleet/leave` | POST | fleet | Notifies the kiosk that the leader removed it from the fleet. |
| `/api/fleet/roster` | POST | fleet | `{devices: [{id, name, version, address, port}]}`: Replaces the saved member directory independently of settings sync. Contains no fleet tokens. |

The status response includes `rosterRevision` on releases that support the directory. The leader sends a roster only when that revision differs from its current member list.

For manual invitations, call `fleetLookup` with `{address, port}` to verify the target. It returns the kiosk identity and normalized endpoint without saving a member. Pass its `id`, `address` and `port` to `fleetInvite` with the chosen `profile`. The leader verifies the identity again before sending the invitation. Omitting `address` keeps the discovered or saved address path.

A fleet token also grants access to `getUpdateStatus`, `checkUpdateNow`, `installUpdate` and `installUploadedApk` under `/api/commands/` and to `POST /api/update/upload`, but nothing else. Both pages utilize commands like: `fleetStatus`, `fleetCandidates`, `fleetInvite`, `fleetSetProfile`, `fleetDeleteProfile`, `fleetAssignProfile`, `fleetSyncable`, `fleetRemove`, `fleetSyncNow`, `fleetUpdate`, `fleetInstallUploaded`, and `fleetLeave`. Note that `fleetAccept` and `fleetDecline` are rejected if sent over the remote API. The WebSocket broadcast includes a `fleetsync` event upon any change.

## Encrypted kiosk connections

Enable **Use HTTPS** under **Device > Remote Administration** on each kiosk you want to encrypt. Existing HTTP kiosks can stay in the same fleet. Discovery and saved fleet directories carry the protocol for each member.

Fleet and intercom connections accept the device's self-signed certificate automatically. There is no certificate pairing or trust list to maintain. These connections encrypt traffic without verifying the peer certificate. Existing fleet tokens and intercom keys still control access. Home Assistant connections and external downloads keep their existing certificate checks.

Renewing, replacing or importing a certificate does not require updating other kiosks. TLS preferences and private keys stay on each device. Fleet synchronization never copies them.

See [TLS encryption](tls.md) for independent admin, camera and intercom settings.
