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
  
  @override
  void initState() {
    super.initState();
    _calculateAdherence();
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          AdherenceChartCard(
                            adherenceRates: _adherenceRates,
                            title: '${_selectedDays}日間の遵守率',
                          ),
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

