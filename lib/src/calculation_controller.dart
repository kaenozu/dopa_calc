import 'package:flutter/foundation.dart';

import 'calculator_engine.dart';

/// 計算機の状態と純粋な計算ロジックを管理する。
/// 演出（エフェクト）の知識を持たない。
class CalculationController extends ChangeNotifier {
  CalculationController({CalculatorEngine? engine})
    : _engine = engine ?? const CalculatorEngine();

  static const maxExpressionLength = 48;

  final CalculatorEngine _engine;

  String _expression = '';
  String _display = '0';
  bool _showResult = false;
  bool _isResolving = false;
  String? _lastFormattedResult;

  String get expression => _expression;
  String get display => _display;
  bool get showResult => _showResult;
  bool get isResolving => _isResolving;
  String? get lastFormattedResult => _lastFormattedResult;

  // ── 入力操作 ──────────────────────────────────────────────

  void clear() {
    _expression = '';
    _display = '0';
    _showResult = false;
    _isResolving = false;
    _lastFormattedResult = null;
    notifyListeners();
  }

  void backspace() {
    if (_expression.isEmpty) return;
    _expression = _expression.substring(0, _expression.length - 1);
    _display = _expression.isEmpty ? '0' : _expression;
    _showResult = false;
    notifyListeners();
  }

  void appendNumber(String value) {
    var next = _showResult ? '' : _expression;
    final currentNumber = next.split(RegExp(r'[+−×÷]')).last;

    if (value == '.' && currentNumber.contains('.')) return;
    if (value == '.' && currentNumber.isEmpty) value = '0.';
    if (next.length + value.length > maxExpressionLength) return;

    next += value;
    _expression = next;
    _display = next;
    _showResult = false;
    notifyListeners();
  }

  void appendOperator(String operator) {
    if (_showResult) {
      final isErrorDisplay = _display != _expression;
      if (isErrorDisplay) {
        _expression = operator == '−' ? '−' : '';
        _display = _expression.isEmpty ? '0' : _expression;
      }
      _showResult = false;
      if (isErrorDisplay || _expression.isEmpty) {
        notifyListeners();
        return;
      }
    }

    if (_expression.isEmpty) {
      if (operator == '−') {
        _expression = '−';
        _display = _expression;
        notifyListeners();
      }
      return;
    }

    final last = _expression[_expression.length - 1];
    const operators = {'+', '−', '×', '÷'};
    _showResult = false;
    if (operators.contains(last)) {
      _expression =
          '${_expression.substring(0, _expression.length - 1)}$operator';
    } else if (_expression.length < maxExpressionLength) {
      _expression += operator;
    }
    _display = _expression;
    notifyListeners();
  }

  void toggleSign() {
    if (_expression.isEmpty) {
      _expression = '−';
      _display = _expression;
      _showResult = false;
      notifyListeners();
      return;
    }

    const operators = {'+', '−', '×', '÷'};
    var operandStart = 0;
    for (var i = _expression.length - 1; i >= 0; i--) {
      final char = _expression[i];
      final isBinaryMinus =
          char == '−' && i > 0 && !operators.contains(_expression[i - 1]);
      final isBinaryOperator =
          char == '+' || char == '×' || char == '÷' || isBinaryMinus;
      if (isBinaryOperator) {
        operandStart = i + 1;
        break;
      }
    }

    final operand = _expression.substring(operandStart);
    if (operand.isEmpty) return;

    if (operand.startsWith('−')) {
      _expression =
          '${_expression.substring(0, operandStart)}${operand.substring(1)}';
    } else if (_expression.length < maxExpressionLength) {
      _expression = '${_expression.substring(0, operandStart)}−$operand';
    }
    _display = _expression;
    _showResult = false;
    notifyListeners();
  }

  // ── 評価・結果 ──────────────────────────────────────────────

  /// 式を評価してフォーマットされた結果を返す。
  String evaluate() {
    return _engine.format(_engine.evaluate(_expression));
  }

  /// 式が空かどうか。
  bool get isEmpty => _expression.isEmpty;

  /// 演出開始時に呼ばれる。isResolvingを立て、フォーマット結果をキャッシュ。
  void beginResolving(String formatted) {
    _lastFormattedResult = formatted;
    _showResult = false;
    _isResolving = true;
    notifyListeners();
  }

  /// 演出完了時 or SKIP時に呼ばれる。
  void finishResult(String display) {
    _display = display;
    _expression = display;
    _showResult = true;
    _isResolving = false;
    _lastFormattedResult = null;
    notifyListeners();
  }

  void showError(String message) {
    _display = message;
    _showResult = true;
    _isResolving = false;
    _lastFormattedResult = null;
    notifyListeners();
  }
}
