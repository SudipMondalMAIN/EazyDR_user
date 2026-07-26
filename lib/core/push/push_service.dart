import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Cloud Messaging. The backend already stores a
/// `device_push_token` column on the user and sends pushes from
/// notifications/app_config broadcast tasks, but exposes no client-facing
/// endpoint yet to *register* that token — so this service requests
/// permission and listens for messages (foreground banners handled by the
/// OS on Android/iOS, in-app snackbar hook available via [onForegroundMessage])
/// without attempting a token upload. Wire up `onTokenRegister` once the
/// backend adds that endpoint.
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
