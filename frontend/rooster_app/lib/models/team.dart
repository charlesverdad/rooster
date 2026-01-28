import 'team_member.dart';

class Team {
  final String id;
  final String name;
  final String organisationId;
  final String? role; // Current user's role in this team (lead, member)
  final List<String> permissions; // Current user's permissions
  final int memberCount;
  final int rosterCount;
  final DateTime createdAt;

  // Team health metrics (optional, for team lead view)
  final double? responseRate;
  final double? coverageRate;
  final int? activeMembers;
  final DateTime? nextRoster;
  final int? unfilledSlots;

  Team({
    required this.id,
    required this.name,
    required this.organisationId,
    this.role,
    this.permissions = const [],
    this.memberCount = 0,
    this.rosterCount = 0,
    required this.createdAt,
    this.responseRate,
    this.coverageRate,
    this.activeMembers,
    this.nextRoster,
    this.unfilledSlots,
  });

  // Permission checking methods
  bool hasPermission(String permission) => permissions.contains(permission);

  bool get canManageTeam => hasPermission(TeamPermission.manageTeam);
  bool get canManageMembers => hasPermission(TeamPermission.manageMembers);
  bool get canSendInvites => hasPermission(TeamPermission.sendInvites);
  bool get canManageRosters => hasPermission(TeamPermission.manageRosters);
  bool get canAssignVolunteers =>
      hasPermission(TeamPermission.assignVolunteers);
  bool get canViewResponses => hasPermission(TeamPermission.viewResponses);

  // Legacy role checks (for backward compatibility)
  bool get isTeamLead => role == 'lead' || canManageTeam;
  bool get isMember => role == 'member' || role == null;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'].toString(),
      name: json['name'],
      organisationId: json['organisation_id'].toString(),
      role: json['role'],
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : [],
      memberCount: json['member_count'] ?? 0,
      rosterCount: json['roster_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      responseRate: json['response_rate']?.toDouble(),
      coverageRate: json['coverage_rate']?.toDouble(),
      activeMembers: json['active_members'],
      nextRoster: json['next_roster'] != null
          ? DateTime.parse(json['next_roster'])
          : null,
      unfilledSlots: json['unfilled_slots'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organisation_id': organisationId,
      'role': role,
      'permissions': permissions,
      'member_count': memberCount,
      'roster_count': rosterCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
