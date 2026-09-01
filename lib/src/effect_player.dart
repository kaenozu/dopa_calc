import 'package:flutter/services.dart';

import 'effect_director.dart';
import 'sound_manager.dart';

abstract interface class EffectHaptics {
  Future<void> selectionClick();
  Future<void> mediumImpact();
  Future<void> heavyImpact();
  Future<void> vibrate();
}

class SystemEffectHaptics implements EffectHaptics {
  const SystemEffectHaptics();

  @override
  Future<void> selectionClick() => HapticFeedback.selectionClick();

  @override
  Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  @override
  Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  @override
  Future<void> vibrate() => HapticFeedback.vibrate();
}

/// 効果音+ハプティクスを統一管理するプレイヤー。
/// EffectOverlayのビートイベントを1箇所で処理する。
class EffectPlayer {
  EffectPlayer({
    SoundManager? soundManager,
    EffectHaptics? haptics,
    Future<void> Function(Duration duration)? delay,
  }) : _soundManager = soundManager ?? SoundManager(),
       _haptics = haptics ?? const SystemEffectHaptics(),
       _delay = delay ?? Future<void>.delayed;

  final SoundManager _soundManager;
  final EffectHaptics _haptics;
  final Future<void> Function(Duration duration) _delay;

  var _generation = 0;
  var _disposed = false;

  /// ビート発火時に音+ハプティクスを一括トリガーする。
  /// cue ごとに遊技機らしい触覚パターンへ出し分ける。
  Future<void> playBeat(
    EffectRank rank,
    BeatEvent event, {
    EffectCue cue = EffectCue.standard,
  }) async {
    if (_disposed) return;
    final token = ++_generation;

    if (event.silent || cue == EffectCue.blackout) {
      await _soundManager.stop();
      return;
    }

    await _soundManager.playBeat(rank, event.beatIndex, cue: cue);
    if (!_isActive(token)) return;

    await _hapticForCue(cue, event.intensity, token);
  }

  /// SKIPや画面破棄時に、遅延ハプティクスと再生中SEを止める。
  Future<void> cancelPending() async {
    _generation++;
    if (_disposed) return;
    await _soundManager.stop();
  }

  Future<void> _hapticForCue(
    EffectCue cue,
    EffectIntensity intensity,
    int token,
  ) async {
    switch (cue) {
      case EffectCue.standard:
        await _impactFor(intensity);
      case EffectCue.preAlert:
        await _haptics.mediumImpact();
      case EffectCue.symbolLock:
        await _haptics.heavyImpact();
      case EffectCue.pushPrompt:
        await _haptics.mediumImpact();
        if (!await _pause(token, const Duration(milliseconds: 240))) return;
        await _haptics.mediumImpact();
        if (!await _pause(token, const Duration(milliseconds: 240))) return;
        await _haptics.heavyImpact();
      case EffectCue.shutter:
        await _haptics.heavyImpact();
        if (!await _pause(token, const Duration(milliseconds: 150))) return;
        await _haptics.vibrate();
      case EffectCue.blackout:
        return;
      case EffectCue.revival:
        await _haptics.vibrate();
        if (!await _pause(token, const Duration(milliseconds: 120))) return;
        await _haptics.heavyImpact();
      case EffectCue.jackpot:
        await _haptics.vibrate();
        if (!await _pause(token, const Duration(milliseconds: 100))) return;
        await _haptics.heavyImpact();
        if (!await _pause(token, const Duration(milliseconds: 100))) return;
        await _haptics.vibrate();
    }
  }

  Future<bool> _pause(int token, Duration duration) async {
    await _delay(duration);
    return _isActive(token);
  }

  bool _isActive(int token) => !_disposed && token == _generation;

  Future<void> _impactFor(EffectIntensity intensity) async {
    switch (intensity) {
      case EffectIntensity.low:
        await _haptics.selectionClick();
      case EffectIntensity.medium:
        await _haptics.mediumImpact();
      case EffectIntensity.high:
        await _haptics.heavyImpact();
      case EffectIntensity.extreme:
        await _haptics.vibrate();
    }
  }

  /// SoundManagerのアセット名を取得（テスト用）。
  String assetFor(
    EffectRank rank,
    int beatIndex, {
    EffectCue cue = EffectCue.standard,
  }) => _soundManager.assetFor(rank, beatIndex, cue: cue);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    await _soundManager.stop();
    await _soundManager.dispose();
  }
}
