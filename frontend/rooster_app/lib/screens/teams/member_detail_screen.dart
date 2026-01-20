import 'package:flutter/material.dart';

class MemberDetailScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = member['isPlaceholder'] as bool;
    final isInvited = member['isInvited'] as bool;
    final isLead = member['role'] == 'Lead';

    return Scaffold(
      appBar: AppBar(
        title: Text(member['name'] as String),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    (member['name'] as String).substring(0, 1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  member['name'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (isLead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Team Lead',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                if (isPlaceholder && !isInvited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('○ '),
                        Text(
                          'Not invited yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isInvited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✉️ '),
                        Text(
                          'Invite sent',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Contact section (only if not placeholder)
          if (!isPlaceholder) ...[
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(member['email'] ?? 'john@example.com'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open email
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Phone'),
                    subtitle: Text(member['phone'] ?? '(555) 123-4567'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open phone
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Teams section
          const Text(
            'Teams',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Text('📹', style: TextStyle(fontSize: 24)),
              title: const Text('Media Team'),
              subtitle: Text(isLead ? 'Team Lead' : 'Member'),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          if (isPlaceholder && !isInvited)
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/send-invite', arguments: member);
              },
              icon: const Icon(Icons.email),
              label: const Text('Send Invite'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
        ],
      ),
    );
  }
}
