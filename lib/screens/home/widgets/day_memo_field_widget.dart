// lib/screens/home/widgets/day_memo_field_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 日付別メモフィールドウィジェット
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialMemoText);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onMemoFocused();
    } else {
      widget.onMemoUnfocused();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedDay == null) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: widget.memoTextNotifier,
      builder: (context, memoText, _) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 360 ? 8 : 16,
            vertical: 8,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isMemoFocused
                  ? Colors.blue
                  : Colors.grey.withOpacity(0.3),
              width: widget.isMemoFocused ? 2 : 1,
            ),
            boxShadow: widget.isMemoFocused
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_note,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${DateFormat('yyyy年M月d日', 'ja_JP').format(widget.selectedDay!)}のメモ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'メモを入力...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: memoText.isNotEmpty
                      ? IconButton(
                          onPressed: widget.onMemoCleared,
                          icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                        )
                      : null,
                ),
                style: const TextStyle(fontSize: 14),
                onTap: widget.onMemoFocused,
                onChanged: (value) {
                  widget.memoTextNotifier.value = value;
                  widget.onMemoChanged(value);
                },
                onSubmitted: (_) => widget.onMemoSaved(),
                onEditingComplete: widget.onMemoSaved,
              ),
              if (widget.isMemoFocused) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: widget.onMemoSaved,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('保存', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: widget.onMemoCleared,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('クリア', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

