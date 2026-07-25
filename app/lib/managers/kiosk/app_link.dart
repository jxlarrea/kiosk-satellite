/// The `app://<package>` scheme a dashboard uses to open another Android app
/// (issue #44).
library;

/// A package name as Android accepts it: dot-separated segments, each starting
/// with a letter. Anything else is not worth handing to the package manager.
final _package = RegExp(r'^[a-zA-Z][\w]*(\.[a-zA-Z][\w]*)+$');

/// The package named by an `app://` URL, or null when [url] is not one of ours
/// or does not name a plausible package.
///
/// The raw string is parsed rather than [Uri.host] because the host is
/// lowercased, and package names are case sensitive. Both `app://pkg` and the
/// hostless `app:pkg` are accepted, with or without a trailing slash, since
/// both are natural things to type into a dashboard's `url_path`.
String? appLinkPackage(String url) {
  final trimmed = url.trim();
  if (!trimmed.toLowerCase().startsWith('app:')) return null;
  var rest = trimmed.substring(4);
  if (rest.startsWith('//')) rest = rest.substring(2);
  while (rest.endsWith('/')) {
    rest = rest.substring(0, rest.length - 1);
  }
  // A path, query or fragment past the package is not something we can pass
  // on, so refuse rather than silently open the app and drop it.
  if (!_package.hasMatch(rest)) return null;
  return rest;
}
