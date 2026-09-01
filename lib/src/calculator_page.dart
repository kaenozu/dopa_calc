import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculation_controller.dart';
import 'calculator_engine.dart';
import 'effect_director.dart';
import 'effect_overlay.dart';
import 'effect_player.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  final _controller = CalculationController();
  final _director = EffectDirector();
  final _effectPlayer = EffectPlayer();

  late final AnimationController _pulseController;
  EffectPlan? _activePlan;
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
    _controller.addListener(_onControllerChanged);
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
        _controller.isResolving &&
        !_pulseController.isAnimating) {
      _startPulse();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _resultTimer?.cancel();
    _pulseController.dispose();
    unawaited(_effectPlayer.dispose());
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  // ── パルスアニメーション ──────────────────────────────────

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

  // ── キー入力 ──────────────────────────────────────────────

  void _press(String key) {
    if (_controller.isResolving) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    switch (key) {
      case 'AC':
        _clear();
        return;
      case '⌫':
        _controller.backspace();
        return;
      case '=':
        _resolve();
        return;
      case '±':
        _controller.toggleSign();
        return;
      case '+':
      case '−':
      case '×':
      case '÷':
        _controller.appendOperator(key);
        return;
      default:
        _controller.appendNumber(key);
        return;
    }
  }

  void _clear() {
    _resultTimer?.cancel();
    _stopPulse();
    setState(() {
      _activePlan = null;
    });
    _controller.clear();
  }

  // ── 演出オーケストレーション ──────────────────────────────

  void _resolve() {
    if (_controller.isEmpty || _controller.isResolving) return;

    try {
      final formatted = _controller.evaluate();
      final plan = _director.planFor(formatted);

      HapticFeedback.heavyImpact();
      _controller.beginResolving(formatted);
      setState(() {
        _activePlan = plan;
      });
      _startPulse();

      _resultTimer?.cancel();
      _resultTimer = Timer(plan.duration, () {
        if (!mounted) return;
        HapticFeedback.vibrate();
        _stopPulse();
        _controller.finishResult(formatted);
        setState(() {
          _activePlan = null;
        });
      });
    } on CalculatorException catch (error) {
      HapticFeedback.heavyImpact();
      _controller.showError(error.message);
      setState(() {
        _activePlan = null;
      });
    }
  }

  void _skipEffect() {
    if (!_controller.isResolving) return;
    _resultTimer?.cancel();
    _stopPulse();
    _controller.finishResult(_controller.lastFormattedResult!);
    setState(() {
      _activePlan = null;
    });
  }

  // ── UI ────────────────────────────────────────────────────

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
                      expression: _controller.expression,
                      display: _controller.display,
                      isResult: _controller.showResult,
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
                onBeat: (event) =>
                    unawaited(_effectPlayer.playBeat(plan.rank, event)),
                onSkip: _skipEffect,
                resultText: _controller.lastFormattedResult,
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
