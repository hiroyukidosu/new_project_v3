import 'package:flutter/material.dart';
import '../models/medication_memo.dart';

class _MemoDialog extends StatefulWidget {
  final Function(MedicationMemo) onMemoAdded;
  final MedicationMemo? initialMemo;
  final List<MedicationMemo> existingMemos;
  const _MemoDialog({
    required this.onMemoAdded,
    this.initialMemo,
    required this.existingMemos,
  });
  @override
  State<_MemoDialog> createState() => _MemoDialogState();
}

class _MemoDialogState extends State<_MemoDialog> {
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
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.height < 600 ? 8 : 12,
                                vertical: MediaQuery.of(context).size.height < 600 ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedWeekdays.length == 7 ? Colors.blue : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedWeekdays.length == 7 ? Colors.blue : Colors.grey[400]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: MediaQuery.of(context).size.height < 600 ? 14 : 16,
                                    color: _selectedWeekdays.length == 7 ? Colors.white : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '毎日',
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedWeekdays.length == 7 ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 4 : 6),
                          // 曜日選択ボタン - コンパクト化
                          Wrap(
                            spacing: MediaQuery.of(context).size.height < 600 ? 2 : 4,
                            runSpacing: MediaQuery.of(context).size.height < 600 ? 2 : 4,
                            children: List.generate(7, (index) {
                              final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
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
                                  width: MediaQuery.of(context).size.height < 600 ? 28 : 32,
                                  height: MediaQuery.of(context).size.height < 600 ? 28 : 32,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey[400]!,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      weekdays[index],
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.height < 600 ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 6 : 8),
                          // 服用回数選択 - コンパクト化
                          Text(
                            '服用回数',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 2 : 4),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _dosageFrequency.toDouble(),
                                  min: 1,
                                  max: 6,
                                  divisions: 5,
                                  label: '$_dosageFrequency回',
                                  onChanged: (value) {
                                    setState(() {
                                      _dosageFrequency = value.round();
                                    });
                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: MediaQuery.of(context).size.height < 600 ? 6 : 8,
                                  vertical: MediaQuery.of(context).size.height < 600 ? 2 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$_dosageFrequency回',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 6 : 8),
                          // タイプ選択 - コンパクト化
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedType = '薬品';
                                      _selectedColor = Colors.blue;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: MediaQuery.of(context).size.height < 600 ? 8 : 12,
                                      vertical: MediaQuery.of(context).size.height < 600 ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedType == '薬品' ? Colors.blue : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedType == '薬品' ? Colors.blue : Colors.grey[400]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.medication,
                                          size: MediaQuery.of(context).size.height < 600 ? 14 : 16,
                                          color: _selectedType == '薬品' ? Colors.white : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '薬品',
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedType == '薬品' ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'サプリメント';
                                      _selectedColor = Colors.green;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: MediaQuery.of(context).size.height < 600 ? 8 : 12,
                                      vertical: MediaQuery.of(context).size.height < 600 ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedType == 'サプリメント' ? Colors.green : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedType == 'サプリメント' ? Colors.green : Colors.grey[400]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.eco,
                                          size: MediaQuery.of(context).size.height < 600 ? 14 : 16,
                                          color: _selectedType == 'サプリメント' ? Colors.white : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'サプリメント',
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.height < 600 ? 12 : 14,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedType == 'サプリメント' ? Colors.white : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 6 : 8),
                          // 用量フィールド - コンパクト化
                          TextField(
                            controller: _dosageController,
                            decoration: const InputDecoration(
                              labelText: '用量',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.straighten, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onTap: () {
                              setState(() {
                                _isDosageFocused = true;
                                _isNameFocused = false;
                                _isNotesFocused = false;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _isDosageFocused = value.isNotEmpty;
                              });
                            },
                            onSubmitted: (value) {
                              setState(() {
                                _isDosageFocused = false;
                              });
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 6 : 8),
                          // メモフィールド - コンパクト化
                          TextField(
                            controller: _notesController,
                            focusNode: _memoFocusNode,
                            decoration: const InputDecoration(
                              labelText: 'メモ',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            maxLines: 3,
                            onTap: () {
                              setState(() {
                                _isNotesFocused = true;
                                _isNameFocused = false;
                                _isDosageFocused = false;
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _isNotesFocused = value.isNotEmpty;
                              });
                            },
                            onSubmitted: (value) {
                              setState(() {
                                _isNotesFocused = false;
                              });
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12),
                          // ボタンエリア - コンパクト化
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: MediaQuery.of(context).size.height < 600 ? 8 : 12,
                                    ),
                                  ),
                                  child: const Text('キャンセル'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveMemo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedColor,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: MediaQuery.of(context).size.height < 600 ? 8 : 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    widget.initialMemo != null ? '更新' : '追加',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMemo() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名前を入力してください')),
      );
      return;
    }

    final memo = MedicationMemo(
      id: widget.initialMemo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
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
    Navigator.of(context).pop();
  }
}