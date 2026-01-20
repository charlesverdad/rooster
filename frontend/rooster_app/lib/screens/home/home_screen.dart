import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assignment_provider.dart';
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
    await assignmentProvider.fetchMyAssignments();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    
    final isTeamLead = authProvider.user?.isTeamLead == true;
    final pendingAssignments = assignmentProvider.assignments.where((a) => a.status == 'pending').toList();
    final upcomingAssignments = assignmentProvider.assignments.where((a) => a.status == 'accepted').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
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
              const Text(
                'Action Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
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
            
            if (upcomingAssignments.isEmpty)
              const EmptyState(
                icon: Icons.check_circle_outline,
                message: 'No upcoming assignments',
                subtitle: 'You\'ll see your accepted assignments here',
              )
            else
              ...upcomingAssignments.take(5).map((assignment) => UpcomingAssignmentCard(
                assignment: assignment,
                onTap: () => _navigateToDetail(assignment),
              )),

            // Team Lead Section (if applicable)
            if (isTeamLead) ...[
              const SizedBox(height: 32),
              TeamLeadSection(
                onViewTeams: () {
                  // TODO: Navigate to teams
                },
              ),
            ],
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
          content: Text('✅ Assignment accepted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleDecline(assignment) async {
    // TODO: Show decline confirmation sheet
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
