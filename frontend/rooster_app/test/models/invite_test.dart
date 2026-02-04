import 'package:flutter_test/flutter_test.dart';
import 'package:rooster_app/services/invite_service.dart';

void main() {
  group('Invite', () {
    group('fromJson', () {
      test('parses full invite json', () {
        final json = {
          'id': 'inv-1',
          'team_id': 'team-1',
          'user_id': 'user-1',
          'email': 'test@example.com',
          'status': 'pending',
          'token': 'abc123',
          'created_at': '2024-01-15T09:00:00Z',
          'expires_at': '2024-01-22T09:00:00Z',
          'accepted_at': null,
          'team': {'name': 'Media Team'},
          'user': {'name': 'John'},
        };

        final invite = Invite.fromJson(json);

        expect(invite.id, 'inv-1');
        expect(invite.teamId, 'team-1');
        expect(invite.userId, 'user-1');
        expect(invite.email, 'test@example.com');
        expect(invite.status, 'pending');
        expect(invite.token, 'abc123');
        expect(invite.teamName, 'Media Team');
        expect(invite.userName, 'John');
        expect(invite.acceptedAt, isNull);
      });

      test('defaults missing fields', () {
        final json = {'id': 'inv-1', 'team_id': 'team-1', 'user_id': 'user-1'};

        final invite = Invite.fromJson(json);

        expect(invite.email, '');
        expect(invite.status, 'pending');
        expect(invite.token, '');
        expect(invite.teamName, isNull);
        expect(invite.userName, isNull);
      });

      test('parses accepted invite', () {
        final json = {
          'id': 'inv-1',
          'team_id': 'team-1',
          'user_id': 'user-1',
          'status': 'accepted',
          'accepted_at': '2024-01-16T10:00:00Z',
        };

        final invite = Invite.fromJson(json);

        expect(invite.status, 'accepted');
        expect(invite.acceptedAt, isNotNull);
        expect(invite.isAccepted, true);
        expect(invite.isPending, false);
      });
    });

    group('status checks', () {
      test('isPending for pending invites', () {
        final invite = Invite(
          id: '1',
          teamId: 't1',
          userId: 'u1',
          email: 'a@b.com',
          status: 'pending',
          token: 'tok',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );
        expect(invite.isPending, true);
        expect(invite.isAccepted, false);
        expect(invite.isExpired, false);
      });

      test('isAccepted for accepted invites', () {
        final invite = Invite(
          id: '1',
          teamId: 't1',
          userId: 'u1',
          email: 'a@b.com',
          status: 'accepted',
          token: 'tok',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
          acceptedAt: DateTime.now(),
        );
        expect(invite.isAccepted, true);
        expect(invite.isPending, false);
      });

      test('isExpired for expired invites', () {
        final invite = Invite(
          id: '1',
          teamId: 't1',
          userId: 'u1',
          email: 'a@b.com',
          status: 'expired',
          token: 'tok',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          expiresAt: DateTime.now().subtract(const Duration(days: 7)),
        );
        expect(invite.isExpired, true);
      });

      test('isExpired when past expiry date even if status is pending', () {
        final invite = Invite(
          id: '1',
          teamId: 't1',
          userId: 'u1',
          email: 'a@b.com',
          status: 'pending',
          token: 'tok',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(invite.isExpired, true);
      });
    });
  });

  group('PendingInvite', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'inv-1',
        'team_id': 'team-1',
        'team_name': 'Worship Team',
        'email': 'test@example.com',
        'created_at': '2024-06-15T10:00:00Z',
      };

      final invite = PendingInvite.fromJson(json);

      expect(invite.id, 'inv-1');
      expect(invite.teamId, 'team-1');
      expect(invite.teamName, 'Worship Team');
      expect(invite.email, 'test@example.com');
      expect(invite.createdAt.year, 2024);
      expect(invite.createdAt.month, 6);
    });

    test('fromJson defaults missing team_name', () {
      final json = {
        'id': 'inv-1',
        'team_id': 'team-1',
        'email': 'test@example.com',
      };

      final invite = PendingInvite.fromJson(json);
      expect(invite.teamName, 'Unknown team');
    });

    test('fromJson defaults missing email', () {
      final json = {'id': 'inv-1', 'team_id': 'team-1', 'team_name': 'Test'};

      final invite = PendingInvite.fromJson(json);
      expect(invite.email, '');
    });
  });
}
