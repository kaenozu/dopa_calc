import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/sound_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundManager', () {
    test('ランク/ビートインデックス → asset マッピング', () {
      final manager = SoundManager();

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
  });
}
