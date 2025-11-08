// lib/screens/home/widgets/dialogs/custom_adherence_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:intl/intl.dart';
// import '../../../../helpers/calculations/adherence_calculator.dart'; // 実際の計算は親ウィジェットで行われる

/// カスタム遵守率計算ダイアログ
class CustomAdherenceDialog extends StatefulWidget {
  final Future<void> Function(double rate, int days) onCalculate;
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
    final daysText = _daysController.text.trim();
    if (daysText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日数を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final days = int.tryParse(daysText);
    if (days == null || days < 1 || days > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('有効な日数（1-365）を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCalculating = true);

    try {
      // 注意: AdherenceCalculatorは、実際のデータが必要なため、
      // ここではコールバック経由で計算を行う
      // 実際の計算は親ウィジェットで実行される
      await widget.onCalculate(0.0, days); // 親で計算されるため、仮の値
      
      // 計算が成功した場合のみダイアログを閉じる
      if (mounted) {
        setState(() => _isCalculating = false);
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ カスタム遵守率ダイアログ計算エラー: $e');
      debugPrint('スタックトレース: $stackTrace');
      // Crashlyticsに記録
      try {
        await FirebaseCrashlytics.instance.log('カスタム遵守率ダイアログ計算エラー: CustomAdherenceDialog');
        await FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: false);
      } catch (_) {
        // Crashlytics記録失敗時は無視
      }
      // エラー時はダイアログを開いたままにする
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('計算エラー: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

