import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'cache_store.dart';

/// Cache persistente en Hive, cifrada con AES-256. La llave se genera una vez
/// y vive en el Keychain/Keystore (flutter_secure_storage), nunca en disco
/// junto a los datos.
class HiveCacheStore implements CacheStore {
  HiveCacheStore._(this._box, this._now);

  static const _boxName = 'swr_cache_v1';
  static const _keyName = 'swr_cache_key_v1';

  final Box<String> _box;
  final DateTime Function() _now;

  static Future<HiveCacheStore> open({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
    DateTime Function()? clock,
  }) async {
    await Hive.initFlutter();
    var encoded = await storage.read(key: _keyName);
    if (encoded == null) {
      encoded = base64UrlEncode(Hive.generateSecureKey());
      await storage.write(key: _keyName, value: encoded);
    }
    final box = await Hive.openBox<String>(
      _boxName,
      encryptionCipher: HiveAesCipher(base64Url.decode(encoded)),
    );
    return HiveCacheStore._(box, clock ?? DateTime.now);
  }

  @override
  Future<CacheEntry?> read(String key) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry(
        data: map['data'] as String,
        savedAt: DateTime.parse(map['savedAt'] as String),
      );
    } on FormatException {
      await _box.delete(key);
      return null;
    }
  }

  @override
  Future<void> write(String key, String data) => _box.put(
    key,
    jsonEncode({'data': data, 'savedAt': _now().toIso8601String()}),
  );

  @override
  Future<void> clear() => _box.clear();
}
