import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/accept_invite_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/availability/availability_screen.dart';
import '../screens/teams/my_teams_screen.dart';
import '../screens/teams/team_detail_screen.dart';
import '../screens/teams/team_settings_screen.dart';
import '../screens/teams/member_detail_screen.dart';
import '../screens/teams/send_invite_screen.dart';
import '../screens/roster/roster_detail_screen.dart';
import '../screens/roster/event_detail_screen.dart';
import '../screens/roster/create_roster_screen.dart';
import '../screens/assignments/assignment_detail_screen.dart';
import '../screens/organisations/org_settings_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.isAuthenticated;
      final isInitialized = authProvider.isInitialized;

      // Wait for auth initialization
      if (!isInitialized) return null;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation.startsWith('/invite/');

      // Not logged in and not on an auth route -> redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Logged in and on login/register -> redirect to home
      if (isLoggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            HomeScreen(focus: state.uri.queryParameters['focus']),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) =>
            AcceptInviteScreen(token: state.pathParameters['token']!),
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => const MyTeamsScreen(),
      ),
      GoRoute(
        path: '/teams/:teamId',
        builder: (context, state) =>
            TeamDetailScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/teams/:teamId/settings',
        builder: (context, state) =>
            TeamSettingsScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/teams/:teamId/members/:memberId',
        builder: (context, state) => MemberDetailScreen(
          teamId: state.pathParameters['teamId']!,
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/teams/:teamId/invite/:memberId',
        builder: (context, state) => SendInviteScreen(
          teamId: state.pathParameters['teamId']!,
          memberId: state.pathParameters['memberId']!,
        ),
      ),
      GoRoute(
        path: '/teams/:teamId/rosters/new',
        builder: (context, state) =>
            CreateRosterScreen(teamId: state.pathParameters['teamId']!),
      ),
      GoRoute(
        path: '/rosters/:rosterId',
        builder: (context, state) =>
            RosterDetailScreen(rosterId: state.pathParameters['rosterId']!),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) =>
            EventDetailScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/assignments/:assignmentId',
        builder: (context, state) => AssignmentDetailScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/availability',
        builder: (context, state) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/organisations/:orgId/settings',
        builder: (context, state) =>
            OrgSettingsScreen(orgId: state.pathParameters['orgId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
