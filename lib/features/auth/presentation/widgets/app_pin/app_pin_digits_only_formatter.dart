import 'package:flutter/services.dart';

/// TextInputFormatter that silently strips any non-digit characters.
/// When a non-digit is rejected the [onRejected] callback fires once.
class AppPinDigitsOnlyFormatter extends TextInputFormatter {
  const AppPinDigitsOnlyFormatter({required this.onRejected});

  final VoidCallback onRejected;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (RegExp(r'^\d*$').hasMatch(newValue.text)) return newValue;
    onRejected();
    final filtered = newValue.text.replaceAll(RegExp(r'\D'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
