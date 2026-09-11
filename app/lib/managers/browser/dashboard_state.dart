/// Sanitized URL components for the SDK's dashboard diagnostics read.
class DashboardState {
  static String? url(Object? value) {
    if (value is! String || value.length > 8192) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        (uri.hasPort && (uri.port < 1 || uri.port > 65535))) {
      return null;
    }
    // Reconstruct only the allowed components, preserving encoded paths.
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: uri.path,
    ).toString();
  }

  static Map<String, String?> fromUrls({
    required Object? homeAssistantUrl,
    required Object? startUrl,
    required Object? currentUrl,
  }) {
    final current = url(currentUrl);
    final path = current == null ? null : Uri.parse(current).path;
    return {
      'homeAssistantUrl': url(homeAssistantUrl),
      'startUrl': url(startUrl),
      'currentUrl': current,
      'currentPath': path == '' ? '/' : path,
    };
  }
}
