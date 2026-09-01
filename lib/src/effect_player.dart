import 'package:flutter/services.dart';

import 'effect_director.dart';
import 'sound_manager.dart';

/// ビートイベントの情報。
class BeatEvent {
  const BeatEvent({
    required this.beatIndex,
    required this.intensity,
    this.silent = false,
  });

  final int beatIndex;
  final EffectIntensity intensity;

  /// trueのとき、音+ハプティクスを両方抑止する（暗転ビート用）。
  final bool silent;
}

/// 効果音+ハプティクスを統一管理するプレイヤー。
/// EffectOverlayのビートイベントを1箇所で処理する。
class EffectPlayer {
  EffectPlayer({SoundManager? soundManager})
    : _soundManager = soundManager ?? SoundManager();

  final SoundManager _soundManager;

  /// ビート発火時に音+ハプティクスを一括トリガーする。
  Future<void> playBeat(EffectRank rank, BeatEvent event) async {
    if (event.silent) return;
    await _soundManager.playBeat(rank, event.beatIndex);
    await _impactFor(event.intensity);
  }

  Future<void> _impactFor(EffectIntensity intensity) async {
    switch (intensity) {
      case EffectIntensity.low:
        await HapticFeedback.selectionClick();
      case EffectIntensity.medium:
        await HapticFeedback.mediumImpact();
      case EffectIntensity.high:
        await HapticFeedback.heavyImpact();
      case EffectIntensity.extreme:
        await HapticFeedback.vibrate();
    }
  }

  /// SoundManagerのアセット名を取得（テスト用）。
  String assetFor(EffectRank rank, int beatIndex) =>
      _soundManager.assetFor(rank, beatIndex);

  Future<void> dispose() => _soundManager.dispose();
}
