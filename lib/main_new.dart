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
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local imports
import 'simple_alarm_app.dart';
import 'core/snapshot_service.dart';
import 'utils/locale_helper.dart';
import 'app/bootstrap.dart';

// Part files for code splitting
part 'parts/main_utils.dart';
part 'parts/main_models.dart';
part 'parts/main_widgets.dart';
part 'parts/main_services.dart';
part 'parts/main_app.dart';

// 高速化：シンプルなデバッグログ
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() async {
  await bootstrap();
  runApp(const MedicationAlarmApp());
}