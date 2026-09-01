import 'dart:math';

import 'package:dopa_calc/src/effect_director.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EffectDirector', () {
    test('777は必ずプレミア', () {
      final director = EffectDirector(random: Random(1));
      expect(director.planFor('777').rank, EffectRank.premium);
    });

    test('0は全消灯系の激熱', () {
      final director = EffectDirector(random: Random(1));
      final plan = director.planFor('0');
      expect(plan.rank, EffectRank.gekiatsu);
      expect(plan.beats.first.headline, '全 消 灯');
    });

    test('7, 77, 7777, 8192はプレミア', () {
      final director = EffectDirector(random: Random(0));
      for (final value in const ['7', '77', '7777', '8192']) {
        expect(director.planFor(value).rank, EffectRank.premium);
      }
    });

    test('負の7系はプレミア', () {
      final director = EffectDirector(random: Random(0));
      expect(director.planFor('-7').rank, EffectRank.premium);
    });

    test('ロール0はプレミア（7系以外）', () {
      final director = EffectDirector(nextInt: (_) => 0);
      expect(director.planFor('1').rank, EffectRank.premium);
    });

    test('ロール1-9は激熱', () {
      final director = EffectDirector(nextInt: (_) => 5);
      expect(director.planFor('1').rank, EffectRank.gekiatsu);
    });

    test('ロール10-29はチャンス', () {
      final director = EffectDirector(nextInt: (_) => 25);
      expect(director.planFor('1').rank, EffectRank.chance);
    });

    test('ロール30-99はノーマル', () {
      final director = EffectDirector(nextInt: (_) => 55);
      expect(director.planFor('1').rank, EffectRank.normal);
    });

    test('777 PREMIUMシーケンスは8ビート', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      expect(plan.beats.length, 8);
    });

    test('PREMIUMシーケンスはdisplayRankが段階的に昇格する', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final displayRanks = plan.beats.map((b) => b.displayRank).toList();
      expect(displayRanks, [
        EffectRank.normal,
        EffectRank.chance,
        EffectRank.gekiatsu,
        EffectRank.gekiatsu,
        EffectRank.gekiatsu,
        EffectRank.normal,
        EffectRank.gekiatsu,
        EffectRank.premium,
      ]);
    });

    test('PREMIUMシーケンスはPUSHとシャッターを経てJACKPOTへ進行する', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final cues = plan.beats.map((b) => b.cue).toList();

      expect(cues, [
        EffectCue.standard,
        EffectCue.preAlert,
        EffectCue.symbolLock,
        EffectCue.pushPrompt,
        EffectCue.shutter,
        EffectCue.blackout,
        EffectCue.revival,
        EffectCue.jackpot,
      ]);
    });

    test('有効ランクは視覚・音で同じ昇格順を返す', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final ranks = List.generate(plan.beats.length, plan.rankForBeat);

      expect(ranks, [
        EffectRank.normal,
        EffectRank.chance,
        EffectRank.gekiatsu,
        EffectRank.gekiatsu,
        EffectRank.gekiatsu,
        EffectRank.normal,
        EffectRank.gekiatsu,
        EffectRank.premium,
      ]);
    });

    test('displayRank未指定ならPlanランクを返す', () {
      final director = EffectDirector(nextInt: (_) => 25);
      final plan = director.planFor('1');

      expect(plan.rank, EffectRank.chance);
      expect(plan.rankForBeat(0), EffectRank.chance);
      expect(plan.rankForBeat(1), EffectRank.chance);
    });

    test('PREMIUMシーケンスはシャッター後にdarkビートへ落とす', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final darkBeat = plan.beats[5];
      expect(plan.beats[4].cue, EffectCue.shutter);
      expect(darkBeat.dark, isTrue);
      expect(darkBeat.cue, EffectCue.blackout);
      expect(darkBeat.headline, '…………');
      expect(darkBeat.intensity, EffectIntensity.low);
    });

    test('PREMIUMシーケンスのビートは全てheadlineとsublineを持つ', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      for (final beat in plan.beats) {
        expect(beat.headline.isNotEmpty, isTrue);
        if (!beat.dark) {
          expect(beat.subline.isNotEmpty, isTrue);
        }
      }
    });

    test('PREMIUMシーケンスのintensityはPUSHとシャッターで最大化する', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final intensities = plan.beats.map((b) => b.intensity).toList();
      expect(intensities, [
        EffectIntensity.low,
        EffectIntensity.medium,
        EffectIntensity.high,
        EffectIntensity.high,
        EffectIntensity.extreme,
        EffectIntensity.low,
        EffectIntensity.high,
        EffectIntensity.extreme,
      ]);
    });

    test('PREMIUMシーケンスは8ビート化しても合計9秒を維持する', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      expect(plan.duration, const Duration(milliseconds: 9000));
    });

    test('ランダム1%PREMIUMもPUSH→シャッター→暗転→復活を持つ', () {
      final director = EffectDirector(nextInt: (_) => 0);
      final plan = director.planFor('1');
      expect(plan.rank, EffectRank.premium);
      expect(plan.beats.length, 7);
      expect(plan.beats[2].cue, EffectCue.pushPrompt);
      expect(plan.beats[3].cue, EffectCue.shutter);
      expect(plan.beats[4].dark, isTrue);
      expect(plan.beats[4].cue, EffectCue.blackout);
      expect(plan.beats[5].cue, EffectCue.revival);
      expect(plan.beats.last.displayRank, EffectRank.premium);
      expect(plan.beats.last.cue, EffectCue.jackpot);
    });

    test('激熱にはPUSHがありCHANCEにはPUSHがない', () {
      final gekiatsu = EffectDirector(nextInt: (_) => 5).planFor('1');
      final chance = EffectDirector(nextInt: (_) => 25).planFor('1');

      expect(
        gekiatsu.beats.any((beat) => beat.cue == EffectCue.pushPrompt),
        isTrue,
      );
      expect(
        chance.beats.any((beat) => beat.cue == EffectCue.pushPrompt),
        isFalse,
      );
      expect(
        gekiatsu.beats.any((beat) => beat.cue == EffectCue.shutter),
        isFalse,
      );
    });
  });
}
