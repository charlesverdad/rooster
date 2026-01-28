import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'providers/assignment_provider.dart';
import 'providers/availability_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/team_provider.dart';
import 'providers/roster_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = createRouter(_authProvider);

    // Set up unauthorized callback -- logout triggers GoRouter redirect to /login
    ApiClient.setOnUnauthorized(() {
      _authProvider.logout();
    });

    // Initialize auth (load token, fetch user)
    _authProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => AvailabilityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => RosterProvider()),
      ],
      child: MaterialApp.router(
        title: 'Rooster',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF673AB7), // Deep Purple
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}
