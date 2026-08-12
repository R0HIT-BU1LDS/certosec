import 'package:flutter/foundation.dart';

import '../models/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';
import '../services/api/api_exception.dart';

/// DashboardProvider owns the home screen's aggregate statistics.
///
/// It loads the stats exactly once per session ([load] short-circuits when
/// data is already present unless [force] is passed, which the pull-to-refresh
/// and the retry button use).
class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._repository);

  final DashboardRepository _repository;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoaded => _stats != null;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (!force && _stats != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _repository.fetchStats();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Something went wrong loading statistics.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
