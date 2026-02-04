import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

/// Typed wrapper for the BeforeInstallPromptEvent so we can call .prompt().
extension type _BeforeInstallPromptEvent._(JSObject _) implements JSObject {
  external JSPromise prompt();
}

/// JS interop to access the deferred beforeinstallprompt event stored on window.
@JS('window._pwaInstallPrompt')
external JSObject? get _deferredPromptRaw;

@JS('window._pwaInstallPrompt')
external set _deferredPromptRaw(JSObject? value);

/// A dismissible card that prompts users to install the PWA.
///
/// Listens for the browser's `beforeinstallprompt` event (captured in index.html)
/// and triggers the native install dialog when the user taps Install.
class InstallPrompt extends StatefulWidget {
  const InstallPrompt({super.key});

  @override
  State<InstallPrompt> createState() => _InstallPromptState();
}

class _InstallPromptState extends State<InstallPrompt> {
  static const _dismissedKey = 'install_prompt_dismissed';

  bool _isDismissed = true;
  bool _canInstall = false;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkState();
  }

  Future<void> _checkState() async {
    if (_hasChecked || !kIsWeb) return;
    _hasChecked = true;

    try {
      // Already running as installed PWA — nothing to prompt.
      if (web.window.matchMedia('(display-mode: standalone)').matches) return;

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_dismissedKey) ?? false;

      if (mounted && !dismissed) {
        setState(() {
          _isDismissed = false;
          _canInstall = true;
        });

        // If the event hasn't fired yet, listen for it.
        if (_deferredPromptRaw == null) {
          web.window.addEventListener(
            'beforeinstallprompt',
            ((web.Event e) {
              e.preventDefault();
              if (mounted) setState(() => _canInstall = true);
            }).toJS,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking install state: $e');
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
    final raw = _deferredPromptRaw;
    if (raw != null) {
      // Trigger the native browser install dialog.
      final prompt = _BeforeInstallPromptEvent._(raw);
      prompt.prompt();
      // Clear the deferred prompt — it can only be used once.
      _deferredPromptRaw = null;
      await _dismiss();
    } else {
      // Fallback for browsers that don't support beforeinstallprompt (e.g. iOS Safari).
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'To install: tap the share icon and select "Add to Home Screen"',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      await _dismiss();
    }
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
