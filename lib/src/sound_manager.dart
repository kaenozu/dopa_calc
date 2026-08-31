import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'effect_director.dart';

class SoundManager {
  final AudioPlayer _player;

  SoundManager({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> playBeat(EffectRank rank, int beatIndex) async {
    final asset = _assetFor(rank, beatIndex);
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$asset'));
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

  Future<void> dispose() => _player.dispose();

  String assetFor(EffectRank rank, int beatIndex) => _assetFor(rank, beatIndex);

  String _assetFor(EffectRank rank, int beatIndex) {
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
