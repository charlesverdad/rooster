class User {
  final String id;
  final String email;
  final String name;
  final List<String> roles;

  User({
    required this.id,
    required this.email,
    required this.name,
    List<String>? roles,
  }) : roles = roles ?? ['member'];

  bool get isTeamLead => roles.contains('team_lead');
  bool get isAdmin => roles.contains('admin');
  bool get isMember => roles.contains('member');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      roles: json['roles'] != null 
          ? List<String>.from(json['roles']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'roles': roles,
    };
  }
}
