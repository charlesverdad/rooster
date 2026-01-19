import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  static String? _token;

  static bool get hasToken => _token != null;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.get(url, headers: _getHeaders()).timeout(ApiConfig.timeout);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(ApiConfig.timeout);
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.patch(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    ).timeout(ApiConfig.timeout);
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await http.delete(url, headers: _getHeaders()).timeout(ApiConfig.timeout);
  }
}
