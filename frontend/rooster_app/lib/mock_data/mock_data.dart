import '../models/assignment.dart';

class MockData {
  // Mock assignments
  static List<Assignment> get assignments => [
    Assignment(
      id: '1',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 2)),
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Assignment(
      id: '2',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 9)),
      status: 'accepted',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Assignment(
      id: '3',
      userId: 'user1',
      rosterId: 'roster2',
      rosterName: 'Wednesday Prayer',
      date: DateTime.now().add(const Duration(days: 5)),
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Assignment(
      id: '4',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 16)),
      status: 'accepted',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Assignment(
      id: '5',
      userId: 'user1',
      rosterId: 'roster1',
      rosterName: 'Sunday Service',
      date: DateTime.now().add(const Duration(days: 23)),
      status: 'accepted',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
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

  // Mock roster dates
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
