import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/organisation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/organisation_provider.dart';
import '../../widgets/back_button.dart';

class OrgSettingsScreen extends StatefulWidget {
  final String orgId;

  const OrgSettingsScreen({super.key, required this.orgId});

  @override
  State<OrgSettingsScreen> createState() => _OrgSettingsScreenState();
}

class _OrgSettingsScreenState extends State<OrgSettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orgProvider = Provider.of<OrganisationProvider>(
        context,
        listen: false,
      );
      orgProvider.fetchMembers(widget.orgId);

      // Set initial name
      final org = _findOrg(orgProvider);
      if (org != null) {
        _nameController.text = org.name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Organisation? _findOrg(OrganisationProvider provider) {
    try {
      return provider.organisations.firstWhere((o) => o.id == widget.orgId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSavingName = true);

    final orgProvider = Provider.of<OrganisationProvider>(
      context,
      listen: false,
    );
    final success = await orgProvider.updateOrganisation(
      widget.orgId,
      name: name,
    );

    if (mounted) {
      setState(() {
        _isSavingName = false;
        _isEditingName = false;
      });
      if (success) {
        // Also refresh auth to get updated org data
        Provider.of<AuthProvider>(context, listen: false).fetchCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organisation name updated'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orgProvider.error ?? 'Failed to update name'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changeMemberRole(
    OrganisationMember member,
    String newRole,
  ) async {
    final orgProvider = Provider.of<OrganisationProvider>(
      context,
      listen: false,
    );
    final success = await orgProvider.updateMemberRole(
      widget.orgId,
      member.userId,
      newRole,
    );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orgProvider.error ?? 'Failed to update role'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(OrganisationMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Remove ${member.userName} from this organisation? '
          'They will also be removed from all teams.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final orgProvider = Provider.of<OrganisationProvider>(
      context,
      listen: false,
    );
    final success = await orgProvider.removeMember(widget.orgId, member.userId);

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orgProvider.error ?? 'Failed to remove member'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteOrganisation() async {
    final org = _findOrg(
      Provider.of<OrganisationProvider>(context, listen: false),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organisation'),
        content: Text(
          'Permanently delete "${org?.name ?? 'this organisation'}"? '
          'This will also delete all teams, rosters, and assignments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final orgProvider = Provider.of<OrganisationProvider>(
      context,
      listen: false,
    );
    final success = await orgProvider.deleteOrganisation(widget.orgId);

    if (mounted) {
      if (success) {
        Provider.of<AuthProvider>(context, listen: false).fetchCurrentUser();
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orgProvider.error ?? 'Failed to delete organisation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgProvider = Provider.of<OrganisationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final org = _findOrg(orgProvider);
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Organisation Settings'),
      ),
      body: org == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Organisation name
                _buildNameSection(org),
                const SizedBox(height: 24),

                // Members
                _buildMembersSection(orgProvider.members, currentUserId),
                const SizedBox(height: 24),

                // Danger zone
                _buildDangerZone(),
              ],
            ),
    );
  }

  Widget _buildNameSection(Organisation org) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organisation Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            if (_isEditingName) ...[
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., City Church',
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _saveName(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() => _isEditingName = false);
                      _nameController.text =
                          _findOrg(
                            Provider.of<OrganisationProvider>(
                              context,
                              listen: false,
                            ),
                          )?.name ??
                          '';
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSavingName ? null : _saveName,
                    child: _isSavingName
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(org.name, style: const TextStyle(fontSize: 18)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () {
                      _nameController.text = org.name;
                      setState(() => _isEditingName = true);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(
    List<OrganisationMember> members,
    String? currentUserId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Members',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              '${members.length}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...members.map(
                  (member) => _buildMemberTile(member, currentUserId),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(OrganisationMember member, String? currentUserId) {
    final isCurrentUser = member.userId == currentUserId;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade600,
        child: Text(
          member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(member.userName, overflow: TextOverflow.ellipsis),
          ),
          if (isCurrentUser)
            Text(
              ' (you)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
        ],
      ),
      subtitle: member.userEmail != null
          ? Text(
              member.userEmail!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: member.isAdmin
                  ? Colors.grey.shade200
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              member.isAdmin ? 'Admin' : 'Member',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          if (!isCurrentUser)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: member.isAdmin ? 'member' : 'admin',
                  child: Text(member.isAdmin ? 'Make Member' : 'Make Admin'),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  _removeMember(member);
                } else {
                  _changeMemberRole(member, value);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade200),
          ),
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
            title: const Text('Delete Organisation'),
            subtitle: const Text('This cannot be undone'),
            trailing: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: _deleteOrganisation,
              child: const Text('Delete'),
            ),
          ),
        ),
      ],
    );
  }
}
