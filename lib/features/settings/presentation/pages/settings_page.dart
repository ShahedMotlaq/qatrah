import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qatrah/core/auth/biometric_service.dart';
import 'package:qatrah/core/auth/secure_auth_storage.dart';
import 'package:qatrah/core/auth/sign_out.dart';
import 'package:qatrah/core/constants/app_assets.dart';
import 'package:qatrah/core/constants/app_constants.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/notification/notification_service.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/settings_storage_service.dart';
import 'package:qatrah/core/widgets/app_background_widget.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_identity_widget.dart';
import 'package:qatrah/core/widgets/app_svg_widget.dart';
import 'package:qatrah/core/widgets/appbar/qatrah_appbar_widget.dart';
import 'package:qatrah/core/widgets/appdialog/dynamic_confirm_dialog.dart';
import 'package:qatrah/features/settings/presentation/widgets/reviews_card_widget.dart';
import 'package:qatrah/features/settings/presentation/widgets/settings_outline_tile_widget.dart';
import 'package:qatrah/features/settings/presentation/widgets/social_buttons_widget.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qatrah/core/services/toast_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    this.isEmployee = false,
    super.key,
  });

  final bool isEmployee;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool _notificationsEnabled = false;
  bool _isCheckingNotificationPermission = true;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _showSecuritySection = false;
  bool _pinSet = false;
  String _appVersion = '';
  final SettingsStorageService _settingsStorage =
      getIt<SettingsStorageService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadAppVersion());
    unawaited(_syncNotificationPermission());
    unawaited(_loadSecurityState());
  }

  Future<void> _loadSecurityState() async {
    final storage = getIt<SecureAuthStorage>();
    final isLockable = await storage.isAppLockSession();
    final pinSet = await storage.isPinSet();
    if (!mounted) return;
    setState(() {
      _showSecuritySection = isLockable;
      _pinSet = pinSet;
    });
    if (isLockable) {
      await _loadBiometricState();
    }
  }

  Future<void> _loadBiometricState() async {
    final supported = await getIt<BiometricService>().isSupported();
    final enabled = await getIt<SecureAuthStorage>().isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _handleBiometricToggle(bool value) async {
    final l10n = context.l10n;
    final storage = getIt<SecureAuthStorage>();
    final biometric = getIt<BiometricService>();

    final verified = await context.pushNamed<bool>(Routes.verifyPin);
    if (verified != true || !mounted) return;

    if (!value) {
      await storage.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);
      return;
    }

    // Re-check enrollment — user may have removed fingerprint since page loaded.
    final supported = await biometric.isSupported();
    if (!mounted) return;
    if (!supported) {
      getIt<ToastService>().showError(l10n.biometricNotEnrolled);
      setState(() {
        _biometricEnabled = false;
        _biometricSupported = false;
      });
      return;
    }

    final ok = await biometric.authenticate(reason: l10n.biometricReason);
    if (!mounted) return;
    // ok == false means user cancelled — no error message needed.
    await storage.setBiometricEnabled(ok);
    setState(() => _biometricEnabled = ok);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncNotificationPermission());
      // Re-check biometric enrollment — user may have changed phone settings.
      if (_showSecuritySection && _pinSet) {
        unawaited(_loadBiometricState());
      }
    }
  }

  Future<void> _syncNotificationPermission() async {
    final status = await Permission.notification.status;
    final appEnabled = await _settingsStorage.isNotificationsEnabled();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled =
          appEnabled && (status.isGranted || status.isLimited);
      _isCheckingNotificationPermission = false;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (_isCheckingNotificationPermission) return;

    if (value) {
      final status = await Permission.notification.request();
      if (!mounted) return;

      final granted = status.isGranted || status.isLimited;
      setState(() {
        _notificationsEnabled = granted;
      });

      if (!granted) {
        getIt<ToastService>().showError(
          status.isPermanentlyDenied
              ? context.l10n.notificationPermissionSettingsRequired
              : context.l10n.notificationPermissionDenied,
        );

        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return;
      }

      await getIt<NotificationService>().setNotificationsEnabled(true);
      return;
    }

    await getIt<NotificationService>().setNotificationsEnabled(false);
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = false;
    });
  }

  void _shareApp(AppLocalizations l10n) {
    final storeUrl = Platform.isIOS
        ? AppConstants.appStoreUrl
        : AppConstants.playStoreUrl;
    unawaited(Share.share('${l10n.shareAppMessage}$storeUrl'));
  }

  Future<void> _showLogoutDialogue(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final router = GoRouter.of(context);

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return DynamicConfirmDialog(
          title: l10n.logout,
          message: l10n.logoutConfirmationMessage,
          confirmBtnText: l10n.logout,
          cancelBtnText: l10n.cancel,
          isDangerousAction: true,
          onConfirm: () async {
            // Awaited: the redirect guard reads the storage signOut clears, so
            // navigating first would let it observe a live session and bounce
            // the user back into the app.
            await signOut();
            router.goNamed(Routes.login);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: QatrahAppBarWidget(
        title: Text(l10n.settings),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              30.verticalSpace,
              AppSvgWidget(
                assetsUrl: AppAssets.syrianVerticalGoldIcon,
                height: 100.h,
              ),
              30.verticalSpace,

              // ── Account ──
              _GroupLabel(title: l10n.accountGroup),
              10.verticalSpace,
              SettingsOutlineTileWidget(
                title: l10n.myProfile,
                icon: HugeIcons.strokeRoundedUser03,
                onTap: () => context.pushNamed(Routes.profile),
              ),
              if (!widget.isEmployee) ...[
                10.verticalSpace,
                SettingsOutlineTileWidget(
                  title: l10n.myAddresses,
                  icon: HugeIcons.strokeRoundedLocation01,
                  onTap: () => context.pushNamed(Routes.myAddresses),
                ),
              ],
              if (!widget.isEmployee) ...[
                10.verticalSpace,
                ReviewsCardWidget(
                  title: l10n.myEvaluations,
                  onOpenReviews: () =>
                      context.pushNamed(Routes.myWaterFeedback),
                ),
              ],

              // ── Preferences ──
              20.verticalSpace,
              _GroupLabel(title: l10n.preferencesGroup),
              10.verticalSpace,
              _buildNotificationPermissionTile(theme, l10n),

              // ── Security ──
              if (_showSecuritySection) ...[
                20.verticalSpace,
                _GroupLabel(title: l10n.securitySection),
                10.verticalSpace,
                SettingsOutlineTileWidget(
                  title: _pinSet ? l10n.changePinTitle : l10n.setPinTitle,
                  icon: HugeIcons.strokeRoundedSquareLock02,
                  onTap: () async {
                    if (_pinSet) {
                      await context.pushNamed(Routes.changePin);
                    } else {
                      await context.pushNamed<void>(
                        Routes.createPin,
                        extra: {'fromSettings': true},
                      );
                    }
                    if (mounted) unawaited(_loadSecurityState());
                  },
                ),
                if (_pinSet && _biometricSupported) ...[
                  10.verticalSpace,
                  _buildBiometricTile(theme, l10n),
                ],
              ],

              // ── App ──
              20.verticalSpace,
              _GroupLabel(title: l10n.appGroup),
              10.verticalSpace,
              SettingsOutlineTileWidget(
                title: l10n.about,
                icon: HugeIcons.strokeRoundedInformationCircle,
                onTap: () => context.pushNamed(Routes.about),
              ),
              10.verticalSpace,
              SettingsOutlineTileWidget(
                title: l10n.contactUs,
                icon: HugeIcons.strokeRoundedCustomerService,
                onTap: () => context.pushNamed(Routes.contactUs),
              ),
              10.verticalSpace,
              SettingsOutlineTileWidget(
                title: l10n.shareApp,
                icon: HugeIcons.strokeRoundedShare01,
                onTap: () => _shareApp(l10n),
              ),

              // ── Session ──
              20.verticalSpace,
              _GroupLabel(title: l10n.sessionGroup),
              10.verticalSpace,
              SettingsOutlineTileWidget(
                title: l10n.logout,
                icon: HugeIcons.strokeRoundedLogout02,
                onTap: () => _showLogoutDialogue(context, l10n),
              ),

              10.verticalSpace,
              const SocialButtonsWidget(),
              16.verticalSpace,
              const AppIdentityWidget(),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricTile(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: .5),
        ),
      ),
      child: Row(
        children: [
          const AppIconWidget(icon: HugeIcons.strokeRoundedFingerPrint),
          16.horizontalSpace,
          Expanded(
            child: Text(
              l10n.biometricToggleLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: _biometricEnabled,
            onChanged: _handleBiometricToggle,
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPermissionTile(
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: .5),
        ),
      ),
      child: Row(
        children: [
          const AppIconWidget(
            icon: HugeIcons.strokeRoundedNotification03,
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notificationsTab,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_isCheckingNotificationPermission)
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: _notificationsEnabled,
              onChanged: _handleNotificationToggle,
              thumbColor: WidgetStateProperty.all(Colors.white),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
