import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_enums.dart';
import '../models/certificate.dart';
import '../repositories/certificate_repository.dart';
import '../services/api/api_exception.dart';

/// CertificatesProvider owns the paginated, searchable certificate ledger.
///
/// Mirrors the StudentsProvider contract: [search] and [status] are applied
/// server-side and reset to page 1, [nextPage] accumulates pages, and issuing
/// a certificate returns a bool the screen uses to decide whether to continue.
class CertificatesProvider extends ChangeNotifier {
  CertificatesProvider(this._repository);

  final CertificateRepository _repository;

  static const int pageSize = AppConfig.defaultPageSize;

  List<Certificate> _certificates = const [];
  int _total = 0;
  int _page = 1;
  int _totalPages = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isBusy = false;
  String? _errorMessage;
  String _search = '';
  CertificateStatus? _status;

  List<Certificate> get certificates => _certificates;
  int get total => _total;
  int get page => _page;
  int get totalPages => _totalPages;
  bool get hasMore => _page < _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String get search => _search;
  CertificateStatus? get status => _status;
  bool get isFiltering => _search.isNotEmpty || _status != null;
  bool get hasError => _errorMessage != null;

  /// Lookup used by the details screen before it falls back to the single
  /// certificate endpoint. Matches by uid (stable public identifier).
  Certificate? certificateByUid(String uid) {
    for (final certificate in _certificates) {
      if (certificate.uid == uid) return certificate;
    }
    return null;
  }

  /// Fetches a single certificate (deep-link path) and merges it into the list.
  Future<void> fetchCertificate(String uid) async {
    if (_isLoading || _isLoadingMore) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final certificate = await _repository.fetchCertificate(uid);
      final index = _certificates.indexWhere((c) => c.uid == uid);
      if (index >= 0) {
        final updated = [..._certificates];
        updated[index] = certificate;
        _certificates = updated;
      } else {
        _certificates = [certificate, ..._certificates];
      }
      if (_certificates.length > _total) _total = _certificates.length;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Something went wrong loading the certificate.';
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

  Future<void> setStatus(CertificateStatus? status) {
    if (status == _status) return Future.value();
    _status = status;
    return _loadPage(1);
  }

  /// Requests a new certificate. On success the created certificate is merged
  /// into the ledger so the details screen can render it immediately.
  Future<Certificate?> issueCertificate(CertificateDraft draft) async {
    if (_isBusy) return null;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final certificate = await _repository.issueCertificate(draft);
      _certificates = [certificate, ..._certificates];
      _total += 1;
      return certificate;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return null;
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
      final result = await _repository.fetchCertificates(
        page: page,
        pageSize: pageSize,
        search: _search.isEmpty ? null : _search,
        status: _status?.name,
      );
      _certificates = append ? [..._certificates, ...result.items] : result.items;
      _total = result.total;
      _page = result.page;
      _totalPages = result.totalPages;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Something went wrong loading certificates.';
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
