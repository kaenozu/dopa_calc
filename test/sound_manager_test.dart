import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/sound_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SoundManager', () {
    test('standardは従来のランク/ビートマッピングを維持する', () {
      String asset(EffectRank rank, int beatIndex) {
        return SoundManager.assetFor(rank, beatIndex, EffectCue.standard);
      }

      expect(asset(EffectRank.normal, 0), 'tick.wav');
      expect(asset(EffectRank.normal, 1), 'tick.wav');
      expect(asset(EffectRank.chance, 0), 'chance.wav');
      expect(asset(EffectRank.chance, 1), 'impact.wav');
      expect(asset(EffectRank.gekiatsu, 0), 'chance.wav');
      expect(asset(EffectRank.gekiatsu, 1), 'impact.wav');
      expect(asset(EffectRank.premium, 0), 'chance.wav');
      expect(asset(EffectRank.premium, 1), 'chance.wav');
      expect(asset(EffectRank.premium, 2), 'premium.wav');
      expect(asset(EffectRank.premium, 3), 'premium.wav');
    });

    test('EffectCueがビート番号より優先される', () {
      String asset(EffectCue cue) {
        return SoundManager.assetFor(EffectRank.normal, 99, cue);
      }

      expect(asset(EffectCue.preAlert), 'chance.wav');
      expect(asset(EffectCue.symbolLock), 'impact.wav');
      expect(asset(EffectCue.pushPrompt), 'impact.wav');
      expect(asset(EffectCue.shutter), 'impact.wav');
      expect(asset(EffectCue.revival), 'premium.wav');
      expect(asset(EffectCue.jackpot), 'premium.wav');
    });
  });
}
