import 'package:flutter/material.dart';
import '../utils/app_dimensions.dart';

// 共通コンポーネント（コード重複削減）
class CommonComponents {
  // 色選択ウィジェット（統一版）
  static Widget buildColorPicker({
    required Color selectedColor,
    required ValueChanged<Color> onColorChanged,
    List<Color>? colors,
  }) {
    final defaultColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    final colorList = colors ?? defaultColors;
    
    return Wrap(
      spacing: AppDimensions.mediumSpacing,
      runSpacing: AppDimensions.mediumSpacing,
      children: colorList.map((color) {
        final isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.shade300,
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
  
  // 色選択ダイアログ（統一版）
  static Future<Color?> showColorPickerDialog({
    required BuildContext context,
    required Color currentColor,
    List<Color>? colors,
  }) {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色を選択'),
        content: StatefulBuilder(
          builder: (context, setState) {
            Color selectedColor = currentColor;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildColorPicker(
                  selectedColor: selectedColor,
                  onColorChanged: (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  colors: colors,
                ),
                const SizedBox(height: AppDimensions.mediumSpacing),
                Text(
                  '選択された色',
                  style: TextStyle(
                    fontSize: AppDimensions.mediumText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, selectedColor),
            child: const Text('選択'),
          ),
        ],
      ),
    );
  }
  
  // 曜日選択ウィジェット（統一版）
  static Widget buildWeekdaySelector({
    required List<int> selectedDays,
    required ValueChanged<List<int>> onChanged,
    List<String>? dayNames,
  }) {
    final defaultDayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final names = dayNames ?? defaultDayNames;
    
    return Wrap(
      spacing: AppDimensions.smallSpacing,
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
              color: isSelected ? Colors.blue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppDimensions.smallBorderRadius),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                names[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: AppDimensions.mediumText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
  
  // 時間選択ウィジェット（統一版）
  static Widget buildTimePicker({
    required TimeOfDay selectedTime,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (time != null) {
          onChanged(time);
        }
      },
      child: Container(
        padding: AppDimensions.standardPadding,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, size: 20),
            const SizedBox(width: AppDimensions.smallSpacing),
            Text(
              selectedTime.format(context),
              style: TextStyle(
                fontSize: AppDimensions.largeText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
  
  // ローディングオーバーレイ（統一版）
  static Widget buildLoadingOverlay({
    required bool isLoading,
    String? message,
  }) {
    if (!isLoading) return const SizedBox.shrink();
    
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          child: Padding(
            padding: AppDimensions.largePadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: AppDimensions.mediumSpacing),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: AppDimensions.mediumText,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // エラーメッセージ表示（統一版）
  static Widget buildErrorMessage({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: AppDimensions.standardPadding,
      margin: AppDimensions.cardMargin,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: AppDimensions.smallSpacing),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: AppDimensions.mediumText,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppDimensions.mediumSpacing),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('再試行'),
            ),
          ],
        ],
      ),
    );
  }
  
  // 成功メッセージ表示（統一版）
  static Widget buildSuccessMessage({
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return Container(
      padding: AppDimensions.standardPadding,
      margin: AppDimensions.cardMargin,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600),
          const SizedBox(width: AppDimensions.smallSpacing),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.green.shade800,
                fontSize: AppDimensions.mediumText,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 確認ダイアログ（統一版）
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '確認',
    String cancelText = 'キャンセル',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
  
  // 入力フィールド（統一版）
  static Widget buildInputField({
    required String label,
    String? hint,
    TextEditingController? controller,
    int? maxLines,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black87 : Colors.grey,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.standardBorderRadius),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          maxLines: maxLines ?? 1,
          keyboardType: keyboardType,
          onChanged: onChanged,
          enabled: enabled,
          validator: validator,
        ),
      ],
    );
  }
}
