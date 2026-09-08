import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_dropdown_widget.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_event.dart';
import 'package:qatrah/features/profile/presentation/bloc/profile_state.dart';

/// Smart hierarchical location selector rendered as a **breadcrumb**:
/// Region → Unit → Neighborhood → Zone.
///
/// This widget is *presentation only*. It sits on top of [EditProfileBloc],
/// which already fetches each level, cascades the selection downward and
/// auto-selects a level when it has a single option. Here we add:
///   • resolved levels collapse into a compact breadcrumb path (with arrows);
///   • the first unresolved level with 2+ options shows a dropdown;
///   • a pencil on any multi-option step lets the user go back and change it —
///     picking a new value clears every level below it and rebuilds from there
///     (handled by the bloc's existing downstream-reset on re-selection).
///
/// The host must provide [EditProfileBloc] and dispatch [GetRegionsEvent], as
/// the address sheet and complete-profile form already do.
class HierarchyBreadcrumbSelector extends StatefulWidget {
  const HierarchyBreadcrumbSelector({super.key, this.onCompleted});

  /// Called when the deepest level (zone) becomes selected.
  final ValueChanged<EditProfileState>? onCompleted;

  @override
  State<HierarchyBreadcrumbSelector> createState() =>
      _HierarchyBreadcrumbSelectorState();
}

class _HierarchyBreadcrumbSelectorState
    extends State<HierarchyBreadcrumbSelector> {
  /// The level (1..4) the user explicitly chose to re-edit, if any.
  int? _editingLevel;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditProfileBloc, EditProfileState>(
      listenWhen: (prev, curr) => prev.selectedZone != curr.selectedZone,
      listener: (context, state) {
        if (state.selectedZone != null) widget.onCompleted?.call(state);
      },
      builder: (context, state) {
        final firstUnresolved = _firstUnresolvedLevel(state);
        // Active = the level being edited, otherwise the first unresolved one.
        // Guard against an editing index that sits below an unresolved ancestor.
        final active =
            (_editingLevel != null && _editingLevel! <= (firstUnresolved ?? 5))
            ? _editingLevel
            : firstUnresolved;

        // Levels strictly before the active one are resolved → breadcrumb.
        final resolvedCount = (active ?? 5) - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (resolvedCount >= 1)
              _buildBreadcrumb(
                context,
                state,
                resolvedCount,
                allResolved: active == null,
              ),
            if (active != null) ...[
              if (resolvedCount >= 1) 10.verticalSpace,
              _buildActiveLevel(context, state, active),
            ],
          ],
        );
      },
    );
  }

  int? _firstUnresolvedLevel(EditProfileState s) {
    for (var l = 1; l <= 4; l++) {
      if (_selectedAt(s, l) == null) return l;
    }
    return null; // all four resolved
  }

  // ── Breadcrumb ──────────────────────────────────────────────────────────────

  Widget _buildBreadcrumb(
    BuildContext context,
    EditProfileState state,
    int count, {
    required bool allResolved,
  }) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (var l = 1; l <= count; l++) {
      if (l > 1) {
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
      children.add(_buildChip(context, state, l));
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

  Widget _buildChip(BuildContext context, EditProfileState state, int level) {
    final theme = Theme.of(context);
    final selected = _selectedAt(state, level)!;
    // Only multi-option levels are changeable; a single-option level has
    // nothing else to pick.
    final changeable = _itemsAt(state, level).length > 1;

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
            selected.name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (changeable) ...[
            4.horizontalSpace,
            InkWell(
              onTap: () => setState(() => _editingLevel = level),
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

  Widget _buildActiveLevel(
    BuildContext context,
    EditProfileState state,
    int level,
  ) {
    final items = _itemsAt(state, level);
    final loading = _loadingAt(state, level);

    if (!loading && items.isEmpty) {
      return _buildNoData(context);
    }

    // AppDropdownField already collapses to read-only text + auto-selects when
    // the list has a single item, and renders a normal dropdown for 2+ items.
    return AppDropdownField<LocationLookupEntity>(
      hintText: _hintAt(context, level),
      items: items,
      value: _selectedAt(state, level),
      isLoading: loading,
      prefixIcon: const AppIconWidget(
        icon: HugeIcons.strokeRoundedLocation04,
      ),
      onChanged: (value) {
        if (value == null) return;
        context.read<EditProfileBloc>().add(
          LocationSelectionChanged(
            fieldType: _fieldTypeAt(level),
            value: value,
            isDefaultLocation: true,
          ),
        );
        if (_editingLevel != null) {
          setState(() => _editingLevel = null);
        }
      },
      validator: (v) => v == null ? context.l10n.requiredField : null,
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

  // ── Per-level accessors ─────────────────────────────────────────────────────

  LocationLookupEntity? _selectedAt(EditProfileState s, int level) {
    switch (level) {
      case 1:
        return s.selectedRegion;
      case 2:
        return s.selectedUnit;
      case 3:
        return s.selectedNeighborhood;
      default:
        return s.selectedZone;
    }
  }

  List<LocationLookupEntity> _itemsAt(EditProfileState s, int level) {
    switch (level) {
      case 1:
        return s.regions;
      case 2:
        return s.units;
      case 3:
        return s.neighborhoods;
      default:
        return s.zones;
    }
  }

  bool _loadingAt(EditProfileState s, int level) {
    switch (level) {
      case 1:
        return s.isRegionsLoading;
      case 2:
        return s.isUnitsLoading;
      case 3:
        return s.isNeighborhoodsLoading;
      default:
        return s.isZonesLoading;
    }
  }

  String _hintAt(BuildContext context, int level) {
    final l10n = context.l10n;
    switch (level) {
      case 1:
        return l10n.regionLabel;
      case 2:
        return l10n.unitLabel;
      case 3:
        return l10n.neighborhoodLabel;
      default:
        return l10n.zoneLabel;
    }
  }

  String _fieldTypeAt(int level) {
    switch (level) {
      case 1:
        return 'region';
      case 2:
        return 'unit';
      case 3:
        return 'neighborhood';
      default:
        return 'zone';
    }
  }
}
