// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Third-party package imports
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:convert';

// Local imports
import 'app/bootstrap.dart';
import 'screens/tutorial/tutorial_screen.dart';
import 'screens/home/home_screen.dart';

// Part files for code splitting
part 'parts/main_utils.dart';
part 'parts/main_models.dart';
part 'parts/main_widgets.dart';
part 'parts/main_services.dart';
part 'parts/main_app.dart';

// 高速化：シンプルなデバッグログ
void _debugLog(final String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() async {
  await bootstrap();
  runApp(
    const ProviderScope(
      child: MedicationAlarmApp(),
    ),
  );
}
