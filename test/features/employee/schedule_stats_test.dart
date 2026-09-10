import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_stats.dart';

final _now = DateTime(2026, 3, 10, 12);

ScheduleEntity _schedule(
  String status, {
  required DateTime start,
  required DateTime end,
  DateTime? actualEnd,
}) {
  return ScheduleEntity(
    id: 1,
    regionId: 1,
    regionName: 'Region',
    fullLocationPath: 'Region',
    startTime: start,
    endTime: end,
    actualEndTime: actualEnd,
    status: status,
  );
}

DateTime _h(int hoursFromNow) => _now.add(Duration(hours: hoursFromNow));

void main() {
  test('counts each status inside its window', () {
    final stats = ScheduleStats.fromSchedules([
      _schedule('ACTIVE', start: _h(-2), end: _h(2)),
      _schedule('PAUSED', start: _h(-1), end: _h(3)),
      _schedule('SCHEDULED', start: _h(5), end: _h(8)),
      _schedule('SCHEDULED', start: _h(30), end: _h(33)), // beyond 24h
      _schedule('COMPLETED', start: _h(-6), end: _h(-3)),
      _schedule('COMPLETED', start: _h(-50), end: _h(-47)), // too old
      _schedule('CANCELLED', start: _h(-4), end: _h(-1)),
      _schedule('cancelled', start: _h(-30), end: _h(-27)), // too old
    ], _now);

    expect(stats.active, 1);
    expect(stats.paused, 1);
    expect(stats.upcoming, 1);
    expect(stats.completed, 1);
    expect(stats.cancelled, 1);
  });

  test('pumping time is clipped to the last 24 hours', () {
    final stats = ScheduleStats.fromSchedules([
      // Active for 2h so far.
      _schedule('ACTIVE', start: _h(-2), end: _h(2)),
      // Started 26h ago, finished 22h ago: only 2h fall inside the window.
      _schedule('COMPLETED', start: _h(-26), end: _h(-22)),
      // Planned 3h but ended early after 1h: actualEndTime wins.
      _schedule('COMPLETED', start: _h(-5), end: _h(-2), actualEnd: _h(-4)),
    ], _now);

    expect(stats.pumpingTime, const Duration(hours: 5));
    expect(stats.completed, 2);
  });

  test('empty input is all zeros', () {
    expect(ScheduleStats.fromSchedules(const [], _now), const ScheduleStats());
  });
}
