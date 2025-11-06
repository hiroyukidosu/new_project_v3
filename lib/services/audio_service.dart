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
      
      try {
        await _audioPlayer.play(AssetSource('sounds/${selectedAlarmSound}.mp3'));
        _isPlaying = true;
      } catch (e) {
        // フォールバック: デフォルト音を使用
        try {
          await _audioPlayer.play(AssetSource('sounds/default.mp3'));
          _isPlaying = true;
        } catch (e2) {
          // エラーは無視
        }
      }
    } catch (e) {
      // エラーは無視
    }
  }

  /// 連続バイブレーションを開始
  static Future<void> startContinuousVibration() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        // 即座にバイブレーションを開始
        await Vibration.vibrate(duration: 2000);
        
        // 連続バイブレーション用のタイマー（2秒ごと）
        _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
          if (_isPlaying) {
            try {
              await Vibration.vibrate(duration: 2000);
            } catch (e) {
              // エラーは無視
            }
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      // エラーは無視
    }
  }

  /// アラームを停止
  static Future<void> stopAlarm() async {
    // 1. バイブレーションタイマーを先に停止（即座にキャンセル）
    try {
      _vibrationTimer?.cancel();
      _vibrationTimer = null;
    } catch (e) {
      // エラーは無視
    }
    
    // 2. バイブレーションを停止
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.cancel();
      }
    } catch (e) {
      // エラーは無視
    }
    
    // 3. 音声を停止
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release); // ループを解除
      _isPlaying = false;
    } catch (e) {
      // エラー時も状態をリセット
      _isPlaying = false;
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
  }
}

