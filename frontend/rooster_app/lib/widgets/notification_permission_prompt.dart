import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/push_service.dart';

/// A dismissible card that prompts users to enable push notifications.
///
/// Shows when push notifications are available but not yet enabled.
class NotificationPermissionPrompt extends StatefulWidget {
  const NotificationPermissionPrompt({super.key});

  @override
  State<NotificationPermissionPrompt> createState() =>
      _NotificationPermissionPromptState();
}

class _NotificationPermissionPromptState
    extends State<NotificationPermissionPrompt> {
  bool _isVisible = false;
  bool _isLoading = false;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    // Only check once and only on web
    if (_hasChecked || !kIsWeb) return;
    _hasChecked = true;

    try {
      final isSubscribed = await PushService.isSubscribed();
      if (isSubscribed) return;

      // Show if the browser supports notifications, even if VAPID
      // isn't configured yet — the subscribe flow handles that gracefully.
      final browserSupports =
          PushService.isSupported &&
          PushService.getPermissionStatus() != 'denied';

      if (mounted && browserSupports) {
        setState(() {
          _isVisible = true;
        });
      }
    } catch (e) {
      // Silently fail - push notifications are optional
      debugPrint('Error checking push availability: $e');
    }
  }

  Future<void> _enable() async {
    setState(() => _isLoading = true);

    try {
      // Request permission and subscribe to push notifications
      final success = await PushService.requestPermissionAndSubscribe();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications enabled!'),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() => _isVisible = false);
        } else {
          // Check if permission was denied
          final status = PushService.getPermissionStatus();
          if (status == 'denied') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notifications blocked. Enable in browser settings.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
            setState(() => _isVisible = false);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not enable notifications. Try again.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay Updated',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get notified about new assignments',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              FilledButton(onPressed: _enable, child: const Text('Enable')),
          ],
        ),
      ),
    );
  }
}
