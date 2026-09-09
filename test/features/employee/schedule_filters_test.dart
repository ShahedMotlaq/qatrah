import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/features/employee/domain/entities/schedule_entity.dart';
import 'package:qatrah/features/employee/presentation/bloc/employee_bloc.dart';

ScheduleEntity _schedule({
  DateTime? start,
  String? notes,
  String? neighborhoodName,
}) {
  final startTime = start ?? DateTime(2026, 3, 10, 8);
  return ScheduleEntity(
    id: 1,
    regionId: 1,
    regionName: 'Amman',
    fullLocationPath: 'Amman > Unit 3',
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 4)),
    status: 'SCHEDULED',
    notes: notes,
    neighborhoodName: neighborhoodName,
  );
}

void main() {
  group('scheduleMatchesQuery', () {
    test('matches notes case-insensitively', () {
      final schedule = _schedule(notes: 'Valve MAINTENANCE required');
      expect(scheduleMatchesQuery(schedule, 'maintenance'), isTrue);
      expect(scheduleMatchesQuery(schedule, 'pump'), isFalse);
    });

    test('matches location names and the full path', () {
      final schedule = _schedule(neighborhoodName: 'الرابية');
      expect(scheduleMatchesQuery(schedule, 'الرابية'), isTrue);
      expect(scheduleMatchesQuery(schedule, 'unit 3'), isTrue);
    });

    test('an empty or whitespace query matches everything', () {
      expect(scheduleMatchesQuery(_schedule(), '   '), isTrue);
    });

    test('ignores surrounding whitespace in the query', () {
      expect(scheduleMatchesQuery(_schedule(notes: 'leak'), '  leak '), isTrue);
    });
  });

  group('scheduleInDateRange', () {
    final schedule = _schedule(start: DateTime(2026, 3, 10, 8));

    test('keeps a schedule that starts on the "to" day', () {
      expect(
        scheduleInDateRange(schedule, null, DateTime(2026, 3, 10)),
        isTrue,
      );
    });

    test('keeps a schedule that starts on the "from" day', () {
      expect(
        scheduleInDateRange(schedule, DateTime(2026, 3, 10), null),
        isTrue,
      );
    });

    test('excludes schedules outside the range', () {
      expect(
        scheduleInDateRange(schedule, DateTime(2026, 3, 11), null),
        isFalse,
      );
      expect(
        scheduleInDateRange(schedule, null, DateTime(2026, 3, 9)),
        isFalse,
      );
    });

    test('no bounds keeps everything', () {
      expect(scheduleInDateRange(schedule, null, null), isTrue);
    });
  });
}
