// Dart core imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local imports
import '../utils/locale_helper.dart';
import '../utils/logger.dart';
import '../utils/error_handler.dart';
import '../utils/constants.dart';
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../models/medication_info.dart';
import '../services/data_repository.dart';
import '../services/data_manager.dart';
import '../widgets/common_widgets.dart';
import '../widgets/trial_widgets.dart';
import '../widgets/tutorial_widgets.dart';
import '../widgets/memo_dialog.dart';
import '../screens/medication_home_page.dart';

/// メインのアプリケーションクラス
class MedicationAlarmApp extends StatelessWidget {
  const MedicationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '服用アラーム',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const TutorialWrapper(),
    );
  }
}
