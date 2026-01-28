import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/roster_event.dart';
import '../providers/team_provider.dart';
import '../services/roster_service.dart';
import '../screens/roster/assign_volunteers_sheet.dart';

class TeamLeadSection extends StatefulWidget {
  const TeamLeadSection({super.key});

  @override
  State<TeamLeadSection> createState() => _TeamLeadSectionState();
}

class _TeamLeadSectionState extends State<TeamLeadSection> {
  List<RosterEvent> _unfilledEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnfilledEvents();
  }

  Future<void> _loadUnfilledEvents() async {
    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final teams = teamProvider.teams;

      if (teams.isEmpty) {
        await teamProvider.fetchMyTeams();
      }

      // Get unfilled events for teams where user is lead
      final leadTeams = teamProvider.teams.where((t) => t.isTeamLead).toList();

      final allUnfilledEvents = <RosterEvent>[];

      for (final team in leadTeams) {
        try {
          final events = await RosterService.getUnfilledEvents(team.id);
          allUnfilledEvents.addAll(events);
        } catch (e) {
          debugPrint('Error fetching unfilled events for team ${team.id}: $e');
        }
      }

      // Sort by date and take events in the next 4 weeks
      final now = DateTime.now();
      final fourWeeksFromNow = now.add(const Duration(days: 28));

      allUnfilledEvents.sort((a, b) => a.date.compareTo(b.date));
      final filtered = allUnfilledEvents
          .where(
            (e) => e.date.isAfter(now) && e.date.isBefore(fourWeeksFromNow),
          )
          .toList();

      if (mounted) {
        setState(() {
          _unfilledEvents = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading unfilled events: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                context.push('/teams');
              },
              child: const Text('View Teams'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Loading state
        if (_isLoading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        // Needs Attention Section
        else if (_unfilledEvents.isEmpty)
          _buildAllFilledCard()
        else
          _buildNeedsAttentionCard(context, _unfilledEvents),
      ],
    );
  }

  Widget _buildAllFilledCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'All Set',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'All upcoming rosters are fully assigned',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsAttentionCard(
    BuildContext context,
    List<RosterEvent> unfilledEvents,
  ) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Needs Attention',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${unfilledEvents.length} unfilled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Show first 3 unfilled events
            ...unfilledEvents
                .take(3)
                .map((event) => _buildUnfilledEventItem(context, event)),
            if (unfilledEvents.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${unfilledEvents.length - 3} more unfilled slots',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnfilledEventItem(BuildContext context, RosterEvent event) {
    final slotsRemaining = event.slotsNeeded - event.filledSlots;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.rosterName ?? 'Roster',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_formatDate(event.date)} • $slotsRemaining slot${slotsRemaining == 1 ? '' : 's'} needed',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _showAssignSheet(context, event),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Assign'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignSheet(BuildContext context, RosterEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AssignVolunteersSheet(
        teamId: event.teamId,
        eventId: event.id,
        eventDate: event.date,
        rosterName: event.rosterName ?? 'Roster',
        onAssign: null,
      ),
    ).then((_) => _loadUnfilledEvents());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(date.year, date.month, date.day);
    final difference = eventDay.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[date.weekday % 7];
    }

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
