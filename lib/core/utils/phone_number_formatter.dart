class PhoneNumberFormatter {
  static String format(String phone) {
    var clean = phone.replaceAll(RegExp(r'\s+'), '');

    // Remove any leading + if present
    if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }

    // For Syrian numbers, if it starts with 09xx, keep it as is (local format)
    // If it starts with 9xx (without 0), add leading 0
    if (clean.startsWith('9') && clean.length == 10) {
      clean = '0$clean';
    }

    // Ensure it has the proper format
    // Expected: 09XXXXXXXX (10 digits starting with 09)
    return clean;
  }
}
