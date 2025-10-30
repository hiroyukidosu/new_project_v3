import 'package:flutter/material.dart';
import '../../constants/app_dimensions.dart';
import '../../models/medication_memo.dart';

/// 薬物カードウィジェット
class MedicationCard extends StatelessWidget {
  final MedicationMemo memo;
  final VoidCallback onTap;
  final bool isSelected;
  
  const MedicationCard({
    Key? key,
    required this.memo,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppDimensions.cardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        side: BorderSide(
          color: isSelected ? memo.color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                    color: memo.color,
                    size: AppDimensions.mediumIcon,
                  ),
                  const SizedBox(width: AppDimensions.mediumSpacing),
                  Expanded(
                    child: Text(
                      memo.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.largeText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: memo.color,
                      size: AppDimensions.mediumIcon,
                    ),
                ],
              ),
              if (memo.dosage.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  '用量: ${memo.dosage}',
                  style: const TextStyle(
                    fontSize: AppDimensions.mediumText,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  memo.notes,
                  style: const TextStyle(
                    fontSize: AppDimensions.mediumText,
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

