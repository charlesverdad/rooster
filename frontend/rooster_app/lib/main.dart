import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/assignment_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/team_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'screens/team_lead/team_lead_dashboard.dart';
import 'screens/availability/availability_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: MaterialApp(
        title: 'Rooster',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MainNavigation(isTeamLead: false),
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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();
    setState(() {
      _isInitialized = true;
    });
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
        print('🔍 DEBUG AuthWrapper: isAuthenticated=${authProvider.isAuthenticated}');
        print('🔍 DEBUG AuthWrapper: user=${authProvider.user?.name}');
        print('🔍 DEBUG AuthWrapper: roles=${authProvider.user?.roles}');
        
        if (authProvider.isAuthenticated) {
          return const MainNavigation();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isTeamLead = authProvider.user?.isTeamLead == true || 
                          authProvider.user?.isAdmin == true;
        
        print('🔍 DEBUG MainNavigation: isTeamLead=$isTeamLead');
        
        // Different screens based on role
        final List<Widget> screens = isTeamLead
            ? const [
                TeamLeadDashboard(),
                AvailabilityScreen(),
                NotificationsScreen(),
              ]
            : const [
                DashboardScreen(),
                AvailabilityScreen(),
                NotificationsScreen(),
              ];
        
        print('🔍 DEBUG MainNavigation: Showing ${isTeamLead ? "TeamLeadDashboard" : "DashboardScreen"}');

        return Scaffold(
          body: screens[_selectedIndex],
          bottomNavigationBar: Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.event_busy),
                    label: 'Availability',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      label: Text('${notificationProvider.unreadCount}'),
                      isLabelVisible: notificationProvider.unreadCount > 0,
                      child: const Icon(Icons.notifications),
                    ),
                    label: 'Notifications',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
