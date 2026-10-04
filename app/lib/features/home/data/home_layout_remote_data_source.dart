import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/resilient_executor.dart';

abstract interface class HomeLayoutRemoteDataSource {
  Future<Map<String, dynamic>> fetchLayout();
}

/// Llama a la Edge Function `home-layout` con el access token de la sesión
/// (lo agrega el SDK) y el correlation id del executor.
class SupabaseHomeLayoutRemoteDataSource implements HomeLayoutRemoteDataSource {
  SupabaseHomeLayoutRemoteDataSource(this._client, this._executor);

  static const service = 'home-layout';

  final SupabaseClient _client;
  final ResilientExecutor _executor;

  @override
  Future<Map<String, dynamic>> fetchLayout() =>
      _executor.run(service, (ctx) async {
        final res = await _client.functions.invoke(
          service,
          method: HttpMethod.get,
          headers: ctx.headers,
        );
        final data = res.data;
        if (data is Map<String, dynamic>) return data;
        if (data is String) return jsonDecode(data) as Map<String, dynamic>;
        throw const ServerFailure(
          message: 'Respuesta inválida del servidor.',
          retryable: false,
        );
      });
}
