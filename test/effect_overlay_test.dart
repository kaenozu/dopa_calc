import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/effect_overlay.dart';
import 'package:dopa_calc/src/effect_widgets.dart';
import 'package:dopa_calc/src/pachinko_cinematic_widgets.dart';
import 'package:dopa_calc/src/pachinko_machine_widgets.dart';
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
        cue: EffectCue.jackpot,
        visualState: EffectVisualState(
          holdStage: HoldStage.rainbow,
          pseudoCount: 3,
          lockedSymbols: 3,
          symbolStyle: SymbolStyle.seven,
          revealState: RevealState.confirmed,
        ),
      ),
    ],
  );
}

EffectPlan _pushPlan() {
  return const EffectPlan(
    rank: EffectRank.gekiatsu,
    beats: [
      EffectBeat(
        headline: '押 せ',
        subline: 'PUSHで運命を決めろ',
        duration: Duration(milliseconds: 900),
        intensity: EffectIntensity.high,
        cue: EffectCue.pushPrompt,
      ),
    ],
  );
}

EffectPlan _shutterPlan() {
  return const EffectPlan(
    rank: EffectRank.premium,
    beats: [
      EffectBeat(
        headline: '役 物 閉 鎖',
        subline: '逃げ道を封鎖しています',
        duration: Duration(milliseconds: 650),
        intensity: EffectIntensity.extreme,
        cue: EffectCue.shutter,
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
        cue: EffectCue.preAlert,
      ),
      EffectBeat(
        headline: '…………',
        subline: '',
        duration: Duration(milliseconds: 500),
        intensity: EffectIntensity.low,
        cue: EffectCue.blackout,
        dark: true,
      ),
    ],
  );
}

EffectPlan _shortPlan() {
  return const EffectPlan(
    rank: EffectRank.premium,
    beats: [
      EffectBeat(
        headline: 'テスト',
        subline: '',
        duration: Duration(milliseconds: 100),
        intensity: EffectIntensity.extreme,
        cue: EffectCue.jackpot,
      ),
    ],
  );
}

EffectPlan _shortPlanForRank(EffectRank rank) {
  return EffectPlan(
    rank: rank,
    beats: const [
      EffectBeat(
        headline: 'テスト',
        subline: '',
        duration: Duration(milliseconds: 100),
        intensity: EffectIntensity.medium,
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
    expect(find.text('DOPA HEAT'), findsOneWidget);
    expect(find.byType(PachinkoMachineOverlay), findsOneWidget);
    expect(find.byType(PachinkoCinematicOverlay), findsOneWidget);
    expect(find.text('777 JACKPOT'), findsOneWidget);
    expect(find.text('JACKPOT'), findsOneWidget);
    expect(find.byKey(const Key('pachinko-revival-burst')), findsOneWidget);
    expect(find.byKey(const Key('pachinko-jackpot-sequence')), findsOneWidget);
    expect(find.byKey(const Key('hold-stage-rainbow')), findsOneWidget);
    expect(find.byKey(const Key('pseudo-count-3')), findsOneWidget);
    expect(find.byKey(const Key('reveal-state-confirmed')), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('期待度状態が青→緑→赤へ画面上でも昇格する', (tester) async {
    final plan = EffectDirector(nextInt: (_) => 55).planFor('777');

    await tester.pumpWidget(
      _testApp(plan: plan, disableAnimations: true),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(const Key('hold-stage-blue')), findsOneWidget);
    expect(find.byKey(const Key('pseudo-count-1')), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('hold-stage-green')), findsOneWidget);
    expect(find.byKey(const Key('pseudo-count-1')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.byKey(const Key('hold-stage-red')), findsOneWidget);
    expect(find.byKey(const Key('pseudo-count-2')), findsOneWidget);
    expect(find.byKey(const Key('locked-symbol-red-0')), findsOneWidget);
    expect(find.byKey(const Key('locked-symbol-red-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PUSH予告は3→2→1で進行しSKIPを隠さない', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(plan: _pushPlan(), disableAnimations: false),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byKey(const Key('pachinko-push-prompt')), findsOneWidget);
    expect(find.text('PUSH'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 330));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 330));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('シャッター演出は360x640でもoverflowせずSKIP可能', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var skipCalls = 0;
    await tester.pumpWidget(
      _testApp(
        plan: _shutterPlan(),
        disableAnimations: false,
        onSkip: () => skipCalls++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.byKey(const Key('pachinko-shutter')), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);
    await tester.tap(find.text('演出SKIP'));
    await tester.pump();

    expect(skipCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disableAnimationsでは常時アニメーションを停止する', (tester) async {
    await tester.pumpWidget(
      _testApp(plan: _premiumPlan(), disableAnimations: true),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(PachinkoMachineOverlay), findsOneWidget);
    expect(find.byType(PachinkoCinematicOverlay), findsOneWidget);
    expect(find.text('777 JACKPOT'), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resultTextがある場合、最後のビート後に結果を1.5秒表示してonSkipが呼ばれる', (tester) async {
    var skipCalled = false;

    await tester.pumpWidget(
      _testApp(
        plan: _shortPlan(),
        disableAnimations: true,
        resultText: '42',
        onSkip: () => skipCalled = true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('42'), findsOneWidget);
    expect(find.text('RESULT UNLOCKED'), findsOneWidget);
    expect(find.text('777 JACKPOT'), findsOneWidget);
    expect(find.text('JACKPOT'), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(skipCalled, isFalse);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(skipCalled, isTrue);
  });

  testWidgets('NORMAL結果ではJACKPOT役物を出さない', (tester) async {
    await tester.pumpWidget(
      _testApp(
        plan: _shortPlanForRank(EffectRank.normal),
        disableAnimations: true,
        resultText: '42',
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('RESULT UNLOCKED'), findsOneWidget);
    expect(find.text('役 物 作 動'), findsNothing);
    expect(find.text('777 JACKPOT'), findsNothing);
    expect(find.text('JACKPOT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('激熱結果では復活役物を出しJACKPOTは出さない', (tester) async {
    await tester.pumpWidget(
      _testApp(
        plan: _shortPlanForRank(EffectRank.gekiatsu),
        disableAnimations: true,
        resultText: '42',
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('RESULT UNLOCKED'), findsOneWidget);
    expect(find.text('役 物 作 動'), findsOneWidget);
    expect(find.text('777 JACKPOT'), findsNothing);
    expect(find.text('JACKPOT'), findsNothing);
    expect(find.byKey(const Key('pachinko-revival-burst')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('結果クライマックス中もSKIPできる', (tester) async {
    var skipCalls = 0;

    await tester.pumpWidget(
      _testApp(
        plan: _shortPlan(),
        disableAnimations: true,
        resultText: '777',
        onSkip: () => skipCalls++,
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('777'), findsWidgets);
    expect(find.text('演出SKIP'), findsOneWidget);
    await tester.tap(find.text('演出SKIP'));
    await tester.pump();

    expect(skipCalls, 1);
  });

  testWidgets('長い指数表記の結果も360x640でoverflowしない', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        plan: _shortPlan(),
        disableAnimations: true,
        resultText: '1.2345678901e+308',
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('1.2345678901e+308'), findsOneWidget);
    expect(find.text('演出SKIP'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await tester.pump(const Duration(milliseconds: 150));

    expect(skipCalled, isTrue);
  });

  testWidgets('darkビートでは背景エフェクトと役物が消えて完全暗転になる', (tester) async {
    await tester.pumpWidget(
      _testApp(plan: _planWithDarkBeat(), disableAnimations: true),
    );

    await tester.pump(const Duration(milliseconds: 32));
    expect(find.text('テスト'), findsWidgets);
    expect(find.byType(EffectBackdrop), findsOneWidget);
    expect(find.byType(PachinkoMachineOverlay), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('…………'), findsWidgets);
    expect(find.text('DOPA HEAT'), findsNothing);
    expect(find.byType(EffectBackdrop), findsNothing);
    expect(find.byType(PachinkoMachineOverlay), findsNothing);
    expect(find.byType(PachinkoCinematicOverlay), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
