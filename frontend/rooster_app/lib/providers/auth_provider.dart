import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    await ApiClient.loadToken();
    if (ApiClient.hasToken) {
      await fetchCurrentUser();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // OAuth2 expects form data, not JSON
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'username': email, 'password': password},
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        await fetchCurrentUser();
        // Re-subscribe push for the new user if permission already granted
        try {
          if (PushService.isSupported &&
              PushService.getPermissionStatus() == 'granted') {
            await PushService.requestPermissionAndSubscribe();
          }
        } catch (e) {
          debugPrint('Error re-subscribing push on login: $e');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        // Auto-login after registration
        return await login(email, password);
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      final response = await ApiClient.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<void> logout() async {
    // Unsubscribe push before clearing auth token (needs auth to call API)
    try {
      await PushService.unsubscribe();
    } catch (e) {
      debugPrint('Error unsubscribing push on logout: $e');
    }
    await ApiClient.clearToken();
    _user = null;
    notifyListeners();
  }
}
