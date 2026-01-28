import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/event_assignment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/team_provider.dart';
import '../../utils/invite_utils.dart';
import '../../widgets/assignment_action_card.dart';
import '../../widgets/upcoming_assignment_card.dart';
import '../../widgets/team_lead_section.dart';
import '../../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final assignmentProvider = Provider.of<AssignmentProvider>(
      context,
      listen: false,
    );
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    await Future.wait([
      assignmentProvider.fetchMyAssignments(),
      notificationProvider.fetchNotifications(),
      teamProvider.fetchMyTeams(),
    ]);
    if (mounted) {
      setState(() => _refreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);

    final isTeamLead = authProvider.user?.isTeamLead == true;
    final pendingAssignments = assignmentProvider.pendingAssignments;
    final upcomingAssignments = assignmentProvider.upcomingAssignments;
    final unreadCount = notificationProvider.unreadCount;
    final hasTeams = teamProvider.teams.isNotEmpty;
    final hasNoContent =
        pendingAssignments.isEmpty && upcomingAssignments.isEmpty && !hasTeams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooster'),
        actions: [
          // Notification bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  context.push('/notifications').then((_) => _loadData());
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: assignmentProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Greeting
                  Text(
                    'Hi ${authProvider.user?.name ?? 'there'}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.push('/teams').then((_) => _loadData());
                        },
                        icon: const Icon(Icons.group_outlined, size: 18),
                        label: const Text('My Teams'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pending Assignments Section
                  if (pendingAssignments.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text(
                          'Action Required',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pendingAssignments.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pendingAssignments.map(
                      (assignment) => AssignmentActionCard(
                        assignment: assignment,
                        onAccept: () => _handleAccept(assignment),
                        onDecline: () => _handleDecline(assignment),
                        onTap: () => _navigateToDetail(assignment),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Upcoming Assignments Section
                  const Text(
                    'Upcoming',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  if (hasNoContent)
                    _buildCreateFirstTeamState()
                  else if (upcomingAssignments.isEmpty &&
                      pendingAssignments.isEmpty)
                    _buildNoAssignmentsState()
                  else if (upcomingAssignments.isEmpty)
                    const EmptyState(
                      icon: Icons.event_available,
                      message: 'No upcoming assignments',
                      subtitle: 'Accept pending assignments to see them here',
                    )
                  else
                    ...upcomingAssignments
                        .take(5)
                        .map(
                          (assignment) => UpcomingAssignmentCard(
                            assignment: assignment,
                            onTap: () => _navigateToDetail(assignment),
                          ),
                        ),

                  // Team Lead Section (if applicable)
                  if (isTeamLead) ...[
                    const SizedBox(height: 32),
                    TeamLeadSection(key: ValueKey(_refreshKey)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildCreateFirstTeamState() {
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
              'Welcome to Rooster!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first team to start rostering volunteers',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _showCreateTeamDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create your first team'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _showInviteLinkDialog,
              icon: const Icon(Icons.link),
              label: const Text('Have an invite link?'),
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
        context.push('/teams/${team.id}').then((_) => _loadData());
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
                  this.context.push('/invite/$token');
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
                this.context.push('/invite/$token');
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAssignmentsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No assignments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you\'re assigned to serve, you\'ll see it here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(EventAssignment assignment) {
    context.push('/assignments/${assignment.id}').then((_) => _loadData());
  }

  Future<void> _handleAccept(EventAssignment assignment) async {
    final assignmentProvider = Provider.of<AssignmentProvider>(
      context,
      listen: false,
    );
    final success = await assignmentProvider.confirmAssignment(assignment.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment accepted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDecline(EventAssignment assignment) async {
    // Show decline confirmation sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => const _DeclineConfirmationSheet(),
    );

    if (confirmed == true && mounted) {
      final assignmentProvider = Provider.of<AssignmentProvider>(
        context,
        listen: false,
      );
      final success = await assignmentProvider.declineAssignment(assignment.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Declined'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _DeclineConfirmationSheet extends StatefulWidget {
  const _DeclineConfirmationSheet();

  @override
  State<_DeclineConfirmationSheet> createState() =>
      _DeclineConfirmationSheetState();
}

class _DeclineConfirmationSheetState extends State<_DeclineConfirmationSheet> {
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Decline this assignment?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Your team lead will be notified.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          const Text(
            'Reason (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          RadioListTile<String>(
            title: const Text('Can\'t make it'),
            value: 'cant_make_it',
            groupValue: _selectedReason,
            onChanged: (value) => setState(() => _selectedReason = value),
          ),
          RadioListTile<String>(
            title: const Text('Schedule conflict'),
            value: 'schedule_conflict',
            groupValue: _selectedReason,
            onChanged: (value) => setState(() => _selectedReason = value),
          ),
          RadioListTile<String>(
            title: const Text('Other'),
            value: 'other',
            groupValue: _selectedReason,
            onChanged: (value) => setState(() => _selectedReason = value),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Confirm Decline'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
