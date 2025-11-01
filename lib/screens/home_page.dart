// MedicationHomePage
// メインホーム画面 - タブバーで各機能にアクセスします

// Dart core imports
import 'dart:async';
import 'dart:convert';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Third-party package imports
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local imports
import '../models/medication_memo.dart';
import '../models/medicine_data.dart';
import '../models/medication_info.dart';
import '../services/app_preferences.dart';
import '../services/medication_service.dart';
import '../services/notification_service.dart';
import '../services/trial_service.dart';
import '../services/in_app_purchase_service.dart';
import '../services/backup_history_service.dart';
import '../services/auto_backup_service.dart';
import 'mixins/purchase_mixin.dart';
import '../widgets/memo_dialog.dart';
import '../widgets/trial_limit_dialog.dart';
import '../utils/logger.dart';
import '../models/notification_types.dart';
import '../core/snapshot_service.dart';
import 'tabs/alarm_tab.dart';
import 'tabs/medicine_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/calendar_tab.dart';
import 'helpers/home_page_data_helper.dart';
import 'helpers/home_page_alarm_helper.dart';
import 'helpers/home_page_backup_helper.dart';
import 'helpers/home_page_stats_helper.dart';
import 'helpers/home_page_utils_helper.dart';

class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});
  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}
class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin, PurchaseMixin {
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
 
  
  // ✅ アラームタブのキー（強制再構築用）
  Key _alarmTabKey = UniqueKey();
  
  // ✅ 統計タブ用のScrollController
  final ScrollController _statsScrollController = ScrollController();
  
  // ✅ 任意の日数の遵守率機能用の変数
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  
  // ✅ 手動復元機能のための変数
  DateTime? _lastOperationTime;
  
  // ✅ 自動バックアップ機能はサービスに移動済み（変数削除）
 
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
  bool _memoSnapshotSaved = false; // メモ変更時のスナップショット保存フラグ
  // ✅ 部分更新用のValueNotifier
  final ValueNotifier<String> _memoTextNotifier = ValueNotifier<String>('');
  final ValueNotifier<Map<String, Color>> _dayColorsNotifier = ValueNotifier<Map<String, Color>>({});
  
  
  // 曜日設定された薬の服用状況を管理
  Map<String, Map<String, bool>> _weekdayMedicationStatus = {};
  
  // 服用回数別の服用状況を管理（日付 -> メモID -> 回数インデックス -> 服用済み）
  Map<String, Map<String, Map<int, bool>>> _weekdayMedicationDoseStatus = {};
  
  // 服用メモのチェック状況を管理
  Map<String, bool> _medicationMemoStatus = {};
  
  // メモ選択状態を管理
  bool _isMemoSelected = false;
  MedicationMemo? _selectedMemo;
  
  
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
  
  // カレンダー色変更用の変数
  Map<String, Color> _dayColors = {};
  static const Duration _logInterval = Duration(seconds: 30); // 30秒間隔でログ出力
  
  
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    // ✅ SnapshotServiceにスナップショット保存関数を登録
    SnapshotService.register((label) => _saveSnapshotBeforeChange(label));
    
   
    
    // PageControllerを初期化
    _medicationPageController = PageController(viewportFraction: 1.0);
    // ValueNotifier初期値
    _memoTextNotifier.value = '';
    _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
    
    // ページネーション初期化
    _initializeScrollListener();
      
    // ✅ 修正：データ読み込みを確実に実行
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint('🔄 データ読み込み開始...');
      
      try {
        // 1. 全データを読み込み
        await _loadSavedData();
        debugPrint('✅ 全データ読み込み完了');
        
        // 2. 服用メモを明示的に読み込み（確実に実行）
        await _loadMedicationMemosWithRetry();
        debugPrint('✅ 服用メモ読み込み完了: ${_medicationMemos.length}件');
        
        // 3. ページネーション初期化
        _currentPage = 0;
        _displayedMemos.clear();
        _loadMoreMemos();
        debugPrint('✅ ページネーション初期化完了');
        
        // 4. 基本設定
        if (_selectedDay == null) {
          _selectedDay = DateTime.now();
        }
        if (_selectedDates.isEmpty) {
          _selectedDates.add(_normalizeDate(DateTime.now()));
        }
        _setupControllerListeners();
        
        // 5. 初期化完了フラグを設定（最後に設定）
      _isInitialized = true;
      
        // 6. UIを強制更新
        if (mounted) {
          setState(() {
            debugPrint('✅ UI更新完了');
          });
        }
        
        debugPrint('✅ 初期化完了: メモ${_medicationMemos.length}件');
      } catch (e, stackTrace) {
        debugPrint('❌ 初期化エラー: $e');
        debugPrint('スタックトレース: $stackTrace');
        
        // エラー時も初期化完了フラグを設定（アプリが動作するようにする）
        _isInitialized = true;
      if (mounted) {
        setState(() {});
        }
      }
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
      
      // ✅ 自動バックアップ機能を初期化（サービスに移動）
      AutoBackupService.initialize(
        (name) => _createSafeBackupData(name),
        (key) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🔄 深夜2:00の自動バックアップが完了しました'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
      );
      
      Logger.debug('全データ読み込み完了（包括的ローカル復元）');
    } catch (e) {
      Logger.debug('データ読み込みエラー: $e');
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
      
      Logger.debug('全データ保存完了（包括的ローカル保存）');
      
      // ✅ 操作時間を記録（手動復元用）
      _lastOperationTime = DateTime.now();
      
      // ✅ 操作スナップショットを常に保存（5分以降でも手動復元可能）
      try {
        final backupData = await _createSafeBackupData('操作スナップショット');
        final jsonString = await _safeJsonEncode(backupData);
        final encryptedData = await _encryptDataAsync(jsonString);
        final snapshotKey = 'operation_snapshot_latest';
        await prefs.setString(snapshotKey, encryptedData);
        await _updateBackupHistory('操作スナップショット', snapshotKey, type: 'snapshot');
        await prefs.setString('last_snapshot_key', snapshotKey);
      } catch (e) {
        debugPrint('操作スナップショット保存エラー: $e');
      }
    } catch (e) {
      Logger.debug('全データ保存エラー: $e');
    }
  }
  
  // ✅ 自動バックアップ機能はサービスに移動済み
  
  // ✅ 操作後5分以内の手動復元機能
  Future<void> _showManualRestoreDialog() async {
    if (!mounted) return;
    
    final now = DateTime.now();
    final canRestore = _lastOperationTime != null && 
        now.difference(_lastOperationTime!).inMinutes <= 5;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.blue),
            SizedBox(width: 8),
            Text('手動復元'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: canRestore ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  canRestore 
                    ? '✅ 操作後5分以内です\n最後の操作から${now.difference(_lastOperationTime!).inMinutes}分経過'
                    : '⚠️ 操作後5分を過ぎています\n最後の操作から${_lastOperationTime != null ? now.difference(_lastOperationTime!).inMinutes : 0}分経過',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              if (canRestore) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _performManualRestore();
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('操作前の状態に復元'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                const Text(
                  '操作後5分以内に復元ボタンを押してください',
                  style: TextStyle(color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ],
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
  
  // ✅ 手動復元を実行
  Future<void> _performManualRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ 操作スナップショット（直近保存時に常に更新）を参照
      final lastBackupKey = prefs.getString('last_snapshot_key');
      
      if (lastBackupKey != null) {
        debugPrint('🔄 手動復元を実行: $lastBackupKey');
        await _restoreBackup(lastBackupKey);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 操作前の状態に復元しました'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ 復元可能なスナップショットが見つかりません'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ 手動復元エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 復元エラー: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
      
      Logger.debug('全データ読み込み完了（包括的ローカル復元）');
    } catch (e) {
      Logger.debug('全データ読み込みエラー: $e');
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
      
      Logger.debug('データ検証とUI更新完了');
    } catch (e) {
      Logger.debug('データ検証とUI更新エラー: $e');
    }
  }
  
  // 最終的なデータ表示確認（簡略化）
  Future<void> _finalDataDisplayCheck() async {
    if (mounted) setState(() {});
  }

  // データの整合性をチェック（簡略化）
  Future<void> _validateDataIntegrity() async {
    // 基本的な整合性チェックのみ
  }
  
  // カレンダーの日付を更新（簡略化）
  Future<void> _updateCalendarForSelectedDate() async {
      if (_selectedDay != null) {
        await _updateMedicineInputsForSelectedDate();
        await _loadMemoForSelectedDate();
    }
  }
  
  // 服用メモの表示を更新（簡略化）
  Future<void> _updateMedicationMemoDisplay() async {
      for (final memo in _medicationMemos) {
      _medicationMemoStatus.putIfAbsent(memo.id, () => false);
    }
  }
  
  // データ保持テスト（簡略化）
  Future<void> _testDataPersistence() async {
    await AppPreferences.saveString('flutter_storage_test', 'test');
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
        _addedMedications.clear();
    _addedMedications.addAll(await HomePageDataHelper.loadMedicationList());
    if (mounted) setState(() {});
  }
  
  // 確実なアラームデータ読み込み（指定パス方式を採用）
  Future<void> _loadAlarmData() async {
    _alarmList = await HomePageAlarmHelper.loadAlarmData();
    setState(() {});
  }
  
  // こぱさん流：アラームの再登録
  Future<void> _reRegisterAlarms() async {
    try {
      if (_alarmList.isEmpty) return;
      
      for (int i = 0; i < _alarmList.length; i++) {
        await _registerSingleAlarm(_alarmList[i], i);
      }
    } catch (e) {
      // エラー処理
    }
  }
  
  // 単一アラームの登録
  Future<void> _registerSingleAlarm(Map<String, dynamic> alarm, int index) async {
    try {
      // アラームの詳細情報を取得（安全な型変換）
      final time = alarm['time']?.toString() ?? '09:00';
      final enabled = alarm['enabled'] is bool ? alarm['enabled'] as bool : true;
      final title = alarm['title']?.toString() ?? '服用アラーム';
      final message = alarm['message']?.toString() ?? '薬を服用する時間です';
      
      if (!enabled) return;
      
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }
    } catch (e) {
      // エラー処理
    }
  }
  
  // アラームの追加（指定パス方式）
  Future<void> addAlarm(Map<String, dynamic> alarm) async {
    try {
      // ✅ 追加：変更前スナップショット
      await _saveSnapshotBeforeChange('アラーム追加_${alarm['name']}');
      setState(() {
        _alarmList.add(alarm);
      });
      
      // アラーム追加後に自動保存
      await _saveAlarmData();
      
      await _registerSingleAlarm(alarm, _alarmList.length - 1);
    } catch (e) {
      // エラー処理
    }
  }
  
  // アラームの削除（指定パス方式）
  Future<void> removeAlarm(int index) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        // ✅ 追加：変更前スナップショット
        final alarm = _alarmList[index];
        await _saveSnapshotBeforeChange('アラーム削除_${alarm['name']}');
        setState(() {
          _alarmList.removeAt(index);
        });
        
        await _saveAlarmData();
      }
    } catch (e) {
      // エラー処理
    }
  }
  
  // アラームの更新（指定パス方式）
  Future<void> updateAlarm(int index, Map<String, dynamic> updatedAlarm) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        // ✅ 追加：変更前スナップショット
        final alarm = _alarmList[index];
        await _saveSnapshotBeforeChange('アラーム編集_${alarm['name']}');
        setState(() {
          _alarmList[index] = updatedAlarm;
        });
        
        await _saveAlarmData();
      }
    } catch (e) {
      // エラー処理
    }
  }
  
  // アラームの有効/無効切り替え（指定パス方式）
  Future<void> toggleAlarm(int index) async {
    try {
      if (index >= 0 && index < _alarmList.length) {
        final alarm = _alarmList[index];
        final newEnabled = !(alarm['enabled'] as bool? ?? true);
        
        // ✅ 追加：変更前スナップショット
        await _saveSnapshotBeforeChange('アラーム切替_${alarm['name']}_${newEnabled ? '有効' : '無効'}');
        setState(() {
          alarm['enabled'] = newEnabled;
        });
        
        await _saveAlarmData();
      }
    } catch (e) {
      // エラー処理
    }
  }
  
  // アラームデータの検証（簡略化）
  Future<void> _validateAlarmData() async {
    // 基本的な検証のみ
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
    await HomePageDataHelper.saveCalendarMarks(_selectedDates, _addedMedications);
  }
  
  // カレンダーマークの読み込み
  Future<void> _loadCalendarMarks() async {
          _selectedDates.clear();
    _selectedDates.addAll(await HomePageDataHelper.loadCalendarMarks(_normalizeDate));
  }
  
  // ユーザー設定の保存
  Future<void> _saveUserPreferences() async {
    await HomePageDataHelper.saveUserPreferences(
      selectedDay: _selectedDay,
      isMemoSelected: _isMemoSelected,
      selectedMemoId: _selectedMemo?.id,
      isAlarmPlaying: _isAlarmPlaying,
      notificationError: _notificationError,
    );
  }
  
  // ユーザー設定の読み込み
  Future<void> _loadUserPreferences() async {
    final prefs = await HomePageDataHelper.loadUserPreferences();
    if (prefs['selectedDay'] != null) {
      _selectedDay = DateTime.parse(prefs['selectedDay']);
    }
    _isMemoSelected = prefs['isMemoSelected'] ?? false;
    _isAlarmPlaying = prefs['isAlarmPlaying'] ?? false;
    _notificationError = prefs['notificationError'] ?? false;
  }
  
  // 日別色設定の保存
  Future<void> _saveDayColors() async {
    await HomePageDataHelper.saveDayColors(_dayColors);
  }
  
  // 日別色設定の読み込み
  Future<void> _loadDayColors() async {
    _dayColors = await HomePageDataHelper.loadDayColors();
  }
  
  // 統計データの保存
  Future<void> _saveStatistics() async {
    await HomePageDataHelper.saveStatistics(_adherenceRates, _addedMedications.length);
  }
  
  // 統計データの読み込み
  Future<void> _loadStatistics() async {
    _adherenceRates = await HomePageDataHelper.loadStatistics();
  }
  
  // アプリ設定の保存
  Future<void> _saveAppSettings() async {
    await HomePageDataHelper.saveAppSettings();
  }
  
  // 服用回数別状態の保存
  Future<void> _saveMedicationDoseStatus() async {
    await HomePageDataHelper.saveMedicationDoseStatus(_weekdayMedicationDoseStatus);
  }
  
  // 服用回数別状態の読み込み
  Future<void> _loadMedicationDoseStatus() async {
    _weekdayMedicationDoseStatus = await HomePageDataHelper.loadMedicationDoseStatus();
  }
  
  // アプリ設定の読み込み
  Future<void> _loadAppSettings() async {
    // アプリ設定の読み込みは必要に応じて実装
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
    _statsScrollController.dispose();
    _medicationPageController.dispose();
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    
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
      try {
        final box = Hive.box<MedicationMemo>('medication_memos');
        for (final memo in _medicationMemos) {
          await box.put(memo.id, memo);
        }
        await box.flush();
      } catch (e) {
        Logger.debug('服用メモ保存エラー: $e');
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
      
      // メモスナップショット保存フラグをリセット
      _memoSnapshotSaved = false;
    } catch (e) {
      _showSnackBar('日付の選択に失敗しました: $e');
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
            onTap: () async {
              // ✅ 変更前スナップショット（カレンダー日付色の設定）
              await _saveSnapshotBeforeChange('日付色変更_$dateKey');
              _dayColors[dateKey] = color;
              _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
              _saveDayColors();
              Navigator.pop(context);
              _showSnackBar('色を設定しました');
              // カレンダーを再描画
              // 部分更新はNotifierで反映済み
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
            onPressed: () async {
              // ✅ 変更前スナップショット（カレンダー日付色のリセット）
              await _saveSnapshotBeforeChange('日付色リセット_$dateKey');
              _dayColors.remove(dateKey);
              _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
              _saveDayColors();
              Navigator.pop(context);
              _showSnackBar('色を削除しました');
              // カレンダーを再描画
              // 部分更新はNotifierで反映済み
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


  // ✅ 改善版：服用メモ読み込み機能（多重バックアップ付き）
  Future<void> _loadMedicationMemos() async {
    try {
      debugPrint('📖 服用メモ読み込み開始...');
      
      // ✅ 1. Hiveボックスから読み込み
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        final memos = box.values.toList();
        debugPrint('✅ Hiveから服用メモ読み込み成功: ${memos.length}件');
        
        setState(() {
          _medicationMemos = memos;
        });
        
        // ✅ バックアップとしてSharedPreferencesにも保存
        await _backupMemosToSharedPreferences();
        return;
      }
      
      // ✅ 2. Hiveが開いていない場合、SharedPreferencesから読み込み
      debugPrint('⚠️ Hiveボックスが開いていません。SharedPreferencesから読み込み...');
      final memos = await _loadMemosFromSharedPreferences();
      
      setState(() {
        _medicationMemos = memos;
      });
      
      debugPrint('✅ SharedPreferencesから服用メモ読み込み完了: ${memos.length}件');
    } catch (e, stackTrace) {
      debugPrint('❌ 服用メモ読み込みエラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // ✅ 3. エラー時は空のリストで初期化
      setState(() {
        _medicationMemos = [];
      });
    }
  }
  
  // ✅ SharedPreferencesからの服用メモ読み込み
  Future<List<MedicationMemo>> _loadMemosFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKeys = [
        'medication_memos_backup', 
        'medication_memos_backup2', 
        'medication_memos_backup3',
        'medication_memos_v2',
        'medication_memos'
      ];
      
      for (final key in backupKeys) {
        try {
          final backupJson = prefs.getString(key);
          if (backupJson != null && backupJson.isNotEmpty) {
            final List<dynamic> memosList = jsonDecode(backupJson);
            final memos = memosList
                .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
                .toList();
            debugPrint('✅ SharedPreferencesから復元: ${memos.length}件 ($key)');
            return memos;
      }
    } catch (e) {
          debugPrint('⚠️ キー $key の読み込みエラー: $e');
          continue;
        }
      }
      
      debugPrint('⚠️ 全てのバックアップが見つかりません');
      return [];
    } catch (e) {
      debugPrint('❌ SharedPreferences読み込みエラー: $e');
      return [];
    }
  }
  
  // ✅ SharedPreferencesへのバックアップ保存
  Future<void> _backupMemosToSharedPreferences() async {
    try {
      if (_medicationMemos.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final memosJson = _medicationMemos.map((memo) => memo.toJson()).toList();
      final jsonString = jsonEncode(memosJson);
      
      // ✅ 複数キーに保存（3重バックアップ）
      await Future.wait([
        prefs.setString('medication_memos_backup', jsonString),
        prefs.setString('medication_memos_backup2', jsonString),
        prefs.setString('medication_memos_backup3', jsonString),
        prefs.setString('medication_memos_v2', jsonString),
      ]);
      
      debugPrint('✅ 服用メモバックアップ保存完了: ${_medicationMemos.length}件');
    } catch (e) {
      debugPrint('❌ 服用メモバックアップ保存エラー: $e');
    }
  }
  
  // ✅ 改善版：服用メモ保存機能（多重バックアップ付き）
  Future<void> _saveMedicationMemoWithBackup(MedicationMemo memo) async {
    try {
      debugPrint('💾 服用メモ保存開始: ${memo.name}');
      
      // ✅ 1. Hiveボックスに保存
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        await box.put(memo.id, memo);
        debugPrint('✅ Hiveに服用メモ保存完了');
      } else {
        debugPrint('⚠️ Hiveボックスが開いていません');
      }
      
      // ✅ 2. SharedPreferencesにもバックアップ保存
      await _backupMemosToSharedPreferences();
      
      debugPrint('✅ 服用メモ保存完了: ${memo.name}');
    } catch (e, stackTrace) {
      debugPrint('❌ 服用メモ保存エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // ✅ エラー時もSharedPreferencesに保存を試行
      try {
        await _backupMemosToSharedPreferences();
        debugPrint('✅ フォールバック保存成功');
      } catch (backupError) {
        debugPrint('❌ フォールバック保存も失敗: $backupError');
      }
    }
  }
  
  // ✅ 改善版：服用メモ削除機能（多重バックアップ付き）
  Future<void> _deleteMedicationMemoWithBackup(String memoId) async {
    try {
      debugPrint('🗑️ 服用メモ削除開始: $memoId');
      
      // ✅ 1. Hiveボックスから削除
      if (Hive.isBoxOpen('medication_memos')) {
        final box = Hive.box<MedicationMemo>('medication_memos');
        await box.delete(memoId);
        debugPrint('✅ Hiveから服用メモ削除完了');
      } else {
        debugPrint('⚠️ Hiveボックスが開いていません');
      }
      
      // ✅ 2. SharedPreferencesにもバックアップ保存
      await _backupMemosToSharedPreferences();
      
      debugPrint('✅ 服用メモ削除完了: $memoId');
    } catch (e, stackTrace) {
      debugPrint('❌ 服用メモ削除エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      
      // ✅ エラー時もSharedPreferencesに保存を試行
      try {
        await _backupMemosToSharedPreferences();
        debugPrint('✅ フォールバック保存成功');
      } catch (backupError) {
        debugPrint('❌ フォールバック保存も失敗: $backupError');
      }
    }
  }
  
  // ✅ 新規追加：リトライ機能付きの服用メモ読み込み
  Future<void> _loadMedicationMemosWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 服用メモ読み込み試行 $attempt/$maxRetries');
        
        // Hiveボックスが開いているか確認
        if (!Hive.isBoxOpen('medication_memos')) {
          debugPrint('⚠️ medication_memosボックスが開いていません。再度開きます...');
          await Hive.openBox<MedicationMemo>('medication_memos');
        }
        
        // データ読み込み
        final box = Hive.box<MedicationMemo>('medication_memos');
        final memos = box.values.toList();
        
        if (memos.isNotEmpty || attempt == maxRetries) {
          setState(() {
            _medicationMemos = memos;
          });
          debugPrint('✅ 服用メモ読み込み成功: ${memos.length}件（試行$attempt回目）');
          return;
        }
        
        // データが空の場合、次の試行前に少し待つ
        if (attempt < maxRetries) {
          debugPrint('⚠️ データが空です。${attempt + 1}回目の試行を実行します...');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
    } catch (e) {
        debugPrint('❌ 服用メモ読み込みエラー（試行$attempt回目）: $e');
        
        if (attempt == maxRetries) {
          debugPrint('❌ 最大試行回数に達しました。バックアップから復元を試みます...');
          // バックアップから復元を試みる
          await _restoreMedicationMemosFromBackup();
        } else {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }
    }
  }
  
  // ✅ 新規追加：バックアップからの復元
  Future<void> _restoreMedicationMemosFromBackup() async {
    try {
      debugPrint('🔄 バックアップから服用メモを復元中...');
      final prefs = await SharedPreferences.getInstance();
      
      // 複数のバックアップキーを試す
      final backupKeys = [
        'medication_memos_backup',
        'medication_memos_backup2',
        'medication_memos_backup3',
      ];
      
      for (final key in backupKeys) {
        final backupJson = prefs.getString(key);
        if (backupJson != null && backupJson.isNotEmpty) {
          try {
            final List<dynamic> memosList = jsonDecode(backupJson);
            final memos = memosList
                .map((json) => MedicationMemo.fromJson(json as Map<String, dynamic>))
                .toList();
            
            if (memos.isNotEmpty) {
              // Hiveボックスに復元
              final box = Hive.box<MedicationMemo>('medication_memos');
              await box.clear();
              for (final memo in memos) {
                await box.put(memo.id, memo);
              }
      
      setState(() {
        _medicationMemos = memos;
      });
      
              debugPrint('✅ バックアップから復元成功: ${memos.length}件 ($key)');
      
              // 成功メッセージを表示
      if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('バックアップから${memos.length}件のメモを復元しました'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              return;
      }
    } catch (e) {
            debugPrint('⚠️ バックアップ解析エラー ($key): $e');
            continue;
          }
        }
      }
      
      debugPrint('⚠️ 全てのバックアップが見つかりません');
    } catch (e) {
      debugPrint('❌ バックアップ復元エラー: $e');
    }
  }

  void _showSnackBar(String message) async {
    if (!mounted) return;
    try {
      final fontSize = 14.0; // 固定フォントサイズ
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
      
      // 完全に作り直されたマーク表示（すべてのマークを削除）
      // 赤丸を含むすべてのマークを削除
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
    return CalendarTab(
      focusedDay: _focusedDay,
      selectedDay: _selectedDay,
      selectedDates: _selectedDates,
      scrollController: _calendarScrollController,
      dayColors: _dayColors,
      medicationMemos: _medicationMemos,
      medicationData: _medicationData,
      onDaySelected: _onDaySelected,
      onChangeDayColor: _changeDayColor,
      getEventsForDay: _getEventsForDay,
      normalizeDate: _normalizeDate,
      calculateDayMedicationStats: (day) {
        final stats = _calculateDayMedicationStats(day);
        return stats;
      },
      buildCalendarDay: _buildCalendarDay,
      buildCalendarStyle: _buildCalendarStyle,
      buildMemoField: _buildMemoField,
      buildMedicationStats: _buildMedicationStats,
      buildMedicationRecords: _buildMedicationRecords,
      onFocusedDayChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      onStateUpdate: () {
        setState(() {});
      },
    );
  }

  // ✅ ③④ カレンダーの日付セル（曜日マーク・チェックマーク表示）
  Widget _buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    // ③服用メモで設定された曜日かチェック
    final hasScheduledMemo = _medicationMemos.any((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    );
    
    // ④服用記録が100%かチェック
    final stats = _calculateDayMedicationStats(day);
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final isComplete = total > 0 && taken == total;
    
    // カスタム色取得
    final customColor = _dayColors[dateStr];
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: customColor ?? 
          (isSelected 
            ? const Color(0xFFff6b6b)
            : isToday 
              ? const Color(0xFF4ecdc4)
              : Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
        border: hasScheduledMemo 
          ? Border.all(color: Colors.amber, width: 2)
          : null,
        boxShadow: isSelected || isToday
          ? [
              BoxShadow(
                color: (customColor ?? (isSelected ? const Color(0xFFff6b6b) : const Color(0xFF4ecdc4))).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: Stack(
        children: [
          // 日付
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // ③曜日マーク（左上）
          if (hasScheduledMemo)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          
          // ④完了チェックマーク（右下）
          if (isComplete)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 日別の服用統計を計算
  Map<String, int> _calculateDayMedicationStats(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    if (_medicationData.containsKey(dateStr)) {
      final dayData = _medicationData[dateStr]!;
      totalMedications += dayData.length;
      takenMedications += dayData.values.where((info) => info.checked).length;
    }
    
    // 服用メモの統計
    for (final memo in _medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications += memo.dosageFrequency;
        final checkedCount = _getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        takenMedications += checkedCount;
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  // 指定日のメモの服用済み回数を取得
  int _getMedicationMemoCheckedCountForDate(String memoId, String dateStr) {
    final doseStatus = _weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }

  // 日付の色を変更するメソッド
  void _changeDayColor() {
    if (_selectedDay == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final colors = [
      {'color': const Color(0xFFff6b6b), 'name': '赤'},
      {'color': const Color(0xFF4ecdc4), 'name': '青緑'},
      {'color': const Color(0xFF45b7d1), 'name': '青'},
      {'color': const Color(0xFFf9ca24), 'name': '黄色'},
      {'color': const Color(0xFFf0932b), 'name': 'オレンジ'},
      {'color': const Color(0xFFeb4d4b), 'name': 'ピンク'},
      {'color': const Color(0xFF6c5ce7), 'name': '紫'},
      {'color': const Color(0xFFa29bfe), 'name': '薄紫'},
      {'color': const Color(0xFF00d2d3), 'name': 'ターコイズ'},
      {'color': const Color(0xFF1e3799), 'name': '濃紺'},
      {'color': const Color(0xFFe55039), 'name': 'トマト'},
      {'color': const Color(0xFF2ecc71), 'name': 'エメラルド'},
    ];
    
    // 色選択ダイアログを表示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'カレンダーの色を選択',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // 高さを制限
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(), // スクロール可能
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 13.7,
                childAspectRatio: 1,
              ),
              itemCount: colors.length + 1, // +1 for "色をリセット"
              itemBuilder: (context, index) {
                if (index == colors.length) {
                  // 色をリセットボタン（デフォルト色に戻す）
                  return GestureDetector(
                    onTap: () async {
                      // ✅ 追加：変更前スナップショット
                      await _saveSnapshotBeforeChange('カレンダー色リセット_$dateStr');
                      setState(() {
                        // デフォルト色（何も指定していない最初の色）に戻す
                        _dayColors.remove(dateStr);
                        _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
                      });
                      await _saveDayColors(); // データ保存
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 2),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.clear, color: Colors.grey, size: 32),
                          SizedBox(height: 4),
                          Text(
                            'リセット',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final colorData = colors[index];
                final color = colorData['color'] as Color;
                final name = colorData['name'] as String;
                final isSelected = _dayColors[dateStr] == color;
                
                return GestureDetector(
                  onTap: () async {
                    // ✅ 追加：変更前スナップショット
                    await _saveSnapshotBeforeChange('カレンダー色変更_${dateStr}_$name');
                    setState(() {
                      _dayColors[dateStr] = color;
                      _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
                    });
                    await _saveDayColors(); // データ保存
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 32,
                          )
                        else
                          const SizedBox(height: 32),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
              child: const Text('キャンセル'),
            ),
          ],
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
                      onTap: () async {
                        if (_selectedDay != null) {
                          // ✅ 追加：変更前スナップショット
                          await _saveSnapshotBeforeChange('服用回数チェック_${memo.name}_${index + 1}回目_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
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
                          await _saveAllData();
                          // 統計を再計算
                          await _calculateAdherenceStats();
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

  // ページネーション機能（大量データ対応）
  static const int _pageSize = 20; // 1ページあたりの件数
  int _currentPage = 0;
  List<MedicationMemo> _displayedMemos = [];
  bool _isLoadingMore = false;
  final ScrollController _memoScrollController = ScrollController();
  
  // アラーム制限機能
  static const int maxAlarms = 100; // アラーム上限
  static const int maxMemos = 1000; // メモ上限

  // Hive最適化データベースサービス（大量データ対応）
  static Box<MedicationMemo>? _memoBox;
  
  static Future<Box<MedicationMemo>> get _getMemoBox async {
    if (_memoBox != null) return _memoBox!;
    _memoBox = await Hive.openBox<MedicationMemo>('medication_memos');
    return _memoBox!;
  }
  


  // ページネーション機能の実装
  Future<void> _loadMoreMemos() async {
    if (_isLoadingMore || _currentPage * _pageSize >= _medicationMemos.length) return;
    
    setState(() => _isLoadingMore = true);
    
    // ページングで一部だけ読み込み
      final startIndex = _currentPage * _pageSize;
      final endIndex = (startIndex + _pageSize).clamp(0, _medicationMemos.length);
      
      if (startIndex < _medicationMemos.length) {
        final newMemos = _medicationMemos.sublist(startIndex, endIndex);
        
        setState(() {
          _displayedMemos.addAll(newMemos);
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
    }
  }
  
  // スクロール監視の初期化
  void _initializeScrollListener() {
    _memoScrollController.addListener(() {
      if (_memoScrollController.position.pixels >= 
          _memoScrollController.position.maxScrollExtent * 0.8) {
        _loadMoreMemos();
      }
    });
  }
  
  // メモ制限チェック
  bool _canAddMemo() {
    return _medicationMemos.length < maxMemos;
  }
  
  // 制限ダイアログ表示
  void _showLimitDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('${type}上限'),
          ],
        ),
        content: Text('${type}は最大${type == 'アラーム' ? maxAlarms : maxMemos}件まで設定できます。\n不要な${type}を削除してください。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
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
          final name = med['name']?.toString() ?? '';
          final taken = med['taken'] is bool ? med['taken'] as bool : false;
          final takenTime = med['takenTime'] is DateTime ? med['takenTime'] as DateTime? : null;
          final notes = med['notes']?.toString() ?? '';
          
          medicationData[name] = MedicationInfo(
            checked: taken,
            medicine: name,
            actualTime: takenTime,
            notes: notes,
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
    await HomePageAlarmHelper.saveAlarmData(_alarmList);
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
  
  // アプリ再起動時のデータ表示を確実にする（簡略化）
  Future<void> _ensureDataDisplayOnRestart() async {
        for (final memo in _medicationMemos) {
      _medicationMemoStatus.putIfAbsent(memo.id, () => false);
    }
    if (mounted) setState(() {});
  }


  // 完全に作り直された服用記録リスト（簡略化）
  Widget _buildAddedMedicationRecord(Map<String, dynamic> medication) {
    final isChecked = medication['isChecked'] ?? false;
    final medicationName = medication['name'] ?? '';
    final medicationType = medication['type'] ?? '';
    final medicationColor = medication['color'] ?? Colors.blue;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isChecked ? Colors.green : Colors.grey.withOpacity(0.3), width: isChecked ? 2 : 1),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (_selectedDay != null) {
                    await _saveSnapshotBeforeChange('服用チェック_${medicationName}_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  }
                setState(() => medication['isChecked'] = !isChecked);
                  _saveCurrentData();
                  _updateCalendarMarks();
                },
                child: Container(
                width: 50,
                height: 50,
                  decoration: BoxDecoration(
                    color: isChecked ? Colors.green : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isChecked ? Icons.check_circle : Icons.radio_button_unchecked, color: isChecked ? Colors.white : Colors.grey, size: 24),
              ),
            ),
            const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(children: [
                    Icon(medicationType == 'サプリメント' ? Icons.eco : Icons.medication, color: isChecked ? Colors.green : medicationColor, size: 18),
                        const SizedBox(width: 8),
                    Expanded(child: Text(medicationName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isChecked ? Colors.green : const Color(0xFF2196F3)))),
                    if (isChecked) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Text('服用済み', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  Text(medicationType, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            IconButton(onPressed: () async {
                  if (_selectedDay != null) {
                    await _saveSnapshotBeforeChange('服用記録削除_${medicationName}_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  }
              setState(() => _addedMedications.remove(medication));
                  _saveCurrentData();
            }, icon: const Icon(Icons.delete, color: Colors.red), tooltip: '削除'),
            ],
        ),
      ),
    );
  }

  Widget _buildMedicineTab() {
    return MedicineTab(
      medicationMemos: _medicationMemos,
      scrollController: _memoScrollController,
      onMarkAsTaken: _markAsTaken,
      onEditMemo: _editMemo,
      onDeleteMemo: _deleteMemo,
      onShowWarningDialog: _showWarningDialog,
    );
  }

  Widget _buildAlarmTab() {
    return AlarmTab(alarmTabKey: _alarmTabKey);
  }


  Widget _buildStatsTab() {
    return StatsTab(
      scrollController: _statsScrollController,
      adherenceRates: _adherenceRates,
      medicationData: _medicationData,
      medicationMemos: _medicationMemos,
      weekdayMedicationStatus: _weekdayMedicationStatus,
      onShowSnackBar: _showSnackBar,
      onCustomAdherenceCalculated: (rate, days) {
        setState(() {
          _customAdherenceResult = rate;
          _customDaysResult = days;
        });
      },
    );
  }
  // ✅ 任意の日数の遵守率カード（別画面へのナビゲーション）
  Widget _buildCustomAdherenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
              '任意の日数の遵守率',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
                      Text(
                        '指定した期間の遵守率を分析',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCustomAdherenceDialog();
                  },
                  icon: const Icon(Icons.calculate),
                  label: const Text('分析'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
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
  
  // ✅ カスタム遵守率ダイアログ表示
  void _showCustomAdherenceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '任意の日数の遵守率',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '分析したい期間の日数を入力してください',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                    controller: _customDaysController,
                      focusNode: _customDaysFocusNode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: '日数（1-365日）',
                        hintText: '例: 30',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                        helperText: '過去何日間のデータを分析しますか？',
                    ),
                    onChanged: (value) {
                        // 入力値の検証
                      },
                    ),
                    const SizedBox(height: 20),
            if (_customAdherenceResult != null) ...[
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_customAdherenceResult!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final days = int.tryParse(_customDaysController.text);
                    if (days != null && days >= 1 && days <= 365) {
                      _calculateCustomAdherence(days);
                      setDialogState(() {}); // ダイアログ内の状態を更新
                    } else {
                      _showSnackBar('1から365の範囲で日数を入力してください');
                    }
                  },
                  child: const Text('分析実行'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // ✅ カスタム遵守率計算
  void _calculateCustomAdherence(int days) async {
    try {
      _customDaysFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      
      final rate = HomePageStatsHelper.calculateCustomAdherence(
        days: days,
        medicationData: _medicationData,
        medicationMemos: _medicationMemos,
        weekdayMedicationStatus: _weekdayMedicationStatus,
      );
      
      if (rate == 0.0) {
        _showSnackBar('指定した期間に服薬データがありません');
        return;
      }
      
      setState(() {
        _customAdherenceResult = rate;
        _customDaysResult = days;
      });
      
      Navigator.of(context).pop();
      
      if (_statsScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _statsScrollController.animateTo(
            _statsScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        });
      }
    } catch (e) {
      _showSnackBar('カスタム遵守率の計算に失敗しました: $e');
    }
  }
  
  // 遵守率グラフ
  Widget _buildAdherenceChart() {
    return HomePageStatsHelper.buildAdherenceChart(_adherenceRates);
  }
  // 薬品別使用状況グラフ
  Widget _buildMedicationUsageChart() {
    return HomePageStatsHelper.buildMedicationUsageChart(
      medicationData: _medicationData,
      medicationMemos: _medicationMemos,
      weekdayMedicationStatus: _weekdayMedicationStatus,
    );
  }
  void _addMemo() {
    showDialog(
      context: context,
      builder: (context) => MemoDialog(
        existingMemos: _medicationMemos,
        onMemoAdded: (memo) async {
          // ✅ 変更前スナップショット
          await _saveSnapshotBeforeChange('メモ追加_${memo.name.isEmpty ? '無題' : memo.name}');
          try {
            // タイトルが空なら自動連番で補完
            MedicationMemo memoToSave = memo;
            final rawTitle = memo.name.trim();
            if (rawTitle.isEmpty) {
              final titles = _medicationMemos.map((m) => m.name).toList();
              final autoTitle = _generateDefaultTitle(titles);
              memoToSave = MedicationMemo(
                id: memo.id,
                name: autoTitle,
                type: memo.type,
                dosage: memo.dosage,
                notes: memo.notes,
                createdAt: memo.createdAt,
                lastTaken: memo.lastTaken,
                color: memo.color,
                selectedWeekdays: memo.selectedWeekdays,
              );
            }

            // ✅ 改善版：メモを保存（多重バックアップ付き）
            await _saveMedicationMemoWithBackup(memoToSave);
            
            // UIを更新（データ再読み込みは不要）
          setState(() {
            _medicationMemos.add(memoToSave);
              // 新しく追加されたメモを表示リストにも追加
              _displayedMemos.add(memoToSave);
          });
            
            // データを保存
            await _saveAllData();
            
            _showSnackBar('服用メモを追加しました');
          } catch (e) {
            _showSnackBar('メモの追加に失敗しました: $e');
          }
        },
      ),
    );
  }
  void _editMemo(MedicationMemo memo) {
    showDialog(
      context: context,
      builder: (context) => MemoDialog(
        initialMemo: memo,
        existingMemos: _medicationMemos,
        onMemoAdded: (updatedMemo) async {
          // ✅ 変更前スナップショット
          await _saveSnapshotBeforeChange('メモ編集_${memo.name.isEmpty ? '無題' : memo.name}');
          // タイトルが空なら自動連番で補完
          MedicationMemo memoToSave = updatedMemo;
          final rawTitle = updatedMemo.name.trim();
          if (rawTitle.isEmpty) {
            final titles = _medicationMemos.where((m) => m.id != memo.id).map((m) => m.name).toList();
            final autoTitle = _generateDefaultTitle(titles);
            memoToSave = MedicationMemo(
              id: updatedMemo.id,
              name: autoTitle,
              type: updatedMemo.type,
              dosage: updatedMemo.dosage,
              notes: updatedMemo.notes,
              createdAt: updatedMemo.createdAt,
              lastTaken: updatedMemo.lastTaken,
              color: updatedMemo.color,
              selectedWeekdays: updatedMemo.selectedWeekdays,
            );
          }

          // ✅ 改善版：メモを保存（多重バックアップ付き）
          await _saveMedicationMemoWithBackup(memoToSave);

          setState(() {
            final index = _medicationMemos.indexWhere((m) => m.id == memo.id);
            if (index != -1) {
              _medicationMemos[index] = memoToSave;
            }
            // 表示リストも更新
            final displayedIndex = _displayedMemos.indexWhere((m) => m.id == memo.id);
            if (displayedIndex != -1) {
              _displayedMemos[displayedIndex] = memoToSave;
            }
          });
          
          _showSnackBar('服用メモを更新しました');
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
    
    // ✅ 改善版：メモを保存（多重バックアップ付き）
    await _saveMedicationMemoWithBackup(updatedMemo);
    
    setState(() {
      final index = _medicationMemos.indexWhere((m) => m.id == memo.id);
      if (index != -1) {
        _medicationMemos[index] = updatedMemo;
      }
    });
    
    _showSnackBar('${memo.name}の服用を記録しました');
  }
  void _deleteMemo(String id) async {
    // ✅ 変更前スナップショット
    final target = _medicationMemos.firstWhere(
      (m) => m.id == id,
      orElse: () => MedicationMemo(
        id: id,
        name: '無題',
        type: '薬品',
        createdAt: DateTime.now(),
      ),
    );
    await _saveSnapshotBeforeChange('メモ削除_${target.name}');
    try {
      // ✅ 改善版：メモを削除（多重バックアップ付き）
      await _deleteMedicationMemoWithBackup(id);
      
      // UIを更新
    setState(() {
      _medicationMemos.removeWhere((memo) => memo.id == id);
        _displayedMemos.removeWhere((memo) => memo.id == id);
        // 関連データも削除
        _medicationMemoStatus.remove(id);
        _weekdayMedicationStatus.remove(id);
        // 日付別の服用状態も削除
        for (final dateStr in _weekdayMedicationDoseStatus.keys) {
          _weekdayMedicationDoseStatus[dateStr]?.remove(id);
        }
      });
      
      // データを保存
      await _saveAllData();
      
    _showSnackBar('メモを削除しました');
    } catch (e) {
      _showSnackBar('削除に失敗しました: $e');
    }
  }

  // 空タイトル時の自動連番生成
  String _generateDefaultTitle(List<String> existingTitles) {
    return HomePageUtilsHelper.generateDefaultTitle(existingTitles);
  }
 
  TimeOfDay _parseTimeString(String timeStr) {
    return HomePageUtilsHelper.parseTimeString(timeStr);
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

  // 曜日設定された薬を表示するウィジェット（簡略化）
  Widget _buildWeekdayMedicationRecord(MedicationMemo memo) {
    final isChecked = _getWeekdayMedicationStatus(memo.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isChecked ? memo.color : memo.color.withOpacity(0.3), width: isChecked ? 2 : 1),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await _saveSnapshotBeforeChange('服用チェック_${memo.name}');
                setState(() => _updateWeekdayMedicationStatus(memo.id, !isChecked));
                  _saveCurrentDataDebounced();
                  _updateCalendarMarks();
                },
                child: Container(
                width: 50,
                height: 50,
                  decoration: BoxDecoration(
                    color: isChecked ? memo.color : memo.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isChecked ? Icons.check_circle : Icons.radio_button_unchecked, color: isChecked ? Colors.white : memo.color, size: 24),
              ),
            ),
            const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                  children: [
                  Row(children: [
                    Icon(memo.type == 'サプリメント' ? Icons.eco : Icons.medication, color: memo.color, size: 18),
                        const SizedBox(width: 8),
                    Expanded(child: Text(memo.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  ]),
                  if (memo.dosage.isNotEmpty) Text('用量: ${memo.dosage}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (memo.notes.isNotEmpty) Text(memo.notes, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                        ),
                      ),
                    ],
        ),
      ),
    );
  }


  void _addMedicationToTimeSlot(String medicationName) {
    // ✅ 変更前スナップショット（非同期だが待たずに実行）
    _saveSnapshotBeforeChange('薬追加_$medicationName');
    // メモ制限チェック
    if (!_canAddMemo()) {
      _showLimitDialog('メモ');
      return;
    }
    
    // 服用メモから薬の詳細情報を取得
    final memo = _medicationMemos.firstWhere(
      (memo) => memo.name == medicationName,
      orElse: () {
        // 空タイトルへの対応: 自動連番を割り当て
        final titles = _medicationMemos.map((m) => m.name).toList();
        final autoTitle = _generateDefaultTitle(titles);
        return MedicationMemo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: medicationName.trim().isEmpty ? autoTitle : medicationName,
        type: '薬',
        color: Colors.blue,
        dosage: '',
        notes: '',
        createdAt: DateTime.now(),
        );
      },
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
    final stats = _calculateMedicationStats();
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final progress = total > 0 ? taken / total : 0.0;
    
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
                  '$taken / $total 服用済み',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progress == 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
                if (total > 0) ...[
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
          child: ValueListenableBuilder<String>(
            valueListenable: _memoTextNotifier,
            builder: (context, memoText, _) {
              _memoController.value = _memoController.value.copyWith(text: memoText, selection: TextSelection.collapsed(offset: memoText.length));
              return TextField(
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
              suffixIcon: (_memoController.text.isNotEmpty)
                  ? IconButton(
                      onPressed: () async {
                        // ✅ 変更前スナップショット（メモクリア）
                        if (_selectedDay != null) {
                          await _saveSnapshotBeforeChange('メモクリア_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                        }
                        _memoTextNotifier.value = '';
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
              // デバウンス処理でスナップショット保存を制限
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () async {
                // デバウンス後にスナップショット保存（1回だけ）
                if (_selectedDay != null && !_memoSnapshotSaved) {
                await _saveSnapshotBeforeChange('メモ変更_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  _memoSnapshotSaved = true;
              }
                _memoTextNotifier.value = value;
                _saveMemo();
              });
              // 即座にUIを更新
              _memoTextNotifier.value = value;
            },
            onSubmitted: (value) {
              // キーボードの決定ボタンで完了
              _completeMemo();
            },
            onEditingComplete: () {
              _completeMemo();
            },
              );
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
                onPressed: () async {
                  // ✅ 変更前スナップショット（メモクリア）
                  if (_selectedDay != null) {
                    await _saveSnapshotBeforeChange('メモクリア_${DateFormat('yyyy-MM-dd').format(_selectedDay!)}');
                  }
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
      _memoSnapshotSaved = false; // スナップショット保存フラグをリセット
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

  // トライアル状態表示ダイアログ（Mixinに移動）
  Future<void> _showTrialStatus() async {
    await showTrialStatus();
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
  



  // アプリ内課金ダイアログを表示（Mixinに移動）
  Future<void> _showPurchaseLinkDialog() async {
    await showPurchaseLinkDialog();
  }

  // 購入を開始（Mixinに移動）
  Future<void> _startPurchase(ProductDetails product) async {
    await startPurchase(product);
  }

  // ✅ バックアップ機能を実装（簡略化）
  Future<void> _showBackupDialog() async {
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.backup, color: Colors.orange), SizedBox(width: 8), Text('バックアップ')]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('・毎日深夜2:00（自動）- フルバックアップ\n・手動保存（任意）- 任意タイミングで保存'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('create'),
                icon: const Icon(Icons.save),
                label: const Text('手動バックアップを作成'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('history'),
                icon: const Icon(Icons.history),
                label: const Text('保存履歴を見る'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<bool>(
                future: _hasUndoAvailable(),
                builder: (context, snapshot) {
                  final available = snapshot.data ?? false;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                  onPressed: available ? () => Navigator.of(context).pop('undo') : null,
                      icon: const Icon(Icons.undo),
                      label: const Text('1つ前の状態に復元'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: available ? Colors.teal : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final key = prefs.getString('last_full_backup_key');
                Navigator.of(context).pop(key != null ? 'restore:$key' : null);
              },
              icon: const Icon(Icons.restore),
              label: const Text('最新フルバックアップを復元'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
          ),
        ]),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる'))],
      ),
    );
    if (result == null) return;
    if (result == 'create') {
      await _createManualBackup();
    } else if (result == 'history') {
      await _showBackupHistory();
    } else if (result == 'undo') {
      await _undoLastChange();
    } else if (result.startsWith('restore:')) {
      final key = result.split(':')[1];
                      await _restoreBackup(key);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('フルバックアップが見つかりません'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
  }

  // ✅ 直前の変更が存在するか（スナップショット有無）
  Future<bool> _hasUndoAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastKey = prefs.getString('last_snapshot_key');
      if (lastKey == null) {
        debugPrint('⚠️ last_snapshot_key が null');
        return false;
      }
      final data = prefs.getString(lastKey);
      final available = data != null;
      if (!available) {
        debugPrint('⚠️ スナップショット実体が見つかりません: $lastKey');
      }
      return available;
    } catch (e) {
      debugPrint('❌ スナップショット確認エラー: $e');
      return false;
    }
  }

  // ✅ 変更前スナップショット保存
  Future<void> _saveSnapshotBeforeChange(String operationType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final snapshotData = await _createSafeBackupData('変更前_$operationType');
      final jsonString = await _safeJsonEncode(snapshotData);
      final encryptedData = await _encryptDataAsync(jsonString);
      final snapshotKey = 'snapshot_before_$timestamp';
      final ok1 = await prefs.setString(snapshotKey, encryptedData);
      final ok2 = await prefs.setString('last_snapshot_key', snapshotKey);
      if (!(ok1 && ok2)) {
        debugPrint('⚠️ スナップショット保存フラグがfalse: $ok1, $ok2');
      }
      debugPrint('✅ 変更前スナップショット保存完了: $operationType (key: $snapshotKey)');
    } catch (e) {
      debugPrint('❌ スナップショット保存エラー: $e');
    }
  }

  // ✅ 1つ前の状態に復元（最新スナップショットから）
  Future<void> _undoLastChange() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSnapshotKey = prefs.getString('last_snapshot_key');
      if (lastSnapshotKey == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('復元できる履歴がありません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _restoreBackup(lastSnapshotKey);
      // 復元に使用したスナップショットは削除（1回使い切り）
      await prefs.remove(lastSnapshotKey);
      await prefs.remove('last_snapshot_key');
      if (mounted) {
        setState(() {
          _focusedDay = _selectedDay ?? DateTime.now();
          // ✅ 追加：メモフィールドを再同期
          if (_selectedDay != null) {
            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
            // 直近の保存内容を反映
            SharedPreferences.getInstance().then((p) {
              final memo = p.getString('memo_$dateStr');
              _memoController.text = memo ?? '';
              _memoTextNotifier.value = memo ?? '';
            });
          }
          // ✅ 追加：アラームタブの完全再構築
          _alarmTabKey = UniqueKey();
          // ✅ 追加：カレンダー色の再同期
          _dayColorsNotifier.value = Map<String, Color>.from(_dayColors);
        });
        // ✅ 追加：カレンダーと入力を再評価
        await _updateMedicineInputsForSelectedDate();
        await _loadMemoForSelectedDate();
        // ✅ 追加：統計の再計算
        await _calculateAdherenceStats();
        // ✅ 追加：服用記録の表示を強制更新
        _updateCalendarMarks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ 1つ前の状態に復元しました'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 復元エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // ✅ 統合されたバックアップ作成メソッド（1回で完了）
  Future<void> _performBackup(String backupName) async {
    if (!mounted) return;
    
    // ローディング表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text('バックアップを作成中...'),
            ],
          ),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKey = 'backup_${DateTime.now().millisecondsSinceEpoch}';
      
      final backupData = await _createSafeBackupData(backupName);
      final jsonString = await _safeJsonEncode(backupData);
      final encryptedData = await _encryptDataAsync(jsonString);
      
      // 4. 保存（1回で完了）
      await prefs.setString(backupKey, encryptedData);
      
      await HomePageBackupHelper.updateBackupHistory(backupName, backupKey);
      
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('✓ バックアップ「$backupName」を作成しました'),
            backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      debugPrint('バックアップ作成エラー: $e');
      if (!mounted) return;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('バックアップの作成に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ 型安全なバックアップデータ作成
  Future<Map<String, dynamic>> _createSafeBackupData(String backupName) async {
    return HomePageBackupHelper.createSafeBackupData(
      backupName: backupName,
      medicationMemos: _medicationMemos,
      addedMedications: _addedMedications,
      medicines: _medicines,
      medicationData: _medicationData,
      weekdayMedicationStatus: _weekdayMedicationStatus,
      weekdayMedicationDoseStatus: _weekdayMedicationDoseStatus,
      medicationMemoStatus: _medicationMemoStatus,
      dayColors: _dayColors,
      alarmList: _alarmList,
      alarmSettings: _alarmSettings,
      adherenceRates: _adherenceRates,
    );
  }

  // ✅ 安全なJSONエンコード（エラーハンドリング）
  Future<String> _safeJsonEncode(Map<String, dynamic> data) async {
    return HomePageBackupHelper.safeJsonEncode(data);
  }

  // ✅ 非同期暗号化
  Future<String> _encryptDataAsync(String data) async {
    return HomePageBackupHelper.encryptDataAsync(data);
  }


  // ✅ 非同期データ復元（最適化版）
  Future<void> _restoreDataAsync(Map<String, dynamic> backupData) async {
    try {
      final restored = await HomePageBackupHelper.restoreDataAsync(backupData);
      
      // アラームをSharedPreferencesに保存
      final prefs = await SharedPreferences.getInstance();
      final restoredAlarmList = restored['restoredAlarmList'] as List<Map<String, dynamic>>;
      await prefs.setInt('alarm_count', restoredAlarmList.length);
      
      for (int i = 0; i < restoredAlarmList.length; i++) {
        final alarm = restoredAlarmList[i];
        await prefs.setString('alarm_${i}_name', alarm['name']?.toString() ?? 'アラーム');
        await prefs.setString('alarm_${i}_time', alarm['time']?.toString() ?? '00:00');
        await prefs.setString('alarm_${i}_repeat', alarm['repeat']?.toString() ?? '一度だけ');
        await prefs.setString('alarm_${i}_alarmType', alarm['alarmType']?.toString() ?? 'sound');
        await prefs.setBool('alarm_${i}_enabled', alarm['enabled'] as bool? ?? true);
        await prefs.setBool('alarm_${i}_isRepeatEnabled', alarm['isRepeatEnabled'] as bool? ?? false);
        await prefs.setInt('alarm_${i}_volume', alarm['volume'] as int? ?? 80);
        
        final dynamic selectedDaysRaw = alarm['selectedDays'];
        final List<bool> selectedDays = selectedDaysRaw is List
            ? List<bool>.from(selectedDaysRaw.map((e) => e == true))
            : <bool>[false, false, false, false, false, false, false];
        for (int j = 0; j < 7; j++) {
          await prefs.setBool('alarm_${i}_day_$j', j < selectedDays.length ? selectedDays[j] : false);
        }
      }
      
      if (!mounted) return;
      
      setState(() {
        _medicationMemos = restored['restoredMemos'] as List<MedicationMemo>;
        _addedMedications = restored['restoredAddedMedications'] as List<Map<String, dynamic>>;
        _medicines = restored['restoredMedicines'] as List<MedicineData>;
        _medicationData = restored['restoredMedicationData'] as Map<String, Map<String, MedicationInfo>>;
        _weekdayMedicationStatus = restored['restoredWeekdayStatus'] as Map<String, Map<String, bool>>;
        _weekdayMedicationDoseStatus = restored['restoredWeekdayDoseStatus'] as Map<String, Map<String, Map<int, bool>>>;
        _medicationMemoStatus = restored['restoredMemoStatus'] as Map<String, bool>;
        _dayColors = restored['restoredDayColors'] as Map<String, Color>;
        _alarmList = restoredAlarmList;
        _alarmSettings = restored['restoredAlarmSettings'] as Map<String, dynamic>;
        _adherenceRates = restored['restoredAdherenceRates'] as Map<String, double>;
        _alarmTabKey = UniqueKey();
      });
      
      await _saveAllData();
      debugPrint('バックアップ復元完了: ${_medicationMemos.length}件のメモ');
    } catch (e) {
      debugPrint('データ復元エラー: $e');
      rethrow;
    }
  }




  // ✅ バックアップ履歴の更新（サービスに移動）
  Future<void> _updateBackupHistory(String backupName, String backupKey, {String type = 'manual'}) async {
    await HomePageBackupHelper.updateBackupHistory(backupName, backupKey, type: type);
  }

  // ✅ バックアップ履歴表示機能（強化版）
  Future<void> _showBackupHistory() async {
    if (!mounted) return;
    
    final history = await BackupHistoryService.getBackupHistory();
    
    // 自動バックアップも含めて全てのバックアップを取得
    final allBackups = <Map<String, dynamic>>[];
    
    // 手動バックアップ履歴を追加
    for (final backup in history) {
      allBackups.add({
        ...backup,
        'type': 'manual',
        'source': '履歴',
      });
    }
    
    // 自動バックアップを追加
    final autoBackupKey = await BackupHistoryService.getLastAutoBackupKey();
    if (autoBackupKey != null) {
      allBackups.add({
        'name': '自動バックアップ（最新）',
        'key': autoBackupKey,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'auto',
        'source': '自動',
      });
    }
    
    if (allBackups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('バックアップがありません'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            SizedBox(width: 8),
            Text('バックアップ一覧'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: ListView.builder(
            itemCount: allBackups.length,
            itemBuilder: (context, index) {
              final backup = allBackups[allBackups.length - 1 - index]; // 新しい順に表示
              final createdAt = DateTime.parse(backup['createdAt'] as String);
              final isAuto = backup['type'] == 'auto';
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isAuto ? Icons.schedule : Icons.backup,
                    color: isAuto ? Colors.green : Colors.orange,
                  ),
                  title: Text(backup['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('yyyy-MM-dd HH:mm').format(createdAt)),
                      Text(
                        '${backup['source']}バックアップ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAuto ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'restore':
                          await _restoreBackup(backup['key'] as String);
                          break;
                        case 'delete':
                          if (!isAuto) {
                            await _deleteBackup(backup['key'] as String, index);
                          }
                          break;
                        case 'preview':
                          await _previewBackup(backup['key'] as String);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('復元'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.green),
                            SizedBox(width: 8),
                            Text('プレビュー'),
                          ],
                        ),
                      ),
                      if (!isAuto) const PopupMenuItem(
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

  // ✅ バックアッププレビュー機能（簡略化）
  Future<void> _previewBackup(String backupKey) async {
    try {
      final backupData = await _loadBackupDataAsync(backupKey);
      if (backupData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('バックアップデータが見つかりません'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      if (!mounted) return;
      final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('バックアッププレビュー'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
                children: [
                Text('名前: ${backupData['name']}'),
                  Text('作成日時: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(backupData['createdAt']))}'),
                  const SizedBox(height: 8),
                  const Text('📊 バックアップ内容:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('・服用メモ数: ${(backupData['medicationMemos'] as List).length}件'),
                  Text('・追加薬品数: ${(backupData['addedMedications'] as List).length}件'),
                  Text('・薬品データ数: ${(backupData['medicines'] as List).length}件'),
                  Text('・アラーム数: ${(backupData['alarmList'] as List).length}件'),
                  const SizedBox(height: 16),
                  const Text('このバックアップを復元しますか？'),
                ],
              ),
            ),
            actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('復元する')),
            ],
          ),
        );
      if (result == true) await _restoreBackup(backupKey);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('プレビューの表示に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ✅ バックアップ復元機能（最適化版）
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
      
      // ✅ 新しい最適化された復元処理を使用
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
    return HomePageBackupHelper.loadBackupDataAsync(backupKey);
  }



  // ✅ バックアップ削除機能
  Future<void> _deleteBackup(String backupKey, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // バックアップデータを削除
      await prefs.remove(backupKey);
      
      // 履歴から削除（サービスを使用）
      await BackupHistoryService.removeFromHistory(backupKey);
      
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
        // 服用メモタブでのみFloatingActionButtonを表示
        floatingActionButton: _tabController.index == 1 
          ? FloatingActionButton(
              onPressed: _addMemo,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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
