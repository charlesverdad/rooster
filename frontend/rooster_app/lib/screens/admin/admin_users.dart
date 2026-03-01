import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  final _searchController = TextEditingController();
  String _activeFilter = 'all';
  String? _sortColumn;
  String? _sortOrder;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _fetchUsers() {
    String? status;
    switch (_activeFilter) {
      case 'superadmin':
        status = 'superadmin';
        break;
      case 'org_admin':
        status = 'org_admin';
        break;
      case 'deactivated':
        status = 'deactivated';
        break;
    }

    context.read<AdminProvider>().fetchUsers(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      status: status,
      page: _currentPage,
      sort: _sortColumn,
      order: _sortOrder,
    );
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _activeFilter = filter;
      _currentPage = 1;
    });
    _fetchUsers();
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
      } else {
        _sortColumn = column;
        _sortOrder = 'asc';
      }
    });
    _fetchUsers();
  }

  void _showUserDetail(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    context.read<AdminProvider>().fetchUserDetail(userId);
    showDialog(
      context: context,
      builder: (ctx) => _UserDetailDialog(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search + Filter
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _currentPage = 1;
                                  _fetchUsers();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) {
                        _currentPage = 1;
                        _fetchUsers();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _activeFilter == 'all',
                    onSelected: (_) => _onFilterChanged('all'),
                  ),
                  FilterChip(
                    label: const Text('Sys Admins'),
                    selected: _activeFilter == 'superadmin',
                    onSelected: (_) => _onFilterChanged('superadmin'),
                  ),
                  FilterChip(
                    label: const Text('Org Admins'),
                    selected: _activeFilter == 'org_admin',
                    onSelected: (_) => _onFilterChanged('org_admin'),
                  ),
                  FilterChip(
                    label: const Text('Deactivated'),
                    selected: _activeFilter == 'deactivated',
                    onSelected: (_) => _onFilterChanged('deactivated'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // User Table
              if (provider.loadingUsers && provider.users.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.usersError != null && provider.users.isEmpty)
                Expanded(
                  child: Center(child: Text('Error: ${provider.usersError}')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortOrder != 'desc',
                        showCheckboxColumn: false,
                        columns: [
                          DataColumn(
                            label: const Text('Name'),
                            onSort: (_, __) => _onSort('name'),
                          ),
                          DataColumn(
                            label: const Text('Email'),
                            onSort: (_, __) => _onSort('email'),
                          ),
                          const DataColumn(label: Text('Organisations')),
                          const DataColumn(label: Text('Roles')),
                          DataColumn(
                            label: const Text('Registered'),
                            onSort: (_, __) => _onSort('created_at'),
                          ),
                          const DataColumn(label: Text('Status')),
                        ],
                        rows: provider.users.map((u) {
                          final user = u as Map<String, dynamic>;
                          return DataRow(
                            onSelectChanged: (_) => _showUserDetail(user),
                            cells: [
                              DataCell(Text(user['name'] as String? ?? '')),
                              DataCell(Text(user['email'] as String? ?? '')),
                              DataCell(Text(_getOrgNames(user))),
                              DataCell(_buildRoleBadges(user)),
                              DataCell(
                                Text(
                                  _formatDate(user['created_at'] as String?),
                                ),
                              ),
                              DataCell(_buildStatusChip(user)),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              // Pagination
              if (provider.usersPages > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () {
                                setState(() => _currentPage--);
                                _fetchUsers();
                              }
                            : null,
                      ),
                      Text(
                        'Page $_currentPage of ${provider.usersPages}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < provider.usersPages
                            ? () {
                                setState(() => _currentPage++);
                                _fetchUsers();
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  int? get _sortColumnIndex {
    switch (_sortColumn) {
      case 'name':
        return 0;
      case 'email':
        return 1;
      case 'created_at':
        return 4;
      default:
        return null;
    }
  }

  String _getOrgNames(Map<String, dynamic> user) {
    final orgs = user['organisations'] as List<dynamic>?;
    if (orgs == null || orgs.isEmpty) return '-';
    return orgs
        .map((o) => (o as Map<String, dynamic>)['name'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .join(', ');
  }

  Widget _buildRoleBadges(Map<String, dynamic> user) {
    final badges = <Widget>[];
    if (user['is_superadmin'] == true) {
      badges.add(_RoleBadge(label: 'Sys Admin', color: Colors.purple));
    }
    final roles = user['roles'] as List<dynamic>?;
    if (roles != null) {
      if (roles.contains('admin')) {
        badges.add(_RoleBadge(label: 'Org Admin', color: Colors.blue));
      }
      if (roles.contains('team_lead')) {
        badges.add(_RoleBadge(label: 'Team Lead', color: Colors.teal));
      }
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 4, children: badges);
  }

  Widget _buildStatusChip(Map<String, dynamic> user) {
    if (user['is_deactivated'] == true) {
      return const Text(
        'Deactivated',
        style: TextStyle(color: Colors.red, fontSize: 13),
      );
    }
    if (user['is_placeholder'] == true) {
      return Text(
        'Placeholder',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      );
    }
    return const Text(
      'Active',
      style: TextStyle(color: Colors.green, fontSize: 13),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(fontSize: 11, color: color)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(60)),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _UserDetailDialog extends StatelessWidget {
  final String userId;

  const _UserDetailDialog({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminProvider, AuthProvider>(
      builder: (context, adminProvider, authProvider, _) {
        final user = adminProvider.selectedUser;
        final currentUserId = authProvider.user?.id;

        if (adminProvider.loadingUserDetail || user == null) {
          return const AlertDialog(
            content: SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final isSelf = user['id'] == currentUserId;
        final isSuperadmin = user['is_superadmin'] == true;
        final isDeactivated = user['is_deactivated'] == true;

        return AlertDialog(
          title: Text(user['name'] as String? ?? 'User'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Info
                  _DetailRow(
                    label: 'Email',
                    value: user['email'] as String? ?? '-',
                  ),
                  _DetailRow(
                    label: 'Registered',
                    value: _formatDate(user['created_at'] as String?),
                  ),
                  _DetailRow(
                    label: 'Status',
                    value: isDeactivated
                        ? 'Deactivated'
                        : user['is_placeholder'] == true
                        ? 'Placeholder'
                        : 'Active',
                  ),
                  const SizedBox(height: 16),

                  // Organisation Memberships
                  Text(
                    'Organisations',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  _buildMembershipList(user['organisations'] as List<dynamic>?),
                  const SizedBox(height: 16),

                  // Team Memberships
                  Text('Teams', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  _buildMembershipList(user['teams'] as List<dynamic>?),
                  const SizedBox(height: 16),

                  if (adminProvider.userDetailError != null) ...[
                    Text(
                      adminProvider.userDetailError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Actions
                  const Divider(),
                  const SizedBox(height: 8),

                  // Sys Admin toggle
                  if (!isSelf)
                    SwitchListTile(
                      title: const Text('System Administrator'),
                      value: isSuperadmin,
                      onChanged: (value) async {
                        bool success;
                        if (value) {
                          success = await adminProvider.promoteAdmin(userId);
                        } else {
                          success = await adminProvider.demoteAdmin(userId);
                        }
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value
                                    ? 'User promoted to system admin'
                                    : 'System admin role removed',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  if (isSelf)
                    const ListTile(
                      title: Text('System Administrator'),
                      subtitle: Text("You can't modify your own admin status"),
                      trailing: Icon(Icons.lock, color: Colors.grey),
                    ),

                  // Deactivate / Reactivate
                  if (!isSelf) ...[
                    const SizedBox(height: 8),
                    if (isDeactivated)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final success = await adminProvider.reactivateUser(
                            userId,
                          );
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User reactivated')),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Reactivate User'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Deactivate User'),
                              content: const Text(
                                'This user will be unable to log in. '
                                'Their data will be preserved.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Deactivate'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final success = await adminProvider.deactivateUser(
                              userId,
                            );
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User deactivated'),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.block, color: Colors.red),
                        label: const Text(
                          'Deactivate User',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                  if (isSelf)
                    const ListTile(
                      dense: true,
                      title: Text(
                        "You can't deactivate your own account",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                adminProvider.clearSelectedUser();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMembershipList(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return Text('None', style: TextStyle(color: Colors.grey.shade600));
    }
    return Column(
      children: items.map((item) {
        final m = item as Map<String, dynamic>;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(m['name'] as String? ?? ''),
          trailing: m['role'] != null
              ? Text(
                  m['role'] as String,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                )
              : null,
        );
      }).toList(),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
