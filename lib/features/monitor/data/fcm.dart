import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/diagnostics.dart';

/// Starts Firebase on Android. Elsewhere (Windows dev builds, tests) there
/// is no `google-services.json`, so push is simply unavailable.
Future<bool> initFirebase() async {
  if (!Platform.isAndroid) return false;
  try {
    await Firebase.initializeApp();
    return true;
  } on Object catch (e) {
    debugLogError('firebase init', e);
    return false;
  }
}

/// This phone's FCM address, or null when push is not available.
Future<String?> fcmToken() async {
  try {
    // The replacement API returns an installation id, not the registration
    // token the FCM v1 "token" field is documented to take.
    // ignore: deprecated_member_use
    return await FirebaseMessaging.instance.getToken();
  } on Object catch (e) {
    debugLogError('fcm token', e);
    return null;
  }
}
