import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_bloc.dart';
import 'package:qatrah/features/auth/presentation/widgets/otp/otp_blocked_view.dart';
import 'package:qatrah/features/auth/presentation/widgets/otp/otp_form_section.dart';
import 'package:qatrah/features/auth/presentation/widgets/otp/otp_header_section.dart';
import 'package:qatrah/features/auth/presentation/widgets/otp/otp_resend_section.dart';

// ── Section: OTP Body ───────────────────────────────────────────────────────

class OtpBody extends StatelessWidget {
  const OtpBody({
    required this.phoneNumber,
    super.key,
    this.isFromForgetPassword = false,
  });

  final String phoneNumber;
  final bool isFromForgetPassword;

  @override
  Widget build(BuildContext context) {
    return BlocListener<OtpBloc, OtpState>(
      listenWhen: (prev, curr) => !prev.isVerified && curr.isVerified,
      listener: (context, state) {
        if (!state.isLoading) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              getIt<SecureAuthStorage>().isPinSet().then((hasPin) {
                if (!context.mounted) return;
                if (state.isFromForgetPassword) {
                  context.goNamed(Routes.navbar);
                } else if (state.shouldCompleteProfile) {
                  context.goNamed(Routes.completeProfile);
                } else {
                  context.goNamed(Routes.navbar);
                }
              });
            }
          });
        }
      },
      child: BlocBuilder<OtpBloc, OtpState>(
        builder: (context, state) {
          // Show dedicated blocked screen for level-3+ rate limits (≥ 60 s)
          if (state.retryLevel >= 3 && state.isTimerRunning) {
            return OtpBlockedView(timerDuration: state.timerDuration);
          }

          return _OtpFormLayout(
            phoneNumber: phoneNumber,
            isFromForgetPassword: isFromForgetPassword,
          );
        },
      ),
    );
  }
}

// ── Section: OTP Form Layout ────────────────────────────────────────────────

class _OtpFormLayout extends StatelessWidget {
  const _OtpFormLayout({
    required this.phoneNumber,
    required this.isFromForgetPassword,
  });

  final String phoneNumber;
  final bool isFromForgetPassword;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            OtpHeaderSection(phoneNumber: phoneNumber),
            40.verticalSpace,
            OtpFormSection(
              phoneNumber: phoneNumber,
              isFromForgetPassword: isFromForgetPassword,
            ),
            OtpResendSection(phoneNumber: phoneNumber),
          ],
        ),
      ),
    );
  }
}
