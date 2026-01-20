import 'package:flutter/foundation.dart';
import '../mock_data/mock_data.dart';

class TeamProvider with ChangeNotifier {
  List<Map<String, dynamic>> _teams = [];
  Map<String, dynamic>? _currentTeam;
  List<Map<String, dynamic>> _currentTeamMembers = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get teams => _teams;
  Map<String, dynamic>? get currentTeam => _currentTeam;
  List<Map<String, dynamic>> get currentTeamMembers => _currentTeamMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use mock data
      _teams = MockData.teams;
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTeamDetail(String teamId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      _currentTeam = MockData.teams.firstWhere((t) => t['id'] == teamId);
      _currentTeamMembers = MockData.teamMembers;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching team detail: $e');
    }
  }

  Future<bool> addMember(String teamId, String name) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Add to local state
      final newMember = {
        'id': 'user${_currentTeamMembers.length + 1}',
        'name': name,
        'email': null,
        'phone': null,
        'role': 'Member',
        'isPlaceholder': true,
        'isInvited': false,
      };
      
      _currentTeamMembers.add(newMember);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding member: $e');
      return false;
    }
  }

  Future<bool> sendInvite(String memberId, String email) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Update member status
      final index = _currentTeamMembers.indexWhere((m) => m['id'] == memberId);
      if (index != -1) {
        _currentTeamMembers[index] = {
          ..._currentTeamMembers[index],
          'email': email,
          'isInvited': true,
        };
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error sending invite: $e');
      return false;
    }
  }

  void clearCurrentTeam() {
    _currentTeam = null;
    _currentTeamMembers = [];
    notifyListeners();
  }
}
