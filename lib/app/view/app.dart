import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/auth/app_lock_lifecycle_observer.dart';
import 'package:qatrah/core/constants/app_constants.dart';
import 'package:qatrah/core/locale/locale_cubit.dart';
import 'package:qatrah/core/network/network_status_cubit.dart';
import 'package:qatrah/core/routing/app_router.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';
import 'package:qatrah/core/theme/app_theme.dart';
import 'package:qatrah/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppLockLifecycleObserver _lockObserver;

  @override
  void initState() {
    super.initState();
    _lockObserver = getIt<AppLockLifecycleObserver>()..attach();
  }

  @override
  void dispose() {
    _lockObserver.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>.value(
          value: getIt<LocaleCubit>(),
        ),
        BlocProvider<NetworkStatusCubit>.value(
          value: getIt<NetworkStatusCubit>(),
        ),
        // Global NotificationsCubit for badge sync across all screens
        BlocProvider<NotificationsCubit>(
          create: (context) => getIt<NotificationsCubit>(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  static const _arabicLocale = Locale('ar');

  // Initialise once — reusing the same TransitionBuilder instance avoids
  // re-creating the BotToast overlay stack on every widget rebuild.
  final TransitionBuilder _botToastInit = BotToastInit();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: AppConstants.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            locale: _arabicLocale,
            theme: AppTheme.createTheme(
              isDark: false,
              languageCode: _arabicLocale.languageCode,
            ),
            darkTheme: AppTheme.createTheme(
              isDark: true,
              languageCode: _arabicLocale.languageCode,
            ),
            themeMode: ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: const [_arabicLocale],
            routerConfig: AppRouter.router,
            builder: (context, child) {
              // 1. Keep ToastService's l10n reference in sync with the widget
              //    tree so it can translate raw error codes without a context.
              getIt<ToastService>().updateL10n(AppLocalizations.of(context));

              // 2. BotToastInit inserts the global overlay that bot_toast uses
              //    to render toasts above everything else, including dialogs.
              return _botToastInit(
                context,
                // 3. The network-status listener now delegates to ToastService
                //    instead of ScaffoldMessenger, so it works even when there
                //    is no Scaffold ancestor in the tree.
                BlocListener<NetworkStatusCubit, NetworkStatusState>(
                  listenWhen: (prev, next) =>
                      !next.isInitial && prev.status != next.status,
                  listener: (context, state) {
                    final l10n = AppLocalizations.of(context);
                    final toast = getIt<ToastService>();
                    if (state.isOffline) {
                      toast.showWarning(l10n.noInternetConnection);
                    } else {
                      toast.showSuccess(l10n.connectionRestored);
                    }
                  },
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
