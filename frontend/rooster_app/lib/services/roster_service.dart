import 'dart:convert';
import '../models/roster.dart';
import '../models/roster_event.dart';
import '../models/suggestion.dart';
import 'api_client.dart';

class RosterService {
  /// Get all rosters for a team
  static Future<List<Roster>> getTeamRosters(String teamId) async {
    final response = await ApiClient.get('/rosters/team/$teamId');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Roster.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get a specific roster by ID
  static Future<Roster> getRoster(String rosterId) async {
    final response = await ApiClient.get('/rosters/$rosterId');

    if (response.statusCode == 200) {
      return Roster.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update a roster
  static Future<Roster> updateRoster(
    String rosterId, {
    String? name,
    int? slotsNeeded,
    String? location,
    String? notes,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (slotsNeeded != null) body['slots_needed'] = slotsNeeded;
    if (location != null) body['location'] = location;
    if (notes != null) body['notes'] = notes;
    if (isActive != null) body['is_active'] = isActive;

    final response = await ApiClient.patch('/rosters/$rosterId', body);

    if (response.statusCode == 200) {
      return Roster.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Delete a roster
  static Future<void> deleteRoster(String rosterId) async {
    final response = await ApiClient.delete('/rosters/$rosterId');

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Create a new roster
  static Future<Roster> createRoster({
    required String teamId,
    required String name,
    required String recurrencePattern,
    required int recurrenceDay,
    required int slotsNeeded,
    required DateTime startDate,
    String assignmentMode = 'manual',
    String? location,
    String? notes,
    DateTime? endDate,
    int? endAfterOccurrences,
    int generateEventsCount = 7,
  }) async {
    final body = {
      'team_id': teamId,
      'name': name,
      'recurrence_pattern': recurrencePattern,
      'recurrence_day': recurrenceDay,
      'slots_needed': slotsNeeded,
      'start_date': startDate.toIso8601String().split('T')[0],
      'assignment_mode': assignmentMode,
      'generate_events_count': generateEventsCount,
    };

    if (location != null) body['location'] = location;
    if (notes != null) body['notes'] = notes;
    if (endDate != null) {
      body['end_date'] = endDate.toIso8601String().split('T')[0];
    }
    if (endAfterOccurrences != null) {
      body['end_after_occurrences'] = endAfterOccurrences;
    }

    final response = await ApiClient.post('/rosters', body);

    if (response.statusCode == 201) {
      return Roster.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get events for a roster
  static Future<List<RosterEvent>> getRosterEvents(
    String rosterId, {
    DateTime? startDate,
    DateTime? endDate,
    bool includeCancelled = false,
  }) async {
    var endpoint =
        '/rosters/$rosterId/events?include_cancelled=$includeCancelled';

    if (startDate != null) {
      endpoint += '&start_date=${startDate.toIso8601String().split('T')[0]}';
    }
    if (endDate != null) {
      endpoint += '&end_date=${endDate.toIso8601String().split('T')[0]}';
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RosterEvent.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get all events for a team
  static Future<List<RosterEvent>> getTeamEvents(
    String teamId, {
    DateTime? startDate,
    DateTime? endDate,
    bool includeCancelled = false,
  }) async {
    var endpoint =
        '/rosters/events/team/$teamId?include_cancelled=$includeCancelled';

    if (startDate != null) {
      endpoint += '&start_date=${startDate.toIso8601String().split('T')[0]}';
    }
    if (endDate != null) {
      endpoint += '&end_date=${endDate.toIso8601String().split('T')[0]}';
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RosterEvent.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get unfilled events for a team
  static Future<List<RosterEvent>> getUnfilledEvents(
    String teamId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var endpoint = '/rosters/events/team/$teamId/unfilled';

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
      return data.map((json) => RosterEvent.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Generate more events for a roster
  static Future<List<RosterEvent>> generateMoreEvents(
    String rosterId, {
    int count = 7,
  }) async {
    final response = await ApiClient.post(
      '/rosters/$rosterId/events/generate?count=$count',
      {},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => RosterEvent.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get a specific event
  static Future<RosterEvent> getEvent(String eventId) async {
    final response = await ApiClient.get('/rosters/events/$eventId');

    if (response.statusCode == 200) {
      return RosterEvent.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Update an event
  static Future<RosterEvent> updateEvent(
    String eventId, {
    String? notes,
    bool? isCancelled,
  }) async {
    final body = <String, dynamic>{};
    if (notes != null) body['notes'] = notes;
    if (isCancelled != null) body['is_cancelled'] = isCancelled;

    final response = await ApiClient.patch('/rosters/events/$eventId', body);

    if (response.statusCode == 200) {
      return RosterEvent.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get assignment suggestions for an event
  static Future<List<Suggestion>> getSuggestionsForEvent(
    String eventId, {
    int limit = 10,
  }) async {
    final response = await ApiClient.get(
      '/rosters/events/$eventId/suggestions?limit=$limit',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> suggestions = data['suggestions'] ?? [];
      return suggestions.map((json) => Suggestion.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Map<String, dynamic>> autoAssignAllEvents(
    String rosterId,
  ) async {
    final response = await ApiClient.post(
      '/rosters/$rosterId/auto-assign-all',
      {},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
