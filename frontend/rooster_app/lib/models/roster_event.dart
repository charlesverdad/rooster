class RosterEvent {
  final String id;
  final String rosterId;
  final String rosterName;
  final DateTime dateTime;
  final int volunteersNeeded;
  final List<String> assignedUserIds;
  final List<String>? assignedUserNames;

  RosterEvent({
    required this.id,
    required this.rosterId,
    required this.rosterName,
    required this.dateTime,
    required this.volunteersNeeded,
    required this.assignedUserIds,
    this.assignedUserNames,
  });

  String get status {
    if (assignedUserIds.isEmpty) return 'unfilled';
    if (assignedUserIds.length < volunteersNeeded) return 'partial';
    return 'filled';
  }

  bool get isFilled => assignedUserIds.length >= volunteersNeeded;
  bool get isUnfilled => assignedUserIds.isEmpty;
  bool get isPartial => assignedUserIds.isNotEmpty && assignedUserIds.length < volunteersNeeded;

  factory RosterEvent.fromJson(Map<String, dynamic> json) {
    return RosterEvent(
      id: json['id'],
      rosterId: json['roster_id'],
      rosterName: json['roster_name'] ?? '',
      dateTime: DateTime.parse(json['date_time']),
      volunteersNeeded: json['volunteers_needed'],
      assignedUserIds: List<String>.from(json['assigned_user_ids'] ?? []),
      assignedUserNames: json['assigned_user_names'] != null
          ? List<String>.from(json['assigned_user_names'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roster_id': rosterId,
      'roster_name': rosterName,
      'date_time': dateTime.toIso8601String(),
      'volunteers_needed': volunteersNeeded,
      'assigned_user_ids': assignedUserIds,
      'assigned_user_names': assignedUserNames,
    };
  }
}
