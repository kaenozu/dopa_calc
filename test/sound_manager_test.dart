import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/sound_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundManager', () {
    test('standardは従来のランク/ビートマッピングを維持する', () {
      final manager = SoundManager();
      addTearDown(manager.dispose);

      expect(manager.assetFor(EffectRank.normal, 0), 'tick.wav');
      expect(manager.assetFor(EffectRank.normal, 1), 'tick.wav');

      expect(manager.assetFor(EffectRank.chance, 0), 'chance.wav');
      expect(manager.assetFor(EffectRank.chance, 1), 'impact.wav');

      expect(manager.assetFor(EffectRank.gekiatsu, 0), 'chance.wav');
      expect(manager.assetFor(EffectRank.gekiatsu, 1), 'impact.wav');

      expect(manager.assetFor(EffectRank.premium, 0), 'chance.wav');
      expect(manager.assetFor(EffectRank.premium, 1), 'chance.wav');
      expect(manager.assetFor(EffectRank.premium, 2), 'premium.wav');
      expect(manager.assetFor(EffectRank.premium, 3), 'premium.wav');
    });

    test('EffectCueがビート番号より優先される', () {
      final manager = SoundManager();
      addTearDown(manager.dispose);

      expect(
        manager.assetFor(
          EffectRank.normal,
          99,
          cue: EffectCue.preAlert,
        ),
        'chance.wav',
      );
      expect(
        manager.assetFor(
          EffectRank.premium,
          0,
          cue: EffectCue.symbolLock,
        ),
        'impact.wav',
      );
      expect(
        manager.assetFor(
          EffectRank.chance,
          0,
          cue: EffectCue.pushPrompt,
        ),
        'impact.wav',
      );
      expect(
        manager.assetFor(
          EffectRank.normal,
          0,
          cue: EffectCue.shutter,
        ),
        'impact.wav',
      );
      expect(
        manager.assetFor(
          EffectRank.normal,
          0,
          cue: EffectCue.revival,
        ),
        'premium.wav',
      );
      expect(
        manager.assetFor(
          EffectRank.normal,
          0,
          cue: EffectCue.jackpot,
        ),
        'premium.wav',
      );
    });
  });
}
