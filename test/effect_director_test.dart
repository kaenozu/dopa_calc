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

    test('777 PREMIUMシーケンスは6ビート', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      expect(plan.beats.length, 6);
    });

    test('PREMIUMシーケンスはdisplayRankが段階的に昇格する', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final displayRanks = plan.beats.map((b) => b.displayRank).toList();
      expect(displayRanks, [
        EffectRank.normal,
        EffectRank.chance,
        EffectRank.gekiatsu,
        EffectRank.normal,
        EffectRank.gekiatsu,
        EffectRank.premium,
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

    test('PREMIUMシーケンスの3番目がdarkビート', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final darkBeat = plan.beats[3];
      expect(darkBeat.dark, isTrue);
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

    test('PREMIUMシーケンスのintensityはlow→medium→high→low→high→extreme', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      final intensities = plan.beats.map((b) => b.intensity).toList();
      expect(intensities, [
        EffectIntensity.low,
        EffectIntensity.medium,
        EffectIntensity.high,
        EffectIntensity.low,
        EffectIntensity.high,
        EffectIntensity.extreme,
      ]);
    });

    test('PREMIUMシーケンスの合計時間は正しい', () {
      final director = EffectDirector(nextInt: (_) => 55);
      final plan = director.planFor('777');
      expect(plan.duration, const Duration(milliseconds: 9000));
    });

    test('ランダム1%PREMIUMは5ビートとdarkを持つ', () {
      final director = EffectDirector(nextInt: (_) => 0);
      final plan = director.planFor('1');
      expect(plan.rank, EffectRank.premium);
      expect(plan.beats.length, 5);
      expect(plan.beats[2].dark, isTrue);
      expect(plan.beats.last.displayRank, EffectRank.premium);
    });
  });
}
