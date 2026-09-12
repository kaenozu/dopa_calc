import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

/// 先バレ・保留変化・疑似連・図柄ロック・役物を1つの非操作レイヤーとして描画する。
class PachinkoMachineOverlay extends StatelessWidget {
  const PachinkoMachineOverlay({
    required this.cue,
    required this.rank,
    required this.visualState,
    required this.accent,
    required this.phase,
    required this.impact,
    required this.reduceMotion,
    super.key,
  });

  final EffectCue cue;
  final EffectRank rank;
  final EffectVisualState visualState;
  final Color accent;
  final double phase;
  final double impact;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final hasExpectationState =
        visualState.holdStage != HoldStage.none ||
        visualState.pseudoCount > 0 ||
        visualState.lockedSymbols > 0 ||
        visualState.revealState != RevealState.tease;
    final hasCueLayer = cue != EffectCue.standard && cue != EffectCue.blackout;

    if (!hasExpectationState && !hasCueLayer) {
      return const SizedBox.shrink();
    }

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cue != EffectCue.standard &&
                cue != EffectCue.shutter &&
                cue != EffectCue.blackout)
              _SirenRails(
                accent: accent,
                phase: phase,
                impact: impact,
                reduceMotion: reduceMotion,
              ),
            if (visualState.holdStage != HoldStage.none)
              _HoldStageDisplay(
                stage: visualState.holdStage,
                phase: phase,
                reduceMotion: reduceMotion,
              ),
            if (visualState.pseudoCount > 0)
              _PseudoBadge(
                count: visualState.pseudoCount,
                accent: accent,
                phase: phase,
                reduceMotion: reduceMotion,
              ),
            if (visualState.lockedSymbols > 0)
              _SymbolLockBackdrop(
                visualState: visualState,
                accent: accent,
                phase: phase,
                reduceMotion: reduceMotion,
              ),
            if (visualState.revealState != RevealState.tease)
              _RevealBadge(
                state: visualState.revealState,
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

class _HoldStageDisplay extends StatelessWidget {
  const _HoldStageDisplay({
    required this.stage,
    required this.phase,
    required this.reduceMotion,
  });

  final HoldStage stage;
  final double phase;
  final bool reduceMotion;

  Color get _staticColor => switch (stage) {
    HoldStage.none => Colors.transparent,
    HoldStage.blue => const Color(0xFF42A5F5),
    HoldStage.green => const Color(0xFF43A047),
    HoldStage.red => const Color(0xFFFF3B30),
    HoldStage.gold => const Color(0xFFFFD700),
    HoldStage.rainbow => const Color(0xFFFFD700),
  };

  String get _label => switch (stage) {
    HoldStage.none => '',
    HoldStage.blue => 'BLUE HOLD',
    HoldStage.green => 'GREEN HOLD',
    HoldStage.red => 'RED HOLD',
    HoldStage.gold => 'GOLD HOLD',
    HoldStage.rainbow => 'RAINBOW HOLD',
  };

  @override
  Widget build(BuildContext context) {
    final color = stage == HoldStage.rainbow && !reduceMotion
        ? HSVColor.fromAHSV(1, (phase * 360) % 360, 0.88, 1).toColor()
        : _staticColor;
    final wave = reduceMotion ? 0.5 : (math.sin(phase * math.pi * 4) + 1) / 2;
    final scale = reduceMotion ? 1.0 : 0.96 + wave * 0.08;

    return Align(
      alignment: const Alignment(0, -0.72),
      child: Transform.scale(
        scale: scale,
        child: Container(
          key: Key('hold-stage-${stage.name}'),
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.72),
                blurRadius: 22 + wave * 16,
                spreadRadius: wave * 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.32, -0.4),
                    colors: [
                      Colors.white,
                      Color.lerp(Colors.white, color, 0.42) ?? color,
                      color,
                      Colors.black,
                    ],
                    stops: const [0, 0.2, 0.68, 1],
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.88),
                      blurRadius: 22,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  shadows: [Shadow(color: color, blurRadius: 16)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PseudoBadge extends StatelessWidget {
  const _PseudoBadge({
    required this.count,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final int count;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final wave = reduceMotion ? 0.5 : (math.sin(phase * math.pi * 6) + 1) / 2;

    return Align(
      alignment: const Alignment(0, -0.52),
      child: Transform.rotate(
        angle: reduceMotion ? 0 : -0.03 + wave * 0.06,
        child: Container(
          key: Key('pseudo-count-$count'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black,
                accent.withValues(alpha: 0.8),
                Colors.white,
                accent.withValues(alpha: 0.8),
                Colors.black,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.72),
                blurRadius: 22 + wave * 12,
              ),
            ],
          ),
          child: Text(
            'PSEUDO ×$count',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.4,
              shadows: [Shadow(color: Colors.white, blurRadius: 5)],
            ),
          ),
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
    required this.visualState,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final EffectVisualState visualState;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  int get _lockedCount => visualState.lockedSymbols.clamp(0, 3).toInt();

  String get _symbol => switch (visualState.symbolStyle) {
    SymbolStyle.normal => '3',
    SymbolStyle.red => '5',
    SymbolStyle.gold => '8',
    SymbolStyle.seven => '7',
  };

  Color _symbolColor(double phase) => switch (visualState.symbolStyle) {
    SymbolStyle.normal => Colors.white,
    SymbolStyle.red => const Color(0xFFFF453A),
    SymbolStyle.gold => const Color(0xFFFFD700),
    SymbolStyle.seven =>
      reduceMotion
          ? const Color(0xFFFFD700)
          : HSVColor.fromAHSV(1, (phase * 360) % 360, 0.82, 1).toColor(),
  };

  @override
  Widget build(BuildContext context) {
    final pulse = reduceMotion
        ? 1.0
        : 0.96 + math.sin(phase * math.pi * 2) * 0.04;
    final symbolColor = _symbolColor(phase);

    return Align(
      alignment: const Alignment(0, 0.2),
      child: FractionallySizedBox(
        widthFactor: 0.82,
        child: Transform.scale(
          scale: pulse,
          child: Opacity(
            opacity: visualState.revealState == RevealState.confirmed
                ? 0.38
                : 0.24,
            child: Row(
              children: List.generate(3, (index) {
                final locked = index < _lockedCount;
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
                            color: locked ? symbolColor : Colors.white24,
                            width: locked ? 3 : 1,
                          ),
                          boxShadow: locked
                              ? [
                                  BoxShadow(
                                    color: symbolColor.withValues(alpha: 0.82),
                                    blurRadius: 30,
                                  ),
                                ]
                              : null,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            locked ? _symbol : '?',
                            key: locked
                                ? Key(
                                    'locked-symbol-${visualState.symbolStyle.name}-$index',
                                  )
                                : null,
                            style: TextStyle(
                              color: locked ? Colors.white : Colors.white38,
                              fontSize: 112,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              shadows: locked
                                  ? [
                                      Shadow(
                                        color: symbolColor,
                                        blurRadius: 30,
                                      ),
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

class _RevealBadge extends StatelessWidget {
  const _RevealBadge({
    required this.state,
    required this.accent,
    required this.phase,
    required this.reduceMotion,
  });

  final RevealState state;
  final Color accent;
  final double phase;
  final bool reduceMotion;

  String get _label => switch (state) {
    RevealState.tease => '',
    RevealState.fakeout => '……?',
    RevealState.revival => 'REVIVAL',
    RevealState.confirmed => '虹 昇 格',
  };

  @override
  Widget build(BuildContext context) {
    final wave = reduceMotion ? 0.5 : (math.sin(phase * math.pi * 4) + 1) / 2;

    return Align(
      alignment: const Alignment(0, 0.58),
      child: Opacity(
        opacity: state == RevealState.fakeout ? 0.72 : 0.92,
        child: Transform.scale(
          scale: reduceMotion ? 1.0 : 0.96 + wave * 0.1,
          child: Text(
            _label,
            key: Key('reveal-state-${state.name}'),
            style: TextStyle(
              color: state == RevealState.fakeout
                  ? Colors.white54
                  : Colors.white,
              fontSize: state == RevealState.confirmed ? 28 : 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [
                Shadow(color: accent, blurRadius: 22 + wave * 14),
                const Shadow(color: Colors.black, blurRadius: 8),
              ],
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
