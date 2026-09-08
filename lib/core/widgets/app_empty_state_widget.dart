// lib/core/widgets/app_empty_state_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

/// A reusable empty state widget that displays a centered icon and message.
/// Used across the app to show empty lists, no data states, etc.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.message,
    required this.icon,
    super.key,
    this.iconColor,
    this.textStyle,
  });

  /// The message to display below the icon.
  final String message;

  /// The icon to display at the top (use HugeIcons.strokeRounded* icons).
  final List<List<dynamic>> icon;

  /// Optional custom color for the icon (defaults to theme's onSurfaceVariant).
  final Color? iconColor;

  /// Optional custom text style (defaults to theme's bodyMedium).
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconWidget(
            icon: icon,
            size: 40,
            color:
                iconColor ??
                theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          10.verticalSpace,
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
                  textStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
