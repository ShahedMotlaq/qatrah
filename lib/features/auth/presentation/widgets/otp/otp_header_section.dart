import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/extensions/string_extension.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';

class OtpHeaderSection extends StatelessWidget {
  const OtpHeaderSection({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = context.colorScheme;

    return Column(
      children: [
        const WaterDropAvatarWidget(),

        30.verticalSpace,
        FittedBox(
          child: Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              children: [
                TextSpan(
                  text: '${context.l10n.otpSent}  ',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontSize: 18.sp,
                  ),
                ),
                TextSpan(
                  text: '\u202A${phoneNumber.obfuscated}\u202C',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.secondary,
                    fontSize: 16.sp,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
