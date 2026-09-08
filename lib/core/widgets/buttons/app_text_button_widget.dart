import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isDisabled = false,
    this.color,
    this.textStyle,
    super.key,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isDisabled;
  final Color? color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    // State that prevents pressing programmatically
    final isActionDisabled = isDisabled || isLoading || onPressed == null;
    final primaryColor = color ?? context.colorScheme.primary;

    return TextButton(
      onPressed: isActionDisabled ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        disabledForegroundColor: isLoading ? primaryColor : null,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      child: isLoading
          ? AppLoadingWidget(
              size: 15.sp,
              color: primaryColor,
            )
          : Text(
              text,
              style:
                  textStyle ??
                  context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActionDisabled && !isLoading
                        ? context.theme.disabledColor
                        : primaryColor,
                  ),
            ),
    );
  }
}
