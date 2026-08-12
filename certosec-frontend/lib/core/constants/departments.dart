/// Departments is the institution's canonical department list, used by the
/// student form dropdown and the student list filter.
///
/// This is frontend configuration. If the backend exposes its own department
/// list endpoint, replace this constant with a fetched list in a later phase.
abstract final class Departments {
  static const List<String> all = [
    'Computer Science',
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Business Administration',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Economics',
    'Law',
    'Nursing',
  ];

  /// Whether a value is a known department (case-insensitive). Used to keep
  /// filters honest even when data comes from a source outside this list.
  static bool isKnown(String? value) {
    if (value == null || value.isEmpty) return false;
    return all.any((d) => d.toLowerCase() == value.toLowerCase());
  }
}
