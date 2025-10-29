// Dart core imports
import 'dart:async';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Third-party package imports
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';

// Local imports
import 'firebase_options.dart';
import 'simple_alarm_app.dart';
import 'core/snapshot_service.dart';
import 'utils/locale_helper.dart';
import 'utils/logger.dart';
import 'utils/error_handler.dart';
import 'utils/constants.dart';
import 'models/medication_memo.dart';
import 'models/medicine_data.dart';
import 'models/medication_info.dart';
import 'services/data_repository.dart';
import 'services/data_manager.dart';
import 'widgets/common_widgets.dart';
import 'widgets/trial_widgets.dart';
import 'widgets/tutorial_widgets.dart';
import 'widgets/memo_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Firebase初期化
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Crashlytics初期化
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // タイムゾーン初期化
    tz.initializeTimeZones();
    
    // Hive初期化
    await Hive.initFlutter();
    
    // アダプター登録
    Hive.registerAdapter(MedicationMemoAdapter());
    Hive.registerAdapter(MedicineDataAdapter());
    Hive.registerAdapter(MedicationInfoAdapter());
    
    // データリポジトリ初期化
    await DataRepository.initialize();
    await DataManager.initialize();
    
    // ロケール初期化
    await LocaleHelper.initialize();
    
    Logger.info('アプリ初期化完了');
    
    runApp(const MedicationAlarmApp());
  } catch (e, stackTrace) {
    AppErrorHandler.handleError(e, stackTrace, context: 'アプリ初期化');
    runApp(const MedicationAlarmApp());
  }
}