/// ストレージキー定数
/// SharedPreferencesとHiveで使用するキーを一元管理します
class StorageKeys {
  // メディケーション関連
  static const String medicationMemosKey = 'medication_memos_v2';
  static const String medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String medicationDoseStatusKey = 'medication_dose_status_v2';
  static const String addedMedicationsKey = 'added_medications_v2';
  
  // アラーム関連
  static const String alarmListKey = 'alarm_list_v2';
  static const String alarmSettingsKey = 'alarm_settings_v2';
  
  // カレンダー関連
  static const String calendarMarksKey = 'calendar_marks_v2';
  static const String dayColorsKey = 'day_colors_v2';
  static const String selectedDatesKey = 'selected_dates_v2';
  
  // 統計関連
  static const String statisticsKey = 'statistics_v2';
  static const String adherenceRatesKey = 'adherence_rates_v2';
  
  // ユーザー設定関連
  static const String userPreferencesKey = 'user_preferences_v2';
  static const String appSettingsKey = 'app_settings_v2';
  
  // バックアップ関連
  static const String backupHistoryKey = 'backup_history_v2';
  static const String backupSuffix = '_backup';
  
  // メディケーションデータ関連
  static const String medicationDataKey = 'medication_data_v2';
  
  // その他
  static const String lastOperationTimeKey = 'last_operation_time_v2';
  static const String memoTextKey = 'memo_text_v2';
}

