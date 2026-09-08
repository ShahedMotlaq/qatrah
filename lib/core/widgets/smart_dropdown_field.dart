import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown Item Model
// ─────────────────────────────────────────────────────────────────────────────

/// Generic dropdown item model. Use this to wrap any entity that needs
/// to appear inside a [SmartDropdownField].
class DropdownItem<T> {
  const DropdownItem({required this.id, required this.label});

  final T id;
  final String label;

  @override
  String toString() => label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Dropdown Field
// ─────────────────────────────────────────────────────────────────────────────

/// A smart hierarchical-dropdown field that automatically:
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
///
/// ## State-management contract
/// * The parent (Bloc / Cubit) owns the selected `value`.
/// * When a single item is detected inside the widget, [onChanged] is called
///   with that item's `id` so the state manager can persist it.
/// * When the list later changes and has >1 item, the widget simply renders
///   a normal dropdown and waits for the user.
class SmartDropdownField<T> extends StatefulWidget {
  const SmartDropdownField({
    required this.items,
    required this.value,
    required this.label,
    required this.onChanged,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.showAutoSelectIndicator = true,
    this.autoSelectIcon = HugeIcons.strokeRoundedCheckmarkCircle01,
    this.widthPercent = 0.9,
    this.textStyle,
    this.borderColor,
    this.autoSelectBgColor,
    super.key,
  });

  /// List of available options.
  final List<DropdownItem<T>> items;

  /// Currently selected value (managed by parent state).
  final T? value;

  /// Label / hint shown above the field (dropdown mode) or inside the
  /// read-only text box (single-item mode).
  final String label;

  /// Called whenever the selection changes — including automatic selection
  /// of a single item.
  final ValueChanged<T?> onChanged;

  /// Whether the underlying data is still being fetched.
  final bool isLoading;

  /// Text shown when [items] is empty. If `null` the [label] is reused.
  final String? emptyPlaceholder;

  /// When `true` a small check-circle icon appears next to the auto-selected
  /// read-only text.
  final bool showAutoSelectIndicator;

  /// HugeIcon used as the auto-selection indicator.
  final List<List<dynamic>> autoSelectIcon;

  /// Width as a percentage of screen width (default 0.9 = 90 %).
  final double widthPercent;

  /// Optional text style for the read-only single-item mode.
  final TextStyle? textStyle;

  /// Border colour for both modes.
  final Color? borderColor;

  /// Background colour for the read-only single-item box.
  final Color? autoSelectBgColor;

  @override
  State<SmartDropdownField<T>> createState() => _SmartDropdownFieldState<T>();
}

class _SmartDropdownFieldState<T> extends State<SmartDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _maybeAutoSelect(widget.items);
  }

  @override
  void didUpdateWidget(covariant SmartDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Whenever the items list changes (by identity or length) we re-evaluate
    // the single-item auto-selection rule.
    if (widget.items != oldWidget.items ||
        widget.items.length != oldWidget.items.length) {
      _maybeAutoSelect(widget.items);
    }
  }

  /// If the list has exactly one item and no value is currently selected,
  /// automatically select it and notify the parent.
  void _maybeAutoSelect(List<DropdownItem<T>> items) {
    if (items.length == 1 && widget.value == null) {
      // Post-frame so we don't call setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(items.first.id);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Builders ───────────────────────────────────────────────────────────

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
    // Loading — show a disabled-looking field with a spinner.
    if (widget.isLoading) {
      return _buildLoadingField(context);
    }

    // Empty — show placeholder text.
    if (widget.items.isEmpty) {
      return _buildEmptyField(context);
    }

    // Exactly one item — render read-only text with optional indicator.
    if (widget.items.length == 1) {
      return _buildAutoSelectedField(context);
    }

    // 2+ items — normal dropdown.
    return _buildDropdownField(context);
  }

  /// A disabled field shown while data is loading.
  Widget _buildLoadingField(BuildContext context) {
    final theme = Theme.of(context);
    return _fieldBox(
      context,
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: _effectiveTextStyle(context)?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 18.r,
            height: 18.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      bgColor: theme.colorScheme.surface.withValues(alpha: 0.5),
      borderColor: theme.colorScheme.outline.withValues(alpha: 0.5),
    );
  }

  /// Placeholder shown when the list is empty.
  Widget _buildEmptyField(BuildContext context) {
    final theme = Theme.of(context);
    return _fieldBox(
      context,
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.emptyPlaceholder ?? widget.label,
              style: _effectiveTextStyle(context)?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppIconWidget(
            icon: HugeIcons.strokeRoundedAlertCircle,
            size: 18.sp,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ],
      ),
      bgColor: theme.colorScheme.surface.withValues(alpha: 0.5),
      borderColor: theme.colorScheme.outline.withValues(alpha: 0.5),
    );
  }

  /// Read-only text Title for the single-item case.
  ///
  /// Instead of a redundant dropdown with one option, we show a clean
  /// text row: "Label: Value" with a small info icon so the user knows
  /// the system selected it automatically.
  Widget _buildAutoSelectedField(BuildContext context) {
    final theme = Theme.of(context);
    final selectedItem = widget.items.firstWhere(
      (item) => item.id == widget.value,
      orElse: () => widget.items.first,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      child: Row(
        children: [
          // Label (dimmed) + value (bold)
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: _effectiveTextStyle(context),
                children: [
                  TextSpan(
                    text: '${widget.label}: ',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                      fontSize: 13.sp,
                    ),
                  ),
                  TextSpan(
                    text: selectedItem.label,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Small info icon indicating auto-selection
          if (widget.showAutoSelectIndicator) ...[
            SizedBox(width: 6.w),
            Tooltip(
              message: 'Auto-selected (only option available)',
              child: AppIconWidget(
                icon: widget.autoSelectIcon,
                size: 16.sp,
                color: theme.colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Normal dropdown for 2+ items.
  Widget _buildDropdownField(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: MediaQuery.of(context).size.width * widget.widthPercent,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: widget.value,
        hint: Text(widget.label),
        icon: AppIconWidget(
          icon: HugeIcons.strokeRoundedArrowDown01,
          size: 18.sp,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 14.h,
          ),
          border: _outlineBorder(theme.colorScheme.outline),
          enabledBorder: _outlineBorder(
            widget.borderColor ?? theme.colorScheme.outline,
          ),
          focusedBorder: _outlineBorder(theme.colorScheme.primary, width: 2),
          disabledBorder: _outlineBorder(
            theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        items: widget.items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item.id,
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (val) => widget.onChanged(val),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _fieldBox(
    BuildContext context, {
    required Widget child,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * widget.widthPercent,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: child,
    );
  }

  TextStyle? _effectiveTextStyle(BuildContext context) {
    return widget.textStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 14.sp,
        );
  }

  OutlineInputBorder _outlineBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.r),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
