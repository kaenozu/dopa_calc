import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

/// 遊技機の盤面ランプ風に四隅を発光させる。
class CabinetLamps extends StatelessWidget {
  const CabinetLamps({
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reduceMotion,
    super.key,
  });

  final Color accent;
  final double phase;
  final double impact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 68, 14, 72),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LampCluster(
                  accent: accent,
                  phase: phase,
                  impact: impact,
                  reduceMotion: reduceMotion,
                  offset: 0,
                ),
                _LampCluster(
                  accent: accent,
                  phase: phase,
                  impact: impact,
                  reduceMotion: reduceMotion,
                  offset: 2,
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _LampCluster(
                  accent: accent,
                  phase: phase,
                  impact: impact,
                  reduceMotion: reduceMotion,
                  offset: 4,
                ),
                _LampCluster(
                  accent: accent,
                  phase: phase,
                  impact: impact,
                  reduceMotion: reduceMotion,
                  offset: 6,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LampCluster extends StatelessWidget {
  const _LampCluster({
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reduceMotion,
    required this.offset,
  });

  final Color accent;
  final double phase;
  final double impact;
  final bool reduceMotion;
  final int offset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final angle =
            (phase + (index + offset) * 0.14) * math.pi * 2;
        final wave = reduceMotion ? 0.78 : (math.sin(angle) + 1) / 2;
        final rawAlpha = (0.34 + wave * 0.6) * impact;
        final alpha = rawAlpha.clamp(0.0, 0.94).toDouble();
        final size = 8.0 + wave * 5.0;
        final lampColor = Color.lerp(accent, Colors.white, wave * 0.42);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.5),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lampColor,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: alpha),
                  blurRadius: 16 + wave * 12,
                  spreadRadius: wave * 1.5,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// NORMAL→CHANCE→激熱→PREMIUMの上昇を盤面メーターとして可視化する。
class HeatGauge extends StatelessWidget {
  const HeatGauge({required this.rank, required this.accent, super.key});

  final EffectRank rank;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final level = rank.index + 1;
    return Semantics(
      label: 'ドパヒート レベル$level/4',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'DOPA HEAT',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                const Spacer(),
                Text(
                  level == 4 ? 'MAX' : 'LEVEL $level/4',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: List.generate(4, (index) {
                final active = index < level;
                final margin = index == 3 ? 0.0 : 5.0;
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: margin),
                    decoration: BoxDecoration(
                      color: active ? accent : Colors.white12,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.7),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// 最終結果を「大当たり告知」風に見せるクライマックス。
class ResultClimax extends StatelessWidget {
  const ResultClimax({
    required this.resultText,
    required this.rankLabel,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
    required this.onSkip,
    super.key,
  });

  final String resultText;
  final String rankLabel;
  final Color accent;
  final double phase;
  final bool reduceMotion;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final scale = reduceMotion
        ? 1.0
        : 1.0 + math.sin(phase * math.pi * 2) * 0.035;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        children: [
          const Spacer(),
          Text(
            'RESULT UNLOCKED',
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: accent, blurRadius: 26)],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.55),
                  blurRadius: 24,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '★ $rankLabel ★',
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Transform.scale(
            scale: scale,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 760),
              height: 170,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.62),
                    blurRadius: 54,
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 18,
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  resultText,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    shadows: [
                      const Shadow(color: Colors.black, blurRadius: 12),
                      Shadow(color: accent, blurRadius: 42),
                      Shadow(color: accent, blurRadius: 90),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ANSWER CONFIRMED',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.2,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSkip,
              icon: const Icon(Icons.fast_forward_rounded),
              label: const Text('演出SKIP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: accent.withValues(alpha: 0.82),
                  width: 2,
                ),
                backgroundColor: Colors.black.withValues(alpha: 0.62),
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
    );
  }
}
