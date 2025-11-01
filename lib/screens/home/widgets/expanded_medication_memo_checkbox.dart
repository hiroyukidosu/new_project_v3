// lib/screens/home/widgets/expanded_medication_memo_checkbox.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';

/// 拡大版の服用メモチェックボックス（カレンダーページ用）
class ExpandedMedicationMemoCheckbox extends StatelessWidget {
  final MedicationMemo memo;
  final bool isSelected;
  final int checkedCount;
  final int totalCount;
  final bool Function(String, int) getMedicationMemoDoseStatus;
  final void Function(String, int, bool) onDoseStatusChanged;
  final void Function() onShowWarningDialog;
  final void Function(String, String) onShowMemoDetailDialog;

  const ExpandedMedicationMemoCheckbox({
    super.key,
    required this.memo,
    required this.isSelected,
    required this.checkedCount,
    required this.totalCount,
    required this.getMedicationMemoDoseStatus,
    required this.onDoseStatusChanged,
    required this.onShowWarningDialog,
    required this.onShowMemoDetailDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.blue
              : checkedCount == totalCount
                  ? Colors.green
                  : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : checkedCount == totalCount ? 1.5 : 1,
        ),
        color: isSelected
            ? Colors.blue.withOpacity(0.1)
            : checkedCount == totalCount
                ? Colors.green.withOpacity(0.05)
                : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上部：アイコン、薬名、服用回数情報
            Row(
              children: [
                // 大きなアイコン
                CircleAvatar(
                  backgroundColor: memo.color,
                  radius: 20,
                  child: Icon(
                    memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 薬名と種類
                      Text(
                        memo.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: checkedCount == totalCount ? Colors.green : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: checkedCount == totalCount
                              ? Colors.green.withOpacity(0.2)
                              : memo.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          memo.type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: checkedCount == totalCount ? Colors.green : memo.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 服用回数に応じたチェックボックス
            const SizedBox(height: 12),
            Row(
              children: List.generate(totalCount, (index) {
                final isChecked = getMedicationMemoDoseStatus(memo.id, index);
                return Expanded(
                  child: Semantics(
                    label: '${memo.name}の服用記録 ${index + 1}回目',
                    hint: 'タップして服用状態を切り替え',
                    child: GestureDetector(
                      onTap: () {
                        onDoseStatusChanged(memo.id, index, !isChecked);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? Colors.green : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecked ? Colors.green : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isChecked ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${index + 1}回目',
                              style: TextStyle(
                                fontSize: 10,
                                color: isChecked ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            // 服用回数情報
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '服用回数: ${memo.dosageFrequency}回 (${checkedCount}/${totalCount})',
                    style: TextStyle(
                      fontSize: 14,
                      color: checkedCount == totalCount ? Colors.green : Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (memo.dosageFrequency >= 6) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onShowWarningDialog(),
                      child: const Icon(Icons.warning, size: 16, color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
            // 用量情報
            if (memo.dosage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.straighten, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '用量: ${memo.dosage}',
                      style: TextStyle(
                        fontSize: 14,
                        color: checkedCount == totalCount ? Colors.green : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // メモ情報（タップ可能）
            if (memo.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => onShowMemoDetailDialog(memo.name, memo.notes),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'メモ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        memo.notes,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'タップしてメモを表示',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

