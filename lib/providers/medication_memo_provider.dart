import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_memo.dart';
import '../services/medication_service.dart';

/// メディケーションメモの状態管理
/// Riverpodを使用してメディケーションメモの状態を管理
class MedicationMemoNotifier extends StateNotifier<List<MedicationMemo>> {
  MedicationMemoNotifier() : super([]);

  /// メディケーションメモを読み込む
  Future<void> loadMemos() async {
    try {
      // MedicationServiceを使用してデータを読み込む
      // 実装は後で追加
      state = [];
    } catch (e) {
      // エラーハンドリング
      debugPrint('メディケーションメモ読み込みエラー: $e');
    }
  }

  /// メディケーションメモを追加する
  Future<void> addMemo(MedicationMemo memo) async {
    try {
      // MedicationServiceを使用してデータを保存
      state = [...state, memo];
    } catch (e) {
      debugPrint('メディケーションメモ追加エラー: $e');
    }
  }

  /// メディケーションメモを更新する
  Future<void> updateMemo(MedicationMemo memo) async {
    try {
      state = state.map((m) => m.id == memo.id ? memo : m).toList();
    } catch (e) {
      debugPrint('メディケーションメモ更新エラー: $e');
    }
  }

  /// メディケーションメモを削除する
  Future<void> deleteMemo(String id) async {
    try {
      state = state.where((m) => m.id != id).toList();
    } catch (e) {
      debugPrint('メディケーションメモ削除エラー: $e');
    }
  }
}

/// メディケーションメモのProvider
final medicationMemoProvider = StateNotifierProvider<MedicationMemoNotifier, List<MedicationMemo>>(
  (ref) => MedicationMemoNotifier(),
);
