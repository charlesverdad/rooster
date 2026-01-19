import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/api_client.dart';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = unreadOnly ? '/notifications?unread_only=true' : '/notifications';
      final response = await ApiClient.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications = data.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        _error = 'Failed to load notifications';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await ApiClient.patch('/notifications/$id/read', {});

      if (response.statusCode == 200) {
        await fetchNotifications();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await ApiClient.patch('/notifications/read-all', {});

      if (response.statusCode == 200) {
        await fetchNotifications();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await ApiClient.delete('/notifications/$id');

      if (response.statusCode == 204) {
        await fetchNotifications();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }
}
