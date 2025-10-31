// アプリケーションのルートウィジェット
// アプリケーションのテーマ、ロケール、およびホーム画面を設定します

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import '../services/trial_service.dart';

/// アプリケーションのルートウィジェット
/// テーマとロケールを設定し、ホーム画面を表示します
class MedicationAlarmApp extends StatelessWidget {
  const MedicationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サプリ＆おくすりスケジュール管理帳',
      locale: const Locale('ja', 'JP'),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7A5C),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16.0)),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F7A5C),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 16.0)),
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MedicationHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
  
  /// フォントサイズを取得（後方互換性のため）
  static Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('fontSize') ?? 16.0;
    } catch (e) {
      return 16.0;
    }
  }
}

