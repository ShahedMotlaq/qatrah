import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/pin_security_service.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/auth/presentation/bloc/app_pin/app_pin_bloc.dart';
import 'package:qatrah/features/auth/presentation/widgets/app_pin/app_pin_form.dart';

/// Pushes a PIN entry that pops with `true` on a successful verification,
/// `false` if the user backs out. Used by Settings to gate biometric
/// enable/disable, etc.
///
/// Note: callers must `await Navigator.push<bool>` (or
/// `context.push<bool>`) the route that hosts this page.
class VerifyPinPage extends StatelessWidget {
  const VerifyPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => AppPinBloc(
        pinService: getIt<PinSecurityService>(),
        mode: AppPinMode.unlock,
      ),
      child: BlocListener<AppPinBloc, AppPinState>(
        listenWhen: (a, b) => a.completed != b.completed && b.completed,
        listener: (context, _) => context.pop(true),
        child: Scaffold(
          appBar: QatrahAppBarWidget(title: Text(l10n.changePinCurrent)),
          body: AppBackground(
            child: AppPinForm(
              title: l10n.changePinCurrent,
              submitLabel: l10n.confirm,
            ),
          ),
        ),
      ),
    );
  }
}
