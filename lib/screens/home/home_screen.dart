import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/medication_memo.dart';

/// メディケーションホームページ
/// アプリのメイン画面
class MedicationHomePage extends StatefulWidget {
  const MedicationHomePage({super.key});

  @override
  State<MedicationHomePage> createState() => _MedicationHomePageState();
}

class _MedicationHomePageState extends State<MedicationHomePage> with TickerProviderStateMixin {
  // カレンダー関連
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _selectedDates = <DateTime>{};
  Map<String, String> _calendarMemos = {};
  
  // メディケーション関連
  List<Map<String, dynamic>> _addedMedications = [];
  Map<String, Map<String, dynamic>> _medicationData = {};
  Map<String, double> _adherenceRates = {};
  List<dynamic> _medicines = [];
  List<MedicationMemo> _medicationMemos = [];
  
  // UI関連
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _memoController = TextEditingController();
  
  // 状態管理
  bool _isLoading = false;
  bool _autoBackupEnabled = true;
  DateTime? _lastAlarmCheckLog;
  final Duration _logInterval = const Duration(minutes: 30);
  
  // キー
  final String _medicationMemosKey = 'medication_memos_v2';
  final String _weekdayMedicationStatusKey = 'weekday_medication_status_v2';
  final String _addedMedicationsKey = 'added_medications_v2';
  
  // スクロール関連
  bool _isAtTop = true;
  double _lastScrollPosition = 0.0;
  bool _isScrollBatonPassActive = false;
  
  // ログ関連
  bool _shouldLog() {
    final now = DateTime.now();
    if (_lastAlarmCheckLog == null) {
      _lastAlarmCheckLog = now;
      return true;
    }
    if (now.difference(_lastAlarmCheckLog!) >= _logInterval) {
      _lastAlarmCheckLog = now;
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    setState(() => _isLoading = true);
    try {
      await _loadSavedData();
    } catch (e) {
      debugPrint('初期化エラー: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSavedData() async {
    try {
      // メディケーションメモの読み込み
      await _loadMedicationMemos();
      
      // その他のデータ読み込み
      await _loadMedicationData();
      await _loadAlarmData();
      await _loadCalendarMarks();
      await _loadUserPreferences();
      await _loadDayColors();
      await _loadStatistics();
      await _loadAppSettings();
      await _loadMedicationDoseStatus();
    } catch (e) {
      debugPrint('データ読み込みエラー: $e');
    }
  }

  Future<void> _loadMedicationMemos() async {
    try {
      final box = Hive.box<MedicationMemo>('medication_memos');
      _medicationMemos = box.values.toList();
    } catch (e) {
      debugPrint('メディケーションメモ読み込みエラー: $e');
    }
  }

  Future<void> _loadMedicationData() async {
    // 実装は後で追加
  }

  Future<void> _loadAlarmData() async {
    // 実装は後で追加
  }

  Future<void> _loadCalendarMarks() async {
    // 実装は後で追加
  }

  Future<void> _loadUserPreferences() async {
    // 実装は後で追加
  }

  Future<void> _loadDayColors() async {
    // 実装は後で追加
  }

  Future<void> _loadStatistics() async {
    // 実装は後で追加
  }

  Future<void> _loadAppSettings() async {
    // 実装は後で追加
  }

  Future<void> _loadMedicationDoseStatus() async {
    // 実装は後で追加
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('薬の管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'カレンダー'),
            Tab(icon: Icon(Icons.medication), text: '薬'),
            Tab(icon: Icon(Icons.bar_chart), text: '統計'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildMedicationTab(),
          _buildStatisticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMemo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return TableCalendar<dynamic>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => _selectedDates.contains(day),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildMedicationTab() {
    return ListView.builder(
      itemCount: _medicationMemos.length,
      itemBuilder: (context, index) {
        final memo = _medicationMemos[index];
        return ListTile(
          leading: Icon(
            memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
            color: memo.color,
          ),
          title: Text(memo.name),
          subtitle: Text(memo.dosage),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteMemo(memo.id),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '統計情報',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '登録された薬: ${_medicationMemos.length}件',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedDates.add(selectedDay);
    });
  }

  void _addMemo() {
    // メモ追加の実装
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('薬を追加'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: '薬の名前',
            hintText: '例: アスピリン',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // メモ追加の実装
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _deleteMemo(String id) {
    setState(() {
      _medicationMemos.removeWhere((memo) => memo.id == id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _memoController.dispose();
    super.dispose();
  }
}
