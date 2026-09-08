import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';

class DynamicFormDialog extends StatelessWidget {
  const DynamicFormDialog({
    required this.title,
    required this.content,
    required this.confirmBtnText,
    required this.cancelBtnText,
    required this.onConfirm,
    super.key,
    this.isLoading = false,
  });

  final String title;
  final Widget content;
  final String confirmBtnText;
  final String cancelBtnText;
  final VoidCallback? onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 24.h),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take only content height
            children: [
              // Title
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              24.verticalSpace,

              // Dynamic form content (fields) - flexible and scrollable if needed
              Flexible(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),

              24.verticalSpace,

              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: cancelBtnText,
                      onPressed: isLoading ? null : () => context.pop(),
                      isOutline: true,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: AppButton(
                      text: isLoading ? '...' : confirmBtnText,
                      onPressed: isLoading ? null : onConfirm,
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
