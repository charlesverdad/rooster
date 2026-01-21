class Team {
  final String id;
  final String name;
  final String organisationId;
  final String? role; // Current user's role in this team (team_lead, member)
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
    this.memberCount = 0,
    this.rosterCount = 0,
    required this.createdAt,
    this.responseRate,
    this.coverageRate,
    this.activeMembers,
    this.nextRoster,
    this.unfilledSlots,
  });

  bool get isTeamLead => role == 'team_lead';
  bool get isMember => role == 'member' || role == null;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'].toString(),
      name: json['name'],
      organisationId: json['organisation_id'].toString(),
      role: json['role'],
      memberCount: json['member_count'] ?? 0,
      rosterCount: json['roster_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      responseRate: json['response_rate']?.toDouble(),
      coverageRate: json['coverage_rate']?.toDouble(),
      activeMembers: json['active_members'],
      nextRoster:
          json['next_roster'] != null ? DateTime.parse(json['next_roster']) : null,
      unfilledSlots: json['unfilled_slots'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organisation_id': organisationId,
      'role': role,
      'member_count': memberCount,
      'roster_count': rosterCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
