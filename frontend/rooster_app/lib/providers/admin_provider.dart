import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _users = [];
  Map<String, dynamic>? _selectedUser;
  Map<String, dynamic>? _config;
  List<dynamic> _organisations = [];

  bool _loadingStats = false;
  bool _loadingUsers = false;
  bool _loadingUserDetail = false;
  bool _loadingConfig = false;
  bool _loadingOrgs = false;
  bool _savingConfig = false;

  String? _statsError;
  String? _usersError;
  String? _userDetailError;
  String? _configError;
  String? _orgsError;

  int _usersTotal = 0;
  int _usersPage = 1;
  int _usersPages = 1;

  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  List<dynamic> get users => _users;
  Map<String, dynamic>? get selectedUser => _selectedUser;
  Map<String, dynamic>? get config => _config;
  List<dynamic> get organisations => _organisations;

  bool get loadingStats => _loadingStats;
  bool get loadingUsers => _loadingUsers;
  bool get loadingUserDetail => _loadingUserDetail;
  bool get loadingConfig => _loadingConfig;
  bool get loadingOrgs => _loadingOrgs;
  bool get savingConfig => _savingConfig;

  String? get statsError => _statsError;
  String? get usersError => _usersError;
  String? get userDetailError => _userDetailError;
  String? get configError => _configError;
  String? get orgsError => _orgsError;

  int get usersTotal => _usersTotal;
  int get usersPage => _usersPage;
  int get usersPages => _usersPages;

  Future<void> fetchDashboardStats() async {
    _loadingStats = true;
    _statsError = null;
    notifyListeners();

    try {
      _dashboardStats = await AdminService.getDashboardStats();
    } catch (e) {
      _statsError = e.toString();
    }

    _loadingStats = false;
    notifyListeners();
  }

  Future<void> fetchUsers({
    String? search,
    String? status,
    int page = 1,
    String? sort,
    String? order,
  }) async {
    _loadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      final data = await AdminService.getUsers(
        search: search,
        status: status,
        page: page,
        sort: sort,
        order: order,
      );
      _users = data['users'] as List<dynamic>? ?? [];
      _usersTotal = data['total'] as int? ?? 0;
      _usersPage = data['page'] as int? ?? 1;
      _usersPages = data['pages'] as int? ?? 1;
    } catch (e) {
      _usersError = e.toString();
    }

    _loadingUsers = false;
    notifyListeners();
  }

  Future<void> fetchUserDetail(String userId) async {
    _loadingUserDetail = true;
    _userDetailError = null;
    notifyListeners();

    try {
      _selectedUser = await AdminService.getUserDetail(userId);
    } catch (e) {
      _userDetailError = e.toString();
    }

    _loadingUserDetail = false;
    notifyListeners();
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      await AdminService.deactivateUser(userId);
      await fetchUserDetail(userId);
      return true;
    } catch (e) {
      _userDetailError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reactivateUser(String userId) async {
    try {
      await AdminService.reactivateUser(userId);
      await fetchUserDetail(userId);
      return true;
    } catch (e) {
      _userDetailError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> promoteAdmin(String userId) async {
    try {
      await AdminService.promoteAdmin(userId);
      await fetchUserDetail(userId);
      return true;
    } catch (e) {
      _userDetailError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> demoteAdmin(String userId) async {
    try {
      await AdminService.demoteAdmin(userId);
      await fetchUserDetail(userId);
      return true;
    } catch (e) {
      _userDetailError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchConfig() async {
    _loadingConfig = true;
    _configError = null;
    notifyListeners();

    try {
      _config = await AdminService.getConfig();
    } catch (e) {
      _configError = e.toString();
    }

    _loadingConfig = false;
    notifyListeners();
  }

  Future<bool> updateConfig(Map<String, dynamic> data) async {
    _savingConfig = true;
    _configError = null;
    notifyListeners();

    try {
      await AdminService.updateConfig(data);
      await fetchConfig();
      _savingConfig = false;
      notifyListeners();
      return true;
    } catch (e) {
      _configError = e.toString();
      _savingConfig = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchOrganisations({String? search, int page = 1}) async {
    _loadingOrgs = true;
    _orgsError = null;
    notifyListeners();

    try {
      final data = await AdminService.getOrganisations(
        search: search,
        page: page,
      );
      _organisations = data['organisations'] as List<dynamic>? ?? [];
    } catch (e) {
      _orgsError = e.toString();
    }

    _loadingOrgs = false;
    notifyListeners();
  }

  void clearSelectedUser() {
    _selectedUser = null;
    notifyListeners();
  }
}
