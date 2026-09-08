import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_empty_state_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/data_column_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_date_cell_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_status_badge_widget.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_table_action_cell_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardTableListWidget extends StatelessWidget {
  const DashboardTableListWidget({super.key});

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return Colors.blue;
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return theme.colorScheme.error;
      default:
        return Colors.black;
    }
  }

  String _getStatusTranslation(String status, BuildContext context) {
    final l10n = context.l10n;
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return l10n.scheduled;
      case 'ACTIVE':
        return l10n.active;
      case 'COMPLETED':
        return l10n.finished;
      case 'CANCELLED':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (p, c) =>
          p.filteredSchedules != c.filteredSchedules ||
          p.isLoading != c.isLoading,
      builder: (context, state) {
        if (state.filteredSchedules.isEmpty) {
          return SliverToBoxAdapter(
            child: Skeletonizer(
              enabled: state.isLoading,
              child: AppEmptyState(
                message: l10n.noSchedulesFound,
                icon: HugeIcons.strokeRoundedCalendar01,
              ),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Skeletonizer(
            enabled: state.isLoading,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: state.filteredSchedules.isNotEmpty
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 32.w,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      theme.colorScheme.primary,
                    ),
                    dividerThickness: 1,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      verticalInside: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    columnSpacing: 15.w,
                    columns: [
                      buildDataColumn(context, label: l10n.region),
                      buildDataColumn(context, label: l10n.unit),
                      buildDataColumn(context, label: l10n.neighborhood),
                      buildDataColumn(context, label: l10n.zoneLabel),
                      buildDataColumn(context, label: l10n.startPumpingLabel),
                      buildDataColumn(context, label: l10n.endPumpingLabel),
                      buildDataColumn(context, label: l10n.notes),
                      buildDataColumn(context, label: l10n.status),
                      buildDataColumn(context, label: l10n.actions),
                    ],
                    rows: state.filteredSchedules.map((schedule) {
                      final status = schedule.status.toUpperCase();
                      final statusColor = _getStatusColor(status, theme);
                      final statusLabel = _getStatusTranslation(
                        status,
                        context,
                      );
                      final notesText = status == 'CANCELLED'
                          ? ((schedule.cancellationReason?.isNotEmpty ?? false)
                                ? schedule.cancellationReason!
                                : ((schedule.notes?.isNotEmpty ?? false)
                                      ? schedule.notes!
                                      : '-'))
                          : ((schedule.notes?.isNotEmpty ?? false)
                                ? schedule.notes!
                                : '-');

                      return DataRow(
                        cells: [
                          DataCell(Center(child: Text(schedule.regionName))),
                          DataCell(
                            Center(child: Text(schedule.unitName ?? '-')),
                          ),
                          DataCell(
                            Center(
                              child: Text(schedule.neighborhoodName ?? '-'),
                            ),
                          ),
                          DataCell(
                            Center(child: Text(schedule.zoneName ?? '-')),
                          ),
                          DataCell(
                            Center(
                              child: ScheduleDateCellWidget(
                                dateTime: schedule.startTime,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: ScheduleDateCellWidget(
                                dateTime:
                                    schedule.actualEndTime ?? schedule.endTime,
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: SizedBox(
                                width: 100.w,
                                child: Text(
                                  notesText,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: ScheduleStatusBadgeWidget(
                                statusColor: statusColor,
                                label: statusLabel,
                              ),
                            ),
                          ),
                          DataCell(
                            ScheduleTableActionCellWidget(
                              status: status,
                              scheduleId: schedule.id,
                              schedule: schedule,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
