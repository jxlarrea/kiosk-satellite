# At a Glance

A quick row of essential Home Assistant entity states displayed right on your screensaver. It’s perfect for the things you check in passing: Is the garage open? Is the front door locked? You get the answers instantly without having to wake the device or navigate a dashboard.

## Setup

Navigate to **Settings**, then **Screensaver**, and select **At a Glance**:

| Setting | Notes |
| --- | --- |
| At a glance | Turns the status row on. |
| Entities | Select up to four entities to display, in the order they appear. |
| Show on Now Playing | Adds the status row to the full-screen Now Playing view. |

Under the **Appearance** section:

| Setting | Notes |
| --- | --- |
| Row scaling | Scales the entire row, similar to Widget scaling. |
| Hide names | Displays only the icon and the value (with the value drawn larger). |
| Monochromatic icons | Keeps all icons a neutral grey instead of their state-based color. |
| Floating text style | Uses floating text instead of chips (the row's original style). |

When you select **Entities**, a picker opens where you can search your Home Assistant setup by name or entity ID—no need to type from memory. Your chosen entities will sit at the top and can be easily reordered. This exact same picker is also available in the remote admin's Screensaver tab.

> Note: The row requires an active Home Assistant connection (Settings → Home Assistant Configuration).

## Where It Appears

The At a Glance row is available on every screensaver mode *except* the Camera Streams grid (since a status row would obscure a live video feed):

* **Black:** The row is centered and takes up the entire display.
* **Clock:** The row sits just under the date; the clock itself shrinks slightly to accommodate it.
* **Photo and Web Modes** (Home Assistant Media, Local Media, Photo Gallery, Immich, Website): The row is pinned near the bottom of the screen, layered over whatever the mode is displaying.

On the Immich screensaver, if the [metadata overlay](screensavers.md#immich-media) occupies a bottom corner, the status row intelligently narrows into two columns and wraps, staying clear of the corners rather than overlapping them.

On a landscape screen, entities display in a single row. In portrait orientation, it displays two entities side-by-side and wraps the rest onto a second row (to prevent names from being cut off in narrow spaces). The columns maintain equal width in both layouts, and the text shrinks slightly before any names are truncated.

## What It Shows

Each entity displays its icon, name, and current state. The icon is inherited directly from Home Assistant. If no specific icon is set, the default Home Assistant icon for that entity type is used (e.g., a lock icon for a lock, an open door for an open garage).

By default, each entity is presented as a "chip"—a rounded, translucent dark pill sized to its content. The icon sits in its own circle on the left, with the name displayed above the state on the right. Because the pill provides its own contrast, it remains highly readable even when overlaid on bright or complex photos.

The icon's background circle reflects the entity's state, matching how Home Assistant highlights active tiles. For example:
* A turned-on light glows amber.
* An unlocked lock warns in red.
* An open cover shows purple.
* Idle entities (and all basic sensors) remain grey.

A colored circle always indicates activity. The text itself never changes color; you read the state from the words, while the color simply acts as a visual cue. If you prefer a cleaner look, enabling **Monochromatic icons** keeps all circles in a neutral grey.

Enabling **Hide names** removes the name text from every entity and enlarges the value text to fill the space. This is ideal for smaller screens read from across a room, where the icon alone provides enough context. (Your custom names are saved and will return if you toggle this setting off later).

Enabling **Floating text style** reverts the row to its original, minimalist look: floating text in a single muted tone, without the chip background or state colors. On the Clock screensaver, this text matches the clock's digit color (Clock color for Digital; digit colors for Flip and Roller) to ensure readability against any background. However, over photos, this text-only style can be harder to read depending on the image behind it—which is exactly why the chip style is now the default.

States are displayed exactly as they appear in Home Assistant, capitalized (e.g., `Open`, `Locked`, `Closed`), with the appropriate unit appended for numeric sensors.

## How It Stays Current

When the screensaver is active, Kiosk Satellite subscribes *only* to these specific At a Glance entities via its own Home Assistant connection. When the screensaver closes, it kills that connection. Because Home Assistant's subscription allows for an entity list, this connection handles just these few entities and costs essentially nothing when the kiosk is in normal use.

Crucially, it does *not* read these states from the currently displayed dashboard. The **Filter dashboard updates** feature (Settings → Home Assistant Setup → Optimizations) exists to prevent lower-end devices from processing entity updates they aren't actively displaying. If the At a Glance row relied on the dashboard connection, it would defeat the purpose of that filter—a rapidly updating entity (like a power meter) would force the dashboard to constantly process new data in the background. Therefore, the status row operates entirely independently of the dashboard filter.

This separate connection also means the At a Glance row continues to work perfectly even if the kiosk is currently pointed at a non-Home Assistant webpage, or if the main dashboard page is in the middle of reloading.