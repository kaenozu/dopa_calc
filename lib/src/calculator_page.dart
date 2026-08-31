import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_engine.dart';
import 'effect_director.dart';
import 'sound_manager.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  static const _engine = CalculatorEngine();
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
      lowerBound: 0.92,
      upperBound: 1.08,
      value: 1.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // アクセシビリティ設定の変更に追従
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
    if (disableAnimations) return;
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopPulse() {
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.value = 1.0;
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
      // 結果表示後の演算子は結果を左辺として継続。エラー表示時はクリア。
      final isErrorDisplay = _display != _expression;
      setState(() {
        if (isErrorDisplay) {
          _expression = operator == '−' ? '−' : '';
          _display = _expression.isEmpty ? '0' : _expression;
        }
        _showResult = false;
      });
      if (isErrorDisplay) return;
      if (_expression.isEmpty) return;
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
      } else {
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
      } else {
        _expression = '${_expression.substring(0, operandStart)}−$operand';
      }
      _display = _expression;
    });
  }

  void _appendNumber(String value) {
    if (_showResult) {
      _expression = '';
      _showResult = false;
    }

    final currentNumber = _expression.split(RegExp(r'[+−×÷]')).last;
    if (value == '.' && currentNumber.contains('.')) return;
    if (value == '.' && currentNumber.isEmpty) value = '0.';

    if (_expression.length >= 48) return;
    setState(() {
      _expression += value;
      _display = _expression;
    });
  }

  void _resolve() {
    if (_expression.isEmpty || _isResolving) return;

    try {
      final result = _engine.evaluate(_expression);
      final formatted = _engine.format(result);
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
        setState(() {
          _display = formatted;
          _expression = formatted;
          _showResult = true;
          _isResolving = false;
          _activePlan = null;
        });
      });
    } on CalculatorException catch (error) {
      HapticFeedback.heavyImpact();
      setState(() {
        _display = error.message;
        _showResult = true;
        _activePlan = null;
        _isResolving = false;
      });
    }
  }

  void _skipEffect() {
    if (!_isResolving) return;
    _resultTimer?.cancel();
    _stopPulse();
    try {
      final result = _engine.evaluate(_expression);
      setState(() {
        _display = _engine.format(result);
        _expression = _display;
        _showResult = true;
        _isResolving = false;
        _activePlan = null;
      });
    } on CalculatorException catch (error) {
      setState(() {
        _display = error.message;
        _showResult = true;
        _isResolving = false;
        _activePlan = null;
      });
    }
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
              _EffectOverlay(
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
                    ? const [Shadow(blurRadius: 20, color: Color(0xFFFF8A00))]
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

    return Material(
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
    );
  }
}

class _EffectOverlay extends StatefulWidget {
  const _EffectOverlay({
    required this.plan,
    required this.pulse,
    required this.onBeat,
    required this.onSkip,
  });

  final EffectPlan plan;
  final Animation<double> pulse;
  final ValueChanged<int> onBeat;
  final VoidCallback onSkip;

  @override
  State<_EffectOverlay> createState() => _EffectOverlayState();
}

class _EffectOverlayState extends State<_EffectOverlay> {
  Timer? _beatTimer;
  var _beatIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.onBeat(_beatIndex);
    _scheduleNextBeat();
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextBeat() {
    final beat = widget.plan.beats[_beatIndex];
    _beatTimer = Timer(beat.duration, () {
      if (!mounted || _beatIndex >= widget.plan.beats.length - 1) return;
      setState(() => _beatIndex++);
      widget.onBeat(_beatIndex);
      _scheduleNextBeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final beat = plan.beats[_beatIndex];
    final accent = switch (plan.rank) {
      EffectRank.normal => Colors.white,
      EffectRank.chance => const Color(0xFF4EDCFF),
      EffectRank.gekiatsu => const Color(0xFFFF3B30),
      EffectRank.premium => const Color(0xFFFFE600),
    };
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shake =
        !disableAnimations && plan.rank.index >= EffectRank.gekiatsu.index;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.90),
        child: AnimatedBuilder(
          animation: widget.pulse,
          builder: (context, child) {
            final pulseDelta = disableAnimations ? 0.0 : widget.pulse.value - 1;
            final scale = disableAnimations ? 1.0 : widget.pulse.value;
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(
                            alpha: disableAnimations
                                ? 0.25
                                : 0.25 + pulseDelta.abs() * 1.8,
                          ),
                          Colors.transparent,
                        ],
                        radius: 0.78,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(shake ? pulseDelta * 38 : 0, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: disableAnimations ? 0 : 160,
                        ),
                        transitionBuilder: (child, animation) =>
                            disableAnimations
                            ? child
                            : ScaleTransition(scale: animation, child: child),
                        child: Column(
                          key: ValueKey(_beatIndex),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              beat.headline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: plan.rank == EffectRank.normal
                                    ? 38
                                    : 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: accent,
                                shadows: [
                                  Shadow(blurRadius: 28, color: accent),
                                  const Shadow(
                                    blurRadius: 8,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                              ),
                              child: Text(
                                beat.subline,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${_beatIndex + 1} / ${plan.beats.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: OutlinedButton(
                    onPressed: widget.onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('演出SKIP'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
