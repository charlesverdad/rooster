import 'package:flutter/material.dart';
import '../models/event_assignment.dart';

class AssignmentActionCard extends StatefulWidget {
  final EventAssignment assignment;
  final VoidCallback onAccept;
  final Future<bool> Function() onDeclineConfirm;
  final VoidCallback onDecline;
  final VoidCallback? onTap;
  final VoidCallback? onTeamTap;

  const AssignmentActionCard({
    super.key,
    required this.assignment,
    required this.onAccept,
    required this.onDeclineConfirm,
    required this.onDecline,
    this.onTap,
    this.onTeamTap,
  });

  @override
  State<AssignmentActionCard> createState() => _AssignmentActionCardState();
}

class _AssignmentActionCardState extends State<AssignmentActionCard>
    with SingleTickerProviderStateMixin {
  bool _isDismissing = false;
  bool _isAccepted = false;
  bool _isDeclined = false;
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.15)).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 0.85, curve: Curves.easeIn),
          ),
        );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.85, curve: Curves.easeOut),
      ),
    );
    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAccept() {
    if (_isDismissing) return;
    // Phase 1: button feedback (checkmark), then start dismiss animation
    setState(() {
      _isAccepted = true;
      _isDismissing = true;
    });
    // Brief pause for button feedback before slide+fade begins
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _controller.forward().then((_) {
        if (mounted) widget.onAccept();
      });
    });
  }

  Future<void> _handleDecline() async {
    if (_isDismissing) return;
    final confirmed = await widget.onDeclineConfirm();
    if (!confirmed || !mounted || _isDismissing) return;
    setState(() {
      _isDeclined = true;
      _isDismissing = true;
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _controller.forward().then((_) {
        if (mounted) widget.onDecline();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDismissing) {
      return _buildCard(context);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _sizeAnimation,
          axisAlignment: -1.0,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(opacity: _fadeAnimation, child: child),
          ),
        );
      },
      child: _buildCard(context),
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
                    child: _isDeclined
                        ? FilledButton(
                            onPressed: null,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              disabledBackgroundColor: Colors.red,
                              disabledForegroundColor: Colors.white,
                            ),
                            child: const Icon(Icons.close, size: 20),
                          )
                        : OutlinedButton(
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
                      style: _isAccepted
                          ? FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            )
                          : null,
                      child: _isAccepted
                          ? const Icon(Icons.check, size: 20)
                          : const Text('Accept'),
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
