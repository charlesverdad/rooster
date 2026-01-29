import 'package:flutter/foundation.dart';
import '../models/roster.dart';
import '../models/roster_event.dart';
import '../models/event_assignment.dart';
import '../models/suggestion.dart';
import '../services/api_client.dart';
import '../services/roster_service.dart';
import '../services/assignment_service.dart';

class RosterProvider with ChangeNotifier {
  List<Roster> _rosters = [];
  Roster? _currentRoster;
  List<RosterEvent> _currentEvents = [];
  List<Suggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  List<Roster> get rosters => _rosters;
  Roster? get currentRoster => _currentRoster;
  List<RosterEvent> get currentEvents => _currentEvents;
  List<Suggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeamRosters(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rosters = await RosterService.getTeamRosters(teamId);
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching rosters: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRosterDetail(String rosterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch roster and events in parallel
      final results = await Future.wait([
        RosterService.getRoster(rosterId),
        RosterService.getRosterEvents(rosterId),
      ]);

      _currentRoster = results[0] as Roster;
      _currentEvents = results[1] as List<RosterEvent>;

      // Sort events by date
      _currentEvents.sort((a, b) => a.date.compareTo(b.date));

      // Auto-generate more events if running low (≤ 3 remaining)
      if (_currentEvents.length <= 3 && _currentRoster != null) {
        await _generateMoreEventsInternal();
      }
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching roster detail: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createRoster({
    required String teamId,
    required String name,
    required String recurrence,
    required int dayOfWeek,
    required int volunteersNeeded,
    required DateTime startDate,
    String? location,
    String? notes,
    DateTime? endDate,
    int? endAfterOccurrences,
  }) async {
    try {
      final roster = await RosterService.createRoster(
        teamId: teamId,
        name: name,
        recurrencePattern: recurrence,
        recurrenceDay: dayOfWeek,
        slotsNeeded: volunteersNeeded,
        startDate: startDate,
        location: location,
        notes: notes,
        endDate: endDate,
        endAfterOccurrences: endAfterOccurrences,
      );

      // Set as current roster
      _currentRoster = roster;

      // Fetch the generated events
      _currentEvents = await RosterService.getRosterEvents(roster.id);
      _currentEvents.sort((a, b) => a.date.compareTo(b.date));

      // Add to local list
      _rosters.add(roster);

      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error creating roster: $e');
      return false;
    }
  }

  Future<void> generateMoreEvents() async {
    await _generateMoreEventsInternal();
  }

  Future<void> _generateMoreEventsInternal() async {
    if (_currentRoster == null) return;

    try {
      final newEvents = await RosterService.generateMoreEvents(
        _currentRoster!.id,
      );

      // Add new events to current list
      _currentEvents.addAll(newEvents);
      _currentEvents.sort((a, b) => a.date.compareTo(b.date));

      notifyListeners();
    } catch (e) {
      debugPrint('Error generating more events: $e');
    }
  }

  Future<bool> assignVolunteerToEvent(String eventId, String userId) async {
    try {
      await AssignmentService.assignUserToEvent(eventId, userId);

      // Refresh the event to get updated filled_slots
      final eventIndex = _currentEvents.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1 && _currentRoster != null) {
        // Refresh events from server
        final events = await RosterService.getRosterEvents(_currentRoster!.id);
        _currentEvents = events;
        _currentEvents.sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error assigning volunteer: $e');
      return false;
    }
  }

  Future<bool> removeAssignment(String assignmentId) async {
    try {
      await AssignmentService.deleteAssignment(assignmentId);

      // Refresh events to update filled slots
      if (_currentRoster != null) {
        final events = await RosterService.getRosterEvents(_currentRoster!.id);
        _currentEvents = events;
        _currentEvents.sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error removing assignment: $e');
      return false;
    }
  }

  Future<RosterEvent> fetchEvent(String eventId) async {
    return await RosterService.getEvent(eventId);
  }

  Future<bool> cancelEvent(String eventId, bool isCancelled) async {
    try {
      await RosterService.updateEvent(eventId, isCancelled: isCancelled);

      // Refresh events if viewing a roster
      if (_currentRoster != null) {
        final events = await RosterService.getRosterEvents(_currentRoster!.id);
        _currentEvents = events;
        _currentEvents.sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }

      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error cancelling event: $e');
      return false;
    }
  }

  Future<List<EventAssignment>> getEventAssignments(String eventId) async {
    try {
      return await AssignmentService.getEventAssignments(eventId);
    } catch (e) {
      debugPrint('Error fetching event assignments: $e');
      return [];
    }
  }

  Future<void> fetchSuggestionsForEvent(String eventId, {int limit = 10}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suggestions = await RosterService.getSuggestionsForEvent(eventId, limit: limit);
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching suggestions: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestions = [];
    notifyListeners();
  }

  Future<Map<String, dynamic>> autoAssignAllEvents(String rosterId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await RosterService.autoAssignAllEvents(rosterId);
      // Refresh the roster to show new assignments
      await fetchRoster(rosterId);
      return result;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error auto-assigning events: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRoster({
    String? name,
    int? slotsNeeded,
    String? location,
    String? notes,
  }) async {
    if (_currentRoster == null) return false;

    try {
      final updated = await RosterService.updateRoster(
        _currentRoster!.id,
        name: name,
        slotsNeeded: slotsNeeded,
        location: location,
        notes: notes,
      );

      _currentRoster = updated;

      // Update in local list
      final index = _rosters.indexWhere((r) => r.id == updated.id);
      if (index != -1) {
        _rosters[index] = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error updating roster: $e');
      return false;
    }
  }

  Future<bool> deleteRoster() async {
    if (_currentRoster == null) return false;

    try {
      await RosterService.deleteRoster(_currentRoster!.id);

      // Remove from local list
      _rosters.removeWhere((r) => r.id == _currentRoster!.id);
      _currentRoster = null;
      _currentEvents = [];

      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error deleting roster: $e');
      return false;
    }
  }

  void clearCurrentRoster() {
    _currentRoster = null;
    _currentEvents = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
