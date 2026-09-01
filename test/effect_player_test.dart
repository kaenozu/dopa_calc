import 'dart:async';

import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/effect_player.dart';
import 'package:dopa_calc/src/sound_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// playBeat/stop/dispose の呼び出しを記録する SoundManager の偽者。
/// AudioPlayer を初期化しない。
class _FakeSoundManager implements SoundManager {
  final List<(EffectRank, int, EffectCue)> playBeatCalls = [];
  var stopCalls = 0;

  @override
  Future<void> playBeat(
    EffectRank rank,
    int beatIndex, {
    EffectCue cue = EffectCue.standard,
  }) async {
    playBeatCalls.add((rank, beatIndex, cue));
  }

  @override
  String assetFor(
    EffectRank rank,
    int beatIndex, {
    EffectCue cue = EffectCue.standard,
  }) => '';

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeHaptics implements EffectHaptics {
  final List<String> calls = [];

  @override
  Future<void> selectionClick() async => calls.add('selection');

  @override
  Future<void> mediumImpact() async => calls.add('medium');

  @override
  Future<void> heavyImpact() async => calls.add('heavy');

  @override
  Future<void> vibrate() async => calls.add('vibrate');
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
    late _FakeSoundManager fakeSound;
    late _FakeHaptics fakeHaptics;
    late EffectPlayer player;

    setUp(() {
      fakeSound = _FakeSoundManager();
      fakeHaptics = _FakeHaptics();
      player = EffectPlayer(
        soundManager: fakeSound,
        haptics: fakeHaptics,
        delay: (_) async {},
      );
    });

    tearDown(() async {
      await player.dispose();
    });

    test('通常ビートで SoundManager.playBeat が呼ばれる', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(beatIndex: 0, intensity: EffectIntensity.medium),
      );

      expect(fakeSound.playBeatCalls, hasLength(1));
      expect(
        fakeSound.playBeatCalls.first,
        (EffectRank.premium, 0, EffectCue.standard),
      );
      expect(fakeHaptics.calls, ['medium']);
    });

    test('cueをSoundManagerへ渡す', () async {
      await player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 2, intensity: EffectIntensity.high),
        cue: EffectCue.pushPrompt,
      );

      expect(
        fakeSound.playBeatCalls.single,
        (EffectRank.gekiatsu, 2, EffectCue.pushPrompt),
      );
    });

    test('silent=true で音とハプティクスを止める', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(
          beatIndex: 5,
          intensity: EffectIntensity.low,
          silent: true,
        ),
        cue: EffectCue.blackout,
      );

      expect(fakeSound.playBeatCalls, isEmpty);
      expect(fakeSound.stopCalls, 1);
      expect(fakeHaptics.calls, isEmpty);
    });

    test('PUSHは中→中→強の3段ハプティクス', () async {
      await player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 3, intensity: EffectIntensity.high),
        cue: EffectCue.pushPrompt,
      );

      expect(fakeHaptics.calls, ['medium', 'medium', 'heavy']);
    });

    test('シャッターは強→長振動', () async {
      await player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 4, intensity: EffectIntensity.extreme),
        cue: EffectCue.shutter,
      );

      expect(fakeHaptics.calls, ['heavy', 'vibrate']);
    });

    test('復活は長振動→強', () async {
      await player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 6, intensity: EffectIntensity.high),
        cue: EffectCue.revival,
      );

      expect(fakeHaptics.calls, ['vibrate', 'heavy']);
    });

    test('JACKPOTは長→強→長の3段ハプティクス', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(beatIndex: 7, intensity: EffectIntensity.extreme),
        cue: EffectCue.jackpot,
      );

      expect(fakeHaptics.calls, ['vibrate', 'heavy', 'vibrate']);
    });

    test('SKIP相当のcancelPendingで遅延PUSHを途中キャンセルする', () async {
      final delayStarted = Completer<void>();
      final releaseDelay = Completer<void>();
      player = EffectPlayer(
        soundManager: fakeSound,
        haptics: fakeHaptics,
        delay: (_) {
          if (!delayStarted.isCompleted) delayStarted.complete();
          return releaseDelay.future;
        },
      );

      final playing = player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 3, intensity: EffectIntensity.high),
        cue: EffectCue.pushPrompt,
      );
      await delayStarted.future;

      await player.cancelPending();
      releaseDelay.complete();
      await playing;

      expect(fakeHaptics.calls, ['medium']);
      expect(fakeSound.stopCalls, 1);
    });
  });
}
