class RosterEvent {
  final String id;
  final String rosterId;
  final String? rosterName;
  final DateTime date; // Date only (no time) from backend
  final String? notes;
  final bool isCancelled;
  final String? teamId;
  final int slotsNeeded;
  final int filledSlots;
  final DateTime? createdAt;

  // For display of assigned volunteers (fetched separately or from event assignments)
  final List<EventAssignmentSummary>? assignments;

  RosterEvent({
    required this.id,
    required this.rosterId,
    this.rosterName,
    required this.date,
    this.notes,
    this.isCancelled = false,
    this.teamId,
    required this.slotsNeeded,
    this.filledSlots = 0,
    this.createdAt,
    this.assignments,
  });

  // Computed properties for UI compatibility
  bool get isFilled => filledSlots >= slotsNeeded;
  bool get isUnfilled => filledSlots == 0;
  bool get isPartial => filledSlots > 0 && filledSlots < slotsNeeded;

  // For backward compatibility with screens that use volunteersNeeded
  int get volunteersNeeded => slotsNeeded;

  // Computed list of assigned user names for display
  List<String> get assignedUserNames =>
      assignments?.map((a) => a.userName).toList() ?? [];

  factory RosterEvent.fromJson(Map<String, dynamic> json) {
    List<EventAssignmentSummary>? assignments;
    if (json['assignments'] != null) {
      assignments = (json['assignments'] as List)
          .map((a) => EventAssignmentSummary.fromJson(a))
          .toList();
    }

    return RosterEvent(
      id: json['id'].toString(),
      rosterId: json['roster_id'].toString(),
      rosterName: json['roster_name'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      isCancelled: json['is_cancelled'] ?? false,
      teamId: json['team_id']?.toString(),
      slotsNeeded: json['slots_needed'] ?? 1,
      filledSlots: json['filled_slots'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      assignments: assignments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roster_id': rosterId,
      'roster_name': rosterName,
      'date': date.toIso8601String().split('T')[0],
      'notes': notes,
      'is_cancelled': isCancelled,
      'team_id': teamId,
      'slots_needed': slotsNeeded,
      'filled_slots': filledSlots,
    };
  }
}

/// Summary of an assignment for display in event lists
class EventAssignmentSummary {
  final String id;
  final String userId;
  final String userName;
  final String status;
  final bool isPlaceholder;
  final bool isInvited;

  EventAssignmentSummary({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    this.isPlaceholder = false,
    this.isInvited = false,
  });

  factory EventAssignmentSummary.fromJson(Map<String, dynamic> json) {
    return EventAssignmentSummary(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      userName: json['user_name'] ?? '',
      status: json['status'] ?? 'pending',
      isPlaceholder: json['is_placeholder'] ?? false,
      isInvited: json['is_invited'] ?? false,
    );
  }
}
