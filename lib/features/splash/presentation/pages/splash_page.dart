import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:qatrah/features/splash/presentation/widgets/splash_body_widget.dart';
import 'package:qatrah/features/splash/presentation/widgets/splash_listener_widget.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit()..appStart(),
      child: SplashListener(
        child: Scaffold(
          backgroundColor: context.colorScheme.primary,
          body: const SplashBody(),
        ),
      ),
    );
  }
}
