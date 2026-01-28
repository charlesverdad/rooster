import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/team_member.dart';
import '../../providers/team_provider.dart';

class TeamSettingsScreen extends StatefulWidget {
  final String teamId;

  const TeamSettingsScreen({super.key, required this.teamId});

  @override
  State<TeamSettingsScreen> createState() => _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends State<TeamSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeamProvider>(
        context,
        listen: false,
      ).fetchTeamDetail(widget.teamId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final team = teamProvider.currentTeam;
    final members = teamProvider.currentTeamMembers;

    if (team == null && teamProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Team Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Team Name
          const Text(
            'Team Name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(team?.name ?? 'Team'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showEditNameDialog(context, team?.name ?? ''),
            ),
          ),
          const SizedBox(height: 24),

          // Member Permissions
          if (team?.canManageTeam ?? false) ...[
            const Text(
              'Member Permissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage what each member can do',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            ...members
                .where((m) => !m.isTeamLead)
                .map((m) => _buildMemberPermissionCard(context, m)),
            const SizedBox(height: 24),
          ],

          // Danger Zone
          if (team?.canManageTeam ?? false) ...[
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
                title: Text(
                  'Delete Team',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                subtitle: const Text(
                  'Permanently delete this team and all its data',
                ),
                onTap: () => _showDeleteConfirmation(context, team?.name ?? ''),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberPermissionCard(BuildContext context, TeamMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: member.isPlaceholder
              ? Colors.grey.shade400
              : Colors.grey.shade600,
          radius: 18,
          child: Text(
            member.userName.isNotEmpty ? member.userName.substring(0, 1) : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(member.userName),
        subtitle: Text(
          '${member.permissions.length} permissions',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          _buildPermissionToggle(
            member,
            TeamPermission.manageMembers,
            'Manage Members',
            'Add and remove team members',
          ),
          _buildPermissionToggle(
            member,
            TeamPermission.sendInvites,
            'Send Invites',
            'Send invites to placeholder members',
          ),
          _buildPermissionToggle(
            member,
            TeamPermission.manageRosters,
            'Manage Rosters',
            'Create, edit, and delete rosters',
          ),
          _buildPermissionToggle(
            member,
            TeamPermission.assignVolunteers,
            'Assign Volunteers',
            'Assign volunteers to events',
          ),
          _buildPermissionToggle(
            member,
            TeamPermission.viewResponses,
            'View Responses',
            'See member availability and responses',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle(
    TeamMember member,
    String permission,
    String label,
    String description,
  ) {
    final hasPermission = member.hasPermission(permission);

    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        description,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      value: hasPermission,
      onChanged: (value) async {
        final teamProvider = Provider.of<TeamProvider>(context, listen: false);
        final newPermissions = List<String>.from(member.permissions);
        if (value) {
          newPermissions.add(permission);
        } else {
          newPermissions.remove(permission);
        }
        await teamProvider.updateMemberPermissions(
          widget.teamId,
          member.userId,
          newPermissions,
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Team Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              Navigator.of(dialogContext).pop();
              final teamProvider = Provider.of<TeamProvider>(
                context,
                listen: false,
              );
              final success = await teamProvider.updateTeam(
                widget.teamId,
                name: name,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Team name updated' : 'Failed to update',
                  ),
                  backgroundColor: success ? null : Colors.red,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String teamName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text(
          'Are you sure you want to delete "$teamName"? This will remove all members, rosters, events, and assignments. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final teamProvider = Provider.of<TeamProvider>(
                context,
                listen: false,
              );
              final success = await teamProvider.deleteTeam(widget.teamId);
              if (!context.mounted) return;
              if (success) {
                // Go back to home
                context.go('/');
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Team deleted')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to delete: ${teamProvider.error ?? "Unknown error"}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
