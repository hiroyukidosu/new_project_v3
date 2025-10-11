import 'package:flutter/material.dart';
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../utils/logger.dart';

// 状態管理の改善サービス
class StateManagementService extends ChangeNotifier {
  // 服用メモの状態
  final Map<String, MedicationMemo> _medicationMemos = {};
  final Map<String, bool> _medicationMemoStatus = {};
  
  // 薬データの状態
  final Map<String, MedicineData> _medicineData = {};
  final Map<String, bool> _medicineStatus = {};
  
  // 選択された日付
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDates = {};
  
  // カレンダーの状態
  DateTime _focusedDay = DateTime.now();
  
  // ローディング状態
  bool _isLoading = false;
  
  // エラー状態
  String? _errorMessage;
  
  // ゲッター
  Map<String, MedicationMemo> get medicationMemos => Map.unmodifiable(_medicationMemos);
  Map<String, bool> get medicationMemoStatus => Map.unmodifiable(_medicationMemoStatus);
  Map<String, MedicineData> get medicineData => Map.unmodifiable(_medicineData);
  Map<String, bool> get medicineStatus => Map.unmodifiable(_medicineStatus);
  DateTime? get selectedDay => _selectedDay;
  Set<DateTime> get selectedDates => Set.unmodifiable(_selectedDates);
  DateTime get focusedDay => _focusedDay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // 服用メモの追加
  void addMedicationMemo(MedicationMemo memo) {
    _medicationMemos[memo.id] = memo;
    _medicationMemoStatus[memo.id] = false;
    notifyListeners();
    Logger.info('服用メモ追加: ${memo.name}');
  }
  
  // 服用メモの更新
  void updateMedicationMemo(MedicationMemo memo) {
    _medicationMemos[memo.id] = memo;
    notifyListeners();
    Logger.info('服用メモ更新: ${memo.name}');
  }
  
  // 服用メモの削除
  void removeMedicationMemo(String id) {
    _medicationMemos.remove(id);
    _medicationMemoStatus.remove(id);
    notifyListeners();
    Logger.info('服用メモ削除: $id');
  }
  
  // 服用メモの状態切り替え
  void toggleMedicationMemoStatus(String id) {
    _medicationMemoStatus[id] = !(_medicationMemoStatus[id] ?? false);
    notifyListeners();
    Logger.debug('服用メモ状態切り替え: $id -> ${_medicationMemoStatus[id]}');
  }
  
  // 薬データの追加
  void addMedicineData(MedicineData medicine) {
    _medicineData[medicine.id] = medicine;
    _medicineStatus[medicine.id] = false;
    notifyListeners();
    Logger.info('薬データ追加: ${medicine.name}');
  }
  
  // 薬データの更新
  void updateMedicineData(MedicineData medicine) {
    _medicineData[medicine.id] = medicine;
    notifyListeners();
    Logger.info('薬データ更新: ${medicine.name}');
  }
  
  // 薬データの削除
  void removeMedicineData(String id) {
    _medicineData.remove(id);
    _medicineStatus.remove(id);
    notifyListeners();
    Logger.info('薬データ削除: $id');
  }
  
  // 薬データの状態切り替え
  void toggleMedicineStatus(String id) {
    _medicineStatus[id] = !(_medicineStatus[id] ?? false);
    notifyListeners();
    Logger.debug('薬データ状態切り替え: $id -> ${_medicineStatus[id]}');
  }
  
  // 日付の選択
  void selectDay(DateTime day) {
    _selectedDay = day;
    _selectedDates.add(day);
    notifyListeners();
    Logger.debug('日付選択: $day');
  }
  
  // 日付の選択解除
  void deselectDay(DateTime day) {
    _selectedDates.remove(day);
    if (_selectedDay == day) {
      _selectedDay = _selectedDates.isNotEmpty ? _selectedDates.first : null;
    }
    notifyListeners();
    Logger.debug('日付選択解除: $day');
  }
  
  // カレンダーのフォーカス変更
  void changeFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
    Logger.debug('カレンダーフォーカス変更: $day');
  }
  
  // ローディング状態の設定
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      Logger.debug('ローディング状態変更: $loading');
    }
  }
  
  // エラーメッセージの設定
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
    if (error != null) {
      Logger.error('エラー設定: $error');
    }
  }
  
  // エラーのクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
    Logger.debug('エラークリア');
  }
  
  // 特定の日付の服用メモを取得
  List<MedicationMemo> getMedicationMemosForDay(DateTime day) {
    return _medicationMemos.values.where((memo) {
      return memo.selectedDays.contains(day.weekday - 1);
    }).toList();
  }
  
  // 特定の日付の薬データを取得
  List<MedicineData> getMedicineDataForDay(DateTime day) {
    return _medicineData.values.where((medicine) {
      return medicine.selectedDays.contains(day.weekday - 1);
    }).toList();
  }
  
  // 統計データの計算
  Map<String, double> calculateAdherenceStats() {
    final stats = <String, double>{};
    
    for (final memo in _medicationMemos.values) {
      final totalDays = memo.selectedDays.length;
      final completedDays = _medicationMemoStatus[memo.id] == true ? 1 : 0;
      stats[memo.id] = totalDays > 0 ? (completedDays / totalDays) * 100 : 0.0;
    }
    
    return stats;
  }
  
  // 状態のリセット
  void reset() {
    _medicationMemos.clear();
    _medicationMemoStatus.clear();
    _medicineData.clear();
    _medicineStatus.clear();
    _selectedDay = null;
    _selectedDates.clear();
    _focusedDay = DateTime.now();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    Logger.info('状態リセット完了');
  }
  
  // バッチ更新（複数の状態を一度に変更）
  void batchUpdate({
    List<MedicationMemo>? memos,
    List<MedicineData>? medicines,
    DateTime? selectedDay,
    DateTime? focusedDay,
    bool? isLoading,
    String? errorMessage,
  }) {
    bool hasChanges = false;
    
    if (memos != null) {
      for (final memo in memos) {
        _medicationMemos[memo.id] = memo;
      }
      hasChanges = true;
    }
    
    if (medicines != null) {
      for (final medicine in medicines) {
        _medicineData[medicine.id] = medicine;
      }
      hasChanges = true;
    }
    
    if (selectedDay != null && _selectedDay != selectedDay) {
      _selectedDay = selectedDay;
      _selectedDates.add(selectedDay);
      hasChanges = true;
    }
    
    if (focusedDay != null && _focusedDay != focusedDay) {
      _focusedDay = focusedDay;
      hasChanges = true;
    }
    
    if (isLoading != null && _isLoading != isLoading) {
      _isLoading = isLoading;
      hasChanges = true;
    }
    
    if (errorMessage != null && _errorMessage != errorMessage) {
      _errorMessage = errorMessage;
      hasChanges = true;
    }
    
    if (hasChanges) {
      notifyListeners();
      Logger.info('バッチ更新完了');
    }
  }
  
  @override
  void dispose() {
    Logger.info('StateManagementService破棄');
    super.dispose();
  }
}
