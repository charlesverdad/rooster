class ApiConfig {
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Resolves the API base URL. Relative URLs (e.g. `/api`) are resolved
  /// against the browser origin via [Uri.base]. Absolute URLs pass through
  /// unchanged. This allows the same build to work behind a reverse proxy
  /// (relative) or directly against a backend (absolute).
  static String get baseUrl {
    if (_rawBaseUrl.startsWith('http')) return _rawBaseUrl;
    final resolved = Uri.base.resolve(_rawBaseUrl).toString();
    // Strip trailing slash for consistency
    return resolved.endsWith('/')
        ? resolved.substring(0, resolved.length - 1)
        : resolved;
  }

  static const Duration timeout = Duration(seconds: 30);
}
