import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/roster_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/roster_provider.dart';
import '../../providers/team_provider.dart';
import 'assign_volunteers_sheet.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final String teamId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.teamId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  RosterEvent? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rosterProvider =
          Provider.of<RosterProvider>(context, listen: false);
      final event = await rosterProvider.fetchEvent(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load event details';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final team = teamProvider.currentTeam;
    final canManage = team?.canAssignVolunteers ?? false;
    final currentUserId = authProvider.user?.id;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event Detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_error ?? 'Event not found',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadEvent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final assignments = event.assignments ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(event.rosterName ?? 'Event'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _showCancelConfirmation(context, event);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(
                        event.isCancelled ? Icons.undo : Icons.cancel,
                        color: event.isCancelled ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.isCancelled ? 'Restore Event' : 'Cancel Event',
                        style: TextStyle(
                          color:
                              event.isCancelled ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvent,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Event Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.deepPurple.shade400),
                        const SizedBox(width: 12),
                        Text(
                          dateFormat.format(event.date),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (event.rosterName != null) ...[
                      Row(
                        children: [
                          Icon(Icons.event_note,
                              size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Text('Roster: ${event.rosterName}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Icon(Icons.people,
                            size: 20, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        _buildSlotStatus(event),
                      ],
                    ),
                    if (event.isCancelled) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cancel,
                                size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'This event has been cancelled',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes,
                              size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(child: Text(event.notes!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Assignments Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assignments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (canManage && !event.isCancelled && !event.isFilled)
                  TextButton.icon(
                    onPressed: () => _showAssignSheet(context, event),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Assign'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (assignments.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No volunteers assigned yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
              )
            else
              ...assignments
                  .map((a) => _buildAssignmentCard(context, a, canManage)),

            if (!event.isCancelled && !event.isFilled) ...[
              const SizedBox(height: 16),
              if (canManage)
                OutlinedButton.icon(
                  onPressed: () => _showAssignSheet(context, event),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Assign Volunteer'),
                )
              else if (currentUserId != null &&
                  assignments.any((a) => a.userId == currentUserId))
                const Chip(
                  avatar: Icon(Icons.check, size: 16, color: Colors.green),
                  label: Text('Signed Up'),
                )
              else
                FilledButton.icon(
                  onPressed: () async {
                    if (currentUserId == null) return;
                    final rosterProvider =
                        Provider.of<RosterProvider>(context, listen: false);
                    final success = await rosterProvider.assignVolunteerToEvent(
                      event.id,
                      currentUserId,
                    );
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('You have volunteered for this event')),
                        );
                        await _loadEvent();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to volunteer'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.volunteer_activism),
                  label: const Text('Volunteer'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotStatus(RosterEvent event) {
    Color color;
    String text;

    if (event.isFilled) {
      color = Colors.green;
      text = '${event.filledSlots}/${event.slotsNeeded} filled';
    } else if (event.isPartial) {
      color = Colors.orange;
      text = '${event.filledSlots}/${event.slotsNeeded} filled';
    } else {
      color = Colors.red;
      text = '${event.filledSlots}/${event.slotsNeeded} filled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(
      BuildContext context, EventAssignmentSummary assignment, bool canManage) {
    Color statusColor;
    IconData statusIcon;

    switch (assignment.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assignment.isPlaceholder
              ? Colors.grey.shade400
              : Colors.deepPurple.shade300,
          child: assignment.isPlaceholder
              ? Icon(Icons.person_outline,
                  color: Colors.grey.shade100, size: 20)
              : Text(
                  assignment.userName.isNotEmpty
                      ? assignment.userName.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
        title: Row(
          children: [
            Text(assignment.userName),
            if (assignment.isPlaceholder) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  assignment.isInvited ? 'Invited' : 'Placeholder',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              assignment.status.substring(0, 1).toUpperCase() +
                  assignment.status.substring(1),
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: canManage
            ? IconButton(
                icon:
                    Icon(Icons.remove_circle_outline, color: Colors.red.shade300),
                onPressed: () =>
                    _showRemoveConfirmation(context, assignment),
              )
            : null,
      ),
    );
  }

  void _showAssignSheet(BuildContext context, RosterEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssignVolunteersSheet(
        teamId: widget.teamId,
        eventDate: event.date,
        onAssign: (userId) async {
          final rosterProvider =
              Provider.of<RosterProvider>(context, listen: false);
          await rosterProvider.assignVolunteerToEvent(event.id, userId);
          await _loadEvent();
        },
      ),
    );
  }

  void _showRemoveConfirmation(
      BuildContext context, EventAssignmentSummary assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: Text(
            'Remove ${assignment.userName} from this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final rosterProvider =
                  Provider.of<RosterProvider>(context, listen: false);
              final success =
                  await rosterProvider.removeAssignment(assignment.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${assignment.userName} removed')),
                  );
                  await _loadEvent();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to remove assignment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, RosterEvent event) {
    final isCancelled = event.isCancelled;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCancelled ? 'Restore Event' : 'Cancel Event'),
        content: Text(isCancelled
            ? 'Restore this event? Volunteers will need to be reassigned.'
            : 'Cancel this event? All assigned volunteers will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final rosterProvider =
                  Provider.of<RosterProvider>(context, listen: false);
              final success = await rosterProvider.cancelEvent(
                  event.id, !isCancelled);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isCancelled
                          ? 'Event restored'
                          : 'Event cancelled'),
                    ),
                  );
                  await _loadEvent();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update event'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: isCancelled
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isCancelled ? 'Restore' : 'Cancel Event'),
          ),
        ],
      ),
    );
  }
}
