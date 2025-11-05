import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 日別メモのHiveサービス
class DailyMemoService {
  static const String _boxName = 'daily_memos';
  static const String _migrationFlagKey = 'daily_memo_migrated_v1';
  static Box<String>? _box;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    // Hive自体の初期化はアプリ側で実施済み想定
    _box = await Hive.openBox<String>(_boxName);
    await _migrateFromSharedPreferencesIfNeeded();
    _initialized = true;
  }

  static Future<void> _migrateFromSharedPreferencesIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrated = prefs.getBool(_migrationFlagKey) ?? false;
      if (migrated) return;

      // SharedPreferencesにある memo_yyyy-MM-dd 形式をHiveへ移行
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('memo_')) {
          final value = prefs.getString(key) ?? '';
          final dateStr = key.substring('memo_'.length);
          if (dateStr.isNotEmpty) {
            await _box!.put(dateStr, value);
          }
        }
      }
      await prefs.setBool(_migrationFlagKey, true);
    } catch (_) {
      // 失敗しても致命的ではないため無視
    }
  }

  static Future<String> getMemo(String dateStr) async {
    await initialize();
    return _box!.get(dateStr, defaultValue: '') ?? '';
  }

  static Future<void> setMemo(String dateStr, String text) async {
    await initialize();
    if (text.isEmpty) {
      await _box!.delete(dateStr);
    } else {
      await _box!.put(dateStr, text);
    }
  }
}


