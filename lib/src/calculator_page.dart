import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_engine.dart';
import 'effect_director.dart';
import 'effect_overlay.dart';
import 'sound_manager.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  static const _engine = CalculatorEngine();
  static const _maxExpressionLength = 48;

  final _director = EffectDirector();
  final _soundManager = SoundManager();

  late final AnimationController _pulseController;
  String _expression = '';
  String _display = '0';
  EffectPlan? _activePlan;
  bool _showResult = false;
  bool _isResolving = false;
  Timer? _resultTimer;

  static const _keys = <String>[
    'AC',
    '⌫',
    '÷',
    '×',
    '7',
    '8',
    '9',
    '−',
    '4',
    '5',
    '6',
    '+',
    '1',
    '2',
    '3',
    '±',
    '0',
    '00',
    '.',
    '=',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      lowerBound: 0.94,
      upperBound: 1.06,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _pulseController.isAnimating) {
      _stopPulse();
    } else if (!disableAnimations &&
        _isResolving &&
        !_pulseController.isAnimating) {
      _startPulse();
    }
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _pulseController.dispose();
    unawaited(_soundManager.dispose());
    super.dispose();
  }

  void _startPulse() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations || _pulseController.isAnimating) return;
    _pulseController.repeat(reverse: true);
  }

  void _stopPulse() {
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.value = 1;
  }

  void _press(String key) {
    if (_isResolving) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    switch (key) {
      case 'AC':
        _clear();
        return;
      case '⌫':
        _backspace();
        return;
      case '=':
        _resolve();
        return;
      case '±':
        _toggleSign();
        return;
      case '+':
      case '−':
      case '×':
      case '÷':
        _appendOperator(key);
        return;
      default:
        _appendNumber(key);
        return;
    }
  }

  void _clear() {
    _resultTimer?.cancel();
    _stopPulse();
    setState(() {
      _expression = '';
      _display = '0';
      _activePlan = null;
      _showResult = false;
      _isResolving = false;
    });
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _display = _expression.isEmpty ? '0' : _expression;
      _showResult = false;
    });
  }

  void _appendOperator(String operator) {
    if (_showResult) {
      final isErrorDisplay = _display != _expression;
      setState(() {
        if (isErrorDisplay) {
          _expression = operator == '−' ? '−' : '';
          _display = _expression.isEmpty ? '0' : _expression;
        }
        _showResult = false;
      });
      if (isErrorDisplay || _expression.isEmpty) return;
    }

    if (_expression.isEmpty) {
      if (operator == '−') {
        setState(() {
          _expression = '−';
          _display = _expression;
        });
      }
      return;
    }

    final last = _expression[_expression.length - 1];
    const operators = {'+', '−', '×', '÷'};
    setState(() {
      _showResult = false;
      if (operators.contains(last)) {
        _expression =
            '${_expression.substring(0, _expression.length - 1)}$operator';
      } else if (_expression.length < _maxExpressionLength) {
        _expression += operator;
      }
      _display = _expression;
    });
  }

  void _toggleSign() {
    if (_expression.isEmpty) {
      setState(() {
        _expression = '−';
        _display = _expression;
        _showResult = false;
      });
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

    setState(() {
      if (operand.startsWith('−')) {
        _expression =
            '${_expression.substring(0, operandStart)}${operand.substring(1)}';
      } else if (_expression.length < _maxExpressionLength) {
        _expression = '${_expression.substring(0, operandStart)}−$operand';
      }
      _display = _expression;
      _showResult = false;
    });
  }

  void _appendNumber(String value) {
    var nextExpression = _showResult ? '' : _expression;
    final currentNumber = nextExpression.split(RegExp(r'[+−×÷]')).last;

    if (value == '.' && currentNumber.contains('.')) return;
    if (value == '.' && currentNumber.isEmpty) value = '0.';
    if (nextExpression.length + value.length > _maxExpressionLength) return;

    nextExpression += value;
    setState(() {
      _expression = nextExpression;
      _display = nextExpression;
      _showResult = false;
    });
  }

  void _resolve() {
    if (_expression.isEmpty || _isResolving) return;

    try {
      final formatted = _evaluateCurrentExpression();
      final plan = _director.planFor(formatted);

      HapticFeedback.heavyImpact();
      setState(() {
        _activePlan = plan;
        _showResult = false;
        _isResolving = true;
      });
      _startPulse();

      _resultTimer?.cancel();
      _resultTimer = Timer(plan.duration, () {
        if (!mounted) return;
        HapticFeedback.vibrate();
        _stopPulse();
        _finishResult(formatted);
      });
    } on CalculatorException catch (error) {
      HapticFeedback.heavyImpact();
      _showError(error.message);
    }
  }

  void _skipEffect() {
    if (!_isResolving) return;
    _resultTimer?.cancel();
    _stopPulse();
    try {
      _finishResult(_evaluateCurrentExpression());
    } on CalculatorException catch (error) {
      _showError(error.message);
    }
  }

  String _evaluateCurrentExpression() {
    return _engine.format(_engine.evaluate(_expression));
  }

  void _finishResult(String display) {
    setState(() {
      _display = display;
      _expression = display;
      _showResult = true;
      _isResolving = false;
      _activePlan = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _display = message;
      _showResult = true;
      _activePlan = null;
      _isResolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                children: [
                  _Header(onReset: _clear),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 3,
                    child: _Display(
                      expression: _expression,
                      display: _display,
                      isResult: _showResult,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 7,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const columns = 4;
                        const rows = 5;
                        const gap = 10.0;
                        final keyWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                                columns;
                        final keyHeight =
                            (constraints.maxHeight - gap * (rows - 1)) / rows;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: gap,
                            crossAxisSpacing: gap,
                            childAspectRatio: keyWidth / keyHeight,
                          ),
                          itemCount: _keys.length,
                          itemBuilder: (context, index) {
                            final key = _keys[index];
                            return _CalcKey(
                              label: key,
                              onTap: () => _press(key),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_activePlan case final plan?)
              EffectOverlay(
                plan: plan,
                pulse: _pulseController,
                onBeat: (beatIndex) =>
                    unawaited(_soundManager.playBeat(plan.rank, beatIndex)),
                onSkip: _skipEffect,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFD400), width: 2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'ドパ電卓',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        const Spacer(),
        TextButton(onPressed: onReset, child: const Text('RESET')),
      ],
    );
  }
}

class _Display extends StatelessWidget {
  const _Display({
    required this.expression,
    required this.display,
    required this.isResult,
  });

  final String expression;
  final String display;
  final bool isResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF161922), Color(0xFF0B0D12)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(blurRadius: 24, spreadRadius: -10, color: Colors.black),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isResult ? 'RESULT' : (expression.isEmpty ? 'READY' : 'CALC'),
            style: const TextStyle(
              color: Color(0xFFFFD400),
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              display,
              maxLines: 1,
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w900,
                color: isResult ? const Color(0xFFFFF06A) : Colors.white,
                shadows: isResult
                    ? const [
                        Shadow(blurRadius: 20, color: Color(0xFFFF8A00)),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  bool get _isOperator => const {'÷', '×', '−', '+', '='}.contains(label);
  bool get _isUtility => const {'AC', '⌫', '±'}.contains(label);

  @override
  Widget build(BuildContext context) {
    final background = _isOperator
        ? const Color(0xFFFFC400)
        : _isUtility
            ? const Color(0xFF343946)
            : const Color(0xFF1A1E27);
    final foreground = _isOperator ? Colors.black : Colors.white;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
