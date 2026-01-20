import '../models/assignment.dart';
import '../models/roster.dart';
import '../models/roster_event.dart';

class MockData {
  // Mock rosters (mutable for adding new ones)
  static final List<Roster> _rosters = [
    Roster(
      id: 'roster1',
      teamId: '1',
      name: 'Sunday Service',
      recurrencePattern: 'weekly',
      recurrenceDay: 0, // Sunday
      slotsNeeded: 2,
      assignmentMode: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Roster(
      id: 'roster2',
      teamId: '1',
      name: 'Wednesday Prayer',
      recurrencePattern: 'weekly',
      recurrenceDay: 3, // Wednesday
      slotsNeeded: 1,
      assignmentMode: 'manual',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  // Mock events (mutable for adding new ones)
  static final List<RosterEvent> _events = [
    // Sunday Service events
    RosterEvent(
      id: 'event1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(0),
      volunteersNeeded: 2,
      assignedUserIds: ['user1', 'user2'],
      assignedUserNames: ['Mike Chen', 'John Smith'],
    ),
    RosterEvent(
      id: 'event2',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(1),
      volunteersNeeded: 2,
      assignedUserIds: ['user1'],
      assignedUserNames: ['Mike Chen'],
    ),
    RosterEvent(
      id: 'event3',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(2),
      volunteersNeeded: 2,
      assignedUserIds: [],
    ),
    RosterEvent(
      id: 'event4',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(3),
      volunteersNeeded: 2,
      assignedUserIds: [],
    ),
    RosterEvent(
      id: 'event5',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(4),
      volunteersNeeded: 2,
      assignedUserIds: [],
    ),
    RosterEvent(
      id: 'event6',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(5),
      volunteersNeeded: 2,
      assignedUserIds: [],
    ),
    RosterEvent(
      id: 'event7',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      dateTime: _getNextSunday(6),
      volunteersNeeded: 2,
      assignedUserIds: [],
    ),
    // Wednesday Prayer events
    RosterEvent(
      id: 'event8',
      rosterId: 'roster2',
      rosterName: 'Wednesday Prayer',
      dateTime: _getNextWednesday(0),
      volunteersNeeded: 1,
      assignedUserIds: ['user3'],
      assignedUserNames: ['Sarah Johnson'],
    ),
    RosterEvent(
      id: 'event9',
      rosterId: 'roster2',
      rosterName: 'Wednesday Prayer',
      dateTime: _getNextWednesday(1),
      volunteersNeeded: 1,
      assignedUserIds: [],
    ),
  ];

  // Helper methods for rosters
  static List<Roster> getRostersForTeam(String teamId) {
    return _rosters.where((r) => r.teamId == teamId).toList();
  }

  static Roster? getRosterById(String rosterId) {
    try {
      return _rosters.firstWhere((r) => r.id == rosterId);
    } catch (e) {
      return null;
    }
  }

  static void addRoster(Roster roster, List<RosterEvent> events) {
    _rosters.add(roster);
    _events.addAll(events);
  }

  // Helper methods for events
  static List<RosterEvent> getEventsForRoster(String rosterId) {
    return _events.where((e) => e.rosterId == rosterId).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  static void addEventsToRoster(String rosterId, List<RosterEvent> events) {
    _events.addAll(events);
  }

  static void updateEvent(RosterEvent event) {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
    }
  }

  // Helper to get next occurrence of a day
  static DateTime _getNextSunday(int weeksFromNow) {
    final now = DateTime.now();
    DateTime next = now;
    
    // Find next Sunday
    while (next.weekday != DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    
    // Add weeks
    next = next.add(Duration(days: 7 * weeksFromNow));
    
    // Set time to 9:00 AM
    return DateTime(next.year, next.month, next.day, 9, 0);
  }

  static DateTime _getNextWednesday(int weeksFromNow) {
    final now = DateTime.now();
    DateTime next = now;
    
    // Find next Wednesday
    while (next.weekday != DateTime.wednesday) {
      next = next.add(const Duration(days: 1));
    }
    
    // Add weeks
    next = next.add(Duration(days: 7 * weeksFromNow));
    
    // Set time to 7:00 PM
    return DateTime(next.year, next.month, next.day, 19, 0);
  }

  // Mock assignments
  static List<Assignment> get assignments => [
    Assignment(
      id: '1',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 2)),
      status: 'pending',
    ),
    Assignment(
      id: '2',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 9)),
      status: 'accepted',
    ),
    Assignment(
      id: '3',
      userId: 'user1',
      rosterId: 'roster2',
      rosterName: 'Wednesday Prayer',
      date: DateTime.now().add(const Duration(days: 5)),
      status: 'pending',
    ),
    Assignment(
      id: '4',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 16)),
      status: 'accepted',
    ),
    Assignment(
      id: '5',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 23)),
      status: 'accepted',
    ),
  ];

  // Mock teams
  static List<Map<String, dynamic>> get teams => [
    {
      'id': '1',
      'name': 'Media Team',
      'icon': '📹',
      'memberCount': 12,
      'nextDate': _formatNextDate(2),
      'role': 'Lead',
      'description': 'Run slides and sound for Sunday services',
    },
    {
      'id': '2',
      'name': 'Worship Team',
      'icon': '🎵',
      'memberCount': 8,
      'nextDate': _formatNextDate(2),
      'role': 'Member',
      'description': 'Lead worship during services',
    },
  ];

  // Mock team members
  static List<Map<String, dynamic>> get teamMembers => [
    {
      'id': 'user1',
      'name': 'Mike Chen',
      'email': 'mike@example.com',
      'phone': '(555) 123-4567',
      'role': 'Lead',
      'isPlaceholder': false,
      'isInvited': false,
    },
    {
      'id': 'user2',
      'name': 'John Smith',
      'email': 'john@example.com',
      'phone': '(555) 234-5678',
      'role': 'Member',
      'isPlaceholder': false,
      'isInvited': false,
    },
    {
      'id': 'user3',
      'name': 'Sarah Johnson',
      'email': 'sarah@example.com',
      'phone': '(555) 345-6789',
      'role': 'Member',
      'isPlaceholder': false,
      'isInvited': false,
    },
    {
      'id': 'user4',
      'name': 'Emma Davis',
      'email': null,
      'phone': null,
      'role': 'Member',
      'isPlaceholder': true,
      'isInvited': false,
    },
    {
      'id': 'user5',
      'name': 'Tom Wilson',
      'email': null,
      'phone': null,
      'role': 'Member',
      'isPlaceholder': true,
      'isInvited': true,
    },
  ];

  // Mock roster dates (deprecated - use events instead)
  static List<Map<String, dynamic>> get rosterDates => [
    {
      'id': 'date1',
      'date': _formatNextDate(2),
      'rosterName': 'Sunday Service',
      'time': '9:00 AM',
      'filled': 2,
      'needed': 2,
    },
    {
      'id': 'date2',
      'date': _formatNextDate(9),
      'rosterName': 'Sunday Service',
      'time': '9:00 AM',
      'filled': 1,
      'needed': 2,
    },
    {
      'id': 'date3',
      'date': _formatNextDate(16),
      'rosterName': 'Sunday Service',
      'time': '9:00 AM',
      'filled': 2,
      'needed': 2,
    },
  ];

  // Mock unavailability
  static List<Map<String, dynamic>> get unavailability => [
    {
      'id': 'unavail1',
      'userId': 'user1',
      'startDate': DateTime.now().add(const Duration(days: 30)),
      'endDate': DateTime.now().add(const Duration(days: 37)),
      'reason': 'Vacation',
    },
  ];

  static String _formatNextDate(int daysFromNow) {
    final date = DateTime.now().add(Duration(days: daysFromNow));
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }
}

