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
  });
}
