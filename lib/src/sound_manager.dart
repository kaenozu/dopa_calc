import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'effect_director.dart';

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

class SoundManager {
  final AudioPlayer _player;

  SoundManager({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> playBeat(EffectRank rank, int beatIndex, EffectCue cue) async {
    if (cue == EffectCue.blackout) {
      await stop();
      return;
    }

    final profile = profileFor(rank, beatIndex, cue);
    try {
      await _player.stop();
      await _player.play(
        AssetSource('sounds/${profile.asset}'),
        volume: profile.volume,
      );
      // audioplayers は playbackRate を play/resume 後に設定する仕様。
      // 毎回1.0も含めて設定し、前ビートのrateが残らないようにする。
      await _player.setPlaybackRate(profile.playbackRate);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'dopa_calc',
          context: ErrorDescription('while playing an effect sound'),
        ),
      );
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'dopa_calc',
          context: ErrorDescription('while stopping an effect sound'),
        ),
      );
    }
  }

  Future<void> dispose() => _player.dispose();

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
