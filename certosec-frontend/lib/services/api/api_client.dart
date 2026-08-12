import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import 'api_exception.dart';

/// Lightweight result wrapper: a decoded JSON payload plus its HTTP status.
class ApiResponse {
  const ApiResponse({required this.statusCode, this.data});

  final int statusCode;
  final Object? data;
}

/// ApiClient is the thin, reusable HTTP boundary of the application.
///
/// Responsibilities:
/// - Build URIs from the configured base URL.
/// - Inject the `Authorization: Bearer <token>` header when a token is
///   available (the token is read via [accessTokenProvider] on every request,
///   so it is always fresh — never cached in the client).
/// - Encode/decode JSON with correct UTF-8 handling.
/// - Normalize every failure into an [ApiException]: transport errors become
///   `network`/`timeout`, and non-2xx responses are parsed for the server's
///   error message and per-field validation errors.
///
/// The client never talks to Supabase or the blockchain directly — it only
/// knows the Express backend.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.timeout = AppConfig.apiTimeout,
    this.accessTokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;

  /// Returns the current access token, or null when signed out. Used to attach
  /// the auth header; implemented by reading from secure storage.
  final Future<String?> Function()? accessTokenProvider;

  final http.Client _httpClient;

  Future<ApiResponse> get(String path, {Map<String, String>? queryParameters}) {
    return _send('GET', path, queryParameters: queryParameters);
  }

  Future<ApiResponse> post(String path, {Object? body}) {
    return _send('POST', path, body: body);
  }

  Future<ApiResponse> put(String path, {Object? body}) {
    return _send('PUT', path, body: body);
  }

  Future<ApiResponse> delete(String path, {Object? body}) {
    return _send('DELETE', path, body: body);
  }

  Future<ApiResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await accessTokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      response = switch (method) {
        'GET' => await _httpClient.get(uri, headers: headers).timeout(timeout),
        'POST' =>
          await _httpClient
              .post(uri, headers: headers, body: encodedBody)
              .timeout(timeout),
        'PUT' =>
          await _httpClient
              .put(uri, headers: headers, body: encodedBody)
              .timeout(timeout),
        'DELETE' =>
          await _httpClient
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(timeout),
        _ => throw ApiException.unknown('Unsupported method: $method'),
      };
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException {
      throw ApiException.network();
    }

    final data = _decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(statusCode: response.statusCode, data: data);
    }

    throw _mapError(response.statusCode, data);
  }

  /// Decodes the response body as JSON when possible, otherwise returns the
  /// raw text. Empty bodies (e.g. 204) decode to null.
  Object? _decode(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return null;
    final text = utf8.decode(bodyBytes, allowMalformed: true);
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  ApiException _mapError(int statusCode, Object? data) {
    final (message, fieldErrors) = _extractServerError(data);

    switch (statusCode) {
      case 400:
      case 422:
        return ApiException.validation(
          message: message ?? 'Please correct the highlighted fields.',
          fieldErrors: fieldErrors,
        );
      case 401:
        return ApiException.unauthorized(message);
      case 403:
        return ApiException.forbidden(message);
      case 404:
        return ApiException.notFound(message);
      default:
        if (statusCode >= 500) {
          return ApiException.server(message);
        }
        return ApiException.unknown(message);
    }
  }

  /// Extracts a human-readable message and per-field validation errors from a
  /// typical Express error body. Supports several common shapes:
  ///   {"message": "..."}
  ///   {"error": "..."}  or  {"error": {"message": "..."}}
  ///   {"detail": "..."}
  ///   {"errors": {"email": "..."}}
  ///   {"fieldErrors": {"email": "..."}}
  (String?, Map<String, String>) _extractServerError(Object? data) {
    if (data is! Map<String, dynamic>) return (null, const {});

    String? message;
    Object? errorValue = data['message'] ?? data['detail'] ?? data['error'];
    if (errorValue is String) {
      message = errorValue;
    } else if (errorValue is Map<String, dynamic>) {
      final nested = errorValue['message'];
      if (nested is String) message = nested;
    }

    final fieldErrors = <String, String>{};
    final errorsValue = data['errors'] ?? data['fieldErrors'];
    if (errorsValue is Map<String, dynamic>) {
      errorsValue.forEach((field, raw) {
        final value = raw is String
            ? raw
            : raw is List
            ? raw.whereType<String>().join(', ')
            : raw?.toString();
        if (value != null && value.isNotEmpty) {
          fieldErrors[field] = value;
        }
      });
    }

    return (message, fieldErrors);
  }
}
