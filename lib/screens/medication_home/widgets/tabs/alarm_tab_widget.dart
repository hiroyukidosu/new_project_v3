// lib/screens/medication_home/widgets/tabs/alarm_tab_widget.dart

import 'package:flutter/material.dart';
import '../../../controllers/medication_home_controller.dart';

/// アラームタブウィジェット
class AlarmTabWidget extends StatelessWidget {
  final MedicationHomeController mainController;

  const AlarmTabWidget({
    super.key,
    required this.mainController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mainController,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'アラーム設定',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (mainController.alarmList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('アラームが設定されていません'),
                  ),
                )
              else
                ...mainController.alarmList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final alarm = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(alarm['name']?.toString() ?? 'アラーム'),
                      subtitle: Text(alarm['time']?.toString() ?? '00:00'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // TODO: アラーム削除機能を実装
                        },
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: アラーム追加機能を実装
                },
                icon: const Icon(Icons.add),
                label: const Text('アラームを追加'),
              ),
            ],
          ),
        );
      },
    );
  }
}

