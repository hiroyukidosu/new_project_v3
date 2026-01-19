import 'dart:async';
import 'package:flutter/foundation.dart';
import 'medication_provider.dart';

/// 遵守率計算結果
class AdherenceResult {
  final Map<int, double> rates; // 日数 -> 遵守率のマップ
  final DateTime calculatedAt;

  AdherenceResult({
    required this.rates,
    required this.calculatedAt,
  });
}

/// 統計プロバイダー - 無限ループを防止する最適化実装
class StatisticsProvider extends ChangeNotifier {
  // ========== ログ制御 ==========
  static bool _logsEnabled = false; // ログを無効化
  
  static void disableLogs() {
    _logsEnabled = false;
  }
  
  static void enableLogs() {
    _logsEnabled = true;
  }

  // ========== 無限ループ検出 ==========
  int _scheduleCallCount = 0;
  int _recalculateCallCount = 0;
  int _notifyCallCount = 0;
  DateTime? _lastScheduleTime;
  DateTime? _lastNotifyTime;
  static const _maxCallsPerSecond = 10; // 1秒間に10回以上は異常
  
  // ========== 計算状態の管理 ==========
  bool _isCalculating = false;
  bool get isCalculating => _isCalculating;

  // ========== キャッシュ ==========
  Map<int, double> _cachedRates = {};
  DateTime? _lastCalculation;

  // ========== デバウンス用タイマー ==========
  Timer? _debounceTimer;

  // ========== 前回の計算ハッシュ（重複計算を防ぐ） ==========
  int _lastCalculationHash = 0;

  // MedicationProviderへの参照（必要に応じて注入）
  MedicationProvider? _medicationProvider;
  
  void setMedicationProvider(MedicationProvider provider) {
    _medicationProvider = provider;
  }
  
  // ========== デバッグログ（条件付き） ==========
  void _debugLog(String message) {
    if (_logsEnabled && kDebugMode) {
      debugPrint(message);
    }
  }
  
  // ========== 無限ループ検出 ==========
  void _checkInfiniteLoop(String methodName) {
    final now = DateTime.now();
    if (_lastScheduleTime != null) {
      final elapsed = now.difference(_lastScheduleTime!);
      if (elapsed.inSeconds < 1) {
        _scheduleCallCount++;
        if (_scheduleCallCount > _maxCallsPerSecond) {
          // 無限ループ検出
          final stackTrace = StackTrace.current;
          debugPrint('🚨 無限ループ検出: $methodName が1秒間に$_scheduleCallCount回呼ばれています');
          debugPrint('📊 呼び出し統計: schedule=$_scheduleCallCount, recalculate=$_recalculateCallCount, notify=$_notifyCallCount');
          debugPrint('📍 スタックトレース:\n$stackTrace');
          
          // 強制的に停止
          _scheduleCallCount = 0;
          _recalculateCallCount = 0;
          _notifyCallCount = 0;
          _debounceTimer?.cancel();
          _isCalculating = false;
        }
      } else {
        _scheduleCallCount = 0;
        _recalculateCallCount = 0;
        _notifyCallCount = 0;
      }
    }
    _lastScheduleTime = now;
  }

  // ========== 遵守率の取得 ==========
  // ⚠️ getter内では計算をトリガーしない（無限ループ防止）
  Map<int, double> get adherenceRates {
    return Map.unmodifiable(_cachedRates);
  }

  // ========== デバウンス付き再計算スケジューリング ==========
  void scheduleRecalculation() {
    // 無限ループ検出
    _checkInfiniteLoop('scheduleRecalculation');
    
    // 計算中ならスキップ
    if (_isCalculating) {
      _debugLog('[StatisticsProvider] 計算中のためスキップ');
      return;
    }

    // 現在のデータのハッシュ値を計算
    final currentHash = _calculateDataHash();
    
    // 前回と同じデータなら計算をスキップ
    if (currentHash == _lastCalculationHash && _cachedRates.isNotEmpty) {
      _debugLog('[StatisticsProvider] データ未変更のため計算スキップ (hash: $currentHash)');
      return;
    }

    // デバウンス処理：既存のタイマーをキャンセル
    _debounceTimer?.cancel();
    
    // 500ms後に実行
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isCalculating) {
        _recalculateAllStatistics();
        _lastCalculationHash = currentHash;
      }
    });
    
    _debugLog('[StatisticsProvider] 再計算をスケジュール (hash: $currentHash, 前回: $_lastCalculationHash)');
  }

  // ========== データのハッシュ値を計算 ==========
  int _calculateDataHash() {
    if (_medicationProvider == null) return 0;
    
    int hash = 0;
    final medications = _medicationProvider!.medications;
    hash ^= medications.length;
    
    for (var med in medications) {
      hash ^= med.id.hashCode;
      hash ^= med.date.millisecondsSinceEpoch;
      hash ^= (med.taken ? 1 : 0);
    }
    
    return hash;
  }

  // ========== すべての統計を再計算 ==========
  Future<void> _recalculateAllStatistics() async {
    _recalculateCallCount++;
    
    if (_isCalculating) {
      _debugLog('[StatisticsProvider] 計算中のため処理スキップ');
      return;
    }

    _isCalculating = true;
    
    // ⚠️ 計算開始前にMedicationProviderの更新フラグを設定（通知を完全に抑制）
    if (_medicationProvider != null) {
      _medicationProvider!.setUpdateFlag(true);
    }
    
    // ⚠️ 計算開始時の通知を削除（無限ループ防止）
    // Selectorが反応して再ビルドを引き起こし、それが再計算をトリガーする可能性があるため

    try {
      _debugLog('[StatisticsProvider] 統計計算開始');
      
      final rates = await _calculateAllRates();

      // 値が変わった場合のみ更新
      if (!_mapsEqual(_cachedRates, rates)) {
        _cachedRates = rates;
        _lastCalculation = DateTime.now();
        
        _debugLog('[StatisticsProvider] 統計計算完了: ${rates.length}件');
        
        // 計算完了を通知（一度だけ）
        _notifyListenersWithTracking('計算完了');
      } else {
        _debugLog('[StatisticsProvider] 統計値に変更なし、通知をスキップ');
      }
    } catch (e) {
      _debugLog('[StatisticsProvider] 統計計算エラー: $e');
      _cachedRates = {};
      _notifyListenersWithTracking('エラー'); // エラー時も通知
    } finally {
      _isCalculating = false;
      
      // ⚠️ 計算完了後にMedicationProviderの更新フラグを解除
      // ただし、通知は既に完了しているため、これ以降の通知は通常通り動作
      if (_medicationProvider != null) {
        _medicationProvider!.setUpdateFlag(false);
      }
    }
  }
  
  // ========== notifyListeners()の呼び出しを追跡 ==========
  void _notifyListenersWithTracking(String reason) {
    final now = DateTime.now();
    
    // 無限ループ検出（時間ベース）
    if (_lastNotifyTime != null) {
      final elapsed = now.difference(_lastNotifyTime!);
      if (elapsed.inSeconds < 1) {
        _notifyCallCount++;
        if (_notifyCallCount > _maxCallsPerSecond) {
          final stackTrace = StackTrace.current;
          debugPrint('🚨 notifyListeners()が異常に多く呼ばれています: $_notifyCallCount回/秒 (理由: $reason)');
          debugPrint('📊 呼び出し統計: schedule=$_scheduleCallCount, recalculate=$_recalculateCallCount');
          debugPrint('📍 スタックトレース:\n$stackTrace');
          _notifyCallCount = 0;
          return; // 通知をスキップ
        }
      } else {
        _notifyCallCount = 0;
      }
    }
    _lastNotifyTime = now;
    
    notifyListeners();
  }

  // マップの等価性チェック
  bool _mapsEqual(Map<int, double> a, Map<int, double> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key) || (a[key]! - b[key]!).abs() > 0.01) {
        return false;
      }
    }
    return true;
  }

  // ========== 全期間の遵守率を計算（改善案 #7 効率化） ==========
  Future<Map<int, double>> _calculateAllRates() async {
    if (_medicationProvider == null) {
      _debugLog('[StatisticsProvider] MedicationProviderが設定されていません');
      return {};
    }

    final now = DateTime.now();
    final result = <int, double>{};

    // 全期間を一度に処理するため、最大期間のデータを取得
    final allMedications = _medicationProvider!.getMedicationsInRange(
      now.subtract(const Duration(days: 90)),
      now,
    );

    for (final days in [7, 30, 90]) {
      final startDate = now.subtract(Duration(days: days));
      final filtered = allMedications.where((m) =>
          m.date.isAfter(startDate) || m.date.isAtSameMomentAs(startDate)).toList();

      result[days] = _calculateRateForPeriod(filtered, days);
    }

    return result;
  }

  // ========== 特定期間の遵守率を計算 ==========
  double _calculateRateForPeriod(List<Medication> medications, int days) {
    if (medications.isEmpty) return 0.0;

    // 実際の計算ロジック
    final takenCount = medications.where((m) => m.taken).length;
    final totalCount = medications.length;

    if (totalCount == 0) return 0.0;
    return (takenCount / totalCount) * 100.0;
  }

  // ========== 手動リフレッシュ ==========
  Future<void> forceRefresh() async {
    _cachedRates.clear();
    _lastCalculation = null;
    _lastCalculationHash = 0;
    await _recalculateAllStatistics();
  }

  // ========== リソース解放 ==========
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

