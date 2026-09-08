// lib/features/water_feedback/data/repositories/water_feedback_repository_impl.dart

import 'dart:developer' as dev;

import 'package:qatrah/core/errors/failures.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/water_feedback/data/models/active_schedule_status_model.dart';
import 'package:qatrah/features/water_feedback/data/models/water_feedback_model.dart';
import 'package:qatrah/features/water_feedback/domain/entities/active_schedule_status_entity.dart';
import 'package:qatrah/features/water_feedback/domain/entities/water_feedback_entity.dart';
import 'package:qatrah/features/water_feedback/domain/repositories/i_water_feedback_repository.dart';

class WaterFeedbackRepositoryImpl implements IWaterFeedbackRepository {
  WaterFeedbackRepositoryImpl(this._apiService);
  final ApiService _apiService;

  @override
  Future<ActiveScheduleStatusEntity> getActiveScheduleStatus() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.waterFeedbackActiveScheduleStatus,
      );
      return ActiveScheduleStatusMapper.fromJson(_extractMap(response));
    } catch (e) {
      throw ServerFailure('Failed to check pumping status');
    }
  }

  @override
  Future<void> submitFeedback(String feedbackType, {int? scheduleId}) async {
    try {
      final data = <String, dynamic>{'feedbackType': feedbackType};
      if (scheduleId != null) {
        data['scheduleId'] = scheduleId;
      }
      await _apiService.post(
        endPoint: ApiEndpoints.waterFeedback,
        data: data,
      );
    } catch (e) {
      throw ServerFailure('Failed to submit feedback, please try again later');
    }
  }

  @override
  Future<WaterFeedbackEntity?> getUserFeedbackForSchedule(
    int scheduleId,
  ) async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.waterFeedbackUserFeedback(scheduleId),
      );
      if (response.isEmpty) return null;
      return WaterFeedbackMapper.fromJson(_extractMap(response));
    } catch (e) {
      throw ServerFailure('Failed to fetch user feedback for schedule');
    }
  }

  @override
  Future<List<WaterFeedbackEntity>> getMyFeedbackHistory() async {
    try {
      final response = await _apiService.get(
        endPoint: ApiEndpoints.waterFeedbackMyFeedback,
      );

      // Fix: correct handling
      List<dynamic> listData;

      if (response is List) {
        // API returns List directly
        listData = response as List<dynamic>;
      } else // API returns Map, need to extract list from appropriate key
      if (response.containsKey('data') && response['data'] is List) {
        listData = response['data'] as List<dynamic>;
      } else if (response.containsKey('content') &&
          response['content'] is List) {
        listData = response['content'] as List<dynamic>;
      } else {
        listData = [];
      }

      final models = listData
          .map((e) => WaterFeedbackMapper.fromJson(e as Map<String, dynamic>))
          .toList();

      // Debug: log adminResponse presence to diagnose missing admin replies
      for (final m in models) {
        if (m.adminResponse == null || m.adminResponse!.isEmpty) {
          final raw = (listData.isNotEmpty)
              ? (listData.first as Map<String, dynamic>).keys.join(', ')
              : 'empty';
          dev.log(
            '🔍 [MyFeedback] id=${m.id} has NO adminResponse. '
            'Available JSON keys: [$raw]',
            name: 'WaterFeedback',
          );
          break; // log once per batch
        }
      }

      return models;
    } catch (e) {
      throw ServerFailure('Error fetching feedback history: $e');
    }
  }

  Map<String, dynamic> _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      return response;
    }
    return const <String, dynamic>{};
  }
}
