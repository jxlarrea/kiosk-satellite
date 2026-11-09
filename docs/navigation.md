# Navigation

Settings > Navigation picks how you move around the kiosk. **Classic** is the [drawer menu](drawer-menu.md) that slides in from the left edge, with pull to refresh and the dashboard carousel. **Compass** lays views out in a cross around a center view, and you swipe between them.

Navigation is the first entry in Settings, under the **Kiosk Satellite** heading. In the remote admin it sits right after Overview.

## Compass

The center view is the one the kiosk rests on. Each side holds up to two views, and you swipe to move along a side:

- Swipe left to show the view on the right, and swipe right to come back.
- Swipe down to show the view above, and swipe up to come back.
- A swipe across a side does nothing. From the view on the right, swipe right to go back toward the center first.

The **Menu** view holds the drawer menu's items: Settings as a button at the top, switches and one-tap actions as quick controls and the pages they open as cards. A new layout has it on the left of the center. It is optional and can go on any side. With remote admin off, a layout without a Menu gets one on the left anyway, so Settings can always be reached.

While a swipe is in motion, the view shrinks to show the views around it, and the new view grows to fill the screen when you let go. Let go past a third of the screen, or flick, to move. A shorter swipe goes back. Set **Swipe animation** to **Slide** to move straight across without the zoom.

### What can go in the layout

| View | Also needs |
| --- | --- |
| Home Assistant dashboard | Any view, a [Custom Page](custom-pages.md) or an app page, picked in the dashboard picker. |
| Menu | Nothing. |
| Music Library | A [Music Library](music-library.md) source set up. |
| Calendar | Nothing. |
| Alarms | Nothing. |
| Now Playing | The Sendspin player and the Now Playing view on. A swipe skips it while nothing is loaded. |
| Camera View | A [camera view](cameras.md) with cameras in it. |
| App Launcher | The App Launcher on with apps picked. |
| Intercom | The [intercom](intercom.md) on. |

Each kind of view goes in the layout once, so there is one dashboard view and one camera view at most. The center can be any of them. By default it is **Home Assistant**, the dashboard the kiosk starts on.

### Editing the layout

On a tablet and in the remote admin, the layout shows as a map of the cross. Tap **Add** at the end of a side to place a view there. Tap a view to select it, then use **Move in**, **Move out**, **Replace** or **Remove** below the map. Tap the center view and **Replace** to pick another center.

On a phone, the layout shows as a list for each side, with arrows to change the order.

### Swipes and the page

A swipe that starts on a slider, a map or a card that scrolls sideways stays with the page. On a dashboard that scrolls, swipe down at the top of the page or swipe up at the bottom to move up or down. Lists in the Music Library or the calendar work the same way: scroll to the end first.

A swipe only works while the view on screen is the one in the layout. A camera view opened by a doorbell, a ringing alarm, an intercom call, an opened link or the screensaver keep the swipe off until they close.

### Back and the exit gesture

Back goes to the center view. At the center, back opens the Menu when the layout has one. Without a Menu, the exit gesture opens Settings.

While [Kiosk Mode](kiosk.md) is on, **Kiosk Mode > Allowed Actions** decides what a swipe reaches. A view whose action is off is skipped: Apps for the App Launcher, Camera View, Intercom, Alarms, Calendar and Music Library for their views, and Floating Player for Now Playing. The center and a dashboard view always show. The Menu shows only with **Allow menu with quick actions** on, and then holds only the allowed actions, with Settings locked. Tap Settings, or use the exit gesture, and enter the PIN to get the full Menu.

### Options

- **Show position while swiping** shows a small map of the layout in the corner with your place marked.
- **Return to center** goes back to the center view after no touch for this long. Set it to 0 to stay on the view. It waits while Hold Mode is on.
- **Menu items** opens **Drawer menu items**. The Menu view and the drawer menu share the same list.

With Compass on, pull to refresh, the dashboard carousel and the edge swipe that opens the drawer menu are off.

[Fleet Management](fleet.md) syncs Navigation with the other settings of its category.
