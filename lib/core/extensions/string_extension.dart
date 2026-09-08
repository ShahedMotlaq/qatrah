// String extension utilities for common formatting operations.

extension StringExtension on String {
  /// Obfuscates the middle characters of a string, useful for masking phone numbers.
  String get obfuscated {
    if (length <= 4) return this;
    final start = substring(0, 2);
    final end = substring(length - 2);
    final middle = '*' * (length - 4);
    return '$start$middle$end';
  }
}
