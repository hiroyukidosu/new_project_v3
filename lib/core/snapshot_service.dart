import 'dart:async';

/// シンプルなスナップショットサービス
/// 他ウィジェットから「変更前のスナップショット保存」を呼び出すための仲介役
class SnapshotService {
  static Future<void> Function(String label)? _saveBeforeChangeCallback;

  /// main側（例: MedicationHomePage）で登録
  static void register(Future<void> Function(String label) callback) {
    _saveBeforeChangeCallback = callback;
  }

  /// 変更前スナップショットを保存（登録がない場合は何もしない）
  static Future<void> saveBeforeChange(String label) async {
    final cb = _saveBeforeChangeCallback;
    if (cb == null) return;
    try {
      await cb(label);
    } catch (_) {
      // スナップショット保存失敗時はアプリ動作を継続（黙殺）
    }
  }
}


