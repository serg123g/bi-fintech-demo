import 'cache_store.dart';
import 'data_result.dart';

/// Emite primero lo cacheado (si existe) y luego lo fresco de la red,
/// actualizando la cache. Si la red falla, el stream termina con el
/// `AppFailure` como error *después* de haber entregado la cache, de modo
/// que la UI puede seguir mostrando datos y avisar que no se actualizaron.
Stream<DataResult<T>> staleWhileRevalidate<T>({
  required CacheStore cache,
  required String key,
  required Future<T> Function() fetch,
  required T Function(String json) decode,
  required String Function(T value) encode,
  DateTime Function()? clock,
}) async* {
  final now = clock ?? DateTime.now;

  CacheEntry? cached;
  try {
    cached = await cache.read(key);
  } on Object {
    cached = null; // cache corrupta o inaccesible: se ignora
  }
  if (cached != null) {
    T? value;
    try {
      value = decode(cached.data);
    } on Object {
      value = null;
    }
    if (value != null) {
      yield DataResult(value, DataSource.cache, cached.savedAt);
    }
  }

  final fresh = await fetch();
  try {
    await cache.write(key, encode(fresh));
  } on Object {
    // No poder escribir la cache no debe romper la respuesta fresca.
  }
  yield DataResult(fresh, DataSource.network, now());
}
