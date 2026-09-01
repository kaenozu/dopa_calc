import 'dart:async';

import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/effect_player.dart';
import 'package:dopa_calc/src/sound_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSoundManager implements SoundManager {
  final List<(EffectRank, int, EffectCue)> playBeatCalls = [];
  var stopCalls = 0;

  @override
  Future<void> playBeat(EffectRank rank, int beatIndex, EffectCue cue) async {
    playBeatCalls.add((rank, beatIndex, cue));
  }

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
    late List<EffectDiagnosticEvent> diagnostics;
    late EffectPlayer player;

    setUp(() {
      fakeSound = _FakeSoundManager();
      fakeHaptics = _FakeHaptics();
      diagnostics = [];
      player = EffectPlayer(
        soundManager: fakeSound,
        haptics: fakeHaptics,
        delay: (_) async {},
        diagnosticSink: diagnostics.add,
      );
    });

    tearDown(() async {
      await player.dispose();
    });

    test('通常ビートで音と強度ハプティクスを再生する', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(beatIndex: 0, intensity: EffectIntensity.medium),
      );

      expect(fakeSound.playBeatCalls, hasLength(1));
      expect(fakeSound.playBeatCalls.single.$1, EffectRank.premium);
      expect(fakeSound.playBeatCalls.single.$2, 0);
      expect(fakeSound.playBeatCalls.single.$3, EffectCue.standard);
      expect(fakeHaptics.calls, ['medium']);
    });

    test('cueをSoundManagerへ渡す', () async {
      await player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 2, intensity: EffectIntensity.high),
        cue: EffectCue.pushPrompt,
      );

      expect(fakeSound.playBeatCalls.single.$3, EffectCue.pushPrompt);
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

    test('診断イベントはSE発火後に実ハプティクス順を記録する', () async {
      await player.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 3, intensity: EffectIntensity.high),
        cue: EffectCue.pushPrompt,
      );

      expect(
        diagnostics.map((event) => (event.kind, event.detail)).toList(),
        [
          (EffectDiagnosticKind.sound, 'play'),
          (EffectDiagnosticKind.haptic, 'medium'),
          (EffectDiagnosticKind.haptic, 'medium'),
          (EffectDiagnosticKind.haptic, 'heavy'),
        ],
      );
      expect(diagnostics.every((event) => event.cue == EffectCue.pushPrompt), isTrue);
      expect(diagnostics.every((event) => event.beatIndex == 3), isTrue);
    });

    test('暗転は再生ではなく停止診断イベントを記録する', () async {
      await player.playBeat(
        EffectRank.premium,
        const BeatEvent(
          beatIndex: 5,
          intensity: EffectIntensity.low,
          silent: true,
        ),
        cue: EffectCue.blackout,
      );

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.kind, EffectDiagnosticKind.control);
      expect(diagnostics.single.detail, 'audio-stop:silent');
      expect(diagnostics.single.cue, EffectCue.blackout);
      expect(diagnostics.single.beatIndex, 5);
    });

    test('cancelPendingで遅延PUSHを途中キャンセルする', () async {
      final delayStarted = Completer<void>();
      final releaseDelay = Completer<void>();
      final cancelPlayer = EffectPlayer(
        soundManager: fakeSound,
        haptics: fakeHaptics,
        delay: (_) {
          if (!delayStarted.isCompleted) delayStarted.complete();
          return releaseDelay.future;
        },
      );
      addTearDown(cancelPlayer.dispose);

      final playing = cancelPlayer.playBeat(
        EffectRank.gekiatsu,
        const BeatEvent(beatIndex: 3, intensity: EffectIntensity.high),
        cue: EffectCue.pushPrompt,
      );
      await delayStarted.future;

      await cancelPlayer.cancelPending();
      releaseDelay.complete();
      await playing;

      expect(fakeHaptics.calls, ['medium']);
      expect(fakeSound.stopCalls, 1);
    });
  });
}
