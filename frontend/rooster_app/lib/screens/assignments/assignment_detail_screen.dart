import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/event_assignment.dart';
import '../../providers/assignment_provider.dart';
import '../../widgets/back_button.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  bool _showingActions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssignmentProvider>(
        context,
        listen: false,
      ).fetchAssignmentDetail(widget.assignmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentProvider = Provider.of<AssignmentProvider>(context);
    final detail = assignmentProvider.currentAssignmentDetail;

    if (assignmentProvider.isLoadingDetail || detail == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: const Text('Assignment'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPending = detail.isPending;
    final isConfirmed = detail.isConfirmed;
    final isDeclined = detail.isDeclined;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Assignment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Roster name
          Text(
            detail.rosterName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => context.push('/teams/${detail.teamId}'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detail.teamName,
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date, Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.calendar_today,
                    _formatDate(detail.eventDate),
                  ),
                  if (detail.location != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.location_on, detail.location!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          if (detail.notes != null && detail.notes!.isNotEmpty) ...[
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  detail.notes!,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Also Serving
          if (detail.coVolunteers.isNotEmpty) ...[
            const Text(
              'Also Serving',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: detail.coVolunteers
                      .map((volunteer) => _buildCoVolunteerRow(volunteer))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Team Lead
          if (detail.teamLead != null) ...[
            const Text(
              'Admin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey.shade600,
                      child: Text(
                        detail.teamLead!.name.isNotEmpty
                            ? detail.teamLead!.name.substring(0, 1)
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
                          Text(
                            detail.teamLead!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (detail.teamLead!.email != null ||
                        detail.teamLead!.phone != null)
                      FilledButton.tonal(
                        onPressed: () =>
                            _showContactSheet(context, detail.teamLead!),
                        child: const Text('Contact'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Action buttons (for pending or when changing response)
          if (isPending || _showingActions) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleDecline(context, detail.id),
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
                    onPressed: () => _handleAccept(context, detail.id),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],

          // Status indicator for confirmed
          if (isConfirmed && !_showingActions) ...[
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

  Widget _buildCoVolunteerRow(CoVolunteer volunteer) {
    final status = volunteer.status;
    final isPlaceholder = volunteer.isPlaceholder;
    final isInvited = volunteer.isInvited;

    // Determine status indicator
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isPlaceholder && !isInvited) {
      statusIcon = Icons.circle_outlined;
      statusColor = Colors.grey.shade500;
      statusText = 'Not invited';
    } else if (isPlaceholder && isInvited) {
      statusIcon = Icons.mail_outline;
      statusColor = Colors.blue.shade600;
      statusText = 'Invited';
    } else if (status == 'confirmed') {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green.shade600;
      statusText = 'Confirmed';
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
            backgroundColor: isPlaceholder
                ? Colors.grey.shade400
                : Colors.grey.shade600,
            child: isPlaceholder
                ? Icon(
                    Icons.person_outline,
                    color: Colors.grey.shade100,
                    size: 18,
                  )
                : Text(
                    volunteer.name.isNotEmpty
                        ? volunteer.name.substring(0, 1)
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  volunteer.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 13, color: statusColor),
                ),
              ],
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 20),
        ],
      ),
    );
  }

  void _showContactSheet(BuildContext context, TeamLead teamLead) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ContactTeamLeadSheet(teamLead: teamLead),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _handleAccept(BuildContext context, String assignmentId) async {
    final assignmentProvider = Provider.of<AssignmentProvider>(
      context,
      listen: false,
    );
    final success = await assignmentProvider.confirmAssignment(assignmentId);

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
    }
  }

  Future<void> _handleDecline(BuildContext context, String assignmentId) async {
    // Show decline confirmation bottom sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => const DeclineConfirmationSheet(),
    );

    if (confirmed == true && context.mounted) {
      final assignmentProvider = Provider.of<AssignmentProvider>(
        context,
        listen: false,
      );
      final success = await assignmentProvider.declineAssignment(assignmentId);

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
      }
    }
  }
}

class ContactTeamLeadSheet extends StatelessWidget {
  final TeamLead teamLead;

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
                backgroundColor: Colors.grey.shade600,
                child: Text(
                  teamLead.name.isNotEmpty
                      ? teamLead.name.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamLead.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (teamLead.email != null)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(Icons.email, color: Colors.blue.shade700),
              ),
              title: const Text('Send Email'),
              subtitle: Text(teamLead.email!),
              onTap: () async {
                final uri = Uri.parse('mailto:${teamLead.email}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          if (teamLead.phone != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.phone, color: Colors.green.shade700),
              ),
              title: const Text('Call'),
              subtitle: Text(teamLead.phone!),
              onTap: () async {
                final phone = teamLead.phone!.replaceAll(RegExp(r'[^\d+]'), '');
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: Icon(Icons.message, color: Colors.grey.shade700),
              ),
              title: const Text('Send Message'),
              subtitle: Text(teamLead.phone!),
              onTap: () async {
                final phone = teamLead.phone!.replaceAll(RegExp(r'[^\d+]'), '');
                final uri = Uri.parse('sms:$phone');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class DeclineConfirmationSheet extends StatefulWidget {
  const DeclineConfirmationSheet({super.key});

  @override
  State<DeclineConfirmationSheet> createState() =>
      _DeclineConfirmationSheetState();
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Your admin will be notified.',
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
