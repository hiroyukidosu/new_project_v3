// MedicineTab
// 服用メモタブ

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../services/trial_service.dart';
import '../../widgets/trial_limit_dialog.dart';

/// 服用メモタブ
/// 服用メモのリストを表示・管理
class MedicineTab extends StatelessWidget {
  final List<MedicationMemo> medicationMemos;
  final ScrollController scrollController;
  final Function(MedicationMemo) onMarkAsTaken;
  final Function(MedicationMemo) onEditMemo;
  final Function(String) onDeleteMemo;
  final Function(BuildContext) onShowWarningDialog;

  const MedicineTab({
    super.key,
    required this.medicationMemos,
    required this.scrollController,
    required this.onMarkAsTaken,
    required this.onEditMemo,
    required this.onDeleteMemo,
    required this.onShowWarningDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                '服用メモ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // 服用メモリスト（無限スクロール対応・高さ最適化）
              Expanded(
                flex: 1,
                child: medicationMemos.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 72, color: Colors.grey),
                            SizedBox(height: 12),
                            Text(
                              '服用メモがまだありません',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '右下の+マークから新しいメモを追加できます。',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: medicationMemos.length,
                        cacheExtent: 1000,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        addSemanticIndexes: true,
                        shrinkWrap: true,
                        primary: false,
                        itemBuilder: (context, index) {
                          final memo = medicationMemos[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                children: [
                                  // アイコンと名前を上に配置
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: memo.color,
                                        radius: 24,
                                        child: Icon(
                                          memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                                          color: Colors.white,
                                          size: 24,
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
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: memo.type == 'サプリメント'
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.blue.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: memo.type == 'サプリメント'
                                                      ? Colors.green.withOpacity(0.3)
                                                      : Colors.blue.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                memo.type,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? Colors.white70
                                                      : (memo.type == 'サプリメント' ? Colors.green : Colors.blue),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // アクションボタンを右上に配置
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          // トライアル制限チェック
                                          final isExpired = await TrialService.isTrialExpired();
                                          if (isExpired) {
                                            showDialog(
                                              context: context,
                                              builder: (context) => TrialLimitDialog(featureName: '服用メモ'),
                                            );
                                            return;
                                          }
                                          switch (value) {
                                            case 'taken':
                                              onMarkAsTaken(memo);
                                              break;
                                            case 'edit':
                                              onEditMemo(memo);
                                              break;
                                            case 'delete':
                                              onDeleteMemo(memo.id);
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'taken',
                                            child: Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.green),
                                                SizedBox(width: 8),
                                                Text('服用記録'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('編集'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('削除'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        child: const Icon(Icons.more_vert),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  // 詳細情報を下に配置
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 服用回数情報
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.repeat, size: 16, color: Colors.blue),
                                            const SizedBox(width: 8),
                                            Text(
                                              '服用回数: ${memo.dosageFrequency}回',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                            if (memo.dosageFrequency >= 6) ...[
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () {
                                                  onShowWarningDialog(context);
                                                },
                                                child: const Icon(Icons.warning, size: 16, color: Colors.orange),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (memo.dosage.isNotEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
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
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (memo.dosage.isNotEmpty) const SizedBox(height: 10),
                                      if (memo.notes.isNotEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.note, size: 16, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  memo.notes,
                                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (memo.notes.isNotEmpty) const SizedBox(height: 10),
                                      // 曜日未設定の警告表示
                                      if (memo.selectedWeekdays.isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red.withOpacity(0.15),
                                                Colors.orange.withOpacity(0.15),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(0.5),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.red.withOpacity(0.2),
                                                spreadRadius: 2,
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.warning_amber_rounded,
                                                      size: 28,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '⚠️ 服用スケジュール未設定',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          '曜日を設定してください',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.orange,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'メモを編集して「服用スケジュール」から(毎日、曜日)を選択してください',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey[800],
                                                          height: 1.4,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (memo.selectedWeekdays.isEmpty) const SizedBox(height: 10),
                                      if (memo.lastTaken != null)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.schedule, size: 16, color: Colors.green),
                                              const SizedBox(width: 8),
                                              Text(
                                                '最後の服用:\n${DateFormat('yyyy/MM/dd HH:mm').format(memo.lastTaken!)}',
                                                style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w500),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

