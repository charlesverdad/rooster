class Team {
  final String id;
  final String name;
  final String organisationId;
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
    required this.memberCount,
    required this.rosterCount,
    required this.createdAt,
    this.responseRate,
    this.coverageRate,
    this.activeMembers,
    this.nextRoster,
    this.unfilledSlots,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      organisationId: json['organisation_id'],
      memberCount: json['member_count'] ?? 0,
      rosterCount: json['roster_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      responseRate: json['response_rate']?.toDouble(),
      coverageRate: json['coverage_rate']?.toDouble(),
      activeMembers: json['active_members'],
      nextRoster: json['next_roster'] != null 
          ? DateTime.parse(json['next_roster']) 
          : null,
      unfilledSlots: json['unfilled_slots'],
    );
  }
}
