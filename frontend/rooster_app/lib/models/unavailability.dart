class Unavailability {
  final String id;
  final String userId;
  final DateTime date;
  final String? reason;
  final DateTime createdAt;

  Unavailability({
    required this.id,
    required this.userId,
    required this.date,
    this.reason,
    required this.createdAt,
  });

  factory Unavailability.fromJson(Map<String, dynamic> json) {
    return Unavailability(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      reason: json['reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Conflict {
  final String assignmentId;
  final String unavailabilityId;
  final DateTime date;
  final String rosterName;
  final String teamName;
  final String? reason;

  Conflict({
    required this.assignmentId,
    required this.unavailabilityId,
    required this.date,
    required this.rosterName,
    required this.teamName,
    this.reason,
  });

  factory Conflict.fromJson(Map<String, dynamic> json) {
    return Conflict(
      assignmentId: json['assignment_id'],
      unavailabilityId: json['unavailability_id'],
      date: DateTime.parse(json['date']),
      rosterName: json['roster_name'],
      teamName: json['team_name'],
      reason: json['reason'],
    );
  }
}
