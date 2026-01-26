import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/team_provider.dart';
import '../../models/event_assignment.dart';
import '../../services/assignment_service.dart';

class MemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  List<EventAssignment> _assignments = [];
  bool _isLoadingAssignments = true;
  String? _assignmentError;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final team = teamProvider.currentTeam;
    final memberId = widget.member['id'] as String?;

    if (team == null ||
        memberId == null ||
        !(team.canViewResponses || team.canManageMembers || team.canManageTeam)) {
      setState(() => _isLoadingAssignments = false);
      return;
    }

    try {
      final assignments =
          await AssignmentService.getTeamMemberAssignments(team.id, memberId);
      if (mounted) {
        setState(() {
          _assignments = assignments;
          _isLoadingAssignments = false;
          _assignmentError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAssignments = false;
          _assignmentError = 'Unable to load assignments.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = widget.member['isPlaceholder'] as bool? ?? false;
    final isInvited = widget.member['isInvited'] as bool? ?? false;
    final isLead = widget.member['role'] == 'Lead';
    final name = widget.member['name'] as String? ?? 'Unknown';
    final email = widget.member['email'] as String?;

    // Get team info from provider
    final teamProvider = Provider.of<TeamProvider>(context);
    final team = teamProvider.currentTeam;
    final teamName = team?.name ?? 'Team';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
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
                  backgroundColor: isPlaceholder
                      ? Colors.grey.shade400
                      : Colors.deepPurple.shade300,
                  child: isPlaceholder
                      ? Icon(Icons.person_outline,
                          color: Colors.grey.shade100, size: 40)
                      : Text(
                          name.isNotEmpty ? name.substring(0, 1) : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (isLead)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail_outline,
                            size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 4),
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
          if (!isPlaceholder && email != null) ...[
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final uri = Uri.parse('mailto:$email');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
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
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                child: Icon(Icons.group, color: Colors.deepPurple.shade700),
              ),
              title: Text(teamName),
              subtitle: Text(isLead ? 'Team Lead' : 'Member'),
            ),
          ),
          const SizedBox(height: 24),

          // Upcoming Assignments section
          const Text(
            'Upcoming Assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingAssignments)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_assignments.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _assignmentError ??
                    (isPlaceholder
                        ? 'Assignments will appear once invited'
                        : 'No upcoming assignments'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            ..._assignments.take(5).map((a) => _buildAssignmentTile(a)),

          if (_assignments.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${_assignments.length - 5} more assignments',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 32),

          // Actions
          if (isPlaceholder && !isInvited)
            FilledButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/send-invite',
                    arguments: widget.member);
              },
              icon: const Icon(Icons.email),
              label: Text(_assignments.isEmpty
                  ? 'Send Invite'
                  : 'Send Invite (${_assignments.length} assignments pending)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentTile(EventAssignment assignment) {
    final dateFormat = DateFormat('EEE, MMM d');
    final dateStr = assignment.eventDate != null
        ? dateFormat.format(assignment.eventDate!)
        : 'TBD';

    Color statusColor;
    IconData statusIcon;

    if (assignment.isConfirmed) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (assignment.isDeclined) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(assignment.rosterName ?? 'Assignment'),
        subtitle: Text(dateStr),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            assignment.status,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
