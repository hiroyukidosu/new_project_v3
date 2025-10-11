import 'package:flutter/foundation.dart';
import '../models/medication_memo.dart';
import '../repositories/medication_repository.dart';
import '../utils/logger.dart';

/// メディケーションビューモデル
class MedicationViewModel extends ChangeNotifier {
  final MedicationRepository _repository;
  
  // 状態管理
  List<MedicationMemo> _memos = [];
  Map<String, bool> _memoStatus = {};
  Map<String, bool> _weekdayStatus = {};
  List<Map<String, dynamic>> _addedMedications = [];
  Map<String, dynamic> _alarmData = {};
  Map<String, dynamic> _calendarMarks = {};
  Map<String, dynamic> _userPreferences = {};
  Map<String, dynamic> _medicationData = {};
  Map<String, String> _dayColors = {};
  Map<String, dynamic> _statistics = {};
  Map<String, dynamic> _appSettings = {};
  Map<String, dynamic> _doseStatus = {};
  
  // UI状態
  bool _isLoading = false;
  String? _error;
  DateTime? _selectedDay;
  DateTime? _focusedDay;
  Set<DateTime> _selectedDates = {};
  
  MedicationViewModel(this._repository);
  
  // Getters
  List<MedicationMemo> get memos => _memos;
  Map<String, bool> get memoStatus => _memoStatus;
  Map<String, bool> get weekdayStatus => _weekdayStatus;
  List<Map<String, dynamic>> get addedMedications => _addedMedications;
  Map<String, dynamic> get alarmData => _alarmData;
  Map<String, dynamic> get calendarMarks => _calendarMarks;
  Map<String, dynamic> get userPreferences => _userPreferences;
  Map<String, dynamic> get medicationData => _medicationData;
  Map<String, String> get dayColors => _dayColors;
  Map<String, dynamic> get statistics => _statistics;
  Map<String, dynamic> get appSettings => _appSettings;
  Map<String, dynamic> get doseStatus => _doseStatus;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get selectedDay => _selectedDay;
  DateTime? get focusedDay => _focusedDay;
  Set<DateTime> get selectedDates => _selectedDates;
  
  /// 初期データの読み込み
  Future<void> loadInitialData() async {
    _setLoading(true);
    _clearError();
    
    try {
      await Future.wait([
        _loadMemos(),
        _loadMemoStatus(),
        _loadWeekdayStatus(),
        _loadAddedMedications(),
        _loadAlarmData(),
        _loadCalendarMarks(),
        _loadUserPreferences(),
        _loadMedicationData(),
        _loadDayColors(),
        _loadStatistics(),
        _loadAppSettings(),
        _loadDoseStatus(),
      ]);
      
      Logger.info('初期データ読み込み完了');
    } catch (e) {
      _setError('初期データ読み込みエラー: $e');
      Logger.error('初期データ読み込みエラー', e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// メモの読み込み
  Future<void> _loadMemos() async {
    try {
      _memos = await _repository.getMemos();
      notifyListeners();
    } catch (e) {
      Logger.error('メモ読み込みエラー', e);
      rethrow;
    }
  }
  
  /// メモステータスの読み込み
  Future<void> _loadMemoStatus() async {
    try {
      _memoStatus = await _repository.getMemoStatus();
    } catch (e) {
      Logger.error('メモステータス読み込みエラー', e);
      rethrow;
    }
  }
  
  /// 曜日ステータスの読み込み
  Future<void> _loadWeekdayStatus() async {
    try {
      _weekdayStatus = await _repository.getWeekdayMedicationStatus();
    } catch (e) {
      Logger.error('曜日ステータス読み込みエラー', e);
      rethrow;
    }
  }
  
  /// 追加メディケーションの読み込み
  Future<void> _loadAddedMedications() async {
    try {
      _addedMedications = await _repository.getAddedMedications();
    } catch (e) {
      Logger.error('追加メディケーション読み込みエラー', e);
      rethrow;
    }
  }
  
  /// アラームデータの読み込み
  Future<void> _loadAlarmData() async {
    try {
      _alarmData = await _repository.getAlarmData();
    } catch (e) {
      Logger.error('アラームデータ読み込みエラー', e);
      rethrow;
    }
  }
  
  /// カレンダーマークの読み込み
  Future<void> _loadCalendarMarks() async {
    try {
      _calendarMarks = await _repository.getCalendarMarks();
    } catch (e) {
      Logger.error('カレンダーマーク読み込みエラー', e);
      rethrow;
    }
  }
  
  /// ユーザー設定の読み込み
  Future<void> _loadUserPreferences() async {
    try {
      _userPreferences = await _repository.getUserPreferences();
    } catch (e) {
      Logger.error('ユーザー設定読み込みエラー', e);
      rethrow;
    }
  }
  
  /// メディケーションデータの読み込み
  Future<void> _loadMedicationData() async {
    try {
      _medicationData = await _repository.getMedicationData();
    } catch (e) {
      Logger.error('メディケーションデータ読み込みエラー', e);
      rethrow;
    }
  }
  
  /// 日付色の読み込み
  Future<void> _loadDayColors() async {
    try {
      _dayColors = await _repository.getDayColors();
    } catch (e) {
      Logger.error('日付色読み込みエラー', e);
      rethrow;
    }
  }
  
  /// 統計データの読み込み
  Future<void> _loadStatistics() async {
    try {
      _statistics = await _repository.getStatistics();
    } catch (e) {
      Logger.error('統計データ読み込みエラー', e);
      rethrow;
    }
  }
  
  /// アプリ設定の読み込み
  Future<void> _loadAppSettings() async {
    try {
      _appSettings = await _repository.getAppSettings();
    } catch (e) {
      Logger.error('アプリ設定読み込みエラー', e);
      rethrow;
    }
  }
  
  /// 服用ステータスの読み込み
  Future<void> _loadDoseStatus() async {
    try {
      _doseStatus = await _repository.getMedicationDoseStatus();
    } catch (e) {
      Logger.error('服用ステータス読み込みエラー', e);
      rethrow;
    }
  }
  
  /// メモの追加
  Future<void> addMemo(MedicationMemo memo) async {
    try {
      _setLoading(true);
      await _repository.saveMemo(memo);
      _memos.add(memo);
      notifyListeners();
      Logger.info('メモ追加完了: ${memo.id}');
    } catch (e) {
      _setError('メモ追加エラー: $e');
      Logger.error('メモ追加エラー', e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// メモの更新
  Future<void> updateMemo(MedicationMemo memo) async {
    try {
      _setLoading(true);
      await _repository.saveMemo(memo);
      final index = _memos.indexWhere((m) => m.id == memo.id);
      if (index != -1) {
        _memos[index] = memo;
        notifyListeners();
      }
      Logger.info('メモ更新完了: ${memo.id}');
    } catch (e) {
      _setError('メモ更新エラー: $e');
      Logger.error('メモ更新エラー', e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// メモの削除
  Future<void> deleteMemo(String id) async {
    try {
      _setLoading(true);
      await _repository.deleteMemo(id);
      _memos.removeWhere((memo) => memo.id == id);
      notifyListeners();
      Logger.info('メモ削除完了: $id');
    } catch (e) {
      _setError('メモ削除エラー: $e');
      Logger.error('メモ削除エラー', e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// メモステータスの更新
  Future<void> updateMemoStatus(Map<String, bool> status) async {
    try {
      await _repository.saveMemoStatus(status);
      _memoStatus = status;
      notifyListeners();
      Logger.info('メモステータス更新完了');
    } catch (e) {
      _setError('メモステータス更新エラー: $e');
      Logger.error('メモステータス更新エラー', e);
    }
  }
  
  /// 曜日ステータスの更新
  Future<void> updateWeekdayStatus(Map<String, bool> status) async {
    try {
      await _repository.saveWeekdayMedicationStatus(status);
      _weekdayStatus = status;
      notifyListeners();
      Logger.info('曜日ステータス更新完了');
    } catch (e) {
      _setError('曜日ステータス更新エラー: $e');
      Logger.error('曜日ステータス更新エラー', e);
    }
  }
  
  /// 追加メディケーションの更新
  Future<void> updateAddedMedications(List<Map<String, dynamic>> medications) async {
    try {
      await _repository.saveAddedMedications(medications);
      _addedMedications = medications;
      notifyListeners();
      Logger.info('追加メディケーション更新完了: ${medications.length}件');
    } catch (e) {
      _setError('追加メディケーション更新エラー: $e');
      Logger.error('追加メディケーション更新エラー', e);
    }
  }
  
  /// アラームデータの更新
  Future<void> updateAlarmData(Map<String, dynamic> alarmData) async {
    try {
      await _repository.saveAlarmData(alarmData);
      _alarmData = alarmData;
      notifyListeners();
      Logger.info('アラームデータ更新完了');
    } catch (e) {
      _setError('アラームデータ更新エラー: $e');
      Logger.error('アラームデータ更新エラー', e);
    }
  }
  
  /// カレンダーマークの更新
  Future<void> updateCalendarMarks(Map<String, dynamic> marks) async {
    try {
      await _repository.saveCalendarMarks(marks);
      _calendarMarks = marks;
      notifyListeners();
      Logger.info('カレンダーマーク更新完了');
    } catch (e) {
      _setError('カレンダーマーク更新エラー: $e');
      Logger.error('カレンダーマーク更新エラー', e);
    }
  }
  
  /// ユーザー設定の更新
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _repository.saveUserPreferences(preferences);
      _userPreferences = preferences;
      notifyListeners();
      Logger.info('ユーザー設定更新完了');
    } catch (e) {
      _setError('ユーザー設定更新エラー: $e');
      Logger.error('ユーザー設定更新エラー', e);
    }
  }
  
  /// メディケーションデータの更新
  Future<void> updateMedicationData(Map<String, dynamic> data) async {
    try {
      await _repository.saveMedicationData(data);
      _medicationData = data;
      notifyListeners();
      Logger.info('メディケーションデータ更新完了');
    } catch (e) {
      _setError('メディケーションデータ更新エラー: $e');
      Logger.error('メディケーションデータ更新エラー', e);
    }
  }
  
  /// 日付色の更新
  Future<void> updateDayColors(Map<String, String> colors) async {
    try {
      await _repository.saveDayColors(colors);
      _dayColors = colors;
      notifyListeners();
      Logger.info('日付色更新完了');
    } catch (e) {
      _setError('日付色更新エラー: $e');
      Logger.error('日付色更新エラー', e);
    }
  }
  
  /// 統計データの更新
  Future<void> updateStatistics(Map<String, dynamic> statistics) async {
    try {
      await _repository.saveStatistics(statistics);
      _statistics = statistics;
      notifyListeners();
      Logger.info('統計データ更新完了');
    } catch (e) {
      _setError('統計データ更新エラー: $e');
      Logger.error('統計データ更新エラー', e);
    }
  }
  
  /// アプリ設定の更新
  Future<void> updateAppSettings(Map<String, dynamic> settings) async {
    try {
      await _repository.saveAppSettings(settings);
      _appSettings = settings;
      notifyListeners();
      Logger.info('アプリ設定更新完了');
    } catch (e) {
      _setError('アプリ設定更新エラー: $e');
      Logger.error('アプリ設定更新エラー', e);
    }
  }
  
  /// 服用ステータスの更新
  Future<void> updateDoseStatus(Map<String, dynamic> status) async {
    try {
      await _repository.saveMedicationDoseStatus(status);
      _doseStatus = status;
      notifyListeners();
      Logger.info('服用ステータス更新完了');
    } catch (e) {
      _setError('服用ステータス更新エラー: $e');
      Logger.error('服用ステータス更新エラー', e);
    }
  }
  
  /// 日付選択の更新
  void updateSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    _selectedDates.add(_normalizeDate(selectedDay));
    notifyListeners();
    Logger.debug('日付選択更新: $selectedDay');
  }
  
  /// 日付の正規化
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// バックアップの作成
  Future<Map<String, dynamic>> createBackup() async {
    try {
      final backup = await _repository.createBackup();
      Logger.info('バックアップ作成完了');
      return backup;
    } catch (e) {
      _setError('バックアップ作成エラー: $e');
      Logger.error('バックアップ作成エラー', e);
      rethrow;
    }
  }
  
  /// ローディング状態の設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// エラーの設定
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  /// エラーのクリア
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// リソースの解放
  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
