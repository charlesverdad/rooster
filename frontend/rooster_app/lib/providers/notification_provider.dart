import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Use mock data with proper model and reference IDs
      _notifications = [
        AppNotification(
          id: '1',
          userId: 'user1',
          type: 'assignment',
          title: 'New Assignment',
          message: 'You\'ve been assigned to Sunday Service on ${_formatDate(DateTime.now().add(const Duration(days: 2)))}',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          referenceId: '1', // Assignment ID
        ),
        AppNotification(
          id: '2',
          userId: 'user1',
          type: 'reminder',
          title: 'Upcoming Assignment',
          message: 'Sunday Service tomorrow at 9:00 AM',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          referenceId: '2', // Assignment ID
        ),
        AppNotification(
          id: '3',
          userId: 'user1',
          type: 'team',
          title: 'Team Update',
          message: 'Mike Chen added you to Media Team',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          readAt: DateTime.now().subtract(const Duration(days: 2)),
          referenceId: '1', // Team ID
        ),
        AppNotification(
          id: '4',
          userId: 'user1',
          type: 'response',
          title: 'Response Received',
          message: 'Sarah Johnson accepted Sunday Service',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          referenceId: 'event1', // Event ID
        ),
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

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          readAt: DateTime.now(),
        );
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

      _notifications = _notifications.map((n) =>
        n.isRead ? n : n.copyWith(readAt: DateTime.now())
      ).toList();
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

      _notifications.removeWhere((n) => n.id == notificationId);
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
