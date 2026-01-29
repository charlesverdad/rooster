class SwapRequest {
  final String id;
  final String requesterAssignmentId;
  final String targetUserId;
  final String status; // 'pending', 'accepted', 'declined', 'expired'
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final String? requesterName;
  final String? targetName;
  final String? rosterName;
  final DateTime? assignmentDate;

  SwapRequest({
    required this.id,
    required this.requesterAssignmentId,
    required this.targetUserId,
    required this.status,
    required this.expiresAt,
    this.respondedAt,
    required this.createdAt,
    this.requesterName,
    this.targetName,
    this.rosterName,
    this.assignmentDate,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isExpired => status == 'expired';
  bool get isResolved => isAccepted || isDeclined || isExpired;

  factory SwapRequest.fromJson(Map<String, dynamic> json) {
    return SwapRequest(
      id: json['id'].toString(),
      requesterAssignmentId: json['requester_assignment_id'].toString(),
      targetUserId: json['target_user_id'].toString(),
      status: json['status'] ?? 'pending',
      expiresAt: DateTime.parse(json['expires_at']),
      respondedAt:
          json['responded_at'] != null ? DateTime.parse(json['responded_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      requesterName: json['requester_name'],
      targetName: json['target_name'],
      rosterName: json['roster_name'],
      assignmentDate: json['assignment_date'] != null
          ? DateTime.parse(json['assignment_date'])
          : null,
    );
  }

  SwapRequest copyWith({
    String? id,
    String? requesterAssignmentId,
    String? targetUserId,
    String? status,
    DateTime? expiresAt,
    DateTime? respondedAt,
    DateTime? createdAt,
    String? requesterName,
    String? targetName,
    String? rosterName,
    DateTime? assignmentDate,
  }) {
    return SwapRequest(
      id: id ?? this.id,
      requesterAssignmentId: requesterAssignmentId ?? this.requesterAssignmentId,
      targetUserId: targetUserId ?? this.targetUserId,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
      requesterName: requesterName ?? this.requesterName,
      targetName: targetName ?? this.targetName,
      rosterName: rosterName ?? this.rosterName,
      assignmentDate: assignmentDate ?? this.assignmentDate,
    );
  }
}
