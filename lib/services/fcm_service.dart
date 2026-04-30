import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> initialize(BuildContext context) async {
    await requestPermission();
    await saveTokenToFirestore();
    listenForTokenRefresh();
    listenForForegroundMessages(context);
    listenForNotificationTaps(context);
  }

  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final token = await _messaging.getToken();

    if (token == null) return;

    await _db.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      await _db.collection('users').doc(user.uid).set({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void listenForForegroundMessages(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'StepQuest';
      final body = message.notification?.body ?? 'New adventure update!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $body'),
        ),
      );
    });
  }

  void listenForNotificationTaps(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final type = message.data['type'];

      if (type == 'quest') {
        Navigator.pushNamed(context, '/quest');
      } else if (type == 'guild') {
        Navigator.pushNamed(context, '/guild');
      } else {
        Navigator.pushNamed(context, '/dashboard');
      }
    });
  }
}
