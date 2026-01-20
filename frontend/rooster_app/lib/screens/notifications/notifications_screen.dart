import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications
    final notifications = [
      {
        'id': '1',
        'type': 'assignment',
        'title': 'New Assignment',
        'message': 'You\'ve been assigned to Sunday Service on Jan 21',
        'time': '2 hours ago',
        'isRead': false,
      },
      {
        'id': '2',
        'type': 'reminder',
        'title': 'Upcoming Assignment',
        'message': 'Sunday Service tomorrow at 9:00 AM',
        'time': '1 day ago',
        'isRead': false,
      },
      {
        'id': '3',
        'type': 'info',
        'title': 'Team Update',
        'message': 'Mike Chen added you to Media Team',
        'time': '3 days ago',
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
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
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification['id'] as String),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted')),
                    );
                  },
                  child: _buildNotificationTile(context, notification),
                );
              },
            ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'assignment':
        icon = Icons.assignment;
        iconColor = Colors.blue;
        break;
      case 'reminder':
        icon = Icons.notifications_active;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Container(
      color: isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'] as String,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification['message'] as String),
            const SizedBox(height: 4),
            Text(
              notification['time'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to related item and mark as read
        },
      ),
    );
  }
}
