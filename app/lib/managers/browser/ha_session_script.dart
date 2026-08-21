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
/// Auto-login for the dashboard itself (ha.auto_login): the app already
/// holds a long-lived access token, so the frontend can be handed a session
/// built from it instead of presenting the login form.
///
/// The seeded session is exactly what the frontend would have stored after
/// a login, with the long-lived token as the access token. `expires` sits
/// ten years out — the token's own lifetime scale — so the frontend never
/// tries the refresh flow it has no refresh token for; if the token is
/// revoked, the websocket auth fails and the frontend falls back to the
/// login form as usual. `hassUrl` and `clientId` are computed in the page
/// from its own location, because the frontend rejects a stored session
/// whose origin is not its own (which also keeps the seed correct under
/// the loopback proxy).
///
/// Seeded only where the page has no session of its own: one it refreshed
/// for itself, or a login someone did by hand, always wins.
String? buildHaAutoLoginScript({required String? token}) {
  final trimmed = token?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return 'try {'
      'if (!localStorage.getItem("hassTokens")) {'
      'localStorage.setItem("hassTokens", JSON.stringify({'
      'access_token: ${jsonEncode(trimmed)},'
      'token_type: "Bearer",'
      'expires_in: 1800,'
      'expires: Date.now() + 315360000000,'
      'hassUrl: location.protocol + "//" + location.host,'
      'clientId: location.protocol + "//" + location.host + "/"'
      '}));'
      '}'
      '} catch (e) {}';
}

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
