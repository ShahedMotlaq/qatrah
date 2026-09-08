import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

class LocationCardWidget extends StatelessWidget {
  const LocationCardWidget({
    required this.title,
    required this.region,
    required this.zone,
    required this.unit,
    required this.neighborhood,
    super.key,
    this.onTap,
  });

  final String title;
  final String region;
  final String zone;
  final String unit;
  final String neighborhood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(title: title, isEditable: onTap != null),
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Column(
                  children: [
                    _LocationInfoItemWidget(
                      icon: HugeIcons.strokeRoundedMaps,
                      label: l10n.regionLabelWithColon,
                      value: region,
                    ),
                    _LocationInfoItemWidget(
                      icon: HugeIcons.strokeRoundedBuilding03,
                      label: l10n.unitLabelWithColon,
                      value: unit,
                    ),
                    _LocationInfoItemWidget(
                      icon: HugeIcons.strokeRoundedHome01,
                      label: l10n.neighborhoodLabelWithColon,
                      value: neighborhood,
                    ),
                    _LocationInfoItemWidget(
                      icon: HugeIcons.strokeRoundedLocation04,
                      label: l10n.zoneLabelWithColon,
                      value: zone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.isEditable});

  final String title;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: AppIconWidget(
              icon: HugeIcons.strokeRoundedLocation04,
              color: theme.colorScheme.primary,
              size: 20.sp,
            ),
          ),
          12.horizontalSpace,
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (isEditable)
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppIconWidget(
                icon: HugeIcons.strokeRoundedEdit02,
                size: 16.sp,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationInfoItemWidget extends StatelessWidget {
  const _LocationInfoItemWidget({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
      child: Row(
        children: [
          AppIconWidget(
            icon: icon,
            size: 16.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          10.horizontalSpace,
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
