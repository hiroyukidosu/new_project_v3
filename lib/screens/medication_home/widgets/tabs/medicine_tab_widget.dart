// lib/screens/medication_home/widgets/tabs/medicine_tab_widget.dart

import 'package:flutter/material.dart';
import '../../../controllers/medication_home_controller.dart';
import '../../../controllers/medication_memo_controller.dart';
import '../../home/widgets/medication_record_list.dart';
import '../../home/widgets/memo_field.dart';

/// 服用メモタブウィジェット
class MedicineTabWidget extends StatelessWidget {
  final MedicationHomeController mainController;
  final MedicationMemoController memoController;

  const MedicineTabWidget({
    super.key,
    required this.mainController,
    required this.memoController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: memoController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // メモ追加ボタン
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: MemoDialogを使用してメモ追加機能を実装
                  // showDialog(context: context, builder: (context) => MemoDialog(...));
                },
                icon: const Icon(Icons.add),
                label: const Text('メモを追加'),
              ),
              const SizedBox(height: 16),
              
              // メモ一覧
              if (memoController.memos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('服用メモがありません'),
                  ),
                )
              else
                ...memoController.memos.map((memo) {
                  final isChecked = memoController.medicationMemoStatus[memo.id] ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: CheckboxListTile(
                      title: Text(memo.name),
                      subtitle: Text(memo.type),
                      value: isChecked,
                      onChanged: (value) {
                        if (value == true) {
                          memoController.markAsTaken(memo, DateTime.now());
                        }
                      },
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: メモ編集機能を実装
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await memoController.deleteMemo(memo.id);
                              mainController.removeMemo(memo.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

