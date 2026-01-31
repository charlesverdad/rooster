import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

/// Service for managing Web Push notifications.
/// Only works on web platform - native platforms should use Firebase.
class PushService {
  static const _permissionDismissedKey = 'push_permission_dismissed';
  static const _subscriptionKey = 'push_subscription_endpoint';

  /// Check if push notifications are supported on this platform.
  static bool get isSupported => kIsWeb;

  /// Get the VAPID public key from the server.
  /// Returns null if push is not configured (503) or on error.
  static Future<String?> getVapidPublicKey() async {
    if (!isSupported) return null;

    try {
      final response = await ApiClient.get('/push/vapid-public-key');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['publicKey'] as String?;
      }
      // 503 means push not configured - this is expected, don't log
      if (response.statusCode != 503) {
        debugPrint(
          'Unexpected response getting VAPID key: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting VAPID key: $e');
    }
    return null;
  }

  /// Check if push notifications are available (configured on server).
  static Future<bool> isAvailable() async {
    final key = await getVapidPublicKey();
    return key != null && key.isNotEmpty;
  }

  /// Check if the user has dismissed the permission prompt.
  static Future<bool> isPermissionDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionDismissedKey) ?? false;
  }

  /// Mark the permission prompt as dismissed.
  static Future<void> dismissPermissionPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionDismissedKey, true);
  }

  /// Clear the dismissed state (e.g., if user wants to try again).
  static Future<void> clearDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionDismissedKey);
  }

  /// Check if user is already subscribed to push notifications.
  static Future<bool> isSubscribed() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriptionKey) != null;
  }

  /// Store subscription endpoint locally.
  static Future<void> _storeSubscription(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionKey, endpoint);
  }

  /// Clear stored subscription.
  static Future<void> _clearSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriptionKey);
  }

  /// Subscribe to push notifications.
  /// Returns true if successful, false otherwise.
  static Future<bool> subscribe({
    required String endpoint,
    required String p256dhKey,
    required String authKey,
  }) async {
    if (!isSupported) return false;

    try {
      final response = await ApiClient.post('/push/subscribe', {
        'endpoint': endpoint,
        'p256dh_key': p256dhKey,
        'auth_key': authKey,
      });

      if (response.statusCode == 200) {
        await _storeSubscription(endpoint);
        return true;
      }
    } catch (e) {
      debugPrint('Error subscribing to push: $e');
    }
    return false;
  }

  /// Unsubscribe from push notifications.
  static Future<bool> unsubscribe() async {
    if (!isSupported) return false;

    final prefs = await SharedPreferences.getInstance();
    final endpoint = prefs.getString(_subscriptionKey);
    if (endpoint == null) return true;

    try {
      final response = await ApiClient.post('/push/unsubscribe', {
        'endpoint': endpoint,
        'p256dh_key': '',
        'auth_key': '',
      });

      if (response.statusCode == 200 || response.statusCode == 404) {
        await _clearSubscription();
        return true;
      }
    } catch (e) {
      debugPrint('Error unsubscribing from push: $e');
    }
    return false;
  }
}
