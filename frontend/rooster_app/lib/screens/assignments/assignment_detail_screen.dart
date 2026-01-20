import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment.dart';
import '../../providers/assignment_provider.dart';
import '../../mock_data/mock_data.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Assignment assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  bool _showingActions = false;

  // Mock data for co-volunteers and team info
  List<Map<String, dynamic>> get _coVolunteers => [
    {
      'name': 'Sarah Johnson',
      'status': 'accepted',
      'isPlaceholder': false,
      'isInvited': false,
    },
    {
      'name': 'Tom Wilson',
      'status': 'pending',
      'isPlaceholder': true,
      'isInvited': true,
    },
  ];

  Map<String, dynamic> get _teamLead => {
    'name': 'Mike Chen',
    'email': 'mike@example.com',
    'phone': '(555) 123-4567',
  };

  String get _teamName {
    // Get team name from mock data based on roster
    final roster = MockData.getRosterById(widget.assignment.rosterId);
    if (roster != null) {
      final team = MockData.teams.firstWhere(
        (t) => t['id'] == roster.teamId,
        orElse: () => {'name': 'Team'},
      );
      return team['name'] as String;
    }
    return 'Media Team';
  }

  @override
  Widget build(BuildContext context) {
    // Get the current assignment from the provider (to react to status changes)
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final currentAssignment = assignmentProvider.assignments.firstWhere(
      (a) => a.id == widget.assignment.id,
      orElse: () => widget.assignment,
    );

    final isPending = currentAssignment.status == 'pending';
    final isAccepted = currentAssignment.status == 'accepted';
    final isDeclined = currentAssignment.status == 'declined';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Roster name
          Text(
            currentAssignment.rosterName ?? 'Assignment',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _teamName,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Date, Time, Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.calendar_today, _formatDate(currentAssignment.date)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.access_time, _formatTime(currentAssignment.date)),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on, 'Main Sanctuary'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          const Text(
            'Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Run slides and sound system for service',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Also Serving
          const Text(
            'Also Serving',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _coVolunteers.map((volunteer) =>
                  _buildCoVolunteerRow(volunteer)
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Team Lead
          const Text(
            'Team Lead',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple.shade300,
                    child: Text(
                      _teamLead['name'].toString().substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _teamLead['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Team Lead',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _showContactSheet(context),
                    child: const Text('Contact'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons (for pending or when changing response)
          if (isPending || _showingActions) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDecline(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _handleAccept(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],

          // Status indicator for accepted
          if (isAccepted && !_showingActions) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'ve accepted this assignment',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showingActions = true;
                  });
                },
                child: const Text('Change Response'),
              ),
            ),
          ],

          // Status indicator for declined
          if (isDeclined && !_showingActions) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'ve declined this assignment',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showingActions = true;
                  });
                },
                child: const Text('Change Response'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoVolunteerRow(Map<String, dynamic> volunteer) {
    final status = volunteer['status'] as String;
    final isPlaceholder = volunteer['isPlaceholder'] as bool;
    final isInvited = volunteer['isInvited'] as bool;

    // Determine status indicator
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isPlaceholder && !isInvited) {
      // Placeholder - not invited
      statusIcon = Icons.circle_outlined;
      statusColor = Colors.grey.shade500;
      statusText = 'Not invited';
    } else if (isPlaceholder && isInvited) {
      // Placeholder - invited
      statusIcon = Icons.mail_outline;
      statusColor = Colors.blue.shade600;
      statusText = 'Invited';
    } else if (status == 'accepted') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green.shade600;
      statusText = 'Accepted';
    } else if (status == 'declined') {
      statusIcon = Icons.cancel;
      statusColor = Colors.red.shade600;
      statusText = 'Declined';
    } else {
      // Pending
      statusIcon = Icons.schedule;
      statusColor = Colors.orange.shade600;
      statusText = 'Pending';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isPlaceholder ? Colors.grey.shade400 : Colors.deepPurple.shade200,
            child: isPlaceholder
                ? Icon(Icons.person_outline, color: Colors.grey.shade100, size: 18)
                : Text(
                    (volunteer['name'] as String).substring(0, 1),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volunteer['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ContactTeamLeadSheet(teamLead: _teamLead),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final endHour = (date.hour + 2) > 12 ? (date.hour + 2) - 12 : (date.hour + 2);
    final endPeriod = (date.hour + 2) >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period - $endHour:$minute $endPeriod';
  }

  Future<void> _handleAccept(BuildContext context) async {
    final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
    final success = await assignmentProvider.updateAssignmentStatus(widget.assignment.id, 'accepted');

    if (success && context.mounted) {
      setState(() {
        _showingActions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment accepted'),
          duration: Duration(seconds: 2),
        ),
      );
      // Only pop if this was a pending assignment, otherwise stay on the page
      if (widget.assignment.status == 'pending') {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDecline(BuildContext context) async {
    // Show decline confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => const DeclineConfirmationSheet(),
    );

    if (confirmed == true && context.mounted) {
      final assignmentProvider = Provider.of<AssignmentProvider>(context, listen: false);
      final success = await assignmentProvider.updateAssignmentStatus(widget.assignment.id, 'declined');

      if (success && context.mounted) {
        setState(() {
          _showingActions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Declined'),
            duration: Duration(seconds: 2),
          ),
        );
        // Only pop if this was a pending assignment, otherwise stay on the page
        if (widget.assignment.status == 'pending') {
          Navigator.of(context).pop();
        }
      }
    }
  }
}

class ContactTeamLeadSheet extends StatelessWidget {
  final Map<String, dynamic> teamLead;

  const ContactTeamLeadSheet({super.key, required this.teamLead});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.shade300,
                child: Text(
                  teamLead['name'].toString().substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamLead['name'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Team Lead',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.email, color: Colors.blue.shade700),
            ),
            title: const Text('Send Email'),
            subtitle: Text(teamLead['email'] as String),
            onTap: () async {
              final email = teamLead['email'] as String;
              final uri = Uri.parse('mailto:$email');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.phone, color: Colors.green.shade700),
            ),
            title: const Text('Call'),
            subtitle: Text(teamLead['phone'] as String),
            onTap: () async {
              final phone = (teamLead['phone'] as String).replaceAll(RegExp(r'[^\d+]'), '');
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Icon(Icons.message, color: Colors.purple.shade700),
            ),
            title: const Text('Send Message'),
            subtitle: Text(teamLead['phone'] as String),
            onTap: () async {
              final phone = (teamLead['phone'] as String).replaceAll(RegExp(r'[^\d+]'), '');
              final uri = Uri.parse('sms:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class DeclineConfirmationSheet extends StatefulWidget {
  const DeclineConfirmationSheet({super.key});

  @override
  State<DeclineConfirmationSheet> createState() => _DeclineConfirmationSheetState();
}

class _DeclineConfirmationSheetState extends State<DeclineConfirmationSheet> {
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
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Schedule conflict'),
            value: 'schedule_conflict',
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Other'),
            value: 'other',
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
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
