import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../firebase_options.dart';

/// App-wide bootstrap. Keep idempotent and resilient.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // ignore if already initialized or not configured
  }

  // Timezone/Intl
  try {
    tz.initializeTimeZones();
  } catch (_) {}
  try {
    await initializeDateFormatting('ja_JP');
  } catch (_) {}

  // Preferences
  try {
    await SharedPreferences.getInstance();
  } catch (_) {}

  // Hive
  try {
    await Hive.initFlutter();
  } catch (_) {}

  // Notifications (best-effort minimal init)
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await plugin.initialize(initSettings);
  } catch (_) {}
}


