import 'package:get_it/get_it.dart';

import '../config/env.dart';
import '../logging/app_logger.dart';

/// Service locator global. Las features solo dependen de interfaces de
/// `domain`; las implementaciones se registran aquí (composition root).
final GetIt sl = GetIt.instance;

/// Permite a tests y al E2E reemplazar registros (repos fake, executor
/// con chaos, etc.) antes de construir la app.
typedef DiOverrides = void Function(GetIt sl);

Future<void> configureDependencies({
  EnvConfig? env,
  DiOverrides? overrides,
}) async {
  await sl.reset();
  sl
    ..registerSingleton<EnvConfig>(env ?? EnvConfig.fromEnvironment())
    ..registerSingleton<AppLogger>(const ConsoleLogger());

  // Las fases siguientes registran aquí: network, cache, repos y blocs.

  overrides?.call(sl);
}
