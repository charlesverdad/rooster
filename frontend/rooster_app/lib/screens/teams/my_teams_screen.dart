import 'package:flutter/material.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - TODO: Replace with actual data from provider
    final teams = [
      {
        'id': '1',
        'name': 'Media Team',
        'icon': '📹',
        'memberCount': 12,
        'nextDate': 'Sun, Jan 21',
        'role': 'Member',
      },
      {
        'id': '2',
        'name': 'Worship Team',
        'icon': '🎵',
        'memberCount': 8,
        'nextDate': 'Sun, Jan 21',
        'role': 'Lead',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...teams.map((team) => _buildTeamCard(context, team)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Browse teams
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse All Teams'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Map<String, dynamic> team) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/team-detail',
            arguments: team['id'],
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    team['icon'],
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${team['memberCount']} members',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Next: ${team['nextDate']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: team['role'] == 'Lead' 
                          ? Colors.purple.shade50 
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      team['role'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: team['role'] == 'Lead'
                            ? Colors.purple.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
