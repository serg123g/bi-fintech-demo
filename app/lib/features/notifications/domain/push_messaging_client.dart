import 'push_message.dart';

/// Abstracción del proveedor de push (FCM). Permite testear el coordinador
/// y, a futuro, cambiar de proveedor sin tocar la app.
abstract interface class PushMessagingClient {
  /// `true` si el usuario autorizó notificaciones.
  Future<bool> requestPermission();

  Future<String?> getToken();

  /// Invalida el token del dispositivo (logout).
  Future<void> deleteToken();

  Stream<String> get onTokenRefresh;

  /// Mensajes recibidos con la app en primer plano.
  Stream<PushMessage> get onForegroundMessage;

  /// Notificación tocada con la app en segundo plano.
  Stream<PushMessage> get onMessageOpenedApp;

  /// Notificación que abrió la app desde cerrada (terminated).
  Future<PushMessage?> getInitialMessage();

  String get platform;
}

abstract interface class DeviceTokenRepository {
  Future<void> register(String token, String platform);
}
