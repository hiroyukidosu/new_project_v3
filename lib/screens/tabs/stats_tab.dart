// StatsTab
// 統計タブ

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/trial_service.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';

/// 統計タブ
/// 服薬遵守率の統計を表示
class StatsTab extends StatefulWidget {
  final ScrollController scrollController;
  final Map<String, double> adherenceRates;
  final Map<String, Map<String, MedicationInfo>> medicationData;
  final List<MedicationMemo> medicationMemos;
  final Map<String, Map<String, bool>> weekdayMedicationStatus;
  final Function(String) onShowSnackBar;
  final Function(double?, int?) onCustomAdherenceCalculated;

  const StatsTab({
    super.key,
    required this.scrollController,
    required this.adherenceRates,
    required this.medicationData,
    required this.medicationMemos,
    required this.weekdayMedicationStatus,
    required this.onShowSnackBar,
    required this.onCustomAdherenceCalculated,
  });

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();

  @override
  void dispose() {
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  const Text(
                    '服薬遵守率',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      controller: widget.scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // 遵守率グラフ
                          _buildAdherenceChart(),
                          const SizedBox(height: 20),
                          // 薬品別使用状況グラフ
                          _buildMedicationUsageChart(),
                          const SizedBox(height: 20),
                          // 期間別遵守率カード
                          ...widget.adherenceRates.entries.map((entry) => _buildStatCard(entry.key, entry.value)).toList(),
                          const SizedBox(height: 20),
                          // 任意の日数の遵守率カード
                          _buildCustomAdherenceCard(),
                        ],
                      ),
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
                      widget.onShowSnackBar('1から365の範囲で日数を入力してください');
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
  
  void _calculateCustomAdherence(int days) async {
    try {
      // キーボードを閉じる
      _customDaysFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      
      final now = DateTime.now();
      int totalDoses = 0;
      int takenDoses = 0;
      
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayData = widget.medicationData[dateStr];
        
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
        final weekdayMemos = widget.medicationMemos.where((memo) => memo.selectedWeekdays.contains(weekday)).toList();
        
        for (final memo in weekdayMemos) {
          totalDoses++;
          // 日付別の服用メモ状態を確認
          if (widget.weekdayMedicationStatus[dateStr]?[memo.id] == true) {
            takenDoses++;
          }
        }
      }
      
      // データがない場合の警告
      if (totalDoses == 0) {
        widget.onShowSnackBar('指定した期間に服薬データがありません');
        return;
      }
      
      final rate = (takenDoses / totalDoses * 100);
     
      // 結果をカード内に表示
      setState(() {
        _customAdherenceResult = rate;
        _customDaysResult = days;
      });
      
      // 親に通知
      widget.onCustomAdherenceCalculated(rate, days);
      
      // ダイアログを閉じる
      Navigator.of(context).pop();
      
      // スクロール位置を復元（統計ページの一番下に戻る）
      if (widget.scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        });
      }
      
    } catch (e) {
      widget.onShowSnackBar('カスタム遵守率の計算に失敗しました: $e');
    }
  }
  
  Widget _buildAdherenceChart() {
    if (widget.adherenceRates.isEmpty) {
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
    final chartData = widget.adherenceRates.entries.toList();
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
                        reservedSize: 30,
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
  
  Widget _buildMedicationUsageChart() {
    // 薬品の使用回数を集計（服用メモのチェック状態も含める）
    Map<String, int> medicationCount = {};
    
    // 動的薬リストの統計
    for (final dayData in widget.medicationData.values) {
      for (final timeSlot in dayData.values) {
        if (timeSlot.medicine.isNotEmpty) {
          medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
        }
      }
    }
    
    // 服用メモのチェック状態を統計に反映（日付別）
    for (final entry in widget.weekdayMedicationStatus.entries) {
      final dateStr = entry.key;
      final dayStatus = entry.value;
      
      for (final memo in widget.medicationMemos) {
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
}

