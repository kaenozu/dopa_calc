import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'effect_director.dart';

class EffectOverlay extends StatefulWidget {
  const EffectOverlay({
    required this.plan,
    required this.pulse,
    required this.onBeat,
    required this.onSkip,
    super.key,
  });

  final EffectPlan plan;
  final Animation<double> pulse;
  final ValueChanged<int> onBeat;
  final VoidCallback onSkip;

  @override
  State<EffectOverlay> createState() => _EffectOverlayState();
}

class _EffectOverlayState extends State<EffectOverlay>
    with TickerProviderStateMixin {
  Timer? _beatTimer;
  var _beatIndex = 0;
  var _reduceMotion = false;

  late final AnimationController _motionController;
  late final AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    widget.onBeat(_beatIndex);
    _scheduleNextBeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion == _reduceMotion) {
      if (!reduceMotion && !_motionController.isAnimating) {
        _motionController.repeat();
      }
      return;
    }

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _motionController.stop();
      _motionController.value = 0;
      _flashController.stop();
      _flashController.value = 1;
    } else {
      _motionController.repeat();
    }
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _motionController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _scheduleNextBeat() {
    final beat = widget.plan.beats[_beatIndex];
    _beatTimer = Timer(beat.duration, () {
      if (!mounted || _beatIndex >= widget.plan.beats.length - 1) return;

      setState(() => _beatIndex++);
      widget.onBeat(_beatIndex);
      unawaited(_impactFor(widget.plan.beats[_beatIndex].intensity));
      if (!_reduceMotion) {
        _flashController.forward(from: 0);
      }
      _scheduleNextBeat();
    });
  }

  Future<void> _impactFor(EffectIntensity intensity) {
    return switch (intensity) {
      EffectIntensity.low => HapticFeedback.selectionClick(),
      EffectIntensity.medium => HapticFeedback.mediumImpact(),
      EffectIntensity.high => HapticFeedback.heavyImpact(),
      EffectIntensity.extreme => HapticFeedback.vibrate(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final beat = plan.beats[_beatIndex];
    final baseAccent = _baseAccent(plan.rank);
    final rankLabel = _rankLabel(plan.rank);
    final rankSubtitle = _rankSubtitle(plan.rank);

    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: Semantics(
          liveRegion: true,
          label: '${beat.headline} ${beat.subline}',
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.pulse,
              _motionController,
              _flashController,
            ]),
            builder: (context, child) {
              final phase = _reduceMotion ? 0.0 : _motionController.value;
              final pulse = _reduceMotion ? 1.0 : widget.pulse.value;
              final accent = _animatedAccent(baseAccent, plan.rank, phase);
              final impact = _intensityFactor(beat.intensity);
              final flash = _reduceMotion
                  ? 0.0
                  : (1 - Curves.easeOut.transform(_flashController.value)) *
                      impact;
              final shakeX = _reduceMotion
                  ? 0.0
                  : math.sin(phase * math.pi * 14) * 5.5 * impact;
              final shakeY = _reduceMotion
                  ? 0.0
                  : math.cos(phase * math.pi * 18) * 3.5 * impact;
              final rotation = _reduceMotion
                  ? 0.0
                  : math.sin(phase * math.pi * 10) * 0.012 * impact;

              return Stack(
                fit: StackFit.expand,
                children: [
                  _EffectBackdrop(rank: plan.rank, accent: accent),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _CelebrationPainter(
                        rank: plan.rank,
                        intensity: beat.intensity,
                        beatIndex: _beatIndex,
                        phase: phase,
                        accent: accent,
                      ),
                    ),
                  ),
                  if (!_reduceMotion)
                    _SweepBeam(accent: accent, phase: phase, impact: impact),
                  _EdgeFrame(accent: accent, impact: impact),
                  SafeArea(
                    minimum: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    child: Column(
                      children: [
                        _RankBanner(
                          rankLabel: rankLabel,
                          rankSubtitle: rankSubtitle,
                          accent: accent,
                          phase: phase,
                          reduceMotion: _reduceMotion,
                        ),
                        const Spacer(),
                        Transform.rotate(
                          angle: rotation,
                          child: Transform.translate(
                            offset: Offset(shakeX, shakeY),
                            child: Transform.scale(
                              scale: 1 + (pulse - 1) * 0.55,
                              child: _HeadlineCard(
                                beat: beat,
                                rank: plan.rank,
                                accent: accent,
                                phase: phase,
                                reduceMotion: _reduceMotion,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        _ProgressPips(
                          current: _beatIndex,
                          total: plan.beats.length,
                          accent: accent,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: widget.onSkip,
                            icon: const Icon(Icons.fast_forward_rounded),
                            label: const Text('演出SKIP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: accent.withValues(alpha: 0.72),
                                width: 1.5,
                              ),
                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (flash > 0.001)
                    IgnorePointer(
                      child: ColoredBox(
                        color: Colors.white.withValues(
                          alpha: (flash * 0.72).clamp(0.0, 0.72),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Color _baseAccent(EffectRank rank) {
  return switch (rank) {
    EffectRank.normal => const Color(0xFFE8F1FF),
    EffectRank.chance => const Color(0xFF4EDCFF),
    EffectRank.gekiatsu => const Color(0xFFFF3B30),
    EffectRank.premium => const Color(0xFFFFD700),
  };
}

String _rankLabel(EffectRank rank) {
  return switch (rank) {
    EffectRank.normal => 'NORMAL',
    EffectRank.chance => 'CHANCE ZONE',
    EffectRank.gekiatsu => '激 熱 ZONE',
    EffectRank.premium => 'PREMIUM RUSH',
  };
}

String _rankSubtitle(EffectRank rank) {
  return switch (rank) {
    EffectRank.normal => 'CALCULATION EFFECT',
    EffectRank.chance => 'EXPECTATION UP',
    EffectRank.gekiatsu => 'HIGH IMPACT',
    EffectRank.premium => 'MAXIMUM CELEBRATION',
  };
}

double _intensityFactor(EffectIntensity intensity) {
  return switch (intensity) {
    EffectIntensity.low => 0.45,
    EffectIntensity.medium => 0.7,
    EffectIntensity.high => 0.9,
    EffectIntensity.extreme => 1.0,
  };
}

Color _animatedAccent(Color base, EffectRank rank, double phase) {
  if (rank != EffectRank.premium) return base;
  final hsv = HSVColor.fromColor(base);
  return hsv.withHue((hsv.hue + phase * 110) % 360).toColor();
}

class _EffectBackdrop extends StatelessWidget {
  const _EffectBackdrop({required this.rank, required this.accent});

  final EffectRank rank;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final secondary = switch (rank) {
      EffectRank.normal => const Color(0xFF10233C),
      EffectRank.chance => const Color(0xFF00324B),
      EffectRank.gekiatsu => const Color(0xFF520000),
      EffectRank.premium => const Color(0xFF4A2400),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.2,
          colors: [
            accent.withValues(alpha: 0.35),
            secondary.withValues(alpha: 0.96),
            Colors.black,
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
    );
  }
}

class _SweepBeam extends StatelessWidget {
  const _SweepBeam({
    required this.accent,
    required this.phase,
    required this.impact,
  });

  final Color accent;
  final double phase;
  final double impact;

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(-1.8 + phase * 3.6, -0.25);
    return IgnorePointer(
      child: FractionallySizedBox(
        widthFactor: 0.46,
        heightFactor: 1.5,
        alignment: alignment,
        child: Transform.rotate(
          angle: -0.38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accent.withValues(alpha: 0.08 * impact),
                  Colors.white.withValues(alpha: 0.34 * impact),
                  accent.withValues(alpha: 0.12 * impact),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeFrame extends StatelessWidget {
  const _EdgeFrame({required this.accent, required this.impact});

  final Color accent;
  final double impact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: accent.withValues(alpha: 0.68),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.44 * impact),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.16 * impact),
                blurRadius: 10,
                spreadRadius: -2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankBanner extends StatelessWidget {
  const _RankBanner({
    required this.rankLabel,
    required this.rankSubtitle,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final String rankLabel;
  final String rankSubtitle;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final pulse = reduceMotion ? 1.0 : 0.92 + math.sin(phase * math.pi * 2) * 0.08;
    return Transform.scale(
      scale: pulse,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.82),
              accent.withValues(alpha: 0.34),
              Colors.black.withValues(alpha: 0.82),
            ],
          ),
          border: Border.symmetric(
            horizontal: BorderSide(color: accent, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.46),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '★  $rankLabel  ★',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(color: accent, blurRadius: 18),
                    const Shadow(color: Colors.black, blurRadius: 6),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rankSubtitle,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: accent.withValues(alpha: 0.92),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  const _HeadlineCard({
    required this.beat,
    required this.rank,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final EffectBeat beat;
  final EffectRank rank;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final targetSize = switch (rank) {
      EffectRank.normal => 56.0,
      EffectRank.chance => 82.0,
      EffectRank.gekiatsu => 104.0,
      EffectRank.premium => 126.0,
    };
    final letterSpacing = switch (rank) {
      EffectRank.normal => 5.0,
      EffectRank.chance => 7.0,
      EffectRank.gekiatsu => 9.0,
      EffectRank.premium => 10.0,
    };
    final tilt = reduceMotion ? 0.0 : math.sin(phase * math.pi * 4) * 0.006;

    return Transform.rotate(
      angle: tilt,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: accent.withValues(alpha: 0.74),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.58),
              blurRadius: 52,
              spreadRadius: -8,
            ),
            const BoxShadow(
              color: Colors.black,
              blurRadius: 22,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: targetSize * 1.34,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      beat.headline,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: targetSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: letterSpacing,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 8
                          ..color = Colors.black,
                      ),
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        final rotation = reduceMotion ? 0.0 : phase * math.pi * 2;
                        return LinearGradient(
                          colors: [
                            Colors.white,
                            accent,
                            Colors.white,
                            accent,
                          ],
                          stops: const [0, 0.32, 0.62, 1],
                          transform: GradientRotation(rotation),
                        ).createShader(bounds);
                      },
                      child: Text(
                        beat.headline,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: targetSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: letterSpacing,
                          shadows: [
                            Shadow(color: accent, blurRadius: 28),
                            Shadow(color: accent, blurRadius: 70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              beat.subline,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
                shadows: [
                  const Shadow(color: Colors.black, blurRadius: 8),
                  Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressPips extends StatelessWidget {
  const _ProgressPips({
    required this.current,
    required this.total,
    required this.accent,
  });

  final int current;
  final int total;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: active ? 28 : 12,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? accent : Colors.white24,
            borderRadius: BorderRadius.circular(99),
            boxShadow: active
                ? [BoxShadow(color: accent, blurRadius: 14)]
                : null,
          ),
        );
      }),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.rank,
    required this.intensity,
    required this.beatIndex,
    required this.phase,
    required this.accent,
  });

  final EffectRank rank;
  final EffectIntensity intensity;
  final int beatIndex;
  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final impact = _intensityFactor(intensity);
    final rankFactor = 0.45 + rank.index * 0.25;
    final particleCount = (16 + 22 * rank.index + 16 * impact).round().clamp(
          16,
          96,
        );
    final rayCount = (12 + 12 * rank.index).clamp(12, 48);
    final center = size.center(Offset.zero);

    _drawRings(canvas, center, size, impact);
    _drawRays(canvas, center, size, rayCount, impact);
    _drawParticles(
      canvas,
      size,
      particleCount,
      impact,
      rankFactor,
    );
    _drawScanLines(canvas, size, impact);
  }

  void _drawRings(
    Canvas canvas,
    Offset center,
    Size size,
    double impact,
  ) {
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < 4; i++) {
      final progress = (phase + i / 4) % 1;
      paint.color = accent.withValues(
        alpha: (1 - progress) * 0.34 * impact,
      );
      canvas.drawCircle(
        center,
        maxRadius * (0.08 + progress * 0.58),
        paint,
      );
    }
  }

  void _drawRays(
    Canvas canvas,
    Offset center,
    Size size,
    int rayCount,
    double impact,
  ) {
    final radius = size.longestSide * 0.86;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < rayCount; i++) {
      final angle = i * math.pi * 2 / rayCount + phase * 0.7;
      final wave = 0.45 + 0.55 * _unitNoise(i * 7 + beatIndex * 31);
      final start = radius * (0.07 + wave * 0.04);
      final end = radius * (0.42 + wave * 0.5);
      paint
        ..strokeWidth = 1.2 + wave * 2.8
        ..color = accent.withValues(alpha: 0.1 + 0.2 * impact);
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * start,
          center.dy + math.sin(angle) * start,
        ),
        Offset(
          center.dx + math.cos(angle) * end,
          center.dy + math.sin(angle) * end,
        ),
        paint,
      );
    }
  }

  void _drawParticles(
    Canvas canvas,
    Size size,
    int particleCount,
    double impact,
    double rankFactor,
  ) {
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < particleCount; i++) {
      final seed = i + beatIndex * 101;
      final baseX = _unitNoise(seed * 3 + 1);
      final baseY = _unitNoise(seed * 5 + 2);
      final speed = 0.35 + _unitNoise(seed * 11 + 7) * 1.1;
      final drift = math.sin((phase * speed + baseY) * math.pi * 2);
      final x = (baseX + drift * 0.035 * rankFactor) * size.width;
      final y = ((baseY - phase * speed * 0.24) % 1) * size.height;
      final radius = 1.6 + _unitNoise(seed * 13 + 4) * (4.5 + rank.index);
      final alpha = (0.25 + _unitNoise(seed * 17 + 9) * 0.62) * impact;
      paint.color = _particleColor(seed).withValues(alpha: alpha.clamp(0, 1));

      if (i % 5 == 0) {
        _drawSpark(canvas, Offset(x, y), radius * 1.9, paint);
      } else {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _drawSpark(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.18, center.dy - radius * 0.18)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.18, center.dy + radius * 0.18)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.18, center.dy + radius * 0.18)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.18, center.dy - radius * 0.18)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawScanLines(Canvas canvas, Size size, double impact) {
    final paint = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.035 * impact);
    const spacing = 18.0;
    for (var y = (phase * spacing) % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  Color _particleColor(int seed) {
    const colors = [
      Color(0xFFFFFFFF),
      Color(0xFF7DF9FF),
      Color(0xFFFFE600),
      Color(0xFFFF4D36),
      Color(0xFFFF72D2),
    ];
    if (rank == EffectRank.normal) return accent;
    return colors[seed.abs() % colors.length];
  }

  double _unitNoise(int seed) {
    final value = math.sin(seed * 12.9898 + 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) {
    return oldDelegate.rank != rank ||
        oldDelegate.intensity != intensity ||
        oldDelegate.beatIndex != beatIndex ||
        oldDelegate.phase != phase ||
        oldDelegate.accent != accent;
  }
}
