import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'app_navigator.dart';
import 'notification_payload.dart';

class PushNotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _syncCurrentUserToken();

    FirebaseAuth.instance.authStateChanges().listen((_) async {
      await _syncCurrentUserToken();
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _saveTokenForCurrentUser(token);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageNavigation(initialMessage);
    }
  }

  static Future<void> _syncCurrentUserToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _saveTokenForCurrentUser(token);
  }

  static Future<void> _saveTokenForCurrentUser(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static void _handleMessageNavigation(RemoteMessage message) {
    final postId = NotificationPayload.extractPostId(message.data);
    if (postId == null) return;

    AppNavigator.openPostById(postId);
  }

  static bool openFromPayload(Map<String, dynamic> data) {
    final postId = NotificationPayload.extractPostId(data);
    if (postId == null) return false;
    AppNavigator.openPostById(postId);
    return true;
  }

  static bool openFromDeepLink(String deepLink) {
    if (deepLink.trim().isEmpty) return false;
    return openFromPayload(<String, dynamic>{'deepLink': deepLink.trim()});
  }
}
