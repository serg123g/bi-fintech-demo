import 'package:fintech_platform/core/cache/cache_store.dart';
import 'package:fintech_platform/core/cache/data_result.dart';
import 'package:fintech_platform/core/cache/stale_while_revalidate.dart';
import 'package:fintech_platform/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 4, 10);
  final t1 = DateTime(2026, 10, 4, 10, 30);

  Stream<DataResult<int>> swr(CacheStore cache, Future<int> Function() fetch) =>
      staleWhileRevalidate<int>(
        cache: cache,
        key: 'k',
        fetch: fetch,
        decode: int.parse,
        encode: (v) => '$v',
        clock: () => t1,
      );

  test('sin cache: solo emite red y la guarda', () async {
    final cache = InMemoryCacheStore(clock: () => t0);
    final events = await swr(cache, () async => 7).toList();
    expect(events, [DataResult(7, DataSource.network, t1)]);
    expect((await cache.read('k'))?.data, '7');
  });

  test('con cache: emite cache (con su fecha) y luego red', () async {
    final cache = InMemoryCacheStore(clock: () => t0);
    await cache.write('k', '1');
    final events = await swr(cache, () async => 2).toList();
    expect(events, [
      DataResult(1, DataSource.cache, t0),
      DataResult(2, DataSource.network, t1),
    ]);
  });

  test('red caída con cache: entrega cache y termina con el fallo', () async {
    final cache = InMemoryCacheStore(clock: () => t0);
    await cache.write('k', '1');
    final data = <DataResult<int>>[];
    Object? error;
    await swr(
      cache,
      () async => throw const NetworkFailure(),
    ).handleError((Object e) => error = e).forEach(data.add);
    expect(data, [DataResult(1, DataSource.cache, t0)]);
    expect(error, isA<NetworkFailure>());
  });

  test('cache corrupta se ignora', () async {
    final cache = InMemoryCacheStore(clock: () => t0);
    await cache.write('k', 'no-es-un-int');
    final events = await swr(cache, () async => 3).toList();
    expect(events.single.source, DataSource.network);
  });
}
