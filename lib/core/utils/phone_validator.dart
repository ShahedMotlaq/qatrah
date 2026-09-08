class PhoneValidator {
  const PhoneValidator._();

  static final RegExp _digitsOnly = RegExp(r'^\d{10}$');
  static final RegExp _blockedPrefix = RegExp('^(090|091|092)');

  static bool isValidSyrianMobile(String input) {
    final normalized = _normalize(input);
    if (!_digitsOnly.hasMatch(normalized)) return false;
    if (_blockedPrefix.hasMatch(normalized)) return false;
    return normalized.startsWith('09');
  }

  static bool hasBlockedPrefix(String input) {
    return _blockedPrefix.hasMatch(_normalize(input));
  }

  static String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), '');
  }
}
