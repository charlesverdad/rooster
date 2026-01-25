import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_member.dart';
import '../../providers/team_provider.dart';
import '../../providers/roster_provider.dart';

class AssignVolunteersSheet extends StatefulWidget {
  // Option 1: Use with teamId and callback (from roster detail)
  final String? teamId;
  final Function(String userId)? onAssign;

  // Option 2: Use with eventId and context (from home screen)
  final String? eventId;
  final DateTime? eventDate;
  final String? rosterName;

  const AssignVolunteersSheet({
    super.key,
    this.teamId,
    this.onAssign,
    this.eventId,
    this.eventDate,
    this.rosterName,
  });

  // Named constructor for roster detail usage
  const AssignVolunteersSheet.forRoster({
    super.key,
    required String teamId,
    required Function(String userId) onAssign,
  })  : teamId = teamId,
        onAssign = onAssign,
        eventId = null,
        eventDate = null,
        rosterName = null;

  // Named constructor for home screen usage
  const AssignVolunteersSheet.forEvent({
    super.key,
    required String eventId,
    required DateTime eventDate,
    required String rosterName,
  })  : eventId = eventId,
        eventDate = eventDate,
        rosterName = rosterName,
        teamId = null,
        onAssign = null;

  @override
  State<AssignVolunteersSheet> createState() => _AssignVolunteersSheetState();
}

class _AssignVolunteersSheetState extends State<AssignVolunteersSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.teamId != null) {
        Provider.of<TeamProvider>(context, listen: false)
            .fetchTeamDetail(widget.teamId!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final members = teamProvider.currentTeamMembers;

    final filteredMembers = _searchQuery.isEmpty
        ? members
        : members
            .where((m) =>
                m.userName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final available = filteredMembers
        .where((m) => !m.isPlaceholder && !m.isInvited)
        .toList();
    final unavailable =
        <TeamMember>[]; // TODO: Add unavailability logic
    final placeholders =
        filteredMembers.where((m) => m.isPlaceholder).toList();

    // Build header text
    String headerText = 'Assign Volunteer';
    String? subtitleText;
    if (widget.rosterName != null && widget.eventDate != null) {
      headerText = widget.rosterName!;
      subtitleText = _formatDate(widget.eventDate!);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Padding(
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
                            headerText,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitleText != null)
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Members list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (available.isNotEmpty) ...[
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...available.map((member) =>
                      _buildMemberTile(member, true, false)),
                  const SizedBox(height: 16),
                ],
                if (placeholders.isNotEmpty) ...[
                  Text(
                    'Placeholders (not yet invited)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...placeholders.map((member) =>
                      _buildMemberTile(member, true, true)),
                  const SizedBox(height: 16),
                ],
                if (unavailable.isNotEmpty) ...[
                  Text(
                    'Unavailable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unavailable.map((member) =>
                      _buildMemberTile(member, false, false)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
      TeamMember member, bool isAvailable, bool isPlaceholder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPlaceholder
              ? Colors.grey.shade400
              : Colors.deepPurple.shade300,
          child: isPlaceholder
              ? Icon(Icons.person_outline, color: Colors.grey.shade100, size: 20)
              : Text(
                  member.userName.isNotEmpty
                      ? member.userName.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
        title: Row(
          children: [
            Text(member.userName),
            if (isPlaceholder) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  member.isInvited ? 'Invited' : 'Not invited',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: isAvailable ? const Icon(Icons.chevron_right) : null,
        onTap: isAvailable
            ? () async {
                await _handleAssign(member);
              }
            : null,
        enabled: isAvailable,
      ),
    );
  }

  Future<void> _handleAssign(TeamMember member) async {
    final memberId = member.userId;
    final memberName = member.userName;
    final isPlaceholder = member.isPlaceholder;

    // Use callback if provided (roster detail flow)
    if (widget.onAssign != null) {
      await widget.onAssign!(memberId);
      if (mounted) {
        Navigator.of(context).pop();
        _showAssignedToast(memberName, isPlaceholder);
      }
      return;
    }

    // Otherwise use eventId (home screen flow)
    if (widget.eventId != null) {
      final rosterProvider =
          Provider.of<RosterProvider>(context, listen: false);
      final success = await rosterProvider.assignVolunteerToEvent(
          widget.eventId!, memberId);

      if (mounted) {
        Navigator.of(context).pop();
        if (success) {
          _showAssignedToast(memberName, isPlaceholder);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to assign volunteer')),
          );
        }
      }
    }
  }

  void _showAssignedToast(String memberName, bool isPlaceholder) {
    final message = isPlaceholder
        ? '$memberName assigned. Invite them to notify.'
        : '$memberName assigned. Notification sent.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
