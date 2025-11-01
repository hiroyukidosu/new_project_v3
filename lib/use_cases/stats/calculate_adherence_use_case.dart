import '../../repositories/medication_repository.dart';
import '../../models/medication_memo.dart';

/// 遵守率計算のUseCase
class CalculateAdherenceUseCase {
  final MedicationRepository _repository;
  
  CalculateAdherenceUseCase(this._repository);
  
  /// 指定日数の遵守率を計算
  Future<Map<String, double>> execute(int days) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final adherenceRates = <String, double>{};
      
      // メモステータスを取得
      final memoStatus = await _repository.getMemoStatus();
      final weekdayStatus = await _repository.getWeekdayMedicationStatus();
      final memos = await _repository.getMemos();
      
      // 各メモの遵守率を計算
      for (final memo in memos) {
        final memoKey = memo.id;
        int completedCount = 0;
        int totalCount = 0;
        
        // 指定期間内の各日付をチェック
        for (int i = 0; i < days; i++) {
          final checkDate = startDate.add(Duration(days: i));
          final dateKey = _formatDate(checkDate);
          final weekdayKey = '${memoKey}_${_getWeekdayKey(checkDate)}';
          
          totalCount++;
          
          // 日付ベースのステータスをチェック
          if (memoStatus.containsKey('$memoKey_$dateKey') && 
              memoStatus['$memoKey_$dateKey'] == true) {
            completedCount++;
          }
          // 曜日ベースのステータスをチェック
          else if (weekdayStatus.containsKey(weekdayKey) && 
                   weekdayStatus[weekdayKey] == true) {
            completedCount++;
          }
        }
        
        final rate = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;
        adherenceRates[memo.name] = rate;
      }
      
      return adherenceRates;
    } catch (e) {
      return {};
    }
  }
  
  /// 日付を文字列にフォーマット
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 曜日キーを取得
  String _getWeekdayKey(DateTime date) {
    const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return weekdays[date.weekday - 1];
  }
}

