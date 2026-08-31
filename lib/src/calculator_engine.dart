class CalculatorException implements Exception {
  const CalculatorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CalculatorEngine {
  const CalculatorEngine();

  double evaluate(String expression) {
    final normalized = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');

    if (normalized.isEmpty) {
      throw const CalculatorException('式が空です');
    }

    final tokens = _tokenize(normalized);
    final rpn = _toRpn(tokens);
    return _evaluateRpn(rpn);
  }

  String format(double value) {
    if (value.isNaN || value.isInfinite) {
      throw const CalculatorException('計算できません');
    }

    if (value == 0) return '0';

    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 1e-10) {
      return rounded.toInt().toString();
    }

    final fixed = value.toStringAsFixed(10);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    void flushNumber() {
      if (buffer.isEmpty) return;
      final number = buffer.toString();
      if (double.tryParse(number) == null) {
        throw const CalculatorException('数字の形式が不正です');
      }
      tokens.add(number);
      buffer.clear();
    }

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final isDigit = RegExp(r'[0-9]').hasMatch(char);

      if (isDigit || char == '.') {
        buffer.write(char);
        continue;
      }

      if (_isOperator(char)) {
        if (char == '-' && (i == 0 || _isOperator(input[i - 1]))) {
          buffer.write(char);
          continue;
        }
        flushNumber();
        tokens.add(char);
        continue;
      }

      throw CalculatorException('使用できない文字です: $char');
    }

    flushNumber();

    if (tokens.isEmpty || _isOperator(tokens.last)) {
      throw const CalculatorException('式が未完成です');
    }
    return tokens;
  }

  List<String> _toRpn(List<String> tokens) {
    final output = <String>[];
    final operators = <String>[];

    for (final token in tokens) {
      if (!_isOperator(token)) {
        output.add(token);
        continue;
      }

      while (operators.isNotEmpty &&
          _precedence(operators.last) >= _precedence(token)) {
        output.add(operators.removeLast());
      }
      operators.add(token);
    }

    while (operators.isNotEmpty) {
      output.add(operators.removeLast());
    }
    return output;
  }

  double _evaluateRpn(List<String> rpn) {
    final stack = <double>[];

    for (final token in rpn) {
      if (!_isOperator(token)) {
        final value = double.tryParse(token);
        if (value == null) {
          throw const CalculatorException('数字を解釈できません');
        }
        stack.add(value);
        continue;
      }

      if (stack.length < 2) {
        throw const CalculatorException('式が不正です');
      }

      final right = stack.removeLast();
      final left = stack.removeLast();
      switch (token) {
        case '+':
          stack.add(left + right);
          break;
        case '-':
          stack.add(left - right);
          break;
        case '*':
          stack.add(left * right);
          break;
        case '/':
          if (right == 0) {
            throw const CalculatorException('0では割れません');
          }
          stack.add(left / right);
          break;
      }
    }

    if (stack.length != 1) {
      throw const CalculatorException('式が不正です');
    }
    return stack.single;
  }

  bool _isOperator(String token) =>
      token == '+' || token == '-' || token == '*' || token == '/';

  int _precedence(String operator) =>
      (operator == '*' || operator == '/') ? 2 : 1;
}
