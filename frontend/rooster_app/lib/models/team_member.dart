/// Represents a member of a team
class TeamMember {
  final String userId;
  final String teamId;
  final String role; // team_lead, member
  final String userName;
  final String? userEmail;
  final bool isPlaceholder;
  final bool isInvited;

  TeamMember({
    required this.userId,
    required this.teamId,
    required this.role,
    required this.userName,
    this.userEmail,
    this.isPlaceholder = false,
    this.isInvited = false,
  });

  bool get isTeamLead => role == 'team_lead';
  bool get isMember => role == 'member';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'].toString(),
      teamId: json['team_id'].toString(),
      role: json['role'] ?? 'member',
      userName: json['user_name'] ?? '',
      userEmail: json['user_email'],
      isPlaceholder: json['is_placeholder'] ?? false,
      isInvited: json['is_invited'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'team_id': teamId,
      'role': role,
      'user_name': userName,
      'user_email': userEmail,
      'is_placeholder': isPlaceholder,
      'is_invited': isInvited,
    };
  }

  // Convert to the Map format used by existing screens
  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'name': userName,
      'email': userEmail,
      'role': isTeamLead ? 'Lead' : 'Member',
      'isPlaceholder': isPlaceholder,
      'isInvited': isInvited,
    };
  }
}
