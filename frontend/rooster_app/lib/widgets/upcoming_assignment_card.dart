import 'package:flutter/material.dart';
import '../models/assignment.dart';

class UpcomingAssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback? onTap;

  const UpcomingAssignmentCard({
    super.key,
    required this.assignment,
    this.onTap,
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
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 24,
              ),
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
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(assignment.date),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final assignmentDate = DateTime(date.year, date.month, date.day);

    if (assignmentDate == DateTime(now.year, now.month, now.day)) {
      return 'Today • ${_formatTime(date)}';
    } else if (assignmentDate == tomorrow) {
      return 'Tomorrow • ${_formatTime(date)}';
    } else {
      final daysUntil = assignmentDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (daysUntil < 7) {
        return 'In $daysUntil days • ${_formatTime(date)}';
      } else {
        return '${_formatMonthDay(date)} • ${_formatTime(date)}';
      }
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatMonthDay(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
