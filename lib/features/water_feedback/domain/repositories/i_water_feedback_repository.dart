import 'package:qatrah/features/water_feedback/domain/entities/active_schedule_status_entity.dart';
import 'package:qatrah/features/water_feedback/domain/entities/water_feedback_entity.dart';

abstract class IWaterFeedbackRepository {
  Future<ActiveScheduleStatusEntity> getActiveScheduleStatus();

  Future<void> submitFeedback(String feedbackType, {int? scheduleId});

  Future<List<WaterFeedbackEntity>> getMyFeedbackHistory();

  Future<WaterFeedbackEntity?> getUserFeedbackForSchedule(int scheduleId);
}
