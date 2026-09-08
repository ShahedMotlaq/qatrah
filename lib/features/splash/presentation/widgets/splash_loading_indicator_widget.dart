import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';

class SplashLoadingIndicator extends StatelessWidget {
  const SplashLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLoadingWidget(
      size: 60.sp,
      color: context.colorScheme.secondary,
      waveColor: context.colorScheme.secondary,
    );
  }
}
