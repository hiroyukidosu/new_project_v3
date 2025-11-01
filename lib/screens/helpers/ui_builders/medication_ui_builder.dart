import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';
import '../../../models/medication_info.dart';

/// メディケーションUIビルダーミックスイン
/// メディケーション関連のUI構築メソッドを提供
mixin MedicationUIBuilderMixin {
  // これらの変数は_MedicationHomePageStateで定義されている前提
  List<MedicationMemo> get medicationMemos;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  Map<String, bool> get medicationMemoStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  DateTime? get selectedDay;
  
  // これらのメソッドは_MedicationHomePageStateで定義されている前提
  void Function(String, int, bool) get onDoseStatusChanged;
  void Function(MedicationMemo) get onEditMemo;
  void Function(String) get onDeleteMemo;
  void Function(MedicationMemo) get onMarkAsTaken;
  
  /// メディケーションメモのチェックボックスを構築
  Widget buildMedicationMemoCheckbox(MedicationMemo memo) {
    if (selectedDay == null) {
      return const SizedBox.shrink();
    }
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
    final doseStatus = weekdayMedicationDoseStatus[dateStr]?[memo.id] ?? {};
    final totalDoses = memo.dosageFrequency;
    final checkedDoses = doseStatus.values.where((checked) => checked).length;
    final allChecked = totalDoses > 0 && checkedDoses == totalDoses;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      child: ListTile(
        leading: Checkbox(
          value: allChecked,
          onChanged: (value) {
            onMarkAsTaken(memo);
          },
        ),
        title: Row(
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${memo.type} / ${memo.dosage}'),
            if (totalDoses > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(totalDoses, (index) {
                  final isChecked = doseStatus[index] ?? false;
                  return GestureDetector(
                    onTap: () => onDoseStatusChanged(memo.id, index, !isChecked),
                    child: Chip(
                      label: Text('${index + 1}回目'),
                      backgroundColor: isChecked
                          ? Colors.green.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => onEditMemo(memo),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => onDeleteMemo(memo.id),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 服用記録リストを構築
  Widget buildMedicationRecords({
    required List<Map<String, dynamic>> addedMedications,
    required void Function(int) onDeleteRecord,
    required void Function(int) onToggleRecord,
  }) {
    if (addedMedications.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: addedMedications.length,
        itemBuilder: (context, index) {
          final medication = addedMedications[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: medication['isChecked'] == true,
                    onChanged: (_) => onToggleRecord(index),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication['name'] ?? '薬',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

