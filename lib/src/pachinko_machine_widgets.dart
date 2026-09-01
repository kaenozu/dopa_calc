import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

/// 先バレ・図柄ロック・PUSH・役物落下を1つの非操作レイヤーとして描画する。
class PachinkoMachineOverlay extends StatelessWidget {
  const PachinkoMachineOverlay({
    required this.cue,
    required this.rank,
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reduceMotion,
    super.key,
  });

  final EffectCue cue;
  final EffectRank rank;
  final Color accent;
  final double phase;
  final double impact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (cue == EffectCue.standard ||
        cue == EffectCue.shutter ||
        cue == EffectCue.blackout) {
      return const SizedBox.shrink();
    }

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SirenRails(
              accent: accent,
              phase: phase,
              impact: impact,
              reduceMotion: reduceMotion,
            ),
            if (cue == EffectCue.preAlert ||
                cue == EffectCue.symbolLock ||
                cue == EffectCue.pushPrompt ||
                cue == EffectCue.revival ||
                cue == EffectCue.jackpot)
              _SymbolLockBackdrop(
                cue: cue,
                accent: accent,
                phase: phase,
                reduceMotion: reduceMotion,
              ),
            if (cue == EffectCue.revival || cue == EffectCue.jackpot)
              _MechanicalDropGate(
                cue: cue,
                accent: accent,
                phase: phase,
                reduceMotion: reduceMotion,
              ),
            if (cue == EffectCue.jackpot)
              _JackpotStamp(
                accent: accent,
                phase: phase,
                reduceMotion: reduceMotion,
              ),
          ],
        ),
      ),
    );
  }
}

class _SirenRails extends StatelessWidget {
  const _SirenRails({
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reduceMotion,
  });

  final Color accent;
  final double phase;
  final double impact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 96, 8, 102),
      child: Row(
        children: [
          _SirenRail(
            accent: accent,
            phase: phase,
            impact: impact,
            reduceMotion: reduceMotion,
          ),
          const Spacer(),
          _SirenRail(
            accent: accent,
            phase: phase + 0.5,
            impact: impact,
            reduceMotion: reduceMotion,
          ),
        ],
      ),
    );
  }
}

class _SirenRail extends StatelessWidget {
  const _SirenRail({
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reduceMotion,
  });

  final Color accent;
  final double phase;
  final double impact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(8, (index) {
        final angle = (phase + index * 0.13) * math.pi * 2;
        final wave = reduceMotion ? 0.72 : (math.sin(angle) + 1) / 2;
        final alpha = ((0.18 + wave * 0.7) * impact)
            .clamp(0.0, 0.92)
            .toDouble();
        final lampColor =
            Color.lerp(accent, Colors.white, wave * 0.5) ?? accent;

        return Container(
          width: 9 + wave * 5,
          height: 24,
          decoration: BoxDecoration(
            color: lampColor.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: alpha),
                blurRadius: 14 + wave * 14,
                spreadRadius: wave,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SymbolLockBackdrop extends StatelessWidget {
  const _SymbolLockBackdrop({
    required this.cue,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final EffectCue cue;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  int get _lockedCount => switch (cue) {
    EffectCue.preAlert => 1,
    EffectCue.symbolLock || EffectCue.pushPrompt || EffectCue.revival => 2,
    EffectCue.jackpot => 3,
    EffectCue.standard || EffectCue.shutter || EffectCue.blackout => 0,
  };

  @override
  Widget build(BuildContext context) {
    final pulse = reduceMotion
        ? 1.0
        : 0.96 + math.sin(phase * math.pi * 2) * 0.04;

    return Align(
      alignment: const Alignment(0, 0.2),
      child: FractionallySizedBox(
        widthFactor: 0.82,
        child: Transform.scale(
          scale: pulse,
          child: Opacity(
            opacity: cue == EffectCue.jackpot ? 0.34 : 0.2,
            child: Row(
              children: List.generate(3, (index) {
                final locked = index < _lockedCount;
                final symbol = locked ? '7' : '?';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: AspectRatio(
                      aspectRatio: 0.78,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: locked ? accent : Colors.white24,
                            width: locked ? 3 : 1,
                          ),
                          boxShadow: locked
                              ? [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.78),
                                    blurRadius: 30,
                                  ),
                                ]
                              : null,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            symbol,
                            style: TextStyle(
                              color: locked ? Colors.white : Colors.white38,
                              fontSize: 112,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              shadows: locked
                                  ? [
                                      Shadow(color: accent, blurRadius: 30),
                                      const Shadow(
                                        color: Colors.black,
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MechanicalDropGate extends StatelessWidget {
  const _MechanicalDropGate({
    required this.cue,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final EffectCue cue;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final wave = reduceMotion
        ? 1.0
        : (math.sin(phase * math.pi * 2 - math.pi / 2) + 1) / 2;
    final drop = Curves.easeOutBack.transform(wave.clamp(0.0, 1.0).toDouble());
    final label = cue == EffectCue.jackpot ? '777 JACKPOT' : '役 物 作 動';

    return Align(
      alignment: const Alignment(0, -0.42),
      child: Transform.translate(
        offset: Offset(0, -72 + drop * 72),
        child: FractionallySizedBox(
          widthFactor: 0.72,
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  accent.withValues(alpha: 0.82),
                  Colors.white,
                  accent.withValues(alpha: 0.82),
                  Colors.black,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.82),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JackpotStamp extends StatelessWidget {
  const _JackpotStamp({
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final Color accent;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final rotation = reduceMotion
        ? -0.08
        : -0.08 + math.sin(phase * math.pi * 2) * 0.025;

    return Align(
      alignment: const Alignment(0, 0.72),
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: 0.2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '777',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 132,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 12,
                      shadows: [
                        Shadow(color: accent, blurRadius: 38),
                        Shadow(color: accent, blurRadius: 82),
                      ],
                    ),
                  ),
                  Text(
                    'JACKPOT',
                    style: TextStyle(
                      color: accent,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      shadows: [Shadow(color: accent, blurRadius: 32)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
