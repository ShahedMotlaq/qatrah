// lib/core/services/toast_service.dart
//
// A context-free, globally accessible notification service built on top of
// [bot_toast].  It wraps every message in a branded card showing the Qatrah
// logo so that every toast is instantly recognisable.
//
// Usage:
//   getIt<ToastService>().showError(rawMessage);
//   getIt<ToastService>().showSuccess(l10n.profileUpdated);
//   getIt<ToastService>().showErrorFromFailure(failure);

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/constants/app_assets.dart';
import 'package:qatrah/core/errors/app_error_messages.dart';
import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/theme/app_typography.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

// ---------------------------------------------------------------------------
// Public enum — determines colour + icon of the toast.
// ---------------------------------------------------------------------------

enum ToastType { success, error, warning, info }

// ---------------------------------------------------------------------------
// ToastService
// ---------------------------------------------------------------------------

/// A singleton service that displays branded, context-free toasts via
/// [bot_toast].
///
/// ### Setup (done once in `App`):
/// ```dart
/// // In MaterialApp builder — keep l10n in sync with the widget tree.
/// getIt<ToastService>().updateL10n(AppLocalizations.of(context));
/// ```
///
/// ### Showing toasts (anywhere — no BuildContext needed):
/// ```dart
/// getIt<ToastService>().showError(rawErrorMessage);
/// getIt<ToastService>().showSuccess(l10n.profileSaved);
/// getIt<ToastService>().showErrorFromFailure(failure);
/// ```
class ToastService {
  ToastService._();

  static final ToastService instance = ToastService._();

  // ── l10n reference ──────────────────────────────────────────────────────
  // Updated by the root [MaterialApp] builder on every rebuild so it always
  // reflects the current locale without needing a BuildContext at call-sites.

  AppLocalizations? _l10n;

  /// Call this in `MaterialApp`'s `builder` to keep the l10n reference fresh.
  void updateL10n(AppLocalizations? l10n) {
    if (l10n != null) _l10n = l10n;
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// Shows an error toast.  [rawMessage] is passed through
  /// [AppErrorMessages.localizedMessage] before display so the user always
  /// sees a human-readable string in the app's locale.
  void showError(String rawMessage) {
    _show(message: _localize(rawMessage), type: ToastType.error);
  }

  /// Shows an error toast derived directly from a domain [Failure].
  /// Handles the [AppErrorMessages] encoding transparently.
  void showErrorFromFailure(Failure failure) {
    final msg = _l10n != null
        ? AppErrorMessages.localizedMessage(
            _l10n!,
            failure.errMessage,
            fallbackCode: failure.errorCode,
          )
        : failure.errMessage;
    _show(message: msg, type: ToastType.error);
  }

  /// Shows a success toast with [message] displayed as-is (already localised
  /// by the caller).
  void showSuccess(String message) {
    _show(message: message, type: ToastType.success);
  }

  /// Shows a warning toast.
  void showWarning(String message) {
    _show(message: message, type: ToastType.warning);
  }

  /// Shows an informational toast.
  void showInfo(String message) {
    _show(message: message, type: ToastType.info);
  }

  /// Removes all currently visible toasts immediately.
  void dismissAll() => BotToast.cleanAll();

  // ── Private helpers ──────────────────────────────────────────────────────

  String _localize(String rawMessage) {
    if (_l10n == null) return rawMessage;
    return AppErrorMessages.localizedMessage(_l10n!, rawMessage);
  }

  void _show({required String message, required ToastType type}) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    BotToast.showCustomNotification(
      // [crossPage] keeps the toast alive even while GoRouter pushes a new
      // route — critical for navigation-triggered errors.
      crossPage: true,
      // Allow stacking so rapid errors (e.g. network + auth) are all visible.
      onlyOne: false,
      align: const Alignment(0, -0.95),
      animationDuration: const Duration(milliseconds: 320),
      animationReverseDuration: const Duration(milliseconds: 200),
      duration: const Duration(seconds: 4),
      toastBuilder: (cancelFunc) => _BrandedToastCard(
        message: trimmed,
        type: type,
        onDismiss: cancelFunc,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BrandedToastCard  (private widget — not exported)
// ---------------------------------------------------------------------------

class _BrandedToastCard extends StatelessWidget {
  const _BrandedToastCard({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  // Semantic colour for each toast type.
  Color _accentColor() => switch (type) {
    ToastType.success => AppColors.success,
    ToastType.error => AppColors.error,
    ToastType.warning => AppColors.warning,
    ToastType.info => AppColors.info,
  };

  // Subtle icon paired with the accent colour.
  IconData _iconData() => switch (type) {
    ToastType.success => Icons.check_circle_rounded,
    ToastType.error => Icons.error_rounded,
    ToastType.warning => Icons.warning_rounded,
    ToastType.info => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final icon = _iconData();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.up,
        onDismissed: (_) => onDismiss(),
        child: Material(
          color: AppColors.transparent,
          child: Container(
            padding: EdgeInsets.fromLTRB(12.w, 0, 4.w, 0),
            decoration: BoxDecoration(
              // Dark surface works in both light and dark environments and
              // ensures the white text always has sufficient contrast.
              color: const Color(0xFF1B2A35),
              borderRadius: BorderRadius.circular(14.r),
              // A coloured top stripe gives instant visual feedback about the
              // toast category without relying on colour alone (accessibility).
              border: Border(
                top: BorderSide(color: accent, width: 3.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // ── Branded logo avatar ──────────────────────────────────
                // Positioned first so it appears on the leading (right) side
                // in RTL Arabic layout.
                _LogoAvatar(accent: accent),
                SizedBox(width: 10.w),

                // ── Divider ──────────────────────────────────────────────
                Container(
                  width: 1,
                  height: 36.h,
                  color: accent.withValues(alpha: 0.35),
                ),
                SizedBox(width: 10.w),

                // ── Status icon ──────────────────────────────────────────
                Icon(icon, color: accent, size: 18.sp),
                SizedBox(width: 8.w),

                // ── Message text ─────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                      // [textAlign: TextAlign.start] respects RTL/LTR
                      // automatically — no hardcoded direction needed.
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),

                // ── Dismiss button ───────────────────────────────────────
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 16.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LogoAvatar  (private — the branded element)
// ---------------------------------------------------------------------------

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9.r),
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Image.asset(
            AppAssets.logoImg,
            fit: BoxFit.contain,
            // Graceful fallback if asset is missing in a test environment.
            errorBuilder: (_, _, _) => Icon(
              Icons.water_drop_rounded,
              color: accent,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }
}
