# Plugin Manager

Plugin documentation lives in the [Community SDK repository](https://github.com/jxlarrea/kiosk-satellite-plugins).

- [Installing and managing plugins](https://github.com/jxlarrea/kiosk-satellite-plugins/blob/main/docs/installing-plugins.md): installation, settings, trust, updates and the remote API.
- [Creating plugins](https://github.com/jxlarrea/kiosk-satellite-plugins/blob/main/docs/creating-plugins.md): the SDK, lifecycle, package format, build tools and publishing.

Plugins can also use the optional [Shizuku connection](shizuku.md).

A fleet leader can install its plugins on its followers with their settings. See [Fleet Management](fleet.md#plugins).

## Plugin updates

Plugin updates are checked a minute after the app starts and every 12 hours. They never install automatically.

A plugin with a newer release shows **New version** on its row in Plugin Manager. In the remote admin it also gets a row under **Needs attention** on the Overview. **Update** on that row opens the same review as the plugin's check for updates button. Nothing installs until you choose **Trust and update**.

Plugins listed in Community Plugins are checked against the list. Any other plugin installed from a repository costs one GitHub API request. Plugins installed from a ZIP and plugins a fleet leader keeps in step are not checked. A release that needs a newer Kiosk Satellite is not shown. Nothing is checked while **Enable Plugins** is off.

## Browse plugins

**Settings > Plugin Manager > Browse plugins**, also in the remote admin, lists Community Plugins: plugins their authors submitted to the [plugins repository](https://github.com/jxlarrea/kiosk-satellite-plugins#submit-your-plugin). The same list is on [kiosksatellite.com](https://kiosksatellite.com/plugins/). Each plugin shows its icon, author, latest version, stars and downloads. Search narrows the list by name, description or author. **Sort by** orders it by Most downloads, Most stars, Recently updated, Newest or Name. **Plugins per page** picks 5, 10, 20, 50 or 100 plugins a page, 10 unless you change it.

Pick a plugin to see the same review that **Add plugin** shows, with its manifest and README, then choose **Trust and install**. A listed plugin you already have says **Installed**, or offers **Update** when the list knows a newer release. A plugin whose latest release needs a newer Kiosk Satellite says which release it needs and offers no Install or Update. The one you have keeps running. The review also says whether a repository is listed in Community Plugins.

The list refreshes twice a day on kiosksatellite.com. Kiosk Satellite downloads it when you open Browse plugins or checks for plugin updates, at most once an hour, and keeps the last copy for when it is offline.

### Install from kiosksatellite.com

The **Install** button on a plugin's page on kiosksatellite.com asks for your kiosk's remote admin address the first time, such as `http://192.168.1.10:2324/`, and opens Plugin Manager there with the plugin's review. Remote admin must be on. Nothing installs until you choose **Trust and install**. If Enable Plugins is off, the remote admin asks to turn it on first.

The application retains its license with an [additional permission for independent plugins](../PLUGIN-EXCEPTION.md).
