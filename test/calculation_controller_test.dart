import 'package:dopa_calc/src/calculation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculationController', () {
    late CalculationController controller;

    setUp(() {
      controller = CalculationController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('初期状態', () {
      expect(controller.expression, '');
      expect(controller.display, '0');
      expect(controller.showResult, isFalse);
      expect(controller.isResolving, isFalse);
      expect(controller.isEmpty, isTrue);
    });

    test('数字入力', () {
      controller.appendNumber('7');
      expect(controller.expression, '7');
      expect(controller.display, '7');
    });

    test('複数桁入力', () {
      controller.appendNumber('1');
      controller.appendNumber('2');
      controller.appendNumber('3');
      expect(controller.expression, '123');
    });

    test('小数点入力', () {
      controller.appendNumber('3');
      controller.appendNumber('.');
      controller.appendNumber('1');
      expect(controller.expression, '3.1');
    });

    test('重複小数点は無視', () {
      controller.appendNumber('3');
      controller.appendNumber('.');
      controller.appendNumber('1');
      controller.appendNumber('.');
      expect(controller.expression, '3.1');
    });

    test('小数点で始まる場合0を付加', () {
      controller.appendNumber('.');
      expect(controller.expression, '0.');
    });

    test('演算子入力', () {
      controller.appendNumber('1');
      controller.appendOperator('+');
      expect(controller.expression, '1+');
    });

    test('連続演算子は置換', () {
      controller.appendNumber('1');
      controller.appendOperator('+');
      controller.appendOperator('×');
      expect(controller.expression, '1×');
    });

    test('空で−演算子は符号入力', () {
      controller.appendOperator('−');
      expect(controller.expression, '−');
    });

    test('符号反転', () {
      controller.appendNumber('5');
      controller.toggleSign();
      expect(controller.expression, '−5');
    });

    test('符号反転の元に戻す', () {
      controller.appendNumber('5');
      controller.toggleSign();
      controller.toggleSign();
      expect(controller.expression, '5');
    });

    test('バックスペース', () {
      controller.appendNumber('1');
      controller.appendNumber('2');
      controller.backspace();
      expect(controller.expression, '1');
    });

    test('空のバックスペースは無視', () {
      controller.backspace();
      expect(controller.expression, '');
    });

    test('クリア', () {
      controller.appendNumber('1');
      controller.appendNumber('2');
      controller.clear();
      expect(controller.expression, '');
      expect(controller.display, '0');
    });

    test('48文字上限', () {
      for (var i = 0; i < 50; i++) {
        controller.appendNumber('1');
      }
      expect(controller.expression.length, 48);
    });

    test('評価: 基本計算', () {
      controller.appendNumber('1');
      controller.appendOperator('+');
      controller.appendNumber('2');
      expect(controller.evaluate(), '3');
    });

    test('評価: 演算子優先順位', () {
      controller.appendNumber('2');
      controller.appendOperator('+');
      controller.appendNumber('3');
      controller.appendOperator('×');
      controller.appendNumber('4');
      expect(controller.evaluate(), '14');
    });

    test('evaluateは通知を発行しない', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.appendNumber('1');
      notified = false;
      controller.evaluate();
      expect(notified, isFalse);
    });

    test('beginResolving/finishResult', () {
      controller.appendNumber('7');
      controller.beginResolving('7');

      expect(controller.isResolving, isTrue);
      expect(controller.lastFormattedResult, '7');

      controller.finishResult('7');
      expect(controller.isResolving, isFalse);
      expect(controller.display, '7');
      expect(controller.lastFormattedResult, isNull);
    });

    test('showError', () {
      controller.appendNumber('1');
      controller.beginResolving('1');
      controller.showError('0では割れません');

      expect(controller.isResolving, isFalse);
      expect(controller.display, '0では割れません');
      expect(controller.showResult, isTrue);
    });

    test('notifyListenersが発行される', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.appendNumber('1');
      controller.appendOperator('+');
      controller.appendNumber('2');
      expect(count, 3);
    });
  });
}
