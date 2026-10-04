import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/push_message.dart';
import '../domain/push_messaging_client.dart';

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient([FirebaseMessaging? messaging])
    : _fcm = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _fcm;

  static PushMessage _map(RemoteMessage m) => PushMessage(
    title: m.notification?.title,
    body: m.notification?.body,
    data: Map<String, Object?>.from(m.data),
  );

  @override
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _fcm.getToken();

  @override
  Future<void> deleteToken() => _fcm.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_map);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_map);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final m = await _fcm.getInitialMessage();
    return m == null ? null : _map(m);
  }

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';
}
