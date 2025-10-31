// カレンダー関連機能のMixin
// home_page.dartからカレンダー関連の機能を分離

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/medication_memo.dart';
import '../../models/medication_info.dart';
import '../../services/trial_service.dart';
import '../../widgets/trial_limit_dialog.dart';

/// カレンダー関連機能のMixin
/// このmixinを使用するクラスは、必要な状態変数とメソッドを提供する必要があります
mixin HomePageCalendarMixin<T extends StatefulWidget> on State<T> {
  // 抽象ゲッター/セッター（実装クラスで提供する必要がある）
  DateTime? get selectedDay;
  DateTime get focusedDay;
  Set<DateTime> get selectedDates;
  List<MedicationMemo> get medicationMemos;
  Map<String, Map<String, MedicationInfo>> get medicationData;
  Map<String, Map<String, Map<int, bool>>> get weekdayMedicationDoseStatus;
  Map<String, Color> get dayColors;
  ValueNotifier<Map<String, Color>> get dayColorsNotifier;
  List<Map<String, dynamic>> get addedMedications;
  bool get memoSnapshotSaved;
  
  set selectedDay(DateTime? value);
  set focusedDay(DateTime value);
  set memoSnapshotSaved(bool value);
  void addSelectedDate(DateTime date);
  void removeSelectedDate(DateTime date);
  void clearAddedMedications();
  void setDayColor(String dateStr, Color? color);
  void setDayColorsNotifierValue(Map<String, Color> value);
  
  // 抽象メソッド（実装クラスで提供する必要がある）
  DateTime normalizeDate(DateTime date);
  Future<void> updateMedicineInputsForSelectedDate();
  Future<void> loadCurrentData();
  Future<void> saveDayColors();
  Future<void> saveSnapshotBeforeChange(String operationType);
  void showSnackBar(String message);
  
  // 日付選択処理
  Future<void> onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    try {
      // トライアル制限チェック（当日以外の選択時）
      final isExpired = await TrialService.isTrialExpired();
      final today = DateTime.now();
      final isToday = selectedDay.year == today.year && 
                      selectedDay.month == today.month && 
                      selectedDay.day == today.day;
      
      if (isExpired && !isToday) {
        showDialog(
          context: context,
          builder: (context) => TrialLimitDialog(featureName: 'カレンダー'),
        );
        return;
      }
      
      // 先にデータ準備
      final normalizedDay = normalizeDate(selectedDay);
      final wasSelected = selectedDates.contains(normalizedDay);
      
      // 1回のsetStateで全て更新
      setState(() {
        if (wasSelected) {
          removeSelectedDate(normalizedDay);
          this.selectedDay = null;
          clearAddedMedications();
        } else {
          addSelectedDate(normalizedDay);
          this.selectedDay = normalizedDay;
        }
        this.focusedDay = focusedDay;
      });
      
      // 非同期処理は外で実行
      if (!wasSelected && this.selectedDay != null) {
        await updateMedicineInputsForSelectedDate();
        await loadCurrentData();
      }
      
      // メモスナップショット保存フラグをリセット
      memoSnapshotSaved = false;
    } catch (e) {
      showSnackBar('日付の選択に失敗しました: $e');
    }
  }

  // カレンダースタイルを動的に生成（日付の色に基づく）
  CalendarStyle buildCalendarStyle() {
    return CalendarStyle(
      outsideDaysVisible: false,
      cellMargin: const EdgeInsets.all(2),
      cellPadding: const EdgeInsets.all(4),
      cellAlignment: Alignment.center,
      defaultTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      selectedTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      todayTextStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      weekendTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      defaultDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      selectedDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFff6b6b),
            Color(0xFFee5a24),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b6b).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      todayDecoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4ecdc4),
            Color(0xFF44a08d),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ecdc4).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      markersMaxCount: 1,
      markerDecoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  // カスタム日付装飾を取得
  BoxDecoration? getCustomDayDecoration(DateTime day) {
    final dateKey = DateFormat('yyyy-MM-dd').format(day);
    final customColor = dayColors[dateKey];
    
    if (customColor != null) {
      return BoxDecoration(
        color: customColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: customColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return null;
  }

  // カレンダーの日付セル（曜日マーク・チェックマーク表示）
  Widget buildCalendarDay(DateTime day, {bool isSelected = false, bool isToday = false}) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    // 服用メモで設定された曜日かチェック
    final hasScheduledMemo = medicationMemos.any((memo) => 
      memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)
    );
    
    // 服用記録が100%かチェック
    final stats = calculateDayMedicationStats(day);
    final total = stats['total'] ?? 0;
    final taken = stats['taken'] ?? 0;
    final isComplete = total > 0 && taken == total;
    
    // カスタム色取得
    final customColor = dayColors[dateStr];
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: customColor ?? 
          (isSelected 
            ? const Color(0xFFff6b6b)
            : isToday 
              ? const Color(0xFF4ecdc4)
              : Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
        border: hasScheduledMemo 
          ? Border.all(color: Colors.amber, width: 2)
          : null,
        boxShadow: isSelected || isToday
          ? [
              BoxShadow(
                color: (customColor ?? (isSelected ? const Color(0xFFff6b6b) : const Color(0xFF4ecdc4))).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
      ),
      child: Stack(
        children: [
          // 日付
          Center(
            child: Text(
              '${day.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          
          // 曜日マーク（左上）
          if (hasScheduledMemo)
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          
          // 完了チェックマーク（右下）
          if (isComplete)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.5),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 日別の服用統計を計算
  Map<String, int> calculateDayMedicationStats(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final weekday = day.weekday % 7;
    
    int totalMedications = 0;
    int takenMedications = 0;
    
    // 動的薬リストの統計
    if (medicationData.containsKey(dateStr)) {
      final dayData = medicationData[dateStr]!;
      totalMedications += dayData.length;
      takenMedications += dayData.values.where((info) => info.checked).length;
    }
    
    // 服用メモの統計
    for (final memo in medicationMemos) {
      if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
        totalMedications += memo.dosageFrequency;
        final checkedCount = getMedicationMemoCheckedCountForDate(memo.id, dateStr);
        takenMedications += checkedCount;
      }
    }
    
    return {'total': totalMedications, 'taken': takenMedications};
  }

  // 指定日のメモの服用済み回数を取得
  int getMedicationMemoCheckedCountForDate(String memoId, String dateStr) {
    final doseStatus = weekdayMedicationDoseStatus[dateStr]?[memoId];
    if (doseStatus == null) return 0;
    return doseStatus.values.where((isChecked) => isChecked).length;
  }

  // 日付の色を変更するメソッド
  void changeDayColor() {
    if (selectedDay == null) return;
    
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDay!);
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
    
    // 色選択ダイアログを表示
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'カレンダーの色を選択',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // 高さを制限
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(), // スクロール可能
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 13.7,
                childAspectRatio: 1,
              ),
              itemCount: colors.length + 1, // +1 for "色をリセット"
              itemBuilder: (context, index) {
                if (index == colors.length) {
                  // 色をリセットボタン（デフォルト色に戻す）
                  return GestureDetector(
                    onTap: () async {
                      // 変更前スナップショット
                      await saveSnapshotBeforeChange('カレンダー色リセット_$dateStr');
                      setState(() {
                        // デフォルト色（何も指定していない最初の色）に戻す
                        setDayColor(dateStr, null);
                        setDayColorsNotifierValue(Map<String, Color>.from(dayColors));
                      });
                      await saveDayColors(); // データ保存
                      Navigator.of(context).pop();
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
                final isSelected = dayColors[dateStr] == color;
                
                return GestureDetector(
                  onTap: () async {
                    // 変更前スナップショット
                    await saveSnapshotBeforeChange('カレンダー色変更_${dateStr}_$name');
                    setState(() {
                      setDayColor(dateStr, color);
                      setDayColorsNotifierValue(Map<String, Color>.from(dayColors));
                    });
                    await saveDayColors(); // データ保存
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
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
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 32,
                          )
                        else
                          const SizedBox(height: 32),
                        const SizedBox(height: 4),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );
  }

  // カレンダーの日付を更新
  Future<void> updateCalendarForSelectedDate() async {
    try {
      if (selectedDay != null) {
        // 選択された日付のデータを読み込み
        await updateMedicineInputsForSelectedDate();
        
        // メモを読み込み
        await loadMemoForSelectedDate();
        
        debugPrint('カレンダー日付更新完了: ${DateFormat('yyyy-MM-dd').format(selectedDay!)}');
      }
    } catch (e) {
      debugPrint('カレンダー日付更新エラー: $e');
    }
  }

  // 完全に作り直されたカレンダーイベント取得
  List<Widget> getEventsForDay(DateTime day) {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final weekday = day.weekday % 7;
      
      // 完全に作り直されたチェック
      bool hasMedications = false;
      bool allTaken = true;
      int takenCount = 0;
      int totalCount = 0;
      
      // 動的薬リストのチェック
      if (addedMedications.isNotEmpty) {
        hasMedications = true;
        totalCount += addedMedications.length;
        for (final medication in addedMedications) {
          if (medication['isChecked'] == true) {
            takenCount++;
          } else {
            allTaken = false;
          }
        }
      }
      
      // 服用メモのチェック
      for (final memo in medicationMemos) {
        if (memo.selectedWeekdays.isNotEmpty && memo.selectedWeekdays.contains(weekday)) {
          hasMedications = true;
          totalCount++;
          // 状態チェックは実装クラスで行う
        }
      }
      
      // 完全に作り直されたマーク表示（すべてのマークを削除）
      // 赤丸を含むすべてのマークを削除
      return [];
    } catch (e) {
      return [];
    }
  }

  // 抽象メソッド（実装クラスで提供する必要がある）
  Future<void> loadMemoForSelectedDate();
}

