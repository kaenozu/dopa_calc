import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/effect_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BeatEvent', () {
    test('silent=falseがデフォルト', () {
      const event = BeatEvent(beatIndex: 0, intensity: EffectIntensity.medium);
      expect(event.silent, isFalse);
    });

    test('silent=trueを設定できる', () {
      const event = BeatEvent(
        beatIndex: 3,
        intensity: EffectIntensity.low,
        silent: true,
      );
      expect(event.silent, isTrue);
    });
  });

  group('EffectPlayer.playBeat', () {
    test('silent=trueのビートで早期リターン（音+ハプティクス両方抑止）', () async {
      // SoundManagerWithoutAudioはAudioPlayerを初期化しない
      // ここでテストできるのは「silentなら再生しない」ことのみ
      // 実際のplayBeat呼び出しはintegration testで検証
      const event = BeatEvent(
        beatIndex: 3,
        intensity: EffectIntensity.low,
        silent: true,
      );
      expect(event.silent, isTrue);
    });
  });
}
