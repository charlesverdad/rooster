import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';

class AssignVolunteersSheet extends StatefulWidget {
  final String teamId;
  final Function(String userId) onAssign;

  const AssignVolunteersSheet({
    super.key,
    required this.teamId,
    required this.onAssign,
  });

  @override
  State<AssignVolunteersSheet> createState() => _AssignVolunteersSheetState();
}

class _AssignVolunteersSheetState extends State<AssignVolunteersSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeamProvider>(context, listen: false)
          .fetchTeamDetail(widget.teamId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final members = teamProvider.currentTeamMembers;

    final filteredMembers = _searchQuery.isEmpty
        ? members
        : members
            .where((m) => (m['name'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    final available = filteredMembers
        .where((m) =>
            m['isPlaceholder'] == false && m['isInvited'] != true)
        .toList();
    final unavailable = filteredMembers.where((m) => false).toList(); // TODO: Add unavailability logic
    final placeholders = filteredMembers
        .where((m) => m['isPlaceholder'] == true)
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Assign Volunteer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Members list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (available.isNotEmpty) ...[
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...available.map((member) => _buildMemberTile(member, true)),
                  const SizedBox(height: 16),
                ],
                if (unavailable.isNotEmpty) ...[
                  Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unavailable
                      .map((member) => _buildMemberTile(member, false)),
                  const SizedBox(height: 16),
                ],
                if (placeholders.isNotEmpty) ...[
                  Text(
                    'Placeholders',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...placeholders
                      .map((member) => _buildMemberTile(member, true)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member, bool isAvailable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: Text(
            (member['name'] as String).substring(0, 1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(member['name'] as String),
            if (member['isPlaceholder'] == true) ...[
              const SizedBox(width: 8),
              Text(
                '○',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        subtitle: member['reason'] != null
            ? Text(
                member['reason'] as String,
                style: TextStyle(color: Colors.orange.shade700),
              )
            : null,
        trailing: isAvailable ? const Icon(Icons.chevron_right) : null,
        onTap: isAvailable
            ? () async {
                await widget.onAssign(member['id'] as String);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ ${member['name']} assigned'),
                    ),
                  );
                }
              }
            : null,
        enabled: isAvailable,
      ),
    );
  }
}
