import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../services/api_client.dart';

class TeamProvider with ChangeNotifier {
  List<Team> _teams = [];
  Team? _currentTeam;
  bool _isLoading = false;
  String? _error;

  List<Team> get teams => _teams;
  Team? get currentTeam => _currentTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/teams');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _teams = data.map((json) => Team.fromJson(json)).toList();
      } else {
        _error = 'Failed to load teams';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTeamDetail(String teamId) async {
    try {
      final response = await ApiClient.get('/teams/$teamId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentTeam = Team.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching team detail: $e');
    }
  }

  void clearCurrentTeam() {
    _currentTeam = null;
    notifyListeners();
  }
}
