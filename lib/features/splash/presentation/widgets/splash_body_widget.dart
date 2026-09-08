import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_assets.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/app_identity_widget.dart';
import 'package:qatrah/features/splash/presentation/widgets/splash_loading_indicator_widget.dart';
import 'package:qatrah/features/splash/presentation/widgets/splash_logo_widget.dart';

class SplashBody extends StatelessWidget {
  const SplashBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          AppAssets.splashBackgroundImg,
          fit: BoxFit.cover,
          width: double.maxFinite,
          height: double.maxFinite,
          color: context.colorScheme.secondary.withValues(alpha: .025),
        ),
        Builder(
          builder: (context) {
            FlutterNativeSplash.remove();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SplashLogo(),
                20.verticalSpace,
                const SplashLoadingIndicator(),
              ],
            );
          },
        ),
        Positioned(
          bottom: 32.h,
          left: 0,
          right: 0,
          child: AppIdentityWidget(
            color: context.colorScheme.onPrimary.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
