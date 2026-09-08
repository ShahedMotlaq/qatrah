import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/auth/auth_session_service.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';
import 'package:qatrah/core/utils/app_logger.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_text_button_widget.dart';
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:qatrah/features/auth/presentation/login_flow.dart';
import 'package:qatrah/features/auth/presentation/widgets/remember_me_checkbox.dart';

// ── Section: Citizen Login Page ─────────────────────────────────────────────
//
// Deliberately self-contained: the submit path talks to IAuthRepository
// directly instead of routing through the app-wide AuthBloc. The bloc is
// shared with logout, and its background transitions were racing this page —
// leaving the button wired to a state the bloc had already moved past, so taps
// did nothing at all in release builds. Local state here has one owner: this
// page.

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _minPasswordLength = 6;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _prefillUsername();
    _showSessionExpiredNoticeIfPending();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Restores the remembered username. Never the password.
  Future<void> _prefillUsername() async {
    try {
      final storage = getIt<SecureStorage>();
      final remember = await storage.getCitizenRememberMe() ?? true;
      if (!mounted) return;
      setState(() => _rememberMe = remember);
      if (!remember) return;
      final saved = await storage.getUserName();
      if (!mounted || saved == null || saved.isEmpty) return;
      if (_usernameController.text.isEmpty) _usernameController.text = saved;
    } catch (e) {
      AppLogger.error('Login prefill failed: $e');
    }
  }

  Future<void> _showSessionExpiredNoticeIfPending() async {
    final expired = await getIt<AuthSessionService>()
        .consumeSessionExpiredFlag();
    if (!mounted || !expired) return;
    getIt<ToastService>().showWarning(context.l10n.sessionExpiredMessage);
  }

  // ── Section: Submit ───────────────────────────────────────────────────────

  Future<void> _login() async {
    if (_isLoading) return;

    final l10n = context.l10n;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final usernameError = username.isEmpty ? l10n.requiredField : null;
    final passwordError = password.length < _minPasswordLength
        ? l10n.passwordTooShort(_minPasswordLength)
        : null;

    setState(() {
      _usernameError = usernameError;
      _passwordError = passwordError;
    });
    if (usernameError != null || passwordError != null) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await getIt<IAuthRepository>().citizenLogin(
      username,
      password,
    );
    if (!mounted) return;

    // The spinner stays up until we have either navigated away or shown the
    // error. Clearing it before the bookkeeping/navigation left an enabled,
    // idle-looking button that accepted a second tap and fired a second login.
    await result.fold(
      (failure) async {
        if (!mounted) return;
        setState(() => _isLoading = false);
        getIt<ToastService>().showError(mapAuthError(failure.errMessage, l10n));
      },
      (user) async {
        await completeLogin(
          kind: LoginKind.citizen,
          username: username,
          rememberMe: _rememberMe,
        );
        if (!mounted) return;
        context.goNamed(Routes.navbar);
      },
    );
  }

  // ── Section: Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QatrahAppBarWidget(title: Text(l10n.login_citizens)),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              children: [
                16.verticalSpace,
                const WaterDropAvatarWidget(),
                16.verticalSpace,
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                24.verticalSpace,
                AppTextField(
                  controller: _usernameController,
                  hintText: l10n.username,
                  errorText: _usernameError,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[],
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  prefixIcon: const AppIconWidget(
                    icon: HugeIcons.strokeRoundedUser03,
                  ),
                  onChanged: (_) {
                    if (_usernameError != null) {
                      setState(() => _usernameError = null);
                    }
                  },
                ),
                20.verticalSpace,
                AppTextField(
                  controller: _passwordController,
                  hintText: l10n.password,
                  isPassword: true,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  autofillHints: const <String>[],
                  enableSuggestions: false,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  prefixIcon: const AppIconWidget(
                    icon: HugeIcons.strokeRoundedCircleLock02,
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                ),
                8.verticalSpace,
                RememberMeCheckbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v),
                ),
                20.verticalSpace,
                AppButton(
                  text: l10n.login,
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                10.verticalSpace,
                AppTextButton(
                  text: l10n.createAccount,
                  color: theme.primaryColor,
                  onPressed: _isLoading
                      ? null
                      : () => context.pushNamed(Routes.registerCitizen),
                ),
                10.verticalSpace,
                AppTextButton(
                  text: l10n.login_employee,
                  color: theme.primaryColor,
                  onPressed: _isLoading
                      ? null
                      : () => context.pushNamed(Routes.loginPageEmployee),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
