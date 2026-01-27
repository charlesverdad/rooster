import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../assignments/assignment_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await notificationProvider.markAllAsRead();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                  ),
                );
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
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
              onRefresh: notificationProvider.fetchNotifications,
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
    final isRead = notification.isRead;

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
      case 'team':
        icon = Icons.group;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Container(
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
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
        trailing:
            notification.type == 'assignment' || notification.type == 'reminder'
            ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
            : null,
        onTap: () => _handleNotificationTap(context, notification),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      await Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).markAsRead(notification.id);
    }

    if (!context.mounted) return;

    // Navigate based on notification type
    if (notification.referenceId != null) {
      switch (notification.type) {
        case 'assignment':
        case 'reminder':
          _navigateToAssignment(context, notification.referenceId!);
          break;
        case 'team':
          // Navigate to team detail
          Navigator.pushNamed(
            context,
            '/team-detail',
            arguments: notification.referenceId,
          );
          break;
        case 'response':
          // For team leads - navigate to roster detail
          // For now, show a snackbar
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(notification.message)));
          break;
      }
    }
  }

  void _navigateToAssignment(BuildContext context, String assignmentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AssignmentDetailScreen(assignmentId: assignmentId),
      ),
    );
  }
}
