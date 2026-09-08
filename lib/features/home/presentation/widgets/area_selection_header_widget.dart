import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/routing/routes.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/core/widgets/silent_refresh_animator.dart';
import 'package:qatrah/features/home/domain/entities/area_entity.dart';
import 'package:qatrah/features/home/presentation/bloc/home_bloc.dart';
import 'package:qatrah/features/home/presentation/bloc/home_event.dart';
import 'package:qatrah/features/home/presentation/bloc/home_state.dart';
import 'package:qatrah/l10n/gen/app_localizations.dart';

class AreaSelectionHeaderWidget extends StatelessWidget {
  const AreaSelectionHeaderWidget({
    super.key,
    this.isRefreshing = false,
  });

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SilentRefreshAnimator(
                    isRefreshing: isRefreshing,
                    child: AppIconWidget(
                      applyPadding: false,
                      icon: HugeIcons.strokeRoundedLocation04,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                8.horizontalSpace,
                Expanded(
                  child: BlocBuilder<HomeBloc, HomeState>(
                    buildWhen: (prev, curr) =>
                        prev.selectedMonitoredArea !=
                            curr.selectedMonitoredArea ||
                        prev.filteredLocationName !=
                            curr.filteredLocationName ||
                        prev.monitoredAreas != curr.monitoredAreas,
                    builder: (context, state) {
                      // Currently viewed location name:
                      // - If a monitored area is selected → show its name
                      // - Otherwise → show profile's default location
                      final currentViewName =
                          state.selectedMonitoredArea?.name ??
                          state.filteredLocationName ??
                          l10n.defaultLocation;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.chooseAreasToWatch,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 12.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            currentViewName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (state.monitoredAreas.isNotEmpty) ...[
                            4.verticalSpace,
                            _MonitoredAreaChips(
                              areas: state.monitoredAreas,
                              selectedArea: state.selectedMonitoredArea,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          InkWell(
            onTap: () => context.pushNamed(Routes.myAddresses),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.addWatch,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoredAreaChips extends StatelessWidget {
  const _MonitoredAreaChips({
    required this.areas,
    required this.selectedArea,
  });

  final List<AreaEntity> areas;
  final AreaEntity? selectedArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: areas.map((area) {
          final isSelected = selectedArea?.id == area.id;
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: GestureDetector(
              onTap: () {
                if (isSelected) {
                  context.read<HomeBloc>().add(
                    ClearMonitoredAreaSelectionEvent(),
                  );
                } else {
                  context.read<HomeBloc>().add(SelectDisplayAreaEvent(area.id));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(
                      alpha: isSelected ? 1 : 0.3,
                    ),
                  ),
                ),
                child: Text(
                  area.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
