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
import 'utils/logger.dart';
import 'utils/error_handler.dart';
import 'utils/constants.dart';
import 'models/medication_memo.dart';
import 'models/medicine_data.dart';
import 'models/medication_info.dart';
import 'services/medication_service.dart';
import 'services/notification_service.dart';
import 'services/trial_service.dart';
import 'services/in_app_purchase_service.dart';
import 'services/data_repository.dart';
import 'services/data_manager.dart';
import 'screens/medication_home_page.dart';

// アプリ初期化クラス
class AppInitializer {
  static Future<void> initialize() async {
    try {
      // Firebase初期化
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Firebase Crashlytics初期化
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      
      // プラットフォーム固有のエラーハンドリング
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      
      // タイムゾーン初期化
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
      
      // ロケール初期化
      await initializeDateFormatting('ja_JP', null);
      
      // Hive初期化
      await Hive.initFlutter();
      
      // アダプター登録
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MedicationInfoAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MedicineDataAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(MedicationMemoAdapter());
      }
      
      // 各種サービスの初期化
      await MedicationService.initialize();
      await DataRepository.initialize();
      await DataManager.initialize();
      await TrialService.initializeTrial();
      
      Logger.info('アプリ初期化完了');
    } catch (e) {
      Logger.error('アプリ初期化エラー', e);
      AppErrorHandler.handleError(e, null, context: 'AppInitializer.initialize');
    }
  }
}

// メインの薬物管理アプリ
class MedicationAlarmApp extends StatelessWidget {
  const MedicationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '薬物管理アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MedicationHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// エントリーポイント
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(const MedicationAlarmApp());
}
