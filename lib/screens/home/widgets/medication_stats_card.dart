// lib/screens/home/widgets/medication_stats_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 服用統計カードウィジェット
class MedicationStatsCard extends StatelessWidget {
  final DateTime? selectedDay;
  final Map<String, int> stats;
  final String title;

  const MedicationStatsCard({
    super.key,
    this.selectedDay,
    required this.stats,
    this.title = '服用統計',
  });

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final percentage = total > 0 ? (taken / total * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  selectedDay != null
                      ? '${DateFormat('yyyy年M月d日', 'ja_JP').format(selectedDay!)}の$title'
                      : title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  '総数',
                  total.toString(),
                  Icons.medication,
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  '服用済み',
                  taken.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  '未服用',
                  (total - taken).toString(),
                  Icons.radio_button_unchecked,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 進捗バー
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: percentage >= 80
                          ? [Colors.green, Colors.greenAccent]
                          : percentage >= 60
                              ? [Colors.orange, Colors.deepOrange]
                              : [Colors.red, Colors.redAccent],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '遵守率: ${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: percentage >= 80
                    ? Colors.green
                    : percentage >= 60
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
