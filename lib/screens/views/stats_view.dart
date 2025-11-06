import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../home/state/home_page_state_manager.dart';
import '../helpers/calculations/adherence_calculator.dart';
import '../helpers/calendar_operations.dart';
import '../home/widgets/dialogs/custom_adherence_dialog.dart';

/// 統計ビュー - 完全再構築版
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
  bool _isCalculating = false; // 計算中フラグ（重複実行防止）
  
  @override
  void initState() {
    super.initState();
    // 統計ページが表示されたときに自動的に遵守率を計算（遅延読み込み）
    // UI表示を優先するため、少し遅延させてから計算
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _ensureAdherenceStatsCalculated();
        }
      });
    });
  }

  Future<void> _ensureAdherenceStatsCalculated() async {
    // 既に計算中の場合はスキップ（重複実行防止）
    if (_isCalculating) {
      return;
    }
    
    // 既に計算済みの場合はスキップ
    final currentRates = widget.stateManager.notifiers.adherenceRatesNotifier.value;
    if (currentRates.isNotEmpty && 
        currentRates.containsKey('7日間') && 
        currentRates.containsKey('30日間')) {
      return;
    }
    
    _isCalculating = true;
    try {
      // 遵守率統計を計算（バックグラウンドで実行してメインスレッドをブロックしない）
      await Future.microtask(() async {
        final calendarOps = CalendarOperations(
          stateManager: widget.stateManager,
          onMountedCheck: () => mounted,
          onStateChanged: () {
            if (mounted) setState(() {});
          },
        );
        await calendarOps.calculateAdherenceStats();
      });
    } finally {
      _isCalculating = false;
    }
  }

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
          // 統計サマリーカード
          _buildSummaryCard(),
          const SizedBox(height: 16),
          // 7日間・30日間遵守率カード
          _buildQuickAdherenceCards(),
          const SizedBox(height: 16),
          // 期間別遵守率グラフ（バーグラフ）
          ValueListenableBuilder<Map<String, double>>(
            valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
            builder: (context, rates, _) => _buildPeriodAdherenceChart(rates),
          ),
          const SizedBox(height: 16),
          // カスタム遵守率カード
          _buildCustomAdherenceCard(),
          const SizedBox(height: 16),
          // 薬品別使用状況グラフ
          _buildMedicationUsageChart(),
        ],
      ),
    );
  }

  /// 統計サマリーカード
  Widget _buildSummaryCard() {
    final memos = widget.stateManager.medicationMemos;
    final totalMemos = memos.length;
    final activeMemos = memos.where((m) => m.selectedWeekdays.isNotEmpty).length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '統計サマリー',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('登録薬品', totalMemos.toString(), Icons.medication),
                _buildSummaryItem('有効薬品', activeMemos.toString(), Icons.check_circle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// 7日間・30日間遵守率カード
  Widget _buildQuickAdherenceCards() {
    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
      builder: (context, rates, _) {
        final sevenDayRate = rates['7日間'];
        final thirtyDayRate = rates['30日間'];
        
        return Row(
          children: [
            Expanded(
              child: _buildQuickAdherenceCard('7日間', sevenDayRate, Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickAdherenceCard('30日間', thirtyDayRate, Colors.green),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAdherenceCard(String period, double? rate, MaterialColor color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.shade400, color.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '$periodの遵守率',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rate != null ? '${rate.toStringAsFixed(1)}%' : '--',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 期間別遵守率グラフ（バーグラフ）
  Widget _buildPeriodAdherenceChart(Map<String, double> rates) {
    if (rates.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'データがありません',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final sortedRates = rates.entries.toList()
      ..sort((a, b) {
        final aPeriod = int.tryParse(a.key.replaceAll('日間', '')) ?? 0;
        final bPeriod = int.tryParse(b.key.replaceAll('日間', '')) ?? 0;
        return aPeriod.compareTo(bPeriod);
      });

    final maxValue = sortedRates.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = sortedRates.map((e) => e.value).reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  '期間別遵守率',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxValue + 20).clamp(0.0, 100.0),
                  minY: (minValue - 20).clamp(0.0, 0.0),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedRates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                sortedRates[index].key,
                                style: const TextStyle(fontSize: 12),
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
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedRates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final rate = entry.value.value;
                    final color = rate >= 80
                        ? Colors.green
                        : rate >= 60
                            ? Colors.orange
                            : Colors.red;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: rate,
                          color: color,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 凡例
            Wrap(
              spacing: 24,
              children: sortedRates.map((entry) {
                final rate = entry.value;
                final color = rate >= 80
                    ? Colors.green
                    : rate >= 60
                        ? Colors.orange
                        : Colors.red;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: ${rate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// カスタム遵守率カード
  Widget _buildCustomAdherenceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'カスタム遵守率',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<double?>(
              valueListenable: widget.stateManager.notifiers.customAdherenceResultNotifier,
              builder: (context, result, _) {
                if (result != null && widget.stateManager.customDaysResult != null) {
                  return Column(
                    children: [
                      Text(
                        '${widget.stateManager.customDaysResult}日間の遵守率',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${result.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 薬品別使用状況グラフ
  Widget _buildMedicationUsageChart() {
    final medicationData = widget.stateManager.medicationData;
    final medicationMemos = widget.stateManager.medicationMemos;
    final weekdayDoseStatus = widget.stateManager.weekdayMedicationDoseStatus;

    Map<String, int> medicationCount = {};

    // 動的薬リストの統計
    for (final dayData in medicationData.values) {
      for (final timeSlot in dayData.values) {
        if (timeSlot.medicine.isNotEmpty && timeSlot.checked) {
          medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
        }
      }
    }

    // 服用メモの統計
    for (final entry in weekdayDoseStatus.entries) {
      final dateStr = entry.key;
      for (final memo in medicationMemos) {
        final doseStatus = weekdayDoseStatus[dateStr]?[memo.id];
        if (doseStatus != null) {
          final checkedCount = doseStatus.values.where((isChecked) => isChecked == true).length;
          if (checkedCount > 0) {
            medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + checkedCount;
          }
        }
      }
    }

    if (medicationCount.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.pie_chart, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'データがありません',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final sortedMedications = medicationCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  '薬品別使用状況',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: sortedMedications.asMap().entries.map((entry) {
                          return PieChartSectionData(
                            color: colors[entry.key % colors.length],
                            value: entry.value.value.toDouble(),
                            title: '${entry.value.value}',
                            radius: 60,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedMedications.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors[entry.key % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.value.key,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${entry.value.value}回',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
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

      if (widget.stateManager.medicationData.isEmpty &&
          widget.stateManager.medicationMemos.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('服用データがありません'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

          final weekdayDoseStatus = widget.stateManager.weekdayMedicationDoseStatus;
          final weekdayStatus = widget.stateManager.weekdayMedicationStatus;
          final medicationMemos = widget.stateManager.medicationMemos;

      final rate = AdherenceCalculator.calculateCustomAdherence(
        days: days,
        medicationData: widget.stateManager.medicationData,
        medicationMemos: medicationMemos,
        weekdayMedicationStatus: weekdayStatus,
        medicationMemoStatus: widget.stateManager.medicationMemoStatus,
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
            if (checkedCount > 0) {
              return checkedCount;
            }
          }
          
          // 方法2: weekdayMedicationStatusで完全服用かどうかを確認（フォールバック）
          final isFullyTaken = weekdayStatus[dateStr]?[memoId] ?? false;
          if (isFullyTaken) {
            // 完全服用の場合は服用回数を返す
            try {
              final memo = medicationMemos.firstWhere((m) => m.id == memoId);
              return memo.dosageFrequency;
            } catch (e) {
              // メモが見つからない場合はデフォルト値1を返す
              return 1;
            }
          }
          
          return 0;
        },
      );

      if (rate.isFinite && !rate.isNaN) {
        widget.stateManager.customAdherenceResult = rate;
        widget.stateManager.customDaysResult = days;
        widget.stateManager.notifiers.customAdherenceResultNotifier.value = rate;
        await widget.stateManager.saveAllData();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${days}日間の遵守率: ${rate.toStringAsFixed(1)}%'),
              backgroundColor: rate >= 80
                  ? Colors.green
                  : rate >= 60
                      ? Colors.orange
                      : Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('計算に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
