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
      expect(
        () => engine.evaluate('1÷0'),
        throwsA(isA<CalculatorException>()),
      );
    });

    test('未完成式はエラー', () {
      expect(
        () => engine.evaluate('1+'),
        throwsA(isA<CalculatorException>()),
      );
    });
  });
}
