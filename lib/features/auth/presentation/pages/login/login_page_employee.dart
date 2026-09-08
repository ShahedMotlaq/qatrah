import 'dart:async';

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
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:qatrah/features/auth/presentation/login_flow.dart';
import 'package:qatrah/features/auth/presentation/widgets/remember_me_checkbox.dart';

// ── Section: Employee Login Page ────────────────────────────────────────────
//
// Same shape as the citizen login page: the submit path owns its own state and
// calls IAuthRepository directly, instead of sharing the app-wide AuthBloc with
// logout events that race this screen.

class LoginPageEmployee extends StatefulWidget {
  const LoginPageEmployee({super.key});

  @override
  State<LoginPageEmployee> createState() => _LoginPageEmployeeState();
}

class _LoginPageEmployeeState extends State<LoginPageEmployee> {
  static const _minPasswordLength = 6;
  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(minutes: 10);

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = true;
  String? _usernameError;
  String? _passwordError;

  Duration? _lockoutRemaining;
  Timer? _lockoutTicker;

  @override
  void initState() {
    super.initState();
    _prefillUsername();
    _refreshLockout();
    _showSessionExpiredNoticeIfPending();
  }

  @override
  void dispose() {
    _lockoutTicker?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isLockedOut => _lockoutRemaining != null;

  Future<void> _prefillUsername() async {
    try {
      final storage = getIt<SecureStorage>();
      final remember = await storage.getEmployeeRememberMe() ?? true;
      if (!mounted) return;
      setState(() => _rememberMe = remember);
      if (!remember) return;
      final saved = await storage.getEmployeeUserName();
      if (!mounted || saved == null || saved.isEmpty) return;
      if (_usernameController.text.isEmpty) _usernameController.text = saved;
    } catch (e) {
      AppLogger.error('Employee login prefill failed: $e');
    }
  }

  Future<void> _showSessionExpiredNoticeIfPending() async {
    final expired = await getIt<AuthSessionService>()
        .consumeSessionExpiredFlag();
    if (!mounted || !expired) return;
    getIt<ToastService>().showWarning(context.l10n.sessionExpiredMessage);
  }

  // ── Section: Lockout ──────────────────────────────────────────────────────

  /// Reads the stored lockout deadline and starts a 1s countdown while it is
  /// still in the future. Brute-force protection, so it is enforced here even
  /// though the server also rate-limits.
  Future<void> _refreshLockout() async {
    Duration? remaining;
    try {
      final until = await getIt<SecureStorage>().getLockoutUntil();
      if (until != null) {
        final left = until.difference(DateTime.now());
        if (left > Duration.zero) remaining = left;
      }
    } catch (e) {
      AppLogger.error('Lockout read failed: $e');
    }

    if (!mounted) return;
    setState(() => _lockoutRemaining = remaining);

    _lockoutTicker?.cancel();
    if (remaining == null) return;

    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      final left = _lockoutRemaining! - const Duration(seconds: 1);
      if (left <= Duration.zero) {
        timer.cancel();
        setState(() => _lockoutRemaining = null);
        return;
      }
      setState(() => _lockoutRemaining = left);
    });
  }

  Future<void> _registerFailedAttempt(String username) async {
    try {
      final storage = getIt<SecureStorage>();
      final attempts = (await storage.getLoginAttempts()) + 1;
      await storage.setLoginAttempts(attempts);
      await storage.addAuditLog('Login failed: $username ($attempts)');

      if (attempts >= _maxAttempts) {
        await storage.setLockoutUntil(DateTime.now().add(_lockoutDuration));
        await _refreshLockout();
      }
    } catch (e) {
      AppLogger.error('Recording failed attempt failed: $e');
    }
  }

  // ── Section: Submit ───────────────────────────────────────────────────────

  Future<void> _login() async {
    if (_isLoading || _isLockedOut) return;

    final l10n = context.l10n;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final usernameError = username.isEmpty
        ? l10n.invalidEmployeeCredential
        : null;
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

    final result = await getIt<IAuthRepository>().employeeLogin(
      username,
      password,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;

    // Loading stays true until we have navigated away or shown the error —
    // see the note on the citizen page.
    await result.fold(
      (failure) async {
        await _registerFailedAttempt(username);
        if (!mounted) return;
        setState(() => _isLoading = false);
        getIt<ToastService>().showError(
          _isLockedOut
              ? l10n.loginTemporarilyDisabledLockout
              : mapAuthError(failure.errMessage, l10n),
        );
      },
      (user) async {
        await completeLogin(
          kind: LoginKind.employee,
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
      appBar: QatrahAppBarWidget(title: Text(l10n.login_employee)),
      extendBody: true,
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Column(
              children: [
                const WaterDropAvatarWidget(),
                16.verticalSpace,
                Text(
                  l10n.appTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                24.verticalSpace,
                if (_lockoutRemaining != null)
                  _LockedOutBanner(remaining: _lockoutRemaining!),
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
                  text: _isLockedOut ? l10n.blocked : l10n.login,
                  isLoading: _isLoading,
                  isDisabled: _isLockedOut,
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section: Locked Out Banner ──────────────────────────────────────────────

class _LockedOutBanner extends StatelessWidget {
  const _LockedOutBanner({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final countdown = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          l10n.loginTemporarilyDisabledLockout,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        8.verticalSpace,
        Text(
          '${l10n.otpBlockedWait}: $countdown',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        20.verticalSpace,
      ],
    );
  }
}
