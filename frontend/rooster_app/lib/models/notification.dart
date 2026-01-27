class AppNotification {
  final String id;
  final String userId;
  final String type; // 'assignment', 'reminder', 'info', 'team'
  final String title;
  final String message;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? referenceId; // ID of related item (assignmentId, teamId, etc.)

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.readAt,
    required this.createdAt,
    this.referenceId,
  });

  bool get isRead => readAt != null;

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[createdAt.month - 1]} ${createdAt.day}';
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] ?? 'info';
    final normalizedType = _normalizeType(rawType);

    return AppNotification(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      type: normalizedType,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      referenceId: json['reference_id']?.toString(),
    );
  }

  static String _normalizeType(String type) {
    switch (type) {
      case 'assignment_created':
        return 'assignment';
      case 'assignment_reminder':
        return 'reminder';
      case 'conflict_detected':
        return 'response';
      case 'team_joined':
        return 'team';
      default:
        return type;
    }
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    DateTime? readAt,
    DateTime? createdAt,
    String? referenceId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      referenceId: referenceId ?? this.referenceId,
    );
  }
}
