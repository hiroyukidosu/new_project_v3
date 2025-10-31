// MemoDialogウィジェット
// メモ追加・編集ダイアログ - 服用メモの追加と編集を行います

import 'package:flutter/material.dart';
import '../models/medication_memo.dart';

/// メモ追加・編集ダイアログ
/// 服用メモの追加と編集を行うダイアログ
class MemoDialog extends StatefulWidget {
  final Function(MedicationMemo) onMemoAdded;
  final MedicationMemo? initialMemo;
  final List<MedicationMemo> existingMemos;
  const MemoDialog({
    super.key,
    required this.onMemoAdded,
    this.initialMemo,
    required this.existingMemos,
  });
  @override
  State<MemoDialog> createState() => _MemoDialogState();
  
  /// ダイアログを表示するヘルパーメソッド
  static void show({
    required BuildContext context,
    required Function(MedicationMemo) onMemoAdded,
    MedicationMemo? initialMemo,
    required List<MedicationMemo> existingMemos,
  }) {
    showDialog(
      context: context,
      builder: (context) => MemoDialog(
        onMemoAdded: onMemoAdded,
        initialMemo: initialMemo,
        existingMemos: existingMemos,
      ),
    );
  }
}

class _MemoDialogState extends State<MemoDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = '薬品';
  Color _selectedColor = Colors.blue;
  bool _isDosageFocused = false;
  bool _isNotesFocused = false;
  bool _isNameFocused = false;
  List<int> _selectedWeekdays = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _memoFocusNode = FocusNode();
  int _dosageFrequency = 1; // 服用回数（1〜6回）
  
  // 空タイトル時の自動連番生成（ダイアログ内専用）
  String _generateDefaultTitle(List<String> existingTitles) {
    const int maxCount = 999;
    int count = 1;
    while (count <= maxCount && existingTitles.contains('メモ$count')) {
      count++;
    }
    return 'メモ$count';
  }
  
  @override
  void initState() {
    super.initState();
    if (widget.initialMemo != null) {
      _nameController.text = widget.initialMemo!.name;
      _dosageController.text = widget.initialMemo!.dosage;
      _notesController.text = widget.initialMemo!.notes;
      _selectedType = widget.initialMemo!.type;
      _selectedColor = widget.initialMemo!.color;
      _selectedWeekdays = List.from(widget.initialMemo!.selectedWeekdays);
      _dosageFrequency = widget.initialMemo!.dosageFrequency ?? 1;
      
      // メモ編集モードの場合、自動的にメモフィールドにフォーカス（スクロールは削除）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialMemo != null) {
          _memoFocusNode.requestFocus();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    // メモ編集と新規追加を統一した画面 - 上部のスペースを最大限活用
    return AnimatedContainer(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.02, // 左右の余白を大幅削減
          vertical: MediaQuery.of(context).size.height * 0.02, // 上下の余白を大幅削減
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // 角丸を削減
        ),
        child: Stack(
          children: [
            Container(
          constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.95, // 画面の95%に拡大
                maxWidth: MediaQuery.of(context).size.width * 0.95,   // 画面の95%に拡大
                minWidth: 280,   // 最小幅を280に設定
              ),
              width: MediaQuery.of(context).size.width * 0.95, // 明示的な幅を設定
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(), // 常にスクロール可能
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 400 ? 4 : 8, // 小さい画面では余白を大幅削減
              vertical: MediaQuery.of(context).size.height < 600 ? 2 : 4, // 小さい画面では余白を大幅削減
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max, // 最大サイズで配置
              children: [
                // ヘッダー（入力時は非表示） - コンパクト化
                if (!_isNameFocused && !_isDosageFocused && !_isNotesFocused) ...[
                Container(
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.height < 600 ? 4 : 6, // パディングを大幅削減
                  ),
                  decoration: BoxDecoration(
                      color: _selectedType == 'サプリメント' ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12), // 角丸を削減
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          _selectedType == 'サプリメント' ? Icons.eco : Icons.medication,
                          color: _selectedType == 'サプリメント' ? Colors.green : Colors.blue,
                        size: 20, // アイコンサイズを削減
                      ),
                      const SizedBox(width: 8), // 間隔を削減
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                widget.initialMemo != null ? 'メモ編集' : 'メモ追加',
                              style: const TextStyle(
                                fontSize: 16, // フォントサイズを削減
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2), // 間隔を削減
                            Text(
                                widget.initialMemo != null ? 'メモを編集します' : '新しいメモを追加します',
                              style: TextStyle(
                                fontSize: 12, // フォントサイズを削減
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                      ),
                    ),
                  ],
                ),
              ),
              ],
              // コンテンツ - パディングを大幅削減
              Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.height < 600 ? 8 : 12), // パディングを大幅削減
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名前（一番上に配置、常に表示） - コンパクト化
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: '名前',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label, size: 20), // アイコンサイズを削減
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                        ),
                      onTap: () {
                        setState(() {
                          _isNameFocused = true;
                          _isDosageFocused = false;
                          _isNotesFocused = false;
                        });
                      },
                      onChanged: (value) {
                          setState(() {
                          _isNameFocused = value.isNotEmpty;
                          });
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isNameFocused = false;
                        });
                      },
                    ),
                    // 曜日選択を常に表示 - 間隔を削減
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を大幅削減
                    // 服用スケジュール（曜日選択） - コンパクト化
                    Text(
                      '服用スケジュール',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14, // フォントサイズを削減
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 2 : 4), // 間隔を大幅削減
                    // 毎日オプション - コンパクト化
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedWeekdays.length == 7) {
                            _selectedWeekdays.clear();
                          } else {
                            _selectedWeekdays = [0, 1, 2, 3, 4, 5, 6];
                          }
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        height: 44, // 高さを削減
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // パディングを削減
                        decoration: BoxDecoration(
                          color: _selectedWeekdays.length == 7 ? _selectedColor : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8), // 角丸を削減
                          border: Border.all(
                            color: _selectedWeekdays.length == 7 ? _selectedColor : Colors.grey.withOpacity(0.3),
                            width: 1.5, // ボーダー幅を削減
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: _selectedWeekdays.length == 7 ? Colors.white : Colors.grey[600],
                              size: 18, // アイコンサイズを削減
                            ),
                            const SizedBox(width: 8), // 間隔を削減
                            Expanded(
                              child: Text(
                              '毎日',
                              style: TextStyle(
                                fontSize: 14, // フォントサイズを削減
                                fontWeight: FontWeight.bold,
                                color: _selectedWeekdays.length == 7 ? Colors.white : Colors.grey[700],
                              ),
                            ),
                            ),
                            const SizedBox(width: 4), // 間隔を削減
                            if (_selectedWeekdays.length == 7)
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16, // アイコンサイズを削減
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を削減
                    // 曜日選択 - コンパクト化
                    Wrap(
                      spacing: 6, // 間隔を削減
                      runSpacing: 6,
                      children: [
                        '日', '月', '火', '水', '木', '金', '土'
                      ].asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final isSelected = _selectedWeekdays.contains(index);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedWeekdays.remove(index);
                              } else {
                                _selectedWeekdays.add(index);
                              }
                            });
                          },
                          child: Container(
                            width: 36, // サイズを削減
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(18), // 角丸を調整
                              border: Border.all(
                                color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
                                width: 1.5, // ボーダー幅を削減
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12, // フォントサイズを削減
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // 用量とメモ選択時は他の要素を非表示 - コンパクト化
                    if (!_isDosageFocused && !_isNotesFocused) ...[
                      SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                      // 種類選択 - コンパクト化
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: '種類',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category, size: 20), // アイコンサイズを削減
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                        ),
                        items: const [
                          DropdownMenuItem(value: '薬品', child: Text('💊 薬品')),
                          DropdownMenuItem(value: 'サプリメント', child: Text('🌿 サプリメント')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                    ],
                    // 服用回数 - コンパクト化
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                    const Text(
                      '服用回数',
                      style: TextStyle(
                        fontSize: 14, // フォントサイズを削減
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4), // 間隔を削減
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8), // パディングを削減
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(6), // 角丸を削減
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _dosageFrequency,
                          isExpanded: true,
                          items: List.generate(6, (index) => index + 1).map((frequency) {
                            return DropdownMenuItem<int>(
                              value: frequency,
                              child: Text('$frequency回', style: const TextStyle(fontSize: 14)), // フォントサイズを削減
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _dosageFrequency = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (_dosageFrequency >= 6) ...[
                      const SizedBox(height: 6), // 間隔を削減
                        Container(
                          padding: const EdgeInsets.all(8), // パディングを削減
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6), // 角丸を削減
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange, size: 16), // アイコンサイズを削減
                              const SizedBox(width: 6), // 間隔を削減
                              const Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '服用回数が多いため、',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12, // フォントサイズを削減
                                      ),
                                    ),
                                    Text(
                                      '医師の指示に従ってください',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12, // フォントサイズを削減
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    // 用量 - コンパクト化
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を削減
                    TextField(
                      key: const ValueKey('dosage_field'),
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: '用量',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.straighten, size: 20), // アイコンサイズを削減
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                      ),
                      onTap: () {
                        setState(() {
                          _isDosageFocused = true;
                          _isNameFocused = false;
                          _isNotesFocused = false;
                        });
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _isDosageFocused = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isDosageFocused = false;
                        });
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6), // 間隔を削減
                    // メモ - コンパクト化
                    TextField(
                      key: const ValueKey('notes_field'),
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'メモ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note, size: 20), // アイコンサイズを削減
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // パディングを削減
                      ),
                      maxLines: MediaQuery.of(context).size.height < 600 ? 2 : 3, // 小さい画面では行数を削減
                      onTap: () {
                        setState(() {
                          _isNotesFocused = true;
                          _isNameFocused = false;
                          _isDosageFocused = false;
                        });
                      },
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _isNotesFocused = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        setState(() {
                          _isNotesFocused = false;
                        });
                      },
                    ),
                      // メモ入力時の決定・完了ボタン - コンパクト化
                      if (_isNotesFocused) ...[
                        const SizedBox(height: 8), // 間隔を削減
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isNotesFocused = false;
                                });
                              },
                              icon: const Icon(Icons.check, size: 16), // アイコンサイズを削減
                              label: const Text('決定', style: TextStyle(fontSize: 12)), // フォントサイズを削減
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // パディングを削減
                            ),
                            ),
                            ),
                            const SizedBox(width: 8), // 間隔を削減
                            Expanded(
                              child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isNotesFocused = false;
                                });
                              },
                              icon: const Icon(Icons.done, size: 16), // アイコンサイズを削減
                              label: const Text('完了', style: TextStyle(fontSize: 12)), // フォントサイズを削減
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // パディングを削減
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // 色選択も用量とメモ選択時は非表示 - コンパクト化
                    if (!_isDosageFocused && !_isNotesFocused) ...[
                      SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12), // 間隔を削減
                        // 色選択 - コンパクト化
                      const Text(
                        '色',
                        style: TextStyle(
                          fontSize: 14, // フォントサイズを削減
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8), // 間隔を削減
                      Wrap(
                        spacing: 8, // 間隔を削減
                        runSpacing: 8,
                        children: [
                          Colors.blue,
                          Colors.red,
                          Colors.green,
                          Colors.orange,
                          Colors.purple,
                          Colors.teal,
                          Colors.pink,
                          Colors.indigo,
                        ].map((color) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40, // サイズを削減
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: _selectedColor == color
                                  ? Border.all(color: Colors.black, width: 2) // ボーダー幅を削減
                                  : Border.all(color: Colors.grey.withOpacity(0.3)),
                              boxShadow: _selectedColor == color
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.3),
                                        blurRadius: 6, // ブラーを削減
                                        spreadRadius: 1, // スプレッドを削減
                                      ),
                                    ]
                                  : null,
                            ),
                            child: _selectedColor == color
                                ? const Icon(Icons.check, color: Colors.white, size: 20) // アイコンサイズを削減
                                : null,
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            // フッター（入力時は非表示） - コンパクト化
            if (!_isNameFocused && !_isDosageFocused && !_isNotesFocused) ...[
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.height < 600 ? 4 : 8, // パディングを削減
                    right: MediaQuery.of(context).size.height < 600 ? 4 : 8,
                    top: MediaQuery.of(context).size.height < 600 ? 4 : 8,
                    bottom: MediaQuery.of(context).size.height < 600 ? 4 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12), // 角丸を削減
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル', style: TextStyle(fontSize: 12)), // フォントサイズを削減
                      ),
                      ),
                      const SizedBox(width: 8), // 間隔を削減
                      Flexible(
                        child: ElevatedButton(
                        onPressed: () {
                          try {
                            String finalName = _nameController.text.trim();
                            if (finalName.isEmpty) {
                              final existingTitles = widget.existingMemos
                                  .where((m) => m.id != widget.initialMemo?.id)
                                  .map((m) => m.name)
                                  .toList();
                              finalName = _generateDefaultTitle(existingTitles);
                            }
                            final memo = MedicationMemo(
                              id: widget.initialMemo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: finalName,
                              type: _selectedType,
                                dosage: _dosageController.text.trim(),
                                notes: _notesController.text.trim(),
                              createdAt: widget.initialMemo?.createdAt ?? DateTime.now(),
                              lastTaken: widget.initialMemo?.lastTaken,
                              color: _selectedColor,
                                selectedWeekdays: _selectedWeekdays,
                                dosageFrequency: _dosageFrequency,
                            );
                            widget.onMemoAdded(memo);
                            Navigator.pop(context);
                            } catch (e) {
                                    // エラーハンドリング
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedType == 'サプリメント' ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // パディングを削減
                        ),
                        child: Text(widget.initialMemo != null ? '更新' : '追加', style: const TextStyle(fontSize: 12)), // フォントサイズを削減
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
            ),
            // 右上端に×ボタンを配置 - コンパクト化
            Positioned(
              top: 4, // 位置を調整
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20), // アイコンサイズを削減
                onPressed: () => Navigator.pop(context),
                tooltip: '閉じる',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(4), // パディングを削減
                ),
              ),
            ),
          ],
      ),
      ),
    );
  }

  // 色選択ダイアログ
  void _showColorPicker() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色を選択'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  // 曜日チップウィジェット
  Widget _buildWeekdayChip(String label, int weekday) {
    final isSelected = weekday == -1 
        ? _selectedWeekdays.length == 7 
        : _selectedWeekdays.contains(weekday);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (weekday == -1) {
            // 毎日を選択
            if (_selectedWeekdays.length == 7) {
              _selectedWeekdays.clear();
            } else {
              _selectedWeekdays = [0, 1, 2, 3, 4, 5, 6];
            }
          } else {
            // 個別の曜日を選択
            if (_selectedWeekdays.contains(weekday)) {
              _selectedWeekdays.remove(weekday);
            } else {
              _selectedWeekdays.add(weekday);
            }
          }
        });
      },
      child: Container(
        height: 32, // 明示的な高さを設定
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  // 警告ダイアログを表示するメソッド
  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('注意'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '服用回数が多いため、',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              '医師の指示に従ってください',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
    
    // 3秒後に自動で閉じる
    Future.delayed(const Duration(seconds: 3), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

}
