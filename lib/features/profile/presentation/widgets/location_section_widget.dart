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

class LocationSectionWidget extends StatelessWidget {
  const LocationSectionWidget({
    required this.title,
    required this.isDefaultLocation,
    super.key,
    this.isReadOnly = false,
  });

  final String title;
  final bool isDefaultLocation;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<EditProfileBloc, EditProfileState>(
      builder: (context, state) {
        return Column(
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
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            16.verticalSpace,
            ListBody(
              children: [
                // 1. Region (always shown)
                AppDropdownField<LocationLookupEntity>(
                  hintText: l10n.region,
                  items: state.regions,
                  value: state.selectedRegion,
                  isLoading: state.isRegionsLoading,
                  prefixIcon: const AppIconWidget(
                    icon: HugeIcons.strokeRoundedLocation04,
                  ),
                  onChanged: isReadOnly
                      ? null
                      : (val) => _dispatchLocationEvent(context, 'region', val),
                  validator: (val) => val == null ? l10n.fieldRequired : null,
                ),

                // 2. Unit (shown only when region is selected)
                if (state.selectedRegion != null) ...[
                  12.verticalSpace,
                  AppDropdownField<LocationLookupEntity>(
                    hintText: l10n.unit,
                    items: state.units,
                    value: state.selectedUnit,
                    isLoading: state.isUnitsLoading,
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedNavigation03,
                    ),
                    onChanged: isReadOnly
                        ? null
                        : (val) => _dispatchLocationEvent(context, 'unit', val),
                    validator: (val) => val == null ? l10n.fieldRequired : null,
                  ),
                ],

                // 3. Neighborhood (shown only when unit is selected)
                if (state.selectedUnit != null) ...[
                  12.verticalSpace,
                  AppDropdownField<LocationLookupEntity>(
                    hintText: l10n.neighborhood,
                    items: state.neighborhoods,
                    value: state.selectedNeighborhood,
                    isLoading: state.isNeighborhoodsLoading,
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedLocation04,
                    ),
                    onChanged: isReadOnly
                        ? null
                        : (val) => _dispatchLocationEvent(
                            context,
                            'neighborhood',
                            val,
                          ),
                    validator: (val) => val == null ? l10n.fieldRequired : null,
                  ),
                ],

                // 4. Zone (shown only when neighborhood is selected)
                if (state.selectedNeighborhood != null) ...[
                  12.verticalSpace,
                  AppDropdownField<LocationLookupEntity>(
                    hintText: l10n.zone,
                    items: state.zones,
                    value: state.selectedZone,
                    isLoading: state.isZonesLoading,
                    prefixIcon: const AppIconWidget(
                      icon: HugeIcons.strokeRoundedLocation04,
                    ),
                    onChanged: isReadOnly
                        ? null
                        : (val) => _dispatchLocationEvent(context, 'zone', val),
                    validator: (val) => val == null ? l10n.fieldRequired : null,
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  void _dispatchLocationEvent(
    BuildContext context,
    String fieldType,
    LocationLookupEntity? value,
  ) {
    if (value != null) {
      context.read<EditProfileBloc>().add(
        LocationSelectionChanged(
          fieldType: fieldType,
          value: value,
          isDefaultLocation: isDefaultLocation,
        ),
      );
    }
  }
}
