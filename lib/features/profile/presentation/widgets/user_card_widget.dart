import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserCardWidget extends StatelessWidget {
  const UserCardWidget({
    required this.fullName,
    required this.roleLabel,
    super.key,
    this.username = '',
    this.onEditTap,
    this.isActive,
    this.isLoading = false,
  });

  final String fullName;
  final String roleLabel;
  final String username;
  final VoidCallback? onEditTap;
  final bool? isActive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Skeleton.keep(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              const _GradientBackground(),
              const _DecorativeBlobs(),
              Skeletonizer(
                enabled: isLoading,
                effect: ShimmerEffect(
                  baseColor: Colors.white.withValues(alpha: 0.20),
                  highlightColor: Colors.white.withValues(alpha: 0.50),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
                  child: Column(
                    children: [
                      _HeroAvatar(showActive: isActive ?? false),
                      10.verticalSpace,
                      Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (username.trim().isNotEmpty) ...[
                        2.verticalSpace,
                        Text(
                          '@${username.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (roleLabel.isNotEmpty) ...[
                        10.verticalSpace,
                        _RoleChip(label: roleLabel),
                      ],
                      if (onEditTap != null) ...[
                        14.verticalSpace,
                        _EditPill(label: l10n.editData, onTap: onEditTap!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: Skeleton.keep(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.forest,
                AppColors.darkPrimary,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorativeBlobs extends StatelessWidget {
  const _DecorativeBlobs();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Skeleton.keep(
        child: IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -40.r,
                right: -30.r,
                child: _blob(
                  120.r,
                  AppColors.goldenWheat.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -50.r,
                left: -40.r,
                child: _blob(160.r, Colors.white.withValues(alpha: 0.06)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.showActive});

  final bool showActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(3.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const WaterDropAvatarWidget(radius: 34),
        ),
        if (showActive)
          Positioned(
            bottom: 6.r,
            right: 6.r,
            child: Container(
              width: 14.r,
              height: 14.r,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.goldenWheat.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.goldenWheat.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconWidget(
            icon: HugeIcons.strokeRoundedCheckmarkBadge02,
            size: 14.sp,
            color: Colors.white,
          ),
          6.horizontalSpace,
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.white.withValues(alpha: 0.15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconWidget(
              icon: HugeIcons.strokeRoundedEdit02,
              size: 15.sp,
              color: Colors.white,
            ),
            6.horizontalSpace,
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
