import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'admin_dashboard.dart';
import 'admin_users.dart';
import 'admin_config.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 800) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/settings'),
          ),
          title: const Text('System Admin'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Please use a desktop browser for admin settings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return const _AdminShellDesktop();
  }
}

class _AdminShellDesktop extends StatefulWidget {
  const _AdminShellDesktop();

  @override
  State<_AdminShellDesktop> createState() => _AdminShellDesktopState();
}

class _AdminShellDesktopState extends State<_AdminShellDesktop>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text('System Admin'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Users'),
            Tab(icon: Icon(Icons.settings_outlined), text: 'Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [AdminDashboard(), AdminUsers(), AdminConfig()],
      ),
    );
  }
}
