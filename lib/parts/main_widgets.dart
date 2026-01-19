part of '../main.dart';

class MedicationCard extends StatelessWidget {
  final MedicationMemo memo;
  final VoidCallback onTap;
  final bool isSelected;
  
  const MedicationCard({
    Key? key,
    required this.memo,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppDimensions.cardMargin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        side: BorderSide(
          color: isSelected ? memo.color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: AppDimensions.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    memo.type == 'サプリメント' ? Icons.eco : Icons.medication,
                    color: memo.color,
                    size: AppDimensions.mediumIcon,
                  ),
                  const SizedBox(width: AppDimensions.mediumSpacing),
                  Expanded(
                    child: Text(
                      memo.name,
                      style: const TextStyle(
                        fontSize: AppDimensions.largeText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: memo.color,
                      size: AppDimensions.mediumIcon,
                    ),
                ],
              ),
              if (memo.dosage.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  '用量: ${memo.dosage}',
                  style: const TextStyle(
                    fontSize: AppDimensions.mediumText,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (memo.notes.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  memo.notes,
                  style: const TextStyle(
                    fontSize: AppDimensions.mediumText,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WeekdaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;
  
  const WeekdaySelector({
    Key? key,
    required this.selectedDays,
    required this.onChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    
    return Wrap(
      spacing: AppDimensions.smallSpacing,
      runSpacing: AppDimensions.smallSpacing,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            final newDays = List<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(index);
            } else {
              newDays.add(index);
            }
            onChanged(newDays);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimensions.mediumText,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ✅ 修正：エラー境界ウィジェット
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  const ErrorBoundary({required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('エラーが発生しました'),
                ElevatedButton(
                  onPressed: () => setState(() => _hasError = false),
                  child: const Text('再試行'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      try {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      } catch (e) {
        _debugLog('Crashlyticsエラーレポート失敗: $e');
      }
      
      // ✅ 修正：レイアウト中のsetState()を避ける
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
    };
  }
}
