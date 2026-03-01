class AuthConfig {
  final bool emailEnabled;
  final bool googleEnabled;
  final String? googleClientId;

  const AuthConfig({
    this.emailEnabled = true,
    this.googleEnabled = false,
    this.googleClientId,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      emailEnabled: json['email_enabled'] ?? true,
      googleEnabled: json['google_enabled'] ?? false,
      googleClientId: json['google_client_id'],
    );
  }

  /// Default config when backend is unreachable — email only.
  factory AuthConfig.defaults() => const AuthConfig();
}
