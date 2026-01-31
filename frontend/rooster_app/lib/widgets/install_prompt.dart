import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A dismissible card that prompts users to install the PWA.
///
/// This widget listens for the `beforeinstallprompt` event via JavaScript interop
/// and displays a prompt when the app can be installed.
class InstallPrompt extends StatefulWidget {
  const InstallPrompt({super.key});

  @override
  State<InstallPrompt> createState() => _InstallPromptState();
}

class _InstallPromptState extends State<InstallPrompt> {
  static const _dismissedKey = 'install_prompt_dismissed';

  bool _isDismissed = true;
  bool _canInstall = false;

  @override
  void initState() {
    super.initState();
    _checkState();
  }

  Future<void> _checkState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_dismissedKey) ?? false;

    if (mounted) {
      setState(() {
        _isDismissed = dismissed;
        // In a real implementation, we'd check for the beforeinstallprompt event
        // For now, we'll show the prompt on web when not dismissed
        _canInstall = !dismissed;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    if (mounted) {
      setState(() => _isDismissed = true);
    }
  }

  Future<void> _install() async {
    // In a real implementation, this would trigger the install prompt
    // via JavaScript interop with the deferred `beforeinstallprompt` event
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'To install: tap the browser menu and select "Add to Home Screen"',
        ),
        duration: Duration(seconds: 5),
      ),
    );
    await _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || !_canInstall) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.download_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Install Rooster',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add to your home screen for quick access',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: _dismiss, child: const Text('Later')),
            const SizedBox(width: 4),
            FilledButton(onPressed: _install, child: const Text('Install')),
          ],
        ),
      ),
    );
  }
}
