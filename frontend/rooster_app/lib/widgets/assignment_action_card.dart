import 'package:flutter/material.dart';
import '../models/event_assignment.dart';

class AssignmentActionCard extends StatefulWidget {
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
  State<AssignmentActionCard> createState() => _AssignmentActionCardState();
}

class _AssignmentActionCardState extends State<AssignmentActionCard>
    with SingleTickerProviderStateMixin {
  // null = idle, true = accepted, false = declined
  bool? _dismissState;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAccept() {
    if (_dismissState != null) return;
    setState(() => _dismissState = true);
    // Animate first, then fire the callback so the provider doesn't
    // remove the item before the animation completes.
    _controller.forward().then((_) {
      if (mounted) widget.onAccept();
    });
  }

  void _handleDecline() {
    if (_dismissState != null) return;
    widget.onDecline();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissState == null) {
      return _buildCard(context);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _sizeAnimation,
          axisAlignment: -1.0,
          child: FadeTransition(opacity: _fadeAnimation, child: child),
        );
      },
      child: _buildDismissedCard(context),
    );
  }

  Widget _buildDismissedCard(BuildContext context) {
    final isAccepted = _dismissState == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isAccepted ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              color: isAccepted ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              isAccepted ? 'Accepted' : 'Declined',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isAccepted
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PENDING RESPONSE',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Roster name
              Text(
                widget.assignment.rosterName ?? 'Assignment',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.assignment.teamName != null &&
                  widget.assignment.teamName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: widget.onTeamTap,
                  child: Text(
                    widget.assignment.teamName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.onTeamTap != null
                          ? Colors.blue
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),

              // Date
              Text(
                _formatDate(widget.assignment.eventDate),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _handleAccept,
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
