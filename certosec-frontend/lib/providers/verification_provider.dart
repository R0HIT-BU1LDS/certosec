import 'package:flutter/foundation.dart';

import '../models/verification_result.dart';
import '../repositories/verification_repository.dart';
import '../services/api/api_exception.dart';

/// VerificationProvider powers the public certificate verification screens.
///
/// It holds exactly one in-flight verification: the latest [result], whether a
/// request is [isLoading], and the [errorMessage] when the backend could not be
/// reached. A new verification always resets the previous result.
class VerificationProvider extends ChangeNotifier {
  VerificationProvider(this._repository);

  final VerificationRepository _repository;

  VerificationResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  VerificationResult? get result => _result;
  bool get isLoading => _isLoading;
  bool get hasResult => _result != null;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> verifyByUid(String uid) {
    return _verify(() => _repository.verifyByUid(uid));
  }

  Future<void> verifyByTxHash(String txHash) {
    return _verify(() => _repository.verifyByTxHash(txHash));
  }

  /// Dispatches to the UID or transaction-hash path based on which value is
  /// present. Exactly one should be non-empty.
  Future<void> verify(String uid, String txHash) {
    if (txHash.isNotEmpty) return verifyByTxHash(txHash);
    return verifyByUid(uid);
  }

  /// Runs a single verification, guarding against duplicate in-flight requests
  /// and always resetting the previous result before the next check.
  Future<void> _verify(Future<VerificationResult> Function() run) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      _result = await run();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Could not verify the certificate. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
