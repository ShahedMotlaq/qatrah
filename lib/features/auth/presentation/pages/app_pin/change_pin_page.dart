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
import 'package:qatrah/core/services/toast_service.dart';

/// Settings entry point: verify current PIN, then enter and confirm a new
/// one. On success the screen pops with a snackbar.
class ChangePinPage extends StatelessWidget {
  const ChangePinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => AppPinBloc(
        pinService: getIt<PinSecurityService>(),
        mode: AppPinMode.change,
      ),
      child: BlocListener<AppPinBloc, AppPinState>(
        listenWhen: (a, b) => a.completed != b.completed && b.completed,
        listener: (context, _) {
          getIt<ToastService>().showSuccess(l10n.changePinSuccess);
          context.pop();
        },
        child: Scaffold(
          appBar: QatrahAppBarWidget(title: Text(l10n.changePinTitle)),
          body: AppBackground(
            child: BlocBuilder<AppPinBloc, AppPinState>(
              buildWhen: (a, b) => a.step != b.step,
              builder: (context, state) {
                final title = switch (state.step) {
                  AppPinStep.verifyCurrent => l10n.changePinCurrent,
                  AppPinStep.enter => l10n.changePinNew,
                  AppPinStep.confirm => l10n.confirmPinCode,
                };
                final submit = switch (state.step) {
                  AppPinStep.verifyCurrent => l10n.confirm,
                  AppPinStep.enter => l10n.save,
                  AppPinStep.confirm => l10n.confirm,
                };
                return AppPinForm(title: title, submitLabel: submit);
              },
            ),
          ),
        ),
      ),
    );
  }
}
