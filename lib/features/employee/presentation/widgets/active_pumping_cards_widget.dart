import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:qatrah/core/extensions/context_l10n.dart';
import 'package:qatrah/core/theme/app_colors.dart';
import 'package:qatrah/core/widgets/app_icon_widget.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_state.dart';
import 'package:qatrah/features/employee/presentation/widgets/schedule_confirmation_dialogs.dart';

class ActiveAndNextPumpingCardsWidget extends StatelessWidget {
  const ActiveAndNextPumpingCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // البحث عن أول جدول نشط (ACTIVE) للبطاقة الخضراء
        final activeSchedule = state.allSchedules
            .where((s) => s.status.toUpperCase() == 'ACTIVE')
            .safeFirst;

        // البحث عن أول جدول مجدول (SCHEDULED) للبطاقة البرتقالية
        final nextSchedule = state.allSchedules
            .where((s) => s.status.toUpperCase() == 'SCHEDULED')
            .safeFirst;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Column(
            children: [
              // 1. البطاقة الخضراء (الضخ جاري الآن)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary, // أخضر الهوية الأساسي
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.h,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              6.horizontalSpace,
                              Text(
                                l10n.activePumping,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    Text(
                      activeSchedule != null
                          ? '${activeSchedule.regionName} - ${activeSchedule.unitName ?? ''}'
                          : 'لا يوجد محطة قيد الضخ حالياً',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (activeSchedule != null) ...[
                      4.verticalSpace,
                      Text(
                        'تبدأ من: ${activeSchedule.startTime.hour}:${activeSchedule.startTime.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    16.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: activeSchedule != null
                                ? () =>
                                      ScheduleConfirmationDialogs.showEndConfirmation(
                                        context,
                                        scheduleId: activeSchedule.id,
                                      )
                                : null,
                            style: ElevatedButton.styleFrom(
                              // زر الإيقاف: أبيض بنص أخضر الهوية بدل الأحمر
                              backgroundColor: Colors.white,
                              foregroundColor: theme.colorScheme.primary,
                              disabledBackgroundColor: Colors.white70,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: const Text('إيقاف'),
                          ),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                activeSchedule != null &&
                                    activeSchedule.status.toUpperCase() ==
                                        'PAUSED'
                                ? () =>
                                      ScheduleConfirmationDialogs.showResumeConfirmation(
                                        context,
                                        scheduleId: activeSchedule.id,
                                      )
                                : activeSchedule != null
                                ? () =>
                                      ScheduleConfirmationDialogs.showPauseConfirmation(
                                        context,
                                        scheduleId: activeSchedule.id,
                                      )
                                : null,
                            style: ElevatedButton.styleFrom(
                              // الإيقاف المؤقت ثانوي: مفرّغ بحدود بيضاء
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white54,
                              elevation: 0,
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              activeSchedule?.status.toUpperCase() == 'PAUSED'
                                  ? 'استئناف'
                                  : 'إيقاف مؤقت',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              12.verticalSpace,

              // 2. البطاقة الحمراء (الحالة التالية)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.deepUmber, // الأحمر الرسمي للتطبيق
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الحالة التالية',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          4.verticalSpace,
                          Text(
                            nextSchedule != null
                                ? '${nextSchedule.regionName} - ${nextSchedule.unitName ?? ''}'
                                : 'لا توجد جداول مجدولة قادمة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppIconWidget(
                      icon: HugeIcons.strokeRoundedClock01,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// امتداد مساعد لاختيار أول عنصر بأمان
extension SafeFirst<E> on Iterable<E> {
  E? get safeFirst => isEmpty ? null : first;
}
