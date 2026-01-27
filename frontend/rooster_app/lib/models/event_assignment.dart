/// Represents a user's assignment to a roster event
class EventAssignment {
  final String id;
  final String eventId;
  final String userId;
  final String status; // pending, confirmed, declined
  final String? userName;
  final String? userEmail;
  final bool isPlaceholder;
  final bool isInvited;
  final DateTime createdAt;

  // Additional fields for display (populated from related data)
  final DateTime? eventDate;
  final String? rosterName;
  final String? teamName;

  EventAssignment({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.userName,
    this.userEmail,
    this.isPlaceholder = false,
    this.isInvited = false,
    required this.createdAt,
    this.eventDate,
    this.rosterName,
    this.teamName,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isDeclined => status == 'declined';

  // Alias for backward compatibility with screens using 'accepted'
  bool get isAccepted => status == 'confirmed';

  factory EventAssignment.fromJson(Map<String, dynamic> json) {
    return EventAssignment(
      id: json['id'].toString(),
      eventId: json['event_id'].toString(),
      userId: json['user_id'].toString(),
      status: json['status'] ?? 'pending',
      userName: json['user_name'],
      userEmail: json['user_email'],
      isPlaceholder: json['is_placeholder'] ?? false,
      isInvited: json['is_invited'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'])
          : null,
      rosterName: json['roster_name'],
      teamName: json['team_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'status': status,
      'user_name': userName,
      'user_email': userEmail,
      'is_placeholder': isPlaceholder,
      'is_invited': isInvited,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Detailed assignment response with co-volunteers and team lead info
class EventAssignmentDetail {
  final String id;
  final String eventId;
  final String userId;
  final String status;
  final String? userName;
  final String? userEmail;
  final bool isPlaceholder;
  final bool isInvited;
  final DateTime createdAt;

  // Event details
  final DateTime eventDate;
  final String rosterId;
  final String rosterName;
  final String teamId;
  final String teamName;
  final String? location;
  final String? notes;
  final int slotsNeeded;

  // Co-volunteers
  final List<CoVolunteer> coVolunteers;

  // Team lead contact info
  final TeamLead? teamLead;

  EventAssignmentDetail({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    this.userName,
    this.userEmail,
    this.isPlaceholder = false,
    this.isInvited = false,
    required this.createdAt,
    required this.eventDate,
    required this.rosterId,
    required this.rosterName,
    required this.teamId,
    required this.teamName,
    this.location,
    this.notes,
    required this.slotsNeeded,
    this.coVolunteers = const [],
    this.teamLead,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isDeclined => status == 'declined';
  bool get isAccepted => status == 'confirmed';

  factory EventAssignmentDetail.fromJson(Map<String, dynamic> json) {
    List<CoVolunteer> coVolunteers = [];
    if (json['co_volunteers'] != null) {
      coVolunteers = (json['co_volunteers'] as List)
          .map((cv) => CoVolunteer.fromJson(cv))
          .toList();
    }

    TeamLead? teamLead;
    if (json['team_lead'] != null) {
      teamLead = TeamLead.fromJson(json['team_lead']);
    }

    return EventAssignmentDetail(
      id: json['id'].toString(),
      eventId: json['event_id'].toString(),
      userId: json['user_id'].toString(),
      status: json['status'] ?? 'pending',
      userName: json['user_name'],
      userEmail: json['user_email'],
      isPlaceholder: json['is_placeholder'] ?? false,
      isInvited: json['is_invited'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      eventDate: DateTime.parse(json['event_date']),
      rosterId: json['roster_id'].toString(),
      rosterName: json['roster_name'] ?? '',
      teamId: json['team_id'].toString(),
      teamName: json['team_name'] ?? '',
      location: json['location'],
      notes: json['notes'],
      slotsNeeded: json['slots_needed'] ?? 1,
      coVolunteers: coVolunteers,
      teamLead: teamLead,
    );
  }
}

/// Info about a co-volunteer on the same event
class CoVolunteer {
  final String userId;
  final String name;
  final String status;
  final bool isPlaceholder;
  final bool isInvited;

  CoVolunteer({
    required this.userId,
    required this.name,
    required this.status,
    this.isPlaceholder = false,
    this.isInvited = false,
  });

  factory CoVolunteer.fromJson(Map<String, dynamic> json) {
    return CoVolunteer(
      userId: json['user_id'].toString(),
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      isPlaceholder: json['is_placeholder'] ?? false,
      isInvited: json['is_invited'] ?? false,
    );
  }
}

/// Info about the team lead for contact purposes
class TeamLead {
  final String userId;
  final String name;
  final String? email;
  final String? phone;

  TeamLead({required this.userId, required this.name, this.email, this.phone});

  factory TeamLead.fromJson(Map<String, dynamic> json) {
    return TeamLead(
      userId: json['user_id'].toString(),
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
    );
  }
}
