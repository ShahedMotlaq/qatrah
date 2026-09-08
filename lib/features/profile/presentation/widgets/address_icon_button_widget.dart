import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddressIconButtonWidget extends StatelessWidget {
  const AddressIconButtonWidget({
    required this.icon,
    required this.onPressed,
    this.isDangerous = false,
    this.tooltipText,
    super.key,
  });

  final dynamic icon;
  final VoidCallback onPressed;
  final bool isDangerous;
  final String? tooltipText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDangerous
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: 36.r,
          height: 36.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDangerous
                ? theme.colorScheme.error.withValues(alpha: 0.08)
                : theme.colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: _buildIconChild(color),
        ),
      ),
    );

    if (tooltipText != null) {
      return Tooltip(
        message: tooltipText,
        child: button,
      );
    }

    return button;
  }

  Widget _buildIconChild(Color color) {
    if (icon is IconData) {
      return Icon(
        icon as IconData,
        size: 18.sp,
        color: color,
      );
    }
    return icon as Widget;
  }
}
