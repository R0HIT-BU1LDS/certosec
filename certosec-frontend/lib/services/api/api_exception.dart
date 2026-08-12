/// Categories of failure the API layer can produce. UI code switches on
/// [ApiException.kind] to decide what the user should see and whether the
/// session should be invalidated.
enum ApiExceptionKind {
  network,
  timeout,
  validation,
  unauthorized,
  forbidden,
  notFound,
  server,
  unknown,
}

/// ApiException is the single error type raised by the API layer.
///
/// Every network problem, HTTP error status, or malformed response is
/// normalized into one of these. `message` is always a human-readable string
/// suitable for direct display; `fieldErrors` (when present) maps input field
/// names to server-provided validation messages.
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final ApiExceptionKind kind;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isNetworkFailure =>
      kind == ApiExceptionKind.network || kind == ApiExceptionKind.timeout;

  /// Thrown when the server never responds (DNS, refused, reset).
  factory ApiException.network() => const ApiException(
    kind: ApiExceptionKind.network,
    message: 'Unable to reach the server. Check your internet connection.',
  );

  /// Thrown when a request exceeds the configured timeout.
  factory ApiException.timeout() => const ApiException(
    kind: ApiExceptionKind.timeout,
    message: 'The server took too long to respond. Please try again.',
  );

  factory ApiException.validation({
    String message = 'Please correct the highlighted fields.',
    Map<String, String> fieldErrors = const {},
  }) => ApiException(
    kind: ApiExceptionKind.validation,
    message: message,
    fieldErrors: fieldErrors,
  );

  factory ApiException.unauthorized([String? message]) => ApiException(
    kind: ApiExceptionKind.unauthorized,
    message: message ?? 'Your session has expired. Please sign in again.',
  );

  factory ApiException.forbidden([String? message]) => ApiException(
    kind: ApiExceptionKind.forbidden,
    message: message ?? 'You do not have permission to do that.',
  );

  factory ApiException.notFound([String? message]) => ApiException(
    kind: ApiExceptionKind.notFound,
    message: message ?? 'The requested resource was not found.',
  );

  factory ApiException.server([String? message]) => ApiException(
    kind: ApiExceptionKind.server,
    message: message ?? 'The server encountered an error. Try again later.',
  );

  factory ApiException.unknown([String? message]) => ApiException(
    kind: ApiExceptionKind.unknown,
    message: message ?? 'Something went wrong. Please try again.',
  );

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
