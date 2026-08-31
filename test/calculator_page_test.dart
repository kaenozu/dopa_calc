import 'package:dopa_calc/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _tapKey(WidgetTester tester, String label) async {
  final keyFinder = find.descendant(
    of: find.byType(InkWell),
    matching: find.text(label),
  );
  final target = keyFinder.evaluate().isNotEmpty
      ? keyFinder.first
      : find.text(label).first;
  await tester.tap(target);
  await tester.pump();
}

Future<void> _tapSequence(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await _tapKey(tester, label);
  }
}

Future<void> _skipEffectIfPresent(WidgetTester tester) async {
  final skipFinder = find.text('演出SKIP');
  if (skipFinder.evaluate().isNotEmpty) {
    await tester.tap(skipFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _displayText(WidgetTester tester) {
  final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox).first);
  return (fittedBox.child as Text).data ?? '';
}

void main() {
  group('CalculatorPage widget', () {
    testWidgets('連続計算: 1+2= → +4= で7', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['1', '+', '2', '=']);
      await tester.pump();
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '3');

      await _tapSequence(tester, ['+', '4', '=']);
      await tester.pump();
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '7');
    });

    testWidgets('連続計算の回帰: 左辺が消えない', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['1', '+', '2', '=']);
      await _skipEffectIfPresent(tester);
      await _tapKey(tester, '+');
      expect(_displayText(tester), '3+');
      await _tapKey(tester, '4');
      expect(_displayText(tester), '3+4');
    });

    testWidgets('指数表記の結果から連続計算できる', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, [
        '1',
        '÷',
        '1',
        '00',
        '00',
        '00',
        '00',
        '00',
        '0',
        '=',
      ]);
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '1e-11');

      await _tapSequence(tester, ['+', '1', '=']);
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '1');
    });

    testWidgets('±で符号反転', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['5', '±']);
      expect(_displayText(tester), '−5');
      await _tapKey(tester, '±');
      expect(_displayText(tester), '5');
    });

    testWidgets('⌫で1文字削除', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['1', '2', '3']);
      expect(_displayText(tester), '123');
      await _tapKey(tester, '⌫');
      expect(_displayText(tester), '12');
    });

    testWidgets('ACでリセット', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['9', '+', '1', '=']);
      await _skipEffectIfPresent(tester);
      await _tapKey(tester, 'AC');
      expect(_displayText(tester), '0');
      expect(find.text('READY'), findsOneWidget);
    });

    testWidgets('48文字境界で追加されない', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      for (var i = 0; i < 48; i++) {
        await _tapKey(tester, '1');
      }
      final before = _displayText(tester);
      expect(before.length, 48);
      await _tapKey(tester, '1');
      final after = _displayText(tester);
      expect(after.length, before.length);
    });

    testWidgets('複数文字キーでも48文字上限を超えない', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      for (var i = 0; i < 47; i++) {
        await _tapKey(tester, '1');
      }
      await _tapKey(tester, '00');
      expect(_displayText(tester).length, 47);
    });

    testWidgets('演出SKIPで即結果表示', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['2', '+', '2', '=']);
      expect(find.text('演出SKIP'), findsOneWidget);
      await tester.tap(find.text('演出SKIP'));
      await tester.pump();
      expect(_displayText(tester), '4');
      expect(find.text('演出SKIP'), findsNothing);
    });

    testWidgets('SKIPしても計算結果は不変', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['7', '×', '8', '=']);
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '56');
    });

    testWidgets('0除算エラー後に再入力可能', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['1', '÷', '0', '=']);
      await tester.pump();
      expect(_displayText(tester), '0では割れません');
      await _tapKey(tester, 'AC');
      expect(_displayText(tester), '0');
      await _tapSequence(tester, ['1', '+', '1', '=']);
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '2');
    });

    testWidgets('エラー表示後に演算子でクリアされる', (tester) async {
      await tester.pumpWidget(const DopaCalculatorApp());
      await _tapSequence(tester, ['1', '÷', '0', '=']);
      await tester.pump();
      expect(_displayText(tester), '0では割れません');
      await _tapKey(tester, '+');
      expect(_displayText(tester), isNot('0では割れません'));
    });

    testWidgets('disableAnimationsでもSKIP可能', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const DopaCalculatorApp(),
        ),
      );
      await _tapSequence(tester, ['1', '+', '1', '=']);
      expect(find.text('演出SKIP'), findsOneWidget);
      await _skipEffectIfPresent(tester);
      expect(_displayText(tester), '2');
    });
  });
}
