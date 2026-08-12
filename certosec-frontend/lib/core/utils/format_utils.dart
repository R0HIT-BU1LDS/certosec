import 'package:intl/intl.dart';

/// FormatUtils centralizes human-readable formatting so dates and numbers
/// render identically across the app and respect the device locale via intl.
abstract final class FormatUtils {
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, hh:mm a');
  static final DateFormat _shortDate = DateFormat('MMM d');

  static String date(DateTime value) => _date.format(value.toLocal());

  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  static String shortDate(DateTime value) => _shortDate.format(value.toLocal());

  static String number(int value) =>
      NumberFormat.decimalPattern().format(value);

  static String count(int value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return number(value);
  }

  /// Compact relative label for "recent activity" lists, e.g. "2h ago".
  static String relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return shortDate(value);
  }

  /// Safely truncates long identifiers (UIDs, hashes) for tight layouts.
  static String truncateMiddle(String value, {int head = 6, int tail = 4}) {
    if (value.length <= head + tail) return value;
    return '${value.substring(0, head)}…${value.substring(value.length - tail)}';
  }

  static String titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
