import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// 画像最適化機能 - メモリ効率とパフォーマンス向上
class ImageOptimization {
  /// 最適化されたアセット画像
  static Widget buildOptimizedAssetImage({
    required String assetPath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth,
    int? cacheHeight,
    Color? color,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      color: color,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        Logger.warning('画像読み込みエラー: $assetPath - $error');
        return errorWidget ?? _buildDefaultErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildDefaultPlaceholder();
      },
    );
  }
  
  /// 最適化されたネットワーク画像
  static Widget buildOptimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth,
    int? cacheHeight,
    Color? color,
    Widget? placeholder,
    Widget? errorWidget,
    Duration fadeInDuration = const Duration(milliseconds: 300),
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      color: color,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: fadeInDuration,
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        Logger.warning('ネットワーク画像読み込みエラー: $imageUrl - $error');
        return errorWidget ?? _buildDefaultErrorWidget();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildDefaultPlaceholder();
      },
    );
  }
  
  /// アイコン最適化（アセット画像の代替）
  static Widget buildOptimizedIcon({
    required IconData icon,
    double? size,
    Color? color,
    String? semanticLabel,
  }) {
    return Icon(
      icon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
  
  /// アバター画像最適化
  static Widget buildOptimizedAvatar({
    String? imagePath,
    String? imageUrl,
    double radius = 20,
    Color? backgroundColor,
    Color? foregroundColor,
    Widget? child,
    IconData? fallbackIcon,
  }) {
    if (imagePath != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: ClipOval(
          child: buildOptimizedAssetImage(
            assetPath: imagePath,
            width: radius * 2,
            height: radius * 2,
            cacheWidth: (radius * 2).round(),
            cacheHeight: (radius * 2).round(),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (imageUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: ClipOval(
          child: buildOptimizedNetworkImage(
            imageUrl: imageUrl,
            width: radius * 2,
            height: radius * 2,
            cacheWidth: (radius * 2).round(),
            cacheHeight: (radius * 2).round(),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: child ?? Icon(fallbackIcon ?? Icons.person),
      );
    }
  }
  
  /// カード画像最適化
  static Widget buildOptimizedCardImage({
    required String imagePath,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    BoxFit fit = BoxFit.cover,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: buildOptimizedAssetImage(
        assetPath: imagePath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width?.round(),
        cacheHeight: height?.round(),
      ),
    );
  }
  
  /// リスト画像最適化
  static Widget buildOptimizedListImage({
    required String imagePath,
    double size = 50,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: buildOptimizedAssetImage(
        assetPath: imagePath,
        width: size,
        height: size,
        cacheWidth: size.round(),
        cacheHeight: size.round(),
        fit: BoxFit.cover,
      ),
    );
  }
  
  /// デフォルトエラーウィジェット
  static Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.error_outline,
        color: Colors.grey,
        size: 24,
      ),
    );
  }
  
  /// デフォルトプレースホルダー
  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// 画像キャッシュ管理
class ImageCacheManager {
  static const int _maxCacheSize = 100; // MB
  static const int _maxCacheObjects = 1000;
  
  /// キャッシュサイズの取得
  static int getCurrentCacheSize() {
    return ImageCache.instance.currentSizeBytes;
  }
  
  /// キャッシュオブジェクト数の取得
  static int getCurrentCacheObjects() {
    return ImageCache.instance.currentSize;
  }
  
  /// キャッシュの最適化
  static void optimizeCache() {
    final currentSize = getCurrentCacheSize();
    final currentObjects = getCurrentCacheObjects();
    
    Logger.info('現在のキャッシュサイズ: ${currentSize / 1024 / 1024:.2f}MB');
    Logger.info('現在のキャッシュオブジェクト数: $currentObjects');
    
    // キャッシュサイズが大きすぎる場合
    if (currentSize > _maxCacheSize * 1024 * 1024) {
      Logger.warning('キャッシュサイズが大きすぎます。クリアします。');
      clearCache();
    }
    
    // キャッシュオブジェクト数が多すぎる場合
    if (currentObjects > _maxCacheObjects) {
      Logger.warning('キャッシュオブジェクト数が多すぎます。クリアします。');
      clearCache();
    }
  }
  
  /// キャッシュのクリア
  static void clearCache() {
    ImageCache.instance.clear();
    Logger.info('画像キャッシュをクリアしました');
  }
  
  /// 特定の画像をキャッシュから削除
  static void evictFromCache(String imageUrl) {
    ImageCache.instance.evict(imageUrl);
    Logger.debug('画像をキャッシュから削除: $imageUrl');
  }
  
  /// メモリ使用量の監視
  static void monitorMemoryUsage() {
    final size = getCurrentCacheSize();
    final objects = getCurrentCacheObjects();
    
    Logger.performance('画像キャッシュ: ${size / 1024 / 1024:.2f}MB, $objects個のオブジェクト');
    
    if (size > _maxCacheSize * 1024 * 1024 * 0.8) {
      Logger.warning('画像キャッシュの使用量が高いです: ${size / 1024 / 1024:.2f}MB');
      optimizeCache();
    }
  }
}

/// 画像プリローダー
class ImagePreloader {
  static final Set<String> _preloadedImages = {};
  
  /// 画像のプリロード
  static Future<void> preloadImage(String imagePath) async {
    if (_preloadedImages.contains(imagePath)) return;
    
    try {
      await precacheImage(AssetImage(imagePath), _getCurrentContext());
      _preloadedImages.add(imagePath);
      Logger.debug('画像プリロード完了: $imagePath');
    } catch (e) {
      Logger.warning('画像プリロードエラー: $imagePath - $e');
    }
  }
  
  /// 複数画像のプリロード
  static Future<void> preloadImages(List<String> imagePaths) async {
    final futures = imagePaths.map((path) => preloadImage(path));
    await Future.wait(futures);
    Logger.info('複数画像プリロード完了: ${imagePaths.length}件');
  }
  
  /// プリロード済み画像のクリア
  static void clearPreloadedImages() {
    _preloadedImages.clear();
    Logger.info('プリロード済み画像をクリアしました');
  }
  
  /// 現在のコンテキストを取得（実装は必要に応じて）
  static BuildContext _getCurrentContext() {
    // 実際の実装では、適切なBuildContextを取得する必要があります
    throw UnimplementedError('BuildContextの取得が必要です');
  }
}
