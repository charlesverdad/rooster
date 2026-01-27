import 'dart:convert';
import '../models/event_assignment.dart';
import 'api_client.dart';

class AssignmentService {
  /// Get all event assignments for the current user
  static Future<List<EventAssignment>> getMyAssignments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var endpoint = '/rosters/event-assignments/my';

    if (startDate != null || endDate != null) {
      endpoint += '?';
      if (startDate != null) {
        endpoint += 'start_date=${startDate.toIso8601String().split('T')[0]}';
      }
      if (endDate != null) {
        if (startDate != null) endpoint += '&';
        endpoint += 'end_date=${endDate.toIso8601String().split('T')[0]}';
      }
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventAssignment.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get detailed assignment info including co-volunteers and team lead
  static Future<EventAssignmentDetail> getAssignmentDetail(
    String assignmentId,
  ) async {
    final response = await ApiClient.get(
      '/rosters/event-assignments/$assignmentId/detail',
    );

    if (response.statusCode == 200) {
      return EventAssignmentDetail.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update assignment status (pending, confirmed, declined)
  static Future<EventAssignment> updateAssignmentStatus(
    String assignmentId,
    String status,
  ) async {
    final response = await ApiClient.patch(
      '/rosters/event-assignments/$assignmentId',
      {'status': status},
    );

    if (response.statusCode == 200) {
      return EventAssignment.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get all assignments for a specific event
  static Future<List<EventAssignment>> getEventAssignments(
    String eventId,
  ) async {
    final response = await ApiClient.get(
      '/rosters/events/$eventId/assignments',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventAssignment.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get event assignments for a specific team member
  static Future<List<EventAssignment>> getTeamMemberAssignments(
    String teamId,
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var endpoint = '/teams/$teamId/members/$userId/assignments';

    if (startDate != null || endDate != null) {
      endpoint += '?';
      if (startDate != null) {
        endpoint += 'start_date=${startDate.toIso8601String().split('T')[0]}';
      }
      if (endDate != null) {
        if (startDate != null) endpoint += '&';
        endpoint += 'end_date=${endDate.toIso8601String().split('T')[0]}';
      }
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => EventAssignment.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Assign a user to an event
  static Future<EventAssignment> assignUserToEvent(
    String eventId,
    String userId,
  ) async {
    final response = await ApiClient.post(
      '/rosters/events/$eventId/assignments',
      {'event_id': eventId, 'user_id': userId},
    );

    if (response.statusCode == 201) {
      return EventAssignment.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Remove an assignment
  static Future<void> deleteAssignment(String assignmentId) async {
    final response = await ApiClient.delete(
      '/rosters/event-assignments/$assignmentId',
    );

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
