// lib/screens/home/widgets/day_memo_field_widget.dart
// プロフェッショナルなデザインの日付別メモフィールドウィジェット

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 日付別メモフィールドウィジェット（プロフェッショナルデザイン）
class DayMemoFieldWidget extends StatefulWidget {
  final DateTime? selectedDay;
  final String initialMemoText;
  final ValueNotifier<String> memoTextNotifier;
  final bool isMemoFocused;
  final Function(String) onMemoChanged;
  final VoidCallback onMemoSaved;
  final VoidCallback onMemoCleared;
  final VoidCallback onMemoFocused;
  final VoidCallback onMemoUnfocused;

  const DayMemoFieldWidget({
    super.key,
    required this.selectedDay,
    required this.initialMemoText,
    required this.memoTextNotifier,
    required this.isMemoFocused,
    required this.onMemoChanged,
    required this.onMemoSaved,
    required this.onMemoCleared,
    required this.onMemoFocused,
    required this.onMemoUnfocused,
  });

  @override
  State<DayMemoFieldWidget> createState() => _DayMemoFieldWidgetState();
}

class _DayMemoFieldWidgetState extends State<DayMemoFieldWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isSaving = false;
  bool _isSaved = false; // 保存済みフラグ

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMemoText);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    
    // 初期値が変更された場合にコントローラーを更新
    widget.memoTextNotifier.addListener(_onMemoTextChanged);
  }

  @override
  void dispose() {
    widget.memoTextNotifier.removeListener(_onMemoTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onMemoTextChanged() {
    if (_controller.text != widget.memoTextNotifier.value) {
      _controller.text = widget.memoTextNotifier.value;
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onMemoFocused();
      // フォーカス時は保存済みフラグをリセット（編集可能にする）
      if (_isSaved) {
        setState(() {
          _isSaved = false;
        });
      }
    } else {
      widget.onMemoUnfocused();
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
      _isSaved = true; // 保存済みフラグを設定
    });
    
    // キーボードを先に閉じる（レイアウト再計算を防ぐ）
    FocusScope.of(context).unfocus();
    
    // 少し待ってから保存処理を実行（レイアウトが安定してから）
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    try {
      // 保存処理を実行（VoidCallbackなのでawait不要）
      widget.onMemoSaved();
      
      // 保存後、フォーカス状態を解除して保存済みUIを表示
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = false; // エラー時は保存済みフラグをリセット
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDay == null) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: widget.memoTextNotifier,
      builder: (context, memoText, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isMemoFocused
                  ? [
                      Colors.blue.shade50,
                      Colors.blue.shade100,
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isMemoFocused
                  ? Colors.blue.shade400
                  : Colors.grey.shade300,
              width: widget.isMemoFocused ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isMemoFocused
                        ? Colors.blue.shade200
                        : Colors.grey.shade300)
                    .withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade700,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${DateFormat('yyyy年M月d日', 'ja_JP').format(widget.selectedDay!)}のメモ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              // メモ入力部分
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 2,
                      decoration: InputDecoration(
                        hintText: 'ここにメモを入力してください...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        suffixIcon: memoText.isNotEmpty
                            ? IconButton(
                                onPressed: widget.onMemoCleared,
                                icon: Icon(
                                  Icons.clear,
                                  size: 20,
                                  color: Colors.grey.shade500,
                                ),
                                tooltip: 'クリア',
                              )
                            : null,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                      onTap: widget.onMemoFocused,
                      onChanged: (value) {
                        widget.memoTextNotifier.value = value;
                        widget.onMemoChanged(value);
                        // テキストが変更されたら保存済みフラグをリセット
                        if (_isSaved && value != widget.initialMemoText) {
                          setState(() {
                            _isSaved = false;
                          });
                        }
                      },
                      onSubmitted: (_) {
                        _handleSave();
                      },
                      onEditingComplete: () {
                        _handleSave();
                      },
                    ),
                    
                    // アクションボタン（フォーカス時のみ表示）
                    if (widget.isMemoFocused) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: widget.onMemoCleared,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('クリア'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _handleSave,
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('保存'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
