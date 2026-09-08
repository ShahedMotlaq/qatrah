import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';

/// A smart dropdown field that automatically:
///
/// 1. **Auto-selects** the only item when the list contains exactly one
///    element — no user interaction required.
/// 2. **Collapses to read-only text** when only one item exists, avoiding
///    a redundant dropdown that wastes space.
/// 3. **Expands back to a normal [DropdownButtonFormField]** as soon as the
///    list grows to 2+ items.
/// 4. Shows a small **Check-circle icon** next to the auto-selected text so
///    the user knows the selection happened automatically.
/// 5. Shows a **disabled placeholder** when the list is empty or still
///    loading.
/// 6. **Guards against redundant selection**: if the user taps the same
///    already-selected value, [onChanged] is NOT called.
class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    required this.hintText,
    required this.items,
    super.key,
    this.value,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.isLoading = false,
    this.itemLabel,
  });

  final String hintText;
  final T? value;
  final List<T> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final bool isLoading;
  final String Function(T)? itemLabel;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  @override
  void initState() {
    super.initState();
    _maybeAutoSelect();
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-evaluate auto-selection whenever the items list changes.
    if (widget.items != oldWidget.items ||
        widget.items.length != oldWidget.items.length) {
      _maybeAutoSelect();
    }
  }

  /// If the list has exactly one item and no value is currently selected,
  /// automatically select it and notify the parent.
  void _maybeAutoSelect() {
    if (widget.items.length == 1 &&
        widget.value == null &&
        widget.onChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged!(widget.items.first);
      });
    }
  }

  /// Guard: don't propagate the change if the user re-selected the same value.
  void _handleChanged(T? newValue) {
    if (newValue == widget.value) return;
    widget.onChanged?.call(newValue);
  }

  String _labelOf(T item) {
    return widget.itemLabel != null ? widget.itemLabel!(item) : item.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: child,
        ),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Loading state.
    if (widget.isLoading) {
      return _buildLoadingField(context);
    }

    // Empty list.
    if (widget.items.isEmpty) {
      return _buildEmptyField(context);
    }

    // Exactly one item — read-only text with auto-select indicator.
    if (widget.items.length == 1) {
      return _buildAutoSelectedField(context);
    }

    // 2+ items — normal dropdown.
    return _buildDropdownField(context);
  }

  Widget _buildLoadingField(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        suffixIcon: SizedBox(
          width: 18.r,
          height: 18.r,
          child: AppLoadingWidget(size: 18.r),
        ),
        border: _outlineBorder(
          theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        enabledBorder: _outlineBorder(
          theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      ),
      child: Text(
        widget.hintText,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildEmptyField(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<T>(
      validator: widget.validator,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon,
            suffixIcon: AppIconWidget(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: 18.sp,
              color: theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            errorText: field.errorText,
            border: _outlineBorder(
              theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            enabledBorder: _outlineBorder(
              theme.colorScheme.outline.withValues(alpha: 0.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 14.h,
            ),
          ),
          child: Text(
            widget.hintText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  /// Elegant label tile for the single-item auto-selected case.
  /// Shows a bold label above the value — no dropdown arrow needed.
  Widget _buildAutoSelectedField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedItem = widget.items.first;

    return FormField<T>(
      initialValue: selectedItem,
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    widget.prefixIcon!,
                    10.horizontalSpace,
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.hintText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        3.verticalSpace,
                        Text(
                          _labelOf(selectedItem),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  8.horizontalSpace,
                  AppIconWidget(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                    size: 18.sp,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: EdgeInsets.only(top: 4.h, right: 12.w, left: 12.w),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Normal dropdown for 2+ items.
  Widget _buildDropdownField(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      elevation: 4,
      style: theme.textTheme.labelMedium,
      icon: const Icon(Icons.keyboard_arrow_down),
      initialValue: widget.value,
      decoration: InputDecoration(
        prefixIconColor: AppColors.darkPrimary,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        border: _outlineBorder(theme.colorScheme.outline),
        enabledBorder: _outlineBorder(theme.colorScheme.outline),
        focusedBorder: _outlineBorder(theme.colorScheme.primary, width: 2),
        disabledBorder: _outlineBorder(
          theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
        errorBorder: _outlineBorder(theme.colorScheme.error),
        focusedErrorBorder: _outlineBorder(theme.colorScheme.error, width: 2),
      ),
      items: widget.items.map((e) {
        return DropdownMenuItem<T>(
          value: e,
          child: Text(_labelOf(e)),
        );
      }).toList(),
      onChanged: _handleChanged,
      validator: widget.validator,
    );
  }

  OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
