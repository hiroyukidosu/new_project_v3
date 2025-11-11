// lib/screens/home/widgets/day_color_picker_dialog.dart

import 'package:flutter/material.dart';

/// 日付色選択ダイアログウィジェット
class DayColorPickerDialog extends StatelessWidget {
  final String dateKey;
  final Function(String, Color) onColorSelected;
  final Function(String) onColorRemoved;

  const DayColorPickerDialog({
    super.key,
    required this.dateKey,
    required this.onColorSelected,
    required this.onColorRemoved,
  });

  static void show(
    BuildContext context, {
    required String dateKey,
    required Function(String, Color) onColorSelected,
    required Function(String) onColorRemoved,
  }) {
    showDialog(
      context: context,
      builder: (context) => DayColorPickerDialog(
        dateKey: dateKey,
        onColorSelected: onColorSelected,
        onColorRemoved: onColorRemoved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      {'color': const Color(0xFFff6b6b), 'name': '赤'},
      {'color': const Color(0xFF4ecdc4), 'name': '青緑'},
      {'color': const Color(0xFF45b7d1), 'name': '青'},
      {'color': const Color(0xFFf9ca24), 'name': '黄色'},
      {'color': const Color(0xFFf0932b), 'name': 'オレンジ'},
      {'color': const Color(0xFFeb4d4b), 'name': 'ピンク'},
      {'color': const Color(0xFF6c5ce7), 'name': '紫'},
      {'color': const Color(0xFFa29bfe), 'name': '薄紫'},
      {'color': const Color(0xFF00d2d3), 'name': 'ターコイズ'},
      {'color': const Color(0xFF1e3799), 'name': '濃紺'},
      {'color': const Color(0xFFe55039), 'name': 'トマト'},
      {'color': const Color(0xFF2ecc71), 'name': 'エメラルド'},
    ];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'カレンダーの色を選択',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 色選択グリッド
            SizedBox(
              width: double.maxFinite,
              height: 300,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 13.7,
                  childAspectRatio: 1,
                ),
                itemCount: colors.length + 1,
                itemBuilder: (context, index) {
                  if (index == colors.length) {
                    return GestureDetector(
                      onTap: () {
                        onColorRemoved(dateKey);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.clear, color: Colors.grey, size: 32),
                            SizedBox(height: 4),
                            Text(
                              'リセット',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final colorData = colors[index];
                  final color = colorData['color'] as Color;
                  final name = colorData['name'] as String;

                  return GestureDetector(
                    onTap: () {
                      onColorSelected(dateKey, color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // キャンセルボタン
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

