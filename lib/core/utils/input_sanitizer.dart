/// Utility class for sanitizing user input before sending to API.
///
/// This ensures:
/// 1. All Arabic digits are converted to English digits
/// 2. Multiple consecutive spaces are collapsed to single space
/// 3. Leading/trailing whitespace is removed
class InputSanitizer {
  // Arabic to English digit mapping
  static const Map<String, String> _arabicToEnglishDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  /// Sanitizes input string for API transmission.
  ///
  /// Performs:
  /// 1. Trim leading/trailing whitespace
  /// 3. Collapse multiple spaces to single space
  ///
  /// Example:
  /// ```dart
  /// ```
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Step 1: Trim leading/trailing whitespace
    var result = input.trim();

    // Step 2: Replace Arabic digits with English digits
    _arabicToEnglishDigits.forEach((arabic, english) {
      result = result.replaceAll(arabic, english);
    });

    // Step 3: Collapse multiple spaces to single space
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Sanitizes all text fields in a map (typically a request body).
  ///
  /// Only processes String values, leaves other types untouched.
  ///
  /// Example:
  /// ```dart
  /// final sanitized = InputSanitizer.sanitizeMap({
  ///   'age': 25,
  /// });
  /// // Returns:
  /// // {
  /// //   'age': 25,
  /// // }
  /// ```
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is String) {
        return MapEntry(key, sanitizeInput(value));
      }
      return MapEntry(key, value);
    });
  }

  /// Sanitizes a list of strings.
  static List<String> sanitizeList(List<String> list) {
    return list.map(sanitizeInput).toList();
  }
}
