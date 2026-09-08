import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_constants.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class SettingsOutlineTileWidget extends StatelessWidget {
  const SettingsOutlineTileWidget({
    required this.title,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String title;
  final List<List> icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final isRtl = locale.languageCode == AppConstants.langAr;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: .5),
          ),
        ),
        child: Row(
          children: [
            AppIconWidget(
              icon: icon,
            ),
            16.horizontalSpace,
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: theme.colorScheme.primary,
              size: 16.r,
            ),
          ],
        ),
      ),
    );
  }
}
