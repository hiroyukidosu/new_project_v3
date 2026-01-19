import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/trial_service.dart';

/// トライアル状態の管理
class TrialState {
  final bool isExpired;
  final int remainingMinutes;
  final String purchaseStatus;
  final bool isLoading;

  const TrialState({
    required this.isExpired,
    required this.remainingMinutes,
    required this.purchaseStatus,
    this.isLoading = false,
  });

  TrialState copyWith({
    bool? isExpired,
    int? remainingMinutes,
    String? purchaseStatus,
    bool? isLoading,
  }) {
    return TrialState(
      isExpired: isExpired ?? this.isExpired,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      purchaseStatus: purchaseStatus ?? this.purchaseStatus,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// トライアル状態のNotifier
class TrialNotifier extends StateNotifier<TrialState> {
  TrialNotifier()
      : super(const TrialState(
          isExpired: false,
          remainingMinutes: 1440,
          purchaseStatus: 'trial',
        ));

  /// トライアル状態を読み込む
  Future<void> loadTrialStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final status = await TrialService.getTrialStatus();
      state = state.copyWith(
        isExpired: status['isExpired'] as bool,
        remainingMinutes: status['remainingMinutes'] as int,
        purchaseStatus: status['purchaseStatus'] as String,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('トライアル状態読み込みエラー: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// トライアルをリセットする
  Future<void> resetTrial() async {
    try {
      await TrialService.resetTrial();
      await loadTrialStatus();
    } catch (e) {
      debugPrint('トライアルリセットエラー: $e');
    }
  }
}

/// トライアル状態のProvider
final trialProvider = StateNotifierProvider<TrialNotifier, TrialState>(
  (ref) => TrialNotifier(),
);

