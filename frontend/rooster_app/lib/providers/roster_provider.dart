import 'package:flutter/foundation.dart';
import '../models/roster.dart';
import '../models/roster_event.dart';
import '../mock_data/mock_data.dart';

class RosterProvider with ChangeNotifier {
  List<Roster> _rosters = [];
  Roster? _currentRoster;
  List<RosterEvent> _currentEvents = [];
  bool _isLoading = false;
  String? _error;

  List<Roster> get rosters => _rosters;
  Roster? get currentRoster => _currentRoster;
  List<RosterEvent> get currentEvents => _currentEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeamRosters(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use mock data
      _rosters = MockData.getRostersForTeam(teamId);
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRosterDetail(String rosterId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      _currentRoster = MockData.getRosterById(rosterId);
      _currentEvents = MockData.getEventsForRoster(rosterId);
      
      // Auto-generate more events if running low (≤ 3 remaining)
      if (_currentEvents.length <= 3 && _currentRoster != null) {
        await _generateMoreEvents();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching roster detail: $e');
    }
  }

  Future<bool> createRoster({
    required String teamId,
    required String name,
    required String recurrence,
    required int dayOfWeek,
    required String time,
    required int volunteersNeeded,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create roster
      final roster = Roster(
        id: 'roster${_rosters.length + 1}',
        teamId: teamId,
        name: name,
        recurrencePattern: recurrence,
        recurrenceDay: dayOfWeek,
        slotsNeeded: volunteersNeeded,
        assignmentMode: 'manual',
        createdAt: DateTime.now(),
      );
      
      // Generate 7 initial events
      final events = _generateInitialEvents(roster, 7);
      
      // Add to mock data
      MockData.addRoster(roster, events);
      
      // Set as current
      _currentRoster = roster;
      _currentEvents = events;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating roster: $e');
      return false;
    }
  }

  Future<void> generateMoreEvents() async {
    await _generateMoreEvents();
  }

  Future<void> _generateMoreEvents() async {
    if (_currentRoster == null) return;
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Get the last event date
      final lastEvent = _currentEvents.isNotEmpty
          ? _currentEvents.last
          : null;
      
      final startDate = lastEvent?.dateTime ?? DateTime.now();
      
      // Generate 7 more events
      final newEvents = _generateEventsFromDate(
        _currentRoster!,
        startDate,
        7,
      );
      
      // Add to mock data and current events
      MockData.addEventsToRoster(_currentRoster!.id, newEvents);
      _currentEvents.addAll(newEvents);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating more events: $e');
    }
  }

  List<RosterEvent> _generateInitialEvents(Roster roster, int count) {
    return _generateEventsFromDate(roster, DateTime.now(), count);
  }

  List<RosterEvent> _generateEventsFromDate(
    Roster roster,
    DateTime startDate,
    int count,
  ) {
    final events = <RosterEvent>[];
    DateTime currentDate = _findNextOccurrence(startDate, roster);

    for (int i = 0; i < count; i++) {
      final eventId = 'event_${roster.id}_${currentDate.millisecondsSinceEpoch}';
      
      events.add(RosterEvent(
        id: eventId,
        rosterId: roster.id,
        rosterName: roster.name,
        dateTime: currentDate,
        volunteersNeeded: roster.slotsNeeded,
        assignedUserIds: [],
      ));

      // Calculate next occurrence
      currentDate = _calculateNextOccurrence(currentDate, roster);
    }

    return events;
  }

  DateTime _findNextOccurrence(DateTime from, Roster roster) {
    DateTime candidate = from;
    
    // Find the next occurrence of the specified day
    while (candidate.weekday % 7 != roster.recurrenceDay) {
      candidate = candidate.add(const Duration(days: 1));
    }
    
    // Set the time
    final timeParts = roster.recurrencePattern.contains(':')
        ? roster.recurrencePattern.split(':')
        : ['09', '00'];
    
    return DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts.length > 1 ? timeParts[1] : '00'),
    );
  }

  DateTime _calculateNextOccurrence(DateTime current, Roster roster) {
    switch (roster.recurrencePattern) {
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'biweekly':
        return current.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(
          current.month == 12 ? current.year + 1 : current.year,
          current.month == 12 ? 1 : current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      default:
        return current.add(const Duration(days: 7));
    }
  }

  Future<bool> assignVolunteerToEvent(String eventId, String userId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      final eventIndex = _currentEvents.indexWhere((e) => e.id == eventId);
      if (eventIndex != -1) {
        final event = _currentEvents[eventIndex];
        final updatedEvent = RosterEvent(
          id: event.id,
          rosterId: event.rosterId,
          rosterName: event.rosterName,
          dateTime: event.dateTime,
          volunteersNeeded: event.volunteersNeeded,
          assignedUserIds: [...event.assignedUserIds, userId],
          assignedUserNames: event.assignedUserNames,
        );
        
        _currentEvents[eventIndex] = updatedEvent;
        MockData.updateEvent(updatedEvent);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error assigning volunteer: $e');
      return false;
    }
  }

  void clearCurrentRoster() {
    _currentRoster = null;
    _currentEvents = [];
    notifyListeners();
  }
}
