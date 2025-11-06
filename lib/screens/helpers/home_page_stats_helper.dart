// 統計関連ヘルパー（完全再構築版 - チェック状況を確実に反映）
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';

class HomePageStatsHelper {
  // 注意: このクラスの calculateCustomAdherence は使用されていません
  // 実際の計算は AdherenceCalculator.calculateCustomAdherence を使用しています

  // 遵守率グラフ構築（非推奨 - stats_view.dartで直接実装）
  static Widget buildAdherenceChart(Map<String, double> adherenceRates) {
    if (adherenceRates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('遵守率グラフ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('データがありません', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    
    final uniqueRates = <String, double>{};
    for (final entry in adherenceRates.entries) {
      if (!uniqueRates.containsKey(entry.key)) {
        uniqueRates[entry.key] = entry.value;
      }
    }
    
    final sortedEntries = uniqueRates.entries.toList()
      ..sort((a, b) {
        final aPeriod = int.tryParse(a.key.replaceAll('日間', '')) ?? 0;
        final bPeriod = int.tryParse(b.key.replaceAll('日間', '')) ?? 0;
        return aPeriod.compareTo(bPeriod);
      });
    
    final chartData = sortedEntries;
    final maxValue = chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minValue = chartData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('遵守率グラフ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('${value.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1.0, // 各データポイントにラベルを表示
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[index].key,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
                      spots: chartData.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.value)).toList(),
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
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                    ),
                  ],
                  minY: minValue - 10,
                  maxY: maxValue + 10,
                  minX: 0,
                  maxX: (chartData.length - 1).toDouble(),
                  baselineY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 薬品別使用状況グラフ構築（非推奨 - stats_view.dartで直接実装）
  static Widget buildMedicationUsageChart({
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
    Map<String, Map<String, Map<int, bool>>>? weekdayMedicationDoseStatus,
    int Function(String, String)? getMedicationMemoCheckedCountForDate,
  }) {
    
    Map<String, int> medicationCount = {};
    
    // 動的薬リストの統計
    for (final dayData in medicationData.values) {
      for (final timeSlot in dayData.values) {
        if (timeSlot.medicine.isNotEmpty && timeSlot.checked) {
          medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
        }
      }
    }
    
    // 服用メモのチェック状態を統計に反映（重要：weekdayMedicationDoseStatusを使用）
    // weekdayMedicationDoseStatusが利用可能な場合は、服用回数別のチェック状態を使用
    if (weekdayMedicationDoseStatus != null && getMedicationMemoCheckedCountForDate != null) {
      // 服用回数別のチェック状態を使用（より正確 - カレンダーページのチェック100%を反映）
      int totalCheckedCount = 0;
      for (final entry in weekdayMedicationDoseStatus.entries) {
        final dateStr = entry.key;
        for (final memo in medicationMemos) {
          // 重要：weekdayMedicationDoseStatusから実際のチェック済み回数を取得
          // これにより、カレンダーページでチェックした回数が正しく反映される
          final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
          if (checkedCount > 0) {
            medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + checkedCount;
          }
        }
      }
    } else {
      for (final entry in weekdayMedicationStatus.entries) {
        for (final memo in medicationMemos) {
          if (entry.value[memo.id] == true) {
            // 完全服用の場合、服用回数分をカウント
            medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + memo.dosageFrequency;
          }
        }
      }
    }
    
    if (medicationCount.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('くすり、サプリ別使用状況', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('データがありません', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    
    final sortedMedications = medicationCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.indigo];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('くすり、サプリ別使用状況', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sortedMedications.asMap().entries.map((entry) {
                    return PieChartSectionData(
                      color: colors[entry.key % colors.length],
                      value: entry.value.value.toDouble(),
                      title: '${entry.value.key}\n${entry.value.value}回',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
}
