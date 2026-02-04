import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
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

  /// Get the current notification permission status.
  static String getPermissionStatus() {
    if (!kIsWeb) return 'unsupported';
    return web.Notification.permission;
  }

  /// Request notification permission from the browser.
  /// Returns 'granted', 'denied', or 'default'.
  static Future<String> requestPermission() async {
    if (!kIsWeb) return 'unsupported';

    try {
      final jsResult = await web.Notification.requestPermission().toDart;
      return jsResult.toDart;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return 'error';
    }
  }

  /// Request permission and subscribe to push notifications.
  /// Returns true if successful, false otherwise.
  static Future<bool> requestPermissionAndSubscribe() async {
    if (!kIsWeb) return false;

    try {
      // Request notification permission
      final permission = await requestPermission();
      if (permission != 'granted') {
        debugPrint('Notification permission not granted: $permission');
        return false;
      }

      // Get the VAPID public key
      final vapidKey = await getVapidPublicKey();
      if (vapidKey == null) {
        debugPrint('VAPID key not available');
        return false;
      }

      // Get service worker registration
      final registration = await _getServiceWorkerRegistration();
      if (registration == null) {
        debugPrint('Service worker not registered');
        return false;
      }

      // Subscribe to push
      final subscription = await _subscribeToPush(registration, vapidKey);
      if (subscription == null) {
        debugPrint('Failed to subscribe to push');
        return false;
      }

      // Send subscription to backend
      final success = await _sendSubscriptionToBackend(subscription);
      if (success) {
        await _storeSubscription(subscription['endpoint'] as String);
        // Send auth token to service worker for push action callbacks
        await sendAuthTokenToServiceWorker();
      }
      return success;
    } catch (e) {
      debugPrint('Error in requestPermissionAndSubscribe: $e');
      return false;
    }
  }

  /// Get the service worker registration.
  static Future<web.ServiceWorkerRegistration?>
  _getServiceWorkerRegistration() async {
    try {
      final container = web.window.navigator.serviceWorker;
      final registration = await container.ready.toDart;
      return registration;
    } catch (e) {
      debugPrint('Error getting service worker registration: $e');
      return null;
    }
  }

  /// Subscribe to push notifications using the PushManager.
  static Future<Map<String, dynamic>?> _subscribeToPush(
    web.ServiceWorkerRegistration registration,
    String vapidKey,
  ) async {
    try {
      final pushManager = registration.pushManager;

      // Convert VAPID key from base64url to Uint8Array
      final applicationServerKey = _urlBase64ToJSUint8Array(vapidKey);

      // Create subscription options
      final options = web.PushSubscriptionOptionsInit(
        userVisibleOnly: true,
        applicationServerKey: applicationServerKey,
      );

      // Subscribe
      final subscription = await pushManager.subscribe(options).toDart;

      // Extract subscription data
      final endpoint = subscription.endpoint;
      final p256dhBuffer = subscription.getKey('p256dh');
      final authBuffer = subscription.getKey('auth');

      if (p256dhBuffer == null || authBuffer == null) {
        debugPrint('Failed to get subscription keys');
        return null;
      }

      // Convert ArrayBuffer to base64
      final p256dhKey = _arrayBufferToBase64(p256dhBuffer);
      final authKey = _arrayBufferToBase64(authBuffer);

      return {
        'endpoint': endpoint,
        'p256dh_key': p256dhKey,
        'auth_key': authKey,
      };
    } catch (e) {
      debugPrint('Error subscribing to push: $e');
      return null;
    }
  }

  /// Convert URL-safe base64 to JSUint8Array.
  static JSUint8Array _urlBase64ToJSUint8Array(String base64String) {
    // Add padding if needed
    var padding = '=' * ((4 - base64String.length % 4) % 4);
    var base64 = base64String + padding;

    // Convert from URL-safe base64 to regular base64
    base64 = base64.replaceAll('-', '+').replaceAll('_', '/');

    // Decode to bytes
    final rawData = base64Decode(base64);

    // Create JSUint8Array from Dart Uint8List
    return rawData.toJS;
  }

  /// Convert ArrayBuffer to base64 string.
  static String _arrayBufferToBase64(JSArrayBuffer buffer) {
    // Convert JSArrayBuffer to Dart Uint8List
    final uint8List = buffer.toDart.asUint8List();
    return base64Encode(uint8List);
  }

  /// Send subscription to backend.
  static Future<bool> _sendSubscriptionToBackend(
    Map<String, dynamic> subscription,
  ) async {
    try {
      final response = await ApiClient.post('/push/subscribe', {
        'endpoint': subscription['endpoint'],
        'p256dh_key': subscription['p256dh_key'],
        'auth_key': subscription['auth_key'],
      });

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending subscription to backend: $e');
      return false;
    }
  }

  /// Send the current auth token to the service worker for push action callbacks.
  /// Call this after subscribing and on app startup if already subscribed.
  static Future<void> sendAuthTokenToServiceWorker() async {
    if (!kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final controller = web.window.navigator.serviceWorker.controller;
      if (controller != null) {
        final message = {'type': 'AUTH_TOKEN', 'token': token}.jsify();
        controller.postMessage(message);
        debugPrint('Auth token sent to service worker');
      }
    } catch (e) {
      debugPrint('Error sending auth token to service worker: $e');
    }
  }

  /// Listen for NAVIGATE messages from the service worker.
  /// When a push notification is tapped in an already-open window, the SW
  /// sends a postMessage with type 'NAVIGATE' and a url to route to.
  static void listenForServiceWorkerMessages(
    void Function(String url) onNavigate,
  ) {
    if (!kIsWeb) return;

    try {
      final sw = web.window.navigator.serviceWorker;
      sw.addEventListener(
        'message',
        (web.Event event) {
          final messageEvent = event as web.MessageEvent;
          final data = messageEvent.data;
          if (data == null) return;

          // Convert JSAny to a Dart map
          final dartData = (data as JSObject).dartify();
          if (dartData is Map) {
            final type = dartData['type'];
            final url = dartData['url'];
            if (type == 'NAVIGATE' && url is String) {
              debugPrint('Received NAVIGATE from service worker: $url');
              onNavigate(url);
            }
          }
        }.toJS,
      );
      debugPrint('Listening for service worker messages');
    } catch (e) {
      debugPrint('Error setting up service worker message listener: $e');
    }
  }

  /// Subscribe to push notifications (legacy method for compatibility).
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
