// lib/screens/medication_home/controllers/medication_home_controller.dart

import 'package:flutter/material.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';
import '../../../core/result.dart';
import '../../../utils/logger.dart';
import '../repositories/medication_repository.dart';
import '../repositories/alarm_repository.dart';
import '../repositories/calendar_repository.dart';
import '../repositories/preference_repository.dart';
import '../repositories/backup_repository.dart';

/// メイン状態管理Controller
class MedicationHomeController extends ChangeNotifier {
  final MedicationRepository _medicationRepo;
  final AlarmRepository _alarmRepo;
  final CalendarRepository _calendarRepo;
  final PreferenceRepository _preferenceRepo;
  final BackupRepository _backupRepo;

  // 状態変数
  DateTime? _selectedDay;
  List<MedicationMemo> _memos = [];
  Map<String, Color> _dayColors = {};
  Map<String, bool> _medicationMemoStatus = {};
  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  List<Map<String, dynamic>> _addedMedications = [];
  Map<String, Map<String, MedicationInfo>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<Map<String, dynamic>> _alarmList = [];
  bool _isLoading = false;
  String? _error;

  MedicationHomeController({
    required MedicationRepository medicationRepo,
    required AlarmRepository alarmRepo,
    required CalendarRepository calendarRepo,
    required PreferenceRepository preferenceRepo,
    required BackupRepository backupRepo,
  })  : _medicationRepo = medicationRepo,
        _alarmRepo = alarmRepo,
        _calendarRepo = calendarRepo,
        _preferenceRepo = preferenceRepo,
        _backupRepo = backupRepo;

  // ゲッター
  DateTime? get selectedDay => _selectedDay;
  List<MedicationMemo> get memos => _memos;
  Map<String, Color> get dayColors => _dayColors;
  Map<String, bool> get medicationMemoStatus => _medicationMemoStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus =>
      _weekdayMedicationDoseStatus;
  List<Map<String, dynamic>> get addedMedications => _addedMedications;
  Map<String, Map<String, MedicationInfo>> get medicationData =>
      _medicationData;
  Map<String, double> get adherenceRates => _adherenceRates;
  List<Map<String, dynamic>> get alarmList => _alarmList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初期化
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 並列でデータを読み込み
      final results = await Future.wait([
        _medicationRepo.loadMemos(),
        _medicationRepo.loadMemoStatus(),
        _medicationRepo.loadWeekdayDoseStatus(),
        _calendarRepo.loadDayColors(),
        _preferenceRepo.loadAddedMedications(),
        _preferenceRepo.loadAdherenceRates(),
        _alarmRepo.loadAlarms(),
      ]);

      // 結果を処理
      _processLoadResults(results);

      Logger.info('初期化完了');
    } catch (e, stackTrace) {
      Logger.error('初期化エラー', e, stackTrace);
      _error = 'データの読み込みに失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _processLoadResults(List<Result> results) {
    // メモ
    if (results[0].isSuccess) {
      _memos = (results[0] as Success<List<MedicationMemo>>).data;
    }

    // メモステータス
    if (results[1].isSuccess) {
      _medicationMemoStatus =
          (results[1] as Success<Map<String, bool>>).data;
    }

    // 曜日別服用回数ステータス
    if (results[2].isSuccess) {
      _weekdayMedicationDoseStatus = (results[2]
          as Success<Map<String, Map<String, Map<int, bool>>>>).data;
    }

    // カレンダー日付色
    if (results[3].isSuccess) {
      _dayColors = (results[3] as Success<Map<String, Color>>).data;
    }

    // 追加薬品リスト
    if (results[4].isSuccess) {
      _addedMedications =
          (results[4] as Success<List<Map<String, dynamic>>>).data;
    }

    // 遵守率
    if (results[5].isSuccess) {
      _adherenceRates = (results[5] as Success<Map<String, double>>).data;
    }

    // アラーム
    if (results[6].isSuccess) {
      _alarmList = (results[6] as Success<List<Map<String, dynamic>>>).data;
    }
  }

  /// 日付選択
  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  /// メモ一覧を更新
  void updateMemos(List<MedicationMemo> memos) {
    _memos = memos;
    notifyListeners();
  }

  /// メモを追加
  void addMemo(MedicationMemo memo) {
    _memos.add(memo);
    notifyListeners();
  }

  /// メモを削除
  void removeMemo(String memoId) {
    _memos.removeWhere((m) => m.id == memoId);
    notifyListeners();
  }

  /// メモを更新
  void updateMemo(MedicationMemo memo) {
    final index = _memos.indexWhere((m) => m.id == memo.id);
    if (index >= 0) {
      _memos[index] = memo;
      notifyListeners();
    }
  }

  /// カレンダー日付色を更新
  void updateDayColor(String dateKey, Color color) {
    _dayColors[dateKey] = color;
    notifyListeners();
  }

  /// メモステータスを更新
  void updateMemoStatus(String key, bool value) {
    _medicationMemoStatus[key] = value;
    notifyListeners();
  }

  /// 全データを保存
  Future<void> saveAllData() async {
    try {
      await Future.wait([
        _calendarRepo.saveDayColors(_dayColors),
        _preferenceRepo.saveAdherenceRates(_adherenceRates),
        _alarmRepo.saveAlarms(_alarmList),
        _preferenceRepo.saveAddedMedications(_addedMedications),
        _medicationRepo.saveMemoStatus(_medicationMemoStatus),
        _medicationRepo.saveWeekdayDoseStatus(_weekdayMedicationDoseStatus),
      ]);

      Logger.info('全データ保存完了');
    } catch (e, stackTrace) {
      Logger.error('全データ保存エラー', e, stackTrace);
      _error = 'データの保存に失敗しました: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    Logger.debug('MedicationHomeController dispose');
    super.dispose();
  }
}

