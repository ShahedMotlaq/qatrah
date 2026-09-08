// lib/features/water_feedback/data/models/water_feedback_model.dart
//
// Serialization layer for [WaterFeedbackEntity]. The domain entity stays pure
// Dart; JSON mapping lives here as an extension.

import 'package:qatrah/features/water_feedback/domain/entities/water_feedback_entity.dart';

extension WaterFeedbackMapper on WaterFeedbackEntity {
  static WaterFeedbackEntity fromJson(Map<String, dynamic> json) =>
      WaterFeedbackEntity(
        id: json['id'] as int,
        feedbackType: json['feedbackType'] as String,
        schedulePath: json['schedulePath'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        adminResponse: json['adminResponse'] as String?,
      );
}
