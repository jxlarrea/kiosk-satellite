import 'dart:convert';

// Custom pages: a person's own HTML pages, either files in Home
// Assistant's `www` folder, which Home Assistant serves at `/local/` on its
// own origin, or pages on another web server.
//
// A page in Home Assistant shares the dashboard's localStorage, so the
// session auto-login seeds (`hassTokens`) signs a
// `home-assistant-js-websocket` page in with no token in its code, and
// every origin rule the kiosk applies to the dashboard (links, the secure
// context proxy, a base URL change) covers the page too. A page on another
// server gets no Home Assistant session. It reaches Home Assistant through
// the kiosk's own connection instead (see PageHaSocket), when the person
// allows it.
//
// A page in Home Assistant is stored by its path ("/local/kitchen.html",
// optionally with a query and a fragment) and navigated to by that path
// without its leading slash, the same shape as a dashboard view path. A
// page elsewhere is stored by its full URL and navigated to as "local/"
// followed by that URL. The dashboard lists show the pages as one more
// dashboard on [customPagesDashboardPath], so every dashboard picker, the
// rotation and the ESPHome selects offer them.

/// The url_path the pages are listed under. Home Assistant requires a
/// hyphen in the url_path of a dashboard someone adds and none of its own
/// panels is named this, so no real dashboard can take it.
const customPagesDashboardPath = 'local';

/// The icon every page wears in the pickers: a window with code in it.
const customPageIcon = 'mdi:application-brackets-outline';

/// The icon of the Custom Pages entry in the dashboard list and of its
/// settings page, the same window.
const customPagesIcon = 'mdi:application-brackets-outline';

/// One page the person added.
class CustomPage {
  const CustomPage({required this.name, required this.path});

  final String name;

  /// "/local/kitchen.html#lights" for a page in Home Assistant, or the full
  /// URL of a page on another server, "https://pages.lan/wall.html#den".
  final String path;

  /// Whether the page lives on another server than Home Assistant.
  bool get external => !path.startsWith('/');

  /// The navigation path, "local/kitchen.html#lights" or
  /// "local/https://pages.lan/wall.html#den".
  String get navPath =>
      external ? '$customPagesDashboardPath/$path' : path.substring(1);

  /// What follows "local/", the page's route inside the Custom Pages
  /// dashboard.
  String get route => navPath.substring('$customPagesDashboardPath/'.length);

  Map<String, Object?> toJson() => {'name': name, 'path': path};
}

/// The pages stored in the `ha.custom_pages` setting, in their order.
/// Anything malformed is skipped rather than failing the whole list.
List<CustomPage> parseCustomPages(String raw) {
  try {
    final list = jsonDecode(raw);
    if (list is! List) return const [];
    final pages = <CustomPage>[];
    for (final e in list) {
      if (e is! Map) continue;
      final name = '${e['name'] ?? ''}'.trim();
      final path = normalizeCustomPagePath('${e['path'] ?? ''}');
      if (name.isEmpty || path == null) continue;
      if (pages.any((p) => p.path == path)) continue;
      pages.add(CustomPage(name: name, path: path));
    }
    return pages;
  } catch (_) {
    return const [];
  }
}

String encodeCustomPages(List<CustomPage> pages) =>
    jsonEncode([for (final p in pages) p.toJson()]);

/// [input] as a stored page path ("/local/kitchen.html" or a full URL) or
/// null when it names no page. Takes the path as typed ("/local/a.html",
/// "local/a.html" or a bare "a.html") or a whole URL. A URL on [haBase]'s
/// origin is a page in Home Assistant and keeps only its path, so it loads
/// from the Home Assistant base URL. Any other http or https URL is a page
/// on another server. Without [haBase], every URL is one elsewhere, which
/// is how a stored list is read back.
String? normalizeCustomPagePath(String input, {String haBase = ''}) {
  var text = input.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s|\\'))) return null;
  if (text.contains('://')) {
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final base = Uri.tryParse(haBase.trim());
    final inHa = base != null && base.hasAuthority && base.origin == uri.origin;
    if (!inHa) return externalPageUrl(uri);
    text =
        uri.path +
        (uri.hasQuery ? '?${uri.query}' : '') +
        (uri.hasFragment ? '#${uri.fragment}' : '');
  }
  // An absolute path names its folder, which has to be /local/. A bare
  // file name is taken as one in it.
  final absolute = text.startsWith('/');
  text = text.replaceFirst(RegExp(r'^/+'), '');
  if (text.startsWith('local/')) {
    text = text.substring('local/'.length);
  } else if (absolute) {
    return null;
  }
  final cut = text.indexOf(RegExp('[?#]'));
  final file = cut < 0 ? text : text.substring(0, cut);
  if (file.isEmpty || file.startsWith('/') || file.endsWith('/')) return null;
  if (file.split('/').any((s) => s.isEmpty || s == '.' || s == '..')) {
    return null;
  }
  return '/local/$text';
}

/// [uri] as a stored external page: the URL the WebView reports for it,
/// with no user info, a lowercase host, no default port and "/" for an
/// empty path, so a page on screen compares equal to its stored form.
String? externalPageUrl(Uri uri) {
  if (uri.userInfo.isNotEmpty) return null;
  return uri.replace(path: uri.path.isEmpty ? '/' : uri.path).toString();
}

/// Whether a navigation path ("local/kitchen.html") names a custom page
/// rather than a dashboard view.
bool isCustomPagePath(String navPath) =>
    navPath.startsWith('$customPagesDashboardPath/');

/// Whether a navigation path names a custom page on another server,
/// "local/https://pages.lan/wall.html".
bool isExternalCustomPagePath(String navPath) =>
    navPath.startsWith('$customPagesDashboardPath/http://') ||
    navPath.startsWith('$customPagesDashboardPath/https://');

/// The URL a navigation path loads: a page on another server is its own
/// URL, anything else lives on the Home Assistant [base].
String viewPathUrl(String base, String navPath) =>
    isExternalCustomPagePath(navPath)
    ? navPath.substring('$customPagesDashboardPath/'.length)
    : '$base/$navPath';

/// The navigation path of the external page [url] shows, or null when it
/// is none of [pages]. The same file under a fragment no page names is
/// still that page, in a layout of its own, so it keeps the fragment.
String? externalPageNavPath(String url, List<CustomPage> pages) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) return null;
  final shown = externalPageUrl(uri);
  if (shown == null) return null;
  final file = customPageFile(shown);
  CustomPage? sameFile;
  for (final p in pages) {
    if (!p.external) continue;
    if (p.path == shown) return p.navPath;
    if (customPageFile(p.path) == file) sameFile ??= p;
  }
  return sameFile == null ? null : '$customPagesDashboardPath/$shown';
}

/// The origins of the pages on other servers, "https://pages.lan".
Set<String> externalPageOrigins(List<CustomPage> pages) => {
  for (final p in pages)
    if (p.external) Uri.parse(p.path).origin,
};

/// The navigation path a URL's path names: the path without its slashes,
/// plus the query and the fragment for a custom page, where they pick a
/// layout of the person's own page. A dashboard view keeps the path alone,
/// since Home Assistant navigates by it.
String navPathOfUri(Uri uri) {
  final path = uri.path.replaceAll(RegExp(r'^/+|/+$'), '');
  if (!isCustomPagePath(path)) return path;
  return path +
      (uri.hasQuery ? '?${uri.query}' : '') +
      (uri.hasFragment && uri.fragment.isNotEmpty ? '#${uri.fragment}' : '');
}

/// The path that brings the page back to [uri]: [navPathOfUri] plus a
/// dashboard's fragment, which is an open popup. The query goes with the
/// fragment, since a path with either has to match the page's whole URL.
/// Without a fragment a dashboard keeps its bare path.
String landingPathOfUri(Uri uri) {
  final path = navPathOfUri(uri);
  if (path.isEmpty || isCustomPagePath(path) || uri.fragment.isEmpty) {
    return path;
  }
  return '$path${uri.hasQuery ? '?${uri.query}' : ''}#${uri.fragment}';
}

/// The page's file, its path or URL without the fragment: what the server
/// serves and the validation asks for.
String customPageFile(String path) {
  final cut = path.indexOf('#');
  return cut < 0 ? path : path.substring(0, cut);
}
