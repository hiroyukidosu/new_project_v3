import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/calendar_widget.dart';

/// カレンダー画面
/// 
/// 責務:
/// - カレンダーの表示
/// - 選択された日付の詳細表示
/// - カレンダー操作の処理
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CalendarController();
    _initializeCalendar();
  }

  /// カレンダーを初期化
  Future<void> _initializeCalendar() async {
    await _controller.loadCalendarMarks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _controller.loadCalendarMarks();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // カレンダー表示
          Expanded(
            flex: 3,
            child: CalendarWidget(
              controller: _controller,
            ),
          ),
          // 選択された日付の詳細
          Expanded(
            flex: 2,
            child: _buildSelectedDateDetails(),
          ),
        ],
      ),
    );
  }

  /// 選択された日付の詳細を表示
  Widget _buildSelectedDateDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '選択された日付',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (_controller.selectedDay != null) ...[
            Text(
              '日付: ${_formatDate(_controller.selectedDay!)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'マーク: ${_controller.hasMark(_controller.selectedDay!) ? "あり" : "なし"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'イベント数: ${_controller.getEventCount(_controller.selectedDay!)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            Text(
              '日付を選択してください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 日付をフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
