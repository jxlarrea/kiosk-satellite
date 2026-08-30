# Kiosk Satellite Immich Screensaver

Kiosk Satellite can use an [Immich](https://immich.app/) server as its
screensaver: point it at your library or the albums you pick and the kiosk
becomes a photo frame, with slideshow transitions, full screen photos, an
optional metadata overlay, and a local cache so images appear instantly.
Videos in the selection play too, muted and in full.

## Setup

1. In Immich, create an API key under **Account Settings → API Keys**. A
   full-access key works; a restricted key needs the `album.read`,
   `asset.read` and `asset.view` permissions, plus `person.read` to use
   the people filters and `tag.read` for the tag filter (see
   [Filters](#filters)). Note that Immich separates
   viewing from downloading: `asset.view` covers the screen-sized previews
   the screensaver actually fetches, and `asset.download` (originals) is
   neither a substitute for it nor needed.
2. On the device, Settings → **Screensaver** → set the screensaver mode to
   **Immich Media** (or do the same from the Screensaver tab in the remote
   admin).
3. Enter the **Server address** (for example `http://immich.local:2283`)
   and the **API key**, then tap **Validate connection**. Validation
   checks the exact calls the screensaver needs, album listing, asset
   search and a preview fetch, so a key that is missing a permission
   fails here naming it instead of failing silently at night. The preview
   check tries up to five assets of the selected source and passes on the
   first one that answers, since an asset the server has not generated a
   preview for yet says nothing about the key. The rest of
   the settings unlock once validation succeeds, and changing the address
   or key asks for a new validation.

## Settings

The page is five groups: Server Connection (the address, key and
Validate button above), then these.

| Group | Setting | Default | Notes |
| --- | --- | --- | --- |
| Media | Media source | All media | The whole library, or any number of albums ticked off the server's list. Shared albums are listed too. A photo in several picked albums shows once. |
| Media | Photos only | off | Skip videos in the slideshow. |
| Media | Cache media locally | on | See below. |
| Media | Cache size (items) | 500 | The oldest cached items are deleted once the cache is full. Live usage shows under the field. |
| Slideshow | Seconds per image | 10 | Videos ignore this and play to their end. |
| Slideshow | Shuffle | off | Random order instead of the server's newest-first order. |
| Slideshow | Transition | Crossfade | The same set every slideshow mode offers: none, crossfade, slide, zoom, Ken Burns, or random. |
| Slideshow | Fill the screen | Smart | See below. |
| Slideshow | Pair portrait photos | on | See below. |
| Metadata | Show metadata | off | See below. |
| Metadata | Album name, Date taken, Camera details, Location | on | One toggle per metadata line. |
| Metadata | Metadata position | Bottom left | Which corner the details sit in. |
| Filters | People | Anyone | See [Filters](#filters). |
| Filters | Exclude people | No one | See [Filters](#filters). |
| Filters | Tags | Any | See [Filters](#filters). |
| Filters | Favorites only | off | See [Filters](#filters). |
| Filters | Taken within | Any time | See [Filters](#filters). |
| Filters | From | Any time | The date Since and Timeframe start at. |
| Filters | To | Today | The date Timeframe ends at. |

The playlist is fetched from the server each time the screensaver
activates, so new uploads and album changes are picked up on the next
activation, not in the middle of a running session.

## Filters

A phone backup holds more than family photos: receipts, recipes, screen
grabs and the odd document. The **Filters** group narrows the chosen
source (the whole library or the picked albums) to what a photo frame should show.
Every filter that is set has to hold, and a photo is never shown twice.

- **People**: only media with any of these people in it. Tap the row and
  tick names off the list of people Immich has recognized and you have
  named. Unnamed face clusters are not offered, so name the family in
  Immich first. People you have hidden in Immich are offered, marked
  **Hidden** under a struck-out eye: hiding only takes them out of
  Immich's own listings, and both filters still work on them.
- **Exclude people**: skip media with any of these people, whoever else
  is in it. The same list, the opposite effect. Immich cannot answer this
  question on its own, so the kiosk asks for every asset's people and
  drops the matches itself, which costs a somewhat larger listing.
- **Tags**: only media carrying any of these tags, picked from Immich's
  tag list by full path (`Family/Kids`).
- **Favorites only**: only media marked as favorite in Immich. The
  quickest way to curate a frame is to heart the photos that belong on
  it.
- **Taken within**: skip media outside a window. The rolling choices are
  the past month, 3 months, year, 2, 5 or 10 years, and they move along
  with the calendar, so a frame set to the past year keeps showing the
  past year. **Since** and **Timeframe** pin the window instead: Since
  reveals a **From** date and shows everything taken from that day on,
  Timeframe reveals **From** and **To** and shows the days between them,
  both ends counting whole. Pick a date off the calendar on either
  surface, tapping the month heading to jump straight to a year rather
  than stepping months. **Clear** in the picker puts an end back to open,
  and Any time drops the filter altogether. A pinned window is the one to use for a
  frame that should start at a wedding, a birth or the year a scanned
  album begins, since a rolling one walks past it.

Picking several people (or tags) means any of them, not all of them at
once: Immich itself reads a list of people as "everyone in the same
photo", so the kiosk searches once per person and merges the answers.
The chosen names are stored on the device, so both settings pages show
them without asking the server, and every save rebuilds the list from
the server, so a person renamed in Immich picks up the new name and one
merged away drops out.

The people lists need the `person.read` permission on the API key and
the tag list needs `tag.read`; a key without them still validates and
runs the screensaver, and the picker says which permission is missing
when opened. With a filter set and nothing matching, the screensaver
says so ("No media matches the source and filters.") rather than
showing a black screen.

## Fill the screen

Most people want photos edge to edge. **Fill the screen** sets how far a
photo may be cropped to get there.

| Setting | What a photo gets |
| --- | --- |
| Off | Its full frame between black bars. |
| Smart (default) | Enlarged to cover the whole panel if its shape is close enough to the screen's, within about a 25 percent crop along one axis. This admits the common 4:3 and 16:9 camera frames on a landscape tablet in either orientation. Portrait and square photos, which such a crop would ruin, keep their full frame and get the photo itself, enlarged, blurred and dimmed, as the backdrop instead of black bars. |
| Always | Enlarged to cover the panel whatever its shape. Nothing is ever framed or letterboxed, at the cost of the crop: a 4:3 photo on a 2:1 panel loses roughly a third of its height, and a portrait photo on a landscape panel is cut down to a narrow band of its middle. |

**Always** has no way to know what a photo is of, so whatever the crop
takes is gone. On photos with a subject that is not centered, a person or
a pet, it is the setting most likely to cut off the thing worth seeing.

For portrait photos, **Pair portrait photos** below fills the panel with
no such loss.

## Pair portrait photos

A photo taken in portrait uses about a third of a landscape screen and
leaves the rest to the blurred backdrop. **Pair portrait photos**, on by
default, shows two portrait photos in a row side by side instead, half
the screen each, so the panel is filled with photos rather than
backdrop. Turn it off to give every photo the screen to itself.
The pair counts as one slide: it holds for the usual interval and then
both are replaced together.

A portrait photo is not limited to the photo that happens to follow it.
When the playlist is read, each portrait photo reaches ahead for the next
portrait photo anywhere in the list and brings it back to its side, so a
library with portrait shots scattered between landscape ones still pairs
them all. Nothing is shown twice or skipped; the order is only
rearranged, and it happens after the shuffle so it follows the order the
slideshow actually runs in.

Pairing needs both photos taller than wide (square ones do not pair,
since half a screen each would show them small) and the screen itself
landscape; videos never pair. A photo left without a partner, the odd one
out of an odd number of portrait shots, shows on its own exactly as
before. Photos are measured by the shape Immich reports, including the
orientation tag phones set instead of rotating the pixels, so a portrait
photo stored as a landscape frame still counts as portrait.

With the metadata overlay on, a pair carries two sets of details: the
left photo's in the bottom-left corner and the right photo's in the
bottom-right, each under its own photo. For as long as the pair is on
screen, any [widget](screensavers.md#widgets) in those two corners is
hidden, so nothing sits on top of the details; it reappears with the
next single photo.

## Metadata overlay

**Show metadata** puts the photo's details in a corner of the screen
(pick which one), each line with its own icon and only when the asset
actually carries the information:

- Album name: the one picked album, or, with several or none picked, an
  album the photo belongs to (a picked one first).
- Date taken.
- Camera details: the camera the photo was taken with, and its focal
  length, aperture and ISO, from EXIF. A line each, one toggle.
- Location: city, state and country from EXIF.

Each line has its own toggle, all on: pointing the screensaver at one
album makes its name the same on every photo, and the same goes for any
other line somebody would rather not read. With the album line off the
lookup it needs is never made either. Turn every line off and the
overlay stands down entirely, vignette included, exactly as if **Show
metadata** were off.

In a right-hand corner the lines are right-aligned with their icons on
the right, mirroring the layout of the corner widgets.

The overlay sits on a soft vignette like the corner widgets do. Its
**Vignette strength** slider (0 to 100 percent, 80 by default) sets how
dark, independently of the widgets' own slider, and 0 removes it,
leaving the text alone over the photo.

A pair of portrait photos overrides the chosen corner, using both bottom
corners so each photo's details sit under it.

## The local cache

With **Cache media locally** on, every image shown is kept on the device,
so later loops of the playlist load from disk instead of the network.
Images are fetched as Immich's screen-sized previews rather than
originals, so a cached item is a few hundred KB, not a 50 MB original.
When the cache exceeds the configured item cap, the least recently shown
items are deleted first; lowering the cap prunes immediately. Videos are
never cached, they stream from the server each time.

## Small clock

The screensaver's **Small clock** widget (added from the Widgets group
under the mode's settings) pairs well with this one: a corner
clock and date over the photos, with a soft vignette behind it so it
stays readable on bright pictures. Widgets own their corners: the
metadata overlay steps to the first free corner when a widget claims
its spot, so both are always readable at once.

## Troubleshooting

- **Validation fails with a permission message**: the API key is
  restricted too tightly. It needs `album.read`, `asset.read` and
  `asset.view`; the message names the one the failing call was denied.
- **"The API key is missing the asset.view permission"**: the key can
  search assets but not fetch their previews. Add `asset.view` to the key
  in Immich; the change applies immediately, no new key needed.
- **The People or Tags picker says a permission is missing**: the key
  lacks `person.read` (people) or `tag.read` (tags). Add it to the key in
  Immich; the rest of the screensaver does not need either.
- **Nobody is listed under People**: the filters pick by name, and Immich
  only has names for the people you have named under its People page.
  Name them there, then open the picker again. Hiding a person in Immich
  does not take them off this list.
- **Validation passes but the log says a preview probe was skipped**:
  that asset has no preview on the server yet (still being processed,
  generation failed, an external library not scanned, or the file is
  offline). Validation moves on to the next asset, and the screensaver
  skips such photos when it meets them.
- **"Could not reach the Immich server"**: the address is wrong, the
  server is down, or the tablet cannot route to it. This message is
  reserved for genuine transport failures (DNS, refused connections,
  timeouts); a server that answers with an error shows the HTTP status or
  the missing permission instead. The screensaver keeps trying on its own,
  first after 15 seconds and then at up to a minute apart, and the
  slideshow resumes by itself once the server answers again, so a device
  that drops its Wi-Fi overnight shows photos again without a restart.
- **Diagnosing from the device**: every failing Immich call is logged
  with its endpoint and HTTP status in the app's log (the Logs tab of the
  remote admin, or `GET /api/logs`), so there is no need to instrument a
  reverse proxy to see what the server answered.
- **Self-signed HTTPS**: certificate errors are accepted automatically
  for the configured Immich host (and only that host). One caveat: videos
  play through the platform player, which does its own certificate
  checking, so on a self-signed server videos are skipped while images
  work. Plain `http://` servers, the common LAN setup, are unaffected.
- **A video does not play**: the device lacks the codec, or the
  self-signed case above applies. Failed items are logged and skipped;
  the slideshow keeps going.
- **New photos do not appear**: the playlist refreshes when the
  screensaver next activates, not during a running session. Dismiss it
  once.
