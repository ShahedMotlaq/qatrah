// lib/features/auth/presentation/pages/otp/otp_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_bloc.dart';
import 'package:qatrah/features/auth/presentation/bloc/otp/otp_input_cubit.dart';
import 'package:qatrah/features/auth/presentation/pages/otp/otp_body.dart';

class OtpPage extends StatelessWidget {
  const OtpPage({
    required this.phoneNumber,
    super.key,
    this.isFromForgetPassword = false,
    this.alreadySent = false, // If true, OTP was already sent from LoginPage
  });

  final String phoneNumber;
  final bool isFromForgetPassword;
  final bool alreadySent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final bloc = OtpBloc();
            // Only send OTP if it wasn't already sent (e.g., from LoginPage)
            if (!alreadySent) {
              bloc.add(SendOtpEvent(phoneNumber));
            }
            return bloc;
          },
        ),
        BlocProvider(create: (_) => OtpInputCubit()),
      ],
      child: Scaffold(
        appBar: QatrahAppBarWidget(
          title: Text(l10n.otpVerification),
        ),
        body: AppBackground(
          child: OtpBody(
            phoneNumber: phoneNumber,
            isFromForgetPassword: isFromForgetPassword,
          ),
        ),
      ),
    );
  }
}
