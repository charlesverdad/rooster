import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../mock_data/mock_data.dart';

class AssignmentProvider with ChangeNotifier {
  List<Assignment> _assignments = [];
  bool _isLoading = false;
  String? _error;

  List<Assignment> get assignments => _assignments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use mock data instead of API
      _assignments = MockData.assignments;
      _assignments.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateAssignmentStatus(String assignmentId, String status) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Update local state
      final index = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _assignments[index] = Assignment(
          id: _assignments[index].id,
          userId: _assignments[index].userId,
          rosterId: _assignments[index].rosterId,
          rosterName: _assignments[index].rosterName,
          date: _assignments[index].date,
          status: status,
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
      return false;
    }
  }
}
