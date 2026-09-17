import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/home/data/repositories/home_repository_impl.dart';
import 'package:qatrah/features/profile/data/repositories/hierarchy_repository_impl.dart';

/// `GET /hierarchy/tree`: one region → one unit → one neighborhood → two
/// zones. Each node names its ancestors, as the API does.
const List<Map<String, dynamic>> _tree = [
  {
    'id': 1,
    'name': 'درعا البلد',
    'type': 'region',
    'active': true,
    'children': [
      {
        'id': 2,
        'name': 'إزرع',
        'type': 'unit',
        'active': true,
        'regionId': 1,
        'regionName': 'درعا البلد',
        'children': [
          {
            'id': 3,
            'name': 'إبطع',
            'type': 'neighborhood',
            'active': true,
            'regionId': 1,
            'regionName': 'درعا البلد',
            'unitId': 2,
            'unitName': 'إزرع',
            'children': [
              {
                'id': 4,
                'name': 'الحي الغربي',
                'type': 'zone',
                'active': true,
                'regionId': 1,
                'regionName': 'درعا البلد',
                'unitId': 2,
                'unitName': 'إزرع',
                'neighborhoodId': 3,
                'neighborhoodName': 'إبطع',
                'children': <dynamic>[],
              },
              {
                'id': 5,
                'name': 'الحي الشرقي',
                'type': 'zone',
                'active': true,
                'regionId': 1,
                'regionName': 'درعا البلد',
                'unitId': 2,
                'unitName': 'إزرع',
                'neighborhoodId': 3,
                'neighborhoodName': 'إبطع',
                'children': <dynamic>[],
              },
            ],
          },
        ],
      },
    ],
  },
];

class _FakeAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode(_tree),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MemoryStorage extends SecureStorage {
  _MemoryStorage() : super(null, false);

  final Map<String, String> values = <String, String>{};

  @override
  Future<void> setValue(DbKeys key, String value) async =>
      values[key.name] = value;

  @override
  Future<String?> getValue(DbKeys key) async => values[key.name];

  @override
  Future<void> deleteValue(DbKeys key) async => values.remove(key.name);
}

void main() {
  late _FakeAdapter adapter;
  late HierarchyRepositoryImpl hierarchy;
  late HomeRepositoryImpl home;

  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_URL=https://example.test/api');
  });

  setUp(() {
    adapter = _FakeAdapter();
    final client = ApiClient(secureStorage: _MemoryStorage())
      ..dio.httpClientAdapter = adapter;
    final apiService = ApiService(client);
    hierarchy = HierarchyRepositoryImpl(apiService);
    home = HomeRepositoryImpl(apiService, hierarchy);
  });

  test('areas are the tree flattened depth-first', () async {
    final result = await home.getAllAreas();
    final areas = result.getOrElse(() => []);

    expect(
      areas.map((a) => a.id),
      [1, 2, 3, 4, 5],
      reason: 'region, unit, neighborhood, then its zones',
    );
    expect(areas.first.name, 'درعا البلد');
  });

  test('a zone area carries its ancestors', () async {
    final areas = (await home.getAllAreas()).getOrElse(() => []);
    final zone = areas.firstWhere((a) => a.id == 4);

    expect(zone.name, 'الحي الغربي');
    expect(zone.zoneName, 'الحي الغربي');
    expect(zone.neighborhoodName, 'إبطع');
    expect(zone.unitName, 'إزرع');
    expect(zone.regionName, 'درعا البلد');
  });

  test('only zones get a zoneName', () async {
    final areas = (await home.getAllAreas()).getOrElse(() => []);

    expect(areas.firstWhere((a) => a.id == 3).zoneName, isEmpty);
  });

  test('areas and the pickers share one request', () async {
    await hierarchy.getRegions();
    await home.getAllAreas();
    await home.getWatchedAreas();

    expect(adapter.calls, 1);
  });

  test('available areas page over the cache', () async {
    final page = (await home.getAvailableAreas(size: 2)).getOrElse(
      () => throw StateError('expected a page'),
    );

    expect(page.content.map((a) => a.id), [1, 2]);
    expect(page.totalElements, 5);
    expect(page.totalPages, 3);
    expect(page.isFirst, isTrue);
    expect(page.isLast, isFalse);
  });

  test('the last page stops at the end', () async {
    final page = (await home.getAvailableAreas(page: 2, size: 2)).getOrElse(
      () => throw StateError('expected a page'),
    );

    expect(page.content.map((a) => a.id), [5]);
    expect(page.isLast, isTrue);
  });

  test('search filters by name', () async {
    final page = (await home.getAvailableAreas(search: 'الحي')).getOrElse(
      () => throw StateError('expected a page'),
    );

    expect(page.content.map((a) => a.id), [4, 5]);
    expect(page.totalElements, 2);
  });
}
