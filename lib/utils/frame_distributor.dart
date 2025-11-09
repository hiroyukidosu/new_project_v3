// lib/utils/frame_distributor.dart
// 重い処理を複数フレームに分散するヘルパー

import 'package:flutter/scheduler.dart';

/// フレーム分散ヘルパー
/// 重い処理を複数フレームに分散して、UIスレッドをブロックしない
class FrameDistributor {
  /// リストの処理をフレーム分散
  static Future<void> processList<T>(
    List<T> items,
    Future<void> Function(T item) processor, {
    int itemsPerFrame = 10,
  }) async {
    for (int i = 0; i < items.length; i++) {
      await processor(items[i]);
      
      // 一定数のアイテム処理ごとにUIスレッドに制御を返す
      if (i > 0 && i % itemsPerFrame == 0) {
        await Future.delayed(Duration.zero);
        // 次のフレームまで待機
        await SchedulerBinding.instance.endOfFrame;
      }
    }
  }

  /// 重い処理をフレーム分散
  static Future<T> processInFrames<T>(
    Future<T> Function() task,
  ) async {
    // 現在のフレームが終了するまで待機
    await SchedulerBinding.instance.endOfFrame;
    // タスクを実行
    return await task();
  }

  /// バッチ処理をフレーム分散
  static Future<void> processBatch<T>(
    List<T> items,
    Future<void> Function(List<T> batch) processor, {
    int batchSize = 10,
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);
      
      await processor(batch);
      
      // バッチ処理ごとにUIスレッドに制御を返す
      await Future.delayed(Duration.zero);
      await SchedulerBinding.instance.endOfFrame;
    }
  }
}

