import 'package:flutter_test/flutter_test.dart';
import 'package:rooster_app/models/team.dart';
import 'package:rooster_app/models/team_member.dart';

void main() {
  group('Team', () {
    group('fromJson', () {
      test('parses full team json', () {
        final json = {
          'id': 'team-1',
          'name': 'Media Team',
          'organisation_id': 'org-1',
          'role': 'lead',
          'permissions': ['manage_team', 'manage_members'],
          'member_count': 5,
          'roster_count': 2,
          'created_at': '2024-01-01T00:00:00Z',
        };

        final team = Team.fromJson(json);

        expect(team.id, 'team-1');
        expect(team.name, 'Media Team');
        expect(team.organisationId, 'org-1');
        expect(team.role, 'lead');
        expect(team.permissions, ['manage_team', 'manage_members']);
        expect(team.memberCount, 5);
        expect(team.rosterCount, 2);
      });

      test('defaults member_count and roster_count to 0', () {
        final json = {
          'id': 'team-1',
          'name': 'Test',
          'organisation_id': 'org-1',
          'created_at': '2024-01-01T00:00:00Z',
        };

        final team = Team.fromJson(json);

        expect(team.memberCount, 0);
        expect(team.rosterCount, 0);
        expect(team.permissions, isEmpty);
      });

      test('parses optional health metrics', () {
        final json = {
          'id': 'team-1',
          'name': 'Test',
          'organisation_id': 'org-1',
          'created_at': '2024-01-01T00:00:00Z',
          'response_rate': 0.85,
          'coverage_rate': 0.92,
          'active_members': 4,
          'unfilled_slots': 2,
        };

        final team = Team.fromJson(json);

        expect(team.responseRate, 0.85);
        expect(team.coverageRate, 0.92);
        expect(team.activeMembers, 4);
        expect(team.unfilledSlots, 2);
      });
    });

    group('permissions', () {
      test('isTeamLead is true for lead role', () {
        final team = Team(
          id: '1',
          name: 'T',
          organisationId: 'o1',
          role: 'lead',
          createdAt: DateTime.now(),
        );
        expect(team.isTeamLead, true);
      });

      test('isTeamLead is true when has manage_team permission', () {
        final team = Team(
          id: '1',
          name: 'T',
          organisationId: 'o1',
          role: 'member',
          permissions: ['manage_team'],
          createdAt: DateTime.now(),
        );
        expect(team.isTeamLead, true);
      });

      test('isMember is true for member role', () {
        final team = Team(
          id: '1',
          name: 'T',
          organisationId: 'o1',
          role: 'member',
          createdAt: DateTime.now(),
        );
        expect(team.isMember, true);
      });

      test('canManageRosters checks permission', () {
        final team = Team(
          id: '1',
          name: 'T',
          organisationId: 'o1',
          permissions: ['manage_rosters'],
          createdAt: DateTime.now(),
        );
        expect(team.canManageRosters, true);
        expect(team.canManageMembers, false);
      });

      test('canSendInvites checks permission', () {
        final team = Team(
          id: '1',
          name: 'T',
          organisationId: 'o1',
          permissions: ['send_invites'],
          createdAt: DateTime.now(),
        );
        expect(team.canSendInvites, true);
        expect(team.canManageTeam, false);
      });
    });

    test('toJson round-trips correctly', () {
      final team = Team(
        id: 'team-1',
        name: 'Media Team',
        organisationId: 'org-1',
        role: 'lead',
        permissions: ['manage_team'],
        memberCount: 3,
        rosterCount: 1,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = team.toJson();
      final restored = Team.fromJson(json);

      expect(restored.id, team.id);
      expect(restored.name, team.name);
      expect(restored.permissions, team.permissions);
      expect(restored.memberCount, team.memberCount);
    });
  });

  group('TeamMember', () {
    group('fromJson', () {
      test('parses full member json', () {
        final json = {
          'user_id': 'user-1',
          'team_id': 'team-1',
          'role': 'lead',
          'permissions': ['manage_team', 'send_invites'],
          'user_name': 'John',
          'user_email': 'john@example.com',
          'is_placeholder': false,
          'is_invited': true,
        };

        final member = TeamMember.fromJson(json);

        expect(member.userId, 'user-1');
        expect(member.teamId, 'team-1');
        expect(member.role, 'lead');
        expect(member.userName, 'John');
        expect(member.userEmail, 'john@example.com');
        expect(member.isPlaceholder, false);
        expect(member.isInvited, true);
      });

      test('defaults optional fields', () {
        final json = {'user_id': 'user-1', 'team_id': 'team-1'};

        final member = TeamMember.fromJson(json);

        expect(member.role, 'member');
        expect(member.permissions, isEmpty);
        expect(member.userName, '');
        expect(member.userEmail, isNull);
        expect(member.isPlaceholder, false);
        expect(member.isInvited, false);
      });
    });

    group('permissions', () {
      test('isTeamLead from role', () {
        final member = TeamMember(
          userId: '1',
          teamId: 't1',
          role: 'lead',
          userName: 'John',
        );
        expect(member.isTeamLead, true);
      });

      test('isTeamLead from manage_team permission', () {
        final member = TeamMember(
          userId: '1',
          teamId: 't1',
          role: 'member',
          permissions: ['manage_team'],
          userName: 'John',
        );
        expect(member.isTeamLead, true);
      });

      test('isMember for regular members', () {
        final member = TeamMember(
          userId: '1',
          teamId: 't1',
          role: 'member',
          userName: 'John',
        );
        expect(member.isMember, true);
        expect(member.isTeamLead, false);
      });
    });

    group('copyWith', () {
      test('updates userEmail and isInvited', () {
        final original = TeamMember(
          userId: '1',
          teamId: 't1',
          role: 'member',
          userName: 'John',
          isInvited: false,
        );

        final updated = original.copyWith(
          userEmail: 'john@test.com',
          isInvited: true,
        );

        expect(updated.userEmail, 'john@test.com');
        expect(updated.isInvited, true);
        expect(updated.userName, 'John');
        expect(original.isInvited, false);
        expect(original.userEmail, isNull);
      });

      test('updates permissions', () {
        final original = TeamMember(
          userId: '1',
          teamId: 't1',
          role: 'member',
          userName: 'John',
          permissions: ['send_invites'],
        );

        final updated = original.copyWith(
          permissions: ['manage_team', 'manage_members'],
        );

        expect(updated.permissions, ['manage_team', 'manage_members']);
        expect(original.permissions, ['send_invites']);
      });
    });

    test('toMap produces expected format', () {
      final member = TeamMember(
        userId: 'u1',
        teamId: 't1',
        role: 'lead',
        userName: 'Jane',
        userEmail: 'jane@test.com',
        permissions: ['manage_team'],
        isPlaceholder: false,
        isInvited: true,
      );

      final map = member.toMap();

      expect(map['id'], 'u1');
      expect(map['name'], 'Jane');
      expect(map['email'], 'jane@test.com');
      expect(map['role'], 'Lead');
      expect(map['isPlaceholder'], false);
      expect(map['isInvited'], true);
    });

    test('toMap shows Member role for non-leads', () {
      final member = TeamMember(
        userId: 'u1',
        teamId: 't1',
        role: 'member',
        userName: 'Bob',
      );

      expect(member.toMap()['role'], 'Member');
    });
  });

  group('TeamPermission', () {
    test('all contains expected permissions', () {
      expect(TeamPermission.all, contains('manage_team'));
      expect(TeamPermission.all, contains('manage_members'));
      expect(TeamPermission.all, contains('send_invites'));
      expect(TeamPermission.all, contains('manage_rosters'));
      expect(TeamPermission.all, contains('assign_volunteers'));
      expect(TeamPermission.all, contains('view_responses'));
      expect(TeamPermission.all.length, 6);
    });
  });
}
