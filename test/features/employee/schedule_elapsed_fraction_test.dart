import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/presentation/widgets/dashboard_table_list_widget.dart';

ScheduleEntity _schedule({required DateTime start, required DateTime end}) {
  return ScheduleEntity(
    id: 1,
    regionId: 1,
    regionName: 'Region',
    fullLocationPath: 'Region',
    startTime: start,
    endTime: end,
    status: 'ACTIVE',
  );
}

void main() {
  final start = DateTime(2026, 1, 1, 8);
  final end = DateTime(2026, 1, 1, 12);
  final schedule = _schedule(start: start, end: end);

  test('halfway through an active window reads 0.5', () {
    expect(
      scheduleElapsedFraction(schedule, 'ACTIVE', DateTime(2026, 1, 1, 10)),
      0.5,
    );
  });

  test('clamps outside the window', () {
    expect(scheduleElapsedFraction(schedule, 'ACTIVE', start), 0.0);
    expect(
      scheduleElapsedFraction(
        schedule,
        'ACTIVE',
        end.add(const Duration(hours: 3)),
      ),
      1.0,
    );
  });

  test('status overrides the clock', () {
    final mid = DateTime(2026, 1, 1, 10);
    expect(scheduleElapsedFraction(schedule, 'SCHEDULED', mid), 0.0);
    expect(scheduleElapsedFraction(schedule, 'completed', mid), 1.0);
    expect(scheduleElapsedFraction(schedule, 'CANCELLED', mid), 1.0);
  });

  test('zero-length window is full, not a divide by zero', () {
    expect(
      scheduleElapsedFraction(
        _schedule(start: start, end: start),
        'ACTIVE',
        start,
      ),
      1.0,
    );
  });
}
