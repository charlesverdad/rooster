class Assignment {
  final String id;
  final String rosterId;
  final String userId;
  final DateTime date;
  final String status;
  final String? rosterName;
  final String? userName;

  Assignment({
    required this.id,
    required this.rosterId,
    required this.userId,
    required this.date,
    required this.status,
    this.rosterName,
    this.userName,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      rosterId: json['roster_id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      rosterName: json['roster_name'],
      userName: json['user_name'],
    );
  }
}
