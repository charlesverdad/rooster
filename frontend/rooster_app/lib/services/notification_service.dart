import 'dart:convert';
import '../models/notification.dart';
import 'api_client.dart';
import 'team_service.dart';

class NotificationService {
  /// Get all notifications for the current user
  static Future<List<AppNotification>> getNotifications({
    bool? unreadOnly,
    int? limit,
    int? offset,
  }) async {
    var endpoint = '/notifications';
    final params = <String>[];

    if (unreadOnly == true) params.add('unread_only=true');
    if (limit != null) params.add('limit=$limit');
    if (offset != null) params.add('offset=$offset');

    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Mark a single notification as read
  static Future<void> markAsRead(String notificationId) async {
    final response =
        await ApiClient.post('/notifications/$notificationId/read', {});

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final response = await ApiClient.post('/notifications/read-all', {});

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    final response = await ApiClient.delete('/notifications/$notificationId');

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
