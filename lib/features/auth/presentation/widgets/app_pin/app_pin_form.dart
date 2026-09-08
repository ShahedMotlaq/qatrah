import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/extensions/theme_extension.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/water_icon_avatar_widget.dart';
import 'package:qatrah/features/auth/presentation/bloc/app_pin/app_pin_bloc.dart';
import 'package:qatrah/features/auth/presentation/widgets/app_pin/app_pin_digits_only_formatter.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

// ── Section: Main PIN Form Widget ───────────────────────────────────────────

/// Shared 4-digit PIN entry form used by Create/Unlock/Change PIN screens.
class AppPinForm extends StatefulWidget {
  const AppPinForm({
    required this.title,
    required this.submitLabel,
    super.key,
    this.subtitle,
    this.preSubmit,
    this.trailing,
    this.autoFocus = true,
    this.showSubmit = true,
  });

  final String title;
  final String? subtitle;
  final Widget? preSubmit;
  final String submitLabel;
  final Widget? trailing;
  final bool autoFocus;
  final bool showSubmit;

  @override
  State<AppPinForm> createState() => _AppPinFormState();
}

class _AppPinFormState extends State<AppPinForm> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _ticker;
  String? _digitsOnlyError;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autoFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<AppPinBloc, AppPinState>(
      listenWhen: (a, b) =>
          (a.digits != b.digits && b.digits.isEmpty) ||
          (a.error != b.error && b.error != AppPinError.none),
      listener: (context, state) {
        // Clear the input field whenever the bloc resets digits.
        if (_controller.text.isNotEmpty) {
          _controller.clear();
          if (widget.autoFocus) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _focusNode.requestFocus();
            });
          }
        }
        // Dismiss any transient digits-only error when bloc fires a new event.
        if (_digitsOnlyError != null) setState(() => _digitsOnlyError = null);
      },
      builder: (context, state) {
        final lockSecs = _remainingLockSeconds(state);
        final disabled = state.isLoading || lockSecs > 0;
        final themes = _PinThemes.of(context);

        // Inline error: bloc error takes priority over transient digits-only.
        final blocError = (state.error != AppPinError.none && lockSecs == 0)
            ? _mapError(state.error, l10n)
            : null;
        final displayError =
            blocError ?? (lockSecs == 0 ? _digitsOnlyError : null);

        return LayoutBuilder(
          builder: (context, constraints) {
            const verticalPadding = 24.0;
            final minHeight = constraints.hasBoundedHeight
                ? (constraints.maxHeight - (verticalPadding * 2)).clamp(
                    0.0,
                    double.infinity,
                  )
                : 0.0;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const WaterDropAvatarWidget(radius: 48),
                    16.verticalSpace,
                    Text(
                      widget.title,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.subtitle != null) ...[
                      8.verticalSpace,
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    24.verticalSpace,
                    _PinInput(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !disabled,
                      autoFocus: widget.autoFocus,
                      themes: themes,
                      hasError: displayError != null,
                      onChanged: (value) => context.read<AppPinBloc>().add(
                        AppPinDigitsChanged(value),
                      ),
                      onCompleted: (_) =>
                          context.read<AppPinBloc>().add(const AppPinSubmit()),
                      onRejected: () => _showDigitsOnlyError(l10n),
                    ),
                    8.verticalSpace,
                    if (displayError != null)
                      _InlineError(text: displayError)
                    else if (lockSecs > 0)
                      _LockMessage(seconds: lockSecs),
                    if (widget.preSubmit != null) ...[
                      8.verticalSpace,
                      widget.preSubmit!,
                    ],
                    24.verticalSpace,
                    if (widget.showSubmit)
                      AppButton(
                        text: widget.submitLabel,
                        isLoading: state.isLoading,
                        onPressed: disabled
                            ? null
                            : () => context.read<AppPinBloc>().add(
                                const AppPinSubmit(),
                              ),
                      ),
                    if (widget.trailing != null) ...[
                      16.verticalSpace,
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Section: Private Helpers ──────────────────────────────────────────────

  int _remainingLockSeconds(AppPinState state) {
    final until = state.lockUntil;
    if (until == null) return 0;
    final diff = until.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  void _showDigitsOnlyError(AppLocalizations l10n) {
    if (!mounted) return;
    setState(() => _digitsOnlyError = l10n.pinDigitsOnly);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _digitsOnlyError = null);
    });
  }

  static String _mapError(AppPinError error, AppLocalizations l10n) {
    switch (error) {
      case AppPinError.length:
        return l10n.pinMustBeFourDigits;
      case AppPinError.mismatch:
        return l10n.pinCodesDoNotMatch;
      case AppPinError.invalid:
        return l10n.invalidPinCode;
      case AppPinError.notSet:
        return l10n.pinCodeNotFound;
      case AppPinError.locked:
      case AppPinError.storage:
      case AppPinError.none:
        return '';
    }
  }
}

// ── Section: PIN Input Widget ───────────────────────────────────────────────

class _PinInput extends StatelessWidget {
  const _PinInput({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.autoFocus,
    required this.themes,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
    required this.onRejected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool autoFocus;
  final _PinThemes themes;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final VoidCallback onRejected;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Pinput(
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        obscureText: true,
        inputFormatters: [
          AppPinDigitsOnlyFormatter(onRejected: onRejected),
        ],
        enabled: enabled,
        defaultPinTheme: themes.defaultTheme,
        focusedPinTheme: themes.focusedTheme,
        errorPinTheme: themes.errorTheme,
        submittedPinTheme: themes.submittedTheme,
        forceErrorState: hasError,
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        onChanged: onChanged,
        onCompleted: onCompleted,
      ),
    );
  }
}

// ── Section: Inline Error Widget ────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Section: Lock Message Widget ────────────────────────────────────────────

class _LockMessage extends StatelessWidget {
  const _LockMessage({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      context.l10n.pinTemporarilyLocked(seconds),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.error,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ── Section: PIN Theme Data ─────────────────────────────────────────────────

class _PinThemes {
  _PinThemes._(
    this.defaultTheme,
    this.focusedTheme,
    this.errorTheme,
    this.submittedTheme,
  );

  factory _PinThemes.of(BuildContext context) {
    final colorScheme = context.colorScheme;
    final defaultTheme = PinTheme(
      width: 54.w,
      height: 58.h,
      textStyle: context.textTheme.headlineSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    return _PinThemes._(
      defaultTheme,
      defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          border: Border.all(
            color: colorScheme.primary,
            width: 1.75,
          ),
        ),
      ),
      defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          border: Border.all(color: colorScheme.error),
        ),
      ),
      defaultTheme.copyWith(
        decoration: defaultTheme.decoration!.copyWith(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.secondary),
        ),
      ),
    );
  }

  final PinTheme defaultTheme;
  final PinTheme focusedTheme;
  final PinTheme errorTheme;
  final PinTheme submittedTheme;
}
