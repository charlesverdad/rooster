import 'package:flutter/foundation.dart';
import '../models/organisation.dart';
import '../services/organisation_service.dart';

class OrganisationProvider with ChangeNotifier {
  List<Organisation> _organisations = [];
  List<OrganisationMember> _members = [];
  bool _isLoading = false;
  String? _error;

  List<Organisation> get organisations => _organisations;
  List<OrganisationMember> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// The current (primary) organisation: first non-personal org, or first org.
  Organisation? get currentOrganisation {
    if (_organisations.isEmpty) return null;
    for (final org in _organisations) {
      if (!org.isPersonal) return org;
    }
    return _organisations.first;
  }

  /// Whether the current user is admin of the current organisation.
  bool get isOrgAdmin => currentOrganisation?.isAdmin ?? false;

  /// Whether the user has at least one non-personal (named) org.
  bool get hasNamedOrg => _organisations.any((o) => !o.isPersonal);

  /// Load organisations from auth response data (called after login).
  void loadOrganisations(List<Organisation> orgs) {
    _organisations = orgs;
    notifyListeners();
  }

  /// Fetch organisations from the API.
  Future<void> fetchOrganisations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _organisations = await OrganisationService.getMyOrganisations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch members of a specific organisation.
  Future<void> fetchMembers(String orgId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _members = await OrganisationService.getMembers(orgId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an organisation's name.
  Future<bool> updateOrganisation(String orgId, {required String name}) async {
    try {
      final updated = await OrganisationService.updateOrganisation(
        orgId,
        name: name,
      );
      final idx = _organisations.indexWhere((o) => o.id == orgId);
      if (idx >= 0) {
        _organisations[idx] = Organisation(
          id: updated.id,
          name: updated.name,
          role: _organisations[idx].role,
          isPersonal: false,
          createdAt: _organisations[idx].createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a member's role.
  Future<bool> updateMemberRole(
    String orgId,
    String userId,
    String role,
  ) async {
    try {
      await OrganisationService.updateMemberRole(orgId, userId, role);
      await fetchMembers(orgId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove a member from the organisation.
  Future<bool> removeMember(String orgId, String userId) async {
    try {
      await OrganisationService.removeMember(orgId, userId);
      _members.removeWhere((m) => m.userId == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an organisation.
  Future<bool> deleteOrganisation(String orgId) async {
    try {
      await OrganisationService.deleteOrganisation(orgId);
      _organisations.removeWhere((o) => o.id == orgId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clear() {
    _organisations = [];
    _members = [];
    _error = null;
    notifyListeners();
  }
}
