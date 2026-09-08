import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:qatrah/features/splash/presentation/bloc/splash_state.dart';

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
          context.goNamed(Routes.maintenance);
        } else if (state is SplashUnauthenticated) {
          context.goNamed(Routes.login);
        }
      },
      child: child,
    );
  }
}
