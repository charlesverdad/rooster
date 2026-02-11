class Organisation {
  final String id;
  final String name;
  final String role; // "admin" or "member"
  final bool isPersonal;
  final DateTime createdAt;

  Organisation({
    required this.id,
    required this.name,
    required this.role,
    this.isPersonal = false,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory Organisation.fromJson(Map<String, dynamic> json) {
    return Organisation(
      id: json['id'],
      name: json['name'],
      role: json['role'] ?? 'member',
      isPersonal: json['is_personal'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'is_personal': isPersonal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OrganisationMember {
  final String userId;
  final String organisationId;
  final String role;
  final String? userEmail;
  final String userName;

  OrganisationMember({
    required this.userId,
    required this.organisationId,
    required this.role,
    this.userEmail,
    required this.userName,
  });

  bool get isAdmin => role == 'admin';

  factory OrganisationMember.fromJson(Map<String, dynamic> json) {
    return OrganisationMember(
      userId: json['user_id'],
      organisationId: json['organisation_id'],
      role: json['role'] ?? 'member',
      userEmail: json['user_email'],
      userName: json['user_name'],
    );
  }
}
