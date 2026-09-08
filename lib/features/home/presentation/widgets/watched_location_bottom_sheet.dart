import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/buttons/app_button_widget.dart';
import 'package:qatrah/core/widgets/smart_dropdown_field.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

/// Bottom sheet that lets the user pick a location from the hierarchy
/// (region → unit → neighborhood → zone).
class WatchedLocationBottomSheet extends StatefulWidget {
  const WatchedLocationBottomSheet({super.key});

  @override
  State<WatchedLocationBottomSheet> createState() =>
      _WatchedLocationBottomSheetState();
}

class _WatchedLocationBottomSheetState
    extends State<WatchedLocationBottomSheet> {
  @override
  void initState() {
    super.initState();
    final state = context.read<HomeBloc>().state;
    if (state.regions.isEmpty) {
      context.read<HomeBloc>().add(FetchRegionsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconWidget(
                icon: HugeIcons.strokeRoundedLocation04,
                color: theme.colorScheme.primary,
              ),
              8.horizontalSpace,
              Text(
                l10n.locationSelectionTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          20.verticalSpace,
          BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              return Column(
                children: [
                  // Region
                  _HierarchyDropdown(
                    label: l10n.regionLabel,
                    selectedId: state.selectedRegionId,
                    isLoading: state.isRegionsLoading,
                    items: state.regions,
                    onChanged: (id) {
                      if (id != null) {
                        context.read<HomeBloc>().add(SelectRegionEvent(id));
                      }
                    },
                  ),
                  // Unit (only after region is chosen)
                  if (state.selectedRegionId != null) ...[
                    12.verticalSpace,
                    _HierarchyDropdown(
                      label: l10n.unitLabel,
                      selectedId: state.selectedUnitId,
                      isLoading: state.isUnitsLoading,
                      items: state.units,
                      onChanged: (id) {
                        if (id != null) {
                          context.read<HomeBloc>().add(SelectUnitEvent(id));
                        }
                      },
                    ),
                  ],
                  // Neighborhood (only after unit is chosen)
                  if (state.selectedUnitId != null) ...[
                    12.verticalSpace,
                    _HierarchyDropdown(
                      label: l10n.neighborhoodLabel,
                      selectedId: state.selectedNeighborhoodId,
                      isLoading: state.isNeighborhoodsLoading,
                      items: state.neighborhoods,
                      onChanged: (id) {
                        if (id != null) {
                          context.read<HomeBloc>().add(
                            SelectNeighborhoodEvent(id),
                          );
                        }
                      },
                    ),
                  ],
                  // Zone (only after neighborhood is chosen)
                  if (state.selectedNeighborhoodId != null) ...[
                    12.verticalSpace,
                    _HierarchyDropdown(
                      label: l10n.zoneLabel,
                      selectedId: state.selectedZoneId,
                      isLoading: state.isZonesLoading,
                      items: state.zones,
                      onChanged: (id) {
                        if (id != null) {
                          context.read<HomeBloc>().add(SelectZoneEvent(id));
                        }
                      },
                    ),
                  ],
                  24.verticalSpace,
                  AppButton(
                    text: l10n.confirmLocation,
                    onPressed: state.selectedNeighborhoodId == null
                        ? null
                        : () {
                            String? label;
                            if (state.selectedZoneId != null) {
                              label = state.zones
                                  .where(
                                    (e) => e.id == state.selectedZoneId,
                                  )
                                  .firstOrNull
                                  ?.name;
                            }
                            label ??= state.neighborhoods
                                .where(
                                  (e) => e.id == state.selectedNeighborhoodId,
                                )
                                .firstOrNull
                                ?.name;

                            context.read<HomeBloc>().add(
                              UpdateWatchedLocationEvent(
                                neighborhoodId: state.selectedNeighborhoodId,
                                zoneId: state.selectedZoneId,
                                locationName: label,
                              ),
                            );
                            Navigator.pop(context);
                          },
                  ),
                ],
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

// ── Reusable hierarchy dropdown (SmartDropdownField wrapper) ────────────────

class _HierarchyDropdown extends StatelessWidget {
  const _HierarchyDropdown({
    required this.label,
    required this.selectedId,
    required this.isLoading,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final int? selectedId;
  final bool isLoading;
  final List<LocationLookupEntity> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Convert LocationLookupEntity → DropdownItem<int> so the smart widget
    // can handle auto-selection, single-item read-only mode, etc.
    final dropdownItems = items
        .map((e) => DropdownItem<int>(id: e.id, label: e.name))
        .toList();

    return SmartDropdownField<int>(
      items: dropdownItems,
      value: selectedId,
      label: label,
      isLoading: isLoading,
      onChanged: onChanged,
      emptyPlaceholder: '—',
    );
  }
}
