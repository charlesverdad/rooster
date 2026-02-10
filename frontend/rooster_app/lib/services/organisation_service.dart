import 'dart:convert';
import '../models/organisation.dart';
import 'api_client.dart';

class OrganisationService {
  static Future<List<Organisation>> getMyOrganisations() async {
    final response = await ApiClient.get('/organisations');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Organisation.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Organisation> getOrganisation(String orgId) async {
    final response = await ApiClient.get('/organisations/$orgId');

    if (response.statusCode == 200) {
      return Organisation.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<Organisation> updateOrganisation(
    String orgId, {
    required String name,
  }) async {
    final response = await ApiClient.patch('/organisations/$orgId', {
      'name': name,
    });

    if (response.statusCode == 200) {
      return Organisation.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> deleteOrganisation(String orgId) async {
    final response = await ApiClient.delete(
      '/organisations/$orgId?confirm=true',
    );

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<List<OrganisationMember>> getMembers(String orgId) async {
    final response = await ApiClient.get('/organisations/$orgId/members');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrganisationMember.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<OrganisationMember> addMember(
    String orgId,
    String userId, {
    String role = 'member',
  }) async {
    final response = await ApiClient.post('/organisations/$orgId/members', {
      'user_id': userId,
      'role': role,
    });

    if (response.statusCode == 201) {
      return OrganisationMember.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<OrganisationMember> updateMemberRole(
    String orgId,
    String userId,
    String role,
  ) async {
    final response = await ApiClient.patch(
      '/organisations/$orgId/members/$userId',
      {'role': role},
    );

    if (response.statusCode == 200) {
      return OrganisationMember.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  static Future<void> removeMember(String orgId, String userId) async {
    final response = await ApiClient.delete(
      '/organisations/$orgId/members/$userId',
    );

    if (response.statusCode != 204) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
