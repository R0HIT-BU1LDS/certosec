import 'package:flutter/services.dart';

import '../config/app_config.dart';

/// AppValidators centralizes input validation. Every validator returns `null`
/// when the value is valid, or a human-readable error message otherwise, which
/// is exactly what Flutter's `FormField.validator` expects.
///
/// Keeping validation in one place means UI, providers, and repositories all
/// agree on what a valid email, UID, or transaction hash looks like.
abstract final class AppValidators {
  static final RegExp _emailPattern = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static final RegExp _certificateUidPattern = RegExp(
    r'^CERT-\d{4}-\d{6}$',
    caseSensitive: false,
  );

  static final RegExp _ethHashPattern = RegExp(r'^0x[0-9a-fA-F]{64}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, field: 'Email');
    if (requiredError != null) return requiredError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, field: 'Password');
    if (requiredError != null) return requiredError;
    if (value!.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Accepts `CERT-2026-000001` style UIDs (prefix, year, six-digit sequence).
  static String? certificateUid(String? value) {
    final requiredError = required(value, field: 'Certificate UID');
    if (requiredError != null) return requiredError;
    final normalized = value!.trim().toUpperCase();
    if (!_certificateUidPattern.hasMatch(normalized)) {
      return 'Format: ${AppConfig.certificateUidPrefix}-YYYY-000001';
    }
    return null;
  }

  /// Accepts standard Ethereum transaction hashes: `0x` followed by 64 hex
  /// characters. Polygon hashes share this exact format.
  static String? ethereumTransactionHash(String? value) {
    final requiredError = required(value, field: 'Transaction hash');
    if (requiredError != null) return requiredError;
    if (!_ethHashPattern.hasMatch(value!.trim())) {
      return 'Enter a valid 0x transaction hash (66 characters)';
    }
    return null;
  }

  static String? name(String? value, {String field = 'Name'}) {
    final requiredError = required(value, field: field);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) return '$field must be at least 2 characters';
    return null;
  }

  /// Student roll number, e.g. `CS-2024-001`. Rejects spaces and symbols.
  static String? studentId(String? value) {
    final requiredError = required(value, field: 'Student ID');
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[A-Za-z0-9-]{3,30}$').hasMatch(value!.trim())) {
      return 'Use only letters, numbers, and dashes (3-30 chars)';
    }
    return null;
  }

  /// Batch/graduation year, e.g. `2024`.
  static String? batchYear(String? value) {
    final requiredError = required(value, field: 'Batch');
    if (requiredError != null) return requiredError;
    final year = int.tryParse(value!.trim());
    if (year == null || year < 2000 || year > 2100) {
      return 'Enter a valid year (e.g. 2024)';
    }
    return null;
  }

  /// Course/program name.
  static String? course(String? value) {
    final requiredError = required(value, field: 'Course');
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 2) return 'Course must be at least 2 characters';
    return null;
  }

  static String? department(String? value) {
    return required(value, field: 'Department');
  }

  /// Optional phone number; must be 7-15 digits when provided.
  static String? optionalPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[\s\-()+.]+'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Utility used by providers to surface the first validation error.
  static String? firstError(List<String?> errors) {
    for (final error in errors) {
      if (error != null) return error;
    }
    return null;
  }

  /// Formats input for the certificate UID field: strips spaces, uppercases,
  /// and enforces the CERT-YYYY-NNNNNN skeleton while typing.
  static String formatCertificateUidInput(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (cleaned.isEmpty) return '';
    final parts = <String>[];
    parts.add(cleaned.substring(0, cleaned.length.clamp(0, 4)));
    if (cleaned.length > 4) {
      parts.add(cleaned.substring(4, cleaned.length.clamp(4, 8)));
    }
    if (cleaned.length > 8) {
      parts.add(cleaned.substring(8, cleaned.length.clamp(8, 14)));
    }
    return parts.join('-');
  }

  /// Filter used inside text fields to reject illegal characters before they
  /// reach the form state.
  static final FilteringTextInputFormatter uidInputFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]'));
}
