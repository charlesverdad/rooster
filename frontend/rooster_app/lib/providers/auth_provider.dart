import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    await ApiClient.loadToken();
    if (ApiClient.hasToken) {
      await fetchCurrentUser();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/auth/login', {
        'username': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        await fetchCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
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
    await ApiClient.clearToken();
    _user = null;
    notifyListeners();
  }
}
