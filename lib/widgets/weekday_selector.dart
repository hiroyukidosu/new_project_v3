import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 曜日選択ウィジェット
class WeekdaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;
  
  const WeekdaySelector({
    Key? key,
    required this.selectedDays,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    
    return Wrap(
      spacing: AppDimensions.smallSpacing,
      runSpacing: AppDimensions.smallSpacing,
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
              borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
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
                  fontSize: AppDimensions.mediumText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

