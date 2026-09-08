import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/auth/biometric_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_text_button_widget.dart';
import 'package:qatrah/core/services/toast_service.dart';

/// Optional biometric setup, shown right after PIN setup or change.
/// Enforces that a PIN must be set before biometric can be enabled.
class BiometricSetupPage extends StatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  State<BiometricSetupPage> createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends State<BiometricSetupPage> {
  bool _busy = false;

  Future<void> _enable() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _doEnable();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _doEnable() async {
    final storage = getIt<SecureAuthStorage>();
    final biometric = getIt<BiometricService>();

    // 1. PIN is required as fallback before biometric can be enabled.
    final pinSet = await storage.isPinSet();
    if (!pinSet) {
      if (!mounted) return;
      // Prompt user to set a PIN first; createPin pops back on completion.
      await context.pushNamed<void>(
        Routes.createPin,
        extra: {'fromSettings': true},
      );
      if (!mounted) return;
      // If user backed out without setting PIN, skip biometric too.
      if (!await storage.isPinSet()) {
        _finish();
        return;
      }
    }

    // 2. Biometric must be enrolled on the device.
    if (!await biometric.isSupported()) {
      if (!mounted) return;
      getIt<ToastService>().showError(context.l10n.biometricNotEnrolled);
      await storage.setBiometricEnabled(false);
      if (mounted) _finish();
      return;
    }

    // 3. Confirm with actual biometric authentication.
    if (!mounted) return;
    final ok = await biometric.authenticate(
      reason: context.l10n.biometricReason,
    );
    await storage.setBiometricEnabled(ok);
    if (mounted) _finish();
  }

  Future<void> _skip() async {
    await getIt<SecureAuthStorage>().setBiometricEnabled(false);
    if (mounted) _finish();
  }

  void _finish() {
    context.goNamed(Routes.navbar);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: QatrahAppBarWidget(
          title: Text(l10n.biometricSetupTitle),
          leading: const SizedBox.shrink(),
        ),
        body: AppBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconWidget(
                  icon: HugeIcons.strokeRoundedFingerPrint,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                24.verticalSpace,
                Text(
                  l10n.biometricSetupTitle,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                12.verticalSpace,
                Text(
                  l10n.biometricSetupSubtitle,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                32.verticalSpace,
                AppButton(
                  text: _busy ? l10n.loading : l10n.biometricEnable,
                  onPressed: _busy ? null : _enable,
                ),
                12.verticalSpace,
                AppTextButton(
                  text: l10n.biometricSkip,
                  onPressed: _busy ? null : _skip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
