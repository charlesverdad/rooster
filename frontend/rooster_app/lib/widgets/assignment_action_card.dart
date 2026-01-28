import 'package:flutter/material.dart';
import '../models/event_assignment.dart';

class AssignmentActionCard extends StatelessWidget {
  final EventAssignment assignment;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onTap;
  final VoidCallback? onTeamTap;

  const AssignmentActionCard({
    super.key,
    required this.assignment,
    required this.onAccept,
    required this.onDecline,
    this.onTap,
    this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PENDING RESPONSE',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Roster name
              Text(
                assignment.rosterName ?? 'Assignment',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (assignment.teamName != null &&
                  assignment.teamName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: onTeamTap,
                  child: Text(
                    assignment.teamName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: onTeamTap != null
                          ? Colors.blue
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Date
              Text(
                _formatDate(assignment.eventDate),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date TBD';

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final assignmentDate = DateTime(date.year, date.month, date.day);

    if (assignmentDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (assignmentDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final daysUntil = assignmentDate
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (daysUntil < 7) {
        return 'In $daysUntil days';
      } else {
        return _formatMonthDay(date);
      }
    }
  }

  String _formatMonthDay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
