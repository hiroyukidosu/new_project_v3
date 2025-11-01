import 'package:flutter/material.dart';
import '../../models/medication_memo.dart';

/// 服用メモチェックボックスウィジェット
class MedicationMemoCheckbox extends StatelessWidget {
  final MedicationMemo memo;
  final Function(String, int, bool) onDoseStatusChanged;
  final Map<String, Map<int, bool>> doseStatus;
  
  const MedicationMemoCheckbox({
    super.key,
    required this.memo,
    required this.onDoseStatusChanged,
    required this.doseStatus,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateKey = _getDateKey(DateTime.now());
    final memoDoseStatus = doseStatus[dateKey]?[memo.id] ?? {};
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: memo.color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    memo.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${memo.type} / ${memo.dosage}',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (memo.dosageFrequency > 1) ...[
              const SizedBox(height: 12),
              const Text(
                '服用回数:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: List.generate(memo.dosageFrequency, (index) {
                  final isChecked = memoDoseStatus[index] ?? false;
                  return GestureDetector(
                    onTap: () => onDoseStatusChanged(
                      memo.id,
                      index,
                      !isChecked,
                    ),
                    child: Chip(
                      label: Text('${index + 1}回目'),
                      backgroundColor: isChecked
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant,
                      avatar: Icon(
                        isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 18,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

