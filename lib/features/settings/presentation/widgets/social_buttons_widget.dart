import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_assets.dart';
import 'package:qatrah/core/constants/app_constants.dart';
import 'package:qatrah/core/utils/app_url_launcher.dart';
import 'package:qatrah/core/widgets/app_svg_widget.dart';

class SocialButtonsWidget extends StatelessWidget {
  const SocialButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SocialIconButton(
          icon: AppAssets.facebookLogo,
          url: AppConstants.facebookUrl,
        ),
        16.horizontalSpace,
        const SocialIconButton(
          icon: AppAssets.xLogo,
          url: AppConstants.xUrl,
        ),
        16.horizontalSpace,
        const SocialIconButton(
          icon: AppAssets.instagramLogo,
          url: AppConstants.instagramUrl,
        ),
      ],
    );
  }
}

class SocialIconButton extends StatelessWidget {
  const SocialIconButton({
    required this.icon,
    required this.url,
    super.key,
    this.color,
  });

  final String icon;
  final String url;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => AppUrlLauncher.launchWebsite(context, url),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: .7),
          ),
        ),
        child: AppSvgWidget(
          assetsUrl: icon,
          fit: BoxFit.cover,
          width: 30.sp,
          height: 30.sp,
        ),
      ),
    );
  }
}
