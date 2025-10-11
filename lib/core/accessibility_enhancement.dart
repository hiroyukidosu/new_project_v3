import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// アクセシビリティの強化 - Semantics追加とダークモード対応
class AccessibilityEnhancement {
  
  /// アクセシビリティ対応のメディケーションカード
  static Widget buildAccessibleMedicationCard({
    required dynamic memo,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return Semantics(
      label: '服用記録: ${memo['name'] ?? '無題'}',
      hint: 'ダブルタップで詳細を表示',
      button: true,
      selected: isSelected,
      child: _AccessibleMedicationCard(
        memo: memo,
        onTap: onTap,
        isSelected: isSelected,
      ),
    );
  }
  
  /// アクセシビリティ対応のカレンダー
  static Widget buildAccessibleCalendar({
    required DateTime focusedDay,
    required DateTime selectedDay,
    required Function(DateTime, DateTime) onDaySelected,
    required Function(DateTime) onPageChanged,
    required Map<DateTime, List<dynamic>> events,
  }) {
    return _AccessibleCalendar(
      focusedDay: focusedDay,
      selectedDay: selectedDay,
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      events: events,
    );
  }
  
  /// アクセシビリティ対応のボタン
  static Widget buildAccessibleButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
    String? hint,
    bool isEnabled = true,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: isEnabled,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
  
  /// アクセシビリティ対応のテキストフィールド
  static Widget buildAccessibleTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helperText,
    bool isRequired = false,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      textField: true,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
  
  /// ダークモード対応の色
  static Color getAccessibleTextColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }
  
  /// ダークモード対応の背景色
  static Color getAccessibleBackgroundColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.grey[900]! : Colors.white;
  }
  
  /// ダークモード対応のカード色
  static Color getAccessibleCardColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[50]!;
  }
  
  /// コントラスト比を考慮した色
  static Color getContrastColor(BuildContext context, Color backgroundColor) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return Colors.white;
    } else {
      return Colors.black87;
    }
  }
}

/// アクセシビリティ対応のメディケーションカード
class _AccessibleMedicationCard extends StatelessWidget {
  final dynamic memo;
  final VoidCallback onTap;
  final bool isSelected;
  
  const _AccessibleMedicationCard({
    required this.memo,
    required this.onTap,
    required this.isSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    final textColor = AccessibilityEnhancement.getAccessibleTextColor(context);
    final cardColor = AccessibilityEnhancement.getAccessibleCardColor(context);
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: isSelected ? 8 : 2,
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo['name'] ?? '無題',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                memo['dosage'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              if (memo['notes'] != null && memo['notes'].isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  memo['notes'],
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// アクセシビリティ対応のカレンダー
class _AccessibleCalendar extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Map<DateTime, List<dynamic>> events;
  
  const _AccessibleCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.events,
  });
  
  @override
  State<_AccessibleCalendar> createState() => _AccessibleCalendarState();
}

class _AccessibleCalendarState extends State<_AccessibleCalendar> {
  @override
  Widget build(BuildContext context) {
    final textColor = AccessibilityEnhancement.getAccessibleTextColor(context);
    final backgroundColor = AccessibilityEnhancement.getAccessibleBackgroundColor(context);
    
    return Container(
      height: 400,
      color: backgroundColor,
      child: Column(
        children: [
          // カレンダーヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: 'カレンダー: ${widget.focusedDay.year}年${widget.focusedDay.month}月',
              child: Text(
                '${widget.focusedDay.year}年${widget.focusedDay.month}月',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          
          // カレンダーグリッド
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: _getDaysInMonth(widget.focusedDay),
              itemBuilder: (context, dayIndex) {
                final day = dayIndex + 1;
                final date = DateTime(widget.focusedDay.year, widget.focusedDay.month, day);
                final hasEvents = widget.events[date]?.isNotEmpty ?? false;
                
                return Semantics(
                  label: '${widget.focusedDay.month}月${day}日',
                  hint: hasEvents ? 'イベントがあります' : 'イベントはありません',
                  button: true,
                  selected: widget.selectedDay.day == day,
                  child: GestureDetector(
                    onTap: () => widget.onDaySelected(date, date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasEvents ? Colors.blue.withOpacity(0.3) : null,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: hasEvents ? Colors.blue : textColor,
                            fontWeight: hasEvents ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}

/// アクセシビリティの監視
class AccessibilityMonitor {
  static final Map<String, int> _accessibilityUsage = {};
  static final Map<String, DateTime> _lastAccessibilityUsage = {};
  
  /// アクセシビリティ機能の使用を記録
  static void recordAccessibilityUsage(String feature) {
    _accessibilityUsage[feature] = (_accessibilityUsage[feature] ?? 0) + 1;
    _lastAccessibilityUsage[feature] = DateTime.now();
    Logger.debug('アクセシビリティ機能使用: $feature');
  }
  
  /// アクセシビリティ統計の取得
  static Map<String, dynamic> getAccessibilityStats() {
    return {
      'usageCounts': Map.from(_accessibilityUsage),
      'lastUsageTimes': Map.from(_lastAccessibilityUsage),
      'totalUsage': _accessibilityUsage.values.fold(0, (sum, count) => sum + count),
    };
  }
  
  /// 統計のクリア
  static void clearStats() {
    _accessibilityUsage.clear();
    _lastAccessibilityUsage.clear();
    Logger.info('アクセシビリティ統計をクリアしました');
  }
}

/// アクセシビリティ対応の最適化されたアプリ
class AccessibleOptimizedApp extends StatelessWidget {
  final Widget child;
  
  const AccessibleOptimizedApp({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アクセシビリティ対応アプリ',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Semantics(
        label: 'メインアプリケーション',
        child: child,
      ),
    );
  }
}

/// アクセシビリティ対応の最適化されたホームページ
class AccessibleOptimizedHomePage extends StatefulWidget {
  const AccessibleOptimizedHomePage({super.key});
  
  @override
  State<AccessibleOptimizedHomePage> createState() => _AccessibleOptimizedHomePageState();
}

class _AccessibleOptimizedHomePageState extends State<AccessibleOptimizedHomePage> {
  List<dynamic> _medicationMemos = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 初期データの読み込み
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _isLoading = false;
      });
      
      Logger.info('アクセシビリティ対応アプリの初期化完了');
    } catch (e) {
      Logger.error('アクセシビリティ対応アプリの初期化エラー', e);
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アクセシビリティ対応アプリ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility),
            onPressed: () {
              AccessibilityMonitor.recordAccessibilityUsage('accessibility_button');
              _showAccessibilityInfo();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // アクセシビリティ情報の表示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withOpacity(0.1),
                  child: const Text(
                    'アクセシビリティ機能が有効です',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                
                // メインコンテンツ
                Expanded(
                  child: _buildAccessibleMedicationList(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildAccessibleMedicationList() {
    return ListView.builder(
      itemCount: _medicationMemos.length,
      itemBuilder: (context, index) {
        final memo = _medicationMemos[index];
        return AccessibilityEnhancement.buildAccessibleMedicationCard(
          memo: memo,
          onTap: () => _handleMedicationTap(memo),
          isSelected: false,
        );
      },
    );
  }
  
  void _handleMedicationTap(dynamic memo) {
    AccessibilityMonitor.recordAccessibilityUsage('medication_tap');
    Logger.debug('メディケーションタップ: ${memo['name']}');
  }
  
  void _showAccessibilityInfo() {
    final stats = AccessibilityMonitor.getAccessibilityStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アクセシビリティ情報'),
        content: SingleChildScrollView(
          child: Text('統計情報:\n${stats.toString()}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
