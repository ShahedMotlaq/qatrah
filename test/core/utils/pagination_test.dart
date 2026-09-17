import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/utils/pagination.dart';

void main() {
  group('pageQuery', () {
    test('omits what was not asked for', () {
      expect(pageQuery(), isEmpty);
      expect(pageQuery(page: 0), {'page': 0});
      expect(pageQuery(size: 50, sort: const []), {'size': 50});
    });

    test('Dio repeats the sort key, which is what Spring binds', () {
      final query = RequestOptions(
        path: '/staff/pumping-runs',
        queryParameters: {
          'zoneId': 4,
          ...pageQuery(
            page: 1,
            size: 20,
            sort: const ['plannedStartAt,asc', 'id,desc'],
          ),
        },
      ).uri.query;

      expect(query, contains('zoneId=4'));
      expect(query, contains('page=1'));
      expect(query, contains('size=20'));
      expect(
        Uri.decodeQueryComponent(query).split('&'),
        containsAll(<String>['sort=plannedStartAt,asc', 'sort=id,desc']),
        reason: 'a single joined string would be read as one field name',
      );
    });
  });

  group('Pagination.fromJson', () {
    test('reads the documented top-level Page fields', () {
      final page = Pagination<int>.fromJson({
        'content': [
          {'v': 1},
          {'v': 2},
        ],
        'totalElements': 134,
        'totalPages': 7,
        'number': 3,
        'size': 20,
        'first': false,
        'last': false,
        'empty': false,
      }, (json) => json['v'] as int);

      expect(page.content, [1, 2]);
      expect(page.totalElements, 134);
      expect(page.totalPages, 7);
      expect(page.currentPage, 3);
      expect(page.pageSize, 20);
      expect(page.isFirst, isFalse);
      expect(page.isEmpty, isFalse);
    });

    test('falls back to the nested pageable object', () {
      final page = Pagination<int>.fromJson({
        'content': <dynamic>[],
        'pageable': {'pageNumber': 2, 'pageSize': 50},
      }, (json) => json['v'] as int);

      expect(page.currentPage, 2);
      expect(page.pageSize, 50);
      expect(page.content, isEmpty);
    });
  });
}
