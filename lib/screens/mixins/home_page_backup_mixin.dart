// バックアップ/復元機能のMixin（統合版）
// home_page.dartからバックアップ関連の機能を分離
// 機能別に分割されたMixinを統合して使用

import 'backup_core_mixin.dart';
import 'backup_dialog_mixin.dart';
import 'backup_restore_mixin.dart';
import 'backup_history_mixin.dart';
import '../../models/medication_memo.dart';
import '../../models/medicine_data.dart';
import '../../models/medication_info.dart';
import 'package:flutter/material.dart';

/// バックアップ/復元機能のMixin（統合版）
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
/// 複数のMixinを統合して提供
/// 
/// 使用例:
/// ```dart
/// class MyPageState extends State<MyPage> 
///     with BackupCoreMixin, BackupDialogMixin, BackupRestoreMixin, BackupHistoryMixin {
///   // BackupCoreMixinで必要なゲッター/セッターを実装
///   @override
///   DateTime? get selectedDay => _selectedDay;
///   // ... 他のゲッター/セッター
/// }
/// ```
/// 
/// または、直接HomePageBackupMixinを使用することもできます。
/// この場合は、すべての抽象メソッドとゲッター/セッターを実装する必要があります。
mixin HomePageBackupMixin<T extends StatefulWidget> on State<T> {
  // 注意: このMixinは統合版です
  // 実際の実装は以下のMixinをwithで結合して使用してください:
  // - BackupCoreMixin: コア機能（データ作成、暗号化など）
  // - BackupDialogMixin: ダイアログ表示
  // - BackupRestoreMixin: 復元機能
  // - BackupHistoryMixin: 履歴表示機能
  
  // 抽象ゲッター/セッター（実装クラスで提供する必要がある）
  DateTime? get selectedDay;
  DateTime? get focusedDay;
  DateTime? get lastOperationTime;
  List<MedicationMemo> get medicationMemos;
  List<Map<String, dynamic>> get addedMedications;
  List<MedicineData> get medicines;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  Map<String, Map<String, bool>> get weekdayMedicationStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  Map<String, bool> get medicationMemoStatus;
  Map<String, Color> get dayColors;
  List<Map<String, dynamic>> get alarmList;
  Map<String, dynamic> get alarmSettings;
  Map<String, double> get adherenceRates;
  TextEditingController get memoController;
  ValueNotifier<String> get memoTextNotifier;
  ValueNotifier<Map<String, Color>> get dayColorsNotifier;
  Key get alarmTabKey;
  
  set selectedDay(DateTime? value);
  set focusedDay(DateTime value);
  set lastOperationTime(DateTime? value);
  void setMedicationMemos(List<MedicationMemo> memos);
  void setAddedMedications(List<Map<String, dynamic>> medications);
  void setMedicines(List<MedicineData> medicinesList);
  void setMedicationData(Map<String, Map<String, MedicationInfo>> data);
  void setWeekdayMedicationStatus(Map<String, Map<String, bool>> status);
  void setWeekdayMedicationDoseStatus(Map<String, Map<String, Map<int, bool>>> status);
  void setMedicationMemoStatus(Map<String, bool> status);
  void setDayColors(Map<String, Color> colors);
  void setAlarmList(List<Map<String, dynamic>> alarms);
  void setAlarmSettings(Map<String, dynamic> settings);
  void setAdherenceRates(Map<String, double> rates);
  void setAlarmTabKey(Key key);
  void setDayColorsNotifierValue(Map<String, Color> value);
  void setMemoControllerText(String text);
  void setMemoTextNotifierValue(String value);
  
  // 抽象メソッド（実装クラスで提供する必要がある）
  Future<void> saveAllData();
  Future<void> saveDayColors();
  Future<void> updateMedicineInputsForSelectedDate();
  Future<void> loadMemoForSelectedDate();
  Future<void> calculateAdherenceStats();
  void updateCalendarMarks();
}
