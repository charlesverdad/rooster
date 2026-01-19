import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../services/api_client.dart';

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
      final response = await ApiClient.get('/rosters/assignments/my');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _assignments = data.map((json) => Assignment.fromJson(json)).toList();
        _assignments.sort((a, b) => a.date.compareTo(b.date));
      } else {
        _error = 'Failed to load assignments';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
