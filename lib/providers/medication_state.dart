import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medication_memo.dart';
import '../repositories/medication_repository.dart';

/// メディケーション状態
class MedicationState {
  final List<MedicationMemo> medicationMemos;
  final Map<String, bool> medicationMemoStatus;
  final Map<String, Map<String, bool>> weekdayMedicationStatus;
  final List<Map<String, dynamic>> addedMedications;
  final bool isLoading;
  final String? errorMessage;
  
  MedicationState({
    this.medicationMemos = const [],
    this.medicationMemoStatus = const {},
    this.weekdayMedicationStatus = const {},
    this.addedMedications = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  
  MedicationState copyWith({
    List<MedicationMemo>? medicationMemos,
    Map<String, bool>? medicationMemoStatus,
    Map<String, Map<String, bool>>? weekdayMedicationStatus,
    List<Map<String, dynamic>>? addedMedications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MedicationState(
      medicationMemos: medicationMemos ?? this.medicationMemos,
      medicationMemoStatus: medicationMemoStatus ?? this.medicationMemoStatus,
      weekdayMedicationStatus: weekdayMedicationStatus ?? this.weekdayMedicationStatus,
      addedMedications: addedMedications ?? this.addedMedications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// メディケーション状態管理Notifier
class MedicationStateNotifier extends StateNotifier<MedicationState> {
  final MedicationRepository _repository;
  
  MedicationStateNotifier(this._repository) : super(MedicationState()) {
    loadAll();
  }
  
  /// 全データを読み込み
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final memos = await _repository.getMemos();
      final memoStatus = await _repository.getMemoStatus();
      final weekdayStatus = await _repository.getWeekdayMedicationStatus();
      final addedMedications = await _repository.getAddedMedications();
      
      // weekdayStatusをMap<String, Map<String, bool>>形式に変換
      final weekdayStatusMap = <String, Map<String, bool>>{};
      for (final entry in weekdayStatus.entries) {
        final parts = entry.key.split('_');
        if (parts.length >= 2) {
          final memoKey = parts[0];
          final weekdayKey = parts.sublist(1).join('_');
          weekdayStatusMap.putIfAbsent(memoKey, () => {});
          weekdayStatusMap[memoKey]![weekdayKey] = entry.value;
        }
      }
      
      state = state.copyWith(
        medicationMemos: memos,
        medicationMemoStatus: memoStatus,
        weekdayMedicationStatus: weekdayStatusMap,
        addedMedications: addedMedications,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'データの読み込みに失敗しました: $e',
      );
    }
  }
  
  /// メモを追加
  Future<void> addMemo(MedicationMemo memo) async {
    try {
      await _repository.saveMemo(memo);
      state = state.copyWith(
        medicationMemos: [...state.medicationMemos, memo],
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'メモの追加に失敗しました: $e');
    }
  }
  
  /// メモを更新
  Future<void> updateMemo(MedicationMemo memo) async {
    try {
      await _repository.saveMemo(memo);
      state = state.copyWith(
        medicationMemos: state.medicationMemos.map((m) => m.id == memo.id ? memo : m).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'メモの更新に失敗しました: $e');
    }
  }
  
  /// メモを削除
  Future<void> deleteMemo(String id) async {
    try {
      await _repository.deleteMemo(id);
      state = state.copyWith(
        medicationMemos: state.medicationMemos.where((m) => m.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'メモの削除に失敗しました: $e');
    }
  }
  
  /// メモステータスを更新
  Future<void> updateMemoStatus(String key, bool value) async {
    try {
      final newStatus = Map<String, bool>.from(state.medicationMemoStatus);
      newStatus[key] = value;
      await _repository.saveMemoStatus(newStatus);
      state = state.copyWith(medicationMemoStatus: newStatus);
    } catch (e) {
      state = state.copyWith(errorMessage: 'ステータスの更新に失敗しました: $e');
    }
  }
  
  /// 曜日メディケーションステータスを更新
  Future<void> updateWeekdayStatus(String memoKey, String weekdayKey, bool value) async {
    try {
      final newWeekdayStatus = Map<String, Map<String, bool>>.from(state.weekdayMedicationStatus);
      newWeekdayStatus.putIfAbsent(memoKey, () => {});
      newWeekdayStatus[memoKey]![weekdayKey] = value;
      
      // フラットな形式に変換して保存
      final flatStatus = <String, bool>{};
      for (final entry in newWeekdayStatus.entries) {
        for (final subEntry in entry.value.entries) {
          flatStatus['${entry.key}_${subEntry.key}'] = subEntry.value;
        }
      }
      
      await _repository.saveWeekdayMedicationStatus(flatStatus);
      state = state.copyWith(weekdayMedicationStatus: newWeekdayStatus);
    } catch (e) {
      state = state.copyWith(errorMessage: '曜日ステータスの更新に失敗しました: $e');
    }
  }
}

/// メディケーション状態のProvider
final medicationStateProvider = StateNotifierProvider<MedicationStateNotifier, MedicationState>(
  (ref) => MedicationStateNotifier(ref.watch(medicationRepositoryProvider)),
);

/// メディケーションリポジトリのProvider
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

/// メディケーションリポジトリの初期化用Provider
final medicationRepositoryInitProvider = FutureProvider<void>((ref) async {
  final repository = ref.read(medicationRepositoryProvider);
  await repository.initialize();
});

