// Dart core imports
import 'dart:async';

// Flutter core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Local imports
import '../models/medication_memo.dart';
import '../utils/constants.dart';

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
        _memoFocusNode.requestFocus();
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.dialogBorderRadius),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * AppDimensions.dialogMaxHeight,
          minHeight: MediaQuery.of(context).size.height * AppDimensions.dialogMinHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Container(
              padding: AppDimensions.dialogPadding,
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.dialogBorderRadius),
                  topRight: Radius.circular(AppDimensions.dialogBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.initialMemo != null ? Icons.edit : Icons.add,
                    color: _selectedColor,
                    size: AppDimensions.largeIcon,
                  ),
                  const SizedBox(width: AppDimensions.mediumSpacing),
                  Expanded(
                    child: Text(
                      widget.initialMemo != null ? 'メモを編集' : '新しいメモを追加',
                      style: TextStyle(
                        fontSize: AppDimensions.titleText,
                        fontWeight: FontWeight.bold,
                        color: _selectedColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: AppDimensions.dialogPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名前フィールド
                    _buildNameField(),
                    const SizedBox(height: AppDimensions.largeSpacing),
                    
                    // タイプ選択
                    _buildTypeSelector(),
                    const SizedBox(height: AppDimensions.largeSpacing),
                    
                    // 用量フィールド
                    _buildDosageField(),
                    const SizedBox(height: AppDimensions.largeSpacing),
                    
                    // 服用頻度
                    _buildDosageFrequency(),
                    const SizedBox(height: AppDimensions.largeSpacing),
                    
                    // 曜日選択
                    _buildWeekdaySelector(),
                    const SizedBox(height: AppDimensions.largeSpacing),
                    
                    // 色選択
                    _buildColorSelector(),
                    const SizedBox(height: AppDimensions.largeSpacing),
                    
                    // メモフィールド
                    _buildNotesField(),
                  ],
                ),
              ),
            ),
            // ボタンエリア
            Container(
              padding: AppDimensions.dialogPadding,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.dialogBorderRadius),
                  bottomRight: Radius.circular(AppDimensions.dialogBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.mediumSpacing),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveMemo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(widget.initialMemo != null ? '更新' : '追加'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '名前',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        TextField(
          controller: _nameController,
          focusNode: _memoFocusNode,
          decoration: const InputDecoration(
            hintText: '薬やサプリメントの名前を入力',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _isNameFocused = value.isNotEmpty;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タイプ',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('薬品'),
                value: '薬品',
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('サプリメント'),
                value: 'サプリメント',
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDosageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '用量',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        TextField(
          controller: _dosageController,
          decoration: const InputDecoration(
            hintText: '例: 1錠、500mg',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _isDosageFocused = value.isNotEmpty;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildDosageFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '服用回数',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Row(
          children: List.generate(6, (index) {
            final frequency = index + 1;
            return Expanded(
              child: RadioListTile<int>(
                title: Text('${frequency}回'),
                value: frequency,
                groupValue: _dosageFrequency,
                onChanged: (value) {
                  setState(() {
                    _dosageFrequency = value!;
                  });
                },
              ),
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildWeekdaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '服用曜日',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Wrap(
          spacing: AppDimensions.smallSpacing,
          runSpacing: AppDimensions.smallSpacing,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
                  border: Border.all(
                    color: isSelected ? _selectedColor : Colors.grey.withOpacity(0.3),
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
        ),
      ],
    );
  }
  
  Widget _buildColorSelector() {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '色',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Wrap(
          spacing: AppDimensions.smallSpacing,
          children: colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.transparent,
                    width: 2,
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
        ),
      ],
    );
  }
  
  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'メモ',
          style: TextStyle(
            fontSize: AppDimensions.mediumText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '追加のメモがあれば入力してください',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _isNotesFocused = value.isNotEmpty;
            });
          },
        ),
      ],
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
      color: _selectedColor,
      selectedWeekdays: _selectedWeekdays,
      dosageFrequency: _dosageFrequency,
    );
    
    widget.onMemoAdded(memo);
    Navigator.of(context).pop();
  }
}
