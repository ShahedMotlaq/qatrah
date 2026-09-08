import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_dropdown_widget.dart';

/// One level of a cascading hierarchy (e.g. Region / Unit / Neighborhood / Zone).
class BreadcrumbLevel<T> {
  const BreadcrumbLevel({
    required this.hint,
    required this.selected,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
  });

  final String hint;
  final T? selected;
  final List<T> items;
  final bool isLoading;
  final ValueChanged<T?> onChanged;
}

/// Generic, bloc-agnostic hierarchical selector rendered as a **breadcrumb**.
///
/// Resolved levels collapse into compact chips (with a pencil to re-edit a
/// multi-option step), and only the first unresolved level shows a dropdown.
/// This mirrors the location selector used on the "My Addresses" screen, but
/// is driven entirely by the [levels] you pass in — so any feature (dashboard
/// filters, create-schedule form, …) can reuse it.
class HierarchyBreadcrumbField<T> extends StatefulWidget {
  const HierarchyBreadcrumbField({
    required this.levels,
    required this.itemLabel,
    this.validate = false,
    this.prefixIcon,
    super.key,
  });

  final List<BreadcrumbLevel<T>> levels;
  final String Function(T) itemLabel;

  /// When true, the active dropdown requires a selection (form validation).
  final bool validate;

  /// Icon shown on the active dropdown. Defaults to a location pin.
  final Widget? prefixIcon;

  @override
  State<HierarchyBreadcrumbField<T>> createState() =>
      _HierarchyBreadcrumbFieldState<T>();
}

class _HierarchyBreadcrumbFieldState<T>
    extends State<HierarchyBreadcrumbField<T>> {
  /// The level the user explicitly chose to re-edit, if any.
  int? _editingLevel;

  int? _firstUnresolved() {
    for (var i = 0; i < widget.levels.length; i++) {
      if (widget.levels[i].selected == null) return i;
    }
    return null; // all resolved
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.levels;
    final firstUnresolved = _firstUnresolved();
    // Active = the level being edited, unless it sits below an unresolved
    // ancestor; otherwise the first unresolved level.
    final active =
        (_editingLevel != null &&
            _editingLevel! <= (firstUnresolved ?? levels.length))
        ? _editingLevel
        : firstUnresolved;

    // Levels strictly before the active one are resolved → breadcrumb chips.
    final resolvedCount = active ?? levels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resolvedCount >= 1)
          _buildBreadcrumb(context, resolvedCount, allResolved: active == null),
        if (active != null) ...[
          if (resolvedCount >= 1) 10.verticalSpace,
          _buildActiveLevel(context, active),
        ],
      ],
    );
  }

  // ── Breadcrumb ─────────────────────────────────────────────────────────────

  Widget _buildBreadcrumb(
    BuildContext context,
    int count, {
    required bool allResolved,
  }) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (var i = 0; i < count; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Icon(
              Icons.chevron_left,
              size: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      children.add(_buildChip(context, i));
    }

    if (allResolved) {
      children.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: AppIconWidget(
            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
            size: 18.sp,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 6.h,
      children: children,
    );
  }

  Widget _buildChip(BuildContext context, int index) {
    final theme = Theme.of(context);
    final level = widget.levels[index];
    final selected = level.selected as T;
    // Only multi-option levels are changeable.
    final changeable = level.items.length > 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.itemLabel(selected),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (changeable) ...[
            4.horizontalSpace,
            InkWell(
              onTap: () => setState(() => _editingLevel = index),
              borderRadius: BorderRadius.circular(999),
              child: Icon(
                Icons.edit_outlined,
                size: 14.sp,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Active level (dropdown / loading / no-data) ─────────────────────────────

  Widget _buildActiveLevel(BuildContext context, int index) {
    final level = widget.levels[index];

    if (!level.isLoading && level.items.isEmpty) {
      return _buildNoData(context);
    }

    return AppDropdownField<T>(
      hintText: level.hint,
      items: level.items,
      value: level.selected,
      isLoading: level.isLoading,
      itemLabel: widget.itemLabel,
      prefixIcon:
          widget.prefixIcon ??
          const AppIconWidget(icon: HugeIcons.strokeRoundedLocation04),
      onChanged: (value) {
        if (value == null) return;
        level.onChanged(value);
        if (_editingLevel != null) {
          setState(() => _editingLevel = null);
        }
      },
      validator: widget.validate
          ? (v) => v == null ? context.l10n.requiredField : null
          : null,
    );
  }

  Widget _buildNoData(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppIconWidget(
          icon: HugeIcons.strokeRoundedAlertCircle,
          size: 16.sp,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        8.horizontalSpace,
        Text(
          context.l10n.noData,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
