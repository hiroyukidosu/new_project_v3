import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 服用記録カードウィジェット
class MedicationRecordCard extends StatelessWidget {
  final Map<String, dynamic> medication;
  final VoidCallback onCheck;
  final VoidCallback onDelete;
  final bool isChecked;
  
  const MedicationRecordCard({
    super.key,
    required this.medication,
    required this.onCheck,
    required this.onDelete,
    this.isChecked = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    final medicationName = medication['name'] as String? ?? '';
    final medicationType = medication['type'] as String? ?? '';
    final takenTime = medication['takenTime'] as String?;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Checkbox(
          value: isChecked,
          onChanged: (_) => onCheck(),
        ),
        title: Text(
          medicationName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isChecked ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medicationType.isNotEmpty)
              Text('種類: $medicationType'),
            if (takenTime != null)
              Text('服用時間: $takenTime'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          color: theme.colorScheme.error,
        ),
        onTap: onCheck,
      ),
    );
  }
}

