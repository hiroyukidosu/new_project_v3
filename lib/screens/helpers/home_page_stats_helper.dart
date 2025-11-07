// 統計関連ヘルパー
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';

class HomePageStatsHelper {
  // カスタム遵守率計算
  static double calculateCustomAdherence({
    required int days,
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
  }) {
    final now = DateTime.now();
    int totalDoses = 0;
    int takenDoses = 0;
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayData = medicationData[dateStr];
      
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
      final weekday = date.weekday % 7;
      final weekdayMemos = medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
      
      for (final memo in weekdayMemos) {
        totalDoses++;
        if (weekdayMedicationStatus[dateStr]?[memo.id] == true) {
          takenDoses++;
        }
      }
    }
    
    if (totalDoses == 0) return 0.0;
    return (takenDoses / totalDoses * 100);
  }

  // 遵守率グラフ構築
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
    
    final chartData = adherenceRates.entries.toList();
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
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[value.toInt()].key,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 薬品別使用状況グラフ構築
  static Widget buildMedicationUsageChart({
    required Map<String, Map<String, MedicationInfo>> medicationData,
    required List<MedicationMemo> medicationMemos,
    required Map<String, Map<String, bool>> weekdayMedicationStatus,
  }) {
    Map<String, int> medicationCount = {};
    
    // 動的薬リストの統計
    for (final dayData in medicationData.values) {
      for (final timeSlot in dayData.values) {
        if (timeSlot.medicine.isNotEmpty) {
          medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
        }
      }
    }
    
    // 服用メモのチェック状態を統計に反映
    for (final entry in weekdayMedicationStatus.entries) {
      for (final memo in medicationMemos) {
        if (entry.value[memo.id] == true) {
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
