// UI構築メソッドのMixin
// home_page.dartからUI構築関連の機能を分離

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../widgets/trial_limit_dialog.dart';
import '../../services/trial_service.dart';

/// UI構築メソッドのMixin
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
mixin HomePageUIBuildersMixin<T extends StatefulWidget> on State<T> {
  // 抽象ゲッター（実装クラスで提供する必要がある）
  DateTime? get selectedDay;
  List<Map<String, dynamic>> get addedMedications;
  List<MedicationMemo> get medicationMemos;
  Map<String, bool> get medicationMemoStatus;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  Map<String, Color> get dayColors;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  
  // 抽象メソッド（実装クラスで提供する必要がある）
  int getMedicationMemoDoseStatusForSelectedDay(String memoId, int doseIndex);
  int getMedicationMemoCheckedCountForSelectedDay(String memoId);
  Future<void> saveSnapshotBeforeChange(String operationType);
  Future<void> updateMedicationDoseStatus(String memoId, int doseIndex, bool isChecked);
  Future<void> saveAllData();
  List<MedicationMemo> getMedicationsForSelectedDay();
  void showMemoDetailDialog(BuildContext context, String medicationName, String memo);
  void showSnackBar(String message);
  Future<void> calculateAdherenceStats();

  // 服用記録の件数を取得するヘルパーメソッド
  int getMedicationRecordCount() {
    return addedMedications.length + getMedicationsForSelectedDay().length;
  }

  // 統計カードを構築
  Widget buildStatCard(String period, double rate) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(period, style: const TextStyle(fontSize: 18)),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: rate >= 80 ? Colors.green : rate >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 服用統計を構築
  Widget buildMedicationStats() {
    if (selectedDay == null) return const SizedBox.shrink();
    
    // 完全に作り直された統計計算
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    totalMedications += addedMedications.length;
    takenMedications += addedMedications.where((med) => med['isChecked'] == true).length;
    
    // 服用メモの統計（今日の曜日に該当するもののみ）
    final weekday = selectedDay!.weekday % 7;
    
    for (final memo in medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications++;
        if (medicationMemoStatus[memo.id] == true) {
          takenMedications++;
        }
      }
    }
    
    final progress = totalMedications > 0 ? takenMedications / totalMedications : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: progress == 1.0 
            ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
            : [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: progress == 1.0 ? Colors.green : Colors.orange,
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
                      progress == 1.0 ? Icons.check_circle : Icons.schedule,
                      color: progress == 1.0 ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      progress == 1.0 ? '完了' : '進行中',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: progress == 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${takenMedications}/${totalMedications}件',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // メモフィールドを構築（簡易版 - 詳細は実装クラスで提供）
  Widget buildMemoField() {
    // このメソッドは実装クラスで詳細を提供する必要があります
    // ここではプレースホルダーとして空のWidgetを返します
    return const SizedBox.shrink();
  }

  // 服用記録を構築（簡易版 - 詳細は実装クラスで提供）
  Widget buildMedicationRecords() {
    // このメソッドは実装クラスで詳細を提供する必要があります
    // ここではプレースホルダーとして空のWidgetを返します
    return const SizedBox.shrink();
  }

  // 服用メモのチェックボックスを構築（簡易版）
  Widget buildMedicationMemoCheckbox(MedicationMemo memo) {
    final checkedCount = getMedicationMemoCheckedCountForSelectedDay(memo.id);
    final totalCount = memo.dosageFrequency;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checkedCount == totalCount 
              ? Colors.green 
              : Colors.grey.withOpacity(0.3),
          width: checkedCount == totalCount ? 1.5 : 1,
        ),
        color: checkedCount == totalCount 
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
                          color: checkedCount == totalCount ? Colors.green : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: checkedCount == totalCount ? Colors.green.withOpacity(0.2) : memo.color.withOpacity(0.2),
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
            const SizedBox(height: 12),
            Row(
              children: List.generate(totalCount, (index) {
                final isChecked = getMedicationMemoDoseStatusForSelectedDay(memo.id, index);
                return Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      if (selectedDay != null) {
                        await saveSnapshotBeforeChange('服用記録更新_${memo.name}_${index + 1}回目');
                        await updateMedicationDoseStatus(memo.id, index, !isChecked);
                        await saveAllData();
                        if (mounted) {
                          setState(() {
                            // UI更新
                          });
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isChecked ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isChecked ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isChecked ? Colors.green : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (memo.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  showMemoDetailDialog(context, memo.name, memo.notes);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          memo.notes,
                          style: const TextStyle(fontSize: 12, color: Colors.blue),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  // 薬がない場合のメッセージを構築
  Widget buildNoMedicationMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'この日に服用する薬はありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

