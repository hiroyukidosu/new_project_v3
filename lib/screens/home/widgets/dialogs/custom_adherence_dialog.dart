// lib/screens/home/widgets/dialogs/custom_adherence_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import '../../../../helpers/calculations/adherence_calculator.dart'; // 実際の計算は親ウィジェットで行われる

/// カスタム遵守率計算ダイアログ
class CustomAdherenceDialog extends StatefulWidget {
  final Function(double rate, int days) onCalculate;
  final ScrollController? statsScrollController;

  const CustomAdherenceDialog({
    super.key,
    required this.onCalculate,
    this.statsScrollController,
  });

  @override
  State<CustomAdherenceDialog> createState() => _CustomAdherenceDialogState();
}

class _CustomAdherenceDialogState extends State<CustomAdherenceDialog> {
  final TextEditingController _daysController = TextEditingController();
  final FocusNode _daysFocusNode = FocusNode();
  bool _isCalculating = false;

  @override
  void dispose() {
    _daysController.dispose();
    _daysFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.analytics, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '任意の日数の遵守率',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分析したい期間の日数を入力してください',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _daysController,
              focusNode: _daysFocusNode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '日数',
                hintText: '例: 30',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            if (_isCalculating) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isCalculating ? null : () => _calculate(),
          child: const Text('計算'),
        ),
      ],
    );
  }

  Future<void> _calculate() async {
    if (!mounted) return;
    
    final daysText = _daysController.text.trim();
    if (daysText.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('日数を入力してください'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final days = int.tryParse(daysText);
    if (days == null || days < 1 || days > 365) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('有効な日数（1-365）を入力してください'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isCalculating = true);

    try {
      // 計算は親ウィジェットで実行される
      // コールバックは非同期で実行されるため、awaitで待つ
      await widget.onCalculate(0.0, days);
      
      // 計算完了後、ダイアログは親ウィジェットで閉じられる
      // ここでは計算中の状態をリセット
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('計算エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // エラーログを記録
      debugPrint('カスタム遵守率ダイアログ計算エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
    }
  }
}

