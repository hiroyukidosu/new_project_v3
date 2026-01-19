import '../models/medication_memo.dart';
import '../utils/logger.dart';

/// Null安全性ヘルパークラス
class NullSafetyHelpers {
  /// 安全にメモを検索
  static MedicationMemo? findMemoSafely({
    required List<MedicationMemo> memos,
    required String medicationName,
  }) {
    try {
      return memos.cast<MedicationMemo?>().firstWhere(
            (memo) => memo?.name == medicationName,
        orElse: () => null,
      );
    } catch (e) {
      Logger.warning('メモ検索エラー: $e');
      return null;
    }
  }
  
  /// 安全にIDでメモを検索
  static MedicationMemo? findMemoByIdSafely({
    required List<MedicationMemo> memos,
    required String id,
  }) {
    try {
      return memos.cast<MedicationMemo?>().firstWhere(
            (memo) => memo?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      Logger.warning('メモID検索エラー: $e');
      return null;
    }
  }
  
  /// 安全にリストから要素を取得
  static T? getAtSafely<T>(List<T> list, int index) {
    try {
      if (index >= 0 && index < list.length) {
        return list[index];
      }
      return null;
    } catch (e) {
      Logger.warning('リスト要素取得エラー: $e');
      return null;
    }
  }
  
  /// 安全にマップから値を取得
  static V? getMapValueSafely<K, V>(Map<K, V> map, K key) {
    try {
      return map[key];
    } catch (e) {
      Logger.warning('マップ値取得エラー: $e');
      return null;
    }
  }
  
  /// 安全に文字列をintに変換
  static int? parseIntSafely(String? value, {int? defaultValue}) {
    try {
      if (value == null || value.isEmpty) return defaultValue;
      return int.tryParse(value) ?? defaultValue;
    } catch (e) {
      Logger.warning('int変換エラー: $e');
      return defaultValue;
    }
  }
  
  /// 安全に文字列をdoubleに変換
  static double? parseDoubleSafely(String? value, {double? defaultValue}) {
    try {
      if (value == null || value.isEmpty) return defaultValue;
      return double.tryParse(value) ?? defaultValue;
    } catch (e) {
      Logger.warning('double変換エラー: $e');
      return defaultValue;
    }
  }
  
  /// 安全に日付を文字列から変換
  static DateTime? parseDateTimeSafely(String? value, {DateTime? defaultValue}) {
    try {
      if (value == null || value.isEmpty) return defaultValue;
      return DateTime.tryParse(value) ?? defaultValue;
    } catch (e) {
      Logger.warning('DateTime変換エラー: $e');
      return defaultValue;
    }
  }
  
  /// Null合体演算子のヘルパー
  static T coalesce<T>(T? value, T defaultValue) {
    return value ?? defaultValue;
  }
  
  /// 複数の値から最初のnullでない値を取得
  static T? coalesceMultiple<T>(List<T?> values) {
    for (final value in values) {
      if (value != null) return value;
    }
    return null;
  }
  
  /// 安全にリストをフィルタリング
  static List<T> filterNonNull<T>(List<T?> list) {
    return list.whereType<T>().toList();
  }
  
  /// 安全にマップをフィルタリング
  static Map<K, V> filterNonNullMap<K, V>(Map<K, V?> map) {
    return Map.fromEntries(
      map.entries.where((entry) => entry.value != null).map(
            (entry) => MapEntry(entry.key, entry.value as V),
      ),
    );
  }
}

