# Music Library

The Music Library browses music on the kiosk and plays it on a speaker. It lists music from Music Assistant, from a Home Assistant speaker's media or from a Sonos household, and it plays on the player the [Now Playing](sendspin.md#full-screen-now-playing) view follows. Pick a speaker in the library and Now Playing, the floating player and every play from the library move to it.

Open it from **Music Library** in the kiosk menu or from the library button next to the close button on the Now Playing view. Both show once a source is set up. A dashboard button can open it with `ks://music-library` (see [Dashboard Links](dashboard-links.md)), a gesture with the **Open Music Library** action (see [Gestures](gestures.md)) and Home Assistant with the ESPHome **Show Music Library** button (see [ESPHome](esphome.md)). Take the menu entry out under [Device > User Interface > Drawer menu items](drawer-menu.md), turn the Now Playing button off under **Settings > Media Player > Music Library** and allow the library in a locked kiosk under **Kiosk Mode > Allowed Actions**.

## Sources

The source picker sits at the top of the sidebar on a tablet, at the top of the rail on a short screen such as the Echo Show 5 and next to the speaker picker on a phone. It lists the sources set up on the device.

| Source | What it lists | Needs |
| --- | --- | --- |
| Music Assistant | Discover, Search, the library's artists, albums, tracks, playlists, radio stations, podcasts and audiobooks, and Browse, which walks each music provider such as Spotify or a music folder. | The server address and token under **Media Player > Music Assistant**. |
| Home Assistant | The media the picked speaker's integration offers, such as a Sonos speaker's favorites, a Spotify account, Radio Browser and My media. Search shows when the speaker's integration supports it. | A Home Assistant speaker picked as the speaker. The list changes with the speaker. |
| Sonos | My Sonos favorites, Sonos playlists and the music library the speakers index from a shared folder. Lists with nothing in them stay hidden. | A Sonos speaker found or added under **Media Player > Sonos**. |

Discover shows the rows Music Assistant's own Discover page shows, in the same order. To hide, show or reorder them, edit the Discover page in Music Assistant and the library follows. Music Assistant saves that layout for each of its users, so the library uses the layout of the user the token belongs to. When Music Assistant recommends nothing, Discover shows what was played recently, your playlists, recently added tracks and radio stations instead. A row that mixes kinds, such as Recently played, says under each entry whether it is a track, an album, an artist or a playlist.

**Browse by genre** comes last on Discover, as on Music Assistant's page, with the eight genres that have the most music in your library. Each genre gets an icon picked from its name. Tap one to open the rows Music Assistant shows for that genre, such as its artists and albums.

Browse shows each music provider with its logo, as Music Assistant does.

The sort button next to the title of a Music Assistant list orders it **A to Z**, **Z to A**, **Recently played**, **Recently added** or **Most played**. Each list keeps its own order. On **Artists** the same menu has **Album artists only**, which leaves out artists who only appear on a few tracks, such as the contributors to a compilation. Home Assistant and Sonos lists keep the order the source gives them.

Picture, camera and text-to-speech sources in Home Assistant's media are left out, since a speaker has nothing to play from them.

## Speakers

The speaker pill at the top shows where the music plays. Tap it to open **Speakers**:

- **Playing on** names the speaker and its group, with a volume slider for the speaker or the whole group, and one for each speaker in the group.
- **Group** opens the list of speakers that can join it. Tick a speaker to add it and clear it to take it out.
- **Other speakers** lists the source's other speakers. Tap one to play there instead. It becomes the player Now Playing follows, the same as picking it under **Media Player > Player**.

Each source lists only its own speakers, so a speaker is never listed twice. Music Assistant also lists this device's own player while Sendspin is on. The Home Assistant list leaves out the speakers Music Assistant adds to Home Assistant, which are already in the Music Assistant list.

When a play needs a speaker of the source first, such as Home Assistant before any of its speakers is picked, Speakers opens and asks for one.

## Playing music

- Tap an album, playlist, artist or folder to open it. Tap **Play** to replace the queue with it.
- Tap a track in an album or playlist to play the album or playlist from that track.
- Tap a radio station, a podcast episode or a track in a list to play it.
- Tap the menu button on a row, or long press a card, for **Play now**, **Play next**, **Add to queue**, **Start radio**, **Go to artist** and **Add to favorites**. Start radio and favorites are Music Assistant only. Start radio keeps playing similar music after the track, album, artist or playlist ends.

Play next and Add to queue show a message, and its **View** button opens the [queue](#the-queue). A play shows a spinner over the cover you tapped, and the player bar shows it with **Loading…** until the speaker starts it.

The player bar at the bottom works like Music Assistant's. The track and its favorite heart sit on the left. Shuffle, previous, play or pause, next and repeat sit over the seek bar in the middle. The [queue](#the-queue), the volume and the button that opens Now Playing sit on the right. Each control shows only where the player supports it, as on Now Playing. With nothing playing, the bar shows the track the queue would resume from: play starts the queue there, and previous and next move through it. Tap the track to open the Now Playing view over the library, and close Now Playing to come back to the library. On a short screen the seek bar becomes a line along the top of the bar, and the volume button opens Speakers. On a phone the bar keeps the track, play or pause, next and the queue.

## The queue

The queue button on the player bar opens the queue of the speaker the library plays on. On a tablet in landscape it docks to the right of the library. On a tablet in portrait, a short screen or a phone it takes the library's place until you close it. It also opens from **View** on the message after Play next or Add to queue.

- The playing track sits at the top under **Now playing**, and what comes next is listed under **Up next**.
- Drag a track by its handle to move it.
- Swipe a track to the left to remove it.
- Tap a track to play it now, or use its menu for **Play now**, **Play next** and **Remove from queue**.
- **Clear** empties the queue and stops the music, after asking first.

Music Assistant players, this device's own player and Sonos speakers have a queue to manage. A Home Assistant speaker has none, so the queue button does not show for it.

## Playing music by voice

Kiosk Satellite ships a blueprint for an LLM conversation agent (Qwen, Gemma, Gemini, Claude, OpenAI or any other agent that can control Home Assistant) that plays music on the speaker the kiosk you are talking to plays on. The agent understands the request in any language it speaks.

The built-in **Home Assistant** conversation agent does not work for this. It only matches sentences against Home Assistant's own intents and cannot fill in the script's title, artist or speaker. An LLM agent with **Prefer handling commands locally** turned on works fine.

If you set up Music Assistant's own voice support for an LLM agent, delete the script you created from its blueprint or stop exposing it to Assist first. With both exposed the agent has two tools for the same request and picks either one.

> **Info:** The long-lived token under **Settings, Home Assistant** must belong to a Home Assistant administrator. This applies to every request the script handles, including questions such as "What's playing?". Playing music from the Music Library on the kiosk works with any user's token. The kiosk listens for the script over its own Home Assistant connection. Home Assistant only lets administrators fire and follow the events the script runs on.

1. Import the blueprint:

    [![Open your Home Assistant instance and show the blueprint import dialog with a specific blueprint pre-filled.](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fjxlarrea%2Fkiosk-satellite%2Fblob%2Fmain%2Fblueprints%2Fscript%2Fkiosk_satellite_music.yaml)

2. Create a script from it.
3. Expose the script to Assist under **Settings, Voice assistants, Expose**.

Then ask the kiosk:

| Ask | What happens |
| --- | --- |
| "Play Punisher by Phoebe Bridgers" | Plays on the speaker this kiosk's Now Playing follows, replacing the queue. |
| "Play some jazz" | Plays what the source's search finds first for it, tracks before the rest. |
| "Play Lucy Dacus in the kitchen" | Plays on the Kitchen speaker, which becomes the one Now Playing follows. |
| "Play this album next" or "Add Thumbs to the queue" | Plays after the current track, or at the end of the queue. |
| "Start a radio from Clairo" | Plays and keeps going with similar music. Music Assistant only. |
| "Show me albums by Phoebe Bridgers" or "Open my playlists" | The Music Library opens on the kiosk, on a search or on that list. |
| "What's playing?" | The agent says the track, the artist and the speaker. |
| "Pause", "Skip this song" or "Go back" | Steers the music on the speaker this kiosk follows. |
| "Turn the music up" or "Set the music volume to 30" | Steps the volume by 10, or sets it. |
| "What's next in the queue?" or "Clear the queue" | Reads the playing track and the next ones, or empties the queue. |
| "Which speakers can you play on?" | Lists the speakers of the library's source. |

The kiosk searches the source of the speaker it plays on, so where the music comes from follows the speaker:

- **Music Assistant** searches every music provider it has, so any title, artist, album, playlist or station works.
- A **Home Assistant** speaker can be searched only when its integration supports search.
- A **Sonos** speaker has no search, so the request has to name one of its favorites.

Music in your library or among your favorites comes before the same name found on a music service, so "play Sola" plays the Sola in your library rather than an artist of that name on Spotify. When a title is both an album and a song, the album, playlist or artist plays and the agent can mention the other. Say "the song" or "the album" to pick one. Music that takes a while to start, such as a whole artist from a service, gets its answer after a few seconds while it keeps starting.

[Realtime conversations](voice-satellite.md#realtime-conversations) play music the same way: with **Tools** on **Home Assistant**, the model sees the exposed script and calls it while the conversation runs.

A request typed into Home Assistant's own chat reaches no kiosk until it names one, as in "play jazz on the kitchen kiosk", which matches the kiosk's device name or ESPHome name.

## Screen sizes

| Screen | Layout |
| --- | --- |
| Tablet | A sidebar with the source, Discover, Search, Browse and the library's lists. Albums show their cover and tracks side by side. |
| Short, such as the Echo Show 5 | A rail with the source and one entry each for Discover, Search, Library and Browse. Library shows its lists as chips. Discover drops the quick tiles at the top. |
| Phone | The source and speaker pickers under the title, tabs along the bottom and the player bar above them. Albums stack the cover over the tracks. |

While the keyboard is up for Search, the player bar and the tabs make room for the results.

## Settings

Under **Settings > Media Player > Music Library**:

| Setting | What it does |
| --- | --- |
| Source | The source the library opens on. **Automatic** starts with the source of the speaker Now Playing follows, else the first one set up. Picking a source in the library changes it too. |
| Show on Now Playing | Adds the library button next to the close button on the Now Playing view. On by default. |
| Close when idle | Returns to the dashboard after no touch for this long. Two minutes by default. The screensaver waits while the library is open. |
| Show in the kiosk menu | Opens [Device > User Interface > Drawer menu items](drawer-menu.md), where the Music Library entry is turned on or off. On by default. |

The **User Interface** group below them sets how the library looks:

| Setting | What it does |
| --- | --- |
| Text scale | The size of the text in the library, from 50% to 200%. Rows get taller with it, and the menus grow with it but keep their normal size below 100%. The title at the top, the navigation, the pickers and the player bar's track and times grow at a slower rate and keep their normal size below 100%. 100% by default. |
| Square artwork | Shows artists in square tiles, like albums and playlists, instead of circles. Off by default. |
| Grid density | The size of the tiles in the library's grids and rows. **Comfortable** makes them larger and **Compact** fits more in a row. **Standard** by default. |
| Show source selection | Shows the source picker in the library. Turn it off to keep the library on the **Source** set above, so nobody at the kiosk can switch it. The source can still be changed in Settings and in the remote admin. On by default. |
| Show speaker selection pill | Shows the speaker pill at the top of the library, which opens the speaker picker. A play with no speaker picked still asks for one, and on a screen without room for the volume slider the player bar's volume button still opens the picker. On by default. |

The **Voice Control** group opens the guide to [playing music by voice](#playing-music-by-voice).
