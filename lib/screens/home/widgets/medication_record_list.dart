// lib/screens/home/widgets/medication_record_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';

/// 服用記録リストウィジェット
class MedicationRecordList extends StatelessWidget {
  final DateTime? selectedDay;
  final List<MedicationMemo> medicationMemos;
  final List<Map<String, dynamic>> addedMedications;
  final bool isMemoSelected;
  final MedicationMemo? selectedMemo;
  final Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus;
  final Function(MedicationMemo) onMemoTap;
  final Function() onBackTap;
  final Function(String, int, bool) onDoseStatusChanged;
  final Function(MedicationMemo) onEditMemo;
  final Function(String) onDeleteMemo;
  final Widget Function(MedicationMemo) buildMedicationMemoCheckbox;
  final Widget Function(Map<String, dynamic>) buildAddedMedicationRecord;
  final Widget Function() buildNoMedicationMessage;

  const MedicationRecordList({
    super.key,
    this.selectedDay,
    this.medicationMemos = const [],
    this.addedMedications = const [],
    this.isMemoSelected = false,
    this.selectedMemo,
    this.weekdayMedicationDoseStatus = const {},
    required this.onMemoTap,
    required this.onBackTap,
    required this.onDoseStatusChanged,
    required this.onEditMemo,
    required this.onDeleteMemo,
    required this.buildMedicationMemoCheckbox,
    required this.buildAddedMedicationRecord,
    required this.buildNoMedicationMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return buildNoMedicationMessage();
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          _buildHeader(context),
          // リストコンテンツ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMemoSelected && selectedMemo != null) ...[
                  _buildBackButton(context),
                  const SizedBox(height: 8),
                  buildMedicationMemoCheckbox(selectedMemo!),
                ] else ...[
                  _buildMedicationItems(context, dateStr),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Text(
            selectedDay != null
                ? '${DateFormat('yyyy年M月d日', 'ja_JP').format(selectedDay!)}の服用記録'
                : '服用記録',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '今日の服用状況を確認しましょう',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onBackTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              const Text(
                '戻る',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationItems(BuildContext context, String dateStr) {
    final totalCount = addedMedications.length + medicationMemos.length;
    
    if (totalCount == 0) {
      return buildNoMedicationMessage();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index < addedMedications.length) {
          // 追加された薬
          return buildAddedMedicationRecord(addedMedications[index]);
        } else {
          // 服用メモ
          final memoIndex = index - addedMedications.length;
          if (memoIndex < medicationMemos.length) {
            return GestureDetector(
              onTap: () => onMemoTap(medicationMemos[memoIndex]),
              child: buildMedicationMemoCheckbox(medicationMemos[memoIndex]),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}
