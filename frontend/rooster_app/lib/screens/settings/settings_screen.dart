import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/push_service.dart';
import '../../widgets/back_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _notificationsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    if (!kIsWeb) return;
    final subscribed = await PushService.isSubscribed();
    if (mounted) {
      setState(() => _notificationsEnabled = subscribed);
    }
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    setState(() => _notificationsLoading = true);

    try {
      bool success;
      if (value) {
        success = await PushService.requestPermissionAndSubscribe();
      } else {
        success = await PushService.unsubscribe();
      }

      if (mounted) {
        if (success) {
          setState(() => _notificationsEnabled = value);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value ? 'Notifications enabled' : 'Notifications disabled',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        } else if (value && PushService.getPermissionStatus() == 'denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notifications blocked. Enable in browser settings.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not update notification settings.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _notificationsLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade600,
                  child: const Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Notifications
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: _notificationsLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: _notificationsEnabled,
                    onChanged: _setNotificationsEnabled,
                  ),
          ),

          // My Availability
          ListTile(
            leading: const Icon(Icons.event_busy),
            title: const Text('My Availability'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/availability');
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authProvider.logout();
              // GoRouter redirect handles navigation to /login
            },
          ),

          const SizedBox(height: 16),

          // Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
