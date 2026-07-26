import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Cloud Messaging. Requests permission, listens for
/// messages, and surfaces the FCM token via [onTokenRegister] so the app
/// can PATCH it to `/api/v1/auth/me/push-token` (see main.dart) — both on
/// first launch and whenever FCM rotates the token.
class PushService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  void Function(RemoteMessage message)? onForegroundMessage;
  void Function(String token)? onTokenRegister;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen((message) {
      onForegroundMessage?.call(message);
    });
    final token = await _messaging.getToken();
    if (token != null) {
      onTokenRegister?.call(token);
      if (kDebugMode) debugPrint('FCM token: $token');
    }
    _messaging.onTokenRefresh.listen((newToken) {
      onTokenRegister?.call(newToken);
    });
  }
}

final pushService = PushService();
