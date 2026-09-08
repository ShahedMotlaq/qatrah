// lib/features/water_feedback/presentation/bloc/water_feedback_state.dart

import 'package:equatable/equatable.dart';
import 'package:qatrah/features/water_feedback/domain/entities/active_schedule_status_entity.dart';
import 'package:qatrah/features/water_feedback/domain/entities/water_feedback_entity.dart';

sealed class WaterFeedbackState extends Equatable {
  const WaterFeedbackState();

  @override
  List<Object?> get props => [];
}

final class WaterFeedbackInitial extends WaterFeedbackState {}

final class WaterFeedbackLoading extends WaterFeedbackState {}

final class WaterFeedbackStatusLoaded extends WaterFeedbackState {
  const WaterFeedbackStatusLoaded(this.status);
  final ActiveScheduleStatusEntity status;

  @override
  List<Object?> get props => [status];
}

final class WaterFeedbackHistoryLoaded extends WaterFeedbackState {
  const WaterFeedbackHistoryLoaded(this.history);
  final List<WaterFeedbackEntity> history;

  @override
  List<Object?> get props => [history];
}

final class WaterFeedbackUserFeedbackLoaded extends WaterFeedbackState {
  const WaterFeedbackUserFeedbackLoaded(this.feedback);
  final WaterFeedbackEntity? feedback;

  @override
  List<Object?> get props => [feedback];
}

final class WaterFeedbackSubmittedSuccess extends WaterFeedbackState {}

final class WaterFeedbackError extends WaterFeedbackState {
  const WaterFeedbackError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
