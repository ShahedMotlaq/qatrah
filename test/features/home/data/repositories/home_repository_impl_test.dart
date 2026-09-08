import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qatrah/core/network/api_endpoints.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/home/data/repositories/home_repository_impl.dart';
import 'package:qatrah/features/home/domain/entities/pumping_status_entity.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  test('default home status includes next scheduled schedule', () async {
    final api = _MockApiService();
    final repository = HomeRepositoryImpl(api);
    final start = DateTime.now().add(const Duration(hours: 1));
    final end = start.add(const Duration(hours: 2));

    when(
      () => api.get(
        endPoint: ApiEndpoints.schedulesHomeStatus,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': {
          'activeSchedule': null,
          'pausedSchedule': null,
          'recentCancelled': null,
          'lastCompleted': null,
          'nextScheduled': {
            'id': 7,
            'areaName': 'Area',
            'areaPath': 'Region / Area',
            'startTime': start.toIso8601String(),
            'endTime': end.toIso8601String(),
            'status': 'SCHEDULED',
          },
        },
      },
    );

    final result = await repository.getPumpingStatus();

    expect(result.isRight(), isTrue);
    final statuses = result.getOrElse(() => []);
    expect(statuses, hasLength(1));
    expect(statuses.single.status, PumpingStatus.scheduled);
    expect(statuses.single.scheduleId, 7);
  });
  test(
    'default home status treats paused schedule without status as paused',
    () async {
      final api = _MockApiService();
      final repository = HomeRepositoryImpl(api);
      final start = DateTime.now().subtract(const Duration(minutes: 10));
      final end = start.add(const Duration(hours: 2));

      when(
        () => api.get(
          endPoint: ApiEndpoints.schedulesHomeStatus,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'data': {
            'activeSchedule': null,
            'pausedSchedule': {
              'id': 8,
              'areaName': 'Area',
              'areaPath': 'Region / Area',
              'startTime': start.toIso8601String(),
              'endTime': end.toIso8601String(),
              'pauseReason': 'Temporary failure',
              'temporaryFailure': true,
            },
            'recentCancelled': null,
            'lastCompleted': null,
            'nextScheduled': null,
          },
        },
      );

      final result = await repository.getPumpingStatus();

      expect(result.isRight(), isTrue);
      final statuses = result.getOrElse(() => []);
      expect(statuses, hasLength(1));
      expect(statuses.single.status, PumpingStatus.paused);
      expect(statuses.single.temporaryFailure, isTrue);
    },
  );

  test('default home status treats temporary failure as paused', () async {
    final api = _MockApiService();
    final repository = HomeRepositoryImpl(api);
    final start = DateTime.now().subtract(const Duration(minutes: 10));
    final end = start.add(const Duration(hours: 2));

    when(
      () => api.get(
        endPoint: ApiEndpoints.schedulesHomeStatus,
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => {
        'data': {
          'activeSchedule': null,
          'pausedSchedule': {
            'id': 9,
            'areaName': 'Area',
            'areaPath': 'Region / Area',
            'startTime': start.toIso8601String(),
            'endTime': end.toIso8601String(),
            'status': 'ACTIVE',
            'temporaryFailure': true,
          },
          'recentCancelled': null,
          'lastCompleted': null,
          'nextScheduled': null,
        },
      },
    );

    final result = await repository.getPumpingStatus();

    expect(result.isRight(), isTrue);
    final statuses = result.getOrElse(() => []);
    expect(statuses, hasLength(1));
    expect(statuses.single.status, PumpingStatus.paused);
    expect(statuses.single.scheduleId, 9);
  });
}
