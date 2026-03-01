import 'dart:convert';
import 'api_client.dart';

class AdminService {
  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await ApiClient.get('/admin/stats');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Map<String, dynamic>> getUsers({
    String? search,
    String? status,
    int page = 1,
    int perPage = 20,
    String? sort,
    String? order,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (sort != null) params['sort'] = sort;
    if (order != null) params['order'] = order;

    final query = Uri(queryParameters: params).query;
    final response = await ApiClient.get('/admin/users?$query');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Map<String, dynamic>> getUserDetail(String userId) async {
    final response = await ApiClient.get('/admin/users/$userId');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> deactivateUser(String userId) async {
    final response = await ApiClient.post(
      '/admin/users/$userId/deactivate',
      {},
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> reactivateUser(String userId) async {
    final response = await ApiClient.post(
      '/admin/users/$userId/reactivate',
      {},
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> promoteAdmin(String userId) async {
    final response = await ApiClient.post(
      '/admin/users/$userId/promote-admin',
      {},
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> demoteAdmin(String userId) async {
    final response = await ApiClient.post(
      '/admin/users/$userId/demote-admin',
      {},
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Map<String, dynamic>> getConfig() async {
    final response = await ApiClient.get('/admin/config');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> updateConfig(Map<String, dynamic> data) async {
    final response = await ApiClient.put('/admin/config', data);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Map<String, dynamic>> getOrganisations({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;

    final query = Uri(queryParameters: params).query;
    final response = await ApiClient.get('/admin/organisations?$query');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
