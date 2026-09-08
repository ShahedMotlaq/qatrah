// lib/features/auth/presentation/widgets/otp/otp_form_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_bloc.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_input_cubit.dart';
import 'package:qatrah/features/auth/presentation/widgets/otp/otp_input_fields.dart';
import 'package:qatrah/features/auth/presentation/widgets/otp/otp_resend_section.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class OtpFormSection extends StatefulWidget {
  const OtpFormSection({
    required this.phoneNumber,
    super.key,
    this.isFromForgetPassword = false,
  });

  final bool isFromForgetPassword;
  final String phoneNumber;

  @override
  State<OtpFormSection> createState() => _OtpFormSectionState();
}

class _OtpFormSectionState extends State<OtpFormSection> {
  // True after the user starts typing following an error — hides the error
  // text and resets the red border until the next submission result.
  bool _isDirty = false;

  @override
  Widget build(BuildContext context) {
    final inputCubit = context.read<OtpInputCubit>();

    return BlocConsumer<OtpBloc, OtpState>(
      // Re-listen whenever a new error id arrives so we reset _isDirty.
      listenWhen: (prev, curr) => prev.errorId != curr.errorId,
      listener: (context, state) {
        // New error arrived — show it again even if user was editing.
        if (_isDirty) setState(() => _isDirty = false);
      },
      builder: (context, state) {
        final errorText = _isDirty ? null : _mapOtpError(state, context.l10n);

        return Column(
          children: [
            OtpInputFields(
              phoneNumber: widget.phoneNumber,
              enabled: !state.isLoading,
              hasError: errorText != null,
              onChanged: (_) {
                if (!_isDirty) setState(() => _isDirty = true);
              },
            ),
            if (errorText != null) ...[
              8.verticalSpace,
              _OtpInlineError(text: errorText),
            ],
            40.verticalSpace,
            AppButton(
              text: context.l10n.verifyNow,
              isLoading: state.isLoading,
              onPressed: state.isLoading
                  ? null
                  : () {
                      final otpCode = inputCubit.otpCode;
                      if (otpCode.length == 4) {
                        setState(() => _isDirty = false);
                        context.read<OtpBloc>().add(
                          VerifyOtpEvent(widget.phoneNumber, otpCode),
                        );
                      }
                    },
            ),
            20.verticalSpace,
          ],
        );
      },
    );
  }

  static String? _mapOtpError(OtpState state, AppLocalizations l10n) {
    final message = state.errorMessage?.trim() ?? '';
    if (message.isEmpty || state.isLoading) return null;

    if (message == 'otp_error_rate_limited') {
      final countdown = OtpResendSection.formatCountdown(
        totalSeconds: state.timerDuration,
        l10n: l10n,
        locale: WidgetsBinding.instance.platformDispatcher.locale,
      );
      return '${l10n.resendOtpIn}$countdown';
    }
    if (message == 'otp_error_persist_failed')
      return l10n.errorDuringVerification;
    if (message == 'error_verify_otp') return l10n.errorVerifyOtp;

    final normalized = message.toLowerCase();
    if (normalized.contains('not found') ||
        normalized.contains('user_not_found')) {
      return l10n.invalidPhoneNumber;
    }
    if (normalized.contains('forbidden') || normalized.contains('403')) {
      return l10n.forbidden;
    }
    return message;
  }
}

class _OtpInlineError extends StatelessWidget {
  const _OtpInlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
      textAlign: TextAlign.center,
    );
  }
}
