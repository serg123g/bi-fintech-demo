import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/resilient_executor.dart';
import '../domain/push_messaging_client.dart';

/// Registra el token vía RPC `register_device_token` (upsert idempotente que
/// además reasigna el token si otro usuario lo tenía en este dispositivo).
class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  SupabaseDeviceTokenRepository(this._client, this._executor);

  static const service = 'device-tokens';

  final SupabaseClient _client;
  final ResilientExecutor _executor;

  @override
  Future<void> register(String token, String platform) =>
      _executor.run(service, (_) async {
        await _client.rpc<void>(
          'register_device_token',
          params: {'p_token': token, 'p_platform': platform},
        );
      });
}
