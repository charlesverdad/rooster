import 'dart:convert';
import '../models/team.dart';
import '../models/team_member.dart';
import 'api_client.dart';

class TeamService {
  /// Create a new team
  static Future<Team> createTeam(String name) async {
    final response = await ApiClient.post('/teams', {'name': name});

    if (response.statusCode == 201) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get all teams for the current user
  static Future<List<Team>> getMyTeams() async {
    final response = await ApiClient.get('/teams');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Team.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get a specific team by ID
  static Future<Team> getTeam(String teamId) async {
    final response = await ApiClient.get('/teams/$teamId');

    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get all members of a team
  static Future<List<TeamMember>> getTeamMembers(String teamId) async {
    final response = await ApiClient.get('/teams/$teamId/members');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TeamMember.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Add a placeholder member to a team (name only)
  static Future<TeamMember> addPlaceholderMember(
    String teamId,
    String name, {
    String role = 'member',
  }) async {
    final response = await ApiClient.post(
      '/teams/$teamId/members/placeholder',
      {'name': name, 'role': role},
    );

    if (response.statusCode == 201) {
      return TeamMember.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Add an existing user to a team
  static Future<TeamMember> addMember(
    String teamId,
    String userId, {
    String role = 'member',
  }) async {
    final response = await ApiClient.post(
      '/teams/$teamId/members',
      {'user_id': userId, 'role': role},
    );

    if (response.statusCode == 201) {
      return TeamMember.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Remove a member from a team
  static Future<void> removeMember(String teamId, String userId) async {
    final response = await ApiClient.delete('/teams/$teamId/members/$userId');

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;

  ApiException(this.statusCode, this.body);

  String get message {
    try {
      final data = jsonDecode(body);
      return data['detail'] ?? 'Unknown error';
    } catch (_) {
      return body;
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
