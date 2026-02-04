import 'package:flutter_test/flutter_test.dart';
import 'package:rooster_app/models/notification.dart';

void main() {
  group('AppNotification', () {
    group('fromJson', () {
      test('parses full notification json', () {
        final json = {
          'id': '123e4567-e89b-12d3-a456-426614174000',
          'user_id': 'user-1',
          'type': 'assignment_created',
          'title': 'New Assignment',
          'message': 'You have been assigned to Sunday Roster',
          'read_at': '2024-01-15T10:00:00Z',
          'created_at': '2024-01-15T09:00:00Z',
          'reference_id': 'ref-123',
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.id, '123e4567-e89b-12d3-a456-426614174000');
        expect(notification.userId, 'user-1');
        expect(notification.type, 'assignment');
        expect(notification.title, 'New Assignment');
        expect(notification.message, 'You have been assigned to Sunday Roster');
        expect(notification.readAt, isNotNull);
        expect(notification.referenceId, 'ref-123');
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'notif-1',
          'user_id': 'user-1',
          'type': 'info',
          'title': 'Info',
          'message': 'Hello',
        };

        final notification = AppNotification.fromJson(json);

        expect(notification.readAt, isNull);
        expect(notification.referenceId, isNull);
        expect(notification.isRead, false);
      });

      test('defaults type when missing', () {
        final json = {
          'id': 'notif-1',
          'user_id': 'user-1',
          'title': 'Test',
          'message': 'Test',
        };

        final notification = AppNotification.fromJson(json);
        expect(notification.type, 'info');
      });
    });

    group('type normalization', () {
      test('normalizes assignment_created to assignment', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'assignment_created',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'assignment');
      });

      test('normalizes assignment_confirmed to response', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'assignment_confirmed',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'response');
      });

      test('normalizes assignment_declined to alert', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'assignment_declined',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'alert');
      });

      test('normalizes team_invite to invite', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'team_invite',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'invite');
      });

      test('normalizes team_joined to team', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'team_joined',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'team');
      });

      test('normalizes team_removed to team', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'team_removed',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'team');
      });

      test('normalizes conflict_detected to conflict', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'conflict_detected',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'conflict');
      });

      test('normalizes assignment_reminder to reminder', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'assignment_reminder',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'reminder');
      });

      test('passes through unknown types', () {
        final n = AppNotification.fromJson({
          'id': '1',
          'user_id': 'u1',
          'type': 'custom_type',
          'title': 't',
          'message': 'm',
        });
        expect(n.type, 'custom_type');
      });
    });

    group('isRead', () {
      test('returns false when readAt is null', () {
        final n = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          createdAt: DateTime.now(),
        );
        expect(n.isRead, false);
      });

      test('returns true when readAt is set', () {
        final n = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          readAt: DateTime.now(),
          createdAt: DateTime.now(),
        );
        expect(n.isRead, true);
      });
    });

    group('timeAgo', () {
      test('shows minutes for recent notifications', () {
        final n = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(n.timeAgo, '5 min ago');
      });

      test('shows hours for notifications within a day', () {
        final n = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );
        expect(n.timeAgo, '3 hours ago');
      });

      test('shows days for notifications within a week', () {
        final n = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );
        expect(n.timeAgo, '2 days ago');
      });

      test('shows month and day for older notifications', () {
        final n = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          createdAt: DateTime(2024, 3, 15),
        );
        expect(n.timeAgo, 'Mar 15');
      });
    });

    group('copyWith', () {
      test('creates copy with changed readAt', () {
        final original = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Test',
          message: 'Test',
          createdAt: DateTime.now(),
        );

        final readTime = DateTime.now();
        final copy = original.copyWith(readAt: readTime);

        expect(copy.id, original.id);
        expect(copy.title, original.title);
        expect(copy.readAt, readTime);
        expect(copy.isRead, true);
        expect(original.isRead, false);
      });

      test('creates copy with changed title', () {
        final original = AppNotification(
          id: '1',
          userId: 'u1',
          type: 'info',
          title: 'Original',
          message: 'Test',
          createdAt: DateTime.now(),
        );

        final copy = original.copyWith(title: 'Updated');

        expect(copy.title, 'Updated');
        expect(original.title, 'Original');
      });
    });
  });
}
