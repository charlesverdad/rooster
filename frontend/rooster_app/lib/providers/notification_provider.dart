import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/team_service.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await NotificationService.getNotifications(
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          readAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();

      // Update local state
      _notifications = _notifications
          .map((n) => n.isRead ? n : n.copyWith(readAt: DateTime.now()))
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await NotificationService.deleteNotification(notificationId);

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error deleting notification: $e');
      return false;
    }
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
