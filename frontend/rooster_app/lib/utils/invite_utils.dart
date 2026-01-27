/// Extract an invite token from user input.
///
/// Handles:
/// - Full HTTPS URLs: https://rooster.app/invite/TOKEN
/// - App scheme URLs: rooster://invite/TOKEN
/// - Bare tokens: TOKEN
///
/// Returns the extracted token, or null if the input is empty.
String? extractTokenFromInviteUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  // Try parsing as a URI
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    // Look for /invite/TOKEN pattern
    final segments = uri.pathSegments;
    for (int i = 0; i < segments.length - 1; i++) {
      if (segments[i] == 'invite' && segments[i + 1].isNotEmpty) {
        return segments[i + 1];
      }
    }
  }

  // If no URI pattern matched, treat the whole input as a bare token
  // (but only if it doesn't contain spaces or slashes, which would indicate
  // a malformed URL rather than a bare token)
  if (!trimmed.contains(' ') && !trimmed.contains('/')) {
    return trimmed;
  }

  // Last resort: if it has slashes but we couldn't parse it, try splitting
  if (trimmed.contains('/invite/')) {
    final parts = trimmed.split('/invite/');
    if (parts.length >= 2 && parts.last.isNotEmpty) {
      return parts.last;
    }
  }

  return trimmed;
}
