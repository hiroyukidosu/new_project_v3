import 'package:intl/intl.dart';

/// 日付ユーティリティ - 日付の正規化を統一
class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  
  /// 日付をキー文字列に変換
  static String toKey(DateTime date) {
    return _dateFormat.format(date);
  }
  
  /// 日付を正規化（時刻情報を削除）
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// UTC日付を正規化
  static DateTime normalizeUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
  
  /// キー文字列から日付に変換
  static DateTime fromKey(String key) {
    return _dateFormat.parse(key);
  }
  
  /// 日付の比較（時刻を無視）
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  /// 今日の日付を取得（正規化済み）
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  /// 昨日の日付を取得（正規化済み）
  static DateTime yesterday() {
    return today().subtract(const Duration(days: 1));
  }
  
  /// 明日の日付を取得（正規化済み）
  static DateTime tomorrow() {
    return today().add(const Duration(days: 1));
  }
  
  /// 日付範囲の生成
  static List<DateTime> generateDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    DateTime current = normalize(start);
    final normalizedEnd = normalize(end);
    
    while (current.isBefore(normalizedEnd) || isSameDay(current, normalizedEnd)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
  
  /// 週の開始日を取得（月曜日）
  static DateTime startOfWeek(DateTime date) {
    final normalized = normalize(date);
    final weekday = normalized.weekday;
    return normalized.subtract(Duration(days: weekday - 1));
  }
  
  /// 週の終了日を取得（日曜日）
  static DateTime endOfWeek(DateTime date) {
    final normalized = normalize(date);
    final weekday = normalized.weekday;
    return normalized.add(Duration(days: 7 - weekday));
  }
  
  /// 月の開始日を取得
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// 月の終了日を取得
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
  
  /// 年の開始日を取得
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }
  
  /// 年の終了日を取得
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }
  
  /// 日付の差分を日数で取得
  static int daysBetween(DateTime start, DateTime end) {
    final normalizedStart = normalize(start);
    final normalizedEnd = normalize(end);
    return normalizedEnd.difference(normalizedStart).inDays;
  }
  
  /// 曜日の日本語名を取得
  static String weekdayNameJa(int weekday) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[weekday - 1];
  }
  
  /// 曜日の英語名を取得
  static String weekdayNameEn(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }
  
  /// 月の日本語名を取得
  static String monthNameJa(int month) {
    return '${month}月';
  }
  
  /// 月の英語名を取得
  static String monthNameEn(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  /// 日付を表示用文字列に変換
  static String formatDisplay(DateTime date) {
    return DateFormat('yyyy年MM月dd日').format(date);
  }
  
  /// 日付を表示用文字列に変換（曜日付き）
  static String formatDisplayWithWeekday(DateTime date) {
    return '${DateFormat('yyyy年MM月dd日').format(date)}（${weekdayNameJa(date.weekday)}）';
  }
  
  /// 日付を簡易表示用文字列に変換
  static String formatShort(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }
  
  /// 日付を時刻付きで表示用文字列に変換
  static String formatWithTime(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}

