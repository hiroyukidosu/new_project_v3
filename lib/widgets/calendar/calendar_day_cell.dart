import 'package:flutter/material.dart';

/// カレンダーの日付セルウィジェット
class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool hasScheduledMemo;
  final bool isComplete;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const CalendarDayCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.hasScheduledMemo = false,
    this.isComplete = false,
    this.backgroundColor,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? (isSelected ? theme.colorScheme.primary.withOpacity(0.2) : null),
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            if (hasScheduledMemo || isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

