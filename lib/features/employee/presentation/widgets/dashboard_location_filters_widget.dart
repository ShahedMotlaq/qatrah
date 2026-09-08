import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/formField_wrappers/hierarchy_breadcrumb_field.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

class DashboardLocationFiltersWidget extends StatelessWidget {
  const DashboardLocationFiltersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final bloc = context.read<DashboardBloc>();
        return HierarchyBreadcrumbField<LocationLookupEntity>(
          itemLabel: (e) => e.name,
          levels: [
            BreadcrumbLevel(
              hint: l10n.regionLabel,
              selected: state.selectedRegion,
              items: state.regions,
              onChanged: (val) => bloc.add(FilterRegionChanged(val)),
            ),
            BreadcrumbLevel(
              hint: l10n.unitLabel,
              selected: state.selectedUnit,
              items: state.filterUnits,
              isLoading: state.isFilterUnitsLoading,
              onChanged: (val) => bloc.add(FilterUnitChanged(val)),
            ),
            BreadcrumbLevel(
              hint: l10n.neighborhoodLabel,
              selected: state.selectedNeighborhood,
              items: state.filterNeighborhoods,
              isLoading: state.isFilterNeighborhoodsLoading,
              onChanged: (val) => bloc.add(FilterNeighborhoodChanged(val)),
            ),
            BreadcrumbLevel(
              hint: l10n.zoneLabel,
              selected: state.selectedZone,
              items: state.filterZones,
              isLoading: state.isFilterZonesLoading,
              onChanged: (val) => bloc.add(FilterZoneChanged(val)),
            ),
          ],
        );
      },
    );
  }
}
