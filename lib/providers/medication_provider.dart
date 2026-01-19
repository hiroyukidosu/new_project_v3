import 'dart:async';
import 'package:flutter/foundation.dart';

/// 薬物データモデル
class Medication {
  final String id;
  final String name;
  final DateTime date;
  final bool taken;
  final DateTime? takenAt;

  Medication({
    required this.id,
    required this.name,
    required this.date,
    required this.taken,
    this.takenAt,
  });

  Medication copyWith({
    String? id,
    String? name,
    DateTime? date,
    bool? taken,
    DateTime? takenAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      taken: taken ?? this.taken,
      takenAt: takenAt ?? this.takenAt,
    );
  }
}

/// 薬物管理プロバイダー - 無限ループ防止実装
class MedicationProvider extends ChangeNotifier {
  final List<Medication> _medications = [];
  int _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
  
  // 無限ループ防止フラグ
  bool _isUpdating = false;
  Timer? _debounceTimer;
  DateTime? _lastNotificationTime;
  static const _minNotificationInterval = Duration(milliseconds: 100);

  List<Medication> get medications => List.unmodifiable(_medications);

  int get lastUpdateTimestamp => _lastUpdateTimestamp;

  /// 薬物を追加
  void addMedication(Medication medication) {
    _medications.add(medication);
    _updateTimestamp();
    _notifySafely();
  }

  /// 薬物を更新
  void updateMedication(Medication medication, {bool notifyListeners = true}) {
    final index = _medications.indexWhere((m) => m.id == medication.id);
    if (index != -1) {
      _medications[index] = medication;
      _updateTimestamp();
      if (notifyListeners) {
        _notifySafely();
      }
    }
  }

  /// 薬物を削除
  void deleteMedication(String id) {
    _medications.removeWhere((m) => m.id == id);
    _updateTimestamp();
    _notifySafely();
  }

  /// 期間内の薬物を取得
  List<Medication> getMedicationsInRange(DateTime start, DateTime end) {
    return _medications.where((m) {
      return (m.date.isAfter(start) || m.date.isAtSameMomentAs(start)) &&
          (m.date.isBefore(end) || m.date.isAtSameMomentAs(end));
    }).toList();
  }

  // ========== ログ制御 ==========
  static bool _logsEnabled = false;
  
  static void disableLogs() {
    _logsEnabled = false;
  }
  
  static void enableLogs() {
    _logsEnabled = true;
  }
  
  // ========== 無限ループ検出 ==========
  int _notifyCallCount = 0;
  DateTime? _lastNotifyTime;
  static const _maxNotifyCallsPerSecond = 10;

  /// 安全な通知（頻繁な通知を防ぐ）
  void _notifySafely() {
    // ⚠️ 更新中は完全に通知をスキップ（無限ループ防止）
    if (_isUpdating) {
      if (_logsEnabled && kDebugMode) {
        debugPrint('[MedicationProvider] 更新中のため通知をスキップ');
      }
      return;
    }

    // 無限ループ検出
    final now = DateTime.now();
    if (_lastNotifyTime != null) {
      final elapsed = now.difference(_lastNotifyTime!);
      if (elapsed.inSeconds < 1) {
        _notifyCallCount++;
        if (_notifyCallCount > _maxNotifyCallsPerSecond) {
          final stackTrace = StackTrace.current;
          debugPrint('🚨 MedicationProvider: notifyListeners()が異常に多く呼ばれています: $_notifyCallCount回/秒');
          debugPrint('📍 スタックトレース:\n$stackTrace');
          _notifyCallCount = 0;
          return; // 通知をスキップ
        }
      } else {
        _notifyCallCount = 0;
      }
    }
    _lastNotifyTime = now;

    if (_lastNotificationTime != null) {
      final elapsed = now.difference(_lastNotificationTime!);
      if (elapsed < _minNotificationInterval) {
        // デバウンス処理
        _debounceTimer?.cancel();
        _debounceTimer = Timer(_minNotificationInterval - elapsed, () {
          _lastNotificationTime = DateTime.now();
          notifyListeners();
        });
        return;
      }
    }

    _lastNotificationTime = now;
    notifyListeners();
  }

  /// 更新フラグを設定（通知なしで更新）
  void setUpdateFlag(bool value) {
    _isUpdating = value;
  }

  void _updateTimestamp() {
    _lastUpdateTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
