import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'effect_director.dart';
import 'generated_sound_bank.dart';

@immutable
class SoundProfile {
  const SoundProfile({
    required this.asset,
    this.volume = 1.0,
    this.playbackRate = 1.0,
  });

  final String asset;
  final double volume;
  final double playbackRate;
}

abstract interface class EffectAudioBackend {
  Future<void> stop();

  Future<void> play(Source source, {required double volume});

  Future<void> setPlaybackRate(double playbackRate);

  Future<void> dispose();
}

class _AudioplayersEffectAudioBackend implements EffectAudioBackend {
  _AudioplayersEffectAudioBackend(this._player);

  final AudioPlayer _player;

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> play(Source source, {required double volume}) {
    return _player.play(source, volume: volume);
  }

  @override
  Future<void> setPlaybackRate(double playbackRate) {
    return _player.setPlaybackRate(playbackRate);
  }

  @override
  Future<void> dispose() => _player.dispose();
}

class SoundManager {
  final EffectAudioBackend _backend;
  int _generation = 0;
  bool _disposed = false;

  SoundManager({AudioPlayer? player, EffectAudioBackend? backend})
    : assert(player == null || backend == null),
      _backend =
          backend ?? _AudioplayersEffectAudioBackend(player ?? AudioPlayer()) {
    GeneratedSoundBank.prime();
  }

  Future<void> playBeat(EffectRank rank, int beatIndex, EffectCue cue) async {
    if (_disposed) return;

    if (cue == EffectCue.blackout) {
      await stop();
      return;
    }

    final generation = ++_generation;
    final profile = profileFor(rank, beatIndex, cue);
    final generatedBytes = GeneratedSoundBank.bytesFor(cue);
    final Source source = generatedBytes == null
        ? AssetSource('sounds/${profile.asset}')
        : BytesSource(generatedBytes, mimeType: 'audio/wav');

    try {
      await _backend.stop();
      if (!_isCurrent(generation)) return;

      await _backend.play(source, volume: profile.volume);
      if (!_isCurrent(generation)) return;

      // audioplayers は playbackRate を play/resume 後に設定する仕様。
      // 毎回1.0も含めて設定し、前ビートのrateが残らないようにする。
      await _backend.setPlaybackRate(profile.playbackRate);
    } catch (error, stackTrace) {
      _report(
        error,
        stackTrace,
        context: 'while playing an effect sound',
      );
    }
  }

  Future<void> stop() async {
    if (_disposed) return;

    // await中の旧playBeatを無効化してから実際の停止命令を送る。
    _generation++;
    try {
      await _backend.stop();
    } catch (error, stackTrace) {
      _report(
        error,
        stackTrace,
        context: 'while stopping an effect sound',
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    _generation++;
    try {
      await _backend.stop();
    } catch (error, stackTrace) {
      _report(
        error,
        stackTrace,
        context: 'while stopping an effect sound during dispose',
      );
    }

    try {
      await _backend.dispose();
    } catch (error, stackTrace) {
      _report(
        error,
        stackTrace,
        context: 'while disposing the effect audio backend',
      );
    }
  }

  bool _isCurrent(int generation) {
    return !_disposed && generation == _generation;
  }

  static void _report(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'dopa_calc',
        context: ErrorDescription(context),
      ),
    );
  }

  /// 音声プラグインを初期化せずに検証できる純粋なCue→音響プロファイル。
  static SoundProfile profileFor(
    EffectRank rank,
    int beatIndex,
    EffectCue cue,
  ) {
    switch (cue) {
      case EffectCue.preAlert:
        // 高め・速めで先バレの鋭さを出す。
        return const SoundProfile(
          asset: 'chance.wav',
          volume: 1.0,
          playbackRate: 1.16,
        );
      case EffectCue.symbolLock:
        // 少し低く重くして図柄停止感を出す。
        return const SoundProfile(
          asset: 'impact.wav',
          volume: 0.96,
          playbackRate: 0.90,
        );
      case EffectCue.pushPrompt:
        // PUSH表示に合わせて通常impactよりわずかに鋭くする。
        return const SoundProfile(
          asset: 'impact.wav',
          volume: 1.0,
          playbackRate: 1.06,
        );
      case EffectCue.shutter:
        // 大きな役物が閉じる重量感を優先する。
        return const SoundProfile(
          asset: 'impact.wav',
          volume: 1.0,
          playbackRate: 0.72,
        );
      case EffectCue.blackout:
        // playBeatでも防御的にstopするため実際には再生しない。
        return const SoundProfile(asset: 'tick.wav', volume: 0.0);
      case EffectCue.revival:
        // 暗転明けを重く立ち上げる。
        return const SoundProfile(
          asset: 'premium.wav',
          volume: 1.0,
          playbackRate: 0.88,
        );
      case EffectCue.jackpot:
        // 復活との差を付け、確定時だけ少し速く華やかにする。
        return const SoundProfile(
          asset: 'premium.wav',
          volume: 1.0,
          playbackRate: 1.08,
        );
      case EffectCue.standard:
        return SoundProfile(asset: _standardAssetFor(rank, beatIndex));
    }
  }

  /// 後方互換用。Cue→assetだけが必要なテスト/呼び出し向け。
  static String assetFor(EffectRank rank, int beatIndex, EffectCue cue) {
    return profileFor(rank, beatIndex, cue).asset;
  }

  static String _standardAssetFor(EffectRank rank, int beatIndex) {
    switch (rank) {
      case EffectRank.normal:
        return 'tick.wav';
      case EffectRank.chance:
        return beatIndex == 0 ? 'chance.wav' : 'impact.wav';
      case EffectRank.gekiatsu:
        return beatIndex == 0 ? 'chance.wav' : 'impact.wav';
      case EffectRank.premium:
        return beatIndex >= 2 ? 'premium.wav' : 'chance.wav';
    }
  }
}
