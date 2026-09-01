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

EffectPlan _planWithDarkBeat() {
  return const EffectPlan(
    rank: EffectRank.premium,
    beats: [
      EffectBeat(
        headline: 'テスト',
        subline: '',
        duration: Duration(milliseconds: 500),
        intensity: EffectIntensity.medium,
      ),
      EffectBeat(
        headline: '…………',
        subline: '',
        duration: Duration(milliseconds: 500),
        intensity: EffectIntensity.low,
        dark: true,
      ),
    ],
  );
}

Widget _testApp({
  required EffectPlan plan,
  required bool disableAnimations,
  String? resultText,
  VoidCallback? onSkip,
}) {
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
              plan: plan,
              pulse: const AlwaysStoppedAnimation<double>(1),
              onBeat: (_) {},
              onSkip: onSkip ?? () {},
              resultText: resultText,
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

    await tester.pumpWidget(
      _testApp(plan: _premiumPlan(), disableAnimations: false),
    );
    await tester.pump(const Duration(milliseconds: 32));

    expect(find.textContaining('PREMIUM RUSH'), findsOneWidget);
    expect(find.text('ドパ計算RUSH'), findsWidgets);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disableAnimationsでは常時アニメーションを停止する', (tester) async {
    await tester.pumpWidget(
      _testApp(plan: _premiumPlan(), disableAnimations: true),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resultTextがある場合、最後のビート後に結果を1.5秒表示してonSkipが呼ばれる', (tester) async {
    var skipCalled = false;
    final plan = EffectPlan(
      rank: EffectRank.premium,
      beats: [
        const EffectBeat(
          headline: 'テスト',
          subline: '',
          duration: Duration(milliseconds: 100),
          intensity: EffectIntensity.low,
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        plan: plan,
        disableAnimations: true,
        resultText: '42',
        onSkip: () => skipCalled = true,
      ),
    );

    // ビート100ms経過
    await tester.pump(const Duration(milliseconds: 150));

    // 結果が表示される
    expect(find.text('42'), findsOneWidget);
    expect(skipCalled, isFalse);

    // 1.5秒待つ
    await tester.pump(const Duration(milliseconds: 1500));

    // onSkipが呼ばれる
    expect(skipCalled, isTrue);
  });

  testWidgets('resultTextがnullの場合、最後のビート後に即時onSkipが呼ばれる', (tester) async {
    var skipCalled = false;
    final plan = EffectPlan(
      rank: EffectRank.normal,
      beats: [
        const EffectBeat(
          headline: 'テスト',
          subline: '',
          duration: Duration(milliseconds: 100),
          intensity: EffectIntensity.low,
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        plan: plan,
        disableAnimations: true,
        onSkip: () => skipCalled = true,
      ),
    );

    // ビート100ms経過
    await tester.pump(const Duration(milliseconds: 150));

    // 即時onSkip
    expect(skipCalled, isTrue);
  });

  testWidgets('darkビートではヘッドラインカードが最小表示になる', (tester) async {
    await tester.pumpWidget(
      _testApp(plan: _planWithDarkBeat(), disableAnimations: true),
    );

    // 1ビート目（darkではない）
    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text('テスト'), findsWidgets);

    // 2ビート目（dark）
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('…………'), findsWidgets);

    expect(tester.takeException(), isNull);
  });
}
