// lib/widgets/alarm_list_item.dart
// アラームリストアイテムのUI

import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../utils/alarm_helpers.dart';
import '../alarm/alarm_ui_builder.dart';

/// アラームリストアイテム
class AlarmListItem extends StatelessWidget {
  final Alarm alarm;
  final int index;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.index,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    alarm.enabled ? Icons.alarm : Icons.alarm_off,
                    color: alarm.enabled ? const Color(0xFF2196F3) : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alarm.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${alarm.time} (${AlarmHelpers.getRepeatDisplayText(alarm)})',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: alarm.enabled,
                    onChanged: onEnabledChanged,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  AlarmUIBuilder.buildAlarmTypeChip(alarm.alarmType.isEmpty ? 'sound' : alarm.alarmType),
                  if (alarm.volume != null)
                    AlarmUIBuilder.buildVolumeChip(alarm.volume),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: '編集',
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('アラーム削除'),
                          content: Text('「${alarm.name}」を削除しますか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('削除', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    tooltip: '削除',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

