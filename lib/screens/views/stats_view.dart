// StatsView
// 統計タブ - 完全独立化（StateManagerに直接依存）

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../home/state/home_page_state_manager.dart';
import '../helpers/calculations/adherence_calculator.dart';
import '../helpers/home_page_stats_helper.dart';
import '../home/widgets/dialogs/custom_adherence_dialog.dart';

/// 統計ビュー
/// StateManagerに完全依存
class StatsView extends StatefulWidget {
  final HomePageStateManager stateManager;

  const StatsView({
    super.key,
    required this.stateManager,
  });

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  @override
  Widget build(BuildContext context) {
    if (!widget.stateManager.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      controller: widget.stateManager.statsScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カスタム遵守率カード
          _buildCustomAdherenceCard(),
          const SizedBox(height: 16),
          // 遵守率グラフ
          ValueListenableBuilder<Map<String, double>>(
            valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
            builder: (context, rates, _) {
              return HomePageStatsHelper.buildAdherenceChart(rates);
            },
          ),
          const SizedBox(height: 16),
          // 薬品別使用状況グラフ（遵守率が更新されたときに再描画）
          ValueListenableBuilder<Map<String, double>>(
            valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
            builder: (context, rates, _) {
              return HomePageStatsHelper.buildMedicationUsageChart(
                medicationData: widget.stateManager.medicationData,
                medicationMemos: widget.stateManager.medicationMemos,
                weekdayMedicationStatus: widget.stateManager.weekdayMedicationStatus,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAdherenceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'カスタム遵守率計算',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double?>(
              valueListenable: widget.stateManager.notifiers.customAdherenceResultNotifier,
              builder: (context, result, _) {
                if (result != null && widget.stateManager.customDaysResult != null) {
                  final percentage = (result * 100).clamp(0.0, 100.0);
                  return Column(
                    children: [
                      Text(
                        '${widget.stateManager.customDaysResult}日間の遵守率',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: percentage >= 80
                              ? Colors.green
                              : percentage >= 60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCustomAdherenceDialog(),
                icon: const Icon(Icons.calculate),
                label: const Text('日数を指定して計算'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomAdherenceDialog() async {
    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => CustomAdherenceDialog(
        onCalculate: (rate, days) async {
          await _calculateCustomAdherence(days);
        },
      ),
    );
  }

  Future<void> _calculateCustomAdherence(int days) async {
    if (!mounted) return;
    
    try {
      // 入力値の検証
      if (days <= 0 || days > 365) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('有効な日数（1-365）を入力してください'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // StateManagerのnullチェック
      if (widget.stateManager.medicationData == null ||
          widget.stateManager.medicationMemos == null ||
          widget.stateManager.weekdayMedicationStatus == null ||
          widget.stateManager.medicationMemoStatus == null ||
          widget.stateManager.weekdayMedicationDoseStatus == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('データが初期化されていません'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      final rate = AdherenceCalculator.calculateCustomAdherence(
        days: days,
        medicationData: widget.stateManager.medicationData,
        medicationMemos: widget.stateManager.medicationMemos,
        weekdayMedicationStatus: widget.stateManager.weekdayMedicationStatus,
        medicationMemoStatus: widget.stateManager.medicationMemoStatus,
        getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
          try {
            final doseStatus = widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
            if (doseStatus == null) return 0;
            return doseStatus.values.where((isChecked) => isChecked).length;
          } catch (e) {
            debugPrint('❌ メモチェック回数取得エラー: $e');
            return 0;
          }
        },
      );
      
      // 0-100の範囲を0-1の範囲に変換（表示時に100倍するため）
      final normalizedRate = rate / 100.0;
      
      if (mounted) {
        widget.stateManager.customAdherenceResult = normalizedRate;
        widget.stateManager.customDaysResult = days;
        widget.stateManager.notifiers.customAdherenceResultNotifier.value = normalizedRate;
        
        Navigator.of(context).pop();
        
        final statsController = widget.stateManager.statsScrollController;
        if (statsController.hasClients) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (statsController.hasClients) {
              statsController.animateTo(
                statsController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ カスタム遵守率計算エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('カスタム遵守率の計算に失敗しました: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // エラー時はダイアログを閉じない
      }
    }
  }
}

