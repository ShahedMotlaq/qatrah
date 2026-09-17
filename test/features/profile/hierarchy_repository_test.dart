import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/api_service.dart';
import 'package:qatrah/features/profile/data/repositories/hierarchy_repository_impl.dart';
import 'package:qatrah/features/profile/domain/entities/hierarchy_node_entity.dart';

/// One region → one unit → two neighborhoods → two zones under the first,
/// one under the second. Shaped exactly like `GET /hierarchy/tree`.
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
        'children': [
          {
            'id': 3,
            'name': 'إبطع',
            'type': 'neighborhood',
            'active': true,
            'regionId': 1,
            'unitId': 2,
            'children': [
              {
                'id': 4,
                'name': 'الحي الغربي',
                'type': 'zone',
                'active': true,
                'regionId': 1,
                'unitId': 2,
                'neighborhoodId': 3,
                'children': <dynamic>[],
              },
              {
                'id': 5,
                'name': 'الحي الشرقي',
                'type': 'zone',
                'active': true,
                'regionId': 1,
                'unitId': 2,
                'neighborhoodId': 3,
                'children': <dynamic>[],
              },
            ],
          },
          {
            'id': 6,
            'name': 'نوى',
            'type': 'neighborhood',
            'active': true,
            'regionId': 1,
            'unitId': 2,
            'children': [
              {
                'id': 7,
                'name': 'حي النور',
                'type': 'zone',
                'active': true,
                'regionId': 1,
                'unitId': 2,
                'neighborhoodId': 6,
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
  late HierarchyRepositoryImpl repository;

  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_URL=https://example.test/api');
  });

  setUp(() {
    adapter = _FakeAdapter();
    final client = ApiClient(secureStorage: _MemoryStorage())
      ..dio.httpClientAdapter = adapter;
    repository = HierarchyRepositoryImpl(ApiService(client));
  });

  test('the whole tree arrives in one request', () async {
    final result = await repository.getTree();

    final roots = result.getOrElse(() => []);
    expect(roots, hasLength(1));
    expect(roots.single.level, HierarchyLevel.region);
    expect(roots.single.children.single.name, 'إزرع');
    expect(adapter.calls, 1);
  });

  test('four levels cost one request, not four', () async {
    final regions = await repository.getRegions();
    final units = await repository.getUnits(1);
    final neighborhoods = await repository.getNeighborhoods(2);
    final zones = await repository.getZones(3);

    expect(regions.getOrElse(() => []).map((e) => e.name), ['درعا البلد']);
    expect(units.getOrElse(() => []).map((e) => e.id), [2]);
    expect(neighborhoods.getOrElse(() => []).map((e) => e.id), [3, 6]);
    expect(zones.getOrElse(() => []).map((e) => e.id), [4, 5]);
    expect(adapter.calls, 1, reason: 'the tree is cached for the session');
  });

  test('concurrent callers share one in-flight request', () async {
    await Future.wait([
      repository.getRegions(),
      repository.getUnits(1),
      repository.getNeighborhoods(2),
      repository.getZones(3),
    ]);

    expect(adapter.calls, 1);
  });

  test('children are scoped to their own parent, not the region', () async {
    final zones = await repository.getZones(6);

    expect(
      zones.getOrElse(() => []).map((e) => e.id),
      [7],
      reason: 'zone 4 and 5 belong to neighborhood 3, not 6',
    );
  });

  test('an unknown parent yields nothing rather than everything', () async {
    final units = await repository.getUnits(999);

    units.fold(
      (failure) => fail('expected an empty list, got ${failure.errMessage}'),
      (list) => expect(list, isEmpty),
    );
  });

  test('forceRefresh refetches', () async {
    await repository.getRegions();
    await repository.getTree(forceRefresh: true);

    expect(adapter.calls, 2);
  });
}
