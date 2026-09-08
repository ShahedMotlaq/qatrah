import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/toast_service.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';
import 'package:qatrah/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:qatrah/features/auth/presentation/login_flow.dart';

class RegisterCitizenPage extends StatefulWidget {
  const RegisterCitizenPage({super.key});

  @override
  State<RegisterCitizenPage> createState() => _RegisterCitizenPageState();
}

class _RegisterCitizenPageState extends State<RegisterCitizenPage> {
  static const _minPasswordLength = 6;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: QatrahAppBarWidget(title: Text(l10n.createAccount)),
      body: AppBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Form(
              key: _formKey,
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
                  AppTextField(
                    controller: _usernameController,
                    hintText: l10n.username,
                    autofillHints: const <String>[],
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedUser03,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                  20.verticalSpace,
                  AppTextField(
                    controller: _fullNameController,
                    hintText: l10n.fullName,
                    autofillHints: const <String>[],
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedUser03,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                  20.verticalSpace,
                  AppTextField(
                    controller: _passwordController,
                    hintText: l10n.password,
                    isPassword: true,
                    autofillHints: const <String>[],
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedCircleLock02,
                    ),
                    validator: (value) {
                      if (value == null || value.length < _minPasswordLength) {
                        // The message takes the *minimum*, not what was typed —
                        // it used to echo the typed length ("at least 3
                        // characters" after typing 3).
                        return l10n.passwordTooShort(_minPasswordLength);
                      }
                      return null;
                    },
                  ),
                  30.verticalSpace,
                  AppButton(
                    text: l10n.createAccountBtn,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final username = _usernameController.text.trim();

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final result = await getIt<IAuthRepository>().citizenRegister(
      username: username,
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;

    await result.fold(
      (failure) async {
        if (!mounted) return;
        setState(() => _isLoading = false);
        getIt<ToastService>().showError(mapAuthError(failure.errMessage, l10n));
      },
      (user) async {
        // A successful register signs the user straight in, so it needs the
        // same bookkeeping as a login — it used to skip the username, the
        // audit entry and the attempt reset.
        await completeLogin(kind: LoginKind.citizen, username: username);
        if (!mounted) return;
        getIt<ToastService>().showSuccess(l10n.registrationSuccess);
        context.goNamed(Routes.navbar);
      },
    );
  }
}
