import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Custom exception for API errors with status code and message
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? detail;

  ApiException(this.statusCode, String body)
    : message = _parseMessage(statusCode, body),
      detail = _parseDetail(body);

  static String _parseMessage(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'You don\'t have permission to do this.';
      case 404:
        return 'Not found.';
      case 422:
        return _parseValidationError(body);
      case 500:
        return 'Server error. Please try again later.';
      default:
        return _parseDetail(body) ?? 'Request failed ($statusCode)';
    }
  }

  static String? _parseDetail(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json.containsKey('detail')) {
        final detail = json['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
      }
    } catch (_) {}
    return null;
  }

  static String _parseValidationError(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json.containsKey('detail')) {
        final detail = json['detail'];
        if (detail is List && detail.isNotEmpty) {
          return detail.map((e) => e['msg'] ?? e.toString()).join(', ');
        }
        if (detail is String) return detail;
      }
    } catch (_) {}
    return 'Invalid data submitted.';
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => message;
}

/// Exception for network/connection errors
class NetworkException implements Exception {
  final String message;
  final dynamic originalError;

  NetworkException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Callback for handling 401 unauthorized responses (e.g., redirect to login)
typedef OnUnauthorizedCallback = void Function();

class ApiClient {
  static String? _token;
  static OnUnauthorizedCallback? _onUnauthorized;

  static bool get hasToken => _token != null;

  /// Set a callback to be called when a 401 response is received
  static void setOnUnauthorized(OnUnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }

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
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<http.Response> _handleResponse(
    Future<http.Response> request,
  ) async {
    try {
      final response = await request;

      // Handle 401 unauthorized - clear token and notify
      if (response.statusCode == 401) {
        await clearToken();
        _onUnauthorized?.call();
      }

      return response;
    } on SocketException catch (e) {
      debugPrint('Network error: $e');
      throw NetworkException(
        'Unable to connect. Please check your internet connection.',
        e,
      );
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      throw NetworkException('Request timed out. Please try again.', e);
    } on http.ClientException catch (e) {
      debugPrint('Client error: $e');
      throw NetworkException('Connection error. Please try again.', e);
    }
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await _handleResponse(
      http.get(url, headers: _getHeaders()).timeout(ApiConfig.timeout),
    );
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await _handleResponse(
      http
          .post(url, headers: _getHeaders(), body: jsonEncode(body))
          .timeout(ApiConfig.timeout),
    );
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await _handleResponse(
      http
          .patch(url, headers: _getHeaders(), body: jsonEncode(body))
          .timeout(ApiConfig.timeout),
    );
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return await _handleResponse(
      http.delete(url, headers: _getHeaders()).timeout(ApiConfig.timeout),
    );
  }
}
