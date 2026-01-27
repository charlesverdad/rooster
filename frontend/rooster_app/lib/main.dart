import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'providers/assignment_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/team_provider.dart';
import 'providers/roster_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/accept_invite_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/availability/availability_screen.dart';
import 'screens/teams/team_detail_screen.dart';
import 'screens/teams/send_invite_screen.dart';
import 'screens/roster/roster_detail_screen.dart';
import 'screens/roster/event_detail_screen.dart';
import 'screens/teams/team_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Global navigator key for handling unauthorized redirects
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up unauthorized callback to redirect to login
    ApiClient.setOnUnauthorized(() {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => RosterProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Rooster',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF673AB7), // Deep Purple
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/availability': (context) => const AvailabilityScreen(),
        },
        onGenerateRoute: (settings) {
          // Handle routes with parameters
          if (settings.name == '/team-detail') {
            final teamId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => TeamDetailScreen(teamId: teamId),
            );
          }
          if (settings.name == '/send-invite') {
            final member = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => SendInviteScreen(member: member),
            );
          }
          if (settings.name == '/roster-detail') {
            final rosterId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => RosterDetailScreen(rosterId: rosterId),
            );
          }
          if (settings.name == '/event-detail') {
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                eventId: args['eventId']!,
                teamId: args['teamId']!,
              ),
            );
          }
          if (settings.name == '/team-settings') {
            final teamId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => TeamSettingsScreen(teamId: teamId),
            );
          }
          // Handle invite deep links: /invite/:token
          if (settings.name != null && settings.name!.startsWith('/invite/')) {
            final token = settings.name!.substring('/invite/'.length);
            return MaterialPageRoute(
              builder: (context) => AcceptInviteScreen(token: token),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  late AppLinks _appLinks;
  String? _pendingDeepLink;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();

    // Check for initial deep link (app opened via link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _pendingDeepLink = _parseDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for deep links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      final path = _parseDeepLink(uri);
      if (path != null && mounted) {
        Navigator.of(context).pushNamed(path);
      }
    });

    setState(() {
      _isInitialized = true;
    });

    // Navigate to pending deep link after initialization
    if (_pendingDeepLink != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamed(_pendingDeepLink!);
      });
    }
  }

  String? _parseDeepLink(Uri uri) {
    // Handle rooster://invite/TOKEN or https://rooster.app/invite/TOKEN
    if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'invite') {
      if (uri.pathSegments.length > 1) {
        return '/invite/${uri.pathSegments[1]}';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
