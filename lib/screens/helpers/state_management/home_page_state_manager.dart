/// ホームページ状態管理ヘルパー
/// 状態管理に関連するメソッドを提供
class HomePageStateManager {
  /// データが変更されたかチェック
  static bool hasDataChanged({
    required bool medicationMemoStatusChanged,
    required bool weekdayMedicationStatusChanged,
    required bool addedMedicationsChanged,
  }) {
    return medicationMemoStatusChanged ||
           weekdayMedicationStatusChanged ||
           addedMedicationsChanged;
  }
  
  /// 変更フラグをリセット
  static Map<String, bool> resetChangeFlags() {
    return {
      'medicationMemoStatus': false,
      'weekdayMedicationStatus': false,
      'addedMedications': false,
    };
  }
  
  /// 変更フラグを設定
  static Map<String, bool> setChangeFlag(String flagName, bool value) {
    return {flagName: value};
  }
}

