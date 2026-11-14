# Drawer Menu

The drawer menu slides in from the left edge of the screen. It holds the shortcuts used at the wall, such as Dashboard, Settings, Camera View, Alarms or Apps. The app version and the theme switcher sit at the bottom. It works the same with Kiosk Mode on or off. While [Kiosk Mode](kiosk.md) is on, the exit gesture and PIN open the full menu. **Allow menu with quick actions** can bring back a restricted menu behind an edge swipe.

## Choosing the Entries

Navigate to **Settings**, then **Device**. Tap **Drawer menu items** in the **User Interface** group. The same row is available in the remote admin. It opens a picker with every entry the menu can show:

- Dashboard, Settings, HA Kiosk Mode, Camera View, Intercom, Alarms, Timers, Calendar, Music Library, Music Assistant, Floating Player, Now Playing, Start Screensaver, Lockdown Mode, Hold Mode, Apps, Clear web cache, Restart Device and Exit Application.
- Plugin actions set to **Show in kiosk drawer** on the [Plugins](plugins.md) page.
- The theme switcher.

Check the entries you want and uncheck the rest. Drag the checked entries or use the arrows next to them to change the order. The arrows show when the picker is wide enough, such as on a tablet or in the remote admin. The menu changes as soon as you tap **Done**.

By default every entry is on except Floating Player, Now Playing, Lockdown Mode and Hold Mode. Plugin actions added later go at the top of the menu until you move them. A stopped plugin keeps its place in the list and shows dimmed in the picker. Removing a plugin takes its entries out of the list, so a reinstall puts them back at the top.

## What Still Decides an Entry

A checked entry only shows when it has something to do on the device:

| Entry | Also needs |
| --- | --- |
| Camera View | Cameras in the default [camera view](cameras.md). |
| Intercom | The [intercom](intercom.md) on and the remote admin serving. |
| Music Library | A [Music Library](music-library.md) source set up. |
| Music Assistant | The Music Assistant server address under **Media Player > Music Assistant**. |
| Floating Player and Now Playing | The Sendspin player on with something playing or queued. Now Playing also needs the Now Playing view on. |
| Apps | The App Launcher on with apps picked. |
| Restart Device | Device owner or a [Shizuku](shizuku.md) connection. |
| Exit Application | Kiosk Satellite not set as the [Home Launcher](home-launcher.md), since the system would start it again right away. |

**Settings** can be unchecked only while remote admin is on. With remote admin off, the menu always shows Settings so there is a way back in. The theme switcher stays at the bottom of the menu wherever it sits in the list.

In the restricted quick actions menu of a locked kiosk, an entry also needs its switch under **Kiosk Mode > Allowed Actions**. Settings, Clear web cache, Restart Device and Exit Application never show there.

The pages of these features each have a **Show in the kiosk menu** row that opens this setting, as does the App Launcher page. Before this setting existed, those rows were switches. After the update, the menu keeps the entries those switches had on.

With [Compass navigation](navigation.md) there is no drawer. The Quick Controls view shows the same list, as quick controls and cards.

[Fleet Management](fleet.md) syncs the list under the Device category.
