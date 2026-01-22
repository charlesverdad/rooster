import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/team_member.dart';
import '../services/team_service.dart';
import '../services/invite_service.dart';

class TeamProvider with ChangeNotifier {
  List<Team> _teams = [];
  Team? _currentTeam;
  List<TeamMember> _currentTeamMembers = [];
  bool _isLoading = false;
  String? _error;

  List<Team> get teams => _teams;
  Team? get currentTeam => _currentTeam;
  List<TeamMember> get currentTeamMembers => _currentTeamMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // For backward compatibility - convert TeamMember list to Map format
  List<Map<String, dynamic>> get currentTeamMembersAsMap =>
      _currentTeamMembers.map((m) => m.toMap()).toList();

  Future<void> fetchMyTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teams = await TeamService.getMyTeams();
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching teams: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new team. Returns the created team or null on error.
  Future<Team?> createTeam(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final team = await TeamService.createTeam(name);
      _teams.add(team);
      _isLoading = false;
      notifyListeners();
      return team;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error creating team: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchTeamDetail(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch team and members in parallel
      final results = await Future.wait([
        TeamService.getTeam(teamId),
        TeamService.getTeamMembers(teamId),
      ]);

      _currentTeam = results[0] as Team;
      _currentTeamMembers = results[1] as List<TeamMember>;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error fetching team detail: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTeamMembers(String teamId) async {
    try {
      _currentTeamMembers = await TeamService.getTeamMembers(teamId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching team members: $e');
    }
  }

  Future<bool> addMember(String teamId, String name) async {
    try {
      final newMember = await TeamService.addPlaceholderMember(teamId, name);
      _currentTeamMembers.add(newMember);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error adding member: $e');
      return false;
    }
  }

  Future<bool> sendInvite(String memberId, String email) async {
    if (_currentTeam == null) return false;

    try {
      await InviteService.sendInvite(_currentTeam!.id, memberId, email);

      // Update the member's invite status locally
      final index = _currentTeamMembers.indexWhere((m) => m.userId == memberId);
      if (index != -1) {
        final member = _currentTeamMembers[index];
        _currentTeamMembers[index] = member.copyWith(
          userEmail: email,
          isInvited: true,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error sending invite: $e');
      return false;
    }
  }

  Future<bool> removeMember(String teamId, String userId) async {
    try {
      await TeamService.removeMember(teamId, userId);
      _currentTeamMembers.removeWhere((m) => m.userId == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      debugPrint('Error removing member: $e');
      return false;
    }
  }

  void clearCurrentTeam() {
    _currentTeam = null;
    _currentTeamMembers = [];
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
