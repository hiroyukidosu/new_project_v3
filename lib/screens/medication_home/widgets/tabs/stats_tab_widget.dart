// lib/screens/medication_home/widgets/tabs/stats_tab_widget.dart

import 'package:flutter/material.dart';
import '../../../controllers/medication_home_controller.dart';
import '../../../controllers/stats_controller.dart';
import '../../home/widgets/medication_stats_card.dart';

/// 統計タブウィジェット
class StatsTabWidget extends StatelessWidget {
  final MedicationHomeController mainController;
  final StatsController statsController;

  const StatsTabWidget({
    super.key,
    required this.mainController,
    required this.statsController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([mainController, statsController]),
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '統計情報',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 統計情報表示
              if (statsController.adherenceRates.isNotEmpty) ...[
                ...statsController.adherenceRates.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(entry.key),
                      trailing: Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: entry.value >= 80
                              ? Colors.green
                              : entry.value >= 60
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              
              // カスタム遵守率カード
              if (statsController.customAdherenceResult != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${statsController.customDaysResult}日間の遵守率',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${statsController.customAdherenceResult!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: statsController.customAdherenceResult! >= 80
                                ? Colors.green
                                : statsController.customAdherenceResult! >= 60
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // カスタム遵守率計算ボタン
              ElevatedButton.icon(
                onPressed: () async {
                  // TODO: CustomAdherenceDialogを使用
                  final days = 30; // デフォルト値
                  await statsController.calculateCustomAdherence(
                    days: days,
                    medicationData: mainController.medicationData,
                    memos: mainController.memos,
                    weekdayMedicationStatus: {},
                    medicationMemoStatus: mainController.medicationMemoStatus,
                    getMedicationMemoCheckedCountForDate: (memoId, dateStr) {
                      // TODO: メモチェック回数取得機能を実装
                      return 0;
                    },
                  );
                },
                icon: const Icon(Icons.calculate),
                label: const Text('カスタム遵守率を計算'),
              ),
            ],
          ),
        );
      },
    );
  }
}

