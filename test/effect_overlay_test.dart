import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/effect_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EffectPlan _premiumPlan() {
  return const EffectPlan(
    rank: EffectRank.premium,
    beats: [
      EffectBeat(
        headline: 'ドパ計算RUSH',
        subline: '答えは最初から決まっている',
        duration: Duration(seconds: 5),
        intensity: EffectIntensity.extreme,
      ),
    ],
  );
}

Widget _testApp({required bool disableAnimations}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 640),
        disableAnimations: disableAnimations,
      ),
      child: Scaffold(
        body: Stack(
          children: [
            EffectOverlay(
              plan: _premiumPlan(),
              pulse: const AlwaysStoppedAnimation<double>(1),
              onBeat: (_) {},
              onSkip: () {},
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('360x640でもPREMIUM演出がoverflowしない', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp(disableAnimations: false));
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.textContaining('PREMIUM RUSH'), findsOneWidget);
    expect(find.text('ドパ計算RUSH'), findsWidgets);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disableAnimationsでは常時アニメーションを停止する', (tester) async {
    await tester.pumpWidget(_testApp(disableAnimations: true));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
