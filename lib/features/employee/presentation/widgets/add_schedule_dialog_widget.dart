import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/utils/user_helper.dart';
import 'package:qatrah/core/widgets/app_toast.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_event.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/add_schedule_dialog_actions_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_form_fields_widget.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/profile/domain/entities/location_lookup_entity.dart';

class AddScheduleDialogWidget extends StatefulWidget {
  const AddScheduleDialogWidget({super.key});

  @override
  State<AddScheduleDialogWidget> createState() =>
      _AddScheduleDialogWidgetState();
}

class _AddScheduleDialogWidgetState extends State<AddScheduleDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  List<int> _assignedUnitIds = const [];
  List<int> _assignedRegionIds = const [];
  bool _isEmployeeScoped = false;
  bool _isPermissionLoading = true;

  LocationLookupEntity? _selectedRegion;
  LocationLookupEntity? _selectedUnit;
  LocationLookupEntity? _selectedNeighborhood;
  LocationLookupEntity? _selectedZone;

  DateTime? _startTime;
  DateTime? _endTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOperatorScope();
  }

  Future<void> _loadOperatorScope() async {
    final isEmployee = await UserHelper.isOperator();
    final isAdmin = await UserHelper.isAdmin();
    final shouldScopeToAssignedUnits = isEmployee && !isAdmin;
    final assignedUnitIds = isEmployee
        ? await UserHelper.getAssignedUnitIds()
        : const <int>[];
    final assignedRegionIds = isEmployee
        ? await UserHelper.getAssignedRegionIds()
        : const <int>[];

    if (!mounted) return;
    setState(() {
      _isEmployeeScoped = shouldScopeToAssignedUnits;
      _assignedUnitIds = assignedUnitIds;
      _assignedRegionIds = assignedRegionIds;
      _isPermissionLoading = false;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext context, DashboardState state) {
    if (_isPermissionLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_isEmployeeScoped) {
      if (_assignedUnitIds.isEmpty) {
        AppToast.show(
          context: context,
          message: context.l10n.noAssignedUnitsCannotAddSchedule,
          type: AppToastType.error,
        );
        return;
      }

      final selectedUnitId = _selectedUnit?.id;
      if (selectedUnitId == null ||
          !_assignedUnitIds.contains(selectedUnitId)) {
        AppToast.show(
          context: context,
          message: context.l10n.forbidden,
          type: AppToastType.error,
        );
        return;
      }

      final selectedRegionId = _selectedRegion?.id;
      if (selectedRegionId == null ||
          !_assignedRegionIds.contains(selectedRegionId)) {
        AppToast.show(
          context: context,
          message: context.l10n.forbidden,
          type: AppToastType.error,
        );
        return;
      }
    }

    if (_startTime == null) {
      AppToast.show(
        context: context,
        message: context.l10n.selectStartTime,
        type: AppToastType.warning,
      );
      return;
    }
    if (_endTime == null) {
      AppToast.show(
        context: context,
        message: context.l10n.selectEndTime,
        type: AppToastType.warning,
      );
      return;
    }

    if (!_endTime!.isAfter(_startTime!)) {
      AppToast.show(
        context: context,
        message: context.l10n.endDateMustBeAfterStart,
        type: AppToastType.warning,
      );
      return;
    }

    // Single point of truth: a zone keeps one persistent plan. If the selected
    // zone already has a live plan (active/paused/scheduled), steer the operator
    // to modify or shift the existing one instead of creating a duplicate.
    final selectedZoneId = _selectedZone?.id;
    if (selectedZoneId != null) {
      const liveStatuses = {'ACTIVE', 'PAUSED', 'SCHEDULED'};
      final hasLivePlan = state.allSchedules.any(
        (s) =>
            s.zoneId == selectedZoneId &&
            liveStatuses.contains(s.status.toUpperCase()),
      );
      if (hasLivePlan) {
        AppToast.show(
          context: context,
          message: context.l10n.zoneAlreadyHasActivePlan,
          type: AppToastType.warning,
        );
        return;
      }
    }

    context.read<DashboardBloc>().add(
      CreateScheduleSubmitted(
        regionId: _selectedRegion!.id,
        unitId: _selectedUnit?.id,
        neighborhoodId: _selectedNeighborhood?.id,
        zoneId: _selectedZone?.id,
        start: _startTime!,
        end: _endTime!,
        notes: _notesController.text.trim(),
      ),
    );
  }

  void _onRegionChanged(LocationLookupEntity? val) {
    setState(() {
      _selectedRegion = val;
      _selectedUnit = null;
      _selectedNeighborhood = null;
      _selectedZone = null;
    });
    if (val != null) {
      context.read<DashboardBloc>().add(FetchUnitsEvent(val.id));
    }
  }

  void _onUnitChanged(LocationLookupEntity? val) {
    setState(() {
      _selectedUnit = val;
      _selectedNeighborhood = null;
      _selectedZone = null;
    });
    if (val != null) {
      context.read<DashboardBloc>().add(FetchNeighborhoodsEvent(val.id));
    }
  }

  void _onNeighborhoodChanged(LocationLookupEntity? val) {
    setState(() {
      _selectedNeighborhood = val;
      _selectedZone = null;
    });
    if (val != null) {
      context.read<DashboardBloc>().add(FetchZonesEvent(val.id));
    }
  }

  void _onZoneChanged(LocationLookupEntity? val) {
    setState(() {
      _selectedZone = val;
    });
  }

  void _onStartTimeChanged(DateTime? val) {
    setState(() {
      _startTime = val;
    });
  }

  void _onEndTimeChanged(DateTime? val) {
    setState(() {
      _endTime = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocConsumer<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state.isSuccess) {
          AppToast.show(
            context: context,
            message: l10n.scheduleCreatedSuccessfully,
          );
          getIt<HomeBloc>().add(RefreshHomeDataEvent());
          Navigator.of(context).pop();
        }
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          AppToast.show(
            context: context,
            message: state.errorMessage!,
            type: AppToastType.error,
          );
        }
      },
      builder: (context, state) {
        final availableRegions = _isEmployeeScoped
            ? state.regions
                  .where((r) => _assignedRegionIds.contains(r.id))
                  .toList()
            : state.regions;
        final availableUnits = _isEmployeeScoped
            ? state.units.where((u) => _assignedUnitIds.contains(u.id)).toList()
            : state.units;

        _syncSingleChoiceSelections(
          state: state,
          availableRegions: availableRegions,
          availableUnits: availableUnits,
        );

        final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (media.size.height - media.viewInsets.bottom) * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    l10n.addNewSchedule,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                16.verticalSpace,
                Flexible(
                  child: SingleChildScrollView(
                    child: ScheduleFormFieldsWidget(
                      formKey: _formKey,
                      state: state,
                      availableRegions: availableRegions,
                      availableUnits: availableUnits,
                      selectedRegion: _selectedRegion,
                      selectedUnit: _selectedUnit,
                      selectedNeighborhood: _selectedNeighborhood,
                      selectedZone: _selectedZone,
                      startTime: _startTime,
                      endTime: _endTime,
                      notesController: _notesController,
                      onRegionChanged: _onRegionChanged,
                      onUnitChanged: _onUnitChanged,
                      onNeighborhoodChanged: _onNeighborhoodChanged,
                      onZoneChanged: _onZoneChanged,
                      onStartTimeChanged: _onStartTimeChanged,
                      onEndTimeChanged: _onEndTimeChanged,
                    ),
                  ),
                ),
                AddScheduleDialogActionsWidget(
                  isLoading: state.isLoading,
                  onSave: () => _onConfirm(context, state),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncSingleChoiceSelections({
    required DashboardState state,
    required List<LocationLookupEntity> availableRegions,
    required List<LocationLookupEntity> availableUnits,
  }) {
    if (_isPermissionLoading) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_selectedRegion == null && availableRegions.length == 1) {
        final region = availableRegions.first;
        setState(() => _selectedRegion = region);
        context.read<DashboardBloc>().add(FetchUnitsEvent(region.id));
        return;
      }

      if (_selectedRegion != null &&
          _selectedUnit == null &&
          availableUnits.length == 1) {
        final unit = availableUnits.first;
        setState(() => _selectedUnit = unit);
        context.read<DashboardBloc>().add(FetchNeighborhoodsEvent(unit.id));
        return;
      }

      if (_selectedUnit != null &&
          _selectedNeighborhood == null &&
          !state.isNeighborhoodsLoading &&
          state.neighborhoods.length == 1) {
        final neighborhood = state.neighborhoods.first;
        setState(() => _selectedNeighborhood = neighborhood);
        context.read<DashboardBloc>().add(FetchZonesEvent(neighborhood.id));
        return;
      }

      if (_selectedNeighborhood != null &&
          _selectedZone == null &&
          !state.isZonesLoading &&
          state.zones.length == 1) {
        setState(() => _selectedZone = state.zones.first);
      }
    });
  }
}
