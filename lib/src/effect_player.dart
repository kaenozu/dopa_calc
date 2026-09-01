import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'effect_director.dart';
import 'sound_manager.dart';

enum EffectDiagnosticKind { sound, haptic, control }

@immutable
class EffectDiagnosticEvent {
  const EffectDiagnosticEvent({
    required this.kind,
    required this.detail,
    this.cue,
    this.beatIndex,
  });

  final EffectDiagnosticKind kind;
  final String detail;
  final EffectCue? cue;
  final int? beatIndex;
}

typedef EffectDiagnosticSink = void Function(EffectDiagnosticEvent event);

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
    this.diagnosticSink,
  }) : _soundManager = soundManager ?? SoundManager(),
       _haptics = haptics ?? const SystemEffectHaptics(),
       _delay = delay ?? Future<void>.delayed;

  final SoundManager _soundManager;
  final EffectHaptics _haptics;
  final Future<void> Function(Duration duration) _delay;
  final EffectDiagnosticSink? diagnosticSink;

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
      _emit(
        EffectDiagnosticKind.control,
        cue: cue,
        beatIndex: event.beatIndex,
        detail: 'audio-stop:silent',
      );
      await _soundManager.stop();
      return;
    }

    _emit(
      EffectDiagnosticKind.sound,
      cue: cue,
      beatIndex: event.beatIndex,
      detail: 'play',
    );
    await _soundManager.playBeat(rank, event.beatIndex, cue);
    if (!_isActive(token)) return;

    await _hapticForCue(cue, event.intensity, event.beatIndex, token);
  }

  /// SKIPや画面破棄時に、遅延ハプティクスと再生中SEを止める。
  Future<void> cancelPending() async {
    _generation++;
    if (_disposed) return;
    _emit(EffectDiagnosticKind.control, detail: 'cancelPending');
    await _soundManager.stop();
  }

  Future<void> _hapticForCue(
    EffectCue cue,
    EffectIntensity intensity,
    int beatIndex,
    int token,
  ) async {
    switch (cue) {
      case EffectCue.standard:
        await _impactFor(intensity, cue, beatIndex);
      case EffectCue.preAlert:
        await _mediumImpact(cue, beatIndex);
      case EffectCue.symbolLock:
        await _heavyImpact(cue, beatIndex);
      case EffectCue.pushPrompt:
        await _mediumImpact(cue, beatIndex);
        if (!await _pause(token, const Duration(milliseconds: 240))) return;
        await _mediumImpact(cue, beatIndex);
        if (!await _pause(token, const Duration(milliseconds: 240))) return;
        await _heavyImpact(cue, beatIndex);
      case EffectCue.shutter:
        await _heavyImpact(cue, beatIndex);
        if (!await _pause(token, const Duration(milliseconds: 150))) return;
        await _vibrate(cue, beatIndex);
      case EffectCue.blackout:
        return;
      case EffectCue.revival:
        await _vibrate(cue, beatIndex);
        if (!await _pause(token, const Duration(milliseconds: 120))) return;
        await _heavyImpact(cue, beatIndex);
      case EffectCue.jackpot:
        await _vibrate(cue, beatIndex);
        if (!await _pause(token, const Duration(milliseconds: 100))) return;
        await _heavyImpact(cue, beatIndex);
        if (!await _pause(token, const Duration(milliseconds: 100))) return;
        await _vibrate(cue, beatIndex);
    }
  }

  Future<bool> _pause(int token, Duration duration) async {
    await _delay(duration);
    return _isActive(token);
  }

  bool _isActive(int token) => !_disposed && token == _generation;

  Future<void> _impactFor(
    EffectIntensity intensity,
    EffectCue cue,
    int beatIndex,
  ) async {
    switch (intensity) {
      case EffectIntensity.low:
        await _selectionClick(cue, beatIndex);
      case EffectIntensity.medium:
        await _mediumImpact(cue, beatIndex);
      case EffectIntensity.high:
        await _heavyImpact(cue, beatIndex);
      case EffectIntensity.extreme:
        await _vibrate(cue, beatIndex);
    }
  }

  Future<void> _selectionClick(EffectCue cue, int beatIndex) {
    _emit(
      EffectDiagnosticKind.haptic,
      cue: cue,
      beatIndex: beatIndex,
      detail: 'selection',
    );
    return _haptics.selectionClick();
  }

  Future<void> _mediumImpact(EffectCue cue, int beatIndex) {
    _emit(
      EffectDiagnosticKind.haptic,
      cue: cue,
      beatIndex: beatIndex,
      detail: 'medium',
    );
    return _haptics.mediumImpact();
  }

  Future<void> _heavyImpact(EffectCue cue, int beatIndex) {
    _emit(
      EffectDiagnosticKind.haptic,
      cue: cue,
      beatIndex: beatIndex,
      detail: 'heavy',
    );
    return _haptics.heavyImpact();
  }

  Future<void> _vibrate(EffectCue cue, int beatIndex) {
    _emit(
      EffectDiagnosticKind.haptic,
      cue: cue,
      beatIndex: beatIndex,
      detail: 'vibrate',
    );
    return _haptics.vibrate();
  }

  void _emit(
    EffectDiagnosticKind kind, {
    required String detail,
    EffectCue? cue,
    int? beatIndex,
  }) {
    diagnosticSink?.call(
      EffectDiagnosticEvent(
        kind: kind,
        detail: detail,
        cue: cue,
        beatIndex: beatIndex,
      ),
    );
  }

  /// asset選択の確認はAudioPlayerを生成せず純粋関数で行う。
  static String assetFor(
    EffectRank rank,
    int beatIndex, {
    EffectCue cue = EffectCue.standard,
  }) => SoundManager.assetFor(rank, beatIndex, cue);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    await _soundManager.stop();
    await _soundManager.dispose();
  }
}
