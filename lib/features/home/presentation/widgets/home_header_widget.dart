import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/constants/app_assets.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/widgets/app_svg_widget.dart';
import 'package:qatrah/features/home/presentation/widgets/custom_outlined_icon_button_widget.dart';

class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AppSvgWidget(
              width: double.maxFinite,
              height: 44.h,
              assetsUrl: AppAssets.syrianHorizontalGoldIcon,
              fit: BoxFit.fitHeight,
            ),
          ),
          Row(
            children: [
              CustomOutlinedIconButtonWidget(
                icon: HugeIcons.strokeRoundedUser03,
                onPressed: () => context.pushNamed(Routes.profile),
              ),
              8.horizontalSpace,
              CustomOutlinedIconButtonWidget(
                icon: HugeIcons.strokeRoundedLocation01,
                onPressed: () => context.pushNamed(Routes.myAddresses),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
