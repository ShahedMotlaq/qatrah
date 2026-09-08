import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_assets.dart';
import 'package:qatrah/core/widgets/app_svg_widget.dart';

class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
      child: AppSvgWidget(
        assetsUrl: AppAssets.syrianVerticalGoldIcon,
        width: double.maxFinite,
        height: 120.h,
      ),
    );
  }
}
