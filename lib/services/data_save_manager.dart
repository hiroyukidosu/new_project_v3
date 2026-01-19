import 'dart:async';
import '../utils/logger.dart';

// データ保存管理サービス（最適化版）
class DataSaveManager {
  // ダーティフラグ（変更されたデータの追跡）
  static final Map<String, bool> _dirtyFlags = {};
  static Timer? _saveTimer;
  static bool _isSaving = false;
  
  // デバウンス設定
  static const Duration _debounceDelay = Duration(seconds: 2);
  static const Duration _maxDebounceDelay = Duration(seconds: 10);
  
  // 保存キュー
  static final List<SaveTask> _saveQueue = [];
  
  // データが変更されたことをマーク
  static void markDirty(String dataType) {
    _dirtyFlags[dataType] = true;
    Logger.debug('データ変更マーク: $dataType');
    
    // デバウンスタイマーを開始
    _startDebounceTimer();
  }
  
  // デバウンスタイマーの開始
  static void _startDebounceTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_debounceDelay, () {
      _saveDirtyDataOnly();
    });
    
    Logger.debug('デバウンスタイマー開始: ${_debounceDelay.inSeconds}秒');
  }
  
  // 変更されたデータのみ保存
  static Future<void> _saveDirtyDataOnly() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    if (_dirtyFlags.isEmpty) {
      Logger.debug('変更されたデータがありません。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final tasks = <Future>[];
      final saveStartTime = DateTime.now();
      
      // 変更されたデータタイプに応じて保存タスクを追加
      for (final entry in _dirtyFlags.entries) {
        if (entry.value) {
          final task = _createSaveTask(entry.key);
          if (task != null) {
            tasks.add(task);
          }
        }
      }
      
      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
        final saveDuration = DateTime.now().difference(saveStartTime);
        Logger.info('差分保存完了: ${tasks.length}件 (${saveDuration.inMilliseconds}ms)');
      }
      
      _dirtyFlags.clear();
    } catch (e) {
      Logger.error('差分保存エラー', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  // 保存タスクの作成
  static Future<void>? _createSaveTask(String dataType) {
    switch (dataType) {
      case 'memos':
        return _saveMemos();
      case 'medications':
        return _saveMedications();
      case 'alarms':
        return _saveAlarms();
      case 'calendar':
        return _saveCalendar();
      case 'settings':
        return _saveSettings();
      case 'statistics':
        return _saveStatistics();
      default:
        Logger.warning('未知のデータタイプ: $dataType');
        return null;
    }
  }
  
  // 個別保存メソッド（プレースホルダー）
  static Future<void> _saveMemos() async {
    Logger.debug('メモデータ保存');
    // 実装は既存のロジックを移植
  }
  
  static Future<void> _saveMedications() async {
    Logger.debug('服用薬データ保存');
    // 実装は既存のロジックを移植
  }
  
  static Future<void> _saveAlarms() async {
    Logger.debug('アラームデータ保存');
    // 実装は既存のロジックを移植
  }
  
  static Future<void> _saveCalendar() async {
    Logger.debug('カレンダーデータ保存');
    // 実装は既存のロジックを移植
  }
  
  static Future<void> _saveSettings() async {
    Logger.debug('設定データ保存');
    // 実装は既存のロジックを移植
  }
  
  static Future<void> _saveStatistics() async {
    Logger.debug('統計データ保存');
    // 実装は既存のロジックを移植
  }
  
  // 即座に保存（緊急時）
  static Future<void> saveImmediately(String dataType) async {
    Logger.info('即座に保存: $dataType');
    _dirtyFlags[dataType] = true;
    await _saveDirtyDataOnly();
  }
  
  // 全データの強制保存
  static Future<void> saveAllData() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final saveStartTime = DateTime.now();
      
      // 全データタイプをマーク
      _dirtyFlags.addAll({
        'memos': true,
        'medications': true,
        'alarms': true,
        'calendar': true,
        'settings': true,
        'statistics': true,
      });
      
      await _saveDirtyDataOnly();
      
      final saveDuration = DateTime.now().difference(saveStartTime);
      Logger.info('全データ保存完了: ${saveDuration.inMilliseconds}ms');
    } catch (e) {
      Logger.error('全データ保存エラー', e);
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  // 保存キューの管理
  static void addToSaveQueue(SaveTask task) {
    _saveQueue.add(task);
    Logger.debug('保存キューに追加: ${task.dataType}');
  }
  
  static Future<void> processSaveQueue() async {
    if (_saveQueue.isEmpty) return;
    
    Logger.info('保存キューを処理: ${_saveQueue.length}件');
    
    final tasks = _saveQueue.map((task) => task.execute()).toList();
    await Future.wait(tasks);
    
    _saveQueue.clear();
    Logger.info('保存キュー処理完了');
  }
  
  // 保存状態の確認
  static bool get isSaving => _isSaving;
  static bool get hasDirtyData => _dirtyFlags.isNotEmpty;
  static int get dirtyDataCount => _dirtyFlags.length;
  static int get queueSize => _saveQueue.length;
  
  // ダーティフラグの取得
  static Map<String, bool> get dirtyFlags => Map.unmodifiable(_dirtyFlags);
  
  // 特定のデータタイプがダーティかチェック
  static bool isDirty(String dataType) => _dirtyFlags[dataType] ?? false;
  
  // ダーティフラグのクリア
  static void clearDirtyFlags() {
    _dirtyFlags.clear();
    Logger.debug('ダーティフラグをクリア');
  }
  
  // 保存統計の取得
  static SaveStatistics getSaveStatistics() {
    return SaveStatistics(
      dirtyDataCount: _dirtyFlags.length,
      queueSize: _saveQueue.length,
      isSaving: _isSaving,
      lastSaveTime: DateTime.now(),
    );
  }
  
  // リソースの解放
  static void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _dirtyFlags.clear();
    _saveQueue.clear();
    _isSaving = false;
    Logger.info('DataSaveManagerリソース解放完了');
  }
}

// 保存タスククラス
class SaveTask {
  final String dataType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  
  SaveTask({
    required this.dataType,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Future<void> execute() async {
    Logger.debug('保存タスク実行: $dataType');
    // 実装は既存のロジックを移植
  }
}

// 保存統計クラス
class SaveStatistics {
  final int dirtyDataCount;
  final int queueSize;
  final bool isSaving;
  final DateTime lastSaveTime;
  
  const SaveStatistics({
    required this.dirtyDataCount,
    required this.queueSize,
    required this.isSaving,
    required this.lastSaveTime,
  });
  
  @override
  String toString() {
    return 'SaveStatistics(dirty: $dirtyDataCount, queue: $queueSize, saving: $isSaving)';
  }
}
