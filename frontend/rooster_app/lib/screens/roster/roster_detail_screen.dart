import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/roster_provider.dart';
import '../roster/assign_volunteers_sheet.dart';
import 'event_detail_screen.dart';

class RosterDetailScreen extends StatefulWidget {
  final String rosterId;

  const RosterDetailScreen({super.key, required this.rosterId});

  @override
  State<RosterDetailScreen> createState() => _RosterDetailScreenState();
}

class _RosterDetailScreenState extends State<RosterDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RosterProvider>(context, listen: false)
          .fetchRosterDetail(widget.rosterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rosterProvider = Provider.of<RosterProvider>(context);
    final roster = rosterProvider.currentRoster;
    final events = rosterProvider.currentEvents;

    if (rosterProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roster Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (rosterProvider.error != null || roster == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roster Detail')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                rosterProvider.error ?? 'Roster not found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  rosterProvider.clearError();
                  rosterProvider.fetchRosterDetail(widget.rosterId);
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
        title: Text(roster.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, roster),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context, roster.name);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Roster', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Roster Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roster.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.repeat,
                    _getRecurrenceDisplay(roster.recurrencePattern),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    _getDayDisplay(roster.recurrenceDay),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.people,
                    '${roster.slotsNeeded} volunteers needed',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Events Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generated Events',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${events.length} events',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Events List
          ...events.map((event) => _buildEventCard(context, event, roster.teamId)),

          const SizedBox(height: 16),

          // Generate More Button
          OutlinedButton.icon(
            onPressed: () async {
              await rosterProvider.generateMoreEvents();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Generated 7 more events')),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Generate More Events'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, event, String teamId) {
    final dateFormat = DateFormat('EEE, MMM d, y');
    final isFilled = event.isFilled;
    final isPartial = event.isPartial;

    Color statusColor;
    IconData statusIcon;

    if (isFilled) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isPartial) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                eventId: event.id,
                teamId: teamId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(event.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${event.filledSlots}/${event.slotsNeeded}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (event.assignedUserNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: event.assignedUserNames
                      .map<Widget>((name) => Chip(
                            label: Text(name),
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
              ],
              if (!isFilled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => AssignVolunteersSheet(
                          teamId: teamId,
                          eventDate: event.date,
                          onAssign: (userId) async {
                            final rosterProvider =
                                Provider.of<RosterProvider>(context,
                                    listen: false);
                            await rosterProvider.assignVolunteerToEvent(
                              event.id,
                              userId,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign Volunteer'),
                  ),
                ),
              ],
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

  String _getDayDisplay(int? day) {
    if (day == null) return 'Not set';
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[day % 7];
  }

  void _showEditDialog(BuildContext context, roster) {
    final nameController = TextEditingController(text: roster.name);
    int slotsNeeded = roster.slotsNeeded;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Roster'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Roster Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Volunteers needed: '),
                  const Spacer(),
                  IconButton(
                    onPressed: slotsNeeded > 1
                        ? () => setState(() => slotsNeeded--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$slotsNeeded',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: slotsNeeded < 10
                        ? () => setState(() => slotsNeeded++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final rosterProvider =
                    Provider.of<RosterProvider>(context, listen: false);
                final success = await rosterProvider.updateRoster(
                  name: nameController.text.trim(),
                  slotsNeeded: slotsNeeded,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Roster updated')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to update: ${rosterProvider.error ?? "Unknown error"}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String rosterName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Roster'),
        content: Text(
          'Are you sure you want to delete "$rosterName"? This will also delete all associated events and assignments. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final rosterProvider =
                  Provider.of<RosterProvider>(context, listen: false);
              final success = await rosterProvider.deleteRoster();

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                if (success) {
                  Navigator.of(context).pop(); // Go back to team detail
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Roster deleted')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to delete: ${rosterProvider.error ?? "Unknown error"}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
