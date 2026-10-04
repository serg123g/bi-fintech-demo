import 'dart:convert';

import 'package:fintech_platform/core/cache/cache_store.dart';
import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:fintech_platform/features/home/data/home_layout_remote_data_source.dart';
import 'package:fintech_platform/features/home/data/home_layout_repository_impl.dart';
import 'package:fintech_platform/sdui/sdui_models.dart';
import 'package:flutter_test/flutter_test.dart';

class _Remote implements HomeLayoutRemoteDataSource {
  Object response = _layout('home-joven-v1');

  @override
  Future<Map<String, dynamic>> fetchLayout() async {
    final r = response;
    if (r is AppFailure) throw r;
    return r as Map<String, dynamic>;
  }
}

Map<String, dynamic> _layout(String id) => {
  'version': 1,
  'layout_id': id,
  'sections': [
    {
      'id': 'g',
      'type': 'greeting',
      'props': {'text': 'Hola'},
    },
  ],
};

void main() {
  late _Remote remote;
  late InMemoryCacheStore cache;
  late HomeLayoutRepositoryImpl repo;

  setUp(() {
    remote = _Remote();
    cache = InMemoryCacheStore();
    repo = HomeLayoutRepositoryImpl(
      remote: remote,
      cache: cache,
      currentUserId: () => 'u1',
      loadFallback: () async => jsonEncode(_layout('home-fallback-v1')),
    );
  });

  Future<(List<DataResult<SduiLayout>>, Object?)> run() async {
    final data = <DataResult<SduiLayout>>[];
    Object? error;
    await repo
        .watchHome()
        .handleError((Object e) => error = e)
        .forEach(data.add);
    return (data, error);
  }

  test('red OK: layout personalizado y se guarda en cache', () async {
    final (data, error) = await run();
    expect(error, isNull);
    expect(data.single.data.layoutId, 'home-joven-v1');
    expect(await cache.read('home_layout:u1'), isNotNull);
  });

  test('endpoint caído con cache: último layout guardado + fallo', () async {
    await run(); // guarda
    remote.response = const ServerFailure();
    final (data, error) = await run();
    expect(data.single.source, DataSource.cache);
    expect(data.single.data.layoutId, 'home-joven-v1');
    expect(error, isA<ServerFailure>());
  });

  test('endpoint caído sin cache: layout empaquetado + fallo', () async {
    remote.response = const NetworkFailure();
    final (data, error) = await run();
    expect(data.single.source, DataSource.fallback);
    expect(data.single.data.layoutId, 'home-fallback-v1');
    expect(error, isA<NetworkFailure>());
  });

  test('contrato inválido (versión futura) -> fallback', () async {
    remote.response = {'version': 99, 'sections': <Object>[]};
    final (data, error) = await run();
    expect(data.single.source, DataSource.fallback);
    expect(error, isA<ServerFailure>());
  });
}
