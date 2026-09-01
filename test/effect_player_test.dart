import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/effect_player.dart';
import 'package:dopa_calc/src/sound_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// playBeat/dispose の呼び出しを記録する SoundManager の偽者。
/// AudioPlayer を初期化しない。
class _FakeSoundManager implements SoundManager {
  final List<(EffectRank, int)> playBeatCalls = [];

  @override
  Future<void> playBeat(EffectRank rank, int beatIndex) async {
    playBeatCalls.add((rank, beatIndex));
  }

  @override
  String assetFor(EffectRank rank, int beatIndex) => '';

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BeatEvent', () {
    test('silent=false がデフォルト', () {
      const event = BeatEvent(beatIndex: 0, intensity: EffectIntensity.medium);
      expect(event.silent, isFalse);
    });

    test('silent=true を設定できる', () {
      const event = BeatEvent(
        beatIndex: 3,
        intensity: EffectIntensity.low,
        silent: true,
      );
      expect(event.silent, isTrue);
    });
  });

  group('EffectPlayer.playBeat', () {
    late _FakeSoundManager fake;
    late EffectPlayer player;

    setUp(() {
      fake = _FakeSoundManager();
      player = EffectPlayer(soundManager: fake);
    });

    tearDown(() async {
      await player.dispose();
    });

    test('通常ビートで SoundManager.playBeat が呼ばれる', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(beatIndex: 0, intensity: EffectIntensity.medium),
      );

      expect(fake.playBeatCalls, hasLength(1));
      expect(fake.playBeatCalls.first, (EffectRank.premium, 0));
    });

    test('silent=true で SoundManager.playBeat が呼ばれない', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(
          beatIndex: 3,
          intensity: EffectIntensity.low,
          silent: true,
        ),
      );

      expect(fake.playBeatCalls, isEmpty);
    });

    test('複数ビートで silent 以外は全て呼ばれる', () async {
      await player.playBeat(
        EffectRank.chance,
        const BeatEvent(beatIndex: 0, intensity: EffectIntensity.high),
      );
      await player.playBeat(
        EffectRank.chance,
        const BeatEvent(
          beatIndex: 1,
          intensity: EffectIntensity.low,
          silent: true,
        ),
      );
      await player.playBeat(
        EffectRank.chance,
        const BeatEvent(beatIndex: 2, intensity: EffectIntensity.extreme),
      );

      // 0番目と2番目は呼ばれ、1番目(silent)は呼ばれない
      expect(fake.playBeatCalls, hasLength(2));
      expect(fake.playBeatCalls[0], (EffectRank.chance, 0));
      expect(fake.playBeatCalls[1], (EffectRank.chance, 2));
    });
  });
}
