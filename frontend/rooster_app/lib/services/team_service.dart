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

  /// Get team availability for a specific date
  static Future<List<Map<String, dynamic>>> getTeamAvailability(
    String teamId, {
    DateTime? date,
  }) async {
    var endpoint = '/dashboard/teams/$teamId/availability';
    if (date != null) {
      endpoint += '?target_date=${date.toIso8601String().split('T')[0]}';
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update a team
  static Future<Team> updateTeam(String teamId, {String? name}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;

    final response = await ApiClient.patch('/teams/$teamId', body);

    if (response.statusCode == 200) {
      return Team.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Delete a team
  static Future<void> deleteTeam(String teamId) async {
    final response = await ApiClient.delete('/teams/$teamId');

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update member permissions
  static Future<void> updateMemberPermissions(
    String teamId,
    String userId,
    List<String> permissions,
  ) async {
    final response = await ApiClient.patch(
      '/teams/$teamId/members/$userId/permissions',
      {'permissions': permissions},
    );

    if (response.statusCode != 200) {
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

// ApiException is now defined in api_client.dart and exported from there
