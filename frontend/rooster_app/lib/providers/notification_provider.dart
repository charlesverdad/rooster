import 'package:flutter/foundation.dart';

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use mock data
      _notifications = [
        {
          'id': '1',
          'type': 'assignment',
          'title': 'New Assignment',
          'message': 'You\'ve been assigned to Sunday Service on ${_formatDate(DateTime.now().add(const Duration(days: 2)))}',
          'time': '2 hours ago',
          'isRead': false,
        },
        {
          'id': '2',
          'type': 'reminder',
          'title': 'Upcoming Assignment',
          'message': 'Sunday Service tomorrow at 9:00 AM',
          'time': '1 day ago',
          'isRead': false,
        },
        {
          'id': '3',
          'type': 'info',
          'title': 'Team Update',
          'message': 'Mike Chen added you to Media Team',
          'time': '3 days ago',
          'isRead': true,
        },
      ];
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));
      
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index] = {
          ..._notifications[index],
          'isRead': true,
        };
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      _notifications = _notifications.map((n) => {
        ...n,
        'isRead': true,
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));
      
      _notifications.removeWhere((n) => n['id'] == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
