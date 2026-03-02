import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        if (provider.loadingStats && provider.dashboardStats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.statsError != null && provider.dashboardStats == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error loading dashboard: ${provider.statsError}'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => provider.fetchDashboardStats(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final stats = provider.dashboardStats;
        if (stats == null) return const SizedBox.shrink();

        final users = stats['users'] as Map<String, dynamic>? ?? {};
        final orgs = stats['organisations'] as Map<String, dynamic>? ?? {};
        final teams = stats['teams'] as Map<String, dynamic>? ?? {};
        final assignments = stats['assignments'] as Map<String, dynamic>? ?? {};
        final authConfig = stats['auth_config'] as Map<String, dynamic>? ?? {};

        return RefreshIndicator(
          onRefresh: () => provider.fetchDashboardStats(),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Section 1: Key Metrics
              Text(
                'Key Metrics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricCard(
                    icon: Icons.people,
                    iconColor: Colors.blue,
                    value: '${users['total'] ?? 0}',
                    label: 'Total Users',
                    subtitle:
                        '+${users['created_last_30_days'] ?? 0} this month',
                  ),
                  _MetricCard(
                    icon: Icons.business,
                    iconColor: Colors.orange,
                    value: '${orgs['named'] ?? 0}',
                    label: 'Organisations',
                    subtitle: null,
                  ),
                  _MetricCard(
                    icon: Icons.groups,
                    iconColor: Colors.teal,
                    value: '${teams['total'] ?? 0}',
                    label: 'Teams',
                    subtitle: null,
                  ),
                  _MetricCard(
                    icon: Icons.assignment,
                    iconColor: Colors.purple,
                    value:
                        '${(assignments['pending'] as int? ?? 0) + (assignments['confirmed'] as int? ?? 0)}',
                    label: 'Active Assignments',
                    subtitle: '${assignments['pending'] ?? 0} pending response',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Section 2: Auth Status
              Text(
                'Auth Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AuthChip(
                    label: 'Email / Password',
                    active: authConfig['email_enabled'] == true,
                  ),
                  _AuthChip(
                    label: 'Google Sign-In',
                    active: authConfig['google_enabled'] == true,
                  ),
                  _AuthChip(
                    label: 'Email Delivery',
                    active: authConfig['email_configured'] == true,
                  ),
                  _AuthChip(
                    label: 'Push Notifications',
                    active: authConfig['push_configured'] == true,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Section 3: Organisation Overview
              Text(
                'Organisation Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildOrgList(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrgList(Map<String, dynamic> stats) {
    final orgList = stats['organisation_list'] as List<dynamic>? ?? [];
    if (orgList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No organisations yet.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < orgList.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _buildOrgRow(orgList[i] as Map<String, dynamic>),
          ],
        ],
      ),
    );
  }

  Widget _buildOrgRow(Map<String, dynamic> org) {
    final orgId = org['id']?.toString();
    return ListTile(
      title: Text(org['name'] as String? ?? 'Unnamed'),
      subtitle: Text(
        '${org['member_count'] ?? 0} members, ${org['team_count'] ?? 0} teams',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            org['created_at'] != null
                ? _formatDate(org['created_at'] as String)
                : '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (orgId != null) const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: orgId != null
          ? () => context.push('/organisations/$orgId/settings')
          : null,
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? subtitle;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withAlpha(30),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthChip extends StatelessWidget {
  final String label;
  final bool active;

  const _AuthChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        color: active ? Colors.green : Colors.grey,
        size: 18,
      ),
      label: Text(label),
      backgroundColor: active ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(
        color: active ? Colors.green.shade200 : Colors.grey.shade300,
      ),
    );
  }
}
