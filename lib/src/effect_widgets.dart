import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

class EffectBackdrop extends StatelessWidget {
  const EffectBackdrop({required this.rank, required this.accent, super.key});

  final EffectRank rank;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final secondary = rank.theme.secondary;

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

class SweepBeam extends StatelessWidget {
  const SweepBeam({
    required this.accent,
    required this.phase,
    required this.impact,
    super.key,
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

class EdgeFrame extends StatelessWidget {
  const EdgeFrame({required this.accent, required this.impact, super.key});

  final Color accent;
  final double impact;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: 0.68), width: 3),
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
    Widget cluster(int offset) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          final local = reduceMotion
              ? 0.78
              : (math.sin(
                          (phase + (index + offset) * 0.14) * math.pi * 2,
                        ) +
                        1) /
                    2;
          final alpha = ((0.34 + local * 0.6) * impact)
              .clamp(0.0, 0.94)
              .toDouble();
          final size = 8.0 + local * 5.0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(accent, Colors.white, local * 0.42),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: alpha),
                    blurRadius: 16 + local * 12,
                    spreadRadius: local * 1.5,
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 68, 14, 72),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [cluster(0), cluster(2)],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [cluster(4), cluster(6)],
            ),
          ],
        ),
      ),
    );
  }
}

class RankBanner extends StatelessWidget {
  const RankBanner({
    required this.rankLabel,
    required this.rankSubtitle,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
    super.key,
  });

  final String rankLabel;
  final String rankSubtitle;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final pulse = reduceMotion
        ? 1.0
        : 0.92 + math.sin(phase * math.pi * 2) * 0.08;
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
            BoxShadow(color: accent.withValues(alpha: 0.46), blurRadius: 24),
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
                return Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
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

class HeadlineCard extends StatelessWidget {
  const HeadlineCard({
    required this.beat,
    required this.rank,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
    this.dark = false,
    super.key,
  });

  final EffectBeat beat;
  final EffectRank rank;
  final Color accent;
  final double phase;
  final bool reduceMotion;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = rank.theme;
    final targetSize = theme.headlineSize;
    final letterSpacing = theme.letterSpacing;
    final tilt = reduceMotion ? 0.0 : math.sin(phase * math.pi * 4) * 0.006;

    // darkビート: 枠線・発光なし、白文字のみ最小表示
    if (dark) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  beat.headline,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Transform.rotate(
      angle: tilt,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 760),
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: accent.withValues(alpha: 0.74), width: 2),
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
                        final rotation = reduceMotion
                            ? 0.0
                            : phase * math.pi * 2;
                        return LinearGradient(
                          colors: [Colors.white, accent, Colors.white, accent],
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

class ProgressPips extends StatelessWidget {
  const ProgressPips({
    required this.current,
    required this.total,
    required this.accent,
    required this.reduceMotion,
    super.key,
  });

  final int current;
  final int total;
  final Color accent;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final active = index <= current;
        return AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 140),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 24),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                side: BorderSide(color: accent.withValues(alpha: 0.82), width: 2),
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
