import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_text_field_widget.dart';
import 'package:qatrah/core/widgets/app_toast.dart';
import 'package:qatrah/core/widgets/formField_wrappers/app_data_picker_widget.dart';
import 'package:qatrah/core/widgets/formField_wrappers/hierarchy_breadcrumb_field.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

class ScheduleFormFieldsWidget extends StatefulWidget {
  const ScheduleFormFieldsWidget({
    required this.state,
    required this.availableRegions,
    required this.availableUnits,
    required this.selectedRegion,
    required this.selectedUnit,
    required this.selectedNeighborhood,
    required this.selectedZone,
    required this.startTime,
    required this.endTime,
    required this.notesController,
    required this.onRegionChanged,
    required this.onUnitChanged,
    required this.onNeighborhoodChanged,
    required this.onZoneChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    this.formKey,
    super.key,
  });

  final DashboardState state;
  final List<LocationLookupEntity> availableRegions;
  final List<LocationLookupEntity> availableUnits;
  final LocationLookupEntity? selectedRegion;
  final LocationLookupEntity? selectedUnit;
  final LocationLookupEntity? selectedNeighborhood;
  final LocationLookupEntity? selectedZone;
  final DateTime? startTime;
  final DateTime? endTime;
  final TextEditingController notesController;
  final ValueChanged<LocationLookupEntity?> onRegionChanged;
  final ValueChanged<LocationLookupEntity?> onUnitChanged;
  final ValueChanged<LocationLookupEntity?> onNeighborhoodChanged;
  final ValueChanged<LocationLookupEntity?> onZoneChanged;
  final ValueChanged<DateTime?> onStartTimeChanged;
  final ValueChanged<DateTime?> onEndTimeChanged;
  final GlobalKey<FormState>? formKey;

  @override
  State<ScheduleFormFieldsWidget> createState() =>
      _ScheduleFormFieldsWidgetState();
}

class _ScheduleFormFieldsWidgetState extends State<ScheduleFormFieldsWidget> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HierarchyBreadcrumbField<LocationLookupEntity>(
            itemLabel: (e) => e.name,
            validate: true,
            levels: [
              BreadcrumbLevel(
                hint: l10n.regionLabel,
                selected: widget.selectedRegion,
                items: widget.availableRegions,
                onChanged: widget.onRegionChanged,
              ),
              BreadcrumbLevel(
                hint: l10n.unitLabel,
                selected: widget.selectedUnit,
                items: widget.availableUnits,
                isLoading: widget.state.isUnitsLoading,
                onChanged: widget.onUnitChanged,
              ),
              BreadcrumbLevel(
                hint: l10n.neighborhoodLabel,
                selected: widget.selectedNeighborhood,
                items: widget.state.neighborhoods,
                isLoading: widget.state.isNeighborhoodsLoading,
                onChanged: widget.onNeighborhoodChanged,
              ),
              BreadcrumbLevel(
                hint: l10n.zoneLabel,
                selected: widget.selectedZone,
                items: widget.state.zones,
                isLoading: widget.state.isZonesLoading,
                onChanged: widget.onZoneChanged,
              ),
            ],
          ),
          10.verticalSpace,
          AppDatePickerField(
            hintText: l10n.startTime,
            value: widget.startTime,
            onChanged: (newDateTime) {
              if (newDateTime != null) {
                final minimumStart = DateTime.now().add(
                  const Duration(minutes: 2),
                );
                if (newDateTime.isBefore(minimumStart)) {
                  AppToast.show(
                    context: context,
                    message: l10n.scheduleStartTimeTooSoon,
                    type: AppToastType.warning,
                  );
                  return;
                }
              }
              widget.onStartTimeChanged(newDateTime);
            },
            validator: (val) {
              if (val == null || val.isEmpty) {
                return l10n.selectStartTime;
              }
              return null;
            },
          ),
          10.verticalSpace,
          AppDatePickerField(
            hintText: l10n.endTime,
            value: widget.endTime,
            onChanged: widget.onEndTimeChanged,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return l10n.selectEndTime;
              }
              return null;
            },
          ),
          10.verticalSpace,
          AppTextField(
            prefixIcon: const AppIconWidget(
              icon: HugeIcons.strokeRoundedNote,
            ),
            controller: widget.notesController,
            hintText: l10n.notes,
            maxLines: 4,
            minLines: 2,
            keyboardType: TextInputType.multiline,
          ),
          16.verticalSpace,
        ],
      ),
    );
  }
}
