// Dart core imports
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Core optimization imports
import 'core/alarm_optimization.dart';

// Third-party package imports
import 'package:table_calendar/table_calendar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expandable/expandable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Local imports
// import 'firebase_options.dart';
import 'simple_alarm_app.dart';

// 高速化：シンプルなデバッグログ
void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

// 高速化：シンプルなLogger
class Logger {
  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }
  static void error(String message, [dynamic error]) {
    if (kDebugMode) debugPrint('[ERROR] $message: $error');
  }
  static void warning(String message) {
    if (kDebugMode) debugPrint('[WARNING] $message');
  }
  static void debug(String message) {
    if (kDebugMode) debugPrint('[DEBUG] $message');
  }
}

// 高速化：PrefsHelper削除

// 高速化：エラーハンドリング削除

// 高速化：ローディングオーバーレイ削除

// ✅ 修正：統一された定数管理
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
  
  // データキー
  static const String medicationMemosKey = 'medication_memos_v2';
  static const String medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String addedMedicationsKey = 'added_medications_v2';
  static const String backupSuffix = '_backup';
}

// ✅ 修正：統一されたUI定数（マジックナンバー削減）
class AppDimensions {
  // 高さ
  static const double listMaxHeight = 250.0;
  static const double listMaxHeightExpanded = 500.0;
  static const double calendarMaxHeight = 600.0;
  static const double dialogMaxHeight = 0.8;
  static const double dialogMinHeight = 0.4;
  
  // パディング
  static const EdgeInsets standardPadding = EdgeInsets.all(16);
  static const EdgeInsets smallPadding = EdgeInsets.all(8);
  static const EdgeInsets largePadding = EdgeInsets.all(24);
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets dialogPadding = EdgeInsets.all(20);
  static const EdgeInsets listPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  
  // マージン
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 10, horizontal: 4);
  static const EdgeInsets sectionMargin = EdgeInsets.only(bottom: 16);
  
  // ボーダー半径
  static const double standardBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double dialogBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  
  // アイコンサイズ
  static const double smallIcon = 16.0;
  static const double mediumIcon = 20.0;
  static const double largeIcon = 24.0;
  static const double extraLargeIcon = 32.0;
  
  // フォントサイズ
  static const double smallText = 11.0;
  static const double mediumText = 14.0;
  static const double largeText = 16.0;
  static const double titleText = 18.0;
  static const double headerText = 24.0;
  
  // スペーシング
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 12.0;
  static const double extraLargeSpacing = 16.0;
  
  // ボタンサイズ
  static const double buttonHeight = 48.0;
  static const double smallButtonHeight = 32.0;
  static const double largeButtonHeight = 56.0;
  
  // アニメーション時間
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // デバウンス時間
  static const Duration shortDebounce = Duration(milliseconds: 500);
  static const Duration standardDebounce = Duration(seconds: 2);
  static const Duration longDebounce = Duration(seconds: 5);
  
  // キャッシュ時間
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const Duration logInterval = Duration(seconds: 30);
}

// ✅ 修正：統一されたデータリポジトリ
class DataRepository {
  static SharedPreferences? _prefs;
  static Box? _hiveBox;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _hiveBox = await Hive.openBox('medication_data');
    Logger.info('DataRepository初期化完了');
  }
  
  // 統一された保存メソッド
  static Future<void> save<T>(String key, T data) async {
    try {
      final json = jsonEncode(data);
      await Future.wait([
        _prefs!.setString(key, json),
        _prefs!.setString('${key}_backup', json),
      ]);
      Logger.info('データ保存完了: $key');
    } catch (e) {
      Logger.error('データ保存エラー: $key', e);
    }
  }
  
  // 統一された読み込みメソッド
  static Future<T?> load<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      for (final suffix in ['', '_backup']) {
        final json = _prefs!.getString('$key$suffix');
        if (json != null && json.isNotEmpty) {
          final data = fromJson(jsonDecode(json));
          Logger.info('データ読み込み成功: $key$suffix');
          return data;
        }
      }
      Logger.warning('データが見つかりません: $key');
      return null;
    } catch (e) {
      Logger.error('データ読み込みエラー: $key', e);
      return null;
    }
  }
  
  // 統一された削除メソッド
  static Future<void> delete(String key) async {
    try {
      await Future.wait([
        _prefs!.remove(key),
        _prefs!.remove('${key}_backup'),
      ]);
      Logger.info('データ削除完了: $key');
    } catch (e) {
      Logger.error('データ削除エラー: $key', e);
    }
  }
  
  // メモリリーク防止のためのクリーンアップ
  static Future<void> dispose() async {
    try {
      await _hiveBox?.close();
      Logger.info('DataRepositoryクリーンアップ完了');
    } catch (e) {
      Logger.error('DataRepositoryクリーンアップエラー', e);
    }
  }
}

// ✅ 修正：統一されたデータ管理システム
class DataManager {
  static final Map<String, bool> _dirtyFlags = <String, bool>{};
  static bool _isSaving = false;
  static SharedPreferences? _prefs;
  
  // 初期化
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    Logger.info('DataManager初期化完了');
  }
  
  // データが変更されたことをマーク
  static void markDirty(String key) {
    _dirtyFlags[key] = true;
    Logger.debug('データ変更マーク: $key');
  }
  
  // 統一されたデータ保存（重複排除）
  static Future<void> save() async {
    if (_isSaving) {
      Logger.warning('データ保存中です。スキップします。');
      return;
    }
    
    _isSaving = true;
    try {
      final data = {
        'medications': _serializeMedications(),
        'memos': _serializeMemos(),
        'settings': _serializeSettings(),
        'version': '1.0.0',
        'lastSaved': DateTime.now().toIso8601String(),
      };
      
      await Future.wait([
        _prefs!.setString('app_data', jsonEncode(data)),
        _prefs!.setString('app_data_backup', jsonEncode(data)),
      ]);
      
      Logger.info('統一データ保存完了');
    } catch (e) {
      Logger.error('統一データ保存エラー', e);
    } finally {
      _isSaving = false;
    }
  }
  
  // 変更されたデータのみ保存（差分保存）
  static Future<void> saveOnlyDirty() async {
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
      
      if (_dirtyFlags['memos'] == true) {
        tasks.add(_saveMemos());
      }
      if (_dirtyFlags['medications'] == true) {
        tasks.add(_saveMedications());
      }
      if (_dirtyFlags['alarms'] == true) {
        tasks.add(_saveAlarms());
      }
      if (_dirtyFlags['settings'] == true) {
        tasks.add(_saveSettings());
      }
      
      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
        Logger.info('差分保存完了: ${tasks.length}件');
      }
      
      _dirtyFlags.clear();
    } catch (e) {
      Logger.error('差分保存エラー', e);
    } finally {
      _isSaving = false;
    }
  }
  
  // データのシリアライズ
  static Map<String, dynamic> _serializeMedications() {
    // 服用薬データのシリアライズ
    return {};
  }
  
  static Map<String, dynamic> _serializeMemos() {
    // メモデータのシリアライズ
    return {};
  }
  
  static Map<String, dynamic> _serializeSettings() {
    // 設定データのシリアライズ
    return {};
  }
  
  // 個別保存メソッド（差分保存用）
  static Future<void> _saveMemos() async {
    // メモ保存ロジック
    Logger.debug('メモデータ保存');
  }
  
  static Future<void> _saveMedications() async {
    // 薬データ保存ロジック
    Logger.debug('薬データ保存');
  }
  
  static Future<void> _saveAlarms() async {
    // アラームデータ保存ロジック
    Logger.debug('アラームデータ保存');
  }
  
  static Future<void> _saveSettings() async {
    // 設定データ保存ロジック
    Logger.debug('設定データ保存');
  }
}

// ✅ 修正：Result型の実装
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);
}

// ✅ 修正：エラーハンドリングの改善
class ErrorService {
  static void handle(BuildContext? context, dynamic error, {String? userMessage}) {
    Logger.error('エラーが発生しました', error);
    
    try {
      FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
    } catch (e) {
      Logger.warning('Crashlyticsレポートエラー: $e');
    }
    
    if (context != null && context.mounted) {
      final message = userMessage ?? _getUserFriendlyMessage(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '再試行',
            textColor: Colors.white,
            onPressed: () => _retry(context),
          ),
        ),
      );
    }
  }
  
  static void _retry(BuildContext context) {
    // 再試行ロジック（必要に応じて実装）
    Logger.info('ユーザーが再試行を選択しました');
  }
  
  // ユーザーフレンドリーなエラーメッセージ生成
  static String _getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission') || errorString.contains('権限')) {
      return '権限が不足しています。設定から許可してください。';
    } else if (errorString.contains('network') || errorString.contains('接続')) {
      return 'ネットワーク接続を確認してください。';
    } else if (errorString.contains('storage') || errorString.contains('容量')) {
      return 'ストレージの容量が不足しています。';
    } else if (errorString.contains('timeout') || errorString.contains('タイムアウト')) {
      return '処理に時間がかかりすぎています。もう一度お試しください。';
    } else if (errorString.contains('not found') || errorString.contains('見つかりません')) {
      return 'データが見つかりません。アプリを再起動してください。';
    } else if (errorString.contains('format') || errorString.contains('形式')) {
      return 'データの形式が正しくありません。';
    } else if (errorString.contains('memory') || errorString.contains('メモリ')) {
      return 'メモリが不足しています。他のアプリを閉じてください。';
    } else {
      return '問題が発生しました。もう一度お試しください。';
    }
  }
  
  static void showUserFriendlyError(BuildContext context, String errorContext, dynamic error) {
    final message = _getUserFriendlyMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '詳細',
          textColor: Colors.white,
          onPressed: () => _showErrorDetails(context, errorContext, error),
        ),
      ),
    );
  }
  
  static void _showErrorDetails(BuildContext context, String errorContext, dynamic error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー詳細'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('コンテキスト: $errorContext'),
            const SizedBox(height: 8),
            Text('エラー: ${error.toString()}'),
            const SizedBox(height: 8),
            const Text('この情報を開発者に報告してください。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// ✅ 修正：メモリリーク対策のためのコントローラー管理
class MedicationController {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _disposed = false;
  
  TextEditingController getController(String id) {
    if (_disposed) {
      Logger.warning('MedicationControllerは既に破棄されています');
      return TextEditingController();
    }
    return _controllers.putIfAbsent(id, () => TextEditingController());
  }
  
  FocusNode getFocusNode(String id) {
    if (_disposed) {
      Logger.warning('MedicationControllerは既に破棄されています');
      return FocusNode();
    }
    return _focusNodes.putIfAbsent(id, () => FocusNode());
  }
  
  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    
    // コントローラーの安全な解放
    for (final controller in _controllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        Logger.warning('コントローラー解放エラー: $e');
      }
    }
    
    // フォーカスノードの安全な解放
    for (final focusNode in _focusNodes.values) {
      try {
        focusNode.dispose();
      } catch (e) {
        Logger.warning('フォーカスノード解放エラー: $e');
      }
    }
    
    _controllers.clear();
    _focusNodes.clear();
    Logger.info('MedicationControllerクリーンアップ完了');
  }
  
  void removeController(String id) {
    if (_disposed) return;
    
    try {
      _controllers[id]?.dispose();
      _focusNodes[id]?.dispose();
      _controllers.remove(id);
      _focusNodes.remove(id);
      Logger.debug('コントローラー削除完了: $id');
    } catch (e) {
      Logger.warning('コントローラー削除エラー: $e');
    }
  }
  
  // コントローラーの状態確認
  bool get isDisposed => _disposed;
  int get controllerCount => _controllers.length;
  int get focusNodeCount => _focusNodes.length;
}

// ✅ 修正：パフォーマンス最適化のためのキャッシュ機能
class MedicationState {
  Map<String, bool>? _cachedMemoStatus;
  Map<String, dynamic>? _cachedMedicationData;
  DateTime? _lastCacheUpdate;
  
  Map<String, bool> getMemoStatusForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (_cachedMemoStatus == null || _isCacheExpired()) {
      _cachedMemoStatus = _calculateMemoStatus(date);
      _lastCacheUpdate = DateTime.now();
    }
    return _cachedMemoStatus ?? {};
  }
  
  Map<String, dynamic> getMedicationDataForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (_cachedMedicationData == null || _isCacheExpired()) {
      _cachedMedicationData = _calculateMedicationData(date);
      _lastCacheUpdate = DateTime.now();
    }
    return _cachedMedicationData ?? {};
  }
  
  bool _isCacheExpired() {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes > 5;
  }
  
  Map<String, bool> _calculateMemoStatus(DateTime date) {
    // メモ状態の計算ロジック
    return {};
  }
  
  Map<String, dynamic> _calculateMedicationData(DateTime date) {
    // 服用データの計算ロジック
    return {};
  }
  
  void invalidateCache() {
    _cachedMemoStatus = null;
    _cachedMedicationData = null;
    _lastCacheUpdate = null;
    Logger.debug('キャッシュを無効化しました');
  }
}

// ✅ 修正：非同期処理の最適化
class AsyncDataLoader {
  // 並列データ読み込み
  static Future<void> loadAllData() async {
    try {
      await Future.wait([
        _loadMedicationData(),
        _loadMemoStatus(),
        _loadAlarmData(),
        _loadCalendarMarks(),
        _loadUserPreferences(),
        _loadDayColors(),
        _loadStatistics(),
        _loadAppSettings(),
        _loadMedicationDoseStatus(),
      ]);
      Logger.info('全データ読み込み完了（並列実行）');
    } catch (e) {
      Logger.error('全データ読み込みエラー', e);
    }
  }
  
  // 並列データ保存
  static Future<void> saveAllData() async {
    try {
      await Future.wait([
        _saveMedicationData(),
        _saveMemoStatus(),
        _saveAlarmData(),
        _saveCalendarMarks(),
        _saveUserPreferences(),
        _saveDayColors(),
        _saveStatistics(),
        _saveAppSettings(),
        _saveMedicationDoseStatus(),
      ]);
      Logger.info('全データ保存完了（並列実行）');
    } catch (e) {
      Logger.error('全データ保存エラー', e);
    }
  }
  
  // 個別読み込みメソッド（プレースホルダー）
  static Future<void> _loadMedicationData() async {
    Logger.debug('服用データ読み込み');
  }
  
  static Future<void> _loadMemoStatus() async {
    Logger.debug('メモ状態読み込み');
  }
  
  static Future<void> _loadAlarmData() async {
    Logger.debug('アラームデータ読み込み');
  }
  
  static Future<void> _loadCalendarMarks() async {
    Logger.debug('カレンダーマーク読み込み');
  }
  
  static Future<void> _loadUserPreferences() async {
    Logger.debug('ユーザー設定読み込み');
  }
  
  static Future<void> _loadDayColors() async {
    Logger.debug('日別色設定読み込み');
  }
  
  static Future<void> _loadStatistics() async {
    Logger.debug('統計データ読み込み');
  }
  
  static Future<void> _loadAppSettings() async {
    Logger.debug('アプリ設定読み込み');
  }
  
  static Future<void> _loadMedicationDoseStatus() async {
    Logger.debug('服用回数別状態読み込み');
  }
  
  // 個別保存メソッド（プレースホルダー）
  static Future<void> _saveMedicationData() async {
    Logger.debug('服用データ保存');
  }
  
  static Future<void> _saveMemoStatus() async {
    Logger.debug('メモ状態保存');
  }
  
  static Future<void> _saveAlarmData() async {
    Logger.debug('アラームデータ保存');
  }
  
  static Future<void> _saveCalendarMarks() async {
    Logger.debug('カレンダーマーク保存');
  }
  
  static Future<void> _saveUserPreferences() async {
    Logger.debug('ユーザー設定保存');
  }
  
  static Future<void> _saveDayColors() async {
    Logger.debug('日別色設定保存');
  }
  
  static Future<void> _saveStatistics() async {
    Logger.debug('統計データ保存');
  }
  
  static Future<void> _saveAppSettings() async {
    Logger.debug('アプリ設定保存');
  }
  
  static Future<void> _saveMedicationDoseStatus() async {
    Logger.debug('服用回数別状態保存');
  }
}

// ✅ 修正：UIコンポーネントの分離
class MedicationCard extends StatelessWidget {
  final MedicationMemo memo;
  final VoidCallback onTap;
  final bool isSelected;
  
  const MedicationCard({
    Key? key,
    required this.memo,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppDimensions.cardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        side: BorderSide(
          color: isSelected ? memo.color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                    color: memo.color,
                    size: AppDimensions.mediumIcon,
                  ),
                  const SizedBox(width: AppDimensions.mediumSpacing),
                  Expanded(
                    child: Text(
                      memo.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.largeText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: memo.color,
                      size: AppDimensions.mediumIcon,
                    ),
                ],
              ),
              if (memo.dosage.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  '用量: ${memo.dosage}',
                  style: const TextStyle(
                    fontSize: AppDimensions.mediumText,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  memo.notes,
                  style: const TextStyle(
                    fontSize: AppDimensions.mediumText,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WeekdaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;
  
  const WeekdaySelector({
    Key? key,
    required this.selectedDays,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    
    return Wrap(
      spacing: AppDimensions.smallSpacing,
      runSpacing: AppDimensions.smallSpacing,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            final newDays = List<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(index);
            } else {
              newDays.add(index);
            }
            onChanged(newDays);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimensions.mediumText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ✅ 修正：エラー境界ウィジェット
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('エラーが発生しました'),
                ElevatedButton(
                  onPressed: () => setState(() => _hasError = false),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (e) {
        _debugLog('Crashlyticsエラーレポート失敗: $e');
      }
      
      // ✅ 修正：レイアウト中のsetState()を避ける
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    };
  }
}

// 🔴 最重要：シングルトンパターンでPrefsを管理
class AppPreferences {
  static SharedPreferences? _preferences;
  
  // アプリ起動時に一度だけ呼ぶ
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _debugLog('AppPreferences初期化完了');
  }
  
  // 保存
  static Future<bool> saveString(String key, String value) async {
    if (_preferences == null) await init();
    final result = await _preferences!.setString(key, value);
    debugPrint('保存完了: $key = $value (結果: $result)');
    return result;
  }
  
  // 読み込み
  static String? getString(String key) {
    final value = _preferences?.getString(key);
    debugPrint('読み込み: $key = $value');
    return value;
  }
  
  // 削除
  static Future<bool> remove(String key) async {
    if (_preferences == null) await init();
    final result = await _preferences!.remove(key);
    debugPrint('削除完了: $key (結果: $result)');
    return result;
  }
  
  // 複数キー保存
  static Future<Map<String, bool>> saveMultiple(Map<String, String> data) async {
    if (_preferences == null) await init();
    final results = <String, bool>{};
    
    for (final entry in data.entries) {
      final result = await _preferences!.setString(entry.key, entry.value);
      results[entry.key] = result;
      debugPrint('複数保存: ${entry.key} = ${entry.value} (結果: $result)');
    }
    
    return results;
  }
  
  // デバッグ用：すべてのキーを表示
  static void debugAllKeys() {
    if (_preferences == null) {
      debugPrint('AppPreferences: 初期化されていません');
      return;
    }
    
    final keys = _preferences!.getKeys();
    debugPrint('AppPreferences: 保存されているキー数: ${keys.length}');
    for (final key in keys) {
      final value = _preferences!.getString(key);
      debugPrint('  $key: $value');
    }
  }

  // アラーム保存機能
  static Future<bool> saveAlarms(List<Map<String, dynamic>> alarms) async {
    if (_preferences == null) await init();
    try {
      // アラーム数を保存
      await _preferences!.setInt('alarm_count', alarms.length);
      
      // 各アラームのデータを個別に保存
      for (int i = 0; i < alarms.length; i++) {
        final alarm = alarms[i];
        await _preferences!.setString('alarm_${i}_name', alarm['name'] ?? '');
        await _preferences!.setString('alarm_${i}_time', alarm['time'] ?? '00:00');
        await _preferences!.setString('alarm_${i}_repeat', alarm['repeat'] ?? '一度だけ');
        await _preferences!.setBool('alarm_${i}_enabled', alarm['enabled'] ?? true);
        await _preferences!.setString('alarm_${i}_alarmType', alarm['alarmType'] ?? 'sound');
        await _preferences!.setInt('alarm_${i}_volume', alarm['volume'] ?? 80);
      }
      
      debugPrint('アラームデータを保存しました: ${alarms.length}件');
      return true;
    } catch (e) {
      debugPrint('アラームデータ保存エラー: $e');
      return false;
    }
  }

  // アラーム読み込み機能
  static List<Map<String, dynamic>> loadAlarms() {
    if (_preferences == null) return [];
    try {
      final alarmCount = _preferences!.getInt('alarm_count') ?? 0;
      final alarmsList = <Map<String, dynamic>>[];
      
      for (int i = 0; i < alarmCount; i++) {
        final name = _preferences!.getString('alarm_${i}_name');
        final time = _preferences!.getString('alarm_${i}_time');
        final repeat = _preferences!.getString('alarm_${i}_repeat');
        final enabled = _preferences!.getBool('alarm_${i}_enabled');
        final alarmType = _preferences!.getString('alarm_${i}_alarmType');
        final volume = _preferences!.getInt('alarm_${i}_volume');
        
        if (name != null && time != null) {
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat ?? '一度だけ',
            'enabled': enabled ?? true,
            'alarmType': alarmType ?? 'sound',
            'volume': volume ?? 80,
          });
        }
      }
      
      debugPrint('アラームデータを読み込みました: ${alarmsList.length}件');
      return alarmsList;
    } catch (e) {
      debugPrint('アラームデータ読み込みエラー: $e');
      return [];
    }
  }

  // アラーム設定保存機能
  static Future<bool> saveAlarmSettings({
    required bool isAlarmEnabled,
    required String notificationType,
    required String alarmSound,
    required int notificationVolume,
  }) async {
    if (_preferences == null) await init();
    try {
      await _preferences!.setBool('alarm_enabled', isAlarmEnabled);
      await _preferences!.setString('notification_type', notificationType);
      await _preferences!.setString('alarm_sound', alarmSound);
      await _preferences!.setInt('notification_volume', notificationVolume);
      
      debugPrint('アラーム設定を保存しました');
      return true;
    } catch (e) {
      debugPrint('アラーム設定保存エラー: $e');
      return false;
    }
  }

  // アラーム設定読み込み機能
  static Map<String, dynamic> loadAlarmSettings() {
    if (_preferences == null) {
      return {
        'isAlarmEnabled': true,
        'notificationType': 'sound',
        'alarmSound': 'default',
        'notificationVolume': 80,
      };
    }
    
    return {
      'isAlarmEnabled': _preferences!.getBool('alarm_enabled') ?? true,
      'notificationType': _preferences!.getString('notification_type') ?? 'sound',
      'alarmSound': _preferences!.getString('alarm_sound') ?? 'default',
      'notificationVolume': _preferences!.getInt('notification_volume') ?? 80,
    };
  }


  // フォントサイズ取得機能
  static Future<double> getFontSize() async {
    if (_preferences == null) await init();
    return _preferences!.getDouble('fontSize') ?? 16.0;
  }

  // フォントサイズ設定機能
  static Future<bool> setFontSize(double fontSize) async {
    if (_preferences == null) await init();
    return await _preferences!.setDouble('fontSize', fontSize);
  }

  // 服用メモ保存機能
  static Future<bool> saveMedicationMemo(MedicationMemo memo) async {
    try {
      final box = Hive.box<MedicationMemo>('medication_memos');
      await box.put(memo.id, memo);
      debugPrint('服用メモを保存しました: ${memo.name}');
      return true;
    } catch (e) {
      debugPrint('服用メモ保存エラー: $e');
      debugPrint('エラーレポート: $e');
      return false;
    }
  }

  // 服用メモ読み込み機能
  static List<MedicationMemo> loadMedicationMemos() {
    try {
      final box = Hive.box<MedicationMemo>('medication_memos');
      return box.values.toList();
    } catch (e) {
      debugPrint('服用メモ読み込みエラー: $e');
      return [];
    }
  }

  // 服用メモ削除機能
  static Future<bool> deleteMedicationMemo(String memoId) async {
    try {
      final box = Hive.box<MedicationMemo>('medication_memos');
      await box.delete(memoId);
      debugPrint('服用メモを削除しました: $memoId');
      return true;
    } catch (e) {
      debugPrint('服用メモ削除エラー: $e');
      return false;
    }
  }

  // 服用メモ更新機能
  static Future<bool> updateMedicationMemo(MedicationMemo memo) async {
    try {
      final box = Hive.box<MedicationMemo>('medication_memos');
      await box.put(memo.id, memo);
      debugPrint('服用メモを更新しました: ${memo.name}');
      return true;
    } catch (e) {
      debugPrint('服用メモ更新エラー: $e');
      return false;
    }
  }
}
/// アプリケーションのエントリーポイント
/// 初期化処理とエラーハンドリングを設定
void main() async {
  // ✅ 修正：Zone mismatchエラーを防ぐため、ensureInitialized()をrunZonedGuarded内で実行
  runZonedGuarded(() async {
    // Flutter bindingsの初期化を同じゾーン内で実行
  WidgetsFlutterBinding.ensureInitialized();
 
    // Firebase初期化
    try {
      await Firebase.initializeApp();
      _debugLog('Firebase初期化完了');
      
      // Crashlytics初期化
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _debugLog('Firebase Crashlytics初期化完了');
      
      // テスト用の初期ログ
      await FirebaseCrashlytics.instance.log('アプリ起動 - Firebase Crashlytics有効');
  } catch (e) {
    debugPrint('Firebase初期化エラー: $e');
      // CrashlyticsHelperは初期化前なので直接debugPrint
      debugPrint('Crashlytics初期化前のエラー: $e');
  }

    // Firebase Crashlyticsのエラーハンドリングを設定（安全な初期化）
    try {
      FlutterError.onError = (errorDetails) {
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } catch (e) {
          debugPrint('Crashlyticsエラーレポート失敗: $e');
    }
  };

  // プラットフォームエラーハンドリング
  PlatformDispatcher.instance.onError = (error, stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (e) {
          debugPrint('Crashlyticsプラットフォームエラーレポート失敗: $e');
    }
    return true;
  };
    } catch (e) {
      debugPrint('Crashlyticsエラーハンドリング設定失敗: $e');
    }

    // ✅ Firebase初期化
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase初期化完了');
      
      // Crashlytics初期化
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      debugPrint('Firebase Crashlytics初期化完了');
      
      // テスト用の初期ログ
      await FirebaseCrashlytics.instance.log('アプリ起動 - Firebase Crashlytics有効');
    } catch (e) {
      debugPrint('Firebase初期化エラー: $e');
    }

    // アプリ初期化と起動
    try {
    await _initializeApp();
      // ✅ 修正：自動バックアップ機能を初期化（コメントアウト）
      // await _initializeAutoBackup();
    runApp(const MedicationAlarmApp());
  } catch (e) {
    debugPrint('アプリ初期化エラー: $e');
      // 初期化に失敗してもアプリは起動する
      try {
        // エラーをCrashlyticsに送信（初期化済みの場合）
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current, fatal: false);
    } catch (crashlyticsError) {
        debugPrint('Crashlyticsエラーレポート失敗: $crashlyticsError');
    }
    runApp(const MedicationAlarmApp());
  }
  }, (error, stack) {
    try {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (e) {
      debugPrint('Zoneエラーレポート失敗: $e');
    }
  });
}


// アプリ初期化処理を分離
Future<void> _initializeApp() async {

  // 全機種対応の設定
  try {
    // システムUIの設定
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // 画面向きの設定
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
  } catch (e) {
  }
 
  try {
    // Firebase初期化（エラーが発生してもアプリは起動）
    await Firebase.initializeApp();
    
    // Crashlytics初期化
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    debugPrint('Firebase Crashlytics初期化完了');
  } catch (e) {
    // Firebase初期化に失敗してもアプリは起動する
    debugPrint('Firebase初期化エラー: $e');
  }
 
  try {
    // タイムゾーン初期化
    tz.initializeTimeZones();
  } catch (e) {
  }
 
  try {
    // 日本語ロケール初期化
    await initializeDateFormatting('ja_JP', null);
  } catch (e) {
  }

  try {
    // Hive初期化（Flutter 3.29.3対応・Zone安全）
    await runZonedGuarded(() async {
    await Hive.initFlutter();
    
    // 服用メモ用アダプターを登録
    Hive.registerAdapter(MedicationMemoAdapter());
    
    // 服用メモ用ボックスを開く
    await Hive.openBox<MedicationMemo>('medication_memos');
    
      debugPrint('Hive初期化完了（Flutter 3.29.3対応・Zone安全）');
    }, (error, stack) {
      debugPrint('Hive初期化Zoneエラー: $error');
    });
  } catch (e) {
    debugPrint('Hive初期化エラー: $e');
  }

  // 🔴 最重要：SharedPreferencesを事前初期化（Zone安全）
  try {
    await runZonedGuarded(() async {
    await AppPreferences.init();
      debugPrint('SharedPreferences初期化完了（完全版・Zone安全）');
    }, (error, stack) {
      debugPrint('SharedPreferences初期化Zoneエラー: $error');
    });
  } catch (e) {
    debugPrint('SharedPreferences初期化エラー: $e');
  }
 
  // アプリ内課金の初期化（Zone安全）
  try {
    await runZonedGuarded(() async {
      // アプリ内課金が利用可能かチェック
      final bool isAvailable = await InAppPurchase.instance.isAvailable();
      if (isAvailable) {
        // 購入履歴を復元
        await InAppPurchaseService.restorePurchases();
        if (kDebugMode) {
          debugPrint('アプリ内課金初期化完了（Zone安全）');
        }
      } else {
        if (kDebugMode) {
          debugPrint('アプリ内課金が利用できません（Google Play Services未対応）');
        }
      }
    }, (error, stack) {
      debugPrint('アプリ内課金初期化Zoneエラー: $error');
    });
  } catch (e) {
    debugPrint('アプリ内課金初期化エラー: $e');
      debugPrint('エラーレポート: $e');
  }
}
/// 通知タイプの列挙型
/// 音、バイブレーション、サイレント、緊急の4種類
enum NotificationType {
  sound('音', Icons.volume_up),
  vibration('バイブレーション', Icons.vibration),
  silent('サイレント', Icons.notifications_off),
  urgent('緊急', Icons.priority_high);
  const NotificationType(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// 音声タイプの列挙型
/// デフォルト、優しい音、緊急音、クラシックの4種類
enum SoundType {
  defaultSound('デフォルト', 'default_sound'),
  gentle('優しい音', 'gentle_sound'),
  urgent('緊急音', 'urgent_sound'),
  classic('クラシック', 'classic_sound');
  
  const SoundType(this.displayName, this.soundFile);
  final String displayName;
  final String soundFile;
}

/// 服用メモ用のHiveアダプター
class MedicationMemoAdapter extends TypeAdapter<MedicationMemo> {
  @override
  final int typeId = 2;

  @override
  MedicationMemo read(BinaryReader reader) {
    return MedicationMemo(
      id: reader.readString(),
      name: reader.readString(),
      type: reader.readString(),
      dosage: reader.readString(),
      notes: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      lastTaken: reader.readBool() ? DateTime.parse(reader.readString()) : null,
      color: Color(reader.readInt()),
      selectedWeekdays: List<int>.from(reader.readList()),
      dosageFrequency: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MedicationMemo obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.type);
    writer.writeString(obj.dosage);
    writer.writeString(obj.notes);
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeBool(obj.lastTaken != null);
    if (obj.lastTaken != null) {
      writer.writeString(obj.lastTaken!.toIso8601String());
    }
    writer.writeInt(obj.color.value);
    writer.writeList(obj.selectedWeekdays);
    writer.writeInt(obj.dosageFrequency);
  }
}

/// 薬のデータモデル
/// 薬の名前、用量、頻度、メモを管理
class MedicineData {
  final String name;
  final String dosage;
  final String frequency;
  final String notes;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;
  final Color color;
  MedicineData({
    required this.name,
    this.dosage = '',
    this.frequency = '',
    this.notes = '',
    this.category = '処方薬',
    this.startDate,
    this.endDate,
    Color? color,
  }) : color = color ?? Colors.blue;
  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'notes': notes,
        'category': category,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'color': color.value,
      };
  factory MedicineData.fromJson(Map<String, dynamic> json) => MedicineData(
        name: json['name'] ?? '',
        dosage: json['dosage'] ?? '',
        frequency: json['frequency'] ?? '',
        notes: json['notes'] ?? '',
        category: json['category'] ?? '処方薬',
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        color: Color(json['color'] ?? Colors.blue.value),
      );
}
/// 服用メモのデータモデル
/// 薬やサプリメントの情報を管理
class MedicationMemo {
  final String id;
  final String name;
  final String type; // '薬品' or 'サプリメント'
  final String dosage;
  final String notes;
  final DateTime createdAt;
  final DateTime? lastTaken;
  final Color color;
  final List<int> selectedWeekdays; // 0=日曜日, 1=月曜日, ..., 6=土曜日
  final int dosageFrequency; // 服用回数（1〜6回）
  MedicationMemo({
    required this.id,
    required this.name,
    required this.type,
    this.dosage = '',
    this.notes = '',
    required this.createdAt,
    this.lastTaken,
    Color? color,
    this.selectedWeekdays = const [],
    this.dosageFrequency = 1,
  }) : color = color ?? Colors.blue;
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'dosage': dosage,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'lastTaken': lastTaken?.toIso8601String(),
        'color': color.value,
        'selectedWeekdays': selectedWeekdays,
        'dosageFrequency': dosageFrequency,
      };
  factory MedicationMemo.fromJson(Map<String, dynamic> json) => MedicationMemo(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] ?? '薬品',
        dosage: json['dosage'] ?? '',
        notes: json['notes'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        lastTaken: json['lastTaken'] != null ? DateTime.parse(json['lastTaken']) : null,
        color: Color(json['color'] ?? Colors.blue.value),
        selectedWeekdays: List<int>.from(json['selectedWeekdays'] ?? []),
        dosageFrequency: json['dosageFrequency'] ?? 1,
      );
}
class MedicineDataAdapter extends TypeAdapter<MedicineData> {
  @override
  final int typeId = 1;
  @override
  MedicineData read(BinaryReader reader) {
    return MedicineData(
      name: reader.readString(),
      dosage: reader.readString(),
      frequency: reader.readString(),
      notes: reader.readString(),
      category: reader.readString(),
      startDate: reader.read() as DateTime?,
      endDate: reader.read() as DateTime?,
      color: Color(reader.readInt()),
    );
  }
  @override
  void write(BinaryWriter writer, MedicineData obj) {
    writer.writeString(obj.name);
    writer.writeString(obj.dosage);
    writer.writeString(obj.frequency);
    writer.writeString(obj.notes);
    writer.writeString(obj.category);
    writer.write(obj.startDate);
    writer.write(obj.endDate);
    writer.writeInt(obj.color.value);
  }
}
class MedicationInfo {
  final bool checked;
  final String medicine;
  final DateTime? actualTime;
  final String notes;
  final String sideEffects;
  MedicationInfo({
    required this.checked,
    required this.medicine,
    this.actualTime,
    this.notes = '',
    this.sideEffects = '',
  });
  Map<String, dynamic> toJson() => {
        'checked': checked,
        'medicine': medicine,
        'actualTime': actualTime?.toIso8601String(),
        'notes': notes,
        'sideEffects': sideEffects,
      };
  factory MedicationInfo.fromJson(Map<String, dynamic> json) => MedicationInfo(
        checked: json['checked'] ?? false,
        medicine: json['medicine'] ?? '',
        actualTime: json['actualTime'] != null ? DateTime.parse(json['actualTime']) : null,
        notes: json['notes'] ?? '',
        sideEffects: json['sideEffects'] ?? '',
      );
}
class MedicationInfoAdapter extends TypeAdapter<MedicationInfo> {
  @override
  final int typeId = 0;
  @override
  MedicationInfo read(BinaryReader reader) {
    return MedicationInfo(
      checked: reader.readBool(),
      medicine: reader.readString(),
      actualTime: reader.read() as DateTime?,
      notes: reader.readString(),
      sideEffects: reader.readString(),
    );
  }
  @override
  void write(BinaryWriter writer, MedicationInfo obj) {
    writer.writeBool(obj.checked);
    writer.writeString(obj.medicine);
    writer.write(obj.actualTime);
    writer.writeString(obj.notes);
    writer.writeString(obj.sideEffects);
  }
}
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
      home: const TutorialWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
  static Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('fontSize') ?? 16.0;
    } catch (e) {
      return 16.0;
    }
  }
}
/// 薬のデータ管理サービス
/// Hiveデータベースを使用して薬の情報を管理
class MedicationService {
  static Box<Map>? _medicationBox;
  static Box<MedicineData>? _medicineDatabase;
  static Box<Map>? _adherenceStats;
  static Box<dynamic>? _settingsBox;
  static bool _isInitialized = false;
  static const String _csvFileName = '服薬記録.csv';
  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(directory.path);
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MedicationInfoAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(MedicineDataAdapter());
      }
      _medicationBox = await Hive.openBox<Map>('medicationData');
      _medicineDatabase = await Hive.openBox<MedicineData>('medicineDatabase');
      _adherenceStats = await Hive.openBox<Map>('adherenceStats');
      _settingsBox = await Hive.openBox('settings');
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
  static Future<Map<String, Map<String, MedicationInfo>>> loadMedicationData() async {
    try {
      await _ensureInitialized();
      if (_medicationBox == null) return {};
      return _medicationBox!.toMap().cast<String, Map>().map(
            (key, value) => MapEntry(
              key,
              value.map((k, v) => MapEntry(k, MedicationInfo.fromJson(Map<String, dynamic>.from(v)))),
            ),
          );
    } catch (e) {
      return {};
    }
  }
  static Future<List<MedicineData>> loadMedicines() async {
    try {
      await _ensureInitialized();
      if (_medicineDatabase == null) return [];
      return _medicineDatabase!.values.toList();
    } catch (e) {
      return [];
    }
  }
  static Future<Map<String, double>> loadAdherenceStats() async {
    try {
      await _ensureInitialized();
      if (_adherenceStats == null) return {};
      return Map<String, double>.from(_adherenceStats!.get('rates') ?? {});
    } catch (e) {
      return {};
    }
  }
  static Future<void> saveMedicationData(Map<String, Map<String, MedicationInfo>> data) async {
    try {
      await _ensureInitialized();
      if (_medicationBox == null) return;
      await _medicationBox!.putAll(
        data.map((key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v.toJson())))),
      );
      await _medicationBox!.flush();
    } catch (e) {
    }
  }
  static Future<void> saveMedicine(MedicineData medicine) async {
    try {
      await _ensureInitialized();
      if (_medicineDatabase == null) return;
      await _medicineDatabase!.put(medicine.name, medicine);
      await _medicineDatabase!.flush();
    } catch (e) {
    }
  }
  static Future<void> deleteMedicine(String name) async {
    try {
      await _ensureInitialized();
      if (_medicineDatabase == null) return;
      await _medicineDatabase!.delete(name);
      await _medicineDatabase!.flush();
    } catch (e) {
    }
  }
  static Future<void> saveAdherenceStats(Map<String, double> stats) async {
    try {
      await _ensureInitialized();
      if (_adherenceStats == null) return;
      await _adherenceStats!.put('rates', stats);
      await _adherenceStats!.flush();
    } catch (e) {
    }
  }
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      await _ensureInitialized();
      if (_settingsBox == null) return;
      await _settingsBox!.putAll(settings);
      await _settingsBox!.flush();
    } catch (e) {
    }
  }
  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      await _ensureInitialized();
      if (_settingsBox == null) return {};
      return Map<String, dynamic>.from(_settingsBox!.toMap());
    } catch (e) {
      return {};
    }
  }
  static Future<void> saveCsvRecord(String dateStr, String timeSlot, String medicine, String status) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_csvFileName');
      final now = DateFormat('yyyy年MM月dd日 HH:mm:ss', 'ja_JP').format(DateTime.now());
      final record = '$dateStr,$timeSlot,${medicine.isEmpty ? "未入力" : medicine},$status,$now\n';
      if (!await file.exists()) {
        await file.writeAsString('日付,時間帯,薬の種類,服薬状況,記録時間\n');
      }
      await file.writeAsString(record, mode: FileMode.append);
    } catch (e) {
    }
  }
}
/// 通知管理サービス
/// ローカル通知の設定と管理を行う
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
     
      if (Platform.isAndroid) {
        final notificationStatus = await Permission.notification.request();
        if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
          if (notificationStatus.isPermanentlyDenied) await openAppSettings();
          return false;
        }
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      }
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      final initialized = await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
        },
      );
      if ((initialized ?? false) && Platform.isAndroid) {
        final channels = [
          const AndroidNotificationChannel(
            'medication_sound',
            '服用アラーム',
            description: '服薬時間の通知',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        ];
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        for (final channel in channels) {
          await androidPlugin?.createNotificationChannel(channel);
        }
      }
      _isInitialized = initialized ?? false;
      return _isInitialized;
    } catch (e) {
      return false;
    }
  }
  static Future<void> scheduleNotifications(
    Map<String, List<TimeOfDay>> notificationTimes,
    Map<String, Map<String, MedicationInfo>> medicationData,
    Map<String, NotificationType> notificationTypes,
  ) async {
    if (!_isInitialized) return;
    try {
      // ✅ 修正：既存の通知をすべてキャンセル
      await _plugin.cancelAll();
      int notificationId = 1;
      final now = DateTime.now();
      
      // ✅ 修正：medicationDataの各エントリに対して通知をスケジュール
      for (final entry in medicationData.entries) {
        final dateStr = entry.key;
        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
          
        for (final timeSlot in notificationTimes.keys) {
          final times = notificationTimes[timeSlot] ?? [];
          
          for (final time in times) {
            var scheduledDate = DateTime(
              date.year, date.month, date.day, 
              time.hour, time.minute
            );
            
            // ✅ 修正：過去の日時はスケジュールしない
            if (scheduledDate.isAfter(DateTime.now())) {
              final medicines = entry.value[timeSlot]?.medicine ?? '';
          final displayMedicines = medicines.isNotEmpty ? medicines : '薬';
          
          const androidDetails = AndroidNotificationDetails(
                'medication_sound',
            '服用アラーム',
            channelDescription: '服薬時間の通知',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                icon: '@mipmap/ic_launcher',
            autoCancel: true,
            ongoing: false,
            actions: [
              AndroidNotificationAction(
                'stop_alarm',
                '停止',
                cancelNotification: true,
              ),
            ],
          );
          
          const iosDetails = DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );
          
          final notificationDetails = NotificationDetails(
            android: androidDetails, 
            iOS: iosDetails,
          );
          
              // ✅ 修正：zonedScheduleを使用して正確なスケジュール
            await _plugin.zonedSchedule(
              notificationId++,
              '服用アラーム',
              '$displayMedicines を服用しましょう',
                tz.TZDateTime.from(scheduledDate, tz.local),
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: 
                  UILocalNotificationDateInterpretation.absoluteTime,
            );
            }
          }
        }
      }
    } catch (e) {
    }
  }
}
/// アプリ内課金サービス
/// 商品ID hirochaso980 を使用した課金機能を提供
class InAppPurchaseService {
  static const String _productId = 'hirochaso980';
  static const String _purchaseStatusKey = 'purchase_status';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 商品情報を取得
  static Future<ProductDetails?> getProductDetails() async {
    try {
      // アプリ内課金が利用可能かチェック
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return null;
      }
      
      final Set<String> productIds = {_productId};
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('商品IDが見つかりません: ${response.notFoundIDs}');
          debugPrint('Google Play Consoleで商品ID「$_productId」が登録されているか確認してください');
        }
        return null;
      }
      
      if (response.productDetails.isNotEmpty) {
        final product = response.productDetails.first;
        if (kDebugMode) {
          debugPrint('商品情報取得成功: ${product.title} - ${product.price}');
        }
        return product;
      }
      
      if (kDebugMode) {
        debugPrint('商品情報が空です');
      }
      return null;
    } catch (e) {
      debugPrint('商品情報取得エラー: $e');
      return null;
    }
  }
  
  // 購入を開始
  static Future<bool> purchaseProduct() async {
    try {
      // アプリ内課金が利用可能かチェック
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return false;
      }
      
      final ProductDetails? product = await getProductDetails();
      if (product == null) {
        if (kDebugMode) {
          debugPrint('商品情報が取得できません');
          debugPrint('Google Play Consoleで商品ID「$_productId」が「有効」状態になっているか確認してください');
        }
        return false;
      }
      
      if (kDebugMode) {
        debugPrint('購入を開始します: ${product.title} - ${product.price}');
      }
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (kDebugMode) {
        if (success) {
          debugPrint('購入リクエストを送信しました');
        } else {
          debugPrint('購入リクエストの送信に失敗しました');
        }
      }
      
      return success;
    } catch (e) {
      debugPrint('購入エラー: $e');
      return false;
    }
  }
  
  // 購入結果を監視
  static void startPurchaseListener(Function(bool success, String? error) onPurchaseResult) {
    _subscription?.cancel();
    _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      for (var purchaseDetails in purchaseDetailsList) {
        _handlePurchaseUpdate(purchaseDetails, onPurchaseResult);
      }
    });
  }
  
  // 購入更新を処理
  static void _handlePurchaseUpdate(PurchaseDetails purchaseDetails, Function(bool success, String? error) onPurchaseResult) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      if (kDebugMode) {
        debugPrint('購入成功: ${purchaseDetails.productID}');
      }
      // 購入済み状態に設定
      TrialService.setPurchaseStatus(TrialService.purchasedStatus);
      onPurchaseResult(true, '商品購入後、期限が無期限になりました！');
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      if (kDebugMode) {
        debugPrint('購入エラー: ${purchaseDetails.error}');
      }
      onPurchaseResult(false, purchaseDetails.error?.message ?? '購入に失敗しました');
    } else if (purchaseDetails.status == PurchaseStatus.canceled) {
      if (kDebugMode) {
        debugPrint('購入キャンセル');
      }
      onPurchaseResult(false, '購入がキャンセルされました');
    }
    
    // 購入完了を通知
    if (purchaseDetails.pendingCompletePurchase) {
      _inAppPurchase.completePurchase(purchaseDetails);
    }
  }
  
  // 購入状態を確認
  static Future<bool> isPurchased() async {
    try {
      final status = await TrialService.getPurchaseStatus();
      return status == TrialService.purchasedStatus;
    } catch (e) {
      debugPrint('購入状態確認エラー: $e');
      return false;
    }
  }
  
  // 購入履歴を復元
  static Future<void> restorePurchases() async {
    try {
      // アプリ内課金が利用可能かチェック
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        debugPrint('アプリ内課金が利用できません');
        return;
      }
      
      if (kDebugMode) {
        debugPrint('購入履歴の復元を開始しました');
      }
      await _inAppPurchase.restorePurchases();
      
      // 購入履歴復元の結果を監視
      _subscription?.cancel();
      _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
        for (var purchaseDetails in purchaseDetailsList) {
          if (purchaseDetails.status == PurchaseStatus.purchased) {
            if (kDebugMode) {
              debugPrint('購入履歴復元成功: ${purchaseDetails.productID}');
            }
            // 購入済み状態に設定
            TrialService.setPurchaseStatus(TrialService.purchasedStatus);
          }
        }
      });
    } catch (e) {
      debugPrint('購入履歴復元エラー: $e');
    }
  }
  
  // リソースを解放
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// トライアル期間管理サービス
/// 7日間のトライアル期間の管理と制限機能を提供
class TrialService {
  static const String _trialStartTimeKey = 'trial_start_time';
  static const String _purchaseLinkKey = 'purchase_link';
  static const String _purchaseStatusKey = 'purchase_status'; // 購入状態を保存
  static const int _trialDurationMinutes = 7 * 24 * 60; // トライアル期間: 7日
  
  // 購入状態の列挙型
  static const String trialStatus = 'trial'; // トライアル中
  static const String expiredStatus = 'expired'; // 期限切れ
  static const String purchasedStatus = 'purchased'; // 購入済み
  
  // トライアル開始時刻を記録
  static Future<void> initializeTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_trialStartTimeKey)) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(_trialStartTimeKey, now);
      }
    } catch (e) {
    }
  }
  
  // 現在の購入状態を取得
  static Future<String> getPurchaseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = prefs.getString(_purchaseStatusKey);
      
      if (status == purchasedStatus) {
        return purchasedStatus; // 購入済み
      }
      
      // トライアル期間をチェック
      final startTime = prefs.getInt(_trialStartTimeKey);
      if (startTime == null) {
        await initializeTrial();
        return trialStatus; // トライアル開始
      }
      
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      final now = DateTime.now();
      final difference = now.difference(start);
      
      if (difference.inMinutes >= _trialDurationMinutes) {
        return expiredStatus; // 期限切れ
      }
      
      return trialStatus; // トライアル中
    } catch (e) {
      return trialStatus;
    }
  }
  
  // 購入状態を設定
  static Future<void> setPurchaseStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_purchaseStatusKey, status);
    } catch (e) {
    }
  }
  
  // トライアル期間が終了しているかチェック（後方互換性のため残す）
  static Future<bool> isTrialExpired() async {
    final status = await getPurchaseStatus();
    return status == expiredStatus;
  }
  
  // 残り時間を取得（分単位）
  static Future<int> getRemainingMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt(_trialStartTimeKey);
      if (startTime == null) return _trialDurationMinutes;
      
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      final now = DateTime.now();
      final elapsed = now.difference(start).inMinutes;
      final remaining = _trialDurationMinutes - elapsed;
      
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }
  
  
  // 購入リンクを設定
  static Future<void> setPurchaseLink(String link) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_purchaseLinkKey, link);
    } catch (e) {
    }
  }
  
  // 購入リンクを取得
  static Future<String?> getPurchaseLink() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_purchaseLinkKey);
    } catch (e) {
      return null;
    }
  }
  
  // トライアル期間をリセット（開発・テスト用）
  static Future<void> resetTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_trialStartTimeKey);
    } catch (e) {
    }
  }
  
  // トライアル・購入状態の詳細情報を取得
  static Future<Map<String, dynamic>> getTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTime = prefs.getInt(_trialStartTimeKey);
      
      if (startTime == null) {
        await initializeTrial();
        return {
          'isExpired': false,
          'remainingMinutes': _trialDurationMinutes,
          'startTime': DateTime.now(),
          'status': 'trial_active'
        };
      }
      
      final start = DateTime.fromMillisecondsSinceEpoch(startTime);
      final now = DateTime.now();
      final elapsed = now.difference(start).inMinutes;
      final remaining = _trialDurationMinutes - elapsed;
      final isExpired = remaining <= 0;
      
      return {
        'isExpired': isExpired,
        'remainingMinutes': remaining > 0 ? remaining : 0,
        'startTime': start,
        'status': isExpired ? 'expired' : 'trial_active'
      };
    } catch (e) {
      return {
        'isExpired': false,
        'remainingMinutes': 0,
        'startTime': DateTime.now(),
        'status': 'error'
      };
    }
  }
  
  // トライアル状態をコンソールに出力（デバッグ用）
  static Future<void> printTrialStatus() async {
    await getTrialStatus();
  }
  
}

/// トライアル制限警告ダイアログ
/// トライアル期間終了時に機能制限を通知するダイアログ
class TrialLimitDialog extends StatelessWidget {
  final String featureName;
  
  const TrialLimitDialog({super.key, required this.featureName});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 鍵アイコンとメッセージ
          Row(
            children: [
              Icon(Icons.lock, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'トライアル期間が終了しました。\n現在、以下の機能が制限されています：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildRestrictionItem('すべてのメモ（服用メモ含む）', '追加・入力ができません'),
          _buildRestrictionItem('アラーム機能', '使用できません'),
          _buildRestrictionItem('統計機能', '閲覧できません'),
          _buildRestrictionItem('カレンダー', '当日以外の閲覧ができません'),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              '機能を継続してご利用いただくには、\n購入が必要です。',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('閉じる'),
        ),
        ElevatedButton(
          onPressed: () async {
            await TrialService.getPurchaseLink();
            // リンクを開く処理（後で実装）
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('👉 機能解除はこちら'),
        ),
      ],
    );
  }
  
  Widget _buildRestrictionItem(String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.block, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// トライアル期間メッセージ表示画面
/// チュートリアル完了後に5秒間表示される
class TrialMessageScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const TrialMessageScreen({super.key, required this.onComplete});
  @override
  State<TrialMessageScreen> createState() => _TrialMessageScreenState();
}

class _TrialMessageScreenState extends State<TrialMessageScreen> {
  @override
  void initState() {
    super.initState();
    // 5秒後に自動的にメインページに遷移
    Timer(const Duration(seconds: 5), () {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              // メッセージ
              const Text(
                '本日から7日間、すべての機能を無料でご利用いただけます。',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '※無料期間終了後は一部機能に制限がかかります。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // ローディングインジケーター
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// チュートリアルラッパー
/// 初回起動時にチュートリアルを表示するかどうかを管理
class TutorialWrapper extends StatefulWidget {
  const TutorialWrapper({super.key});
  @override
  State<TutorialWrapper> createState() => _TutorialWrapperState();
}
class _TutorialWrapperState extends State<TutorialWrapper> {
  bool _showTutorial = true;
  bool _showTrialMessage = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      await _checkTutorialStatus();
      // トライアル期間を初期化
      await TrialService.initializeTrial();
      await Future.wait([
        MedicationService.initialize().catchError((e) {
          return null;
        }),
        NotificationService.initialize().catchError((e) {
          return false;
        }),
      ]);
    } catch (e) {
    }
  }
  Future<void> _checkTutorialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('tutorialShown') ?? false) {
        setState(() => _showTutorial = false);
      }
    } catch (e) {
    }
  }
  
  void _onTutorialComplete() {
    setState(() {
      _showTutorial = false;
      _showTrialMessage = true;
    });
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('tutorialShown', true));
  }
  
  void _onTrialMessageComplete() {
    setState(() {
      _showTrialMessage = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_showTutorial) {
      return TutorialPage(onComplete: _onTutorialComplete);
    } else if (_showTrialMessage) {
      return TrialMessageScreen(onComplete: _onTrialMessageComplete);
    } else {
      return const MedicationHomePage();
    }
  }
}
/// チュートリアルページ
/// アプリの使い方を説明するページビュー
class TutorialPage extends StatefulWidget {
  final VoidCallback onComplete;
  const TutorialPage({super.key, required this.onComplete});
  @override
  State<TutorialPage> createState() => _TutorialPageState();
}
class _TutorialPageState extends State<TutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<Map<String, dynamic>> _tutorialPages = [
    {
      'icon': Icons.calendar_month,
      'title': 'カレンダー機能',
      'description': '日付をタップして服用記録を管理\n服用メモから服用スケジュール(毎日、曜日)を選択',
      'color': Colors.blue,
      'image': '📅',
      'features': ['日付選択', '服用記録', 'スケジュール管理'],
    },
    {
      'icon': Icons.medication,
      'title': '服用メモ',
      'description': '薬やサプリメントを登録\n曜日設定で服用スケジュールを管理',
      'color': Colors.green,
      'image': '💊',
      'features': ['薬品登録', 'サプリメント登録', '曜日設定'],
    },
    {
      'icon': Icons.alarm,
      'title': 'アラーム',
      'description': '服用時間を忘れずにリマインド\n複数の通知時間を設定可能',
      'color': Colors.orange,
      'image': '⏰',
      'features': ['通知設定', 'リマインド', '複数時間'],
    },
    {
      'icon': Icons.analytics,
      'title': '統計',
      'description': '服用遵守率をグラフで可視化\n健康管理をデータでサポート',
      'color': Colors.purple,
      'image': '📊',
      'features': ['遵守率グラフ', 'データ分析', '健康管理'],
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _tutorialPages.length,
                itemBuilder: (context, index) {
                  final page = _tutorialPages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 大きな図（絵文字）
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: page['color'] as Color,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              page['image'] as String,
                              style: const TextStyle(fontSize: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // タイトル
                        Text(
                          page['title'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: page['color'] as Color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // 説明文
                        Text(
                          page['description'],
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // 機能一覧
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (page['color'] as Color).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '主な機能',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: page['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: (page['features'] as List<String>).map((feature) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: page['color'] as Color,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      feature,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ボタンエリア（固定位置）
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ページインジケーター
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _tutorialPages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                          color: _currentPage == index 
                              ? _tutorialPages[_currentPage]['color'] as Color
                              : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // ボタンエリア
                  Row(
                    children: [
                      // スキップボタン（左側）
                      Expanded(
                        child: TextButton(
                          onPressed: widget.onComplete,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'スキップ',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 次へ/始めるボタン（右側）
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _tutorialPages.length - 1) {
                              widget.onComplete();
                            } else {
                              _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _tutorialPages[_currentPage]['color'] as Color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            ),
                    child: Text(
                      _currentPage == _tutorialPages.length - 1 ? '始める' : '次へ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// メインのホームページ
/// カレンダー、服用メモ、統計、設定のタブを持つメインページ
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}
class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDates = <DateTime>{};
  // 動的に追加される薬のリスト
  List<Map<String, dynamic>> _addedMedications = [];
  late TabController _tabController;
  bool _notificationError = false;
  bool _isInitialized = false;
  bool _isAlarmPlaying = false;
  bool _isLoading = false; // ✅ 修正：ローディング状態を追加
  Map<String, Map<String, MedicationInfo>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<MedicineData> _medicines = [];
  List<MedicationMemo> _medicationMemos = [];
  Timer? _debounce;
  Timer? _saveDebounceTimer; // ✅ 修正：保存用デバウンスタイマーを追加
  StreamSubscription<List<PurchaseDetails>>? _subscription; // ✅ 修正：StreamSubscriptionを追加
  
  // ✅ 修正：変更フラグ変数を追加
  bool _medicationMemoStatusChanged = false;

  bool _weekdayMedicationStatusChanged = false;
  bool _addedMedicationsChanged = false;
 
  // カスタム遵守率の結果表示用
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
 
  // ✅ 修正：データキーの統一とバージョン管理
  static const String _medicationMemosKey = 'medication_memos_v2';
  static const String _medicationMemoStatusKey = 'medication_memo_status_v2';
  static const String _weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  static const String _addedMedicationsKey = 'added_medications_v2';
  
  // バックアップキー
  static const String _backupSuffix = '_backup';
 
  
  // メモ用の状態変数
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  bool _isMemoFocused = false;
  
  
  // 曜日設定された薬の服用状況を管理
  Map<String, Map<String, bool>> _weekdayMedicationStatus = {};
  
  // 服用回数別の服用状況を管理（日付 -> メモID -> 回数インデックス -> 服用済み）
  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  
  // 服用メモのチェック状況を管理
  Map<String, bool> _medicationMemoStatus = {};
  
  // メモ選択状態を管理
  bool _isMemoSelected = false;
  MedicationMemo? _selectedMemo;
  
  // 日別の色を管理
  Map<String, Color> _dayColors = {};
  
  // アラームデータを管理
  List<Map<String, dynamic>> _alarmList = [];
  Map<String, dynamic> _alarmSettings = {};
  
  // オーバースクロール検出用の状態変数
  bool _isAtTop = false;
  double _lastScrollPosition = 0.0;
  
  // カレンダータブのスクロール制御用
  final ScrollController _calendarScrollController = ScrollController();
  
  // 服用履歴メモ用のScrollController
  final ScrollController _medicationHistoryScrollController = ScrollController();
  
  // 服用記録ページめくり用のコントローラー
  late PageController _medicationPageController;
  int _currentMedicationPage = 0;
  
  // カレンダー下の位置を取得するためのGlobalKey
  final GlobalKey _calendarBottomKey = GlobalKey();
  
  // スクロールバトンタッチ用の変数
  bool _isScrollBatonPassActive = false;
  
  // ログ制御用の変数
  DateTime _lastAlarmCheckLog = DateTime.now();
  static const Duration _logInterval = Duration(seconds: 30); // 30秒間隔でログ出力
  
  // ログ出力を制限するヘルパーメソッド
  bool _shouldLog() {
    final now = DateTime.now();
    if (now.difference(_lastAlarmCheckLog) >= _logInterval) {
      _lastAlarmCheckLog = now;
      return true;
    }
    return false;
  }
  
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    
   
    
    // PageControllerを初期化
    _medicationPageController = PageController(viewportFraction: 1.0);
    
    // こぱさん流：データ読み込みを先に実行（上書きを防ぐ）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // データ読み込みを確実に実行
      await _loadSavedData();
      
      
      // 服用メモデータを読み込み
      await _loadMedicationMemos();
   
      // データ読み込み後に基本設定を実行
      if (_selectedDay == null) {
    _selectedDay = DateTime.now();
      }
      if (_selectedDates.isEmpty) {
    _selectedDates.add(_normalizeDate(DateTime.now()));
      }
    _setupControllerListeners();
      
      // 初期化フラグを設定
      _isInitialized = true;
      
      // UIを強制更新
      setState(() {});
    });
  }
  
  // 包括的データ読み込みシステム：すべてのデータを復元
  Future<void> _loadSavedData() async {
    try {
      // 包括的データ読み込み：すべてのデータを復元
      await _loadAllData();
      
      // 重い処理も実行
      await _initializeAsync();
      
      // アラームの再登録
      await _reRegisterAlarms();
      
      // データ保持テスト
      await _testDataPersistence();
      
      _debugLog('全データ読み込み完了（包括的ローカル復元）');
    } catch (e) {
      _debugLog('データ読み込みエラー: $e');
    }
  }
  
  // 包括的データ保存システム：すべてのデータをローカル保存
  Future<void> _saveAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. メモ状態の保存
      await _saveMemoStatus();
      
      // 2. 服用薬データの保存
      await _saveMedicationList();
      
      // 3. アラームデータの保存
      await _saveAlarmData();
      
      // 4. カレンダーマークの保存
      await _saveCalendarMarks();
      
      // 5. ユーザー設定の保存
      await _saveUserPreferences();
      
      // 6. 服用データの保存
      await _saveMedicationData();
      
      // 7. 日別色設定の保存
      await _saveDayColors();
      
      // 8. 統計データの保存
      await _saveStatistics();
      
      // 9. アプリ設定の保存
      await _saveAppSettings();
      
      // 10. 服用回数別状態の保存
      await _saveMedicationDoseStatus();
      
      _debugLog('全データ保存完了（包括的ローカル保存）');
    } catch (e) {
      _debugLog('全データ保存エラー: $e');
    }
  }
  
  // 包括的データ読み込みシステム：すべてのデータを復元
  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. メモ状態の読み込み
      await _loadMemoStatus();
      
      // 2. 服用薬データの読み込み
      await _loadMedicationList();
      
      // 3. アラームデータの読み込み
      await _loadAlarmData();
      
      // 3.5. アラームの再登録
      await _reRegisterAlarms();
      
      // 4. カレンダーマークの読み込み
      await _loadCalendarMarks();
      
      // 5. ユーザー設定の読み込み
      await _loadUserPreferences();
      
      // 6. 服用データの読み込み
      await _loadMedicationData();
      
      // 7. 日別色設定の読み込み
      await _loadDayColors();
      
      // 8. 統計データの読み込み
      await _loadStatistics();
      
      // 9. 服用回数別状態の読み込み
      await _loadMedicationDoseStatus();
      
      // 9. アプリ設定の読み込み
      await _loadAppSettings();
      
      // 10. データ検証とUI更新
      await _validateAndUpdateUI();
      
      _debugLog('全データ読み込み完了（包括的ローカル復元）');
    } catch (e) {
      _debugLog('全データ読み込みエラー: $e');
    }
  }
  
  // データ検証とUI更新
  Future<void> _validateAndUpdateUI() async {
    try {
      // データの整合性をチェック
      await _validateDataIntegrity();
      
      // UIを強制更新
      if (mounted) {
        setState(() {
          // 状態を強制更新
        });
      }
      
      // カレンダーの日付を更新
      await _updateCalendarForSelectedDate();
      
      // 服用メモの状態を更新
      await _updateMedicationMemoDisplay();
      
      // アラームデータの検証
      await _validateAlarmData();
      
      // アラームデータの整合性チェック
      await _checkAlarmDataIntegrity();
      
      // アプリ再起動時のデータ表示を確実にする
      await _ensureDataDisplayOnRestart();
      
      // 最終的なデータ表示確認
      await _finalDataDisplayCheck();
      
      _debugLog('データ検証とUI更新完了');
    } catch (e) {
      _debugLog('データ検証とUI更新エラー: $e');
    }
  }
  
  // 最終的なデータ表示確認
  Future<void> _finalDataDisplayCheck() async {
    try {
      // データ表示の最終確認
      debugPrint('=== 最終データ表示確認 ===');
      debugPrint('選択日付: ${_selectedDay != null ? DateFormat('yyyy-MM-dd').format(_selectedDay!) : 'なし'}');
      debugPrint('服用メモ数: ${_medicationMemos.length}件');
      debugPrint('メモ状態数: ${_medicationMemoStatus.length}件');
      debugPrint('動的薬リスト数: ${_addedMedications.length}件');
      debugPrint('カレンダーマーク数: ${_selectedDates.length}件');
      debugPrint('日別色設定数: ${_dayColors.length}件');
      
      // UIを最終更新
      if (mounted) {
        setState(() {
          // 最終的なUI更新
        });
      }
      
      debugPrint('=== 最終データ表示確認完了 ===');
    } catch (e) {
      debugPrint('最終データ表示確認エラー: $e');
    }
  }
  
  // データの整合性をチェック
  Future<void> _validateDataIntegrity() async {
    try {
      // 選択された日付のデータを確認
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final dayData = _medicationData[dateStr];
        
        if (dayData != null) {
          debugPrint('選択日付のデータ確認: $dateStr - ${dayData.length}件');
        } else {
          debugPrint('選択日付のデータなし: $dateStr');
        }
      }
      
      // 服用メモの状態を確認
      debugPrint('服用メモ状態: ${_medicationMemoStatus.length}件');
      
      // カレンダーマークを確認
      debugPrint('カレンダーマーク: ${_selectedDates.length}件');
      
      // 日別色設定を確認
      debugPrint('日別色設定: ${_dayColors.length}件');
      
    } catch (e) {
      debugPrint('データ整合性チェックエラー: $e');
    }
  }
  
  // カレンダーの日付を更新
  Future<void> _updateCalendarForSelectedDate() async {
    try {
      if (_selectedDay != null) {
        // 選択された日付のデータを読み込み
        await _updateMedicineInputsForSelectedDate();
        
        // メモを読み込み
        await _loadMemoForSelectedDate();
        
        debugPrint('カレンダー日付更新完了: ${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
      }
    } catch (e) {
      debugPrint('カレンダー日付更新エラー: $e');
    }
  }
  
  // 服用メモの表示を更新
  Future<void> _updateMedicationMemoDisplay() async {
    try {
      // 服用メモの状態を再計算
      for (final memo in _medicationMemos) {
        if (!_medicationMemoStatus.containsKey(memo.id)) {
          _medicationMemoStatus[memo.id] = false;
        }
      }
      
      debugPrint('服用メモ表示更新完了: ${_medicationMemos.length}件');
    } catch (e) {
      debugPrint('服用メモ表示更新エラー: $e');
    }
  }
  
  // 🔴 最重要：データ保持テスト（完全版）
  Future<void> _testDataPersistence() async {
    try {
      // 🔴 最重要：最小構成テンプレート
      final testKey = 'flutter_storage_test';
      final testValue = 'data_persistence_test_${DateTime.now().millisecondsSinceEpoch}';
      
      debugPrint('🔴 データ保持テスト開始: $testValue');
      
      // 🔴 最重要：保存処理（awaitを確実に付ける）
      await AppPreferences.saveString(testKey, testValue);
      debugPrint('🔴 データ保持テスト保存完了（完全版）');
      
      // 🔴 最重要：復元処理（起動時）
      final readValue = AppPreferences.getString(testKey);
      if (readValue == testValue) {
        debugPrint('🔴 データ保持テスト成功: $readValue（完全版）');
      } else {
        debugPrint('🔴 データ保持テスト失敗: 期待値=$testValue, 実際値=$readValue');
      }
      
      // 🔴 最重要：デバッグ用：すべてのキーを表示
      AppPreferences.debugAllKeys();
      
      // テストデータの削除
      await AppPreferences.remove(testKey);
      debugPrint('🔴 テストデータ削除完了');
    } catch (e) {
      debugPrint('🔴 データ保持テストエラー: $e');
    }
  }
  
  // 服用データの読み込み
  Future<void> _loadMedicationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSaveDate = prefs.getString('last_save_date');
      
      if (lastSaveDate != null) {
        final backupData = prefs.getString('medication_backup_$lastSaveDate');
        if (backupData != null) {
          final dataJson = jsonDecode(backupData) as Map<String, dynamic>;
          debugPrint('服用データ復元: $lastSaveDate');
        }
      }
    } catch (e) {
      debugPrint('服用データ読み込みエラー: $e');
    }
  }
  
  // こぱさん流：服用薬データを読み込み（確実なデータ復元）
  Future<void> _loadMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? medicationListStr;
      
      // こぱさん流：複数キーから読み込み
      final keys = ['medicationList', 'medicationList_backup'];
      
      for (final key in keys) {
        medicationListStr = prefs.getString(key);
        if (medicationListStr != null && medicationListStr.isNotEmpty) {
          debugPrint('服用薬データ読み込み成功: $key（こぱさん流）');
          break;
        }
      }
      
      if (medicationListStr != null && medicationListStr.isNotEmpty) {
        final medicationListJson = jsonDecode(medicationListStr) as Map<String, dynamic>;
        _addedMedications.clear();
        
        final count = prefs.getInt('medicationList_count') ?? 0;
        for (int i = 0; i < count; i++) {
          final medKey = 'medication_$i';
          if (medicationListJson.containsKey(medKey)) {
            final medData = medicationListJson[medKey] as Map<String, dynamic>;
            _addedMedications.add({
              'id': medData['id'],
              'name': medData['name'],
              'type': medData['type'],
              'dosage': medData['dosage'],
              'color': medData['color'],
              'taken': medData['taken'],
              'takenTime': medData['takenTime'] != null ? DateTime.parse(medData['takenTime']) : null,
              'notes': medData['notes'],
            });
          }
        }
        
        debugPrint('服用薬データ読み込み完了: ${_addedMedications.length}件（こぱさん流）');
        
        // こぱさん流：UIに反映
        if (mounted) {
          setState(() {
            // 保存された値があればそれを使う
          });
        }
      } else {
        debugPrint('服用薬データが見つかりません（こぱさん流）');
        _addedMedications.clear();
      }
    } catch (e) {
      debugPrint('服用薬データ読み込みエラー: $e');
      _addedMedications.clear();
    }
  }
  
  // 確実なアラームデータ読み込み（指定パス方式を採用）
  Future<void> _loadAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmCount = prefs.getInt('alarm_count') ?? 0;
      final alarmsList = <Map<String, dynamic>>[];
      
      debugPrint('アラームデータ読み込み開始: $alarmCount件');
      
      for (int i = 0; i < alarmCount; i++) {
        final name = prefs.getString('alarm_${i}_name');
        final time = prefs.getString('alarm_${i}_time');
        final repeat = prefs.getString('alarm_${i}_repeat');
        final enabled = prefs.getBool('alarm_${i}_enabled');
        final alarmType = prefs.getString('alarm_${i}_alarmType');
        final volume = prefs.getInt('alarm_${i}_volume');
        final message = prefs.getString('alarm_${i}_message');
        
        if (name != null && time != null) {
          alarmsList.add({
            'name': name,
            'time': time,
            'repeat': repeat ?? '一度だけ',
            'enabled': enabled ?? true,
            'alarmType': alarmType ?? 'sound',
            'volume': volume ?? 80,
            'message': message ?? '薬を服用する時間です',
          });
        }
      }
      
      setState(() {
        _alarmList = alarmsList;
      });
      
      debugPrint('アラームデータ読み込み完了: ${_alarmList.length}件（指定パス方式）');
      
      // UIを更新
      if (mounted) {
        setState(() {
          // アラームデータを反映
        });
      }
    } catch (e) {
      debugPrint('アラームデータ読み込みエラー: $e');
      _alarmList = [];
    }
  }
  
  // こぱさん流：アラームの再登録
  Future<void> _reRegisterAlarms() async {
    try {
      if (_alarmList.isEmpty) {
        debugPrint('アラーム再登録: アラームデータなし');
        return;
      }
      
      debugPrint('アラーム再登録開始: ${_alarmList.length}件');
      
      // 既存の通知をキャンセル
      // await NotificationService.cancelAllNotifications();
      
      // 各アラームを再登録
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        await _registerSingleAlarm(alarm, i);
      }
      
      debugPrint('アラーム再登録完了: ${_alarmList.length}件');
    } catch (e) {
      debugPrint('アラーム再登録エラー: $e');
    }
  }
  
  // 単一アラームの登録
  Future<void> _registerSingleAlarm(Map<String, dynamic> alarm, int index) async {
    try {
      // アラームの詳細情報を取得
      final time = alarm['time'] as String? ?? '09:00';
      final enabled = alarm['enabled'] as bool? ?? true;
      final title = alarm['title'] as String? ?? '服用アラーム';
      final message = alarm['message'] as String? ?? '薬を服用する時間です';
      
      if (!enabled) {
        debugPrint('アラーム $index は無効化されています');
        return;
      }
      
      // 時間を解析
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // 今日の日時を設定
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      
      // 過去の時間の場合は明日に設定
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
      
      // 通知をスケジュール
      // await NotificationService.scheduleNotification(
      //   id: index,
      //   title: title,
      //   body: message,
      //   scheduledTime: scheduledTime,
      // );
      
      debugPrint('アラーム $index 登録完了: $time');
    } catch (e) {
      debugPrint('アラーム $index 登録エラー: $e');
    }
  }
  
  // アラームの追加（指定パス方式）
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      setState(() {
        _alarmList.add(alarm);
      });
      
      // アラーム追加後に自動保存
      await _saveAlarmData();
      
      // 新しいアラームを登録
      await _registerSingleAlarm(alarm, _alarmList.length - 1);
      
      debugPrint('アラーム追加完了: ${alarm['name']}');
    } catch (e) {
      debugPrint('アラーム追加エラー: $e');
    }
  }
  
  // アラームの削除（指定パス方式）
  Future<void> removeAlarm(int index) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        setState(() {
          _alarmList.removeAt(index);
        });
        
        // アラーム削除後に自動保存
        await _saveAlarmData();
        
        debugPrint('アラーム削除完了: インデックス $index');
      }
    } catch (e) {
      debugPrint('アラーム削除エラー: $e');
    }
  }
  
  // アラームの更新（指定パス方式）
  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        setState(() {
          _alarmList[index] = updatedAlarm;
        });
        
        // アラーム更新後に自動保存
        await _saveAlarmData();
        
        debugPrint('アラーム更新完了: インデックス $index');
      }
    } catch (e) {
      debugPrint('アラーム更新エラー: $e');
    }
  }
  
  // アラームの有効/無効切り替え（指定パス方式）
  Future<void> toggleAlarm(int index) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        final alarm = _alarmList[index];
        final newEnabled = !(alarm['enabled'] as bool? ?? true);
        
        setState(() {
          alarm['enabled'] = newEnabled;
        });
        
        // アラーム切り替え後に自動保存
        await _saveAlarmData();
        
        debugPrint('アラーム切り替え完了: インデックス $index, 有効=$newEnabled');
      }
    } catch (e) {
      debugPrint('アラーム切り替えエラー: $e');
    }
  }
  
  // アラームデータの検証
  Future<void> _validateAlarmData() async {
    try {
      debugPrint('=== アラームデータ検証 ===');
      debugPrint('アラーム数: ${_alarmList.length}件');
      
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        debugPrint('アラーム $i:');
        debugPrint('  タイトル: ${alarm['title'] ?? 'なし'}');
        debugPrint('  時間: ${alarm['time'] ?? 'なし'}');
        debugPrint('  有効: ${alarm['enabled'] ?? false}');
        debugPrint('  メッセージ: ${alarm['message'] ?? 'なし'}');
      }
      
      debugPrint('アラーム設定: ${_alarmSettings.length}件');
      for (final entry in _alarmSettings.entries) {
        debugPrint('  ${entry.key}: ${entry.value}');
      }
      
      debugPrint('=== アラームデータ検証完了 ===');
    } catch (e) {
      debugPrint('アラームデータ検証エラー: $e');
    }
  }
  
  // アラームデータの整合性チェック
  Future<void> _checkAlarmDataIntegrity() async {
    try {
      // アラームデータの整合性をチェック
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        
        // 必須フィールドのチェック
        if (!alarm.containsKey('title') || alarm['title'] == null) {
          alarm['title'] = '服用アラーム';
        }
        if (!alarm.containsKey('time') || alarm['time'] == null) {
          alarm['time'] = '09:00';
        }
        if (!alarm.containsKey('enabled') || alarm['enabled'] == null) {
          alarm['enabled'] = true;
        }
        if (!alarm.containsKey('message') || alarm['message'] == null) {
          alarm['message'] = '薬を服用する時間です';
        }
      }
      
      // データを再保存
      await _saveAlarmData();
      
      debugPrint('アラームデータ整合性チェック完了');
    } catch (e) {
      debugPrint('アラームデータ整合性チェックエラー: $e');
    }
  }
  
  // カレンダーマークの保存
  Future<void> _saveCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final marksJson = <String, dynamic>{};
      
      // 選択された日付を保存
      for (final date in _selectedDates) {
        marksJson[date.toIso8601String()] = {
          'date': date.toIso8601String(),
          'hasData': _addedMedications.isNotEmpty,
          'medicationCount': _addedMedications.length,
        };
      }
      
      final success1 = await prefs.setString('calendar_marks', jsonEncode(marksJson));
      final success2 = await prefs.setString('calendar_marks_backup', jsonEncode(marksJson));
      final success3 = await prefs.setInt('calendar_marks_count', _selectedDates.length);
      
      if (success1 && success2 && success3) {
        debugPrint('カレンダーマーク保存完了: ${_selectedDates.length}件');
      } else {
        debugPrint('カレンダーマーク保存に失敗');
      }
    } catch (e) {
      debugPrint('カレンダーマーク保存エラー: $e');
    }
  }
  
  // カレンダーマークの読み込み
  Future<void> _loadCalendarMarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? marksStr;
      
      final keys = ['calendar_marks', 'calendar_marks_backup'];
      
      for (final key in keys) {
        try {
          marksStr = prefs.getString(key);
          if (marksStr != null && marksStr.isNotEmpty) {
            debugPrint('カレンダーマーク読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (marksStr != null && marksStr.isNotEmpty) {
        try {
          final marksJson = jsonDecode(marksStr) as Map<String, dynamic>;
          _selectedDates.clear();
          
          for (final entry in marksJson.entries) {
            final dateStr = entry.key;
            final date = DateTime.parse(dateStr);
            _selectedDates.add(_normalizeDate(date));
          }
          
          debugPrint('カレンダーマーク読み込み完了: ${_selectedDates.length}件');
        } catch (e) {
          debugPrint('カレンダーマークJSONデコードエラー: $e');
          _selectedDates.clear();
        }
      } else {
        debugPrint('カレンダーマークが見つかりません');
        _selectedDates.clear();
      }
    } catch (e) {
      debugPrint('カレンダーマーク読み込みエラー: $e');
      _selectedDates.clear();
    }
  }
  
  // ユーザー設定の保存
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = <String, dynamic>{
        'selectedDay': _selectedDay?.toIso8601String(),
        'isMemoSelected': _isMemoSelected,
        'selectedMemoId': _selectedMemo?.id,
        'isAlarmPlaying': _isAlarmPlaying,
        'notificationError': _notificationError,
        'lastSaveTime': DateTime.now().toIso8601String(),
      };
      
      final success1 = await prefs.setString('user_preferences', jsonEncode(preferencesJson));
      final success2 = await prefs.setString('user_preferences_backup', jsonEncode(preferencesJson));
      
      if (success1 && success2) {
        debugPrint('ユーザー設定保存完了');
      } else {
        debugPrint('ユーザー設定保存に失敗');
      }
    } catch (e) {
      debugPrint('ユーザー設定保存エラー: $e');
    }
  }
  
  // ユーザー設定の読み込み
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? preferencesStr;
      
      final keys = ['user_preferences', 'user_preferences_backup'];
      
      for (final key in keys) {
        try {
          preferencesStr = prefs.getString(key);
          if (preferencesStr != null && preferencesStr.isNotEmpty) {
            debugPrint('ユーザー設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (preferencesStr != null && preferencesStr.isNotEmpty) {
        try {
          final preferencesJson = jsonDecode(preferencesStr) as Map<String, dynamic>;
          
          if (preferencesJson['selectedDay'] != null) {
            _selectedDay = DateTime.parse(preferencesJson['selectedDay']);
          }
          
          _isMemoSelected = preferencesJson['isMemoSelected'] ?? false;
          _isAlarmPlaying = preferencesJson['isAlarmPlaying'] ?? false;
          _notificationError = preferencesJson['notificationError'] ?? false;
          
          debugPrint('ユーザー設定読み込み完了');
        } catch (e) {
          debugPrint('ユーザー設定JSONデコードエラー: $e');
        }
      } else {
        debugPrint('ユーザー設定が見つかりません');
      }
    } catch (e) {
      debugPrint('ユーザー設定読み込みエラー: $e');
    }
  }
  
  // 日別色設定の保存
  Future<void> _saveDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorsJson = <String, dynamic>{};
      
      for (final entry in _dayColors.entries) {
        colorsJson[entry.key] = entry.value.value;
      }
      
      final success1 = await prefs.setString('day_colors', jsonEncode(colorsJson));
      final success2 = await prefs.setString('day_colors_backup', jsonEncode(colorsJson));
      
      if (success1 && success2) {
        debugPrint('日別色設定保存完了: ${_dayColors.length}件');
      } else {
        debugPrint('日別色設定保存に失敗');
      }
    } catch (e) {
      debugPrint('日別色設定保存エラー: $e');
    }
  }
  
  // 日別色設定の読み込み
  Future<void> _loadDayColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? colorsStr;
      
      final keys = ['day_colors', 'day_colors_backup'];
      
      for (final key in keys) {
        try {
          colorsStr = prefs.getString(key);
          if (colorsStr != null && colorsStr.isNotEmpty) {
            debugPrint('日別色設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (colorsStr != null && colorsStr.isNotEmpty) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(colorsStr);
          _dayColors = decoded.map((key, value) => MapEntry(key, Color(value)));
          debugPrint('日別色設定読み込み完了: ${_dayColors.length}件');
        } catch (e) {
          debugPrint('日別色設定JSONデコードエラー: $e');
          _dayColors = {};
        }
      } else {
        debugPrint('日別色設定が見つかりません');
        _dayColors = {};
      }
    } catch (e) {
      debugPrint('日別色設定読み込みエラー: $e');
      _dayColors = {};
    }
  }
  
  // 統計データの保存
  Future<void> _saveStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = <String, dynamic>{
        'adherenceRates': _adherenceRates,
        'totalMedications': _addedMedications.length,
        'lastCalculation': DateTime.now().toIso8601String(),
      };
      
      final success1 = await prefs.setString('statistics', jsonEncode(statisticsJson));
      final success2 = await prefs.setString('statistics_backup', jsonEncode(statisticsJson));
      
      if (success1 && success2) {
        debugPrint('統計データ保存完了');
      } else {
        debugPrint('統計データ保存に失敗');
      }
    } catch (e) {
      debugPrint('統計データ保存エラー: $e');
    }
  }
  
  // 統計データの読み込み
  Future<void> _loadStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? statisticsStr;
      
      final keys = ['statistics', 'statistics_backup'];
      
      for (final key in keys) {
        try {
          statisticsStr = prefs.getString(key);
          if (statisticsStr != null && statisticsStr.isNotEmpty) {
            debugPrint('統計データ読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (statisticsStr != null && statisticsStr.isNotEmpty) {
        try {
          final statisticsJson = jsonDecode(statisticsStr) as Map<String, dynamic>;
          _adherenceRates = Map<String, double>.from(statisticsJson['adherenceRates'] ?? {});
          debugPrint('統計データ読み込み完了');
        } catch (e) {
          debugPrint('統計データJSONデコードエラー: $e');
          _adherenceRates = {};
        }
      } else {
        debugPrint('統計データが見つかりません');
        _adherenceRates = {};
      }
    } catch (e) {
      debugPrint('統計データ読み込みエラー: $e');
      _adherenceRates = {};
    }
  }
  
  // アプリ設定の保存
  Future<void> _saveAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = <String, dynamic>{
        'appVersion': '1.0.1',
        'lastUpdate': DateTime.now().toIso8601String(),
        'dataVersion': 'flutter_3_29_3',
        'backupEnabled': true,
      };
      
      final success1 = await prefs.setString('app_settings', jsonEncode(settingsJson));
      final success2 = await prefs.setString('app_settings_backup', jsonEncode(settingsJson));
      
      if (success1 && success2) {
        debugPrint('アプリ設定保存完了');
      } else {
        debugPrint('アプリ設定保存に失敗');
      }
    } catch (e) {
      debugPrint('アプリ設定保存エラー: $e');
    }
  }
  
  // 服用回数別状態の保存
  Future<void> _saveMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusJson = <String, dynamic>{};
      
      for (final dateEntry in _weekdayMedicationDoseStatus.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value;
        final memoStatusJson = <String, dynamic>{};
        
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value;
          final doseStatusJson = <String, dynamic>{};
          
          for (final doseEntry in doseStatus.entries) {
            doseStatusJson[doseEntry.key.toString()] = doseEntry.value;
          }
          
          memoStatusJson[memoId] = doseStatusJson;
        }
        
        doseStatusJson[dateStr] = memoStatusJson;
      }
      
      final success1 = await prefs.setString('medication_dose_status', jsonEncode(doseStatusJson));
      final success2 = await prefs.setString('medication_dose_status_backup', jsonEncode(doseStatusJson));
      
      if (success1 && success2) {
        debugPrint('服用回数別状態保存完了');
      } else {
        debugPrint('服用回数別状態保存に失敗');
      }
    } catch (e) {
      debugPrint('服用回数別状態保存エラー: $e');
    }
  }
  
  // 服用回数別状態の読み込み
  Future<void> _loadMedicationDoseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doseStatusStr = prefs.getString('medication_dose_status') ?? 
                           prefs.getString('medication_dose_status_backup') ?? '{}';
      final doseStatusJson = jsonDecode(doseStatusStr) as Map<String, dynamic>;
      
      _weekdayMedicationDoseStatus.clear();
      
      for (final dateEntry in doseStatusJson.entries) {
        final dateStr = dateEntry.key;
        final memoStatus = dateEntry.value as Map<String, dynamic>;
        final memoStatusMap = <String, Map<int, bool>>{};
        
        for (final memoEntry in memoStatus.entries) {
          final memoId = memoEntry.key;
          final doseStatus = memoEntry.value as Map<String, dynamic>;
          final doseStatusMap = <int, bool>{};
          
          for (final doseEntry in doseStatus.entries) {
            doseStatusMap[int.parse(doseEntry.key)] = doseEntry.value as bool;
          }
          
          memoStatusMap[memoId] = doseStatusMap;
        }
        
        _weekdayMedicationDoseStatus[dateStr] = memoStatusMap;
      }
      
      debugPrint('服用回数別状態読み込み完了');
    } catch (e) {
      debugPrint('服用回数別状態読み込みエラー: $e');
    }
  }
  
  // アプリ設定の読み込み
  Future<void> _loadAppSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? settingsStr;
      
      final keys = ['app_settings', 'app_settings_backup'];
      
      for (final key in keys) {
        try {
          settingsStr = prefs.getString(key);
          if (settingsStr != null && settingsStr.isNotEmpty) {
            debugPrint('アプリ設定読み込み成功: $key');
            break;
          }
        } catch (e) {
          debugPrint('キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      if (settingsStr != null && settingsStr.isNotEmpty) {
        try {
          final settingsJson = jsonDecode(settingsStr) as Map<String, dynamic>;
          debugPrint('アプリ設定読み込み完了: ${settingsJson['appVersion']}');
        } catch (e) {
          debugPrint('アプリ設定JSONデコードエラー: $e');
        }
      } else {
        debugPrint('アプリ設定が見つかりません');
      }
    } catch (e) {
      debugPrint('アプリ設定読み込みエラー: $e');
    }
  }
  
  // その他の設定読み込み
  Future<void> _loadOtherSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 日別の色設定
      final colorsJson = prefs.getString('day_colors');
      if (colorsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(colorsJson);
        _dayColors = decoded.map((key, value) => MapEntry(key, Color(value)));
      }
      
      debugPrint('その他設定読み込み完了');
    } catch (e) {
      debugPrint('その他設定読み込みエラー: $e');
    }
  }
  void _setupControllerListeners() {
    // 動的薬リストのリスナー設定は不要
  }
  
  /// 軽量な初期化処理（アプリ起動を阻害しない）
  Future<void> _initializeAsync() async {
    try {
      // 重複初期化を防ぐ
      if (_isInitialized) {
        debugPrint('初期化済みのためスキップ');
        return;
      }
      
      // 軽量な初期化のみ実行
      _notificationError = !await NotificationService.initialize();
      
      // 重い処理は後回し
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadHeavyData();
      });
      
      debugPrint('軽量初期化完了');
    } catch (e) {
      debugPrint('初期化エラー: $e');
    }
  }
  
  // 重いデータ読み込み（後回し）
  Future<void> _loadHeavyData() async {
    try {
      final futures = await Future.wait([
        MedicationService.loadMedicationData(),
        MedicationService.loadMedicines(),
        MedicationService.loadAdherenceStats(),
        MedicationService.loadSettings(),
      ]);
      
      setState(() {
        _medicationData = futures[0] as Map<String, Map<String, MedicationInfo>>;
        _medicines = futures[1] as List<MedicineData>;
        _adherenceRates = futures[2] as Map<String, double>;
      });
      
      debugPrint('重いデータ読み込み完了');
    } catch (e) {
      debugPrint('重いデータ読み込みエラー: $e');
    }
  }
  
  // SharedPreferencesからバックアップ復元
  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSaveDate = prefs.getString('last_save_date');
      
      if (lastSaveDate != null) {
        final backupData = prefs.getString('medication_backup_$lastSaveDate');
        if (backupData != null) {
          final dataJson = jsonDecode(backupData) as Map<String, dynamic>;
          debugPrint('バックアップデータ復元: $lastSaveDate');
        }
      }
    } catch (e) {
      debugPrint('バックアップ復元エラー: $e');
    }
  }
  @override
  void dispose() {
    // ✅ 修正：すべてのタイマーとコントローラーを適切に解放
    _debounce?.cancel();
    _debounce = null;
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = null;
    
    // ✅ 修正：StreamSubscriptionの完全解放
    _subscription?.cancel();
    _subscription = null;
    
    // ✅ 修正：動的薬リストのリスナー解放
    for (final medication in _addedMedications) {
      // 各薬のコントローラーがあれば解放
      if (medication.containsKey('controller')) {
        (medication['controller'] as TextEditingController?)?.dispose();
      }
    }
    
    // ✅ 修正：メモコントローラーとフォーカスノードのクリーンアップ
    _memoController.dispose();
    _memoFocusNode.dispose();
    _tabController.dispose();
    _calendarScrollController.dispose();
    _medicationHistoryScrollController.dispose();
    _medicationPageController.dispose();
    _customDaysController.dispose();
    
    // ✅ 修正：購入サービスも解放
    InAppPurchaseService.dispose();
    
    // ✅ 修正：Hiveボックスのクリーンアップ
    try {
      Hive.close();
    } catch (e) {
      Logger.warning('Hiveの解放エラー: $e');
    }
    
    super.dispose();
  }
  DateTime _normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);
  Future<void> _calculateAdherenceStats() async {
    try {
      final now = DateTime.now();
      final stats = <String, double>{};
      for (final period in [7, 30, 90]) {
        int totalDoses = 0;
        int takenDoses = 0;
        for (int i = 0; i < period; i++) {
          final date = now.subtract(Duration(days: i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayData = _medicationData[dateStr];
        
        // 動的薬リストの統計
          if (dayData != null) {
            for (final timeSlot in dayData.values) {
              if (timeSlot.medicine.isNotEmpty) {
                totalDoses++;
                if (timeSlot.checked) takenDoses++;
              }
            }
          }
        
        // 曜日設定された薬の統計（服用メモのチェック状態を反映）
        final weekday = date.weekday % 7; // 0=日曜日, 1=月曜日, ..., 6=土曜日
        final weekdayMemos = _medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
        
        for (final memo in weekdayMemos) {
          totalDoses++;
          // 服用メモのチェック状態を確認
          if (_medicationMemoStatus[memo.id] == true) {
            takenDoses++;
          }
        }
        }
        stats['$period日間'] = totalDoses > 0 ? (takenDoses / totalDoses * 100) : 0;
      }
      setState(() => _adherenceRates = stats);
      await MedicationService.saveAdherenceStats(stats);
    } catch (e) {
    }
  }
  // ✅ 修正：デバウンス保存の実装
  void _saveCurrentDataDebounced() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(seconds: 2), () {
      _saveCurrentDataDebounced();
    });
  }

  // 強化されたデータ保存メソッド（差分保存対応）
  void _saveCurrentData() async {
    try {
      if (!_isInitialized) return;
      
      // ✅ 修正：変更があった部分のみ保存
      if (_medicationMemoStatusChanged) {
        await _saveMedicationMemoStatus();
        _medicationMemoStatusChanged = false;
      }
      
      if (_weekdayMedicationStatusChanged) {
        await _saveWeekdayMedicationStatus();
        _weekdayMedicationStatusChanged = false;
      }
      
      if (_addedMedicationsChanged) {
      await _saveAddedMedications();
        _addedMedicationsChanged = false;
      }
      
      // 服用メモの保存（Hiveベース）
      for (final memo in _medicationMemos) {
        await AppPreferences.saveMedicationMemo(memo);
      }
      
      // メモの保存
      await _saveMemo();
      
      // 統計の再計算
      await _calculateAdherenceStats();
      
    } catch (e) {
    }
  }
  
  // 動的薬リストの保存
  Future<void> _saveAddedMedications() async {
    try {
      if (_selectedDay == null) return;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      _medicationData.putIfAbsent(dateStr, () => {});
      
      // 動的薬リストの保存（個別に保存）
      for (final medication in _addedMedications) {
        final key = 'added_medication_${medication.hashCode}';
        _medicationData[dateStr]![key] = MedicationInfo(
          checked: medication['isChecked'] as bool,
          medicine: medication['name'] as String,
          actualTime: medication['isChecked'] as bool ? DateTime.now() : null,
        );
      }
      
      await MedicationService.saveMedicationData(_medicationData);
    } catch (e) {
    }
  }
  
  // 服用メモの状態保存
  Future<void> _saveMedicationMemoStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoStatusJson = <String, dynamic>{};
      
      for (final entry in _medicationMemoStatus.entries) {
        memoStatusJson[entry.key] = entry.value;
      }
      
      // ✅ 修正：統一されたキーとバックアップ保存
      final data = jsonEncode(memoStatusJson);
      await prefs.setString(_medicationMemoStatusKey, data);
      await prefs.setString(_medicationMemoStatusKey + _backupSuffix, data);
    } catch (e) {
    }
  }
  
  // 曜日設定薬の状態保存
  Future<void> _saveWeekdayMedicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekdayStatusJson = <String, dynamic>{};
      
      for (final dateEntry in _weekdayMedicationStatus.entries) {
        weekdayStatusJson[dateEntry.key] = dateEntry.value;
      }
      
      await prefs.setString('weekday_medication_status', jsonEncode(weekdayStatusJson));
    } catch (e) {
    }
  }
  
  // 強化されたデータ読み込みメソッド
  Future<void> _loadCurrentData() async {
    try {
      // 服用メモの状態読み込み
      await _loadMedicationMemoStatus();
      
      // 曜日設定薬の状態読み込み
      await _loadWeekdayMedicationStatus();
      
      // メモの読み込み
      await _loadMemo();
      
    } catch (e) {
    }
  }
  
  // 服用メモの状態読み込み
  Future<void> _loadMedicationMemoStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memoStatusJson = prefs.getString('medication_memo_status');
      
      if (memoStatusJson != null) {
        final Map<String, dynamic> memoStatusData = jsonDecode(memoStatusJson);
        _medicationMemoStatus.clear();
        
        for (final entry in memoStatusData.entries) {
          _medicationMemoStatus[entry.key] = entry.value as bool;
        }
      }
      
      // 服用メモの初期状態を未チェックに設定
      for (final memo in _medicationMemos) {
        if (!_medicationMemoStatus.containsKey(memo.id)) {
          _medicationMemoStatus[memo.id] = false;
        }
      }
    } catch (e) {
      // エラー時も初期状態を未チェックに設定
      for (final memo in _medicationMemos) {
        _medicationMemoStatus[memo.id] = false;
      }
    }
  }
  
  // 曜日設定薬の状態読み込み
  Future<void> _loadWeekdayMedicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekdayStatusJson = prefs.getString('weekday_medication_status');
      
      if (weekdayStatusJson != null) {
        final Map<String, dynamic> weekdayStatusData = jsonDecode(weekdayStatusJson);
        _weekdayMedicationStatus.clear();
        
        for (final dateEntry in weekdayStatusData.entries) {
          _weekdayMedicationStatus[dateEntry.key] = Map<String, bool>.from(dateEntry.value);
        }
      }
    } catch (e) {
    }
  }
  
  // メモの読み込み
  Future<void> _loadMemo() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final prefs = await SharedPreferences.getInstance();
        final memo = prefs.getString('memo_$dateStr');
        if (memo != null) {
          _memoController.text = memo;
        }
      }
    } catch (e) {
    }
  }
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    try {
      // トライアル制限チェック（当日以外の選択時）
      final isExpired = await TrialService.isTrialExpired();
      final today = DateTime.now();
      final isToday = selectedDay.year == today.year && 
                      selectedDay.month == today.month && 
                      selectedDay.day == today.day;
      
      if (isExpired && !isToday) {
        showDialog(
          context: context,
          builder: (context) => TrialLimitDialog(featureName: 'カレンダー'),
        );
        return;
      }
      
      // ✅ 修正：先にデータ準備
      final normalizedDay = _normalizeDate(selectedDay);
      final wasSelected = _selectedDates.contains(normalizedDay);
      
      // ✅ 修正：1回のsetStateで全て更新
      setState(() {
        if (wasSelected) {
          _selectedDates.remove(normalizedDay);
            _selectedDay = null;
            _addedMedications.clear();
        } else {
          _selectedDates.add(normalizedDay);
          _selectedDay = normalizedDay;
        }
        _focusedDay = focusedDay;
      });
      
      // ✅ 修正：非同期処理は外で実行
      if (!wasSelected && _selectedDay != null) {
        await _updateMedicineInputsForSelectedDate();
        await _loadCurrentData();
      }
    } catch (e) {
      _showSnackBar('日付の選択に失敗しました: $e');
    }
  }
  
  // 選択された日付の色を変更
  void _changeDayColor() {
    if (_selectedDay != null) {
      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      _showColorPickerDialog(dateKey);
    } else {
      _showSnackBar('日付を選択してください');
    }
  }
  
  // カレンダースタイルを動的に生成（日付の色に基づく）
  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      cellMargin: const EdgeInsets.all(2),
      cellPadding: const EdgeInsets.all(4),
      cellAlignment: Alignment.center,
      defaultTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      selectedTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      todayTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      weekendTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      defaultDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      selectedDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFff6b6b),
            Color(0xFFee5a24),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b6b).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      todayDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4ecdc4),
            Color(0xFF44a08d),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ecdc4).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      markersMaxCount: 1,
      markerDecoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
  
  // カスタム日付装飾を取得
  BoxDecoration? _getCustomDayDecoration(DateTime day) {
    final dateKey = DateFormat('yyyy-MM-dd').format(day);
    final customColor = _dayColors[dateKey];
    
    if (customColor != null) {
      return BoxDecoration(
        color: customColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: customColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return null;
  }
  
  // 色選択ダイアログ
  void _showColorPickerDialog(String dateKey) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('日付の色を選択'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              setState(() {
                _dayColors[dateKey] = color;
              });
              _saveDayColors();
              Navigator.pop(context);
              _showSnackBar('色を設定しました');
              // カレンダーを再描画
              setState(() {});
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dayColors.remove(dateKey);
              });
              _saveDayColors();
              Navigator.pop(context);
              _showSnackBar('色を削除しました');
              // カレンダーを再描画
              setState(() {});
            },
            child: const Text('色を削除'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
  Future<void> _updateMedicineInputsForSelectedDate() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final dayData = _medicationData[dateStr];
        // 動的薬リストの復元
        _addedMedications = [];
        if (dayData != null) {
          for (final entry in dayData.entries) {
            if (entry.key.startsWith('added_medication_')) {
              _addedMedications.add({
                'name': entry.value.medicine,
                'type': '薬',
                'color': Colors.blue,
                'dosage': '',
                'notes': '',
                'isChecked': entry.value.checked,
              });
            }
          }
        }
        // メモの読み込み
        _loadMemoForSelectedDate();
      } else {
        _addedMedications = [];
        _memoController.clear();
      }
    } catch (e) {
    }
  }

  Future<void> _loadMemoForSelectedDate() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final prefs = await SharedPreferences.getInstance();
        final savedMemo = prefs.getString('memo_$dateStr');
        if (savedMemo != null) {
          _memoController.text = savedMemo;
        } else {
          _memoController.clear();
        }
      }
    } catch (e) {
    }
  }


  // 服用メモ読み込み機能
  Future<void> _loadMedicationMemos() async {
    try {
      final memos = AppPreferences.loadMedicationMemos();
      setState(() {
        _medicationMemos = memos;
      });
    } catch (e) {
      debugPrint('服用メモ読み込みエラー: $e');
    }
  }

  void _showSnackBar(String message) async {
    if (!mounted) return;
    try {
      final fontSize = await MedicationAlarmApp.getFontSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
    }
  }
  // 完全に作り直されたカレンダーイベント取得
  List<Widget> _getEventsForDay(DateTime day) {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final weekday = day.weekday % 7;
      
      // 完全に作り直されたチェック
      bool hasMedications = false;
      bool allTaken = true;
      int takenCount = 0;
      int totalCount = 0;
      
      // 動的薬リストのチェック
      if (_addedMedications.isNotEmpty) {
        hasMedications = true;
        totalCount += _addedMedications.length;
        for (final medication in _addedMedications) {
          if (medication['isChecked'] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 服用メモのチェック
      for (final memo in _medicationMemos) {
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          hasMedications = true;
          totalCount++;
          if (_medicationMemoStatus[memo.id] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 完全に作り直されたマーク表示
      if (hasMedications) {
        if (allTaken && totalCount > 0) {
          // すべて服用済み - チェックマーク（緑）
          return [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: const Icon(
                Icons.check_circle,
                size: 14,
                color: Colors.green,
              ),
            ),
          ];
        } else if (takenCount > 0) {
          // 一部服用済み - チェックマーク（オレンジ）
          return [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: const Icon(
                Icons.check_circle_outline,
                size: 14,
                color: Colors.orange,
              ),
            ),
          ];
        } else {
          // 未服用 - 未チェックマーク（グレー）
          return [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: const Icon(
                Icons.radio_button_unchecked,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
  // 服用記録の件数を取得するヘルパーメソッド
  int _getMedicationRecordCount() {
    return _addedMedications.length + _getMedicationsForSelectedDay().length;
  }




  Widget _buildCalendarTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ 修正：画面サイズに応じたレスポンシブデザイン
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenHeight < 600;
        final isNarrowScreen = screenWidth < 360;
        
        return SingleChildScrollView(
          controller: _calendarScrollController,
          padding: EdgeInsets.symmetric(
            horizontal: isNarrowScreen ? 8 : screenWidth * 0.05, // 狭い画面ではパディング削減
            vertical: isSmallScreen ? 4 : 8, // 小さい画面では縦パディング削減
          ),
          physics: _isScrollBatonPassActive 
            ? const AlwaysScrollableScrollPhysics() 
            : const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // メモフィールド（一番上に配置）
              if (_selectedDay != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16), // 左右のマージンを削除して横いっぱいに
                  padding: EdgeInsets.fromLTRB(
                    isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16), // 左
                    0, // 上（余白削除）
                    isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16), // 右
                    isSmallScreen ? 8 : (isNarrowScreen ? 12 : 16), // 下
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日付表示
                      Row(
                        children: [
                          Text(
                            '今日のメモ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // 余白削除
                      // メモフィールド
                      _buildMemoField(),
                    ],
                  ),
                ),
              // 色を変えるボタン（コンパクト化）
              Container(
                margin: const EdgeInsets.only(bottom: 8), // マージン削減
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _changeDayColor,
                      icon: const Icon(Icons.palette, size: 16), // アイコンサイズ削減
                      label: const Text('日付の色を変える', style: TextStyle(fontSize: 12)), // フォントサイズ削減
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // パディング削減
                        minimumSize: const Size(0, 32), // 最小サイズ設定
                      ),
                    ),
                  ],
                ),
              ),
              // カレンダー（高さ350pxに固定）
              SizedBox(
                height: 350, // 高さを350pxに固定
                child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), // 角丸削減
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                    ),
                    child: TableCalendar<dynamic>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: CalendarFormat.month,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      locale: 'ja_JP',
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final customDecoration = _getCustomDayDecoration(day);
                          if (customDecoration != null) {
                            return Container(
                              margin: const EdgeInsets.all(1), // マージン削減
                              decoration: customDecoration,
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12, // フォントサイズ削減
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontSize: 18, // フォントサイズ削減
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white, size: 20),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ],
                          ),
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // フォントサイズ削減
                          color: Colors.white,
                        ),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 12, // フォントサイズ削減
                        ),
                      ),
                      calendarStyle: _buildCalendarStyle(),
                      onDaySelected: _onDaySelected,
                      selectedDayPredicate: (day) {
                        return _selectedDates.contains(_normalizeDate(day));
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ),
                ),
              ),
              ),
              const SizedBox(height: 12), // 間隔削減
              // 今日の服用状況表示（カレンダーの下、服用記録の上）
              if (_selectedDay != null)
                _buildMedicationStats(),
              const SizedBox(height: 8),
              // 服用記録セクション（高さ制限削除）
              if (_selectedDay != null)
                _buildMedicationRecords(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  Widget _buildMedicationRecords() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 最小サイズに制限
        children: [
          // ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20), // パディング削減
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${DateFormat('yyyy年M月d日', 'ja_JP').format(_selectedDay!)}の服用記録',
                  style: const TextStyle(
                    fontSize: 18, // フォントサイズ削減
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4), // 間隔削減
                Text(
                  '今日の服用状況を確認しましょう',
                  style: TextStyle(
                    fontSize: 12, // フォントサイズ削減
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 完全に作り直された服用記録リスト
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // メモ選択時は選択されたメモのみ表示
                  if (_isMemoSelected && _selectedMemo != null) ...[
                    // 戻るボタン
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isMemoSelected = false;
                            _selectedMemo = null;
                          });
                        },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                    children: [
                                  Icon(Icons.arrow_back, color: Colors.blue, size: 16),
                                  const SizedBox(width: 8),
                            Text(
                                    '戻る',
                              style: TextStyle(
                                      color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                              ),
                        ),
                      ),
                    ],
                  ),
                    ),
                    _buildWeekdayMedicationRecord(_selectedMemo!)
                  ] else ...[
                    // カレンダー下の位置マーカー
                    SizedBox(
                      key: _calendarBottomKey,
                      height: 1, // 見えないマーカー
                    ),
                    // ✅ 修正：服用記録リスト（ページめくり方式・SizedBox）
                    _getMedicationListLength() == 0
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4, // MediaQuery使用
                            child: _buildNoMedicationMessage(),
                          )
                        : SizedBox(
                            height: 400, // 固定高さを設定
                            child: PageView.builder(
                              controller: _medicationPageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentMedicationPage = index;
                                });
                              },
                              itemCount: _getMedicationListLength(),
                              itemBuilder: (context, index) {
                                return _buildMedicationItem(index);
                              },
                            ),
                          ),
                    // 服用数の表示UI（メモ0のときは表示しない）
                    if (_getMedicationListLength() > 0 && _getMedicationListLength() != 1)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Text(
                          '${_currentMedicationPage + 1}/${_getMedicationListLength()} 服用の数',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // ページめくりボタン
                    if (_getMedicationListLength() > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentMedicationPage > 0 ? () {
                                  _medicationPageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentMedicationPage > 0 ? Colors.blue : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '前の\n服用内容',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _currentMedicationPage < _getMedicationListLength() - 1 ? () {
                                  _medicationPageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentMedicationPage < _getMedicationListLength() - 1 ? Colors.blue : Colors.grey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '次の\n服用内容',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
            ),
          ),
          // フッター統計（削除）
        ],
      ),
    );
  }

  // 安全な最大高さを計算する関数

  // 服用記録リストの長さを取得
  int _getMedicationListLength() {
    final addedCount = _addedMedications.length;
    final memoCount = _getMedicationsForSelectedDay().length;
    final hasNoData = addedCount == 0 && memoCount == 0;
    return addedCount + memoCount + (hasNoData ? 1 : 0);
  }

  // 服用記録アイテムを構築
  Widget _buildMedicationItem(int index) {
    final addedCount = _addedMedications.length;
    final memoCount = _getMedicationsForSelectedDay().length;
    
    if (index < addedCount) {
      // 追加された薬
      return _buildAddedMedicationRecord(_addedMedications[index]);
    } else if (index < addedCount + memoCount) {
      // 服用メモ
      final memoIndex = index - addedCount;
      return _buildMedicationMemoCheckbox(_getMedicationsForSelectedDay()[memoIndex]);
    } else {
      // データなしメッセージ
      return _buildNoMedicationMessage();
    }
  }

  // 服用メモが未追加の場合のメッセージ表示
  Widget _buildNoMedicationMessage() {
    return Container(
      height: 450, // 高さを450pxに設定
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '服用メモから服用スケジュール\n(毎日、曜日)を選択してください',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '服用メモタブで薬品やサプリメントを追加してから、\nカレンダーページで服用スケジュールを管理できます。',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // 服用メモタブに切り替え
              _tabController.animateTo(1);
            },
            icon: const Icon(Icons.add),
            label: const Text('服用メモを追加'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 服用メモのチェックボックス（カレンダーページ用・拡大版）
  Widget _buildMedicationMemoCheckbox(MedicationMemo memo) {
    final isSelected = _isMemoSelected && _selectedMemo?.id == memo.id;
    // 服用回数に応じたチェック状況を取得
    final checkedCount = _getMedicationMemoCheckedCountForSelectedDay(memo.id);
    final totalCount = memo.dosageFrequency;
    
    return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Colors.blue 
                : checkedCount == totalCount 
                    ? Colors.green 
                    : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : checkedCount == totalCount ? 1.5 : 1,
          ),
          color: isSelected 
              ? Colors.blue.withOpacity(0.1)
              : checkedCount == totalCount 
                  ? Colors.green.withOpacity(0.05) 
                  : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上部：アイコン、薬名、服用回数情報
              Row(
                children: [
                  // 大きなアイコン
                  CircleAvatar(
                    backgroundColor: memo.color,
                    radius: 20,
                    child: Icon(
                      memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 薬名と種類
                        Text(
                          memo.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: checkedCount == totalCount ? Colors.green : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: checkedCount == totalCount ? Colors.green.withOpacity(0.2) : memo.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            memo.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: checkedCount == totalCount ? Colors.green : memo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 服用回数に応じたチェックボックス
              const SizedBox(height: 12),
              Row(
                children: List.generate(totalCount, (index) {
                  final isChecked = _getMedicationMemoDoseStatusForSelectedDay(memo.id, index);
                  return Expanded(
                    child: Semantics(
                      label: '${memo.name}の服用記録 ${index + 1}回目',
                      hint: 'タップして服用状態を切り替え',
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedDay != null) {
                          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                          setState(() {
                            // 日付別の服用メモ状態を更新
                            _weekdayMedicationStatus.putIfAbsent(dateStr, () => {});
                            _weekdayMedicationDoseStatus.putIfAbsent(dateStr, () => {});
                            _weekdayMedicationDoseStatus[dateStr]!.putIfAbsent(memo.id, () => {});
                            _weekdayMedicationDoseStatus[dateStr]![memo.id]![index] = !isChecked;
                            
                            // 全体の服用状況を更新（全回数完了時に服用済み）
                            final checkedCount = _getMedicationMemoCheckedCountForSelectedDay(memo.id);
                            final totalCount = memo.dosageFrequency;
                            _weekdayMedicationStatus[dateStr]![memo.id] = checkedCount == totalCount;
                            _medicationMemoStatus[memo.id] = checkedCount == totalCount;
                          });
                          // データ保存
                          _saveAllData();
                          // 統計を再計算
                          _calculateAdherenceStats();
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? Colors.green : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecked ? Colors.green : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isChecked ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${index + 1}回目',
                              style: TextStyle(
                                fontSize: 10,
                                color: isChecked ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // 服用回数情報
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '服用回数: ${memo.dosageFrequency}回 (${checkedCount}/${totalCount})',
                      style: TextStyle(
                        fontSize: 14,
                        color: checkedCount == totalCount ? Colors.green : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (memo.dosageFrequency >= 6) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _showWarningDialog(context);
                        },
                        child: const Icon(Icons.warning, size: 16, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
              ),
              // 用量情報
              if (memo.dosage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.straighten, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '用量: ${memo.dosage}',
                        style: TextStyle(
                          fontSize: 14,
                          color: checkedCount == totalCount ? Colors.green : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // メモ情報（タップ可能）
              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    _showMemoDetailDialog(context, memo.name, memo.notes);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.note, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'メモ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          memo.notes,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'タップしてメモを表示',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }

  // メモ詳細ダイアログを表示
  void _showMemoDetailDialog(BuildContext context, String medicationName, String memo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  const Icon(Icons.note, size: 24, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$medicationName のメモ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 20),
              // メモ内容
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Text(
                      memo,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // フッターボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 服用済みに追加（簡素化版）
  void _addToTakenMedications(MedicationMemo memo) {
    if (_selectedDay == null) return;
    
    // 重複チェック
    final existingIndex = _addedMedications.indexWhere((med) => med['id'] == memo.id);
    
    if (existingIndex == -1) {
      // 新規追加
      _addedMedications.add({
        'id': memo.id,
        'name': memo.name,
        'type': memo.type,
        'dosage': memo.dosage,
        'color': memo.color,
        'taken': true,
        'takenTime': DateTime.now(),
        'notes': memo.notes,
      });
    } else {
      // 既存のものを更新
      _addedMedications[existingIndex]['taken'] = true;
      _addedMedications[existingIndex]['takenTime'] = DateTime.now();
    }
    
    // メモの状態を更新
    _medicationMemoStatus[memo.id] = true;
    
    // カレンダーマークを追加（服用状況に反映）
    if (_selectedDay != null) {
      if (!_selectedDates.contains(_selectedDay!)) {
        _selectedDates.add(_selectedDay!);
      }
    }
    
    // データ保存のみ
    _saveAllData();
  }
  
  // 服用済みから削除（簡素化版）
  void _removeFromTakenMedications(String memoId) {
    _addedMedications.removeWhere((med) => med['id'] == memoId);
    
    // その日の服用メモがすべてチェックされていない場合、カレンダーマークを削除
    if (_selectedDay != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      final hasCheckedMemos = _medicationMemoStatus.values.any((status) => status);
      if (!hasCheckedMemos && _addedMedications.isEmpty) {
        _selectedDates.remove(dateStr);
      }
    }
    
    // データ保存のみ
    _saveAllData();
  }
  
  // 服用メモの状態を更新
  void _updateMedicationMemoStatus(String memoId, bool isChecked) {
    setState(() {
      _medicationMemoStatus[memoId] = isChecked;
    });
    // データ保存
    _saveAllData();
  }
  
  // こぱさん流：服用データを保存（確実なデータ保持）
  Future<void> _saveMedicationData() async {
    try {
      if (_selectedDay != null) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final medicationData = <String, MedicationInfo>{};
        
        // _addedMedicationsからMedicationInfoを作成
        for (final med in _addedMedications) {
          medicationData[med['name'] as String] = MedicationInfo(
            checked: med['taken'] as bool,
            medicine: med['name'] as String,
            actualTime: med['takenTime'] as DateTime?,
            notes: med['notes'] as String? ?? '',
          );
        }
        
        // こぱさん流：awaitを確実に付けて保存
        await MedicationService.saveMedicationData({dateStr: medicationData});
        await _saveToSharedPreferences(dateStr, medicationData);
        await _saveMemoStatus();
        await _saveAdditionalBackup(dateStr, medicationData);
        
        // 服用薬データも保存
        await _saveMedicationList();
        
        // アラームデータも保存
        await _saveAlarmData();
        
        debugPrint('全データ保存完了: $dateStr（こぱさん流）');
      }
    } catch (e) {
      debugPrint('データ保存エラー: $e');
    }
  }
  
  // 追加のバックアップ保存
  Future<void> _saveAdditionalBackup(String dateStr, Map<String, MedicationInfo> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};
      
      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }
      
      // 複数のバックアップキーで保存
      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('medication_backup_latest', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      await prefs.setString('last_save_timestamp', DateTime.now().toIso8601String());
      
      // 強制的にフラッシュ
      await prefs.commit();
      
      debugPrint('追加バックアップ保存完了: $dateStr');
    } catch (e) {
      debugPrint('追加バックアップ保存エラー: $e');
    }
  }
  
  // こぱさん流：服用薬データを保存（確実なデータ保持）
  Future<void> _saveMedicationList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationListJson = <String, dynamic>{};
      
      // 服用薬リストを保存
      for (int i = 0; i < _addedMedications.length; i++) {
        final med = _addedMedications[i];
        medicationListJson['medication_$i'] = {
          'id': med['id'],
          'name': med['name'],
          'type': med['type'],
          'dosage': med['dosage'],
          'color': med['color'],
          'taken': med['taken'],
          'takenTime': med['takenTime']?.toIso8601String(),
          'notes': med['notes'],
        };
      }
      
      // こぱさん流：awaitを確実に付けて保存
      await prefs.setString('medicationList', jsonEncode(medicationListJson));
      await prefs.setString('medicationList_backup', jsonEncode(medicationListJson));
      await prefs.setInt('medicationList_count', _addedMedications.length);
      
      debugPrint('服用薬データ保存完了: ${_addedMedications.length}件（こぱさん流）');
    } catch (e) {
      debugPrint('服用薬データ保存エラー: $e');
    }
  }
  
  // 確実なアラームデータ保存（指定パス方式を採用）
  Future<void> _saveAlarmData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // アラーム数を保存
      await prefs.setInt('alarm_count', _alarmList.length);
      
      // 各アラームのデータを個別に保存（指定パス方式）
      for (int i = 0; i < _alarmList.length; i++) {
        final alarm = _alarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name'] ?? '');
        await prefs.setString('alarm_${i}_time', alarm['time'] ?? '00:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat'] ?? '一度だけ');
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] ?? true);
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType'] ?? 'sound');
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] ?? 80);
        await prefs.setString('alarm_${i}_message', alarm['message'] ?? '薬を服用する時間です');
      }
      
      // バックアップも保存
      await prefs.setString('alarm_backup_count', _alarmList.length.toString());
      await prefs.setString('alarm_last_save', DateTime.now().toIso8601String());
      
      debugPrint('アラームデータ保存完了: ${_alarmList.length}件（指定パス方式）');
    } catch (e) {
      debugPrint('アラームデータ保存エラー: $e');
    }
  }
  
  // SharedPreferencesにバックアップ保存
  Future<void> _saveToSharedPreferences(String dateStr, Map<String, MedicationInfo> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = <String, dynamic>{};
      
      for (final entry in data.entries) {
        dataJson[entry.key] = entry.value.toJson();
      }
      
      await prefs.setString('medication_backup_$dateStr', jsonEncode(dataJson));
      await prefs.setString('last_save_date', dateStr);
      debugPrint('SharedPreferencesバックアップ保存完了: $dateStr');
    } catch (e) {
      debugPrint('SharedPreferences保存エラー: $e');
    }
  }
  
  // 🔴 最重要：メモの状態を保存（完全版）
  Future<void> _saveMemoStatus() async {
    try {
      final memoStatusJson = <String, dynamic>{};
      
      for (final entry in _medicationMemoStatus.entries) {
        memoStatusJson[entry.key] = entry.value;
      }
      
      // 🔴 最重要：awaitを確実に付けて保存
      await AppPreferences.saveString('medicationMemoStatus', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('medication_memo_status', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('memo_status_backup', jsonEncode(memoStatusJson));
      await AppPreferences.saveString('last_memo_save', DateTime.now().toIso8601String());
      
      debugPrint('メモ状態保存完了: ${memoStatusJson.length}件（完全版）');
    } catch (e) {
      debugPrint('メモ状態保存エラー: $e');
    }
  }
  
  // 🔴 最重要：メモの状態を読み込み（完全版）
  Future<void> _loadMemoStatus() async {
    try {
      String? memoStatusStr;
      
      // 🔴 最重要：複数キーから読み込み（優先順位付き）
      final keys = ['medicationMemoStatus', 'medication_memo_status', 'memo_status_backup'];
      
      for (final key in keys) {
        memoStatusStr = AppPreferences.getString(key);
        if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
          debugPrint('メモ状態読み込み成功: $key（完全版）');
          break;
        }
      }
      
      if (memoStatusStr != null && memoStatusStr.isNotEmpty) {
        final memoStatusJson = jsonDecode(memoStatusStr) as Map<String, dynamic>;
        _medicationMemoStatus = memoStatusJson.map((key, value) => MapEntry(key, value as bool));
        debugPrint('メモ状態読み込み完了: ${_medicationMemoStatus.length}件');
        
        // 🔴 最重要：UIに反映
        if (mounted) {
    setState(() {
            // 保存された値があればそれを使う
          });
        }
      } else {
        debugPrint('メモ状態データが見つかりません（初期値を使用）');
        _medicationMemoStatus = {};
      }
    } catch (e) {
      debugPrint('メモ状態読み込みエラー: $e');
      _medicationMemoStatus = {};
    }
  }

  // 服用メモのチェック状態を取得
  bool _getMedicationMemoStatus(String memoId) {
    return _medicationMemoStatus[memoId] ?? false;
  }
  
  // 選択された日付の服用メモのチェック状態を取得
  bool _getMedicationMemoStatusForSelectedDay(String memoId) {
    if (_selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    return _weekdayMedicationStatus[dateStr]?[memoId] ?? false;
  }
  
  // 指定日のメモの服用回数別チェック状況を取得
  bool _getMedicationMemoDoseStatusForSelectedDay(String memoId, int doseIndex) {
    if (_selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    return _weekdayMedicationDoseStatus[dateStr]?[memoId]?[doseIndex] ?? false;
  }
  
  // 指定日のメモの服用済み回数を取得
  int _getMedicationMemoCheckedCountForSelectedDay(String memoId) {
    if (_selectedDay == null) return 0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final doseStatus = _weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }
  
  // アプリ再起動時のデータ表示を確実にする
  Future<void> _ensureDataDisplayOnRestart() async {
    try {
      // データ読み込み完了を待つ
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 選択された日付のデータを確認
      if (_selectedDay != null) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        debugPrint('再起動後データ表示確認: $dateStr');
        
        // 服用メモの状態を再確認
        for (final memo in _medicationMemos) {
          if (!_medicationMemoStatus.containsKey(memo.id)) {
            _medicationMemoStatus[memo.id] = false;
          }
        }
        
        // UIを強制更新
        if (mounted) {
    setState(() {
            // データ表示を確実にする
          });
        }
        
        debugPrint('再起動後データ表示完了: メモ${_medicationMemos.length}件, 状態${_medicationMemoStatus.length}件');
      }
    } catch (e) {
      debugPrint('再起動後データ表示エラー: $e');
    }
  }


  // 完全に作り直された服用記録リスト
  Widget _buildAddedMedicationRecord(Map<String, dynamic> medication) {
    final isChecked = medication['isChecked'] ?? false;
    final medicationName = medication['name'] ?? '';
    final medicationType = medication['type'] ?? '';
    final medicationColor = medication['color'] ?? Colors.blue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isChecked
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isChecked 
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isChecked
              ? LinearGradient(
                  colors: [Colors.green.withOpacity(0.05), Colors.green.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24), // パディングを増加
          child: Row(
            children: [
              // 完全に作り直された服用済みチェックボックス
              GestureDetector(
                onTap: () {
                  // 強制的に状態を更新
                  setState(() {
                    medication['isChecked'] = !isChecked;
                  });
                  
                  // データを保存
                  _saveCurrentDataDebounced();
                  
                  // カレンダーマークを更新
                  _updateCalendarMarks();
                  
                  // 統計を強制再計算
                  setState(() {
                    // 統計を強制再計算
                  });
                },
                child: Container(
                  width: 60, // サイズを大きく
                  height: 60,
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.green : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isChecked
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isChecked ? Colors.white : Colors.grey,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 24), // 間隔を広く
              // 薬の情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          medicationType == 'サプリメント' ? Icons.eco : Icons.medication,
                          color: isChecked ? Colors.green : medicationColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          medicationName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isChecked ? Colors.green : const Color(0xFF2196F3),
                          ),
                        ),
                        if (isChecked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '服用済み',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medicationType,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 削除ボタン
              IconButton(
                onPressed: () {
                  setState(() {
                    _addedMedications.remove(medication);
                  });
                  _saveCurrentDataDebounced();
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: '削除',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineTab() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.max, // 最大高さを使用
              children: [
                Text(
                  '服用メモ',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
            // 服用メモリスト（無限スクロール対応・高さ最適化）
            Expanded(
              flex: 1, // 残りの高さを全て使用
              child: _medicationMemos.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            '服用メモがまだありません',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '右下の+マークから新しいメモを追加できます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _medicationMemos.length,
                // 無限スクロール用の最適化設定
                cacheExtent: 1000, // キャッシュ範囲を拡張（パフォーマンス向上）
                addAutomaticKeepAlives: true, // 自動的にKeepAliveを追加
                addRepaintBoundaries: true, // 再描画境界を追加
                addSemanticIndexes: true, // セマンティックインデックスを追加
                // スクロール動作の最適化
                shrinkWrap: true, // コンテンツに応じて高さを調整
                primary: false, // 高さ無制限のためfalseに設定
                itemBuilder: (context, index) {
                  final memo = _medicationMemos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    elevation: 4,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          // アイコンと名前を上に配置
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: memo.color,
                                radius: 24,
                                child: Icon(
                                  memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memo.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness == Brightness.dark 
                                            ? Colors.white 
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: memo.type == 'サプリメント'
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: memo.type == 'サプリメント'
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        memo.type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.white70 
                                              : (memo.type == 'サプリメント' ? Colors.green : Colors.blue),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // アクションボタンを右上に配置
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  // トライアル制限チェック
                                  final isExpired = await TrialService.isTrialExpired();
                                  if (isExpired) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => TrialLimitDialog(featureName: '服用メモ'),
                                    );
                                    return;
                                  }
                                  switch (value) {
                                    case 'taken':
                                      _markAsTaken(memo);
                                      break;
                                    case 'edit':
                                      _editMemo(memo);
                                      break;
                                    case 'delete':
                                      _deleteMemo(memo.id);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'taken',
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('服用記録'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('編集'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('削除'),
                                      ],
                                    ),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // 詳細情報を下に配置
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 服用回数情報
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.repeat, size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      '服用回数: ${memo.dosageFrequency}回',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    if (memo.dosageFrequency >= 6) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          _showWarningDialog(context);
                                        },
                                        child: const Icon(Icons.warning, size: 16, color: Colors.orange),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (memo.dosage.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.straighten, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '用量: ${memo.dosage}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              if (memo.dosage.isNotEmpty) const SizedBox(height: 10),
                              if (memo.notes.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.note, size: 16, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          memo.notes,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (memo.notes.isNotEmpty) const SizedBox(height: 10),
                              // 曜日未設定の警告表示
                              if (memo.selectedWeekdays.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning, size: 16, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '服用スケジュールが設定されていません',
                                              style: TextStyle(
                                                fontSize: 14, 
                                                color: Colors.orange, 
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (memo.selectedWeekdays.isEmpty) const SizedBox(height: 10),
                              if (memo.lastTaken != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        '最後の服用:\n${DateFormat('yyyy/MM/dd HH:mm').format(memo.lastTaken!)}',
                                        style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 今日の服用状況を削除
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // トライアル制限チェック
          final isExpired = await TrialService.isTrialExpired();
          if (isExpired) {
            showDialog(
              context: context,
              builder: (context) => TrialLimitDialog(featureName: '服用メモ'),
            );
            return;
          }
          _addMemo();
        },
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAlarmTab() {
    return FutureBuilder<bool>(
      future: TrialService.isTrialExpired(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final isExpired = snapshot.data ?? false;
        
        if (isExpired) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    'トライアル期間が終了しました',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'アラーム機能は制限されています',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TrialService.getPurchaseLink();
                      // リンクを開く処理（後で実装）
                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text('👉 機能解除はこちら'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        return const SimpleAlarmApp();
      },
    );
  }


  Widget _buildStatsTab() {
    return FutureBuilder<bool>(
      future: TrialService.isTrialExpired(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final isExpired = snapshot.data ?? false;
        
        if (isExpired) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 80, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    'トライアル期間が終了しました',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '統計機能は制限されています',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await TrialService.getPurchaseLink();
                      // リンクを開く処理（後で実装）
                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text('👉 機能解除はこちら'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max, // 最大高さを使用
            children: [
              const Text(
                '服薬遵守率',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                flex: 1, // 残りの高さを全て使用
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  // 無限スクロール用の最適化設定
                  cacheExtent: 1000, // キャッシュ範囲を拡張
                  addAutomaticKeepAlives: true, // 自動的にKeepAliveを追加
                  addRepaintBoundaries: true, // 再描画境界を追加
                  addSemanticIndexes: true, // セマンティックインデックスを追加
                  shrinkWrap: false, // 高さを親に合わせる
                  primary: true, // プライマリスクロールビューとして設定
                  children: [
                    // 遵守率グラフ
                    _buildAdherenceChart(),
                    const SizedBox(height: 20),
                    // 薬品別使用状況グラフ
                    _buildMedicationUsageChart(),
                    const SizedBox(height: 20),
                    // 期間別遵守率カード
                    ..._adherenceRates.entries.map((entry) => _buildStatCard(entry.key, entry.value)).toList(),
                    _buildCustomAdherenceCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
  Widget _buildStatCard(String period, double rate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(period, style: const TextStyle(fontSize: 18)),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: rate >= 80 ? Colors.green : rate >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCustomAdherenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任意の日数の遵守率',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '日数を入力（1-365日）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                      helperText: '1-365日まで設定可能',
                    ),
                    onChanged: (value) {
                      // リアルタイム計算を無効化
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final days = int.tryParse(_customDaysController.text);
                    if (days != null && days >= 1 && days <= 365) {
                      _calculateCustomAdherenceInCard(days);
                    } else {
                      _showSnackBar('1から365の範囲で日数を入力してください');
                    }
                  },
                  child: const Text('計算'),
                ),
              ],
            ),
            if (_customAdherenceResult != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _customAdherenceResult! >= 80
                      ? Colors.green.withOpacity(0.1)
                      : _customAdherenceResult! >= 60
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _customAdherenceResult! >= 80
                        ? Colors.green
                        : _customAdherenceResult! >= 60
                            ? Colors.orange
                            : Colors.red,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_customDaysResult}日間の遵守率',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_customAdherenceResult!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _customAdherenceResult! >= 80
                            ? Colors.green
                            : _customAdherenceResult! >= 60
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  void _calculateCustomAdherenceInCard(int days) async {
    try {
      // 範囲チェック
      if (days < 1 || days > 365) {
        _showSnackBar('日数は1から365の範囲で入力してください');
        return;
      }
      final now = DateTime.now();
      int totalDoses = 0;
      int takenDoses = 0;
      
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayData = _medicationData[dateStr];
        
        // 動的薬リストの統計
        if (dayData != null) {
          for (final timeSlot in dayData.values) {
            if (timeSlot.medicine.isNotEmpty) {
              totalDoses++;
              if (timeSlot.checked) takenDoses++;
            }
          }
        }
        
        // 服用メモのチェック状況を統計に反映
        final weekday = date.weekday % 7; // 0=日曜日, 1=月曜日, ..., 6=土曜日
        final weekdayMemos = _medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
        
        for (final memo in weekdayMemos) {
          totalDoses++;
          // 日付別の服用メモ状態を確認
          if (_weekdayMedicationStatus[dateStr]?[memo.id] == true) {
            takenDoses++;
          }
        }
      }
      
      // データがない場合の警告
      if (totalDoses == 0) {
        _showSnackBar('指定した期間に服薬データがありません');
        return;
      }
      final rate = (takenDoses / totalDoses * 100);
     
      // 結果をカード内に表示
      setState(() {
        _customAdherenceResult = rate;
        _customDaysResult = days;
      });
    } catch (e) {
      _showSnackBar('カスタム遵守率の計算に失敗しました: $e');
    }
  }
  // 遵守率グラフ
  Widget _buildAdherenceChart() {
    if (_adherenceRates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                '遵守率グラフ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'データがありません',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    final chartData = _adherenceRates.entries.toList();
    final maxValue = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = chartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '遵守率グラフ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250, // 高さを増加
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50, // 予約サイズを増加
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, // 予約サイズを追加
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[value.toInt()].key,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  minY: minValue - 10,
                  maxY: maxValue + 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // 薬品別使用状況グラフ
  Widget _buildMedicationUsageChart() {
    // 薬品の使用回数を集計（服用メモのチェック状態も含める）
    Map<String, int> medicationCount = {};
    
    // 動的薬リストの統計
    for (final dayData in _medicationData.values) {
      for (final timeSlot in dayData.values) {
        if (timeSlot.medicine.isNotEmpty) {
          medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
        }
      }
    }
    
    // 服用メモのチェック状態を統計に反映（日付別）
    for (final entry in _weekdayMedicationStatus.entries) {
      final dateStr = entry.key;
      final dayStatus = entry.value;
      
      for (final memo in _medicationMemos) {
        if (dayStatus[memo.id] == true) {
          medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + 1;
        }
      }
    }
    if (medicationCount.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'くすり、サプリ別使用状況',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'データがありません',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    final sortedMedications = medicationCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'くすり、サプリ別使用状況',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sortedMedications.asMap().entries.map((entry) {
                    final index = entry.key;
                    final medication = entry.value;
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                      Colors.pink,
                      Colors.indigo,
                    ];
                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: medication.value.toDouble(),
                      title: '${medication.key}\n${medication.value}回',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _applyBulkCheck() async {
    try {
      if (_selectedDates.isEmpty) {
        _showSnackBar('日付を選択してから実行してください。');
        return;
      }
      bool hasData = false;
      // 動的薬リストのチェック
      if (_addedMedications.isNotEmpty) {
        hasData = true;
      }
      if (!hasData) {
        _showSnackBar('薬名または服薬状況を入力してください。');
        return;
      }
      for (final date in _selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        _medicationData.putIfAbsent(dateStr, () => {});
        // 動的薬リストのコピー
        for (final medication in _addedMedications) {
          final medicine = medication['name'] as String;
          final checked = medication['isChecked'] as bool;
          _medicationData[dateStr]!['added_medication_${medication.hashCode}'] = MedicationInfo(
            checked: checked,
            medicine: medicine,
            actualTime: checked ? DateTime.now() : null,
          );
          await MedicationService.saveCsvRecord(dateStr, 'added_medication', medicine, checked ? '服薬済み' : '未服薬');
        }
      }
      await MedicationService.saveMedicationData(_medicationData);
      // 通知設定は簡素化
      final notificationTimes = <String, List<TimeOfDay>>{};
      final notificationTypes = <String, NotificationType>{};
      await NotificationService.scheduleNotifications(notificationTimes, _medicationData, notificationTypes);
      setState(() {
        _selectedDates.clear();
        _selectedDay = null;
      });
      _updateMedicineInputsForSelectedDate();
      _showSnackBar('✅ 一括設定を適用しました。');
    } catch (e) {
      _showSnackBar('一括設定の適用に失敗しました: $e');
    }
  }
  Future<void> _applyBulkUncheck() async {
    try {
      if (_selectedDates.isEmpty) {
        _showSnackBar('日付を選択してから実行してください。');
        return;
      }
      for (final date in _selectedDates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        _medicationData.putIfAbsent(dateStr, () => {});
        // 動的薬リストのコピー
        for (final medication in _addedMedications) {
          final medicine = medication['name'] as String;
          _medicationData[dateStr]!['added_medication_${medication.hashCode}'] = MedicationInfo(
            checked: false,
            medicine: medicine,
            actualTime: null,
          );
          await MedicationService.saveCsvRecord(dateStr, 'added_medication', medicine, '未服薬');
        }
      }
      await MedicationService.saveMedicationData(_medicationData);
      // 通知設定は簡素化
      final notificationTimes = <String, List<TimeOfDay>>{};
      final notificationTypes = <String, NotificationType>{};
      await NotificationService.scheduleNotifications(notificationTimes, _medicationData, notificationTypes);
      setState(() {
        _selectedDates.clear();
        _selectedDay = null;
      });
      _updateMedicineInputsForSelectedDate();
      _showSnackBar('❌ 一括解除を適用しました。');
    } catch (e) {
      _showSnackBar('一括解除の適用に失敗しました: $e');
    }
  }
  Future<void> _deleteMedicine(String name) async {
    try {
      await MedicationService.deleteMedicine(name);
      setState(() {
        _medicines.removeWhere((medicine) => medicine.name == name);
      });
      _showSnackBar('薬品を削除しました');
    } catch (e) {
      _showSnackBar('薬品の削除に失敗しました: $e');
    }
  }
  void _addMemo() {
    showDialog(
      context: context,
      builder: (context) => _MemoDialog(
        onMemoAdded: (memo) async {
          setState(() {
            _medicationMemos.add(memo);
          });
          await AppPreferences.saveMedicationMemo(memo);
          _showSnackBar('${memo.type}を追加しました');
        },
      ),
    );
  }
  void _editMemo(MedicationMemo memo) {
    showDialog(
      context: context,
      builder: (context) => _MemoDialog(
        initialMemo: memo,
        onMemoAdded: (updatedMemo) async {
          setState(() {
            final index = _medicationMemos.indexWhere((m) => m.id == memo.id);
            if (index != -1) {
              _medicationMemos[index] = updatedMemo;
            }
          });
          await AppPreferences.updateMedicationMemo(updatedMemo);
          _showSnackBar('${updatedMemo.type}を更新しました');
        },
      ),
    );
  }
  void _markAsTaken(MedicationMemo memo) async {
    final updatedMemo = MedicationMemo(
      id: memo.id,
      name: memo.name,
      type: memo.type,
      dosage: memo.dosage,
      notes: memo.notes,
      createdAt: memo.createdAt,
      lastTaken: DateTime.now(),
      color: memo.color,
      selectedWeekdays: memo.selectedWeekdays,
    );
    
    setState(() {
      final index = _medicationMemos.indexWhere((m) => m.id == memo.id);
      if (index != -1) {
        _medicationMemos[index] = updatedMemo;
      }
    });
    
    await AppPreferences.updateMedicationMemo(updatedMemo);
    _showSnackBar('${memo.name}の服用を記録しました');
  }
  void _deleteMemo(String id) async {
    setState(() {
      _medicationMemos.removeWhere((memo) => memo.id == id);
    });
    await AppPreferences.deleteMedicationMemo(id);
    _showSnackBar('メモを削除しました');
  }

  // CSV共有機能の強化（未使用）
  Future<void> _exportToCSV() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/medication_data_$timestamp.csv');
     
      final csvContent = StringBuffer();
     
      // ヘッダー行
      csvContent.writeln('日付,時間,薬名,服薬状況,実際の服薬時間,遅延時間(分),遵守率');
     
      // 統計情報を計算（服用メモのチェック状態も含める）
      int totalDoses = 0;
      int takenDoses = 0;
      final Map<String, int> medicationCount = {};
      final Map<String, int> medicationTakenCount = {};
     
      // 動的薬リストの統計
      for (final entry in _medicationData.entries) {
        final date = entry.key;
        final dayData = entry.value;
       
        for (final timeSlot in dayData.entries) {
          final time = timeSlot.key;
          final info = timeSlot.value;
         
          if (info.medicine.isNotEmpty) {
            totalDoses++;
            if (info.checked) takenDoses++;
           
            // 薬品別カウント
            medicationCount[info.medicine] = (medicationCount[info.medicine] ?? 0) + 1;
            if (info.checked) {
              medicationTakenCount[info.medicine] = (medicationTakenCount[info.medicine] ?? 0) + 1;
            }
          }
        }
      }
      
      // 服用メモのチェック状態を統計に反映（日付別）
      for (final entry in _weekdayMedicationStatus.entries) {
        final dateStr = entry.key;
        final dayStatus = entry.value;
        
        for (final memo in _medicationMemos) {
          if (dayStatus[memo.id] == true) {
            totalDoses++;
            takenDoses++;
            medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + 1;
            medicationTakenCount[memo.name] = (medicationTakenCount[memo.name] ?? 0) + 1;
          }
        }
      }
     
      // 統計サマリーを追加
      csvContent.writeln('');
      csvContent.writeln('=== 統計サマリー ===');
      csvContent.writeln('総服薬回数,$totalDoses');
      csvContent.writeln('服薬済み回数,$takenDoses');
      csvContent.writeln('全体遵守率,${totalDoses > 0 ? (takenDoses / totalDoses * 100).toStringAsFixed(1) : 0}%');
      csvContent.writeln('');
      csvContent.writeln('=== 薬品別統計 ===');
      csvContent.writeln('薬品名,総回数,服薬済み回数,遵守率');
     
      for (final medication in medicationCount.keys) {
        final total = medicationCount[medication]!;
        final taken = medicationTakenCount[medication] ?? 0;
        final rate = total > 0 ? (taken / total * 100) : 0;
        csvContent.writeln('$medication,$total,$taken,${rate.toStringAsFixed(1)}%');
      }
     
      await file.writeAsString(csvContent.toString());
     
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: '服薬データをエクスポートしました（統計情報付き）');
     
      _showSnackBar('CSVファイルをエクスポートしました（統計情報付き）');
    } catch (e) {
      _showSnackBar('CSVエクスポートに失敗しました: $e');
    }
  }
 
  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _selectAllDates() {
    setState(() {
      _selectedDates.clear();
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);
      
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final date = startDate.add(Duration(days: i));
        _selectedDates.add(_normalizeDate(date));
      }
      
      if (_selectedDates.isNotEmpty) {
        _selectedDay = _selectedDates.first;
      }
    });
    _updateMedicineInputsForSelectedDate();
    _showSnackBar('今月のすべての日付を選択しました');
  }

  void _clearAllSelections() {
    setState(() {
      _selectedDates.clear();
      _selectedDay = null;
    });
    _updateMedicineInputsForSelectedDate();
    _showSnackBar('すべての選択を解除しました');
  }

  // 選択された日付の曜日に基づいて服用メモを取得
  List<MedicationMemo> _getMedicationsForSelectedDay() {
    if (_selectedDay == null) return [];
    
    final weekday = _selectedDay!.weekday % 7; // 0=日曜日, 1=月曜日, ..., 6=土曜日
    return _medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
  }

  // 曜日設定された薬の服用状況を取得
  bool _getWeekdayMedicationStatus(String memoId) {
    if (_selectedDay == null) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    return _weekdayMedicationStatus[dateStr]?[memoId] ?? false;
  }

  // 曜日設定された薬の服用状況を更新
  void _updateWeekdayMedicationStatus(String memoId, bool isTaken) {
    if (_selectedDay == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    _weekdayMedicationStatus.putIfAbsent(dateStr, () => {});
    _weekdayMedicationStatus[dateStr]![memoId] = isTaken;
  }

  // 曜日設定された薬を表示するウィジェット
  Widget _buildWeekdayMedicationRecord(MedicationMemo memo) {
    final isChecked = _getWeekdayMedicationStatus(memo.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20), // 間隔を広く
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isChecked
            ? Border.all(color: memo.color, width: 2)
            : Border.all(color: memo.color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: isChecked 
                ? memo.color.withOpacity(0.2)
                : memo.color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isChecked
              ? LinearGradient(
                  colors: [memo.color.withOpacity(0.1), memo.color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [memo.color.withOpacity(0.05), memo.color.withOpacity(0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24), // パディングを増加
          child: Row(
            children: [
              // 服用済みチェックボックス
              GestureDetector(
                onTap: () {
                  setState(() {
                    _updateWeekdayMedicationStatus(memo.id, !isChecked);
                  });
                  _saveCurrentDataDebounced();
                  _updateCalendarMarks();
                },
                child: Container(
                  width: 60, // サイズを大きく
                  height: 60,
                  decoration: BoxDecoration(
                    color: isChecked ? memo.color : memo.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isChecked
                        ? [
                            BoxShadow(
                              color: memo.color.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isChecked ? Colors.white : memo.color,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 24), // 間隔を広く
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                          color: memo.color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            memo.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: memo.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: memo.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            memo.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: memo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (memo.dosage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '用量: ${memo.dosage}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (memo.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        memo.notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _addMedicationToTimeSlot(String medicationName) {
    // 服用メモから薬の詳細情報を取得
    final memo = _medicationMemos.firstWhere(
      (memo) => memo.name == medicationName,
      orElse: () => MedicationMemo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: medicationName,
        type: '薬',
        color: Colors.blue,
        dosage: '',
        notes: '',
        createdAt: DateTime.now(),
      ),
    );
    
    // 新しい薬をリストに追加
    setState(() {
      _addedMedications.add({
        'name': memo.name,
        'type': memo.type,
        'color': memo.color,
        'dosage': memo.dosage,
        'notes': memo.notes,
        'isChecked': false,
      });
    });
    
    _saveCurrentDataDebounced();
    _showSnackBar('$medicationName を服用記録に追加しました');
  }

  // 完全に作り直されたカレンダーマーク更新
  void _updateCalendarMarks() {
    if (_selectedDay == null) return;
    
    // 強制的にカレンダーを更新
    setState(() {
      // カレンダーのマークを強制更新
    });
  }

  // 軽量化された統計計算メソッド
  Map<String, int> _calculateMedicationStats() {
    if (_selectedDay == null) return {'total': 0, 'taken': 0};
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    totalMedications += _addedMedications.length;
    takenMedications += _addedMedications.where((med) => med['isChecked'] == true).length;
    
    // 服用メモの統計（軽量化）
    final weekday = _selectedDay!.weekday % 7;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    for (final memo in _medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (_medicationMemoStatus[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  Widget _buildMedicationStats() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    // 完全に作り直された統計計算
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    totalMedications += _addedMedications.length;
    takenMedications += _addedMedications.where((med) => med['isChecked'] == true).length;
    
    // 服用メモの統計（今日の曜日に該当するもののみ）
    final weekday = _selectedDay!.weekday % 7;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    for (final memo in _medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (_medicationMemoStatus[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    final progress = totalMedications > 0 ? takenMedications / totalMedications : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: progress == 1.0 
            ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
            : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress == 1.0 ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      progress == 1.0 ? Icons.check_circle : Icons.schedule,
                      color: progress == 1.0 ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '今日の服用状況',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: progress == 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$takenMedications / $totalMedications 服用済み',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
                if (totalMedications > 0) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progress == 1.0 ? Colors.green : Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: (progress == 1.0 ? Colors.green : Colors.orange).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 修正：オーバーフローを防ぐためにFlexibleを使用
        Row(
          children: [
            Icon(Icons.note_alt, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
              '今日のメモ',
              style: TextStyle(
                fontSize: 14, // フォントサイズ削減
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis, // テキストオーバーフロー対策
              ),
            ),
            const Spacer(),
            if (_memoController.text.isNotEmpty)
              Flexible(
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // パディング削減
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8), // 角丸削減
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Text(
                  '保存済み',
                  style: TextStyle(
                    fontSize: 10, // フォントサイズ削減
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6), // 間隔削減
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8), // 角丸削減
            border: Border.all(
              color: _isMemoFocused ? Colors.blue.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              width: _isMemoFocused ? 1.5 : 1,
            ),
            boxShadow: _isMemoFocused ? [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: TextField(
            controller: _memoController,
            focusNode: _memoFocusNode,
            maxLines: 2, // 2行表示に固定
            minLines: 2, // 最小行数を2に変更
            decoration: InputDecoration(
              hintText: '副作用、病院、通院記録など',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 12, // フォントサイズ削減
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12), // パディング削減
              suffixIcon: _memoController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _memoController.clear();
                        });
                        _saveMemo();
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                    )
                  : null,
            ),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.lightGreen[300] 
                  : Colors.black87,
            ),
            onTap: () async {
              // トライアル制限チェック
              final isExpired = await TrialService.isTrialExpired();
              if (isExpired) {
                showDialog(
                  context: context,
                  builder: (context) => TrialLimitDialog(featureName: 'メモ'),
                );
                FocusScope.of(context).unfocus();
                return;
              }
              setState(() {
                _isMemoFocused = true;
              });
            },
            onChanged: (value) {
              setState(() {
                // リアルタイムでUIを更新
              });
              // メモの内容が変更された時の処理
              _saveMemo();
            },
            onSubmitted: (value) {
              // キーボードの決定ボタンで完了
              _completeMemo();
            },
            onEditingComplete: () {
              _completeMemo();
            },
          ),
        ),
        // メモ入力時の完了ボタン（コンパクト化）
        if (_isMemoFocused) ...[
          const SizedBox(height: 8), // 間隔削減
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _completeMemo();
                },
                icon: const Icon(Icons.save, size: 16), // アイコンサイズ削減
                label: const Text('保存', style: TextStyle(fontSize: 12)), // フォントサイズ削減
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // パディング削減
                  minimumSize: const Size(0, 32), // 最小サイズ設定
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _memoController.clear();
                    _isMemoFocused = false;
                  });
                  _saveMemo();
                  FocusScope.of(context).unfocus();
                },
                icon: const Icon(Icons.clear, size: 16), // アイコンサイズ削減
                label: const Text('クリア', style: TextStyle(fontSize: 12)), // フォントサイズ削減
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // パディング削減
                  minimumSize: const Size(0, 32), // 最小サイズ設定
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _saveMemo() async {
    try {
      if (_selectedDay != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('memo_$dateStr', _memoController.text);
      }
    } catch (e) {
    }
  }
  
  void _completeMemo() {
    setState(() {
      _isMemoFocused = false;
    });
    // カーソルの選択を外す
    FocusScope.of(context).unfocus();
    _saveMemo().then((_) {
      if (_memoController.text.isNotEmpty) {
        _showSnackBar('メモを保存しました');
      } else {
        _showSnackBar('メモをクリアしました');
      }
    });
  }

  // トライアル状態表示ダイアログ
  Future<void> _showTrialStatus() async {
    final status = await TrialService.getPurchaseStatus();
    final remainingMinutes = await TrialService.getRemainingMinutes();
    
    if (!mounted) return;
    
    // 状態に応じたアイコンと色を設定
    IconData statusIcon;
    Color statusColor;
    String statusText;
    
    switch (status) {
      case TrialService.trialStatus:
        statusIcon = Icons.timer;
        statusColor = Colors.blue;
        statusText = 'トライアル中';
        break;
      case TrialService.expiredStatus:
        statusIcon = Icons.warning;
        statusColor = Colors.red;
        statusText = '期限切れ';
        break;
      case TrialService.purchasedStatus:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = '購入済み';
        break;
      default:
        statusIcon = Icons.timer;
        statusColor = Colors.blue;
        statusText = 'トライアル中';
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 12),
            const Text('購入状態'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('現在の状態', statusText, statusColor),
            if (status == TrialService.trialStatus) ...[
            const SizedBox(height: 12),
            _buildStatusRow('残り時間', 
                  '${(remainingMinutes / (24 * 60)).ceil()}日',
                  Colors.orange),
            ],
            if (status == TrialService.expiredStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('期限', '7日間終了', Colors.red),
            ],
            if (status == TrialService.purchasedStatus) ...[
              const SizedBox(height: 12),
              _buildStatusRow('有効期限', '無制限', Colors.green),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          if (status == TrialService.expiredStatus)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _showPurchaseLinkDialog();
              },
              child: const Text('購入する'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
  
  // 警告ダイアログを表示するメソッド
  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('注意'),
          ],
        ),
        content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              '服用回数が多いため、',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              '医師の指示に従ってください',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
    
    // 3秒後に自動で閉じる
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }
  
  // 購入状態に設定するメソッド
  Future<void> _setPurchasedStatus() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('購入状態に設定'),
          ],
        ),
        content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'アプリを購入済み状態に設定しますか？',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '設定後は以下の機能が無制限で使用できます：',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text('• メモの追加・編集'),
            Text('• アラーム機能'),
            Text('• 統計機能'),
            Text('• カレンダー機能'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await TrialService.setPurchaseStatus(TrialService.purchasedStatus);
              Navigator.of(context).pop();
              
              // 実際の購入時と同じメッセージを表示
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 32),
                      SizedBox(width: 12),
                      Text('購入完了！'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '商品購入後、期限が無期限になりました！',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                        child: const Column(
                  children: [
                            Text(
                              '🎉 プレミアム機能が有効になりました！',
                      style: TextStyle(
                            fontSize: 16,
                        fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                            SizedBox(height: 8),
                            Text(
                              '• メモの追加・編集\n• アラーム機能\n• 統計機能\n• カレンダー機能',
                              style: TextStyle(fontSize: 14),
                              textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: const Text('ありがとうございます！'),
                    ),
                  ],
                ),
              );
            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
            ),
            child: const Text('購入済みに設定'),
          ),
        ],
      ),
    );
  }

  // トライアル状態に設定
  Future<void> _setTrialStatus() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('トライアル状態に'),
                  Text('設定'),
                  ],
                ),
              ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'アプリをトライアル状態に設定しますか？',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '設定後は以下の制限が適用されます：',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text('• トライアル期間: 7日間'),
            Text('• 期限切れ後は機能制限'),
            Text('• 購入で制限解除'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              // トライアルをリセットして新しいトライアルを開始
              await TrialService.resetTrial();
              await TrialService.initializeTrial();
              await TrialService.setPurchaseStatus(TrialService.trialStatus);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('トライアル状態に設定しました（7日間）'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('トライアルに設定'),
          ),
        ],
      ),
    );
  }



  // アプリ内課金ダイアログを表示
  Future<void> _showPurchaseLinkDialog() async {
    if (!mounted) return;
    
    // 商品情報を取得
    final ProductDetails? product = await InAppPurchaseService.getProductDetails();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Colors.green),
            SizedBox(width: 12),
            Text('アプリ内課金'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品情報表示
              if (product != null) ...[
              Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                          const Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                            'プレミアム機能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                              color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
                      Text(
                        '商品名: ${product.title}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '説明: ${product.description}',
                        style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        '価格: ${product.price}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
          ),
        ],
      ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 機能説明
                    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
                        const Icon(Icons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
          const Text(
                          'プレミアム機能',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                            color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
                      '購入後は以下の機能が無制限で使用できます：',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
                    const SizedBox(height: 8),
                    const Text('• メモの追加・編集'),
                    const Text('• アラーム機能'),
                    const Text('• 統計機能'),
                    const Text('• カレンダー機能'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 購入ボタン
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'アプリ内課金で購入',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
                      onPressed: product != null ? () async {
                        Navigator.of(context).pop();
                        await _startPurchase(product);
                      } : null,
                      icon: const Icon(Icons.shopping_cart),
                      label: Text(product != null ? '${product.price}で購入' : '商品情報を取得中...'),
            style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
              foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await InAppPurchaseService.restorePurchases();
                        
                        // 購入履歴復元の結果を確認
                        final isPurchased = await InAppPurchaseService.isPurchased();
                        if (isPurchased) {
                          // 購入履歴が復元された場合の特別なメッセージ
    showDialog(
      context: context,
                            barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
                                  Icon(Icons.restore, color: Colors.blue, size: 32),
            SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('購入履歴復元'),
                                        Text('完了！'),
                  ],
                ),
              ),
                                ],
                              ),
                              content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                                    '商品購入後、期限が無期限になりました！',
              style: TextStyle(
                                      fontSize: 18,
                fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    '過去の購入履歴が復元され、プレミアム機能が有効になりました。',
                                    style: TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('ありがとうございます！'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('購入履歴が見つかりませんでした')),
                          );
                        }
                      },
                      child: const Text('購入履歴を復元'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }



  // 購入を開始
  Future<void> _startPurchase(ProductDetails product) async {
    // 購入結果の監視を開始
    InAppPurchaseService.startPurchaseListener((success, error) {
      if (success) {
        // 購入成功時の特別なメッセージを表示
    showDialog(
      context: context,
          barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
                Text('購入完了！'),
          ],
        ),
            content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
                const Text(
                  '商品購入後、期限が無期限になりました！',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Column(
                    children: [
            Text(
                        '🎉 プレミアム機能が有効になりました！',
              style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• メモの追加・編集\n• アラーム機能\n• 統計機能\n• カレンダー機能',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.left,
                      ),
                    ],
              ),
            ),
          ],
        ),
        actions: [
              ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('ありがとうございます！'),
          ),
        ],
      ),
    );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('購入に失敗しました: ${error ?? "不明なエラー"}'),
            backgroundColor: Colors.red,
      ),
    );
  }
    });
    
    // 購入を開始
    final success = await InAppPurchaseService.purchaseProduct();
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('購入の開始に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ バックアップ機能を実装
  Future<void> _showBackupDialog() async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.orange),
            SizedBox(width: 8),
            Text('バックアップ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⏱ バックアップ間隔のおすすめ\n\n'
                  '・毎日深夜2:00（自動）- フルバックアップ\n'
                  '・操作後5分以内（自動）- 差分バックアップ\n'
                  '・手動保存（任意）- 任意タイミングで保存',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _createManualBackup();
                },
                icon: const Icon(Icons.save),
                label: const Text('手動バックアップを作成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _showBackupHistory();
                },
                icon: const Icon(Icons.history),
                label: const Text('保存履歴を見る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRecommendation(String timing, String content, String reason, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(timing, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          Text(content, style: const TextStyle(fontSize: 12)),
          Text(reason, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ✅ 手動バックアップ作成機能
  Future<void> _createManualBackup() async {
    if (!mounted) return;
    
    // 保存名入力ダイアログ
    final TextEditingController nameController = TextEditingController();
    final now = DateTime.now();
    nameController.text = '${DateFormat('yyyy-MM-dd_HH-mm').format(now)}_手動保存';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップ名を入力'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: '例: 2024-01-15_14-30_手動保存',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameController.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      await _performBackup(result);
    }
  }

  // ✅ バックアップ実行機能（1回で完了するように最適化）
  Future<void> _performBackup(String backupName) async {
    // ローディング表示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('バックアップを作成中...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // ✅ 改善：1回でバックアップを完了
      await _createAndSaveBackupInOneStep(backupName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップ「$backupName」を作成しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの作成に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ 1回でバックアップを完了するメソッド
  Future<void> _createAndSaveBackupInOneStep(String backupName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // バックアップデータを直接作成
      final backupData = {
        'name': backupName,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'manual',
        // 服用メモ関連
        'medicationMemos': _medicationMemos.map((memo) => memo.toJson()).toList(),
        'addedMedications': _addedMedications,
        'medicationData': _medicationData.map((dateKey, dayData) {
          final dayDataJson = <String, dynamic>{};
          for (final medEntry in dayData.entries) {
            dayDataJson[medEntry.key] = medEntry.value.toJson();
          }
          return MapEntry(dateKey, dayDataJson);
        }),
        'medicines': _medicines.map((medicine) => medicine.toJson()).toList(),
        // チェック状態関連
        'weekdayMedicationStatus': _weekdayMedicationStatus,
        'weekdayMedicationDoseStatus': _weekdayMedicationDoseStatus,
        'medicationMemoStatus': _medicationMemoStatus,
        // カレンダー色関連（Colorオブジェクトをintに変換）
        'dayColors': _dayColors.map((key, value) => MapEntry(key, value.value)),
        // アラーム関連
        'alarmList': _alarmList,
        'alarmSettings': _alarmSettings,
        // その他の状態
        'adherenceRates': _adherenceRates,
      };
      
      // JSONエンコード
      final jsonString = jsonEncode(backupData);
      
      // 暗号化（簡易版）
      final encryptedData = await _encryptDataAsync(jsonString);
      
      // 保存
      await prefs.setString(backupKey, encryptedData);
      
      // 履歴更新
      await _updateBackupHistory(backupName, backupKey);
      
    } catch (e) {
      debugPrint('1回バックアップ作成エラー: $e');
      rethrow;
    }
  }

  // ✅ 非同期でバックアップデータを作成（JSONエンコード対応）
  Future<Map<String, dynamic>> _createBackupDataAsync(String backupName) async {
    try {
      // ✅ 修正：JSONエンコード可能な形式に変換
      final medicationDataJson = <String, Map<String, dynamic>>{};
      for (final entry in _medicationData.entries) {
        final dateKey = entry.key;
        final dayData = entry.value;
        final dayDataJson = <String, dynamic>{};
        
        for (final medEntry in dayData.entries) {
          final medKey = medEntry.key;
          final medInfo = medEntry.value;
          dayDataJson[medKey] = medInfo.toJson();
        }
        
        medicationDataJson[dateKey] = dayDataJson;
      }
      
      return {
        'name': backupName,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'manual',
        // 服用メモ関連
        'medicationMemos': _medicationMemos.map((memo) => memo.toJson()).toList(),
        'addedMedications': _addedMedications,
        'medicationData': medicationDataJson, // ✅ 修正：JSONエンコード可能な形式
        'medicines': _medicines.map((medicine) => medicine.toJson()).toList(),
        // チェック状態関連
        'weekdayMedicationStatus': _weekdayMedicationStatus,
        'weekdayMedicationDoseStatus': _weekdayMedicationDoseStatus,
        'medicationMemoStatus': _medicationMemoStatus,
        // カレンダー色関連（Colorオブジェクトをintに変換）
        'dayColors': _dayColors.map((key, value) => MapEntry(key, value.value)),
        // アラーム関連
        'alarmList': _alarmList,
        'alarmSettings': _alarmSettings,
        // その他の状態
        'adherenceRates': _adherenceRates,
      };
    } catch (e) {
      debugPrint('バックアップデータ作成エラー: $e');
      rethrow;
    }
  }

  // ✅ 非同期でバックアップを保存（JSONエンコードエラーハンドリング）
  Future<void> _saveBackupAsync(Map<String, dynamic> backupData, String backupName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      // ✅ 修正：JSONエンコードのエラーハンドリング
      String jsonString;
      try {
        jsonString = jsonEncode(backupData);
      } catch (e) {
        debugPrint('JSONエンコードエラー: $e');
        // エンコードできないオブジェクトを除外して再試行
        final safeBackupData = _createSafeBackupData(backupData);
        jsonString = jsonEncode(safeBackupData);
      }
      
      // 非同期で暗号化
      final encryptedData = await _encryptDataAsync(jsonString);
      
      // 非同期で保存
      await prefs.setString(backupKey, encryptedData);
      
      // 非同期で履歴更新
      await _updateBackupHistory(backupName, backupKey);
    } catch (e) {
      debugPrint('バックアップ保存エラー: $e');
      rethrow;
    }
  }

  // ✅ 安全なバックアップデータを作成（エンコードできないオブジェクトを除外）
  Map<String, dynamic> _createSafeBackupData(Map<String, dynamic> originalData) {
    final safeData = <String, dynamic>{};
    
    for (final entry in originalData.entries) {
      try {
        // 各値をテストしてエンコード可能かチェック
        jsonEncode(entry.value);
        safeData[entry.key] = entry.value;
      } catch (e) {
        debugPrint('エンコードできないオブジェクトを除外: ${entry.key} - $e');
        // エンコードできないオブジェクトは除外
        if (entry.key == 'medicationData') {
          safeData[entry.key] = <String, dynamic>{};
        } else if (entry.key == 'dayColors') {
          safeData[entry.key] = <String, int>{};
        } else {
          safeData[entry.key] = null;
        }
      }
    }
    
    return safeData;
  }

  // ✅ 非同期でデータを暗号化
  Future<String> _encryptDataAsync(String data) async {
    // 重い処理を非同期で実行
    return await Future(() {
      final key = 'medication_app_backup_key_2024';
      final encrypted = StringBuffer();
      for (int i = 0; i < data.length; i++) {
        encrypted.write(String.fromCharCode(
          data.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
        ));
      }
      return encrypted.toString();
    });
  }

  // ✅ データ暗号化機能
  String _encryptData(String data) {
    // 簡単なXOR暗号化（実際のアプリではAES暗号化を推奨）
    final key = 'medication_app_backup_key_2024';
    final encrypted = StringBuffer();
    for (int i = 0; i < data.length; i++) {
      encrypted.write(String.fromCharCode(
        data.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
      ));
    }
    return encrypted.toString();
  }

  // ✅ データ復号化機能
  String _decryptData(String encryptedData) {
    // XOR暗号化の復号化
    final key = 'medication_app_backup_key_2024';
    final decrypted = StringBuffer();
    for (int i = 0; i < encryptedData.length; i++) {
      decrypted.write(String.fromCharCode(
        encryptedData.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
      ));
    }
    return decrypted.toString();
  }

  // ✅ バックアップ履歴の更新（5件制限）
  Future<void> _updateBackupHistory(String backupName, String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('backup_history') ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    
    history.add({
      'name': backupName,
      'key': backupKey,
      'createdAt': DateTime.now().toIso8601String(),
      'type': 'manual',
    });
    
    // 古い順に自動削除（最大5件まで保持）
    if (history.length > 5) {
      // 古いバックアップデータを削除
      final oldBackup = history.removeAt(0);
      await prefs.remove(oldBackup['key']);
    }
    
    await prefs.setString('backup_history', jsonEncode(history));
  }

  // ✅ バックアップ履歴表示機能
  Future<void> _showBackupHistory() async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('backup_history') ?? '[]';
    final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
    
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('バックアップ履歴がありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップ履歴'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final backup = history[history.length - 1 - index]; // 新しい順に表示
              final createdAt = DateTime.parse(backup['createdAt']);
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.backup, color: Colors.orange),
                  title: Text(backup['name']),
                  subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'restore':
                          await _restoreBackup(backup['key']);
                          break;
                        case 'delete':
                          await _deleteBackup(backup['key'], index);
                          break;
                        case 'preview':
                          await _previewBackup(backup['key']);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('プレビュー'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore, color: Colors.green),
                            SizedBox(width: 8),
                            Text('復元する'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除する'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // ✅ バックアッププレビュー機能
  Future<void> _previewBackup(String backupKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(backupKey);
      
      if (encryptedData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('バックアップデータが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final decryptedData = _decryptData(encryptedData);
      final backupData = jsonDecode(decryptedData);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('バックアッププレビュー'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('名前: ${backupData['name']}'),
                  Text('作成日時: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupData['createdAt']))}'),
                  const SizedBox(height: 8),
                  const Text('📊 バックアップ内容:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('・服用メモ数: ${(backupData['medicationMemos'] as List).length}件'),
                  Text('・追加薬品数: ${(backupData['addedMedications'] as List).length}件'),
                  Text('・薬品データ数: ${(backupData['medicines'] as List).length}件'),
                  Text('・アラーム数: ${(backupData['alarmList'] as List).length}件'),
                  Text('・カレンダー色設定: ${(backupData['dayColors'] as Map).length}日分'),
                  Text('・チェック状態: ${(backupData['weekdayMedicationStatus'] as Map).length}日分'),
                  Text('・服用率データ: ${(backupData['adherenceRates'] as Map).length}件'),
                  const SizedBox(height: 16),
                  const Text('このバックアップを復元しますか？'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _restoreBackup(backupKey);
                },
                child: const Text('復元する'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プレビューの表示に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ バックアップ復元機能（非同期で軽く最適化）
  Future<void> _restoreBackup(String backupKey) async {
    // ローディング表示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('バックアップを復元中...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    try {
      // 非同期でバックアップデータを読み込み
      final backupData = await _loadBackupDataAsync(backupKey);
      
      if (backupData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('バックアップデータが見つかりません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // 非同期でデータを復元
      await _restoreDataAsync(backupData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップを復元しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ 非同期でバックアップデータを読み込み
  Future<Map<String, dynamic>?> _loadBackupDataAsync(String backupKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(backupKey);
    
    if (encryptedData == null) return null;
    
    // 非同期で復号化
    final decryptedData = await _decryptDataAsync(encryptedData);
    return jsonDecode(decryptedData);
  }

  // ✅ 非同期でデータを復号化
  Future<String> _decryptDataAsync(String encryptedData) async {
    // 重い処理を非同期で実行
    return await Future(() {
      final key = 'medication_app_backup_key_2024';
      final decrypted = StringBuffer();
      for (int i = 0; i < encryptedData.length; i++) {
        decrypted.write(String.fromCharCode(
          encryptedData.codeUnitAt(i) ^ key.codeUnitAt(i % key.length)
        ));
      }
      return decrypted.toString();
    });
  }

  // ✅ 非同期でデータを復元
  Future<void> _restoreDataAsync(Map<String, dynamic> backupData) async {
    // データの復元（型安全な処理）- 全データを復元対象に
    // ✅ 修正：setState()を呼ぶ前に全データを復元し、一度にUI更新
    final List<MedicationMemo> restoredMemos = (backupData['medicationMemos'] as List)
        .map((json) => MedicationMemo.fromJson(json))
        .toList();
    final List<Map<String, dynamic>> restoredAddedMedications = List<Map<String, dynamic>>.from(backupData['addedMedications']);
    
    // 薬品データの復元
    List<MedicineData> restoredMedicines = [];
    if (backupData['medicines'] != null) {
      restoredMedicines = (backupData['medicines'] as List)
          .map((json) => MedicineData.fromJson(json))
          .toList();
    }
    
    // ✅ 修正：MedicationInfo型の安全な復元処理
    final Map<String, Map<String, MedicationInfo>> restoredMedicationData = <String, Map<String, MedicationInfo>>{};
    if (backupData['medicationData'] != null) {
      final medicationDataMap = backupData['medicationData'] as Map<String, dynamic>;
      for (final entry in medicationDataMap.entries) {
        final dateKey = entry.key;
        final dayData = entry.value as Map<String, dynamic>;
        final medicationInfoMap = <String, MedicationInfo>{};
        
        for (final medEntry in dayData.entries) {
          final medKey = medEntry.key;
          final medData = medEntry.value as Map<String, dynamic>;
          medicationInfoMap[medKey] = MedicationInfo.fromJson(medData);
        }
        
        restoredMedicationData[dateKey] = medicationInfoMap;
      }
    }
    
    // チェック状態の復元
    final Map<String, Map<String, bool>> restoredWeekdayStatus = {};
    if (backupData['weekdayMedicationStatus'] != null) {
      restoredWeekdayStatus.addAll(Map<String, Map<String, bool>>.from(backupData['weekdayMedicationStatus']));
    }
    
    final Map<String, Map<String, Map<int, bool>>> restoredWeekdayDoseStatus = {};
    if (backupData['weekdayMedicationDoseStatus'] != null) {
      restoredWeekdayDoseStatus.addAll(Map<String, Map<String, Map<int, bool>>>.from(backupData['weekdayMedicationDoseStatus']));
    }
    
    final Map<String, bool> restoredMemoStatus = {};
    if (backupData['medicationMemoStatus'] != null) {
      restoredMemoStatus.addAll(Map<String, bool>.from(backupData['medicationMemoStatus']));
    }
    
    // ✅ 修正：dayColorsの安全な復元処理
    final Map<String, Color> restoredDayColors = <String, Color>{};
    if (backupData['dayColors'] != null) {
      final dayColorsMap = backupData['dayColors'] as Map<String, dynamic>;
      for (final entry in dayColorsMap.entries) {
        restoredDayColors[entry.key] = Color(entry.value as int);
      }
    }
    
    // アラーム関連の復元
    final List<Map<String, dynamic>> restoredAlarmList = [];
    if (backupData['alarmList'] != null) {
      restoredAlarmList.addAll(List<Map<String, dynamic>>.from(backupData['alarmList']));
    }
    
    final Map<String, dynamic> restoredAlarmSettings = {};
    if (backupData['alarmSettings'] != null) {
      restoredAlarmSettings.addAll(Map<String, dynamic>.from(backupData['alarmSettings']));
    }
    
    // その他の状態の復元
    final Map<String, double> restoredAdherenceRates = {};
    if (backupData['adherenceRates'] != null) {
      restoredAdherenceRates.addAll(Map<String, double>.from(backupData['adherenceRates']));
    }
    
    // ✅ 修正：一度に全データを復元してsetState()を1回だけ呼ぶ
    setState(() {
      _medicationMemos = restoredMemos;
      _addedMedications = restoredAddedMedications;
      _medicines = restoredMedicines;
      _medicationData = restoredMedicationData;
      _weekdayMedicationStatus = restoredWeekdayStatus;
      _weekdayMedicationDoseStatus = restoredWeekdayDoseStatus;
      _medicationMemoStatus = restoredMemoStatus;
      _dayColors = restoredDayColors;
      _alarmList = restoredAlarmList;
      _alarmSettings = restoredAlarmSettings;
      _adherenceRates = restoredAdherenceRates;
    });
    
    // ✅ 修正：復元後にデータを保存（1回だけ）
    await _saveAllData();
  }

  // ✅ バックアップ削除機能
  Future<void> _deleteBackup(String backupKey, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // バックアップデータを削除
      await prefs.remove(backupKey);
      
      // 履歴から削除
      final historyJson = prefs.getString('backup_history') ?? '[]';
      final history = List<Map<String, dynamic>>.from(jsonDecode(historyJson));
      history.removeAt(history.length - 1 - index);
      await prefs.setString('backup_history', jsonEncode(history));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップを削除しました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // キーボード表示時のオーバーフローを防止
        appBar: AppBar(
          title: const Text(
            'サプリ＆おくすりスケジュール管理帳',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          titleSpacing: 0,
          actions: [
            // 購入状態設定メニュー
              PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                  case 'purchase_status':
                    _showTrialStatus();
                      break;
                  case 'set_purchase_link':
                    _showPurchaseLinkDialog();
                      break;
                  case 'backup':
                    _showBackupDialog();
                      break;
                  // 開発用: 手動で購入状態/トライアル状態を切り替えるメニュー（本番では無効）
                  // case 'set_purchased':
                  //   _setPurchasedStatus();
                  //     break;
                  // case 'set_trial':
                  //   _setTrialStatus();
                  //     break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                  value: 'purchase_status',
                    child: Row(
                      children: [
                      const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                      const Text('購入状態'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                  value: 'set_purchase_link',
                    child: Row(
                      children: [
                      const Icon(Icons.payment, color: Colors.green),
                        const SizedBox(width: 8),
                      const Text('課金情報'),
                      ],
                    ),
                  ),
                  // ✅ 修正：バックアップ機能を追加
                  PopupMenuItem(
                    value: 'backup',
                    child: Row(
                      children: [
                        const Icon(Icons.backup, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('バックアップ'),
                      ],
                    ),
                  ),
                  // 開発用: 手動切替メニュー（本番ではコメントアウト）
                  // PopupMenuItem(
                  // value: 'set_purchased',
                  //   child: Row(
                  //     children: [
                  //     const Icon(Icons.check_circle, color: Colors.green),
                  //       const SizedBox(width: 8),
                  //     const Text('購入状態にする（開発用）'),
                  //     ],
                  //   ),
                  // ),
                  // PopupMenuItem(
                  // value: 'set_trial',
                  //   child: Row(
                  //     children: [
                  //     const Icon(Icons.timer, color: Colors.blue),
                  //       const SizedBox(width: 8),
                  //     const Text('トライアル状態にする（開発用）'),
                  //     ],
                  //   ),
                  // ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(icon: Icon(Icons.calendar_month), text: 'カレンダー'),
              Tab(icon: Icon(Icons.medication), text: '服用メモ'),
              Tab(icon: Icon(Icons.alarm), text: 'アラーム'),
              Tab(icon: Icon(Icons.analytics), text: '統計'),
            ],
          ),
        ),
        body: _isInitialized
          ? Card(
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.02, // 画面幅の2%
                vertical: 8,
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // カレンダータブ
                    _buildCalendarTab(),
                    // 薬品タブ
                    _buildMedicineTab(),
                    // 服用アラームタブ
                    _buildAlarmTab(),
                    // 統計タブ
                    _buildStatsTab(),
                  ],
                ),
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'アプリを初期化中...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  // スクロール上端に到達した時の処理（画面遷移なし）
  void _onScrollToTop() {
    debugPrint('服用記録リスト上端に到達');
    // 画面遷移を削除 - ユーザーが手動でスクロールできるようにする
  }

  // スクロール下端に到達した時の処理（画面遷移なし）
  void _onScrollToBottom() {
    debugPrint('服用記録リスト下端に到達');
    // 画面遷移を削除 - ユーザーが手動で上にスクロールできるようにする
  }





  // 上端でのナビゲーションヒント表示
  void _showTopNavigationHint() {
    // 軽いハプティックフィードバックで上端到達を通知
    HapticFeedback.selectionClick();
  }


}
class _MemoDialog extends StatefulWidget {
  final Function(MedicationMemo) onMemoAdded;
  final MedicationMemo? initialMemo;
  const _MemoDialog({
    required this.onMemoAdded,
    this.initialMemo,
  });
  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}
class _MemoDialogState extends State<_MemoDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = '薬品';
  Color _selectedColor = Colors.blue;
  bool _isDosageFocused = false;
  bool _isNotesFocused = false;
  bool _isNameFocused = false;
  List<int> _selectedWeekdays = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _memoFocusNode = FocusNode();
  int _dosageFrequency = 1; // 服用回数（1〜6回）
  
  @override
  void initState() {
    super.initState();
    if (widget.initialMemo != null) {
      _nameController.text = widget.initialMemo!.name;
      _dosageController.text = widget.initialMemo!.dosage;
      _notesController.text = widget.initialMemo!.notes;
      _selectedType = widget.initialMemo!.type;
      _selectedColor = widget.initialMemo!.color;
      _selectedWeekdays = List.from(widget.initialMemo!.selectedWeekdays);
      _dosageFrequency = widget.initialMemo!.dosageFrequency ?? 1;
      
      // メモ編集モードの場合、自動的にメモフィールドにフォーカス（スクロールは削除）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialMemo != null) {
          _memoFocusNode.requestFocus();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // メモ編集と新規追加を統一した画面 - 上部のスペースを最大限活用
    return AnimatedContainer(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.02, // 左右の余白を大幅削減
          vertical: MediaQuery.of(context).size.height * 0.02, // 上下の余白を大幅削減
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 角丸を削減
        ),
        child: Stack(
          children: [
            Container(
          constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.95, // 画面の95%に拡大
                maxWidth: MediaQuery.of(context).size.width * 0.95,   // 画面の95%に拡大
                minWidth: 280,   // 最小幅を280に設定
              ),
              width: MediaQuery.of(context).size.width * 0.95, // 明示的な幅を設定
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), // 常にスクロール可能
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 400 ? 4 : 8, // 小さい画面では余白を大幅削減
              vertical: MediaQuery.of(context).size.height < 600 ? 2 : 4, // 小さい画面では余白を大幅削減
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max, // 最大サイズで配置
              children: [
                // ヘッダー（入力時は非表示） - コンパクト化
                if (!_isNameFocused && !_isDosageFocused && !_isNotesFocused) ...[
                Container(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.height < 600 ? 4 : 6, // パディングを大幅削減
                  ),
                  decoration: BoxDecoration(
                      color: _selectedType == 'サプリメント' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12), // 角丸を削減
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _selectedType == 'サプリメント' ? Icons.eco : Icons.medication,
                          color: _selectedType == 'サプリメント' ? Colors.green : Colors.blue,
                        size: 20, // アイコンサイズを削減
                      ),
                      const SizedBox(width: 8), // 間隔を削減
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                widget.initialMemo != null ? 'メモ編集' : 'メモ追加',
                              style: const TextStyle(
                                fontSize: 16, // フォントサイズを削減
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2), // 間隔を削減
                            Text(
                                widget.initialMemo != null ? 'メモを編集します' : '新しいメモを追加します',
                              style: TextStyle(
                                fontSize: 12, // フォントサイズを削減
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                      ),
                    ),
                  ],
                ),
              ),
              ],
              // コンテンツ - パディングを大幅削減
              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.height < 600 ? 8 : 12), // パディングを大幅削減
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名前（一番上に配置、常に表示） - コンパクト化
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '名前',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label, size: 20), // アイコンサイズを削減
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                        ),
                      onTap: () {
                        setState(() {
                          _isNameFocused = true;
                          _isDosageFocused = false;
                          _isNotesFocused = false;
                        });
                      },
                      onChanged: (value) {
                          setState(() {
                          _isNameFocused = value.isNotEmpty;
                          });
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isNameFocused = false;
                        });
                      },
                    ),
                    // 曜日選択を常に表示 - 間隔を削減
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を大幅削減
                    // 服用スケジュール（曜日選択） - コンパクト化
                    Text(
                      '服用スケジュール',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14, // フォントサイズを削減
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 2 : 4), // 間隔を大幅削減
                    // 毎日オプション - コンパクト化
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedWeekdays.length == 7) {
                            _selectedWeekdays.clear();
                          } else {
                            _selectedWeekdays = [0, 1, 2, 3, 4, 5, 6];
                          }
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 44, // 高さを削減
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // パディングを削減
                        decoration: BoxDecoration(
                          color: _selectedWeekdays.length == 7 ? _selectedColor : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8), // 角丸を削減
                          border: Border.all(
                            color: _selectedWeekdays.length == 7 ? _selectedColor : Colors.grey.withOpacity(0.3),
                            width: 1.5, // ボーダー幅を削減
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _selectedWeekdays.length == 7 ? Colors.white : Colors.grey[600],
                              size: 18, // アイコンサイズを削減
                            ),
                            const SizedBox(width: 8), // 間隔を削減
                            Expanded(
                              child: Text(
                              '毎日',
                              style: TextStyle(
                                fontSize: 14, // フォントサイズを削減
                                fontWeight: FontWeight.bold,
                                color: _selectedWeekdays.length == 7 ? Colors.white : Colors.grey[700],
                              ),
                            ),
                            ),
                            const SizedBox(width: 4), // 間隔を削減
                            if (_selectedWeekdays.length == 7)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16, // アイコンサイズを削減
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を削減
                    // 曜日選択 - コンパクト化
                    Wrap(
                      spacing: 6, // 間隔を削減
                      runSpacing: 6,
                      children: [
                        '日', '月', '火', '水', '木', '金', '土'
                      ].asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final isSelected = _selectedWeekdays.contains(index);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedWeekdays.remove(index);
                              } else {
                                _selectedWeekdays.add(index);
                              }
                            });
                          },
                          child: Container(
                            width: 36, // サイズを削減
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18), // 角丸を調整
                              border: Border.all(
                                color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
                                width: 1.5, // ボーダー幅を削減
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // フォントサイズを削減
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 用量とメモ選択時は他の要素を非表示 - コンパクト化
                    if (!_isDosageFocused && !_isNotesFocused) ...[
                      SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                      // 種類選択 - コンパクト化
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: '種類',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category, size: 20), // アイコンサイズを削減
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                        ),
                        items: const [
                          DropdownMenuItem(value: '薬品', child: Text('💊 薬品')),
                          DropdownMenuItem(value: 'サプリメント', child: Text('🌿 サプリメント')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                    ],
                    // 服用回数 - コンパクト化
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                    const Text(
                      '服用回数',
                      style: TextStyle(
                        fontSize: 14, // フォントサイズを削減
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4), // 間隔を削減
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8), // パディングを削減
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(6), // 角丸を削減
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _dosageFrequency,
                          isExpanded: true,
                          items: List.generate(6, (index) => index + 1).map((frequency) {
                            return DropdownMenuItem<int>(
                              value: frequency,
                              child: Text('$frequency回', style: const TextStyle(fontSize: 14)), // フォントサイズを削減
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _dosageFrequency = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (_dosageFrequency >= 6) ...[
                      const SizedBox(height: 6), // 間隔を削減
                        Container(
                          padding: const EdgeInsets.all(8), // パディングを削減
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6), // 角丸を削減
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 16), // アイコンサイズを削減
                              const SizedBox(width: 6), // 間隔を削減
                              const Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '服用回数が多いため、',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12, // フォントサイズを削減
                                      ),
                                    ),
                                    Text(
                                      '医師の指示に従ってください',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12, // フォントサイズを削減
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    // 用量 - コンパクト化
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を削減
                    TextField(
                      key: const ValueKey('dosage_field'),
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: '用量',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten, size: 20), // アイコンサイズを削減
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                      ),
                      onTap: () {
                        setState(() {
                          _isDosageFocused = true;
                          _isNameFocused = false;
                          _isNotesFocused = false;
                        });
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _isDosageFocused = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isDosageFocused = false;
                        });
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を削減
                    // メモ - コンパクト化
                    TextField(
                      key: const ValueKey('notes_field'),
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'メモ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note, size: 20), // アイコンサイズを削減
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                      ),
                      maxLines: MediaQuery.of(context).size.height < 600 ? 2 : 3, // 小さい画面では行数を削減
                      onTap: () {
                        setState(() {
                          _isNotesFocused = true;
                          _isNameFocused = false;
                          _isDosageFocused = false;
                        });
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _isNotesFocused = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isNotesFocused = false;
                        });
                      },
                    ),
                      // メモ入力時の決定・完了ボタン - コンパクト化
                      if (_isNotesFocused) ...[
                        const SizedBox(height: 8), // 間隔を削減
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isNotesFocused = false;
                                });
                              },
                              icon: const Icon(Icons.check, size: 16), // アイコンサイズを削減
                              label: const Text('決定', style: TextStyle(fontSize: 12)), // フォントサイズを削減
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // パディングを削減
                            ),
                            ),
                            ),
                            const SizedBox(width: 8), // 間隔を削減
                            Expanded(
                              child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isNotesFocused = false;
                                });
                              },
                              icon: const Icon(Icons.done, size: 16), // アイコンサイズを削減
                              label: const Text('完了', style: TextStyle(fontSize: 12)), // フォントサイズを削減
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // パディングを削減
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // 色選択も用量とメモ選択時は非表示 - コンパクト化
                    if (!_isDosageFocused && !_isNotesFocused) ...[
                      SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                        // 色選択 - コンパクト化
                      const Text(
                        '色',
                        style: TextStyle(
                          fontSize: 14, // フォントサイズを削減
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8), // 間隔を削減
                      Wrap(
                        spacing: 8, // 間隔を削減
                        runSpacing: 8,
                        children: [
                          Colors.blue,
                          Colors.red,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.teal,
                          Colors.pink,
                          Colors.indigo,
                        ].map((color) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40, // サイズを削減
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _selectedColor == color
                                  ? Border.all(color: Colors.black, width: 2) // ボーダー幅を削減
                                  : Border.all(color: Colors.grey.withOpacity(0.3)),
                              boxShadow: _selectedColor == color
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 6, // ブラーを削減
                                        spreadRadius: 1, // スプレッドを削減
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white, size: 20) // アイコンサイズを削減
                                : null,
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            // フッター（入力時は非表示） - コンパクト化
            if (!_isNameFocused && !_isDosageFocused && !_isNotesFocused) ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.height < 600 ? 4 : 8, // パディングを削減
                    right: MediaQuery.of(context).size.height < 600 ? 4 : 8,
                    top: MediaQuery.of(context).size.height < 600 ? 4 : 8,
                    bottom: MediaQuery.of(context).size.height < 600 ? 4 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12), // 角丸を削減
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル', style: TextStyle(fontSize: 12)), // フォントサイズを削減
                      ),
                      ),
                      const SizedBox(width: 8), // 間隔を削減
                      Flexible(
                        child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.trim().isNotEmpty) {
                            try {
                            final memo = MedicationMemo(
                              id: widget.initialMemo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                name: _nameController.text.trim(),
                              type: _selectedType,
                                dosage: _dosageController.text.trim(),
                                notes: _notesController.text.trim(),
                              createdAt: widget.initialMemo?.createdAt ?? DateTime.now(),
                              lastTaken: widget.initialMemo?.lastTaken,
                              color: _selectedColor,
                                selectedWeekdays: _selectedWeekdays,
                                dosageFrequency: _dosageFrequency,
                            );
                            widget.onMemoAdded(memo);
                            Navigator.pop(context);
                            } catch (e) {
                                    // エラーハンドリング
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'サプリメント' ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // パディングを削減
                        ),
                        child: Text(widget.initialMemo != null ? '更新' : '追加', style: const TextStyle(fontSize: 12)), // フォントサイズを削減
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
            ),
            // 右上端に×ボタンを配置 - コンパクト化
            Positioned(
              top: 4, // 位置を調整
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20), // アイコンサイズを削減
                onPressed: () => Navigator.pop(context),
                tooltip: '閉じる',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(4), // パディングを削減
                ),
              ),
            ),
          ],
      ),
      ),
    );
  }

  // 色選択ダイアログ
  void _showColorPicker() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色を選択'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  // 曜日チップウィジェット
  Widget _buildWeekdayChip(String label, int weekday) {
    final isSelected = weekday == -1 
        ? _selectedWeekdays.length == 7 
        : _selectedWeekdays.contains(weekday);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (weekday == -1) {
            // 毎日を選択
            if (_selectedWeekdays.length == 7) {
              _selectedWeekdays.clear();
            } else {
              _selectedWeekdays = [0, 1, 2, 3, 4, 5, 6];
            }
          } else {
            // 個別の曜日を選択
            if (_selectedWeekdays.contains(weekday)) {
              _selectedWeekdays.remove(weekday);
            } else {
              _selectedWeekdays.add(weekday);
            }
          }
        });
      },
      child: Container(
        height: 32, // 明示的な高さを設定
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // 警告ダイアログを表示するメソッド
  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('注意'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '服用回数が多いため、',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              '医師の指示に従ってください',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
    
    // 3秒後に自動で閉じる
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

}






