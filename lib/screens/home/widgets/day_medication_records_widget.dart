// lib/screens/home/widgets/day_medication_records_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication_memo.dart';
import 'medication_item_widgets.dart';
import 'expanded_medication_memo_checkbox.dart';

/// 日付別服用記録リストウィジェット
class DayMedicationRecordsWidget extends StatelessWidget {
  final DateTime? selectedDay;
  final List<MedicationMemo> medicationMemos;
  final List<Map<String, dynamic>> addedMedications;
  final Map<String, Map<String, Map<int, bool>>> weekdayMedicationDoseStatus;
  final bool isMemoSelected;
  final MedicationMemo? selectedMemo;
  final Function(MedicationMemo) onMemoTap;
  final VoidCallback onBackTap;
  final Function(String, int, bool) onDoseStatusChanged;
  final Function(MedicationMemo) onEditMemo;
  final Function(String) onDeleteMemo;
  final Function(String, String) onShowMemoDetailDialog;
  final Function() onShowWarningDialog;
  final bool Function(String, int) getMedicationMemoDoseStatus;
  final int Function(String) getMedicationMemoCheckedCount;
  final Function(Map<String, dynamic>) onAddedMedicationCheckToggle;
  final Function(Map<String, dynamic>) onAddedMedicationDelete;

  const DayMedicationRecordsWidget({
    super.key,
    required this.selectedDay,
    required this.medicationMemos,
    required this.addedMedications,
    required this.weekdayMedicationDoseStatus,
    required this.isMemoSelected,
    this.selectedMemo,
    required this.onMemoTap,
    required this.onBackTap,
    required this.onDoseStatusChanged,
    required this.onEditMemo,
    required this.onDeleteMemo,
    required this.onShowMemoDetailDialog,
    required this.onShowWarningDialog,
    required this.getMedicationMemoDoseStatus,
    required this.getMedicationMemoCheckedCount,
    required this.onAddedMedicationCheckToggle,
    required this.onAddedMedicationDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) {
      return NoMedicationMessage(
        onAddMemo: () {
          // タブ切り替えは親で処理
        },
      );
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
    final weekday = selectedDay!.weekday % 7;
    final dayMemos = medicationMemos.where((memo) {
      return memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday);
    }).toList();

    final totalCount = addedMedications.length + dayMemos.length;

    if (totalCount == 0) {
      return NoMedicationMessage(
        onAddMemo: () {
          // タブ切り替えは親で処理
        },
      );
    }

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${DateFormat('yyyy年M月d日', 'ja_JP').format(selectedDay!)}の服用記録',
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
          ),
          // リストコンテンツ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMemoSelected && selectedMemo != null) ...[
                  _buildBackButton(context),
                  const SizedBox(height: 8),
                  _buildSelectedMemoCheckbox(selectedMemo!, dateStr),
                ] else ...[
                  ...addedMedications.map((medication) {
                    return AddedMedicationCard(
                      medication: medication,
                      onCheckToggle: () => onAddedMedicationCheckToggle(medication),
                      onDelete: () => onAddedMedicationDelete(medication),
                    );
                  }),
                  ...dayMemos.map((memo) {
                    return GestureDetector(
                      onTap: () => onMemoTap(memo),
                      child: _buildMemoCheckbox(memo, dateStr),
                    );
                  }),
                ],
              ],
            ),
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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: Colors.blue, size: 16),
              SizedBox(width: 8),
              Text(
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

  Widget _buildSelectedMemoCheckbox(MedicationMemo memo, String dateStr) {
    final checkedCount = getMedicationMemoCheckedCount(memo.id);
    final totalCount = memo.dosageFrequency;

    return ExpandedMedicationMemoCheckbox(
      memo: memo,
      isSelected: true,
      checkedCount: checkedCount,
      totalCount: totalCount,
      getMedicationMemoDoseStatus: getMedicationMemoDoseStatus,
      onDoseStatusChanged: onDoseStatusChanged,
      onShowWarningDialog: onShowWarningDialog,
      onShowMemoDetailDialog: onShowMemoDetailDialog,
    );
  }

  Widget _buildMemoCheckbox(MedicationMemo memo, String dateStr) {
    final checkedCount = getMedicationMemoCheckedCount(memo.id);
    final totalCount = memo.dosageFrequency;

    return ExpandedMedicationMemoCheckbox(
      memo: memo,
      isSelected: false,
      checkedCount: checkedCount,
      totalCount: totalCount,
      getMedicationMemoDoseStatus: getMedicationMemoDoseStatus,
      onDoseStatusChanged: onDoseStatusChanged,
      onShowWarningDialog: onShowWarningDialog,
      onShowMemoDetailDialog: onShowMemoDetailDialog,
    );
  }
}

