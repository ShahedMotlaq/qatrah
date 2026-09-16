import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qatrah/core/auth/app_lock_state.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/auth/biometric_service.dart';
import 'package:qatrah/core/auth/pin_security_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_confirm_dialog.dart';
import 'package:qatrah/core/widgets/buttons/app_text_button_widget.dart';
import 'package:qatrah/features/auth/presentation/bloc/app_pin/app_pin_bloc.dart';
import 'package:qatrah/features/auth/presentation/widgets/app_pin/app_pin_form.dart';
import 'package:qatrah/features/auth/presentation/widgets/app_pin/biometric_login_button.dart';

// ── Section: App Lock Page ──────────────────────────────────────────────────

/// The local lock screen that gates access to protected employee screens.
///
/// PIN entry is the primary unlock method. If biometric is enabled and
/// supported, the user can launch it manually from below the PIN fields.
/// After a successful unlock the page hands control to the [Routes.splash]
/// which performs the session refresh + role-based routing.
class AppLockPage extends StatelessWidget {
  const AppLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppPinBloc(
        pinService: getIt<PinSecurityService>(),
        mode: AppPinMode.unlock,
      ),
      child: const _AppLockView(),
    );
  }
}

// ── Section: App Lock View ──────────────────────────────────────────────────

class _AppLockView extends StatefulWidget {
  const _AppLockView();

  @override
  State<_AppLockView> createState() => _AppLockViewState();
}

class _AppLockViewState extends State<_AppLockView> {
  late final Future<bool> _biometricAvailableFuture;

  @override
  void initState() {
    super.initState();
    _biometricAvailableFuture = _biometricAvailable();
  }

  // ── Navigation & Actions ──────────────────────────────────────────────────

  Future<void> _runBiometric() async {
    final l10n = context.l10n;
    final biometric = getIt<BiometricService>();
    final pinService = getIt<PinSecurityService>();

    final ok = await biometric.authenticate(reason: l10n.biometricReason);
    if (!ok || !mounted) return;
    await pinService.resetAttempts();
    if (!mounted) return;
    _routeToProtected();
  }

  void _routeToProtected() {
    getIt<AppLockState>().markUnlocked();
    context.goNamed(Routes.splash);
  }

  Future<void> _onForgotPin() async {
    if (!mounted) return;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => DynamicConfirmDialog(
        title: l10n.forgotPin,
        message: l10n.forgotPinConfirm,
        confirmBtnText: l10n.confirm,
        cancelBtnText: l10n.cancel,
        isDangerousAction: true,
        onConfirm: _clearLocalSessionAndGoLogin,
      ),
    );
  }

  Future<void> _clearLocalSessionAndGoLogin() async {
    await getIt<SecureAuthStorage>().clear();
    await getIt<AuthSessionService>().clearSession();
    getIt<AppLockState>().markLocked();
    if (!mounted) return;
    context.goNamed(Routes.login);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<AppPinBloc, AppPinState>(
      listenWhen: (a, b) =>
          (a.completed != b.completed && b.completed) ||
          (a.shouldClearSession != b.shouldClearSession &&
              b.shouldClearSession),
      listener: (context, state) async {
        if (state.shouldClearSession) {
          await _clearLocalSessionAndGoLogin();
          return;
        }
        if (state.completed) {
          _routeToProtected();
        }
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: QatrahAppBarWidget(
            title: Text(l10n.appLockTitle),
            leading: const SizedBox.shrink(),
          ),
          body: AppBackground(
            child: BlocBuilder<AppPinBloc, AppPinState>(
              builder: (context, state) {
                return AppPinForm(
                  title: l10n.appLockTitle,
                  subtitle: l10n.appLockSubtitle,
                  submitLabel: l10n.login,
                  showSubmit: false,
                  preSubmit: FutureBuilder<bool>(
                    future: _biometricAvailableFuture,
                    builder: (context, snap) {
                      if (snap.data != true) {
                        return const SizedBox();
                      }
                      return BiometricLoginButton(onTap: _runBiometric);
                    },
                  ),
                  trailing: state.failedAttempts >= 3
                      ? Column(
                          children: [
                            AppTextButton(
                              text: l10n.forgotPin,
                              onPressed: _onForgotPin,
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _biometricAvailable() async {
    final storage = getIt<SecureAuthStorage>();
    if (!await storage.isBiometricEnabled()) return false;
    return getIt<BiometricService>().isSupported();
  }
}
