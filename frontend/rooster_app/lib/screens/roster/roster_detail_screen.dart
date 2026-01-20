import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/roster_provider.dart';
import '../../providers/team_provider.dart';
import '../roster/assign_volunteers_sheet.dart';

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

    if (rosterProvider.isLoading || roster == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roster Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(roster.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit roster screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit roster coming soon')),
              );
            },
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
          ...events.map((event) => _buildEventCard(context, event)),

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

  Widget _buildEventCard(BuildContext context, event) {
    final dateFormat = DateFormat('EEE, MMM d, y');
    final timeFormat = DateFormat('h:mm a');
    final isFilled = event.isFilled;
    final isPartial = event.isPartial;
    final isUnfilled = event.isUnfilled;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isFilled) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Filled';
    } else if (isPartial) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Partial';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Unfilled';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to event detail
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
                          dateFormat.format(event.dateTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeFormat.format(event.dateTime),
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                        '${event.assignedUserIds.length}/${event.volunteersNeeded}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (event.assignedUserNames != null &&
                  event.assignedUserNames!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: event.assignedUserNames!
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
                          rosterDate: dateFormat.format(event.dateTime),
                          onAssign: (userId) async {
                            final rosterProvider =
                                Provider.of<RosterProvider>(context,
                                    listen: false);
                            await rosterProvider.assignVolunteerToEvent(
                              event.id,
                              userId,
                            );
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
}
