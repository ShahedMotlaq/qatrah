// lib/features/home/presentation/widgets/expanded_area_selection_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/app_loading_widget.dart';
import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/home/domain/usecases/get_all_areas_use_case.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/features/home/presentation/widgets/area_dropdown_item_widget.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class ExpandedAreaSelectionWidget extends StatefulWidget {
  const ExpandedAreaSelectionWidget({super.key});

  @override
  State<ExpandedAreaSelectionWidget> createState() =>
      _ExpandedAreaSelectionWidgetState();
}

class _ExpandedAreaSelectionWidgetState
    extends State<ExpandedAreaSelectionWidget> {
  List<AreaEntity> _areas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    final getAllAreasUseCase = getIt<GetAllAreasUseCase>();
    final result = await getAllAreasUseCase();

    result.fold(
      (failure) {
        setState(() {
          _error = failure.errMessage;
          _isLoading = false;
        });
      },
      (areas) {
        setState(() {
          _areas = areas;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Center(child: AppLoadingWidget()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(child: Text(_error!)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .075),
              border: Border.all(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: .1,
                  ),
                  child: AppIconWidget(
                    icon: HugeIcons.strokeRoundedAlert01,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                8.horizontalSpace,
                Flexible(
                  child: Text(
                    l10n.selectRegionToWatchInfo,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          14.verticalSpace,
          BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (prev, curr) =>
                prev.monitoredAreas != curr.monitoredAreas,
            builder: (context, state) {
              return Column(
                children: _areas.map((area) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AreaDropdownItemWidget(
                      areaId: area.id,
                      cityName: area.name,
                      subTitle: area.regionName,
                      isSelected: state.monitoredAreas.any(
                        (e) => e.id == area.id,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
