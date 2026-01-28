import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'add_member_sheet.dart';
import '../../providers/roster_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/team.dart';
import '../../models/team_member.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshTeamData());
  }

  void _refreshTeamData() {
    Provider.of<RosterProvider>(
      context,
      listen: false,
    ).fetchTeamRosters(widget.teamId);
    Provider.of<TeamProvider>(
      context,
      listen: false,
    ).fetchTeamDetail(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final rosterProvider = Provider.of<RosterProvider>(context);
    final team = teamProvider.currentTeam;
    final members = teamProvider.currentTeamMembers;
    final rosters = rosterProvider.rosters;

    if (teamProvider.isLoading && team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (teamProvider.error != null && team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                teamProvider.error ?? 'Failed to load team',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  teamProvider.clearError();
                  Provider.of<RosterProvider>(
                    context,
                    listen: false,
                  ).fetchTeamRosters(widget.teamId);
                  teamProvider.fetchTeamDetail(widget.teamId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(team?.name ?? 'Team'),
        actions: [
          if (team?.canManageTeam ?? false)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                context
                    .push('/teams/${widget.teamId}/settings')
                    .then((_) => _refreshTeamData());
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            Provider.of<RosterProvider>(
              context,
              listen: false,
            ).fetchTeamRosters(widget.teamId),
            Provider.of<TeamProvider>(
              context,
              listen: false,
            ).fetchTeamDetail(widget.teamId),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Team info
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade900,
                  child: Text(
                    team?.name.isNotEmpty == true
                        ? team!.name.substring(0, 1)
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team?.name ?? 'Team',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${members.length} members',
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

            // Rosters section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rosters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (team?.canManageRosters ?? false)
                  TextButton(
                    onPressed: () {
                      context
                          .push('/teams/${widget.teamId}/rosters/new')
                          .then((_) => _refreshTeamData());
                    },
                    child: const Text('+ Create Roster'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (rosterProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (rosters.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rosters yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first roster to get started',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...rosters.map((roster) => _buildRosterCard(context, roster)),

            const SizedBox(height: 24),

            // Members
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Members',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (team?.canManageMembers ?? false)
                  TextButton(
                    onPressed: () async {
                      final name = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => const AddMemberSheet(),
                      );
                      if (name != null && context.mounted) {
                        final success = await teamProvider.addMember(
                          widget.teamId,
                          name,
                        );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added $name as placeholder'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('+ Add Member'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...members.map((member) => _buildMemberCard(context, member, team)),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterCard(BuildContext context, roster) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/rosters/${roster.id}').then((_) => _refreshTeamData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.calendar_today, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roster.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRecurrenceDisplay(roster.recurrencePattern),
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
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, TeamMember member, Team? team) {
    final isPlaceholder = member.isPlaceholder;
    final isInvited = member.isInvited;
    final isLead = member.isTeamLead;
    final canSendInvites = team?.canSendInvites ?? false;

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
          context
              .push('/teams/${widget.teamId}/members/${member.userId}')
              .then((_) => _refreshTeamData());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade900,
                child: Text(
                  member.userName.isNotEmpty
                      ? member.userName.substring(0, 1)
                      : '?',
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
                    Row(
                      children: [
                        Text(
                          member.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (statusIcon.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            statusIcon,
                            style: TextStyle(fontSize: 14, color: statusColor),
                          ),
                        ],
                      ],
                    ),
                    if (isLead)
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (isPlaceholder && !isInvited && canSendInvites)
                OutlinedButton(
                  onPressed: () {
                    context
                        .push('/teams/${widget.teamId}/invite/${member.userId}')
                        .then((_) => _refreshTeamData());
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Invite'),
                ),
              if (!isPlaceholder || isInvited) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _getRecurrenceDisplay(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return pattern;
    }
  }
}
