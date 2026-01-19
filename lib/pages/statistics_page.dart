import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/medication_provider.dart';

/// 統計ページ - 無限ループを防止する最適化実装
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _lastTimestamp = 0;
  bool _isInitialized = false;
  bool _isScheduling = false; // スケジューリング中フラグ
  Timer? _scheduleTimer; // デバウンス用タイマー
  
  // 無限ループ検出
  int _listenerCallCount = 0;
  DateTime? _lastListenerCallTime;
  static const _maxListenerCallsPerSecond = 10;

  @override
  void initState() {
    super.initState();
    // ログを無効化
    StatisticsProvider.disableLogs();
    MedicationProvider.disableLogs();
    
    // 初回のみ計算をトリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final medicationProvider = context.read<MedicationProvider>();
        _lastTimestamp = medicationProvider.lastUpdateTimestamp;
        
        // ⚠️ リスナーを登録する前に初期計算を実行（無限ループ防止）
        context.read<StatisticsProvider>().scheduleRecalculation();
        _isInitialized = true;
        
        // ⚠️ リスナー登録を遅延させる（初期計算完了後）
        // さらに、計算が完了するまで待機
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            final statsProvider = context.read<StatisticsProvider>();
            // 計算が完了していることを確認してからリスナーを登録
            if (!statsProvider.isCalculating) {
              medicationProvider.addListener(_onMedicationDataChanged);
            } else {
              // 計算中なら、さらに待機
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && !statsProvider.isCalculating) {
                  medicationProvider.addListener(_onMedicationDataChanged);
                }
              });
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // リスナーを削除
    if (_isInitialized) {
      context.read<MedicationProvider>().removeListener(_onMedicationDataChanged);
    }
    // タイマーをキャンセル
    _scheduleTimer?.cancel();
    super.dispose();
  }

  void _onMedicationDataChanged() {
    // 無限ループ検出
    final now = DateTime.now();
    if (_lastListenerCallTime != null) {
      final elapsed = now.difference(_lastListenerCallTime!);
      if (elapsed.inSeconds < 1) {
        _listenerCallCount++;
        if (_listenerCallCount > _maxListenerCallsPerSecond) {
          final stackTrace = StackTrace.current;
          debugPrint('🚨 StatisticsPage: _onMedicationDataChanged()が異常に多く呼ばれています: $_listenerCallCount回/秒');
          debugPrint('📍 スタックトレース:\n$stackTrace');
          _listenerCallCount = 0;
          return; // 処理をスキップ
        }
      } else {
        _listenerCallCount = 0;
      }
    }
    _lastListenerCallTime = now;
    
    if (!mounted || _isScheduling) return;
    
    // ⚠️ StatisticsProviderが計算中の場合、リスナーを無視（無限ループ防止）
    final statisticsProvider = context.read<StatisticsProvider>();
    if (statisticsProvider.isCalculating) {
      return; // 計算中は無視
    }
    
    final medicationProvider = context.read<MedicationProvider>();
    final newTimestamp = medicationProvider.lastUpdateTimestamp;
    
    // timestampが実際に変更された場合のみ処理
    if (newTimestamp != _lastTimestamp) {
      _lastTimestamp = newTimestamp;
      _isScheduling = true;
      
      // 既存のタイマーをキャンセル
      _scheduleTimer?.cancel();
      
      // デバウンス処理：短時間内の連続呼び出しを防ぐ
      _scheduleTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted && _isScheduling) {
          // ⚠️ 再度計算中チェック（タイマー実行時）
          if (!statisticsProvider.isCalculating) {
            statisticsProvider.scheduleRecalculation();
          }
          _isScheduling = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服薬統計'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () {
              context.read<StatisticsProvider>().forceRefresh();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 統計データの表示のみ（isCalculatingとadherenceRatesのみ監視）
    // ⚠️ builder内では何も実行しない（無限ループ防止）
    return Selector<StatisticsProvider, ({bool isCalculating, Map<int, double> rates})>(
          selector: (context, provider) => (
            isCalculating: provider.isCalculating,
            rates: provider.adherenceRates,
          ),
          shouldRebuild: (previous, next) => 
            previous.isCalculating != next.isCalculating ||
            !_mapsEqual(previous.rates, next.rates),
          builder: (context, data, _) {
            // ⚠️ builder内では計算をトリガーしない（純粋にUIの表示のみ）
            if (data.isCalculating && data.rates.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('統計を計算中...'),
                  ],
                ),
              );
            }

            if (data.rates.isEmpty) {
              return const Center(
                child: Text('統計データがありません'),
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<StatisticsProvider>().forceRefresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('遵守率'),
                  const SizedBox(height: 16),
                  _buildAdherenceCard('7日間', data.rates[7] ?? 0.0),
                  const SizedBox(height: 12),
                  _buildAdherenceCard('30日間', data.rates[30] ?? 0.0),
                  const SizedBox(height: 12),
                  _buildAdherenceCard('90日間', data.rates[90] ?? 0.0),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                ],
              ),
            );
          },
        );
      },
    );
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildAdherenceCard(String period, double rate) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  period,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getRateColor(rate),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_getRateColor(rate)),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '遵守率は定期的に自動更新されます。\n手動で更新する場合は、右上の更新ボタンをタップしてください。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
