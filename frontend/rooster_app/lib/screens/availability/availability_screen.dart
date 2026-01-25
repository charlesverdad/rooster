import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/assignment_provider.dart';
import '../../models/event_assignment.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AssignmentProvider>(context, listen: false).fetchMyAssignments();
    });
  }

  Future<void> _refresh() async {
    await Provider.of<AssignmentProvider>(context, listen: false).fetchMyAssignments();
  }

  Future<void> _updateStatus(String assignmentId, String newStatus) async {
    final provider = Provider.of<AssignmentProvider>(context, listen: false);
    final success = await provider.updateAssignmentStatus(assignmentId, newStatus);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'confirmed'
                ? 'Assignment accepted'
                : 'Assignment declined',
          ),
          backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AssignmentProvider>(context);

    // Group assignments by status
    final pending = provider.pendingAssignments;
    final confirmed = provider.upcomingAssignments;
    final declined = provider.assignments.where((a) => a.isDeclined).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (pending.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Pending Response',
                      pending.length,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    ...pending.map((assignment) => _buildAssignmentCard(
                          context,
                          assignment,
                          showActions: true,
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (confirmed.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Accepted',
                      confirmed.length,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    ...confirmed.map((assignment) => _buildAssignmentCard(
                          context,
                          assignment,
                          showActions: false,
                        )),
                    const SizedBox(height: 24),
                  ],
                  if (declined.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      'Declined',
                      declined.length,
                      Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    ...declined.map((assignment) => _buildAssignmentCard(
                          context,
                          assignment,
                          showActions: false,
                        )),
                  ],
                  if (provider.assignments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.event_available, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No assignments yet',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(
    BuildContext context,
    EventAssignment assignment, {
    required bool showActions,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final eventDate = assignment.eventDate;
    final isToday = eventDate != null &&
        DateTime.now().difference(eventDate).inDays == 0;
    final isPast = eventDate != null && eventDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        assignment.rosterName ?? 'Assignment',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventDate != null
                            ? dateFormat.format(eventDate)
                            : 'Date TBD',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Chip(
                    label: const Text('TODAY'),
                    backgroundColor: Colors.orange,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (showActions && !isPast) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateStatus(assignment.id, 'declined'),
                      icon: const Icon(Icons.close),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateStatus(assignment.id, 'confirmed'),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
