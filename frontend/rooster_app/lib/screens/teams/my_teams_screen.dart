import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';
import '../../models/team.dart';
import '../../services/invite_service.dart';
import '../../utils/invite_utils.dart';

class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  List<PendingInvite> _pendingInvites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeamProvider>(context, listen: false).fetchMyTeams();
      _fetchPendingInvites();
    });
  }

  Future<void> _fetchPendingInvites() async {
    try {
      final invites = await InviteService.getMyPendingInvites();
      if (mounted) {
        setState(() {
          _pendingInvites = invites;
        });
      }
    } catch (e) {
      // Silently fail — pending invites are supplementary
    }
  }

  Future<void> _acceptInvite(PendingInvite invite) async {
    try {
      await InviteService.acceptInviteByTeam(invite.teamId);
      if (!mounted) return;

      // Refresh both lists
      Provider.of<TeamProvider>(context, listen: false).fetchMyTeams();
      _fetchPendingInvites();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Joined ${invite.teamName}!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _declineInvite(PendingInvite invite) async {
    // Just remove from local list — user can ignore the invite
    setState(() {
      _pendingInvites.removeWhere((i) => i.id == invite.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final teams = teamProvider.teams;

    return Scaffold(
      appBar: AppBar(title: const Text('My Teams')),
      floatingActionButton: teams.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCreateTeamDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
            )
          : null,
      body: teamProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : teamProvider.error != null && teamProvider.teams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    teamProvider.error ?? 'Failed to load teams',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      teamProvider.clearError();
                      teamProvider.fetchMyTeams();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await teamProvider.fetchMyTeams();
                await _fetchPendingInvites();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_pendingInvites.isNotEmpty) ...[
                    _buildPendingInvitesSection(),
                    const SizedBox(height: 16),
                  ],
                  if (teams.isEmpty && _pendingInvites.isEmpty)
                    _buildEmptyState()
                  else
                    ...teams.map((team) => _buildTeamCard(context, team)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showInviteLinkDialog,
                    icon: const Icon(Icons.link),
                    label: const Text('Have an invite link?'),
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.group_add,
              size: 64,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No teams yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a team to start rostering volunteers',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateTeamDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create your first team'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateTeamDialog() async {
    final nameController = TextEditingController();

    final teamName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            hintText: 'e.g., Media Team',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (teamName != null && mounted) {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final team = await teamProvider.createTeam(teamName);

      if (team != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${team.name} created!'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to the new team's detail page
        context.push('/teams/${team.id}').then((_) {
          if (mounted) {
            Provider.of<TeamProvider>(context, listen: false).fetchMyTeams();
          }
        });
      } else if (teamProvider.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${teamProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInviteLinkDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your invite link or token below',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Invite link or token',
                hintText: 'https://rooster.app/invite/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onSubmitted: (value) {
                final token = extractTokenFromInviteUrl(value);
                if (token != null) {
                  Navigator.of(context).pop();
                  _navigateToInvite(token);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final token = extractTokenFromInviteUrl(controller.text);
              if (token != null) {
                Navigator.of(context).pop();
                _navigateToInvite(token);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _navigateToInvite(String token) {
    context.push('/invite/$token');
  }

  Widget _buildPendingInvitesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Invitations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ..._pendingInvites.map((invite) => _buildPendingInviteCard(invite)),
      ],
    );
  }

  Widget _buildPendingInviteCard(PendingInvite invite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.mail_outline, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.teamName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You\'ve been invited to join this team',
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _declineInvite(invite),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _acceptInvite(invite),
                  child: const Text('Join Team'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, Team team) {
    final isLead = team.isTeamLead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final teamProvider = Provider.of<TeamProvider>(
            context,
            listen: false,
          );
          context.push('/teams/${team.id}').then((_) {
            if (mounted) teamProvider.fetchMyTeams();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: Text(
                      team.name.isNotEmpty ? team.name.substring(0, 1) : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${team.memberCount} ${team.memberCount == 1 ? 'member' : 'members'}',
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
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${team.rosterCount} rosters',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLead
                          ? Colors.grey.shade200
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLead ? 'Admin' : 'Member',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
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
