import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../models/student.dart';
import '../models/student_draft.dart';
import '../repositories/student_repository.dart';
import '../services/api/api_exception.dart';

/// StudentsProvider owns the paginated, searchable student directory.
///
/// The screen renders whatever this provider holds:
/// - [_students] is the currently visible page (or the accumulated pages when
///   navigating forward with nextPage).
/// - [search] and [department] are applied server-side; changing either resets
///   to page 1.
/// - Mutations (add/update/delete) return a bool the screen uses to decide
///   whether to pop, and always refresh the current page afterwards so the
///   list reflects server truth.
class StudentsProvider extends ChangeNotifier {
  StudentsProvider(this._repository);

  final StudentRepository _repository;

  static const int pageSize = AppConfig.defaultPageSize;

  List<Student> _students = const [];
  int _total = 0;
  int _page = 1;
  int _totalPages = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isBusy = false;
  String? _errorMessage;
  String _search = '';
  String? _department;

  List<Student> get students => _students;
  int get total => _total;
  int get page => _page;
  int get totalPages => _totalPages;
  bool get hasMore => _page < _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  String? get department => _department;
  bool get isFiltering => _search.isNotEmpty || _department != null;
  bool get hasError => _errorMessage != null;

  /// Lookup used by the details screen before it decides to fall back to the
  /// single-student endpoint.
  Student? studentById(String id) {
    for (final student in _students) {
      if (student.id == id) return student;
    }
    return null;
  }

  /// Fetches a single student (deep-link path) and merges it into the list so
  /// subsequent reads hit the cache.
  Future<void> fetchStudent(String id) async {
    if (_isLoading || _isLoadingMore) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final student = await _repository.fetchStudent(id);
      final index = _students.indexWhere((s) => s.id == id);
      if (index >= 0) {
        final updated = [..._students];
        updated[index] = student;
        _students = updated;
      } else {
        _students = [student, ..._students];
      }
      if (_students.length > _total) _total = _students.length;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Something went wrong loading the student.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitial() => _loadPage(1);

  Future<void> reload() => _loadPage(_page);

  Future<void> nextPage() => _loadPage(_page + 1, append: true);

  Future<void> previousPage() => _loadPage(_page - 1);

  Future<void> setSearch(String query) {
    final normalized = query.trim();
    if (normalized == _search) return Future.value();
    _search = normalized;
    return _loadPage(1);
  }

  Future<void> setDepartment(String? department) {
    if (department == _department) return Future.value();
    _department = department;
    return _loadPage(1);
  }

  Future<bool> addStudent(StudentDraft draft) async {
    if (_isBusy) return false;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createStudent(draft);
      await _loadPage(_page);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> updateStudent(String id, StudentDraft draft) async {
    if (_isBusy) return false;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateStudent(id, draft);
      await _loadPage(_page);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> deleteStudent(String id) async {
    if (_isBusy) return false;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteStudent(id);
      // Deleting the last row of the last page would show an empty page;
      // step back one page in that case.
      final targetPage = (_students.length == 1 && _page > 1)
          ? _page - 1
          : _page;
      await _loadPage(targetPage);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _loadPage(int page, {bool append = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (page < 1) return;

    if (append) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final result = await _repository.fetchStudents(
        page: page,
        pageSize: pageSize,
        search: _search.isEmpty ? null : _search,
        department: _department,
      );
      _students = append ? [..._students, ...result.items] : result.items;
      _total = result.total;
      _page = result.page;
      _totalPages = result.totalPages;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Something went wrong loading students.';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
