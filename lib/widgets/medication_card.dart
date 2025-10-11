import 'package:flutter/material.dart';
import '../models/medication_memo.dart';
import '../utils/app_dimensions.dart';

// 服用メモカードウィジェット（UI分離）
class MedicationCard extends StatelessWidget {
  final MedicationMemo memo;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isChecked;

  const MedicationCard({
    super.key,
    required this.memo,
    required this.onTap,
    this.isSelected = false,
    this.isChecked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppDimensions.cardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.mediumSpacing),
              _buildContent(),
              if (memo.selectedDays.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.mediumSpacing),
                _buildSelectedDays(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
          size: AppDimensions.largeIcon,
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
        const SizedBox(width: AppDimensions.mediumSpacing),
        Expanded(
          child: Text(
            memo.name,
            style: TextStyle(
              fontSize: AppDimensions.largeText,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
        ),
        if (isChecked)
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: AppDimensions.largeIcon,
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '用量: ${memo.dosage}',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Text(
          '種類: ${memo.type}',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDays() {
    final dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    
    return Wrap(
      spacing: AppDimensions.smallSpacing,
      children: memo.selectedDays.map((day) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.smallSpacing,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Text(
            dayNames[day],
            style: TextStyle(
              fontSize: AppDimensions.smallText,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 服用メモチェックボックスウィジェット
class MedicationMemoCheckbox extends StatelessWidget {
  final MedicationMemo memo;
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const MedicationMemoCheckbox({
    super.key,
    required this.memo,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppDimensions.cardMargin,
      child: CheckboxListTile(
        title: Text(
          memo.name,
          style: TextStyle(
            fontSize: AppDimensions.largeText,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${memo.dosage} - ${memo.type}',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            color: Colors.grey[600],
          ),
        ),
        value: isChecked,
        onChanged: (value) => onChanged(value ?? false),
        secondary: Icon(
          memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
          size: AppDimensions.largeIcon,
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
