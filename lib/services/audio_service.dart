// lib/services/audio_service.dart
// 音声・バイブレーション管理サービス

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';

/// オーディオサービス
class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Timer? _vibrationTimer;
  static bool _isPlaying = false;

  /// アラーム音を再生
  static Future<void> playAlarmSound({
    required String selectedAlarmSound,
    required int notificationVolume,
  }) async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(notificationVolume / 100.0);
      
      String soundFile = 'assets/sounds/${selectedAlarmSound}.mp3';
      debugPrint('🔊 アラーム音再生開始: $soundFile');
      
      try {
        await _audioPlayer.play(AssetSource('sounds/${selectedAlarmSound}.mp3'));
        _isPlaying = true;
        debugPrint('✅ アラーム音再生成功');
      } catch (e) {
        debugPrint('❌ アラーム音ファイル再生エラー: $e');
        // フォールバック: デフォルト音を使用
        try {
          await _audioPlayer.play(AssetSource('sounds/default.mp3'));
          _isPlaying = true;
          debugPrint('✅ デフォルト音再生開始');
        } catch (e2) {
          debugPrint('❌ デフォルト音再生エラー: $e2');
        }
      }
    } catch (e) {
      debugPrint('❌ アラーム音設定エラー: $e');
    }
  }

  /// 連続バイブレーションを開始
  static Future<void> startContinuousVibration() async {
    debugPrint('📳 連続バイブレーション開始');
    try {
      if (await Vibration.hasVibrator() == true) {
        debugPrint('✅ バイブレーション機能有効');
        // 即座にバイブレーションを開始
        await Vibration.vibrate(duration: 2000);
        
        // 連続バイブレーション用のタイマー（2秒ごと）
        _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
          if (_isPlaying) {
            debugPrint('📳 バイブレーション実行');
            try {
              await Vibration.vibrate(duration: 2000);
            } catch (e) {
              debugPrint('❌ バイブレーションエラー: $e');
            }
          } else {
            timer.cancel();
            debugPrint('📳 バイブレーション停止（アラーム停止）');
          }
        });
      } else {
        debugPrint('⚠️ バイブレーション機能利用不可');
      }
    } catch (e) {
      debugPrint('❌ バイブレーション初期化エラー: $e');
    }
  }

  /// アラームを停止
  static Future<void> stopAlarm() async {
    debugPrint('⏹️ アラーム停止開始');
    
    try {
      // 音声を停止
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('✅ 音声停止完了');
    } catch (e) {
      debugPrint('❌ 音声停止エラー: $e');
    }
    
    try {
      // バイブレーションタイマーを停止
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
      debugPrint('✅ バイブレーション停止完了');
    } catch (e) {
      debugPrint('❌ バイブレーション停止エラー: $e');
    }
  }

  /// 再生中かどうか
  static bool get isPlaying => _isPlaying;

  /// クリーンアップ
  static void dispose() {
    _audioPlayer.dispose();
    _vibrationTimer?.cancel();
    _vibrationTimer = null;
    _isPlaying = false;
    debugPrint('✅ AudioService dispose完了');
  }
}

