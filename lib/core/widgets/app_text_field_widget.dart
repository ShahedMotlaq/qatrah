import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class _ArabicToEnglishDigitsFormatter extends TextInputFormatter {
  static const _map = {
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

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var converted = newValue.text;
    _map.forEach((ar, en) => converted = converted.replaceAll(ar, en));
    if (converted == newValue.text) return newValue;
    return newValue.copyWith(text: converted);
  }
}

final _arabicDigitsConverter = _ArabicToEnglishDigitsFormatter();

class AppTextField extends StatefulWidget {
  const AppTextField({
    this.onTap,
    this.readOnly = false,
    super.key,
    this.controller,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.onChanged,
    this.maxLines,
    this.minLines,
    this.maxLength,
    this.autofillHints,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.enableIMEPersonalizedLearning = true,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final void Function()? onTap;
  final void Function(String)? onChanged;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final bool autocorrect;
  final bool enableIMEPersonalizedLearning;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;

  /// Caller-owned error message. Use instead of [validator] when the parent
  /// drives validation itself rather than through a [Form].
  final String? errorText;

  final TextInputAction? textInputAction;

  /// Keyboard action (Go / Done) handler — lets a form be submitted without
  /// reaching for the on-screen button.
  final void Function(String)? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      maxLength: widget.maxLength,
      maxLines: widget.maxLines ?? 1,
      minLines: widget.minLines ?? 1,
      onTap: widget.onTap,
      readOnly: widget.readOnly,
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      enableSuggestions: widget.enableSuggestions,
      autocorrect: widget.autocorrect,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      textAlign: widget.textAlign,
      inputFormatters: [
        _arabicDigitsConverter,
        if (widget.inputFormatters != null) ...widget.inputFormatters!,
      ],
      decoration: InputDecoration(
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon,

        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscureText = !_obscureText),
                icon: AppIconWidget(
                  icon: _obscureText
                      ? HugeIcons.strokeRoundedViewOff
                      : HugeIcons.strokeRoundedView,
                ),
              )
            : widget.suffixIcon,
      ),
    );
  }
}
