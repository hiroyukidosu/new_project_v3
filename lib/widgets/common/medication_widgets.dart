import 'package:flutter/material.dart';
import '../../models/medication_memo.dart';

/// メディケーションカードウィジェット
/// 薬の情報を表示するカード
class MedicationCard extends StatelessWidget {
  final MedicationMemo memo;
  final VoidCallback onTap;
  final bool isSelected;

  const MedicationCard({
    super.key,
    required this.memo,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? memo.color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                    color: memo.color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      memo.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: memo.color,
                      size: 24,
                    ),
                ],
              ),
              if (memo.dosage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '用量: ${memo.dosage}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  memo.notes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 曜日選択ウィジェット
/// 服用曜日を選択するウィジェット
class WeekdaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const WeekdaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            final newDays = List<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(index);
            } else {
              newDays.add(index);
            }
            onChanged(newDays);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// カラー選択ウィジェット
/// 色を選択するウィジェット
class ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
  });

  static const List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

/// 服用回数選択ウィジェット
/// 1日あたりの服用回数を選択するウィジェット
class DosageFrequencySelector extends StatelessWidget {
  final int selectedFrequency;
  final ValueChanged<int> onFrequencyChanged;

  const DosageFrequencySelector({
    super.key,
    required this.selectedFrequency,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: selectedFrequency,
      onChanged: (value) {
        if (value != null) {
          onFrequencyChanged(value);
        }
      },
      items: List.generate(6, (index) => index + 1).map((frequency) {
        return DropdownMenuItem<int>(
          value: frequency,
          child: Text('$frequency回'),
        );
      }).toList(),
    );
  }
}
