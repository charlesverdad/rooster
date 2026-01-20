import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/assignment_action_card.dart';
import '../../widgets/upcoming_assignment_card.dart';
import '../../widgets/team_lead_section.dart';
import '../../widgets/empty_state.dart';
import '../assignments/assignment_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Defer data loading to after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await Future.wait([
      assignmentProvider.fetchMyAssignments(),
      notificationProvider.fetchNotifications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final isTeamLead = authProvider.user?.isTeamLead == true;
    final pendingAssignments = assignmentProvider.assignments.where((a) => a.status == 'pending').toList();
    final upcomingAssignments = assignmentProvider.assignments.where((a) => a.status == 'accepted').toList();
    final unreadCount = notificationProvider.unreadCount;

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
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
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
              Navigator.pushNamed(context, '/settings');
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    ...pendingAssignments.map((assignment) => AssignmentActionCard(
                      assignment: assignment,
                      onAccept: () => _handleAccept(assignment),
                      onDecline: () => _handleDecline(assignment),
                      onTap: () => _navigateToDetail(assignment),
                    )),
                    const SizedBox(height: 24),
                  ],

                  // Upcoming Assignments Section
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (upcomingAssignments.isEmpty && pendingAssignments.isEmpty)
                    _buildNoAssignmentsState()
                  else if (upcomingAssignments.isEmpty)
                    const EmptyState(
                      icon: Icons.event_available,
                      message: 'No upcoming assignments',
                      subtitle: 'Accept pending assignments to see them here',
                    )
                  else
                    ...upcomingAssignments.take(5).map((assignment) => UpcomingAssignmentCard(
                      assignment: assignment,
                      onTap: () => _navigateToDetail(assignment),
                    )),

                  // Team Lead Section (if applicable)
                  if (isTeamLead) ...[
                    const SizedBox(height: 32),
                    const TeamLeadSection(),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildNoAssignmentsState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.grey.shade300,
            ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(assignment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssignmentDetailScreen(assignment: assignment),
      ),
    );
  }

  Future<void> _handleAccept(assignment) async {
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final success = await assignmentProvider.updateAssignmentStatus(assignment.id, 'accepted');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment accepted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDecline(assignment) async {
    // Show decline confirmation sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => const _DeclineConfirmationSheet(),
    );

    if (confirmed == true && mounted) {
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
      final success = await assignmentProvider.updateAssignmentStatus(assignment.id, 'declined');

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
  State<_DeclineConfirmationSheet> createState() => _DeclineConfirmationSheetState();
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your team lead will be notified.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Reason (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
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
