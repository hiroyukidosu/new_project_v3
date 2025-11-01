// lib/screens/home/widgets/memo_field.dart

import 'package:flutter/material.dart';

/// メモ入力欄ウィジェット
class MemoField extends StatefulWidget {
  final String initialValue;
  final String hintText;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSaved;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  const MemoField({
    super.key,
    this.initialValue = '',
    this.hintText = 'メモを入力...',
    this.maxLines = 2,
    this.onChanged,
    this.onSaved,
    this.focusNode,
    this.controller,
  });

  @override
  State<MemoField> createState() => _MemoFieldState();
}

class _MemoFieldState extends State<MemoField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? Colors.blue : Colors.grey.withOpacity(0.3),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: _isFocused
              ? IconButton(
                  icon: const Icon(Icons.check, color: Colors.blue),
                  onPressed: () {
                    _focusNode.unfocus();
                    widget.onSaved?.call();
                  },
                )
              : null,
        ),
        onChanged: (value) {
          widget.onChanged?.call(value);
        },
      ),
    );
  }
}
