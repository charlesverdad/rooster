import 'dart:convert';
import '../models/swap_request.dart';
import '../models/user.dart';
import 'api_client.dart';

class SwapRequestService {
  /// Create a new swap request
  static Future<SwapRequest> createSwapRequest(
    String assignmentId,
    String targetUserId,
  ) async {
    final response = await ApiClient.post(
      '/rosters/swap-requests',
      {
        'requester_assignment_id': assignmentId,
        'target_user_id': targetUserId,
      },
    );

    if (response.statusCode == 201) {
      return SwapRequest.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get all swap requests for the current user
  static Future<List<SwapRequest>> getMySwapRequests({
    String? status,
  }) async {
    var endpoint = '/rosters/swap-requests/my';

    if (status != null) {
      endpoint += '?status=$status';
    }

    final response = await ApiClient.get(endpoint);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SwapRequest.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get a specific swap request by ID
  static Future<SwapRequest> getSwapRequest(String swapRequestId) async {
    final response = await ApiClient.get(
      '/rosters/swap-requests/$swapRequestId',
    );

    if (response.statusCode == 200) {
      return SwapRequest.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Accept a swap request
  static Future<SwapRequest> acceptSwapRequest(String swapRequestId) async {
    final response = await ApiClient.post(
      '/rosters/swap-requests/$swapRequestId/accept',
      {},
    );

    if (response.statusCode == 200) {
      return SwapRequest.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Decline a swap request
  static Future<SwapRequest> declineSwapRequest(String swapRequestId) async {
    final response = await ApiClient.post(
      '/rosters/swap-requests/$swapRequestId/decline',
      {},
    );

    if (response.statusCode == 200) {
      return SwapRequest.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Get eligible swap targets for a specific assignment
  static Future<List<User>> getEligibleSwapTargets(
    String assignmentId,
  ) async {
    final response = await ApiClient.get(
      '/rosters/event-assignments/$assignmentId/eligible-swap-targets',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }
}
