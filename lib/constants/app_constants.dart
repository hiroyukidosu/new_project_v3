// アプリ全体で使用する定数

/// アプリケーション定数
class AppConstants {
  // アニメーション時間
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // デバウンス時間
  static const Duration debounceDelay = Duration(seconds: 2);
  static const Duration shortDebounceDelay = Duration(milliseconds: 500);
  
  // ログ間隔
  static const Duration logInterval = Duration(seconds: 30);
  
  // データ保存キー
  static const String medicationMemosKey = 'medication_memos_v2';
  static const String medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String addedMedicationsKey = 'added_medications_v2';
  static const String backupSuffix = '_backup';
  
  // カレンダー関連定数
  static const String calendarMarksKey = 'calendar_marks';
  static const Duration calendarScrollAnimationDuration = Duration(milliseconds: 300);
  static const double calendarScrollSensitivity = 3.0;
  static const double calendarScrollVelocityThreshold = 300.0;
}

