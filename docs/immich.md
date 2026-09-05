# Kiosk Satellite Immich Screensaver

Kiosk Satellite can turn your device into a smart digital photo frame using an [Immich](https://immich.app/) server. Point it at your library or specific albums to enjoy full screen slideshows, customizable transition effects, an optional metadata overlay, and local image caching for instant loading. It even plays videos from your selection in full with audio muted.

## Setup

1. In Immich, generate an API key under **Account Settings > API Keys**. A full access key works great. If you prefer a restricted key, make sure to grant `album.read`, `asset.read`, and `asset.view` permissions. Add `person.read` if you plan to filter by people, and `tag.read` for tag filtering (see [Filters](#filters)). Note that Immich separates viewing from downloading: `asset.view` handles the screen sized previews the screensaver uses, so `asset.download` is not required.
2. On your device, go to **Settings > Screensaver** and set the mode to **Immich Media** (or configure this from the Screensaver tab in the remote admin).
3. Enter your **Server address** (such as `http://immich.local:2283`) and your **API key**, then tap **Validate connection**. Validation tests the exact API endpoints the screensaver depends on, including album listings, asset searches, and preview fetches. If your key is missing a required permission, validation will explicitly name the issue rather than failing silently later. The preview check tests up to five assets from your selected source and passes on the first successful response. Once validated, the remaining settings will unlock. Updating the address or key will require validating again.

## Settings

The settings page is organized into five main sections: Server Connection, Media, Slideshow, Metadata, and Filters.

| Group | Setting | Default | Notes |
| --- | --- | --- | --- |
| Media | Media source | All media | Displays your whole library or specific albums you select from the server list, including shared albums. Photos appearing in multiple selected albums are only shown once. |
| Media | Photos only | off | Skips video assets during the slideshow. |
| Media | Cache media locally | on | Stores previews on the device for faster loading. |
| Media | Cache size (items) | 500 | Automatically purges the oldest cached files when full. Current usage displays beneath this field. |
| Slideshow | Seconds per image | 10 | Sets photo display duration. Videos ignore this setting and play through to completion. |
| Slideshow | Shuffle | off | Displays media in random order instead of the server default (newest first). |
| Slideshow | Transition | Crossfade | Options include none, crossfade, slide, zoom, Ken Burns, or random. |
| Slideshow | Fill the screen | Smart | Controls how aggressively photos are cropped to fit the screen. |
| Slideshow | Pair portrait photos | on | Displays two portrait photos side by side in landscape mode. |
| Slideshow | Tap edges to change slides | on | A tap on the left or right fifth of the screen shows the previous or next photo instead of dismissing the screensaver. |
| Metadata | Show metadata | off | Displays photo details in a designated corner of the screen. |
| Metadata | Album name, Date taken, Camera details, Location | on | Toggles individual metadata lines. |
| Metadata | Metadata position | Bottom left | Specifies which corner holds the photo details. |
| Filters | People | Anyone | Filter by specific recognized individuals. |
| Filters | Exclude people | No one | Exclude media containing specific individuals. |
| Filters | Tags | Any | Filter by specific Immich tags. |
| Filters | Favorites only | off | Limits the slideshow to photos marked as favorites in Immich. |
| Filters | Taken within | Any time | Restricts photos based on a rolling or pinned timeframe. |
| Filters | From | Any time | Defines the starting date for Since or Timeframe filters. |
| Filters | To | Today | Defines the ending date for the Timeframe filter. |

Your playlist refreshes from the server every time the screensaver starts. Any newly uploaded photos or album edits will show up during the next screensaver session.

## Filters

A full phone backup often contains receipts, documents, and screenshots alongside family memories. The **Filters** settings let you refine your source media so your screen displays only what belongs on a photo frame. Every active filter must be satisfied for a photo to appear, and photos are never duplicated.

* **People:** Displays media containing any of the selected individuals. Tap the row to select recognized people from your Immich library. Be sure to name your recognized face clusters in Immich first, as unnamed clusters will not appear in the picker. Individuals you have hidden in Immich will appear marked as **Hidden** with a struck out eye icon. Hiding someone in Immich only removes them from Immich's internal views, so both filters still work as expected.
* **Exclude people:** Automatically skips any media containing the specified people, regardless of who else is in the shot. Because Immich cannot perform this check directly, the kiosk requests person data for each asset and filters out matches locally.
* **Tags:** Limits media to assets tagged with specific keywords using full path names (e.g., `Family/Kids`).
* **Favorites only:** Restricts playback to items you have starred or favorited in Immich. This is often the easiest way to curate a display list.
* **Taken within:** Filters photos outside a specific time window. Rolling options include the past month, 3 months, 1 year, 2 years, 5 years, or 10 years, moving along automatically with the calendar. Selecting **Since** or **Timeframe** pins a fixed window instead. **Since** reveals a **From** date to display everything taken from that point forward. **Timeframe** reveals both **From** and **To** dates, displaying photos taken between those dates inclusive. You can select dates directly from the calendar picker or tap the month header to jump straight to a year. Tapping **Clear** in the picker leaves an end open, while choosing **Any time** removes the filter entirely. Fixed date ranges work best for events like weddings or births where you want a consistent starting point.

Selecting multiple people or tags acts as an "OR" filter rather than an "AND" filter. Because Immich interprets a person search as everyone present in a single photo, the kiosk searches for each person individually and merges the results. Selected names are saved on the device so settings load instantly without querying the server. Saving your settings automatically rebuilds the list, ensuring renamed or merged people in Immich update seamlessly.

Selecting people requires the `person.read` API permission, while tags require `tag.read`. If these permissions are missing, the key will still validate and run the screensaver, but the filter pickers will display a message indicating which permission is needed. If your filters produce no matching assets, the screensaver displays a helpful status message ("No media matches the source and filters.") instead of staying on a black screen.

## Fill the Screen

Most users prefer photos to fill the entire display. The **Fill the screen** setting controls how much cropping is allowed to achieve that edge to edge look.

| Setting | Effect |
| --- | --- |
| Off | Displays the full uncropped photo, placing black bars where aspect ratios differ. |
| Smart (default) | Enlarges photos to fill the display if the aspect ratio is close to the screen's dimensions (allowing up to roughly a 25 percent crop on one axis). This accommodates standard 4:3 and 16:9 camera shots on landscape displays. For portrait or square photos where cropping would ruin the composition, the photo remains uncropped in the center while an enlarged, blurred, and dimmed version of the image serves as the background instead of black bars. |
| Always | Forces every photo to fill the panel regardless of aspect ratio. Nothing is ever letterboxed, but cropping can be severe. A 4:3 image on a 2:1 screen loses about a third of its height, and a portrait photo on a landscape screen is cropped down to a narrow horizontal strip. |

The **Always** mode has no awareness of a photo's subject, so anything outside the crop area is lost. If a photo features an off center subject like a person or a pet, this setting may crop them out.

For portrait photos on landscape screens, the **Pair portrait photos** setting provides a much better solution without severe cropping.

## Pair Portrait Photos

Single portrait photos on a landscape display normally leave large blurred background areas on either side. With **Pair portrait photos** enabled (on by default), the app places two portrait photos side by side. Each photo occupies half the screen, filling the panel cleanly with photos rather than background blur. You can turn this setting off if you prefer each photo to appear solo.

A pair counts as a single slideshow entry: both photos display for the configured duration and transition together.

The pairing logic intelligently searches your playlist. When the playlist loads, each portrait photo looks ahead for the next available portrait image in the list and pairs up with it. This ensures that even if portrait shots are scattered randomly among landscape photos, every portrait photo gets paired. No photos are skipped or duplicated; the list order is simply rearranged following your shuffle settings.

To pair up, both images must be taller than they are wide (square images are excluded since fitting two on a screen would make them very small), and the device must be in landscape orientation. Videos are never paired. If an odd number of portrait photos leaves one without a partner, it displays on its own as usual. Photos are measured using the dimensions reported by Immich, which accounts for orientation EXIF tags automatically.

When the metadata overlay is enabled, a portrait pair displays two distinct sets of details: the left photo's information sits in the bottom left corner, and the right photo's details sit in the bottom right corner directly beneath each image. While a pair is on screen, any [widgets](screensavers.md#widgets) in those two bottom corners are temporarily hidden so details remain readable. They reappear automatically on the next single photo slide.

## Metadata Overlay

Enabling **Show metadata** places photo details in a designated corner of the screen. Each line features a subtle icon and only displays when the photo actually contains that metadata:

* Album name: Displays the selected album name. If multiple or no albums are selected, it shows an album the photo belongs to.
* Date taken: Displays the capture date.
* Camera details: Shows the camera model, focal length, aperture, and ISO derived from EXIF data.
* Location: Displays city, state, and country information from EXIF data.

Each metadata line has its own toggle switch. If you point your screensaver at a single album, you may want to turn off the album line so it doesn't repeat on every photo. Turning off a specific toggle also prevents the app from querying that data. If you turn off all metadata lines, the overlay and its background vignette turn off completely, behaving just as if **Show metadata** were disabled.

When placed in a right hand corner, text and icons align to the right, mirroring the layout of right aligned widgets.

The overlay rests on a subtle dark vignette to keep text readable against bright photos. You can adjust the **Vignette strength** slider from 0 to 100 percent (80 percent by default). Setting it to 0 removes the vignette entirely, leaving clean text over the photo.

When a pair of portrait photos is on screen, the overlay overrides your corner selection and uses both bottom corners so each photo's metadata sits directly underneath it.

## The Local Cache

With **Cache media locally** enabled, every displayed photo is stored directly on the device. Subsequent playlist loops load images directly from local storage instead of downloading them over the network again. The app caches Immich's screen sized previews rather than full resolution originals, keeping individual file sizes down to a few hundred kilobytes instead of tens of megabytes. When the cache reaches its configured limit, the oldest and least recently viewed items are automatically purged. Lowering the cache limit triggers an immediate cleanup. Videos are never cached locally and will always stream directly from the server.

## Troubleshooting

* **Validation fails with a permission message:** Your API key is restricted. Ensure it has `album.read`, `asset.read`, and `asset.view` permissions enabled in Immich.
* **"The API key is missing the asset.view permission":** Your key can search assets but cannot fetch previews. Add `asset.view` to the key permissions in Immich. You do not need to generate a new key; changes apply immediately.
* **The People or Tags picker indicates a permission is missing:** The key lacks `person.read` (for people) or `tag.read` (for tags). Grant the missing permission in Immich. The rest of the screensaver functions fine without them.
* **No individuals appear under People:** The picker relies on named individuals. Open Immich, assign names to your recognized face clusters on the People page, and reopen the picker. Hiding a person in Immich will not remove them from this list.
* **Validation passes but logs show a preview probe was skipped:** The selected asset does not have a preview generated on the server yet (it may still be processing, failed to generate, or belongs to an offline external library). Validation will test the next asset, and the screensaver will simply skip ungenerated photos during playback.
* **"Could not reach the Immich server":** The server address is incorrect, the server is offline, or the device cannot connect to your network. This message is reserved for true network transport errors (DNS failures, refused connections, or timeouts). If the server responds with an HTTP error code, the app displays that specific status instead. The screensaver will automatically attempt to reconnect (first after 15 seconds, then every minute), resuming the slideshow seamlessly once the connection recovers.
* **Diagnosing issues on the device:** Every failed Immich request is recorded with its endpoint URL and HTTP status in the app log (accessible via the Logs tab in the remote admin or at `GET /api/logs`), making it easy to diagnose issues without setting up network proxies.
* **Self-signed HTTPS certificates:** The app automatically accepts self signed certificate errors specifically for your configured Immich host. Note that videos play through the native system player, which enforces strict certificate checks. On a self signed HTTPS setup, photos will play normally, but videos will be skipped. Standard `http://` setups on local networks are completely unaffected.
* **A video fails to play:** The device lacks the required hardware codec, or you are using self signed HTTPS. Failed videos are logged and skipped automatically so the slideshow continues uninterrupted.
* **New photos do not show up:** The playlist refreshes when the screensaver starts up. If the screensaver is currently running, dismiss it once and let it restart to pull in new media.