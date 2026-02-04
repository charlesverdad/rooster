import 'dart:convert';
import 'api_client.dart';

class Invite {
  final String id;
  final String teamId;
  final String userId;
  final String email;
  final String status; // pending, accepted, expired
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  // Related data
  final String? teamName;
  final String? userName;

  Invite({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.email,
    required this.status,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
    this.teamName,
    this.userName,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isExpired =>
      status == 'expired' || DateTime.now().isAfter(expiresAt);

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'].toString(),
      teamId: json['team_id'].toString(),
      userId: json['user_id'].toString(),
      email: json['email'] ?? '',
      status: json['status'] ?? 'pending',
      token: json['token'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(days: 7)),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
      teamName: json['team']?['name'],
      userName: json['user']?['name'],
    );
  }
}

class InviteService {
  /// Send an invite to a placeholder member
  static Future<Invite> sendInvite(
    String teamId,
    String userId,
    String email,
  ) async {
    final response = await ApiClient.post(
      '/invites/team/$teamId/user/$userId',
      {'email': email},
    );

    if (response.statusCode == 201) {
      return Invite.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get all invites for a team
  static Future<List<Invite>> getTeamInvites(String teamId) async {
    final response = await ApiClient.get('/invites/team/$teamId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invite.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Resend an invite (generates a new token)
  static Future<Invite> resendInvite(String inviteId) async {
    final response = await ApiClient.post('/invites/$inviteId/resend', {});

    if (response.statusCode == 200) {
      return Invite.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Validate an invite token
  static Future<Map<String, dynamic>> validateToken(String token) async {
    final response = await ApiClient.get('/invites/validate/$token');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Accept an invite
  static Future<Map<String, dynamic>> acceptInvite(
    String token,
    String? password,
  ) async {
    final body = <String, dynamic>{};
    if (password != null) {
      body['password'] = password;
    }
    final response = await ApiClient.post('/invites/accept/$token', body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get pending invites for the current logged-in user
  static Future<List<PendingInvite>> getMyPendingInvites() async {
    final response = await ApiClient.get('/invites/my-pending');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PendingInvite.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Accept a pending invite by team ID (for logged-in users)
  static Future<Map<String, dynamic>> acceptInviteByTeam(String teamId) async {
    final response = await ApiClient.post('/invites/accept-team/$teamId', {});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class PendingInvite {
  final String id;
  final String teamId;
  final String teamName;
  final String email;
  final DateTime createdAt;

  PendingInvite({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.email,
    required this.createdAt,
  });

  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    return PendingInvite(
      id: json['id'].toString(),
      teamId: json['team_id'].toString(),
      teamName: json['team_name'] ?? 'Unknown team',
      email: json['email'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
