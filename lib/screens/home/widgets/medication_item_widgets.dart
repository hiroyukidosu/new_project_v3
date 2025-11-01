// lib/screens/home/widgets/medication_item_widgets.dart
// 服用記録に関するウィジェットを集約

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';

/// 追加された薬の服用記録カード
class AddedMedicationCard extends StatelessWidget {
  final Map<String, dynamic> medication;
  final VoidCallback onCheckToggle;
  final VoidCallback onDelete;

  const AddedMedicationCard({
    super.key,
    required this.medication,
    required this.onCheckToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = medication['isChecked'] ?? false;
    final medicationName = medication['name'] ?? '';
    final medicationType = medication['type'] ?? '';
    final medicationColor = medication['color'] ?? Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isChecked ? Colors.green : Colors.grey.withOpacity(0.3),
          width: isChecked ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // チェックボックス
            GestureDetector(
              onTap: onCheckToggle,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isChecked ? Colors.green : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isChecked ? Colors.white : Colors.grey,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 薬情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        medicationType == 'サプリメント' ? Icons.eco : Icons.medication,
                        color: isChecked ? Colors.green : medicationColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          medicationName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isChecked ? Colors.green : const Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      if (isChecked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '服用済み',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    medicationType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // 削除ボタン
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: '削除',
            ),
          ],
        ),
      ),
    );
  }
}

/// 曜日設定された薬の服用記録カード（服用回数対応）
class WeekdayMedicationCard extends StatelessWidget {
  final MedicationMemo memo;
  final int totalDoses;
  final int checkedDoses;
  final Function(int doseIndex) onDoseToggle;
  final VoidCallback? onTap;

  const WeekdayMedicationCard({
    super.key,
    required this.memo,
    required this.totalDoses,
    required this.checkedDoses,
    required this.onDoseToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAllChecked = checkedDoses == totalDoses;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAllChecked ? Colors.green : Colors.grey.withOpacity(0.3),
            width: isAllChecked ? 2 : 1,
          ),
          color: isAllChecked ? Colors.green.withOpacity(0.05) : Colors.white,
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
              // ヘッダー
              Row(
                children: [
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
                        Text(
                          memo.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAllChecked ? Colors.green : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAllChecked
                                ? Colors.green.withOpacity(0.2)
                                : memo.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            memo.type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isAllChecked ? Colors.green : memo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // 服用回数チェックボックス
              const SizedBox(height: 12),
              Row(
                children: List.generate(totalDoses, (index) {
                  final isChecked = index < checkedDoses;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onDoseToggle(index),
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
                  );
                }),
              ),
              // 服用情報
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
                      '服用回数: $totalDoses回 ($checkedDoses/$totalDoses)',
                      style: TextStyle(
                        fontSize: 14,
                        color: isAllChecked ? Colors.green : Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (totalDoses >= 6) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.warning, size: 16, color: Colors.orange),
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
                          color: isAllChecked ? Colors.green : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // メモ情報
              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
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
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// データなしメッセージ
class NoMedicationMessage extends StatelessWidget {
  final VoidCallback onAddMemo;

  const NoMedicationMessage({
    super.key,
    required this.onAddMemo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            '服用メモから服用スケジュール\n(毎日、曜日)を選択してください',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '服用メモタブで薬品やサプリメントを追加してから、\nカレンダーページで服用スケジュールを管理できます。',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddMemo,
            icon: const Icon(Icons.add),
            label: const Text('服用メモを追加'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 服用統計カード（簡易版）
class MedicationStatsCardSimple extends StatelessWidget {
  final int total;
  final int taken;

  const MedicationStatsCardSimple({
    super.key,
    required this.total,
    required this.taken,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? taken / total : 0.0;
    final isComplete = progress == 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isComplete
              ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
              : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : Icons.schedule,
                      color: isComplete ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '今日の服用状況',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isComplete ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$taken / $total 服用済み',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.orange,
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete ? Colors.green : Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: (isComplete ? Colors.green : Colors.orange).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

