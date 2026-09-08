import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/theme/app_colors.dart';

class AppIconWidget extends StatelessWidget {
  const AppIconWidget({
    required this.icon,
    this.size,
    this.color,
    this.strokeWidth,
    this.applyPadding = true,
    super.key,
  });

  final List<List<dynamic>> icon;

  final double? size;

  final Color? color;

  final double? strokeWidth;
  final bool applyPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: applyPadding ? const EdgeInsets.all(12) : EdgeInsets.zero,
      child: HugeIcon(
        icon: icon,
        size: size ?? 24,
        color: color ?? AppColors.darkPrimary,
        strokeWidth: strokeWidth ?? 1.5,
      ),
    );
  }
}
