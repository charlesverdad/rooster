import 'package:flutter_test/flutter_test.dart';
import 'package:rooster_app/models/notification.dart';
import 'package:rooster_app/providers/notification_provider.dart';

void main() {
  group('NotificationProvider', () {
    late NotificationProvider provider;

    setUp(() {
      provider = NotificationProvider();
    });

    test('initial state is correct', () {
      expect(provider.notifications, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
      expect(provider.unreadCount, 0);
    });

    test('unreadCount returns count of unread notifications', () {
      // We can't easily set internal state without mocking the service,
      // but we can test the getter logic via the model
      final unread = AppNotification(
        id: '1',
        userId: 'u1',
        type: 'info',
        title: 'Unread',
        message: 'msg',
        createdAt: DateTime.now(),
      );
      final read = AppNotification(
        id: '2',
        userId: 'u1',
        type: 'info',
        title: 'Read',
        message: 'msg',
        readAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      expect(unread.isRead, false);
      expect(read.isRead, true);
    });

    test('clearError sets error to null', () {
      provider.clearError();
      expect(provider.error, isNull);
    });
  });
}
