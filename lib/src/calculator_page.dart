import 'dart:async';
import 'dart:math' as math;

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
      final formatted = _evaluateCurrentExpression();
      _finishResult(formatted);
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

class _PachinkoPainter extends CustomPainter {
  _PachinkoPainter({
    required this.rank,
    required this.intensity,
    required this.beatIndex,
    required this.progress,
    required this.random,
    required this.accentColor,
  });

  final EffectRank rank;
  final EffectIntensity intensity;
  final int beatIndex;
  final double progress;
  final math.Random random;
  final Color accentColor;

  static const _sparkleColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF7DF9FF),
    Color(0xFFFFE600),
    Color(0xFFFF3B30),
    Color(0xFFFF8A00),
    Color(0xFFB347EA),
    Color(0xFF39FF14),
    Color(0xFFFF69B4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide * 0.7;

    if (rank == EffectRank.normal) {
      _drawSparkles(canvas, paint, size, 20, additive: false);
      return;
    }

    if (rank == EffectRank.chance) {
      _drawSparkles(canvas, paint, size, 80, additive: true);
      _drawStreaks(canvas, paint, size, 40);
      _drawStarburst(canvas, paint, center, maxRadius * 1.6, 40);
      return;
    }

    if (rank == EffectRank.gekiatsu) {
      _drawSparkles(canvas, paint, size, 300, additive: true);
      _drawStarburst(canvas, paint, center, maxRadius * 2.2, 80);
      _drawStreaks(canvas, paint, size, 80);
      _drawLightning(canvas, paint, size, 18);
      return;
    }

    _drawSparkles(canvas, paint, size, 700, additive: true);
    _drawStarburst(canvas, paint, center, maxRadius * 3.5, 160);
    _drawStreaks(canvas, paint, size, 160);
    _drawLightning(canvas, paint, size, 40);
    _drawVignette(canvas, paint, size);
  }

  void _drawSparkles(Canvas canvas, Paint paint, Size size, int count, {required bool additive}) {
    if (additive) paint.blendMode = BlendMode.plus;
    for (var i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final color = _sparkleColors[random.nextInt(_sparkleColors.length)];
      final alpha = (0.6 + random.nextDouble() * 0.4).clamp(0.0, 1.0);
      final radius = (10 + random.nextDouble() * 34).clamp(10.0, 44.0);
      _drawStar(canvas, paint, Offset(x, y), radius, color.withValues(alpha: alpha));
    }
    paint.blendMode = BlendMode.srcOver;
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius, Color color) {
    const points = 4;
    final innerRadius = radius * 0.28;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = (i * math.pi) / points - math.pi / 2;
      final x = center.dx + math.cos(angle) * r;
      final y = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    paint.color = color;
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, paint);
    paint.maskFilter = null;
  }

  void _drawStarburst(Canvas canvas, Paint paint, Offset center, double radius, int rays) {
    final gradient = RadialGradient(
      colors: <Color>[
        Colors.white.withValues(alpha: 1.0),
        accentColor.withValues(alpha: 1.0),
        accentColor.withValues(alpha: 0.9),
        accentColor.withValues(alpha: 0.0),
      ],
      stops: const <double>[0.0, 0.08, 0.22, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    paint.shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, paint);
    paint.shader = null;

    for (var i = 0; i < rays; i++) {
      final angle = (i * 2 * math.pi) / rays + progress * 1.1;
      final length = radius * (0.86 + random.nextDouble() * 0.14);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle) * length,
          center.dy + math.sin(angle) * length,
        );
      paint.color = accentColor.withValues(alpha: 0.85);
      paint.strokeWidth = 4;
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
    paint.style = PaintingStyle.fill;
  }

  void _drawStreaks(Canvas canvas, Paint paint, Size size, int count) {
    paint.blendMode = BlendMode.plus;
    for (var i = 0; i < count; i++) {
      final fromLeft = random.nextBool();
      final y = random.nextDouble() * size.height;
      final length = size.width * (0.6 + random.nextDouble() * 0.4);
      final path = Path();
      if (fromLeft) {
        path.moveTo(0, y);
        path.lineTo(length, y + (random.nextDouble() - 0.5) * 120);
      } else {
        path.moveTo(size.width, y);
        path.lineTo(size.width - length, y + (random.nextDouble() - 0.5) * 120);
      }
      paint.color = accentColor.withValues(alpha: 0.35 + random.nextDouble() * 0.65);
      paint.strokeWidth = 3 + random.nextDouble() * 9;
      paint.style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
    paint.style = PaintingStyle.fill;
    paint.blendMode = BlendMode.srcOver;
  }

  void _drawLightning(Canvas canvas, Paint paint, Size size, int count) {
    paint.blendMode = BlendMode.plus;
    for (var i = 0; i < count; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() > 0.5 ? 0.0 : size.height;
      final endY = startY == 0.0 ? size.height : 0.0;
      final segments = 7 + random.nextInt(10);
      final path = Path()..moveTo(startX, startY);
      var currentY = startY;
      final step = (endY - startY).abs() / segments;
      for (var s = 0; s < segments; s++) {
        currentY += step * (endY > startY ? 1 : -1);
        final jitter = (random.nextDouble() - 0.5) * size.width * 0.6;
        path.lineTo(startX + jitter, currentY);
      }
      final color = _sparkleColors[random.nextInt(_sparkleColors.length)];
      paint.color = color.withValues(alpha: 0.9 + random.nextDouble() * 0.1);
      paint.strokeWidth = 5 + random.nextDouble() * 14;
      paint.style = PaintingStyle.stroke;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, paint);
      paint.maskFilter = null;
    }
    paint.style = PaintingStyle.fill;
    paint.blendMode = BlendMode.srcOver;
  }

  void _drawVignette(Canvas canvas, Paint paint, Size size) {
    final gradient = RadialGradient(
      colors: <Color>[
        Colors.transparent,
        Colors.transparent,
        const Color(0xFF000000).withValues(alpha: 0.7),
        const Color(0xFF000000).withValues(alpha: 0.95),
      ],
      stops: const <double>[0.0, 0.3, 0.65, 1.0],
    );
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;
  }

  @override
  bool shouldRepaint(_PachinkoPainter old) =>
      old.beatIndex != beatIndex ||
      old.progress != progress ||
      old.rank != rank ||
      old.intensity != intensity;
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

class _EffectOverlayState extends State<_EffectOverlay> with TickerProviderStateMixin {
  Timer? _beatTimer;
  var _beatIndex = 0;
  late final AnimationController _flashController;
  late final AnimationController _flash2Controller;
  late final AnimationController _vignetteController;
  late final AnimationController _colorCycleController;
  late final AnimationController _waveController;
  var _flashBaseAlpha = 0.0;

  @override
  void initState() {
    super.initState();
    widget.onBeat(_beatIndex);
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flash2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _vignetteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _colorCycleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat();
    _scheduleNextBeat();
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _flashController.dispose();
    _flash2Controller.dispose();
    _vignetteController.dispose();
    _colorCycleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _scheduleNextBeat() {
    final beat = widget.plan.beats[_beatIndex];
    _flashBaseAlpha = switch (beat.intensity) {
      EffectIntensity.low => 0.2,
      EffectIntensity.medium => 0.6,
      EffectIntensity.high => 0.9,
      EffectIntensity.extreme => 1.0,
    };
    _beatTimer = Timer(beat.duration, () {
      if (!mounted || _beatIndex >= widget.plan.beats.length - 1) return;
      setState(() => _beatIndex++);
      _flashController.forward(from: 0);
      _flash2Controller.forward(from: 0);
      widget.onBeat(_beatIndex);
      _scheduleNextBeat();
    });
  }

  Color _colorCycledAccent(Color base) {
    if (widget.plan.rank != EffectRank.premium) return base;
    final t = _colorCycleController.value * 2 * math.pi;
    final r = (base.r * 255 + math.sin(t) * 90).round().clamp(0, 255);
    final g = (base.g * 255 + math.sin(t + 2.094) * 90).round().clamp(0, 255);
    final b = (base.b * 255 + math.sin(t + 4.189) * 90).round().clamp(0, 255);
    final a = (base.a * 255).round();
    return Color.fromARGB(a, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final beat = plan.beats[_beatIndex];
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final baseAccent = switch (plan.rank) {
      EffectRank.normal => Colors.white,
      EffectRank.chance => const Color(0xFF4EDCFF),
      EffectRank.gekiatsu => const Color(0xFFFF3B30),
      EffectRank.premium => const Color(0xFFFFE600),
    };
    final accent = _colorCycledAccent(baseAccent);

    final shakeIntensity = switch (beat.intensity) {
      EffectIntensity.low => 0.0,
      EffectIntensity.medium => 50.0,
      EffectIntensity.high => 120.0,
      EffectIntensity.extreme => 200.0,
    };
    final shake = !disableAnimations && shakeIntensity > 0;

    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            widget.pulse,
            _flashController,
            _flash2Controller,
            _vignetteController,
            _colorCycleController,
            _waveController,
          ]),
          builder: (context, child) {
            final pulseDelta = disableAnimations ? 0.0 : widget.pulse.value - 1;
            final scale = disableAnimations ? 1.0 : widget.pulse.value;
            final flashCurve = Curves.easeOut.transform(_flashController.value);
            final flashAlpha = (_flashBaseAlpha * (1 - flashCurve)).clamp(0.0, 1.0);
            final flash2Alpha = (_flashBaseAlpha * 0.5 * (1 - _flash2Controller.value)).clamp(0.0, 1.0);
            final shakeX = shake
                ? (math.Random().nextDouble() - 0.5) * shakeIntensity * (0.8 + pulseDelta.abs() * 0.5)
                : 0.0;
            final shakeY = shake
                ? (math.Random().nextDouble() - 0.5) * shakeIntensity * (0.8 + pulseDelta.abs() * 0.5)
                : 0.0;
            final rotation = shake ? (math.Random().nextDouble() - 0.5) * 0.08 * (0.8 + pulseDelta.abs() * 0.5) : 0.0;
            final headlineSize = switch (plan.rank) {
              EffectRank.normal => 52.0,
              EffectRank.chance => 84.0,
              EffectRank.gekiatsu => 110.0,
              EffectRank.premium => 150.0,
            };

            return Stack(
              children: [
                IgnorePointer(
                  child: Container(
                    color: accent.withValues(alpha: 0.12 + pulseDelta.abs() * 0.35),
                  ),
                ),
                if (!disableAnimations)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PachinkoPainter(
                        rank: plan.rank,
                        intensity: beat.intensity,
                        beatIndex: _beatIndex,
                        progress: pulseDelta,
                        random: math.Random(_beatIndex * 41 + plan.rank.index * 13 + (pulseDelta * 100).toInt()),
                        accentColor: accent,
                      ),
                    ),
                  ),
                if (!disableAnimations && plan.rank.index >= EffectRank.gekiatsu.index)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WavePainter(
                        color: accent,
                        progress: _waveController.value,
                      ),
                    ),
                  ),
                Center(
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.translate(
                      offset: Offset(shakeX, shakeY),
                      child: Transform.scale(
                        scale: scale,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Column(
                            key: ValueKey(_beatIndex),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(36),
                                  boxShadow: [
                                    BoxShadow(blurRadius: 180, spreadRadius: -40, color: accent.withValues(alpha: 1.0)),
                                    BoxShadow(blurRadius: 60, spreadRadius: -16, color: Colors.black.withValues(alpha: 0.95)),
                                  ],
                                ),
                                child: ShaderMask(
                                  blendMode: BlendMode.srcIn,
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [Colors.white, accent, Colors.white, accent],
                                    stops: const [0.0, 0.25, 0.75, 1.0],
                                    transform: GradientRotation(_colorCycleController.value * 2 * math.pi),
                                  ).createShader(bounds),
                                  child: Text(
                                    beat.headline,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: headlineSize,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 12,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(blurRadius: 90, color: accent.withValues(alpha: 1.0)),
                                        Shadow(blurRadius: 30, color: Colors.black),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  beat.subline,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 1.0),
                                    shadows: const [Shadow(blurRadius: 32, color: Colors.black)],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                '${_beatIndex + 1} / ${plan.beats.length}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.transparent, Colors.transparent, Colors.black.withValues(alpha: 0.6), Colors.black.withValues(alpha: 0.95)],
                        stops: const [0.0, 0.3, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
                if (flashAlpha > 0.001)
                  IgnorePointer(
                    child: Container(color: accent.withValues(alpha: flashAlpha)),
                  ),
                if (flash2Alpha > 0.001)
                  IgnorePointer(
                    child: Container(color: Colors.white.withValues(alpha: flash2Alpha * 0.5)),
                  ),
                if (beat.intensity == EffectIntensity.extreme && _flashController.value < 0.4)
                  IgnorePointer(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.35 * (1 - _flashController.value / 0.4)),
                    ),
                  ),
                Positioned(
                  left: 16, right: 16, bottom: 24,
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

class _WavePainter extends CustomPainter {
  _WavePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.4 + progress * 0.4);
    for (var i = 0; i < 5; i++) {
      final path = Path();
      final y = size.height * (0.2 + i * 0.15);
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 10) {
        final wave = math.sin(x * 0.02 + progress * 4 * math.pi + i) * 20;
        path.lineTo(x, y + wave);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.progress != progress;
}
