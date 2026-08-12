/// ModelUtils is a small toolkit for resilient JSON parsing.
///
/// Backends evolve; keys get renamed, values come back as int or string.
/// These helpers normalize the common variations so models stay stable and
/// never crash on a missing or oddly-typed field.
abstract final class ModelUtils {
  /// Returns the first non-null value found under any of [keys], or null.
  static Object? pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value;
    }
    return null;
  }

  /// Like [pick] but sourced from a nested map when present (e.g. `meta`).
  static Object? pickAny(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic>? meta,
  }) {
    final value = pick(json, keys);
    if (value != null || meta == null) return value;
    return pick(meta, keys);
  }

  static Map<String, dynamic>? pickMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = pick(json, keys);
    return value is Map<String, dynamic> ? value : null;
  }

  static List<dynamic> pickList(Map<String, dynamic> json, List<String> keys) {
    final value = pick(json, keys);
    return value is List ? value : const [];
  }

  static int pickInt(
    Map<String, dynamic> json,
    List<String> keys, {
    int fallback = 0,
    Map<String, dynamic>? meta,
  }) {
    final value = pickAny(json, keys, meta: meta);
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    return parsed ?? fallback;
  }

  static bool pickBool(
    Map<String, dynamic> json,
    List<String> keys, {
    bool fallback = false,
  }) {
    final value = pick(json, keys);
    if (value is bool) return value;
    return switch (value?.toString().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => fallback,
    };
  }

  static DateTime? pickDate(Map<String, dynamic> json, List<String> keys) {
    final value = pick(json, keys);
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String? pickString(Map<String, dynamic> json, List<String> keys) {
    final value = pick(json, keys);
    return value?.toString();
  }
}
