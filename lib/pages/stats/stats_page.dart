import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/medication_state.dart';
import '../../use_cases/stats/calculate_adherence_use_case.dart';
import '../../repositories/medication_repository.dart';
import '../../widgets/stats/adherence_chart_card.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_dialog.dart';

/// 統計ページ
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});
  
  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  Map<String, double> _adherenceRates = {};
  bool _isCalculating = false;
  int _selectedDays = 7;
  
  // カスタム遵守率機能用の変数
  final ScrollController _statsScrollController = ScrollController();
  double? _customAdherenceResult;
  int? _customDaysResult;
  final TextEditingController _customDaysController = TextEditingController();
  final FocusNode _customDaysFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _calculateAdherence();
  }
  
  @override
  void dispose() {
    _statsScrollController.dispose();
    _customDaysController.dispose();
    _customDaysFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _calculateAdherence() async {
    setState(() => _isCalculating = true);
    try {
      final repository = ref.read(medicationRepositoryProvider);
      final useCase = CalculateAdherenceUseCase(repository);
      final rates = await useCase.execute(_selectedDays);
      setState(() {
        _adherenceRates = rates;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() => _isCalculating = false);
      if (mounted) {
        ErrorDialog.show(
          context,
          message: '遵守率の計算に失敗しました: $e',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final medicationState = ref.watch(medicationStateProvider);
    
    return LoadingOverlay(
      isLoading: medicationState.isLoading || _isCalculating,
      message: '計算中...',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('統計'),
        ),
        body: Column(
          children: [
            // 期間選択
            _buildPeriodSelector(context),
            
            // 遵守率グラフ
            Expanded(
              child: _adherenceRates.isEmpty
                  ? _buildEmptyState(context)
                  : SingleChildScrollView(
                      controller: _statsScrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AdherenceChartCard(
                            adherenceRates: _adherenceRates,
                            title: '${_selectedDays}日間の遵守率',
                          ),
                          const SizedBox(height: 16),
                          // カスタム遵守率カード
                          _buildCustomAdherenceCard(context),
                          const SizedBox(height: 16),
                          // 詳細統計をここに追加可能
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPeriodSelector(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '期間を選択',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7日')),
                ButtonSegment(value: 30, label: Text('30日')),
                ButtonSegment(value: 90, label: Text('90日')),
              ],
              selected: {_selectedDays},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _selectedDays = selection.first;
                  _calculateAdherence();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCustomAdherenceCard(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '任意の日数の遵守率',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCustomAdherenceDialog(context),
                  icon: const Icon(Icons.analytics, size: 18),
                  label: const Text('分析'),
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
    );
  }
  
  void _showCustomAdherenceDialog(BuildContext context) {
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
                      _calculateCustomAdherence(context, days);
                      setDialogState(() {}); // ダイアログ内の状態を更新
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('1から365の範囲で日数を入力してください'),
                        ),
                      );
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
  
  Future<void> _calculateCustomAdherence(BuildContext context, int days) async {
    try {
      // 現在のスクロール位置を保存
      final currentScrollPosition = _statsScrollController.hasClients 
          ? _statsScrollController.offset 
          : 0.0;
      
      // キーボードを閉じる
      _customDaysFocusNode.unfocus();
      FocusScope.of(context).unfocus();
      
      setState(() => _isCalculating = true);
      
      // 遵守率を計算
      final repository = ref.read(medicationRepositoryProvider);
      final useCase = CalculateAdherenceUseCase(repository);
      final rates = await useCase.execute(days);
      
      // 全体の遵守率を計算（平均）
      double totalRate = 0.0;
      if (rates.isNotEmpty) {
        totalRate = rates.values.reduce((a, b) => a + b) / rates.length;
      }
      
      if (totalRate == 0.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('指定した期間に服薬データがありません')),
          );
        }
        setState(() => _isCalculating = false);
        return;
      }
      
      setState(() {
        _customAdherenceResult = totalRate;
        _customDaysResult = days;
        _isCalculating = false;
      });
      
      // ダイアログを閉じる
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // スクロール位置を復元（統計ページの一番下に戻る）
      if (_statsScrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_statsScrollController.hasClients) {
            _statsScrollController.animateTo(
              _statsScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      setState(() => _isCalculating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カスタム遵守率の計算に失敗しました: $e')),
        );
      }
    }
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'データがありません',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

