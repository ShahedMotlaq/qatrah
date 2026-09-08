import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/profile/domain/entities/address_entity.dart';
import 'package:qatrah/features/profile/presentation/widgets/address_icon_button_widget.dart';

class AddressCardWidget extends StatelessWidget {
  const AddressCardWidget({
    required this.address,
    required this.isSelected,
    required this.onEdit,
    required this.onDelete,
    required this.onViewStatus,
    super.key,
  });

  final AddressEntity address;
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final zoneLabel = address.zoneName.isNotEmpty
        ? address.zoneName
        : address.neighborhoodName;
    final accentColor = isSelected ? primary : secondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? primary.withValues(alpha: 0.05)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected
              ? primary.withValues(alpha: 0.30)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.50),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? primary.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isSelected ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 4.w,
                  color: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(
                          address: address,
                          accentColor: accentColor,
                          zoneLabel: zoneLabel,
                        ),
                        12.verticalSpace,
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        8.verticalSpace,
                        _CardActions(
                          address: address,
                          onEdit: onEdit,
                          onDelete: onDelete,
                          onViewStatus: onViewStatus,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.address,
    required this.accentColor,
    required this.zoneLabel,
  });

  final AddressEntity address;
  final Color accentColor;
  final String zoneLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: AppIconWidget(
              icon: HugeIcons.strokeRoundedLocation04,
              size: 22.sp,
              color: accentColor,
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.isDefault ? l10n.defaultAddress : address.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              4.verticalSpace,
              Row(
                children: [
                  AppIconWidget(
                    icon: HugeIcons.strokeRoundedMaps,
                    size: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  4.horizontalSpace,
                  Expanded(
                    child: Text(
                      '${address.regionName} · $zoneLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onViewStatus,
  });

  final AddressEntity address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isReal = address.id > 0;

    return Row(
      children: [
        if (address.isDefault)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconWidget(
                  icon: HugeIcons.strokeRoundedHome01,
                  size: 12.sp,
                  color: theme.colorScheme.primary,
                ),
                5.horizontalSpace,
                Text(
                  l10n.defaultAddress,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        // View-only: show this address's pumping status without changing the
        // default (which is managed from the profile). Available for every
        // saved address.
        if (isReal) ...[
          AddressIconButtonWidget(
            icon: Icons.water_drop_outlined,
            tooltipText: l10n.currentPumpingStatus,
            onPressed: onViewStatus,
          ),
          8.horizontalSpace,
        ],
        // The default address is managed from the profile (by changing the
        // default location there). Only the other addresses can be edited or
        // deleted here.
        if (isReal && !address.isDefault) ...[
          AddressIconButtonWidget(
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
          8.horizontalSpace,
          AddressIconButtonWidget(
            icon: Icons.delete_outline,
            onPressed: onDelete,
            isDangerous: true,
          ),
        ],
      ],
    );
  }
}
