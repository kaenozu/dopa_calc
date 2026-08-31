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
  });
}
