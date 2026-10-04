import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

/// Abstracción de logging. En producción se reemplaza por una implementación
/// que reenvía a Crashlytics/Sentry (ver docs/OPERATIONS.md) sin tocar features.
abstract interface class AppLogger {
  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  });
}

extension AppLoggerX on AppLogger {
  void debug(String m, [Map<String, Object?> c = const {}]) =>
      log(LogLevel.debug, m, context: c);
  void info(String m, [Map<String, Object?> c = const {}]) =>
      log(LogLevel.info, m, context: c);
  void warning(String m, [Map<String, Object?> c = const {}]) =>
      log(LogLevel.warning, m, context: c);
  void error(
    String m, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) => log(
    LogLevel.error,
    m,
    context: context,
    error: error,
    stackTrace: stackTrace,
  );
}

/// Logger estructurado a consola (`dart:developer`), formato `clave=valor`
/// para que sea fácil de filtrar por `correlationId`.
class ConsoleLogger implements AppLogger {
  const ConsoleLogger({this.name = 'fintech'});

  final String name;

  @override
  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final ctx = context.entries.map((e) => '${e.key}=${e.value}').join(' ');
    developer.log(
      '[${level.name.toUpperCase()}] $message ${ctx.isEmpty ? '' : '| $ctx'}',
      name: name,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}
