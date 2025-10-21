import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// メモリ最適化ユーティリティ
/// 
/// メモリ使用量を監視し、最適化を実行
class MemoryOptimizer {
  static final List<WeakReference> _weakReferences = [];
  static int _memoryWarningCount = 0;
  
  /// メモリ使用量を監視
  static void monitorMemoryUsage() {
    if (kDebugMode) {
      // デバッグ環境でのみメモリ使用量を監視
      _logMemoryUsage();
    }
  }
  
  /// メモリ使用量をログ出力
  static void _logMemoryUsage() {
    // メモリ使用量の概算（実際の実装はプラットフォーム依存）
    final estimatedUsage = _estimateMemoryUsage();
    
    if (estimatedUsage > 100 * 1024 * 1024) { // 100MB以上
      debugPrint('[MEMORY] High memory usage: ${(estimatedUsage / 1024 / 1024).toStringAsFixed(1)}MB');
      _memoryWarningCount++;
    }
  }
  
  /// メモリ使用量を概算
  static int _estimateMemoryUsage() {
    // 実際の実装では、プラットフォーム固有のAPIを使用
    // ここでは簡易的な概算
    return _weakReferences.length * 1024; // 1KB per reference
  }
  
  /// 弱参照を追加
  static void addWeakReference(Object object) {
    _weakReferences.add(WeakReference(object));
    
    // 定期的にクリーンアップ
    if (_weakReferences.length % 100 == 0) {
      _cleanupWeakReferences();
    }
  }
  
  /// 弱参照をクリーンアップ
  static void _cleanupWeakReferences() {
    _weakReferences.removeWhere((ref) => ref.target == null);
  }
  
  /// メモリ警告回数を取得
  static int getMemoryWarningCount() {
    return _memoryWarningCount;
  }
  
  /// メモリ統計をリセット
  static void reset() {
    _weakReferences.clear();
    _memoryWarningCount = 0;
  }
}

/// メモリ効率的なリストビルダー
class MemoryEfficientListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;
  final double? cacheExtent;
  
  const MemoryEfficientListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
    this.cacheExtent,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // メモリ最適化設定
      cacheExtent: cacheExtent ?? 200.0, // キャッシュ範囲を制限
      addAutomaticKeepAlives: false, // 自動保持を無効化
      addRepaintBoundaries: true, // 再描画境界を追加
      addSemanticIndexes: false, // セマンティックインデックスを無効化
    );
  }
}

/// メモリ効率的なグリッドビルダー
class MemoryEfficientGridView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final ScrollController? controller;
  final bool shrinkWrap;
  
  const MemoryEfficientGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.crossAxisSpacing = 0,
    this.mainAxisSpacing = 0,
    this.controller,
    this.shrinkWrap = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      // メモリ最適化設定
      cacheExtent: 200.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }
}

/// メモリ効率的な画像ウィジェット
class MemoryEfficientImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? cacheWidth;
  final double? cacheHeight;
  
  const MemoryEfficientImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
  });
  
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      // メモリ最適化設定
      cacheWidth: cacheWidth?.toInt(),
      cacheHeight: cacheHeight?.toInt(),
      isAntiAlias: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// メモリ効率的なアニメーション
class MemoryEfficientAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onComplete;
  
  const MemoryEfficientAnimation({
    super.key,
    required this.child,
    required this.duration,
    this.curve = Curves.easeInOut,
    this.onComplete,
  });
  
  @override
  State<MemoryEfficientAnimation> createState() => _MemoryEfficientAnimationState();
}

class _MemoryEfficientAnimationState extends State<MemoryEfficientAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// メモリ最適化されたページビュー
class MemoryEfficientPageView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final PageController? controller;
  final ScrollPhysics? physics;
  
  const MemoryEfficientPageView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.physics,
  });
  
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // メモリ最適化設定
      allowImplicitScrolling: false,
    );
  }
}
