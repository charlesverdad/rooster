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

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    // Only show on web
    if (!kIsWeb) return;

    // Check if push is available and not dismissed
    final isAvailable = await PushService.isAvailable();
    final isDismissed = await PushService.isPermissionDismissed();
    final isSubscribed = await PushService.isSubscribed();

    if (mounted) {
      setState(() {
        _isVisible = isAvailable && !isDismissed && !isSubscribed;
      });
    }
  }

  Future<void> _dismiss() async {
    await PushService.dismissPermissionPrompt();
    if (mounted) {
      setState(() => _isVisible = false);
    }
  }

  Future<void> _enable() async {
    setState(() => _isLoading = true);

    try {
      // Show instructions for enabling notifications
      // In a full implementation, this would request permission and subscribe
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Click "Allow" when prompted to enable notifications',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // For now, just dismiss - actual subscription would happen via JS interop
      await _dismiss();
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
            else ...[
              TextButton(onPressed: _dismiss, child: const Text('Later')),
              const SizedBox(width: 4),
              FilledButton(onPressed: _enable, child: const Text('Enable')),
            ],
          ],
        ),
      ),
    );
  }
}
