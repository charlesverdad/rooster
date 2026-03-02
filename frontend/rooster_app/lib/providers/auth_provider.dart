import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/auth_config.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/push_service.dart';
import '../providers/organisation_provider.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  OrganisationProvider? _orgProvider;
  AuthConfig _authConfig = AuthConfig.defaults();
  bool _setupRequired = false;
  bool _setupChecked = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  AuthConfig get authConfig => _authConfig;
  bool get setupRequired => _setupRequired;
  bool get setupChecked => _setupChecked;

  void setOrgProvider(OrganisationProvider provider) {
    _orgProvider = provider;
  }

  Future<void> init() async {
    // Fetch auth config and setup status in the background — don't block initialization.
    // Login screen renders with defaults (email enabled) and updates when
    // the config arrives.
    _fetchAuthConfig();
    _fetchSetupRequired();
    await ApiClient.loadToken();
    if (ApiClient.hasToken) {
      await fetchCurrentUser();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _fetchSetupRequired() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/auth/setup-required'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _setupRequired = data['setup_required'] == true;
      }
    } catch (e) {
      debugPrint('Error fetching setup status: $e');
      // Fail-safe: treat as not required
      _setupRequired = false;
    }
    _setupChecked = true;
    notifyListeners();
  }

  Future<bool> setup(
    String name,
    String email,
    String password,
    String? organisationName,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      };
      if (organisationName != null && organisationName.isNotEmpty) {
        body['organisation_name'] = organisationName;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/setup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiClient.saveToken(data['access_token']);
        _setupRequired = false;
        await fetchCurrentUser();
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (response.statusCode == 409) {
        _setupRequired = false;
        _error = 'Setup is already complete.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? 'Setup failed';
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

  Future<void> _fetchAuthConfig() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/auth/config'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _authConfig = AuthConfig.fromJson(jsonDecode(response.body));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching auth config: $e');
    }
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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final clientId = _authConfig.googleClientId ?? ApiConfig.googleClientId;
      final googleSignIn = GoogleSignIn(
        clientId: clientId.isNotEmpty ? clientId : null,
        scopes: ['email', 'profile'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _error = 'Could not get Google ID token';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id_token': idToken}),
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
          debugPrint('Error re-subscribing push on Google login: $e');
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? 'Google login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Google login error: $e';
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
        _orgProvider?.loadOrganisations(_user!.organisations);
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
