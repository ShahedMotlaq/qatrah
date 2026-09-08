// lib/features/water_feedback/domain/entities/water_feedback_entity.dart

class WaterFeedbackEntity {
  const WaterFeedbackEntity({
    required this.id,
    required this.feedbackType,
    required this.schedulePath,
    required this.createdAt,
    this.adminResponse,
  });

  final int id;
  final String feedbackType;
  final String schedulePath;
  final DateTime createdAt;
  final String? adminResponse;
}
