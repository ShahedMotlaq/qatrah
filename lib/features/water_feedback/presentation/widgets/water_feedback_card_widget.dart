// lib/features/water_feedback/presentation/widgets/water_feedback_card_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/water_feedback/domain/entities/active_schedule_status_entity.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_bloc.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_state.dart';
import 'package:qatrah/features/water_feedback/presentation/widgets/operator_complaints_section.dart';
import 'package:qatrah/features/water_feedback/presentation/widgets/water_feedback_dialog.dart';

class WaterFeedbackCardWidget extends StatelessWidget {
  const WaterFeedbackCardWidget({this.includeCompleted = true, super.key});

  /// When false, the card is surfaced only for an actively-pumping schedule.
  /// A completed (past) schedule still awaiting a rating is suppressed — used
  /// on the home screen, where past-pumping ratings now live in the "unrated"
  /// tab of the My Evaluations page instead.
  final bool includeCompleted;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterFeedbackCubit, WaterFeedbackState>(
      builder: (context, state) {
        if (state is WaterFeedbackStatusLoaded) {
          final status = state.status;
          final cubit = context.read<WaterFeedbackCubit>();
          // Show card if the user can submit feedback for this schedule
          if (status.hasActiveSchedule && cubit.canSubmitFeedback(status)) {
            // Home only shows the active (green) prompt; a completed/past
            // schedule awaiting rating belongs to the "unrated" tab instead.
            if (!includeCompleted && status.scheduleStatus == 'COMPLETED') {
              return const SizedBox.shrink();
            }
            return _buildCard(context, status);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCard(BuildContext context, ActiveScheduleStatusEntity status) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final complaints = context
        .read<WaterFeedbackCubit>()
        .operatorNeighborhoodComplaints;
    final isCompleted = status.scheduleStatus == 'COMPLETED';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main pumping status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) => WaterFeedbackDialog(
                    onSelected: (type) =>
                        context.read<WaterFeedbackCubit>().submitFeedback(
                          type,
                          scheduleId: status.scheduleId,
                        ),
                  ),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary.withValues(
                      alpha: .1,
                    ),
                    child: AppIconWidget(
                      icon: HugeIcons.strokeRoundedDroplet,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  8.horizontalSpace,
                  Flexible(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      trailing: Visibility(
                        visible:
                            status.timeRemaining.isNotEmpty && !isCompleted,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                              4.horizontalSpace,
                              Text(
                                status.timeRemaining,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      title: Text(
                        isCompleted
                            ? l10n.pumpingEndedLabel
                            : l10n.pumpingStatusActiveNow,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      subtitle: Text(
                        l10n.pressToRate,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Operator complaints section (only for operators)
        if (complaints.isNotEmpty)
          OperatorComplaintsSection(complaints: complaints),
      ],
    );
  }
}
