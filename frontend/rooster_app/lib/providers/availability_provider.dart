import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/unavailability.dart';
import '../services/api_client.dart';

class AvailabilityProvider with ChangeNotifier {
  List<Unavailability> _unavailabilities = [];
  List<Conflict> _conflicts = [];
  bool _isLoading = false;
  String? _error;

  List<Unavailability> get unavailabilities => _unavailabilities;
  List<Conflict> get conflicts => _conflicts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUnavailabilities() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/availability/me');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _unavailabilities = data
            .map((json) => Unavailability.fromJson(json))
            .toList();
        _unavailabilities.sort((a, b) => a.date.compareTo(b.date));
      } else {
        _error = 'Failed to load unavailabilities';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchConflicts() async {
    try {
      final response = await ApiClient.get('/availability/conflicts');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _conflicts = data.map((json) => Conflict.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching conflicts: $e');
    }
  }

  Future<bool> markUnavailable(DateTime date, String? reason) async {
    try {
      final response = await ApiClient.post('/availability', {
        'date': date.toIso8601String().split('T')[0],
        'reason': reason,
      });

      if (response.statusCode == 201) {
        await fetchUnavailabilities();
        await fetchConflicts();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _error = data['detail'] ?? 'Failed to mark unavailable';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUnavailability(String id) async {
    try {
      final response = await ApiClient.delete('/availability/$id');

      if (response.statusCode == 204) {
        await fetchUnavailabilities();
        await fetchConflicts();
        return true;
      } else {
        _error = 'Failed to delete unavailability';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error: $e';
      notifyListeners();
      return false;
    }
  }
}
