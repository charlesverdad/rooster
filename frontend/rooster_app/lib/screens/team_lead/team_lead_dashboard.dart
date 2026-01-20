import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';

class TeamLeadDashboard extends StatefulWidget {
  const TeamLeadDashboard({super.key});

  @override
  State<TeamLeadDashboard> createState() => _TeamLeadDashboardState();
}

class _TeamLeadDashboardState extends State<TeamLeadDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeamProvider>(context, listen: false).fetchMyTeams();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<TeamProvider>(context, listen: false).fetchMyTeams();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: teamProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Welcome back, ${authProvider.user?.name ?? 'Team Lead'}! 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Team Lead',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Alerts Section
                  if (_hasAlerts(teamProvider.teams)) ...[
                    _buildAlertsSection(teamProvider.teams),
                    const SizedBox(height: 24),
                  ],
                  
                  // Your Teams Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Teams',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Navigate to create roster
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Roster'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (teamProvider.teams.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.groups, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No teams yet',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...teamProvider.teams.map((team) => _buildTeamCard(team)),
                ],
              ),
      ),
    );
  }

  bool _hasAlerts(List teams) {
    return teams.any((team) => (team.unfilledSlots ?? 0) > 0);
  }

  Widget _buildAlertsSection(List teams) {
    final teamsWithAlerts = teams.where((team) => (team.unfilledSlots ?? 0) > 0).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Needs Attention (${teamsWithAlerts.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.orange.shade700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...teamsWithAlerts.map((team) => _buildAlertCard(team)),
      ],
    );
  }

  Widget _buildAlertCard(team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${team.unfilledSlots} unfilled slots',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (team.nextRoster != null) ...[
              const SizedBox(height: 4),
              Text(
                'Next: ${DateFormat('EEE, MMM d').format(team.nextRoster!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to assign volunteers
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Assign Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(team) {
    final dateFormat = DateFormat('EEE, MMM d');
    final hasUnfilledSlots = (team.unfilledSlots ?? 0) > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to team detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.groups,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${team.memberCount} members • ${team.rosterCount} rosters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasUnfilledSlots)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${team.unfilledSlots}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (team.nextRoster != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: ${dateFormat.format(team.nextRoster!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (!hasUnfilledSlots)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'All filled',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Needs volunteers',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
