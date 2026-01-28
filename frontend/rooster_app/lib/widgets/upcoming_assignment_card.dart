import 'package:flutter/material.dart';
import '../models/event_assignment.dart';

class UpcomingAssignmentCard extends StatelessWidget {
  final EventAssignment assignment;
  final VoidCallback? onTap;
  final VoidCallback? onTeamTap;

  const UpcomingAssignmentCard({
    super.key,
    required this.assignment,
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
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.rosterName ?? 'Assignment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
                    Text(
                      _formatDate(assignment.eventDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
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
