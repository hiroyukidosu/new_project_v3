// StatsView
// 統計タブ - プロフェッショナルなデザイン

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
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

class _StatsViewState extends State<StatsView> with TickerProviderStateMixin {
  bool _hasCalculatedInitialStats = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // 薬品別使用状況のデータを保持
  Map<String, int> _medicationUsageData = {};
  final ValueNotifier<Map<String, int>> _medicationUsageNotifier = ValueNotifier<Map<String, int>>({});

  @override
  void initState() {
    super.initState();
    
    // アニメーションコントローラーの初期化
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // 初期表示時に統計を計算（既存のチェック状態も反映）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateInitialStats();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _medicationUsageNotifier.dispose();
    super.dispose();
  }

  Future<void> _calculateInitialStats() async {
    if (_hasCalculatedInitialStats) return;
    
    // StateManagerの初期化を待つ
    int retryCount = 0;
    while (!widget.stateManager.isInitialized && retryCount < 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      retryCount++;
    }
    
    if (!widget.stateManager.isInitialized) {
      debugPrint('⚠️ StateManagerが初期化されていません');
      return;
    }
    
    try {
      await _updateAdherenceStats();
      await _updateMedicationUsageData(); // 薬品別使用状況も初期化時に計算
      _hasCalculatedInitialStats = true;
      if (mounted) {
        setState(() {
          // 薬品別使用状況も初期表示時に反映されるように強制再描画
        });
      }
    } catch (e) {
      debugPrint('❌ 初期統計計算エラー: $e');
    }
  }

  /// 薬品別使用状況のデータを更新（遵守率グラフと同じタイミングで実行）
  Future<void> _updateMedicationUsageData() async {
    if (!mounted) return;
    
    try {
      // StateManagerが初期化されていることを確認
      if (!widget.stateManager.isInitialized) {
        debugPrint('⚠️ StateManagerが初期化されていないため、薬品別使用状況を計算できません');
        return;
      }

      final medicationData = widget.stateManager.medicationData;
      final medicationMemos = widget.stateManager.medicationMemos;
      final weekdayStatus = widget.stateManager.weekdayMedicationStatus;

      Map<String, int> medicationCount = {};

      // 動的薬リストの統計（既存データから計算）
      for (final dayData in medicationData.values) {
        for (final timeSlot in dayData.values) {
          if (timeSlot.medicine.isNotEmpty) {
            medicationCount[timeSlot.medicine] = (medicationCount[timeSlot.medicine] ?? 0) + 1;
          }
        }
      }

      // 服用メモのチェック状態を統計に反映（既存データから計算）
      // 初期表示時から既存のチェック状態を反映
      for (final entry in weekdayStatus.entries) {
        for (final memo in medicationMemos) {
          if (entry.value[memo.id] == true) {
            medicationCount[memo.name] = (medicationCount[memo.name] ?? 0) + 1;
          }
        }
      }

      // データを更新（空でも更新して初期表示を確実にする）
      _medicationUsageData = medicationCount;
      if (mounted) {
        _medicationUsageNotifier.value = Map<String, int>.from(medicationCount);
        // データが更新されたことをログに出力
        if (medicationCount.isNotEmpty) {
          debugPrint('✅ 薬品別使用状況更新: ${medicationCount.length}種類の薬品');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 薬品別使用状況更新エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }

  Future<void> _updateAdherenceStats() async {
    try {
      final stats = <String, double>{};
      final medicationData = widget.stateManager.medicationData;
      final medicationMemos = widget.stateManager.medicationMemos;
      final weekdayStatus = widget.stateManager.weekdayMedicationStatus;
      final memoStatus = widget.stateManager.medicationMemoStatus;

      for (final period in [7, 30, 90]) {
        final rate = AdherenceCalculator.calculateCustomAdherence(
          days: period,
          medicationData: medicationData,
          medicationMemos: medicationMemos,
          weekdayMedicationStatus: weekdayStatus,
          medicationMemoStatus: memoStatus,
          getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
            final doseStatus = widget.stateManager.weekdayMedicationDoseStatus[dateStr]?[memoId];
            if (doseStatus == null) return 0;
            return doseStatus.values.where((isChecked) => isChecked).length;
          },
        );
        stats['${period}日'] = rate;
      }

      widget.stateManager.adherenceRates = stats;
      widget.stateManager.notifiers.adherenceRatesNotifier.value = stats;
      
      // 遵守率更新時に薬品別使用状況も更新
      await _updateMedicationUsageData();
    } catch (e) {
      debugPrint('❌ 遵守率統計更新エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.stateManager.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // 初期統計が未計算の場合は計算（薬品別使用状況も含む）
    if (!_hasCalculatedInitialStats) {
      _calculateInitialStats();
    }
    
    // 薬品別使用状況が空の場合は即座に計算（初期表示時）
    if (_medicationUsageData.isEmpty && widget.stateManager.isInitialized) {
      _updateMedicationUsageData();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
              ],
            ),
          ),
          child: SingleChildScrollView(
            controller: widget.stateManager.statsScrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー
                _buildHeader(),
                const SizedBox(height: 24),
                
                // サマリーカード
                _buildSummaryCards(),
                const SizedBox(height: 24),
                
                // カスタム遵守率カード
                _buildCustomAdherenceCard(),
                const SizedBox(height: 24),
                
                // 遵守率グラフ
                ValueListenableBuilder<Map<String, double>>(
                  valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
                  builder: (context, rates, _) {
                    return _buildAdherenceChart(rates);
                  },
                ),
                const SizedBox(height: 24),
                
                // 薬品別使用状況グラフ（遵守率グラフと同じタイミングで更新・初期表示時から反映）
                Builder(
                  builder: (context) {
                    // 遵守率グラフと同じNotifierを監視して、同じタイミングで更新
                    return ValueListenableBuilder<Map<String, double>>(
                      valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
                      builder: (context, rates, _) {
                        // 遵守率が更新されたときに薬品別使用状況も計算
                        // 初期表示時にも確実に反映される
                        if (mounted) {
                          _updateMedicationUsageData();
                        }
                        // 現在のデータで表示
                        return ValueListenableBuilder<Map<String, int>>(
                          valueListenable: _medicationUsageNotifier,
                          builder: (context, medicationCount, _) {
                            return _buildMedicationUsageChart(medicationCount);
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return             Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '統計ダッシュボード',
                        style: TextStyle(
                          fontSize: math.min(28, MediaQuery.of(context).size.width * 0.07),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.headlineMedium?.color,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '服薬状況の詳細な分析',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            );
  }

  Widget _buildSummaryCards() {
    return ValueListenableBuilder<Map<String, double>>(
      valueListenable: widget.stateManager.notifiers.adherenceRatesNotifier,
      builder: (context, rates, _) {
        if (rates.isEmpty) {
          return const SizedBox.shrink();
        }

        final periods = ['7日', '30日', '90日'];
        final colors = [
          [Colors.blue.shade400, Colors.blue.shade600],
          [Colors.green.shade400, Colors.green.shade600],
          [Colors.orange.shade400, Colors.orange.shade600],
        ];
        final icons = [
          Icons.calendar_today,
          Icons.calendar_month,
          Icons.calendar_view_month,
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            // 画面サイズに応じてレイアウトを調整
            if (constraints.maxWidth > 600) {
              // 横並び
              return Row(
                children: List.generate(periods.length, (i) {
                  final period = periods[i];
                  final rate = rates[period] ?? 0.0;
                  final colorPair = colors[i];
                  final icon = icons[i];

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < periods.length - 1 ? 12 : 0,
                      ),
                      child: _buildSummaryCard(
                        period: period,
                        rate: rate,
                        gradientColors: colorPair,
                        icon: icon,
                      ),
                    ),
                  );
                }),
              );
            } else {
              // 縦並び（小さい画面）
              return Column(
                children: List.generate(periods.length, (i) {
                  final period = periods[i];
                  final rate = rates[period] ?? 0.0;
                  final colorPair = colors[i];
                  final icon = icons[i];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < periods.length - 1 ? 12 : 0,
                    ),
                    child: _buildSummaryCard(
                      period: period,
                      rate: rate,
                      gradientColors: colorPair,
                      icon: icon,
                    ),
                  );
                }),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String period,
    required double rate,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    final percentage = rate.clamp(0.0, 100.0);
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                percentage >= 80 ? Icons.trending_up : Icons.trending_down,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '遵守率',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAdherenceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calculate,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'カスタム遵守率',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '任意の期間を指定して分析',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<double?>(
              valueListenable: widget.stateManager.notifiers.customAdherenceResultNotifier,
              builder: (context, result, _) {
                if (result != null && widget.stateManager.customDaysResult != null) {
                  final percentage = (result * 100).clamp(0.0, 100.0);
                  final color = percentage >= 80
                      ? Colors.green
                      : percentage >= 60
                          ? Colors.orange
                          : Colors.red;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${widget.stateManager.customDaysResult}日間',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showCustomAdherenceDialog(),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text(
                  '期間を指定して計算',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceChart(Map<String, double> adherenceRates) {
    if (adherenceRates.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.show_chart,
        title: '遵守率グラフ',
        message: 'データがありません',
      );
    }

    final chartData = adherenceRates.entries.toList();
    final maxValue = chartData.map((e) => e.value).reduce(math.max);
    final minValue = chartData.map((e) => e.value).reduce(math.min);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '遵守率の推移',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '期間別の服薬遵守率',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: math.min(280, MediaQuery.of(context).size.height * 0.35),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                chartData[value.toInt()].key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
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
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue.shade600,
                      barWidth: 4,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.blue.shade600,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.shade400.withOpacity(0.3),
                            Colors.blue.shade400.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minY: (minValue - 10).clamp(0.0, double.infinity),
                  maxY: (maxValue + 10).clamp(0.0, 100.0),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipBgColor: Colors.blue.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationUsageChart(Map<String, int> medicationCount) {
    // 引数で受け取ったデータを使用（初期表示時から反映される）
    if (medicationCount.isEmpty) {
      return _buildEmptyCard(
        icon: Icons.medication,
        title: '薬品別使用状況',
        message: 'データがありません',
      );
    }

    final sortedMedications = medicationCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMedications = sortedMedications.take(8).toList();
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '薬品別使用状況',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '最も使用頻度の高い薬品',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                // 画面幅に応じてレイアウトを調整
                if (constraints.maxWidth > 500) {
                  // 横並び（円グラフと凡例）
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 280,
                          child: PieChart(
                            PieChartData(
                              sections: topMedications.asMap().entries.map((entry) {
                                final index = entry.key;
                                final medication = entry.value;
                                final total = topMedications.fold<int>(
                                  0,
                                  (sum, item) => sum + item.value,
                                );
                                final percentage = (medication.value / total * 100);

                                return PieChartSectionData(
                                  color: colors[index % colors.length],
                                  value: medication.value.toDouble(),
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                              sectionsSpace: 3,
                              centerSpaceRadius: 60,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: topMedications.asMap().entries.map((entry) {
                              final index = entry.key;
                              final medication = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: colors[index % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            medication.key,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${medication.value}回',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // 縦並び（小さい画面）
                  return Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sections: topMedications.asMap().entries.map((entry) {
                              final index = entry.key;
                              final medication = entry.value;
                              final total = topMedications.fold<int>(
                                0,
                                (sum, item) => sum + item.value,
                              );
                              final percentage = (medication.value / total * 100);

                              return PieChartSectionData(
                                color: colors[index % colors.length],
                                value: medication.value.toDouble(),
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 70,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            sectionsSpace: 3,
                            centerSpaceRadius: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: topMedications.asMap().entries.map((entry) {
                          final index = entry.key;
                          final medication = entry.value;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors[index % colors.length].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors[index % colors.length].withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medication.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${medication.value}回',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
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
      barrierDismissible: true,
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

      // StateManagerの初期化チェック
      if (!widget.stateManager.isInitialized) {
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

        // ダイアログはCustomAdherenceDialog内で閉じられるため、ここでは閉じない
        // Navigator.of(context).pop(); // 削除

        final statsController = widget.stateManager.statsScrollController;
        if (statsController.hasClients) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (statsController.hasClients && mounted) {
              try {
                statsController.animateTo(
                  statsController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                );
              } catch (e) {
                debugPrint('❌ スクロールアニメーションエラー: $e');
              }
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
      }
      // エラーを再スローして、ダイアログ側でキャッチできるようにする
      rethrow;
    }
  }
}
