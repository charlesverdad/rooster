import 'package:flutter/material.dart';

class TeamDetailScreen extends StatelessWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    // Mock data - TODO: Replace with actual data from provider
    final team = {
      'name': 'Media Team',
      'icon': '📹',
      'memberCount': 12,
      'description': 'Run slides and sound for Sunday services',
    };

    final upcomingDates = [
      {
        'date': 'Sun, Jan 21',
        'rosterName': 'Sunday Service',
        'time': '9:00 AM',
        'filled': 2,
        'needed': 2,
      },
      {
        'date': 'Sun, Jan 28',
        'rosterName': 'Sunday Service',
        'time': '9:00 AM',
        'filled': 1,
        'needed': 2,
      },
    ];

    final members = [
      {'name': 'Mike Chen', 'role': 'Lead', 'isPlaceholder': false, 'isInvited': false},
      {'name': 'John Smith', 'role': 'Member', 'isPlaceholder': false, 'isInvited': false},
      {'name': 'Sarah Johnson', 'role': 'Member', 'isPlaceholder': false, 'isInvited': false},
      {'name': 'Emma Davis', 'role': 'Member', 'isPlaceholder': true, 'isInvited': false},
      {'name': 'Tom Wilson', 'role': 'Member', 'isPlaceholder': true, 'isInvited': true},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(team['name'] as String),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Team settings
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Team info
          Row(
            children: [
              Text(
                team['icon'] as String,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['name'] as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${team['memberCount']} members',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Upcoming roster dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Create roster
                },
                child: const Text('+ Create Roster'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...upcomingDates.map((date) => _buildRosterDateCard(context, date)),
          const SizedBox(height: 24),

          // Members
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Add member
                },
                child: const Text('+ Add Member'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...members.map((member) => _buildMemberCard(context, member)),
        ],
      ),
    );
  }

  Widget _buildRosterDateCard(BuildContext context, Map<String, dynamic> date) {
    final isFilled = date['filled'] == date['needed'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date['date'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${date['rosterName']} • ${date['time']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFilled ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${date['filled']}/${date['needed']} filled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isFilled ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (!isFilled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Assign volunteers
                  },
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Assign'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member) {
    final isPlaceholder = member['isPlaceholder'] as bool;
    final isInvited = member['isInvited'] as bool;
    final isLead = member['role'] == 'Lead';

    String statusIcon = '';
    Color? statusColor;
    
    if (isPlaceholder && !isInvited) {
      statusIcon = '○'; // Placeholder
      statusColor = Colors.grey.shade600;
    } else if (isInvited) {
      statusIcon = '✉️'; // Invited
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to member detail
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  (member['name'] as String).substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          member['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (statusIcon.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            statusIcon,
                            style: TextStyle(
                              fontSize: 14,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isLead)
                      Text(
                        'Team Lead',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.purple.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (isPlaceholder && !isInvited)
                OutlinedButton(
                  onPressed: () {
                    // TODO: Send invite
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Invite'),
                ),
              if (!isPlaceholder || isInvited)
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
