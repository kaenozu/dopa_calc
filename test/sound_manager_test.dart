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

    test('Cueごとに速度/音量プロファイルを分離する', () {
      SoundProfile profile(EffectCue cue) {
        return SoundManager.profileFor(EffectRank.premium, 7, cue);
      }

      expect(profile(EffectCue.standard).playbackRate, 1.0);
      expect(profile(EffectCue.preAlert).playbackRate, 1.16);
      expect(profile(EffectCue.symbolLock).playbackRate, 0.90);
      expect(profile(EffectCue.pushPrompt).playbackRate, 1.06);
      expect(profile(EffectCue.shutter).playbackRate, 0.72);
      expect(profile(EffectCue.revival).playbackRate, 0.88);
      expect(profile(EffectCue.jackpot).playbackRate, 1.08);

      expect(profile(EffectCue.symbolLock).volume, 0.96);
      expect(profile(EffectCue.blackout).volume, 0.0);
    });

    test('全プロファイルは安全なvolume/playbackRate範囲に収まる', () {
      for (final cue in EffectCue.values) {
        final profile = SoundManager.profileFor(EffectRank.premium, 7, cue);
        expect(profile.volume, inInclusiveRange(0.0, 1.0), reason: '$cue');
        expect(
          profile.playbackRate,
          inInclusiveRange(0.5, 2.0),
          reason: '$cue',
        );
      }
    });

    test('復活とJACKPOTは同じ素材でも速度差を持つ', () {
      final revival = SoundManager.profileFor(
        EffectRank.premium,
        6,
        EffectCue.revival,
      );
      final jackpot = SoundManager.profileFor(
        EffectRank.premium,
        7,
        EffectCue.jackpot,
      );

      expect(revival.asset, 'premium.wav');
      expect(jackpot.asset, 'premium.wav');
      expect(revival.playbackRate, lessThan(1.0));
      expect(jackpot.playbackRate, greaterThan(1.0));
    });
  });
}
