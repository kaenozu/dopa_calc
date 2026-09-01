import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

class CelebrationPainter extends CustomPainter {
  const CelebrationPainter({
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
    final impact = intensityFactor(intensity);
    final rankFactor = 0.45 + rank.index * 0.25;
    final particleCount = (16 + 22 * rank.index + 16 * impact)
        .round()
        .clamp(16, 96)
        .toInt();
    final rayCount = (12 + 12 * rank.index).clamp(12, 48).toInt();
    final center = size.center(Offset.zero);

    _drawRings(canvas, center, size, impact);
    _drawRays(canvas, center, size, rayCount, impact);
    if (impact >= 0.85) {
      _drawComets(
        canvas,
        size,
        rank == EffectRank.premium ? 14 : 8,
        impact,
      );
    }
    if (rank == EffectRank.premium && impact >= 0.9) {
      _drawLightning(canvas, size, impact);
    }
    _drawParticles(canvas, size, particleCount, impact, rankFactor);
    _drawScanLines(canvas, size, impact);
  }

  void _drawRings(Canvas canvas, Offset center, Size size, double impact) {
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < 4; i++) {
      final progress = (phase + i / 4) % 1;
      paint.color = accent.withValues(alpha: (1 - progress) * 0.34 * impact);
      canvas.drawCircle(center, maxRadius * (0.08 + progress * 0.58), paint);
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

  void _drawComets(Canvas canvas, Size size, int count, double impact) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..blendMode = BlendMode.plus;

    for (var i = 0; i < count; i++) {
      final seed = i + beatIndex * 211;
      final base = _unitNoise(seed * 3 + 5);
      final lane = _unitNoise(seed * 7 + 11);
      final speed = 0.75 + _unitNoise(seed * 13 + 17) * 0.9;
      final travel = (base + phase * speed) % 1.0;
      final x = (travel * 1.35 - 0.18) * size.width;
      final y = ((lane + travel * 0.22) % 1.0) * size.height;
      final length = 18 + _unitNoise(seed * 19 + 23) * 46;
      final glow = 0.35 + _unitNoise(seed * 29 + 31) * 0.55;

      paint
        ..strokeWidth = 1.5 + glow * 2.6
        ..color = (i.isEven ? Colors.white : accent).withValues(
          alpha: ((0.28 + glow * 0.42) * impact)
              .clamp(0.0, 0.9)
              .toDouble(),
        );
      canvas.drawLine(
        Offset(x, y),
        Offset(x - length, y + length * 0.34),
        paint,
      );
    }
  }

  void _drawLightning(Canvas canvas, Size size, double impact) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = BlendMode.plus;
    final phaseStep = (phase * 16).floor();

    for (var bolt = 0; bolt < 3; bolt++) {
      final baseX = size.width * (0.18 + bolt * 0.32);
      final path = Path()..moveTo(baseX, -8);
      for (var segment = 0; segment < 8; segment++) {
        final y = size.height * (segment + 1) / 8;
        final jitter =
            (_unitNoise(
                  (bolt + 1) * 193 + segment * 31 + phaseStep * 17,
                ) -
                0.5) *
            size.width *
            0.18;
        final x = (baseX + jitter).clamp(0.0, size.width).toDouble();
        path.lineTo(x, y);
      }

      paint
        ..strokeWidth = 1.5 + impact * 1.8
        ..color = (bolt.isEven ? Colors.white : accent).withValues(
          alpha: (0.18 + impact * 0.16).clamp(0.0, 0.42).toDouble(),
        );
      canvas.drawPath(path, paint);
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
      paint.color = _particleColor(
        seed,
      ).withValues(alpha: alpha.clamp(0.0, 1.0).toDouble());

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
  bool shouldRepaint(CelebrationPainter oldDelegate) {
    return oldDelegate.rank != rank ||
        oldDelegate.intensity != intensity ||
        oldDelegate.beatIndex != beatIndex ||
        oldDelegate.phase != phase ||
        oldDelegate.accent != accent;
  }
}
