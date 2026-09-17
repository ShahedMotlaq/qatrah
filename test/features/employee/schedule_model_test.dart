import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/features/employee/data/models/schedule_model.dart';

void main() {
  test('reads a PumpingRunDto', () {
    final run = ScheduleModelMapper.fromJson({
      'id': 42,
      'scheduleId': 6,
      'zoneId': 4,
      'zoneName': 'الحي الغربي',
      'regionId': 1,
      'plannedStartAt': '2026-09-14T08:00:00+03:00',
      'plannedEndAt': '2026-09-14T11:00:00+03:00',
      'actualStartAt': '2026-09-14T08:05:12+03:00',
      'actualEndAt': null,
      'status': 'ACTIVE',
    });

    expect(run.id, 42);
    expect(run.zoneId, 4);
    expect(run.status, 'ACTIVE');
    expect(run.startTime.toUtc().hour, 5); // 08:00+03:00
    expect(run.endTime.toUtc().hour, 8);
    expect(run.actualEndTime, isNull);
  });

  test('a finished run carries actualEndAt', () {
    final run = ScheduleModelMapper.fromJson({
      'id': 43,
      'plannedStartAt': '2026-09-14T08:00:00+03:00',
      'plannedEndAt': '2026-09-14T11:00:00+03:00',
      'actualEndAt': '2026-09-14T10:42:00+03:00',
      'status': 'COMPLETED',
    });

    expect(run.actualEndTime?.toUtc().hour, 7);
  });

  test('legacy schedule field names still parse', () {
    final run = ScheduleModelMapper.fromJson({
      'id': 7,
      'startTime': '2026-09-14T08:00:00+03:00',
      'endTime': '2026-09-14T11:00:00+03:00',
      'actualEndTime': '2026-09-14T10:00:00+03:00',
      'status': 'COMPLETED',
    });

    expect(run.startTime.toUtc().hour, 5);
    expect(run.actualEndTime, isNotNull);
  });

  test('a row with no planned window is rejected, not silently zeroed', () {
    expect(
      () => ScheduleModelMapper.fromJson({'id': 1, 'status': 'SCHEDULED'}),
      throwsFormatException,
    );
  });
}
