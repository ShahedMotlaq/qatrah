// lib/features/water_feedback/presentation/bloc/water_feedback_cubit.dart

import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/service_locator/service_locator.dart';
import 'package:qatrah/core/services/connectivity_service.dart';
import 'package:qatrah/core/utils/user_helper.dart';
import 'package:qatrah/features/complaints/domain/entities/complaints_entity.dart';
import 'package:qatrah/features/complaints/domain/repositories/i_complaints_repository.dart';
import 'package:qatrah/features/water_feedback/domain/entities/active_schedule_status_entity.dart';
import 'package:qatrah/features/water_feedback/domain/repositories/i_water_feedback_repository.dart';
import 'package:qatrah/features/water_feedback/presentation/bloc/water_feedback_state.dart';

class WaterFeedbackCubit extends Cubit<WaterFeedbackState> {
  WaterFeedbackCubit(
    this._repository,
    this._complaintsRepository,
    this._connectivity,
  ) : super(WaterFeedbackInitial());

  final IWaterFeedbackRepository _repository;
  final IComplaintsRepository _complaintsRepository;
  final ConnectivityService _connectivity;

  List<ComplaintEntity> _operatorNeighborhoodComplaints = [];
  List<ComplaintEntity> get operatorNeighborhoodComplaints =>
      _operatorNeighborhoodComplaints;

  // Track locally submitted ratings to prevent duplicates
  // Key: scheduleId, Value: feedbackType
  final Map<int, String> _submittedRatings = {};

  /// Check if a schedule has already been locally rated
  bool hasLocalRating(int? scheduleId) {
    if (scheduleId == null) return false;
    return _submittedRatings.containsKey(scheduleId);
  }

  /// Get the local rating for a schedule
  String? getLocalRating(int? scheduleId) {
    if (scheduleId == null) return null;
    return _submittedRatings[scheduleId];
  }

  /// Record a local rating submission
  void _recordLocalRating(int? scheduleId, String feedbackType) {
    if (scheduleId != null) {
      _submittedRatings[scheduleId] = feedbackType;
    }
  }

  /// Clear local rating for a schedule (when refetching status)
  void _clearLocalRating(int? scheduleId) {
    if (scheduleId != null) {
      _submittedRatings.remove(scheduleId);
    }
  }

  Future<void> checkActiveSchedule() async {
    emit(WaterFeedbackLoading());

    try {
      final status = await _repository.getActiveScheduleStatus();

      // Apply operator scope filtering
      // If user is an operator, verify that the active schedule's unit
      // is in their assigned units list
      if (status.hasActiveSchedule && status.unitId != null) {
        final hasAccess = await UserHelper.canPerformOperatorAction(
          status.unitId!,
        );

        if (!hasAccess) {
          // Operator doesn't have access to this unit - treat as no active schedule
          dev.log(
            '⚠️ [Operator Scope] Operator denied access to unit ${status.unitId}',
            name: 'WaterFeedback',
          );
          // Emit status as if no active schedule exists for this operator
          emit(
            WaterFeedbackStatusLoaded(
              status.copyWith(hasActiveSchedule: false),
            ),
          );
          return;
        }

        dev.log(
          '✅ [Operator Scope] Operator has access to unit ${status.unitId}',
          name: 'WaterFeedback',
        );

        // If operator has access and there's a neighborhoodId, fetch complaints
        if (status.neighborhoodId != null) {
          await _fetchNeighborhoodComplaints(status.neighborhoodId!);
        }
      }

      // Citizen guard: only show rating card for profile area
      final isCitizen = await UserHelper.isCitizen();
      if (isCitizen &&
          status.hasActiveSchedule &&
          status.neighborhoodId != null) {
        final profileNeighborhoodId = await getIt<SecureStorage>()
            .getSelectedHomeNeighborhoodId();
        if (profileNeighborhoodId != null &&
            status.neighborhoodId != profileNeighborhoodId) {
          dev.log(
            '⚠️ [Citizen Guard] Active schedule neighborhood ${status.neighborhoodId} '
            '!= profile neighborhood $profileNeighborhoodId — hiding rating card',
            name: 'WaterFeedback',
          );
          emit(
            WaterFeedbackStatusLoaded(
              status.copyWith(hasActiveSchedule: false),
            ),
          );
          return;
        }
      }

      emit(WaterFeedbackStatusLoaded(status));
    } catch (e) {
      emit(WaterFeedbackError(e.toString()));
    }
  }

  /// Fetch complaints for the neighborhood being pumped
  Future<void> _fetchNeighborhoodComplaints(int neighborhoodId) async {
    try {
      dev.log(
        '📝 [Complaints] Fetching complaints for neighborhood $neighborhoodId',
        name: 'WaterFeedback',
      );

      final result = await _complaintsRepository.getComplaintsByNeighborhood(
        neighborhoodId,
        status: 'PENDING',
      );

      await result.fold(
        (failure) {
          dev.log(
            '❌ [Complaints] Failed to fetch: ${failure.errMessage}',
            name: 'WaterFeedback',
          );
          _operatorNeighborhoodComplaints = [];
        },
        (paginated) {
          _operatorNeighborhoodComplaints = paginated.items;
          dev.log(
            '✅ [Complaints] Loaded ${paginated.items.length} pending complaints',
            name: 'WaterFeedback',
          );
        },
      );
    } catch (e) {
      dev.log(
        '❌ [Complaints] Error fetching neighborhood complaints: $e',
        name: 'WaterFeedback',
      );
      _operatorNeighborhoodComplaints = [];
    }
  }

  /// Validates whether the user can submit feedback for a given schedule.
  /// Schedule status must be ACTIVE or COMPLETED.
  /// If COMPLETED, current time must be within actualEndTime + feedbackWindowHours.
  /// Feedback cannot be submitted if already submitted or if schedule is CANCELLED.
  bool canSubmitFeedback(ActiveScheduleStatusEntity schedule) {
    // Prevent feedback for cancelled or paused schedules
    if (schedule.scheduleStatus == 'CANCELLED') return false;
    if (schedule.scheduleStatus == 'PAUSED') return false;

    // Prevent duplicate feedback
    if (schedule.alreadySubmittedFeedback) return false;

    // Allow ACTIVE schedules
    if (schedule.scheduleStatus == 'ACTIVE') return true;

    // For COMPLETED schedules, check feedback window
    if (schedule.scheduleStatus == 'COMPLETED') {
      return schedule.isWithinFeedbackWindow;
    }

    return false;
  }

  Future<void> submitFeedback(String feedbackType, {int? scheduleId}) async {
    emit(WaterFeedbackLoading());

    try {
      // Record the local rating before sending
      _recordLocalRating(scheduleId, feedbackType);

      await _repository.submitFeedback(feedbackType, scheduleId: scheduleId);
      emit(WaterFeedbackSubmittedSuccess());
      await checkActiveSchedule();
    } catch (e) {
      emit(WaterFeedbackError(e.toString()));
    }
  }

  Future<void> getUserFeedbackForSchedule(int scheduleId) async {
    emit(WaterFeedbackLoading());

    try {
      final feedback = await _repository.getUserFeedbackForSchedule(scheduleId);
      emit(WaterFeedbackUserFeedbackLoaded(feedback));
    } catch (e) {
      emit(WaterFeedbackError(e.toString()));
    }
  }

  Future<void> getHistory() async {
    emit(WaterFeedbackLoading());

    final hasInternet = await _connectivity.hasInternetConnection();
    if (!hasInternet) {
      emit(const WaterFeedbackError('no_internet'));
      return;
    }

    try {
      final history = await _repository.getMyFeedbackHistory();
      emit(WaterFeedbackHistoryLoaded(history));
    } catch (e) {
      emit(WaterFeedbackError(e.toString()));
    }
  }
}
