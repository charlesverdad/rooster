import 'organisation.dart';

class User {
  final String id;
  final String? email;
  final String name;
  final List<String> roles;
  final bool isPlaceholder;
  final List<Organisation> organisations;

  User({
    required this.id,
    this.email,
    required this.name,
    List<String>? roles,
    this.isPlaceholder = false,
    List<Organisation>? organisations,
  }) : roles = roles ?? ['member'],
       organisations = organisations ?? [];

  bool get isTeamLead => roles.contains('team_lead');
  bool get isAdmin => roles.contains('admin');
  bool get isMember => roles.contains('member');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      roles: json['roles'] != null ? List<String>.from(json['roles']) : null,
      isPlaceholder: json['is_placeholder'] ?? false,
      organisations: json['organisations'] != null
          ? (json['organisations'] as List)
                .map((o) => Organisation.fromJson(o))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'roles': roles,
      'is_placeholder': isPlaceholder,
    };
  }
}
