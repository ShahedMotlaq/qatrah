import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/pin_security_service.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/features/auth/presentation/bloc/app_pin/app_pin_bloc.dart';
import 'package:qatrah/features/auth/presentation/widgets/app_pin/app_pin_form.dart';

/// PIN setup page. When [fromSettings] is true, it's optional (can pop back)
/// and returns to settings after completion. Otherwise it's the mandatory
/// first-time setup flow that continues to biometric setup.
class CreatePinPage extends StatelessWidget {
  const CreatePinPage({this.fromSettings = false, super.key});

  final bool fromSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (_) => AppPinBloc(
        pinService: getIt<PinSecurityService>(),
        mode: AppPinMode.setup,
      ),
      child: BlocListener<AppPinBloc, AppPinState>(
        listenWhen: (a, b) => a.completed != b.completed && b.completed,
        listener: (context, state) {
          if (fromSettings) {
            context.pop();
          } else {
            context.goNamed(Routes.biometricSetup);
          }
        },
        child: PopScope(
          canPop: fromSettings,
          child: Scaffold(
            appBar: QatrahAppBarWidget(
              title: Text(l10n.pinCodeTitle),
              leading: const SizedBox.shrink(),
            ),
            body: AppBackground(
              child: BlocBuilder<AppPinBloc, AppPinState>(
                buildWhen: (a, b) => a.step != b.step,
                builder: (context, state) {
                  final isConfirm = state.step == AppPinStep.confirm;
                  return AppPinForm(
                    title: isConfirm ? l10n.confirmPinCode : l10n.setPinCode,
                    subtitle: isConfirm
                        ? l10n.confirmPinCodeSubtitle
                        : l10n.setPinCodeSubtitle,
                    submitLabel: isConfirm ? l10n.confirm : l10n.save,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
