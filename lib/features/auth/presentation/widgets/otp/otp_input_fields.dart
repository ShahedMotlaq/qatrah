// lib/features/auth/presentation/widgets/otp/otp_input_fields.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_bloc.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_input_cubit.dart';

class OtpInputFields extends StatelessWidget {
  const OtpInputFields({
    required this.phoneNumber,
    super.key,
    this.enabled = true,
    this.hasError = false,
    this.onChanged,
  });

  final String phoneNumber;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final cubit = context.read<OtpInputCubit>();

    final defaultPinTheme = PinTheme(
      width: 66,
      height: 66,
      textStyle: context.textTheme.headlineSmall?.copyWith(
        color: context.colorScheme.primary,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: colorScheme.primary,
          width: 1.75,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Pinput(
        controller: cubit.controller,
        focusNode: cubit.focusNode,
        autofocus: true,
        enabled: enabled,
        submittedPinTheme: submittedPinTheme,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        errorPinTheme: errorPinTheme,
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        forceErrorState: hasError,
        // SMS auto-read removed — caused native crash in release builds.
        onChanged: onChanged,
        onCompleted: (pin) {
          context.read<OtpBloc>().add(VerifyOtpEvent(phoneNumber, pin));
        },
      ),
    );
  }
}
