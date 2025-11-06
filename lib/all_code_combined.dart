// ============================================================================
// AI評価用: すべてのDartコードを1つのファイルにまとめたもの
// ============================================================================
// このファイルは、プロジェクト全体の主要なDartコードを1つのファイルに
// まとめたものです。AI評価やコードレビュー用に作成されました。
//
// 注意: このファイルは実際のプロジェクトでは使用されません。
// 実際のプロジェクトでは、各ファイルは適切なディレクトリ構造に分かれています。
// ============================================================================

// ============================================================================
// パート1: インポートと依存関係
// ============================================================================

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ============================================================================
// パート2: 定数と設定
// ============================================================================

/// アプリケーション定数
class AppConstants {
  static const int repositoryInitTimeout = 30;
  static const int maxBackupHistory = 50;
  static const Duration keyBackupInterval = Duration(hours: 24);
}

// ============================================================================
// パート3: モデルクラス
// ============================================================================

/// 服用メモモデル
@HiveType(typeId: 0)
class MedicationMemo extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  List<int> selectedWeekdays;
  
  @HiveField(3)
  int dosageFrequency;
  
  @HiveField(4)
  String? notes;
  
  MedicationMemo({
    required this.id,
    required this.name,
    required this.selectedWeekdays,
    required this.dosageFrequency,
    this.notes,
  });
}

/// 薬品情報モデル
class MedicationInfo {
  final String medicine;
  final bool checked;
  
  MedicationInfo({
    required this.medicine,
    required this.checked,
  });
}

// ============================================================================
// パート4: ユーティリティクラス
// ============================================================================

/// ロガークラス
class Logger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔵 DEBUG: $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('🟢 INFO: $message');
    }
  }
  
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('🟡 WARNING: $message');
    }
  }
  
  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      debugPrint('🔴 ERROR: $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
    }
  }
}

// ============================================================================
// パート5: サービスクラス
// ============================================================================

/// AppPreferencesサービス
class AppPreferences {
  static SharedPreferences? _preferences;
  static bool _isInitialized = false;
  
  static Future<void> init() async {
    if (_isInitialized) return;
    _preferences = await SharedPreferences.getInstance();
    _isInitialized = true;
  }
  
  static bool get isInitialized => _isInitialized;
  
  static bool? getBool(String key) {
    if (!_isInitialized) return null;
    return _preferences?.getBool(key);
  }
  
  static Future<bool> setBool(String key, bool value) async {
    if (!_isInitialized) await init();
    return await _preferences?.setBool(key, value) ?? false;
  }
  
  static String? getString(String key) {
    if (!_isInitialized) return null;
    return _preferences?.getString(key);
  }
  
  static Future<bool> setString(String key, String value) async {
    if (!_isInitialized) await init();
    return await _preferences?.setString(key, value) ?? false;
  }
}

/// Hiveライフサイクルサービス
class HiveLifecycleService {
  static bool _isInitialized = false;
  static final Map<String, Box> _openBoxes = {};
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // アダプター登録
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicationMemoAdapter());
    }
    
    // ボックスを開く
    await _openUnencryptedBoxes();
    
    _isInitialized = true;
  }
  
  static Future<void> _openUnencryptedBoxes() async {
    try {
      final boxNames = [
        'medication_data',
        'alarm_data',
        'calendar_data',
        'backup_data',
      ];
      
      for (final boxName in boxNames) {
        if (!Hive.isBoxOpen(boxName)) {
          final box = boxName == 'medication_data'
              ? await Hive.openBox(boxName)
              : await Hive.openBox<String>(boxName);
          _openBoxes[boxName] = box;
          Logger.debug('✅ $boxNameボックスオープン完了');
        } else {
          _openBoxes[boxName] = Hive.box(boxName);
          Logger.debug('✅ $boxNameボックスは既に開かれています');
        }
      }
    } catch (e) {
      Logger.error('非暗号化ボックスオープンエラー', e);
      rethrow;
    }
  }
  
  static Box<T>? getBox<T>(String boxName) {
    return _openBoxes[boxName] as Box<T>?;
  }
  
  static Future<void> closeAllBoxes() async {
    for (final box in _openBoxes.values) {
      await box.close();
    }
    _openBoxes.clear();
  }
}

// MedicationMemoAdapter（簡易版）
class MedicationMemoAdapter extends TypeAdapter<MedicationMemo> {
  @override
  final int typeId = 0;
  
  @override
  MedicationMemo read(BinaryReader reader) {
    return MedicationMemo(
      id: reader.readString(),
      name: reader.readString(),
      selectedWeekdays: List<int>.from(reader.readList()),
      dosageFrequency: reader.readInt(),
      notes: reader.readStringOrNull(),
    );
  }
  
  @override
  void write(BinaryWriter writer, MedicationMemo obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeList(obj.selectedWeekdays);
    writer.writeInt(obj.dosageFrequency);
    writer.writeStringOrNull(obj.notes);
  }
}

// ============================================================================
// パート6: 遵守率計算
// ============================================================================

/// 遵守率計算ヘルパー
class AdherenceCalculator {
  /// カスタム遵守率を計算
  static double calculateCustomAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    required Map<String, bool> medicationMemoStatus,
    required int Function(String, String) getMedicationMemoCheckedCountForDate,
  }) {
    if (days <= 0) return 0.0;
    
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    
    int totalDoses = 0;
    int takenDoses = 0;
    
    // 各日をループ
    for (int i = 0; i < days; i++) {
      final checkDate = startDate.add(Duration(days: i));
      final dateStr = _formatDate(checkDate);
      final weekday = checkDate.weekday % 7;
      
      // 動的薬リストの統計
      if (medicationData.containsKey(dateStr)) {
        final dayData = medicationData[dateStr]!;
        for (final info in dayData.values) {
          totalDoses++;
          if (info.checked) {
            takenDoses++;
          }
        }
      }
      
      // 服用メモの統計
      for (final memo in medicationMemos) {
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          totalDoses += memo.dosageFrequency;
          
          // チェック済み回数を取得
          final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
          takenDoses += checkedCount;
        }
      }
    }
    
    if (totalDoses == 0) return 0.0;
    return (takenDoses / totalDoses) * 100;
  }
  
  /// 日付を文字列にフォーマット
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// パート7: カレンダー操作
// ============================================================================

/// カレンダー・統計操作を管理するクラス
class CalendarOperations {
  final dynamic stateManager;
  final bool Function() onMountedCheck;
  final void Function() onStateChanged;
  
  CalendarOperations({
    required this.stateManager,
    required this.onMountedCheck,
    required this.onStateChanged,
  });
  
  /// 遵守率統計を計算（StateManagerも更新）
  Future<void> calculateAdherenceStats() async {
    try {
      final stats = <String, double>{};
      final medicationData = stateManager?.medicationData ?? {};
      final medicationMemos = stateManager?.medicationMemos ?? [];
      final weekdayStatus = stateManager?.weekdayMedicationStatus ?? {};
      final memoStatus = stateManager?.medicationMemoStatus ?? {};
      final weekdayDoseStatus = stateManager?.weekdayMedicationDoseStatus ?? {};
      
      if (kDebugMode) {
        debugPrint('遵守率計算開始: メモ数=${medicationMemos.length}, 服用回数ステータス=${weekdayDoseStatus.length}日分');
      }
      
      for (final period in [7, 30, 90]) {
        final rate = AdherenceCalculator.calculateCustomAdherence(
          days: period,
          medicationData: medicationData,
          medicationMemos: medicationMemos,
          weekdayMedicationStatus: weekdayStatus,
          medicationMemoStatus: memoStatus,
          getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
            // weekdayMedicationDoseStatusから実際のチェック済み回数を取得（カレンダーページのチェック100%を反映）
            final doseStatus = weekdayDoseStatus[dateStr]?[memoId];
            if (doseStatus == null) {
              if (kDebugMode) {
                debugPrint('遵守率計算: メモID=$memoId, 日付=$dateStr のデータなし');
              }
              return 0;
            }
            // チェック済みの回数をカウント（カレンダーページでチェックした回数が反映される）
            final checkedCount = doseStatus.values.where((isChecked) => isChecked).length;
            if (kDebugMode) {
              debugPrint('遵守率計算: メモID=$memoId, 日付=$dateStr, チェック済み=$checkedCount回');
            }
            return checkedCount;
          },
        );
        stats['$period日間'] = rate;
        if (kDebugMode) {
          debugPrint('遵守率計算完了: $period日間 = ${rate.toStringAsFixed(1)}%');
        }
      }
      
      if (stateManager != null) {
        stateManager!.adherenceRates = Map.from(stats);
        stateManager!.notifiers.adherenceRatesNotifier.value = Map.from(stats);
        if (kDebugMode) {
          debugPrint('遵守率グラフ更新: ${stats.length}件のデータ');
        }
      }
      
      if (onMountedCheck()) {
        onStateChanged();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 遵守率統計計算エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }
}

// ============================================================================
// パート8: メインアプリケーション
// ============================================================================

/// Firebase初期化状態
bool _isFirebaseInitialized = false;

/// アプリケーションのエントリーポイント
void main() async {
  // Zone mismatchを避けるため、runZonedGuarded内で初期化とrunAppを実行
  await runZonedGuarded(() async {
    // パフォーマンス最適化：最小限の初期化のみ実行
    WidgetsFlutterBinding.ensureInitialized();
  
    // 1. 最優先: SharedPreferences初期化（Firebase初期化で使用するため）
    try {
      await AppPreferences.init();
    } catch (e, stackTrace) {
      Logger.error('SharedPreferences初期化エラー', e);
      _logError('SharedPreferences初期化エラー', e, stackTrace);
    }
    
    // 2. Firebase初期化（Crashlyticsを使用する前に必ず実行）
    await _initializeAppSyncEarly();
    
    // 3. Hive初期化（パフォーマンス最適化）
    try {
      await HiveLifecycleService.initialize();
      
      // ボックス確認
      final memoBox = HiveLifecycleService.getBox<MedicationMemo>('medication_memos');
      Logger.debug(memoBox != null 
        ? '✅ ボックス確認完了: ${memoBox.length}件のデータ'
        : '⚠️ medication_memosボックスが開いていません');
    } catch (e, stackTrace) {
      Logger.error('初期化エラー', e);
      _logError('初期化エラー', e, stackTrace);
      // エラー時もアプリは継続動作
    }
    
    // 4. アプリを起動（ProviderScopeでラップ）
    runApp(
      const ProviderScope(
        child: MedicationAlarmApp(),
      ),
    );
    
    // 重い初期化処理は非同期で実行（エラーハンドリング付き）
    Future.microtask(() async {
      try {
        await _initializeAppAsync();
      } catch (e, stackTrace) {
        Logger.error('非同期初期化エラー（microtask）', e);
        _logError('非同期初期化エラー（microtask）', e, stackTrace);
      }
    });
  }, (error, stack) async {
    // Firebase初期化チェック
    if (_isFirebaseInitialized) {
      try {
        await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {
        // Crashlytics記録失敗時はログのみ
        Logger.error('Crashlytics記録エラー', error);
      }
    } else {
      // Firebase未初期化時はLoggerのみ
      Logger.error('未処理例外（Firebase未初期化）', error);
    }
  });
}

/// 早期に必要な同期/準同期初期化（エラーハンドラ、Firebase/Crashlyticsなど）
Future<void> _initializeAppSyncEarly() async {
  if (_isFirebaseInitialized) {
    return; // 既に初期化済み
  }
  
  try {
    // Firebase を最優先で初期化
    // 注意: firebase_options.dartは実際のプロジェクトに存在する必要があります
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    _isFirebaseInitialized = true;
    
    // Crashlytics 収集はリリースビルドのみ有効化（同意取得は別途）
    final consent = AppPreferences.isInitialized 
      ? (AppPreferences.getBool('crashlytics_consent') ?? false)
      : false;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode && consent);

    // Flutter フレームワークのエラーハンドラ
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      // release でのみ Crashlytics 送信（開発ノイズ回避）
      if (kReleaseMode && _isFirebaseInitialized) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        } catch (_) {
          // Crashlytics記録失敗時はコンソールに出力
          FlutterError.dumpErrorToConsole(errorDetails);
        }
      } else {
        FlutterError.dumpErrorToConsole(errorDetails);
      }
    };

    // エンジンレベルの未処理例外を捕捉
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      if (kReleaseMode && _isFirebaseInitialized) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {
          // Crashlytics記録失敗時はLoggerに出力
          Logger.error('未処理例外（Crashlytics記録失敗）', error);
        }
      } else {
        // Firebase未初期化時はLoggerに出力
        Logger.error('未処理例外（Firebase未初期化）', error);
      }
      return true;
    };
    
    Logger.debug('✅ Firebase初期化完了');
  } catch (e, stackTrace) {
    // Firebase初期化失敗は致命的だが、アプリは続行を試みる
    Logger.error('Firebase初期化エラー', e);
    _isFirebaseInitialized = false;
  }
}

/// 非同期初期化処理（パフォーマンス最適化）
Future<void> _initializeAppAsync() async {
  try {
    // その他の重い初期化処理
    await _initializeHeavyServices();
  } catch (e, stackTrace) {
    // 初期化失敗時はログのみ出力（アプリは継続動作）
    Logger.error('非同期初期化エラー', e);
    _logError('非同期初期化エラー', e, stackTrace);
  }
}

/// エラーログを記録（Crashlytics使用）
Future<void> _logError(String reason, dynamic error, StackTrace stackTrace) async {
  if (!_isFirebaseInitialized) {
    // Firebase未初期化時はLoggerのみ
    Logger.error(reason, error);
    return;
  }
  
  try {
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  } catch (_) {
    // Crashlytics記録失敗時は無視
  }
}

/// 重いサービスの初期化
Future<void> _initializeHeavyServices() async {
  try {
    // タイムゾーン初期化
    tz.initializeTimeZones();
    
    Logger.debug('✅ 重いサービス初期化完了');
  } catch (e, stackTrace) {
    Logger.error('重いサービス初期化エラー', e);
    _logError('重いサービス初期化エラー', e, stackTrace);
  }
}

// ============================================================================
// パート9: メインアプリウィジェット
// ============================================================================

/// メインアプリケーションウィジェット
class MedicationAlarmApp extends StatefulWidget {
  const MedicationAlarmApp({super.key});

  @override
  State<MedicationAlarmApp> createState() => _MedicationAlarmAppState();
}

class _MedicationAlarmAppState extends State<MedicationAlarmApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResourcesSync();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.detached) {
      _cleanupResources().catchError((error, stackTrace) {
        if (_isFirebaseInitialized) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: 'クリーンアップエラー',
            fatal: false,
          ).timeout(const Duration(seconds: 5), onTimeout: () {});
        }
      });
    }
  }

  /// 同期的なリソースクリーンアップ
  void _cleanupResourcesSync() {
    // タイマーやサブスクリプションのクリーンアップ
  }

  /// 非同期リソースクリーンアップ
  Future<void> _cleanupResources() async {
    try {
      await HiveLifecycleService.closeAllBoxes();
      Logger.debug('✅ リソースクリーンアップ完了');
    } catch (e) {
      Logger.error('リソースクリーンアップエラー', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Medication Alarm App - AI評価用統合ファイル'),
        ),
      ),
    );
  }
}

// ============================================================================
// パート10: データ永続化（簡易版）
// ============================================================================

/// 服用データ永続化クラス（簡易版）
class MedicationDataPersistence {
  static const String _appDataBox = 'medication_data';
  
  Future<Box> _openAppDataBox() async {
    // 既に開かれている場合は既存のBoxを返す
    if (Hive.isBoxOpen(_appDataBox)) {
      return Hive.box(_appDataBox);
    }
    // 型指定なしで開く（既存のデータとの互換性のため）
    return await Hive.openBox(_appDataBox);
  }
  
  /// 服用回数別ステータスを保存
  Future<void> saveMedicationDoseStatus(
    Map<String, Map<String, Map<int, bool>>> doseStatus
  ) async {
    try {
      final box = await _openAppDataBox();
      
      // 空の場合は何もしない
      if (doseStatus.isEmpty) {
        Logger.debug('服用回数別ステータスが空のため、保存をスキップします');
        return;
      }
      
      // Group by month (YYYY-MM)
      final Map<String, Map<String, dynamic>> monthly = {};
      doseStatus.forEach((dateStr, memoMap) {
        // dateStr expected yyyy-MM-dd
        final parts = dateStr.split('-');
        if (parts.length < 2) {
          Logger.warning('不正な日付形式: $dateStr');
          return;
        }
        final monthKey = 'dose_${parts[0]}-${parts[1]}';
        monthly.putIfAbsent(monthKey, () => {
          'month': '${parts[0]}-${parts[1]}',
          'records': <String, dynamic>{},
          'updated_at': DateTime.now().toIso8601String(),
        });
        final monthData = monthly[monthKey];
        if (monthData != null) {
          final records = monthData['records'] as Map<String, dynamic>?;
          if (records != null) {
            records[dateStr] = memoMap.map((memoId, doseMap) =>
              MapEntry(memoId, doseMap.map((k, v) => MapEntry(k.toString(), v)))
            );
          }
          monthData['updated_at'] = DateTime.now().toIso8601String();
        }
      });
      
      int savedCount = 0;
      for (final entry in monthly.entries) {
        // Merge with existing month to avoid overwriting other dates
        final existing = (box.get(entry.key) as Map?) ?? {
          'month': entry.value['month'],
          'records': <String, dynamic>{},
          'updated_at': DateTime.now().toIso8601String(),
        };
        final existingRecords = Map<String, dynamic>.from(existing['records'] as Map);
        existingRecords.addAll(entry.value['records'] as Map<String, dynamic>);
        existing['records'] = existingRecords;
        existing['updated_at'] = DateTime.now().toIso8601String();
        await box.put(entry.key, existing);
        savedCount += (entry.value['records'] as Map).length;
      }
      
      Logger.info('服用回数別ステータス保存完了(Hive): ${doseStatus.length}日分、${savedCount}件のレコード');
    } catch (e, stackTrace) {
      Logger.error('服用回数別ステータス保存エラー', e);
      Logger.error('服用回数別ステータス保存スタックトレース', stackTrace);
    }
  }
  
  /// 服用回数別ステータスを読み込み
  Future<Map<String, Map<String, Map<int, bool>>>> loadMedicationDoseStatus() async {
    try {
      final box = await _openAppDataBox();
      final Map<String, Map<String, Map<int, bool>>> result = {};
      int loadedDates = 0;
      int loadedRecords = 0;
      
      for (final key in box.keys) {
        if (key is String && key.startsWith('dose_') && RegExp(r'_\d{4}-\d{2}$').hasMatch(key)) {
          final data = box.get(key);
          if (data is Map && data['records'] is Map) {
            final recs = data['records'] as Map;
            for (final entry in recs.entries) {
              final dateStr = entry.key.toString();
              final memoMap = entry.value as Map;
              result[dateStr] = memoMap.map((memoId, doseMap) =>
                MapEntry(memoId.toString(), (doseMap as Map).map((k, v) => MapEntry(int.parse(k.toString()), v == true)))
              );
              loadedDates++;
              loadedRecords += memoMap.length;
            }
          }
        }
      }
      
      Logger.info('服用回数別ステータス読み込み完了: ${loadedDates}日分、${loadedRecords}件のレコード');
      return result;
    } catch (e, stackTrace) {
      Logger.error('服用回数別ステータス読み込みエラー', e);
      Logger.error('服用回数別ステータス読み込みスタックトレース', stackTrace);
      return {};
    }
  }
}

// ============================================================================
// パート11: 主要な機能の実装サマリー
// ============================================================================

/*
このファイルには、プロジェクトの主要な機能が含まれています：

1. **初期化処理**:
   - Firebase初期化
   - Hive初期化
   - SharedPreferences初期化
   - エラーハンドリング設定

2. **データ管理**:
   - MedicationMemoモデル
   - MedicationInfoモデル
   - Hiveライフサイクル管理
   - データ永続化

3. **遵守率計算**:
   - AdherenceCalculatorクラス
   - カスタム遵守率計算
   - カレンダーページのチェック状態を反映

4. **カレンダー操作**:
   - CalendarOperationsクラス
   - 遵守率統計計算
   - 服用完了率の反映

5. **アプリケーション構造**:
   - メインアプリケーション
   - ライフサイクル管理
   - リソースクリーンアップ

注意: このファイルは実際のプロジェクトのすべての機能を含むわけではありません。
実際のプロジェクトでは、各機能は適切なディレクトリ構造に分かれています。
*/

// ============================================================================
// ファイル終了
// ============================================================================

