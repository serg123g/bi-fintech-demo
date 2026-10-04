import 'dart:convert';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/data_result.dart';
import '../../../core/cache/stale_while_revalidate.dart';
import '../../../core/errors/failures.dart';
import '../../../sdui/sdui_models.dart';
import '../../../sdui/sdui_parser.dart';
import '../domain/home_layout_repository.dart';
import 'home_layout_remote_data_source.dart';

class HomeLayoutRepositoryImpl implements HomeLayoutRepository {
  HomeLayoutRepositoryImpl({
    required HomeLayoutRemoteDataSource remote,
    required CacheStore cache,
    required String Function() currentUserId,
    required Future<String> Function() loadFallback,
    DateTime Function()? clock,
  }) : _remote = remote,
       _cache = cache,
       _userId = currentUserId,
       _loadFallback = loadFallback,
       _now = clock ?? DateTime.now;

  final HomeLayoutRemoteDataSource _remote;
  final CacheStore _cache;
  final String Function() _userId;
  final Future<String> Function() _loadFallback;
  final DateTime Function() _now;

  Future<SduiLayout> _fetch() async {
    final json = await _remote.fetchLayout();
    try {
      return SduiParser.parse(json);
    } on FormatException {
      // Contrato roto o versión futura: se trata como fallo no transitorio.
      throw const ServerFailure(
        message: 'No pudimos personalizar tu inicio.',
        retryable: false,
      );
    }
  }

  @override
  Stream<DataResult<SduiLayout>> watchHome() async* {
    var delivered = false;
    try {
      await for (final r in staleWhileRevalidate<SduiLayout>(
        cache: _cache,
        key: 'home_layout:${_userId()}',
        fetch: _fetch,
        decode: (s) => SduiParser.parse(jsonDecode(s)),
        encode: (l) => jsonEncode(l.toJson()),
        clock: _now,
      )) {
        delivered = true;
        yield r;
      }
    } on AppFailure {
      if (!delivered) {
        // Ni red ni cache: layout empaquetado para que el home nunca quede
        // en blanco.
        final fallback = SduiParser.parse(jsonDecode(await _loadFallback()));
        yield DataResult(fallback, DataSource.fallback, _now());
      }
      rethrow;
    }
  }
}
