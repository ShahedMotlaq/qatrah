import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/services/version_check_service.dart';
import 'package:qatrah/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:qatrah/features/splash/presentation/bloc/splash_state.dart';
import 'package:qatrah/features/splash/presentation/widgets/optional_update_dialog.dart';

class SplashListener extends StatelessWidget {
  const SplashListener({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is SplashAuthenticated) {
          context.goNamed(
            Routes.navbar,
            extra: {'forceIsEmployee': state.isEmployee},
          );
          _offerUpdate(context, state.optionalUpdate);
        } else if (state is SplashEmployeeLocked) {
          context.goNamed(Routes.appLock);
        } else if (state is SplashEmployeePinSetup) {
          context.goNamed(Routes.createPin);
        } else if (state is SplashForceUpdate) {
          context.goNamed(
            Routes.forceUpdate,
            extra: {'storeUrl': state.storeUrl, 'apkUrl': state.apkUrl},
          );
        } else if (state is SplashMaintenance) {
          context.goNamed(
            Routes.maintenance,
            extra: {
              'message': state.message,
              'retryAfterSeconds': state.retryAfterSeconds,
            },
          );
        } else if (state is SplashUnauthenticated) {
          context.goNamed(Routes.login);
          _offerUpdate(context, state.optionalUpdate);
        }
      },
      child: child,
    );
  }

  /// Runs after the frame that performs the navigation, so the dialog opens
  /// over the destination rather than over a splash that is being torn down.
  void _offerUpdate(BuildContext context, VersionCheckResult? version) {
    if (version == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(showOptionalUpdateDialog(context, version));
    });
  }
}
