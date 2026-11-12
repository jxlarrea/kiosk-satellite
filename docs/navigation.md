# Navigation

Settings > Navigation picks how you move around the kiosk. **Classic** is the [drawer menu](drawer-menu.md) that slides in from the left edge, with pull to refresh and the dashboard carousel. **Compass** lays views out in a cross around a center view, and you swipe between them.

Navigation is the first entry in Settings, under the **Kiosk Satellite** heading. In the remote admin it sits right after Overview.

## Compass

The center view is the one the kiosk rests on. Each side holds up to two views, and you swipe to move along a side:

- Swipe left to show the view on the right, and swipe right to come back.
- Swipe down to show the view above, and swipe up to come back.
- A swipe across a side does nothing. From the view on the right, swipe right to go back toward the center first.

The **Quick Controls** view holds the drawer menu's items: switches and one-tap actions as quick controls, then Settings and the pages they open as square cards. A new layout has it on the left of the center. It is optional and can go on any side. With remote admin off, a layout without Quick Controls gets it on the left anyway, so Settings can always be reached.

While a swipe is in motion, the view shrinks to show the views around it, and the new view grows to fill the screen when you let go. Let go past a third of the screen, or flick, to move. A shorter swipe goes back. Set **Swipe animation** to **Slide** to move straight across without the zoom.

### What can go in the layout

| View | Also needs |
| --- | --- |
| Home Assistant dashboard | Any view, a [Custom Page](custom-pages.md) or an app page, picked in the dashboard picker. Add as many as the layout has room for. |
| Quick Controls | Nothing. |
| Music Library | A [Music Library](music-library.md) source set up. |
| Calendar | Nothing. |
| Alarms | Nothing. |
| Now Playing | The Sendspin player and the Now Playing view on. A swipe skips it while nothing is loaded. |
| Camera View | A [camera view](cameras.md) with cameras in it. |
| App Launcher | The App Launcher on with apps picked. |
| Intercom | The [intercom](intercom.md) on. |

Home Assistant dashboard views can go in the layout several times, each view once. Every other kind of view goes in once, so there is one camera view at most. The center can be any of them. By default it is **Home Assistant**, the dashboard the kiosk starts on.

### Several dashboard views

All dashboard views show in the same page, so adding more does not load Home Assistant again. A swipe from one dashboard view to another switches the view in that page, as a tap on a dashboard tab does.

The swipe holds a picture of the view it lands on until the page has built that view. The first swipe to a view after a start takes longest, since Home Assistant builds its cards then. A view on another dashboard takes longer than a view on the same dashboard. After 2.5 seconds the page shows as it is.

**Return to home dashboard view** goes back to the view picked for the place you are on, not to the default dashboard. Swipe to another dashboard view and that one is where the page returns.

If the page moves to a dashboard view of the layout on its own, such as through a navigation card or the Dashboard view select in Home Assistant, the layout follows: that view is the one you swipe from next.

### Editing the layout

On a tablet and in the remote admin, the layout shows as a map of the cross. Tap **Add** at the end of a side to place a view there. Tap a view to select it, then use **Move in**, **Move out**, **Replace** or **Remove** below the map. Tap the center view and **Replace** to pick another center.

On a phone, the layout shows as a list for each side, with arrows to change the order.

### Swipes and the page

A swipe that starts on a slider, a map or a card that scrolls sideways stays with the page. On a dashboard that scrolls, swipe down at the top of the page or swipe up at the bottom to move up or down. Lists in the Music Library or the calendar work the same way: scroll to the end first.

A swipe only works while the view on screen is the one in the layout. A camera view opened by a doorbell, a ringing alarm, an intercom call, an opened link or the screensaver keep the swipe off until they close.

### Plugin overlays

A swipe that starts on a plugin overlay, such as a navigation bar, stays with the plugin. Overlays drawn over the dashboard show on dashboard views only. Overlays a plugin draws on top show over every view and move with the view while you swipe. A plugin's window shows over dashboard views, where swipes wait until you close it.

### The screensaver

The screensaver starts over any view after the idle timeout, as it does over the dashboard, and the view is still there when it ends. A camera view is the exception: live cameras hold the screensaver off, as they do everywhere else. If Return to center comes due while the screensaver runs, the kiosk lands on the center when it ends.

Views in the layout skip their own **Close when idle** and the camera view's **Auto-dismiss after**. **Return to center** decides when they go instead. Opened outside the layout, such as a camera view a doorbell opens, they keep their own setting.

### Back and the exit gesture

Back goes to the center view. At the center, back opens Quick Controls when the layout has it. Without Quick Controls, the exit gesture opens Settings.

While [Kiosk Mode](kiosk.md) is on, **Kiosk Mode > Allowed Actions** decides what a swipe reaches. A view whose action is off is skipped: Apps for the App Launcher, Camera View, Intercom, Alarms, Calendar and Music Library for their views, and Floating Player for Now Playing. The center and a dashboard view always show. Quick Controls shows only with **Allow menu with quick actions** on, and then holds only the allowed actions, with Settings locked. Tap Settings, or use the exit gesture, and enter the PIN to get all of Quick Controls.

### Options

- **Show position while swiping** shows a small map of the layout in the corner with your place marked.
- **Return to center** goes back to the center view after no touch for this long. Set it to 0 to stay on the view. It waits while Hold Mode is on.
- **Menu items** opens **Drawer menu items**. The Quick Controls view and the drawer menu share the same list.

With Compass on, pull to refresh, the dashboard carousel and the edge swipe that opens the drawer menu are off. Settings > Navigation says so under the style cards. Their settings stay in place, greyed out with "Off while Compass navigation is on." under them, and come back as they were when you switch to Classic.

[Fleet Management](fleet.md) syncs Navigation with the other settings of its category.
