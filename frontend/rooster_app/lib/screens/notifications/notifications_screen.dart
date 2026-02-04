import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../providers/team_provider.dart';
import '../../services/api_client.dart';
import '../../services/invite_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// IDs of notifications that were unread when the screen first opened.
  /// Used so the blue highlight persists during this viewing session,
  /// even though we immediately mark them as read on the backend (to
  /// clear the badge).
  final Set<String> _initiallyUnreadIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await provider.fetchNotifications();

      // Snapshot which ones are unread right now
      for (final n in provider.notifications) {
        if (!n.isRead) _initiallyUnreadIds.add(n.id);
      }

      // Mark all as read on backend (clears badge) but don't update
      // local styling — highlights stay until next time this screen opens.
      if (_initiallyUnreadIds.isNotEmpty) {
        provider.markAllAsRead();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? RefreshIndicator(
              onRefresh: notificationProvider.fetchNotifications,
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll see assignment and team updates here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _initiallyUnreadIds.clear();
                await notificationProvider.fetchNotifications();
              },
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await notificationProvider.deleteNotification(
                        notification.id,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification deleted')),
                      );
                    },
                    child: _buildNotificationTile(context, notification),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    AppNotification notification,
  ) {
    // Use the snapshot from when the screen opened, not the live state,
    // so highlights persist during this session.
    final showAsUnread = _initiallyUnreadIds.contains(notification.id);

    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'assignment':
        icon = Icons.assignment;
        iconColor = Colors.blue;
        break;
      case 'reminder':
        icon = Icons.notifications_active;
        iconColor = Colors.orange;
        break;
      case 'response':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'alert':
        icon = Icons.warning_rounded;
        iconColor = Colors.deepOrange;
        break;
      case 'invite':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case 'conflict':
        icon = Icons.error_outline;
        iconColor = Colors.red;
        break;
      case 'team':
        icon = Icons.group;
        iconColor = Colors.grey;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Container(
      color: showAsUnread ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: showAsUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: _hasNavigation(notification)
            ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
            : null,
        onTap: () => _handleNotificationTap(context, notification),
      ),
    );
  }

  bool _hasNavigation(AppNotification notification) {
    if (notification.referenceId == null) return false;
    return const [
      'assignment',
      'reminder',
      'response',
      'alert',
      'team',
      'invite',
    ].contains(notification.type);
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    // Navigate based on notification type
    if (notification.referenceId != null) {
      switch (notification.type) {
        case 'assignment':
        case 'reminder':
          _navigateToAssignment(context, notification.referenceId!);
          break;
        case 'response':
        case 'alert':
          _navigateToAssignment(context, notification.referenceId!);
          break;
        case 'team':
          context.push('/teams/${notification.referenceId}');
          break;
        case 'invite':
          await _handleInviteTap(context, notification);
          break;
      }
    }
  }

  void _navigateToAssignment(BuildContext context, String assignmentId) {
    context.push('/assignments/$assignmentId');
  }

  Future<void> _handleInviteTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (notification.referenceId == null) return;

    final teamId = notification.referenceId!;

    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team Invitation'),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Join Team'),
          ),
        ],
      ),
    );

    if (accept != true || !context.mounted) return;

    try {
      await InviteService.acceptInviteByTeam(teamId);
      if (!context.mounted) return;

      // Remove this notification and refresh teams
      final notifProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notifProvider.deleteNotification(notification.id);
      _initiallyUnreadIds.remove(notification.id);

      Provider.of<TeamProvider>(context, listen: false).fetchMyTeams();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined the team!')),
      );

      context.push('/teams/$teamId');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.isNotFound) {
        // No pending invite — user probably already joined
        // Remove the stale notification
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).deleteNotification(notification.id);
        _initiallyUnreadIds.remove(notification.id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You\'ve already joined this team.')),
        );

        // Navigate to the team anyway
        context.push('/teams/$teamId');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join team: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join team: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
