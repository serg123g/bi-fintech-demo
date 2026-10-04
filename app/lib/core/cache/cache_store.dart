import 'package:equatable/equatable.dart';

class CacheEntry extends Equatable {
  const CacheEntry({required this.data, required this.savedAt});

  /// JSON serializado.
  final String data;
  final DateTime savedAt;

  @override
  List<Object?> get props => [data, savedAt];
}

/// Almacenamiento clave-valor para stale-while-revalidate.
/// Las claves deben incluir el id de usuario para no mezclar datos entre
/// sesiones en el mismo dispositivo.
abstract interface class CacheStore {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, String data);

  /// Se llama al cerrar sesión: no deben quedar datos financieros en disco.
  Future<void> clear();
}

class InMemoryCacheStore implements CacheStore {
  InMemoryCacheStore({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, CacheEntry> _entries = {};

  @override
  Future<CacheEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, String data) async =>
      _entries[key] = CacheEntry(data: data, savedAt: _now());

  @override
  Future<void> clear() async => _entries.clear();
}
