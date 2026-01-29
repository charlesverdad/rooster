import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_member.dart';
import '../../models/suggestion.dart';
import '../../providers/team_provider.dart';
import '../../providers/roster_provider.dart';
import '../../services/team_service.dart';

class AssignVolunteersSheet extends StatefulWidget {
  // Option 1: Use with teamId and callback (from roster detail)
  final String? teamId;
  final Function(String userId)? onAssign;

  // Option 2: Use with eventId and context (from home screen)
  final String? eventId;
  final DateTime? eventDate;
  final String? rosterName;

  // Optional suggestions to display
  final List<Suggestion>? suggestions;

  const AssignVolunteersSheet({
    super.key,
    this.teamId,
    this.onAssign,
    this.eventId,
    this.eventDate,
    this.rosterName,
    this.suggestions,
  });

  // Named constructor for roster detail usage
  const AssignVolunteersSheet.forRoster({
    super.key,
    required this.teamId,
    required this.onAssign,
    this.suggestions,
  }) : eventId = null,
       eventDate = null,
       rosterName = null;

  // Named constructor for home screen usage
  const AssignVolunteersSheet.forEvent({
    super.key,
    required this.eventId,
    required this.eventDate,
    required this.rosterName,
    this.suggestions,
  }) : teamId = null,
       onAssign = null;

  @override
  State<AssignVolunteersSheet> createState() => _AssignVolunteersSheetState();
}

class _AssignVolunteersSheetState extends State<AssignVolunteersSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String?> _unavailabilityReasons = {};
  bool _loadingAvailability = false;
  bool _creatingPlaceholder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.teamId != null) {
        Provider.of<TeamProvider>(
          context,
          listen: false,
        ).fetchTeamDetail(widget.teamId!);
        _fetchAvailability(widget.teamId!);
      }
    });
  }

  Future<void> _fetchAvailability(String teamId) async {
    if (widget.eventDate == null) return;

    setState(() => _loadingAvailability = true);

    try {
      final availability = await TeamService.getTeamAvailability(
        teamId,
        date: widget.eventDate,
      );

      final reasons = <String, String?>{};
      for (final entry in availability) {
        if (entry['is_available'] == false) {
          reasons[entry['user_id'].toString()] =
              entry['unavailability_reason'] as String?;
        }
      }

      if (mounted) {
        setState(() {
          _unavailabilityReasons = reasons;
          _loadingAvailability = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching availability: $e');
      if (mounted) {
        setState(() => _loadingAvailability = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
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

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final members = teamProvider.currentTeamMembers;

    final filteredMembers = _searchQuery.isEmpty
        ? members
        : members
              .where(
                (m) => m.userName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    // Split members into available, unavailable, and placeholders
    final available = <TeamMember>[];
    final unavailable = <TeamMember>[];
    final placeholders = <TeamMember>[];

    for (final m in filteredMembers) {
      if (m.isPlaceholder) {
        placeholders.add(m);
      } else if (_unavailabilityReasons.containsKey(m.userId)) {
        unavailable.add(m);
      } else if (!m.isInvited) {
        available.add(m);
      } else {
        // Invited but not placeholder - treat as available
        available.add(m);
      }
    }

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

          if (_loadingAvailability)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Members list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Suggestions section (only when suggestions are provided and search is empty)
                if (widget.suggestions != null &&
                    widget.suggestions!.isNotEmpty &&
                    _searchQuery.isEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Suggested',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.suggestions!.take(3).map(
                    (suggestion) => _buildSuggestionTile(suggestion),
                  ),
                  const SizedBox(height: 16),
                ],
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
                  ...available.map(
                    (member) => _buildMemberTile(member, true, false, null),
                  ),
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
                  ...placeholders.map(
                    (member) => _buildMemberTile(member, true, true, null),
                  ),
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
                  ...unavailable.map(
                    (member) => _buildMemberTile(
                      member,
                      false,
                      false,
                      _unavailabilityReasons[member.userId],
                    ),
                  ),
                ],
                // Show "Create placeholder" option when search has no results
                if (_searchQuery.isNotEmpty && filteredMembers.isEmpty)
                  _buildCreatePlaceholderTile(_searchQuery.trim()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(Suggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            suggestion.userName.isNotEmpty
                ? suggestion.userName.substring(0, 1)
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          suggestion.userName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          suggestion.reasoning,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Create a TeamMember-like object from the suggestion
          // to use with the existing _handleAssign method
          final member = TeamMember(
            userId: suggestion.userId,
            teamId: widget.teamId ?? '',
            role: 'member',
            userName: suggestion.userName,
            isPlaceholder: false,
            isInvited: true,
          );
          await _handleAssign(member);
        },
      ),
    );
  }

  Widget _buildMemberTile(
    TeamMember member,
    bool isAvailable,
    bool isPlaceholder,
    String? unavailableReason,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPlaceholder
              ? Colors.grey.shade400
              : isAvailable
              ? Colors.grey.shade600
              : Colors.grey.shade300,
          child: isPlaceholder
              ? Icon(
                  Icons.person_outline,
                  color: Colors.grey.shade100,
                  size: 20,
                )
              : Text(
                  member.userName.isNotEmpty
                      ? member.userName.substring(0, 1)
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Row(
          children: [
            Text(
              member.userName,
              style: TextStyle(
                color: isAvailable ? null : Colors.grey.shade500,
              ),
            ),
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
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ],
        ),
        subtitle: !isAvailable && unavailableReason != null
            ? Text(
                unavailableReason,
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              )
            : !isAvailable
            ? Text(
                'Unavailable',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              )
            : null,
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

  Widget _buildCreatePlaceholderTile(String name) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.person_add, color: Colors.white, size: 20),
        ),
        title: Text('Create "$name"'),
        subtitle: const Text(
          'Add as placeholder and assign',
          style: TextStyle(fontSize: 12),
        ),
        trailing: _creatingPlaceholder
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        onTap: _creatingPlaceholder ? null : () => _handleCreateAndAssign(name),
      ),
    );
  }

  Future<void> _handleCreateAndAssign(String name) async {
    if (widget.teamId == null) return;

    setState(() => _creatingPlaceholder = true);

    try {
      final teamProvider = Provider.of<TeamProvider>(context, listen: false);
      final success = await teamProvider.addMember(widget.teamId!, name);

      if (!mounted) return;

      if (!success) {
        setState(() => _creatingPlaceholder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create placeholder')),
        );
        return;
      }

      // The newly added member is the last one in the list
      final newMember = teamProvider.currentTeamMembers.last;

      // Assign the new placeholder to the event
      await _handleAssign(newMember);
    } catch (e) {
      debugPrint('Error creating placeholder: $e');
      if (mounted) {
        setState(() => _creatingPlaceholder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create placeholder')),
        );
      }
    }
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
      final rosterProvider = Provider.of<RosterProvider>(
        context,
        listen: false,
      );
      final success = await rosterProvider.assignVolunteerToEvent(
        widget.eventId!,
        memberId,
      );

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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
