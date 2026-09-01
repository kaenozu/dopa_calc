import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

/// 高強度ビート専用の追加描画。基礎パーティクルの上限は増やさず、
/// 流星とPREMIUM稲妻で盤面の密度を上げる。
class PachinkoAccentPainter extends CustomPainter {
  const PachinkoAccentPainter({
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
    if (impact < 0.85) return;

    final cometCount = rank == EffectRank.premium ? 14 : 8;
    _drawComets(canvas, size, cometCount, impact);

    if (rank == EffectRank.premium && impact >= 0.9) {
      _drawLightning(canvas, size, impact);
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
      final rawAlpha = (0.28 + glow * 0.42) * impact;
      final alpha = rawAlpha.clamp(0.0, 0.9).toDouble();

      paint
        ..strokeWidth = 1.5 + glow * 2.6
        ..color = (i.isEven ? Colors.white : accent).withValues(alpha: alpha);
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
        final noiseSeed = (bolt + 1) * 193 + segment * 31 + phaseStep * 17;
        final jitter = (_unitNoise(noiseSeed) - 0.5) * size.width * 0.18;
        final x = (baseX + jitter).clamp(0.0, size.width).toDouble();
        path.lineTo(x, y);
      }

      final rawAlpha = 0.18 + impact * 0.16;
      final alpha = rawAlpha.clamp(0.0, 0.42).toDouble();
      paint
        ..strokeWidth = 1.5 + impact * 1.8
        ..color = (bolt.isEven ? Colors.white : accent).withValues(
          alpha: alpha,
        );
      canvas.drawPath(path, paint);
    }
  }

  double _unitNoise(int seed) {
    final value = math.sin(seed * 12.9898 + 78.233) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(PachinkoAccentPainter oldDelegate) {
    return oldDelegate.rank != rank ||
        oldDelegate.intensity != intensity ||
        oldDelegate.beatIndex != beatIndex ||
        oldDelegate.phase != phase ||
        oldDelegate.accent != accent;
  }
}
