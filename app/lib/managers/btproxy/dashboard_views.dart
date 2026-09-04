/// The dashboard-view select option a URL corresponds to, or null when it
/// is none of them. A bare dashboard url renders that dashboard's first
/// view, so it maps to the first option under that url_path.
/// Origin-agnostic on purpose: with the secure context proxy on, the page
/// lives on a loopback origin and only the path is trustworthy.
///
/// The ESPHome Dashboard select derives its state from the current URL
/// through this, so the option list and the page agree on what a view is.
String? matchDashboardView(String url, List<String> options) {
  if (options.isEmpty) return null;
  final path = Uri.tryParse(url)?.path.replaceAll(RegExp(r'^/+|/+$'), '') ?? '';
  if (path.isEmpty) return null;
  if (options.contains(path)) return path;
  if (path.contains('/')) return null;
  final first = options.firstWhere(
    (o) => o.startsWith('$path/'),
    orElse: () => '',
  );
  return first.isEmpty ? null : first;
}
