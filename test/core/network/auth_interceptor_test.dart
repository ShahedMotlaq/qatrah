import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qatrah/core/local_storage/secure_storage.dart';
import 'package:qatrah/core/network/api_client.dart';
import 'package:qatrah/core/network/api_endpoints.dart';

/// In-memory [SecureStorage]: every read/write funnels through these three
/// primitives, so overriding them is enough for the whole token API.
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

  @override
  Future<void> setDynamicValue(String key, String value) async =>
      values[key] = value;

  @override
  Future<String?> getDynamicValue(String key) async => values[key];

  @override
  Future<void> deleteDynamicValue(String key) async => values.remove(key);
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  // ApiClient is a singleton, so it keeps the storage it was first built
  // with — one instance for the whole file, wiped between tests.
  final storage = _MemoryStorage();
  late ApiClient client;

  setUpAll(() {
    dotenv.loadFromString(envString: 'BASE_URL=https://example.test/api');
  });

  setUp(() async {
    storage.values.clear();
    client = ApiClient(secureStorage: storage);
    client.authInterceptor.clearCachedToken();
    await storage.setRole('OPERATOR');
    await storage.setToken('access-1', role: 'OPERATOR');
    await storage.setRefreshToken('refresh-1');
  });

  String? authOf(RequestOptions o) => o.headers['Authorization'] as String?;

  test('bearer on protected routes and logout, none on public auth', () async {
    final adapter = _FakeAdapter((_) => _json(200, {}));
    client.dio.httpClientAdapter = adapter;

    await client.dio.get<dynamic>(ApiEndpoints.currentUser);
    await client.dio.post<dynamic>(ApiEndpoints.logout, data: {});
    await client.dio.post<dynamic>(ApiEndpoints.login, data: {});
    await client.dio.post<dynamic>(ApiEndpoints.refresh, data: {});

    expect(authOf(adapter.requests[0]), 'Bearer access-1');
    expect(authOf(adapter.requests[1]), 'Bearer access-1');
    expect(authOf(adapter.requests[2]), isNull);
    expect(authOf(adapter.requests[3]), isNull);
  });

  test('401 UNAUTHENTICATED refreshes once and retries the request', () async {
    var protectedCalls = 0;
    final adapter = _FakeAdapter((o) {
      if (o.path == ApiEndpoints.refresh) {
        return _json(200, {'token': 'access-2', 'refreshToken': 'refresh-2'});
      }
      protectedCalls++;
      if (protectedCalls == 1) return _json(401, {'code': 'UNAUTHENTICATED'});
      return _json(200, {'ok': true});
    });
    client.dio.httpClientAdapter = adapter;

    final res = await client.dio.get<dynamic>(ApiEndpoints.currentUser);

    expect(res.statusCode, 200);
    expect(protectedCalls, 2);
    expect(
      adapter.requests.where((o) => o.path == ApiEndpoints.refresh).length,
      1,
      reason: 'exactly one refresh — the token rotates',
    );
    expect(authOf(adapter.requests.last), 'Bearer access-2');
    expect(await storage.getToken(), 'access-2');
    expect(await storage.getRefreshToken(), 'refresh-2');
  });

  test('401 ACCOUNT_DISABLED is not refreshable — session cleared', () async {
    final adapter = _FakeAdapter(
      (_) => _json(401, {'code': 'ACCOUNT_DISABLED'}),
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.get<dynamic>(ApiEndpoints.currentUser),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests.map((o) => o.path), isNot(contains('/auth/refresh')));
    expect(await storage.getToken(), isNull);
  });

  test('403 LOGIN_CHANNEL_NOT_ALLOWED clears the session', () async {
    final adapter = _FakeAdapter(
      (_) => _json(403, {'code': 'LOGIN_CHANNEL_NOT_ALLOWED'}),
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.get<dynamic>(ApiEndpoints.currentUser),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getToken(), isNull);
  });

  test('403 FORBIDDEN_OPERATION keeps the session', () async {
    final adapter = _FakeAdapter(
      (_) => _json(403, {'code': 'FORBIDDEN_OPERATION'}),
    );
    client.dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.get<dynamic>(ApiEndpoints.currentUser),
      throwsA(isA<DioException>()),
    );
    expect(await storage.getToken(), 'access-1');
  });
}
