// lib/screens/helpers/calendar_operations.dart
// カレンダー・統計関連の機能を集約（完全再構築版 - 徹底的に作り直し）

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../services/medication_service.dart';
import '../home/state/home_page_state_manager.dart';
import 'calculations/adherence_calculator.dart';

/// カレンダー・統計操作を管理するクラス（完全再構築版）
class CalendarOperations {
  final HomePageStateManager? stateManager;
  final bool Function() onMountedCheck;
  final void Function() onStateChanged;

  CalendarOperations({
    required this.stateManager,
    required this.onMountedCheck,
    required this.onStateChanged,
  });

  /// カレンダーマーク更新
  void updateCalendarMarks() {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null || stateManager == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final normalizedDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    
    // 服用メモのチェック状態を確認
    final memoStatus = stateManager!.medicationMemoStatus;
    final hasCheckedMemos = memoStatus.values.any((status) => status);
    
    // 追加された薬のチェック状態を確認
    final addedMeds = stateManager!.addedMedications;
    final hasCheckedMeds = addedMeds.any((med) => med['taken'] == true);
    
    // 服用済みのメモまたは薬がある場合、カレンダーマークを追加
    if (hasCheckedMemos || hasCheckedMeds) {
      if (!stateManager!.selectedDates.contains(normalizedDay)) {
        stateManager!.selectedDates.add(normalizedDay);
      }
    } else {
      // 服用済みがない場合、その日のマークを削除
      final dateStrFormatted = DateFormat('yyyy-MM-dd').format(selectedDay);
      stateManager!.selectedDates.removeWhere((d) {
        final dStr = DateFormat('yyyy-MM-dd').format(d);
        return dStr == dateStrFormatted;
      });
    }
    
    // UI更新
    if (onMountedCheck()) {
      onStateChanged();
    }
  }

  /// 遵守率統計を計算（完全再構築版 - 徹底的に作り直し）
  /// weekdayMedicationDoseStatusから実際のチェック済み回数を確実に取得
  Future<void> calculateAdherenceStats() async {
    try {
      if (stateManager == null) return;
      
      final stats = <String, double>{};
      final medicationData = stateManager!.medicationData;
      final medicationMemos = stateManager!.medicationMemos;
      final weekdayStatus = stateManager!.weekdayMedicationStatus;
      final memoStatus = stateManager!.medicationMemoStatus;
      final weekdayDoseStatus = stateManager!.weekdayMedicationDoseStatus;
      
      // デバッグログ：データ構造を確認
      if (kDebugMode) {
        debugPrint('========================================');
        debugPrint('遵守率計算開始');
        debugPrint('メモ数: ${medicationMemos.length}');
        debugPrint('weekdayDoseStatus日数: ${weekdayDoseStatus.length}');
        if (weekdayDoseStatus.isNotEmpty) {
          final sampleDate = weekdayDoseStatus.keys.first;
          final sampleData = weekdayDoseStatus[sampleDate];
          debugPrint('サンプル日付: $sampleDate, メモ数: ${sampleData?.length ?? 0}');
          if (sampleData != null && sampleData.isNotEmpty) {
            final sampleMemoId = sampleData.keys.first;
            final sampleDoseStatus = sampleData[sampleMemoId];
            debugPrint('サンプルメモID: $sampleMemoId, チェック状態: $sampleDoseStatus');
            if (sampleDoseStatus != null) {
              final checkedCount = sampleDoseStatus.values.where((v) => v == true).length;
              debugPrint('サンプルメモのチェック済み回数: $checkedCount');
            }
          }
        }
        debugPrint('========================================');
      }
      
      // 7日間、30日間、90日間の遵守率を計算（重複を防ぐため、一度だけ計算）
      // 重要：statsをクリアしてから計算することで、重複を防ぐ
      stats.clear();
      
      for (final period in [7, 30, 90]) {
        final rate = AdherenceCalculator.calculateCustomAdherence(
          days: period,
          medicationData: medicationData,
          medicationMemos: medicationMemos,
          weekdayMedicationStatus: weekdayStatus,
          medicationMemoStatus: memoStatus,
          getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
            // 方法1: weekdayMedicationDoseStatusから個別のチェック回数を取得
            // まず、正確なキーで検索
            var doseStatus = weekdayDoseStatus[dateStr]?[memoId];
            
            // 見つからない場合、型変換を試す
            if (doseStatus == null) {
              // 日付が存在するか確認
              if (weekdayDoseStatus.containsKey(dateStr)) {
                try {
                  final memoIdAsInt = int.parse(memoId);
                  doseStatus = weekdayDoseStatus[dateStr]?[memoIdAsInt.toString()];
                } catch (e) {
                  // 無視
                }
                
                // それでも見つからない場合、部分一致で検索
                if (doseStatus == null) {
                  final dateData = weekdayDoseStatus[dateStr];
                  if (dateData != null) {
                    for (final availableId in dateData.keys) {
                      final availableIdStr = availableId.toString();
                      if (availableIdStr == memoId ||
                          availableIdStr.contains(memoId) ||
                          memoId.contains(availableIdStr)) {
                        doseStatus = dateData[availableId];
                        if (doseStatus != null) break;
                      }
                    }
                  }
                }
              }
            }
            
            if (doseStatus != null) {
              // 個別チェック回数を返す
              final checkedCount = doseStatus.values.where((isChecked) => isChecked == true).length;
              if (kDebugMode && checkedCount > 0) {
                debugPrint('遵守率計算: 日付=$dateStr, メモID=$memoId, チェック済み=$checkedCount回');
              }
              if (checkedCount > 0) {
                return checkedCount;
              }
            }
            
            // 方法2: weekdayMedicationStatusで完全服用かどうかを確認（フォールバック）
            // カレンダーページで100%チェックされた場合のフラグを使用
            final isFullyTaken = weekdayStatus[dateStr]?[memoId] ?? false;
            if (isFullyTaken) {
              // 完全服用の場合は服用回数を返す
              try {
                final memo = medicationMemos.firstWhere((m) => m.id == memoId);
                if (kDebugMode) {
                  debugPrint('遵守率計算: 日付=$dateStr, メモID=$memoId, 完全服用フラグ=true, 服用回数=${memo.dosageFrequency}');
                }
                return memo.dosageFrequency;
              } catch (e) {
                // メモが見つからない場合はデフォルト値1を返す
                if (kDebugMode) {
                  debugPrint('遵守率計算: メモID=$memoId が見つからないため、デフォルト値1を返す');
                }
                return 1;
              }
            }
            
            if (kDebugMode) {
              debugPrint('遵守率計算: 日付=$dateStr, メモID=$memoId, チェック状態なし');
            }
            return 0;
          },
        );
        
        if (kDebugMode) {
          debugPrint('遵守率計算完了: $period日間 = ${rate.toStringAsFixed(1)}%');
        }
        
        if (!stats.containsKey('$period日間')) {
          stats['$period日間'] = rate;
        }
      }
      
      // 遵守率データを更新
      stateManager!.adherenceRates = Map<String, double>.from(stats);
      stateManager!.notifiers.adherenceRatesNotifier.value = Map<String, double>.from(stats);
      
      // 統計を保存
      await MedicationService.saveAdherenceStats(stats);
      
      // UI更新を確実に実行
      if (onMountedCheck()) {
        onStateChanged();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 遵守率統計計算エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  /// 軽量化された統計計算メソッド
  Map<String, int> calculateMedicationStats() {
    final selectedDay = stateManager?.selectedDay;
    if (selectedDay == null) return {'total': 0, 'taken': 0};
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    final addedMeds = stateManager?.addedMedications ?? [];
    totalMedications += addedMeds.length;
    takenMedications += addedMeds.where((med) => med['isChecked'] == true).length;
    
    // 服用メモの統計（軽量化）
    // Dartのweekdayは1(月)～7(日)
    // selectedWeekdaysは0(月)～6(日)なので、weekday - 1で変換
    final weekday = selectedDay.weekday - 1;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay);
    final memos = stateManager?.medicationMemos ?? [];
    final status = stateManager?.medicationMemoStatus ?? {};
    
    for (final memo in memos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (status[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  /// 日付正規化
  DateTime normalizeDate(DateTime date) => DateTime.utc(date.year, date.month, date.day);

  /// カレンダーイベント取得
  List<Widget> getEventsForDay(DateTime day) {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      // Dartのweekdayは1(月)～7(日)
      // selectedWeekdaysは0(月)～6(日)なので、weekday - 1で変換
      final weekday = day.weekday - 1;
      
      bool hasMedications = false;
      bool allTaken = true;
      int takenCount = 0;
      int totalCount = 0;
      
      // 動的薬リストのチェック
      final addedMeds = stateManager?.addedMedications ?? [];
      if (addedMeds.isNotEmpty) {
        hasMedications = true;
        totalCount += addedMeds.length;
        for (final medication in addedMeds) {
          if (medication['isChecked'] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 服用メモのチェック
      final memos = stateManager?.medicationMemos ?? [];
      final memoStatus = stateManager?.medicationMemoStatus ?? {};
      for (final memo in memos) {
        // Dartのweekdayは1(月)～7(日)
        // selectedWeekdaysは0(月)～6(日)なので、weekday - 1で変換
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          hasMedications = true;
          totalCount++;
          if (memoStatus[memo.id] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // イベントウィジェット生成（簡略化版）
      if (!hasMedications) {
        return [];
      }
      
      return [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: allTaken ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
        ),
      ];
    } catch (e) {
      debugPrint('❌ カレンダーイベント取得エラー: $e');
      return [];
    }
  }
}
