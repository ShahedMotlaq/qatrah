import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_bloc.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_input_cubit.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class OtpResendSection extends StatelessWidget {
  const OtpResendSection({required this.phoneNumber, super.key});

  final String phoneNumber;

  static String formatCountdown({
    required int totalSeconds,
    required AppLocalizations l10n,
    required Locale locale,
  }) {
    if (totalSeconds < 60) {
      return ' $totalSeconds${l10n.secondsRemaining}';
    }

    if (totalSeconds % 60 == 0) {
      final minutes = totalSeconds ~/ 60;
      if (locale.languageCode == 'ar') {
        return ' $minutes دقيقة';
      }
      return minutes == 1 ? ' $minutes minute' : ' $minutes minutes';
    }

    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return ' $m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final l10n = context.l10n;

    return BlocBuilder<OtpBloc, OtpState>(
      buildWhen: (p, c) =>
          p.isTimerRunning != c.isTimerRunning ||
          p.timerDuration != c.timerDuration ||
          p.isLoading != c.isLoading,
      builder: (context, state) {
        if (state.isTimerRunning) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.resendOtpIn,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                formatCountdown(
                  totalSeconds: state.timerDuration,
                  l10n: l10n,
                  locale: Localizations.localeOf(context),
                ),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          );
        }

        return TextButton.icon(
          onPressed: state.isLoading
              ? null
              : () {
                  context.read<OtpInputCubit>().clearAndFocus();
                  context.read<OtpBloc>().add(SendOtpEvent(phoneNumber));
                },
          icon: Icon(Icons.refresh, size: 18.sp),
          label: Text(context.l10n.resendOtp),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        );
      },
    );
  }
}
