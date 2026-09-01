import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'effect_director.dart';

class SoundManager {
  final AudioPlayer _player;

  SoundManager({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> playBeat(
    EffectRank rank,
    int beatIndex, {
    EffectCue cue = EffectCue.standard,
  }) async {
    final asset = _assetFor(rank, beatIndex, cue: cue);
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$asset'));
    } catch (error, stackTrace) {
      _reportPlaybackError(error, stackTrace, 'while playing an effect sound');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (error, stackTrace) {
      _reportPlaybackError(error, stackTrace, 'while stopping an effect sound');
    }
  }

  Future<void> dispose() => _player.dispose();

  String assetFor(
    EffectRank rank,
    int beatIndex, {
    EffectCue cue = EffectCue.standard,
  }) => _assetFor(rank, beatIndex, cue: cue);

  String _assetFor(
    EffectRank rank,
    int beatIndex, {
    required EffectCue cue,
  }) {
    switch (cue) {
      case EffectCue.preAlert:
        return 'chance.wav';
      case EffectCue.symbolLock:
      case EffectCue.pushPrompt:
      case EffectCue.shutter:
        return 'impact.wav';
      case EffectCue.revival:
      case EffectCue.jackpot:
        return 'premium.wav';
      case EffectCue.blackout:
        // blackout は EffectPlayer 側で再生自体を抑止する。
        return 'tick.wav';
      case EffectCue.standard:
        break;
    }

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

  void _reportPlaybackError(
    Object error,
    StackTrace stackTrace,
    String context,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'dopa_calc',
        context: ErrorDescription(context),
      ),
    );
  }
}
