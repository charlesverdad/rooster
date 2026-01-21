/// Permission constants for team members
class TeamPermission {
  static const String manageTeam = 'manage_team';
  static const String manageMembers = 'manage_members';
  static const String sendInvites = 'send_invites';
  static const String manageRosters = 'manage_rosters';
  static const String assignVolunteers = 'assign_volunteers';
  static const String viewResponses = 'view_responses';

  static const List<String> all = [
    manageTeam,
    manageMembers,
    sendInvites,
    manageRosters,
    assignVolunteers,
    viewResponses,
  ];
}

/// Represents a member of a team
class TeamMember {
  final String userId;
  final String teamId;
  final String role; // lead, member
  final List<String> permissions;
  final String userName;
  final String? userEmail;
  final bool isPlaceholder;
  final bool isInvited;

  TeamMember({
    required this.userId,
    required this.teamId,
    required this.role,
    this.permissions = const [],
    required this.userName,
    this.userEmail,
    this.isPlaceholder = false,
    this.isInvited = false,
  });

  // Permission checking methods
  bool hasPermission(String permission) => permissions.contains(permission);

  bool get canManageTeam => hasPermission(TeamPermission.manageTeam);
  bool get canManageMembers => hasPermission(TeamPermission.manageMembers);
  bool get canSendInvites => hasPermission(TeamPermission.sendInvites);
  bool get canManageRosters => hasPermission(TeamPermission.manageRosters);
  bool get canAssignVolunteers => hasPermission(TeamPermission.assignVolunteers);
  bool get canViewResponses => hasPermission(TeamPermission.viewResponses);

  // Legacy role checks (for backward compatibility)
  bool get isTeamLead => role == 'lead' || canManageTeam;
  bool get isMember => role == 'member';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'].toString(),
      teamId: json['team_id'].toString(),
      role: json['role'] ?? 'member',
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
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
      'permissions': permissions,
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
      'permissions': permissions,
      'isPlaceholder': isPlaceholder,
      'isInvited': isInvited,
    };
  }

  // Create a copy with updated permissions
  TeamMember copyWith({
    String? userId,
    String? teamId,
    String? role,
    List<String>? permissions,
    String? userName,
    String? userEmail,
    bool? isPlaceholder,
    bool? isInvited,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      isInvited: isInvited ?? this.isInvited,
    );
  }
}
