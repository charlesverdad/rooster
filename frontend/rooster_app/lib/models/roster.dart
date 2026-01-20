class Roster {
  final String id;
  final String name;
  final String teamId;
  final String? description;
  final String recurrencePattern;
  final int? recurrenceDay;
  final int slotsNeeded;
  final String assignmentMode;
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
    this.description,
    required this.recurrencePattern,
    this.recurrenceDay,
    required this.slotsNeeded,
    required this.assignmentMode,
    required this.createdAt,
    this.teamName,
    this.filledSlots,
    this.totalSlots,
    this.nextOccurrence,
  });

  bool get isFullyFilled => filledSlots != null && totalSlots != null && filledSlots == totalSlots;
  bool get hasUnfilledSlots => filledSlots != null && totalSlots != null && filledSlots! < totalSlots!;

  factory Roster.fromJson(Map<String, dynamic> json) {
    return Roster(
      id: json['id'],
      name: json['name'],
      teamId: json['team_id'],
      description: json['description'],
      recurrencePattern: json['recurrence_pattern'],
      recurrenceDay: json['recurrence_day'],
      slotsNeeded: json['slots_needed'],
      assignmentMode: json['assignment_mode'],
      createdAt: DateTime.parse(json['created_at']),
      teamName: json['team_name'],
      filledSlots: json['filled_slots'],
      totalSlots: json['total_slots'],
      nextOccurrence: json['next_occurrence'] != null 
          ? DateTime.parse(json['next_occurrence']) 
          : null,
    );
  }
}
