class Roster {
  final String id;
  final String name;
  final String teamId;
  final String recurrencePattern;
  final int recurrenceDay;
  final int slotsNeeded;
  final String assignmentMode;
  final String? location;
  final String? notes;
  final DateTime startDate;
  final DateTime? endDate;
  final int? endAfterOccurrences;
  final bool isActive;
  final DateTime createdAt;

  // Additional fields for display
  final String? teamName;
  final int? filledSlots;
  final int? totalSlots;
  final DateTime? nextOccurrence;

  Roster({
    required this.id,
    required this.name,
    required this.teamId,
    required this.recurrencePattern,
    required this.recurrenceDay,
    required this.slotsNeeded,
    required this.assignmentMode,
    this.location,
    this.notes,
    required this.startDate,
    this.endDate,
    this.endAfterOccurrences,
    this.isActive = true,
    required this.createdAt,
    this.teamName,
    this.filledSlots,
    this.totalSlots,
    this.nextOccurrence,
  });

  bool get isFullyFilled =>
      filledSlots != null && totalSlots != null && filledSlots == totalSlots;
  bool get hasUnfilledSlots =>
      filledSlots != null && totalSlots != null && filledSlots! < totalSlots!;
  bool get isOneTime => recurrencePattern == 'one_time';

  factory Roster.fromJson(Map<String, dynamic> json) {
    return Roster(
      id: json['id'],
      name: json['name'],
      teamId: json['team_id'],
      recurrencePattern: json['recurrence_pattern'],
      recurrenceDay: json['recurrence_day'],
      slotsNeeded: json['slots_needed'],
      assignmentMode: json['assignment_mode'],
      location: json['location'],
      notes: json['notes'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      endAfterOccurrences: json['end_after_occurrences'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      teamName: json['team_name'],
      filledSlots: json['filled_slots'],
      totalSlots: json['total_slots'],
      nextOccurrence: json['next_occurrence'] != null
          ? DateTime.parse(json['next_occurrence'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'team_id': teamId,
      'recurrence_pattern': recurrencePattern,
      'recurrence_day': recurrenceDay,
      'slots_needed': slotsNeeded,
      'assignment_mode': assignmentMode,
      'location': location,
      'notes': notes,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'end_after_occurrences': endAfterOccurrences,
      'is_active': isActive,
    };
  }
}
