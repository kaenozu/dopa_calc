import 'package:dopa_calc/src/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = CalculatorEngine();

  group('CalculatorEngine', () {
    test('四則演算と優先順位', () {
      expect(engine.evaluate('1+2×3'), 7);
      expect(engine.evaluate('10÷2+3'), 8);
      expect(engine.evaluate('10−2×4'), 2);
    });

    test('小数', () {
      expect(engine.format(engine.evaluate('0.1+0.2')), '0.3');
      expect(engine.format(engine.evaluate('5÷2')), '2.5');
    });

    test('負数', () {
      expect(engine.evaluate('−5+2'), -3);
      expect(engine.evaluate('5×−2'), -10);
    });

    test('0除算はエラー', () {
      expect(() => engine.evaluate('1÷0'), throwsA(isA<CalculatorException>()));
    });

    test('未完成式はエラー', () {
      expect(() => engine.evaluate('1+'), throwsA(isA<CalculatorException>()));
    });

    test('微小値は0に潰れない', () {
      final formatted = engine.format(engine.evaluate('1÷100000000000'));
      expect(formatted, isNot('0'));
      expect(formatted.contains('e'), isTrue);
    });

    test('指数表記の結果を次の計算に使える', () {
      final tiny = engine.format(engine.evaluate('1÷100000000000'));
      expect(tiny, contains('e'));
      expect(engine.evaluate('$tiny+1'), closeTo(1.00000000001, 1e-15));
    });

    test('指数部の+符号も解釈できる', () {
      expect(engine.evaluate('1E+3+2'), 1002);
    });

    test('不正な指数表記はエラー', () {
      expect(() => engine.evaluate('1e+'), throwsA(isA<CalculatorException>()));
      expect(
        () => engine.evaluate('e3+1'),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('1/3は10桁で丸め', () {
      expect(engine.format(engine.evaluate('1÷3')), '0.3333333333');
    });

    test('0.99999999995は10桁で丸め', () {
      expect(engine.format(0.99999999995), '0.9999999999');
    });

    test('指数表記の微小値はe表記', () {
      expect(engine.format(1e-11), contains('e-11'));
      expect(engine.format(1e-11), isNot('0'));
    });
  });
}
