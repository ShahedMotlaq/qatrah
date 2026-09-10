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
    this.subtitle,
  });

  final String title;
  final List<List> icon;
  final VoidCallback onTap;

  /// Optional second line under [title] — e.g. the signed-in user's role.
  final String? subtitle;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    2.verticalSpace,
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
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
