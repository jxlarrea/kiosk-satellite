import 'dart:convert';

/// Handing an external WebView the dashboard's Home Assistant session
/// (discussion #225).
///
/// A second WebView pointed at a Home Assistant page — the website
/// screensaver, a dashboard link, a rotation slot — normally shares the
/// dashboard's login already: localStorage is per origin, and every WebView
/// in the app draws on the same store. It does not when the origins differ,
/// which is the ordinary case with the secure context proxy on (the
/// dashboard lives on a loopback origin) or when the address was typed with
/// a different host than the dashboard's. The page then shows the login
/// form, and on a screensaver a person cannot even answer it: the first
/// touch dismisses the screensaver.
///
/// So the session is copied across at document start, exactly like the Music
/// Assistant token seeding: only onto an origin known to be this Home
/// Assistant, and only where the page has no session of its own — one it
/// refreshed for itself, or a login someone did by hand, always wins.
///
/// `hassUrl` is rewritten to the page's own origin. It is the address the
/// frontend then talks to, and the copy's value belongs to the origin it
/// came from: a loopback proxy address on a page served over https is a
/// blocked, mixed-content websocket. A page served by Home Assistant is
/// always reachable at its own origin.
String? buildHaSessionScript({required String? tokens, required String url}) {
  if (tokens == null || tokens.trim().isEmpty) return null;
  final target = Uri.tryParse(url);
  if (target == null || !target.hasScheme || target.host.isEmpty) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(tokens);
  } catch (_) {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  if (decoded['access_token'] is! String) return null;
  final session = jsonEncode({...decoded, 'hassUrl': target.origin});
  return 'try {'
      'if (!localStorage.getItem("hassTokens")) {'
      'localStorage.setItem("hassTokens", ${jsonEncode(session)});'
      '}'
      '} catch (e) {}';
}
