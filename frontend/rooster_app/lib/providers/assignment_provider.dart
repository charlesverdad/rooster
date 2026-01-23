import 'package:flutter/foundation.dart';
import '../models/event_assignment.dart';
import '../services/api_client.dart';
import '../services/assignment_service.dart';

class AssignmentProvider with ChangeNotifier {
  List<EventAssignment> _assignments = [];
  EventAssignmentDetail? _currentAssignmentDetail;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;

  List<EventAssignment> get assignments => _assignments;
  EventAssignmentDetail? get currentAssignmentDetail => _currentAssignmentDetail;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;

  // Computed properties
  List<EventAssignment> get pendingAssignments =>
      _assignments.where((a) => a.isPending).toList();
  List<EventAssignment> get upcomingAssignments =>
      _assignments.where((a) => a.isConfirmed).toList();

  Future<void> fetchMyAssignments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignments = await AssignmentService.getMyAssignments(
        startDate: startDate,
        endDate: endDate,
      );
      // Sort by event date (from EventAssignment metadata if available)
      // Since basic assignment response doesn't have event_date, keep as-is
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching assignments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAssignmentDetail(String assignmentId) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      _currentAssignmentDetail =
          await AssignmentService.getAssignmentDetail(assignmentId);
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching assignment detail: $e');
    }

    _isLoadingDetail = false;
    notifyListeners();
  }

  Future<bool> updateAssignmentStatus(
      String assignmentId, String status) async {
    try {
      final updated =
          await AssignmentService.updateAssignmentStatus(assignmentId, status);

      // Update local state
      final index = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _assignments[index] = updated;
      }

      // Update detail if it's the current one
      if (_currentAssignmentDetail?.id == assignmentId) {
        // Re-fetch detail to get updated data
        await fetchAssignmentDetail(assignmentId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error updating assignment status: $e');
      return false;
    }
  }

  Future<bool> confirmAssignment(String assignmentId) async {
    return await updateAssignmentStatus(assignmentId, 'confirmed');
  }

  Future<bool> declineAssignment(String assignmentId) async {
    return await updateAssignmentStatus(assignmentId, 'declined');
  }

  void clearCurrentDetail() {
    _currentAssignmentDetail = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }
}
