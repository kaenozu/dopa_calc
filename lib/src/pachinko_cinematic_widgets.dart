import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'effect_director.dart';

/// PUSH・シャッター・復活フラッシュなど、時間進行を使う演出レイヤー。
class PachinkoCinematicOverlay extends StatelessWidget {
  const PachinkoCinematicOverlay({
    required this.cue,
    required this.accent,
    required this.phase,
    required this.progress,
    required this.reduceMotion,
    super.key,
  });

  final EffectCue cue;
  final Color accent;
  final double phase;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (cue != EffectCue.pushPrompt &&
        cue != EffectCue.shutter &&
        cue != EffectCue.revival &&
        cue != EffectCue.jackpot) {
      return const SizedBox.shrink();
    }

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cue == EffectCue.pushPrompt)
              _PushPrompt(
                accent: accent,
                phase: phase,
                progress: progress,
                reduceMotion: reduceMotion,
              ),
            if (cue == EffectCue.shutter)
              _ShutterDoors(
                accent: accent,
                progress: progress,
                reduceMotion: reduceMotion,
              ),
            if (cue == EffectCue.revival || cue == EffectCue.jackpot)
              _RevivalBurst(
                accent: accent,
                progress: progress,
                reduceMotion: reduceMotion,
              ),
          ],
        ),
      ),
    );
  }
}

class _PushPrompt extends StatelessWidget {
  const _PushPrompt({
    required this.accent,
    required this.phase,
    required this.progress,
    required this.reduceMotion,
  });

  final Color accent;
  final double phase;
  final double progress;
  final bool reduceMotion;

  String _countdownFor(double value) {
    if (value < 0.34) return '3';
    if (value < 0.67) return '2';
    return '1';
  }

  @override
  Widget build(BuildContext context) {
    final countdown = _countdownFor(progress);
    final wave = reduceMotion ? 0.6 : (math.sin(phase * math.pi * 8) + 1) / 2;
    final scale = reduceMotion ? 1.0 : 0.94 + wave * 0.1;

    return Stack(
      key: const Key('pachinko-push-prompt'),
      fit: StackFit.expand,
      children: [
        Align(
          alignment: const Alignment(0, -0.1),
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.76),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.88),
                  blurRadius: 34,
                  spreadRadius: 4,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              countdown,
              style: TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w900,
                shadows: [Shadow(color: accent, blurRadius: 20)],
              ),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.46),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 142,
              height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    accent,
                    const Color(0xFFB00000),
                    Colors.black,
                  ],
                  stops: const [0, 0.18, 0.7, 1],
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.92),
                    blurRadius: 42 + wave * 20,
                    spreadRadius: 8 + wave * 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'PUSH',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '押 せ',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.72),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShutterDoors extends StatelessWidget {
  const _ShutterDoors({
    required this.accent,
    required this.progress,
    required this.reduceMotion,
  });

  final Color accent;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final closure = reduceMotion ? 0.72 : _closureFor(progress);

    return LayoutBuilder(
      key: const Key('pachinko-shutter'),
      builder: (context, constraints) {
        final halfWidth = constraints.maxWidth / 2;
        final offset = halfWidth * (1 - closure);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(-offset, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: halfWidth + 10,
                  height: double.infinity,
                  child: _ShutterPanel(
                    accent: accent,
                    label: '>>>',
                    rightEdge: true,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(offset, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: halfWidth + 10,
                  height: double.infinity,
                  child: _ShutterPanel(
                    accent: accent,
                    label: '<<<',
                    rightEdge: false,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _closureFor(double value) {
    if (value < 0.62) {
      return Curves.easeInCubic.transform(
        (value / 0.62).clamp(0.0, 1.0).toDouble(),
      );
    }
    final reopen = Curves.easeOutExpo.transform(
      ((value - 0.62) / 0.38).clamp(0.0, 1.0).toDouble(),
    );
    return 1 - reopen;
  }
}

class _ShutterPanel extends StatelessWidget {
  const _ShutterPanel({
    required this.accent,
    required this.label,
    required this.rightEdge,
  });

  final Color accent;
  final String label;
  final bool rightEdge;

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.white, width: 3);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: rightEdge ? Alignment.centerLeft : Alignment.centerRight,
          end: rightEdge ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            Colors.black,
            accent.withValues(alpha: 0.76),
            Colors.white.withValues(alpha: 0.9),
            accent.withValues(alpha: 0.9),
            Colors.black,
          ],
        ),
        border: Border(
          right: rightEdge ? border : BorderSide.none,
          left: rightEdge ? BorderSide.none : border,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.9),
            blurRadius: 34,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: rightEdge ? 1 : 3,
          child: Text(
            '$label  LOCK  $label',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              shadows: [Shadow(color: Colors.white, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevivalBurst extends StatelessWidget {
  const _RevivalBurst({
    required this.accent,
    required this.progress,
    required this.reduceMotion,
  });

  final Color accent;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final normalized = (progress / 0.22).clamp(0.0, 1.0).toDouble();
    final flash = reduceMotion
        ? 0.12
        : 1 - Curves.easeOut.transform(normalized);
    final ringScale = reduceMotion ? 1.0 : 0.45 + normalized * 1.7;

    return Stack(
      key: const Key('pachinko-revival-burst'),
      fit: StackFit.expand,
      children: [
        if (flash > 0.001)
          ColoredBox(
            color: Colors.white.withValues(
              alpha: (flash * 0.88).clamp(0.0, 0.88).toDouble(),
            ),
          ),
        Center(
          child: Transform.scale(
            scale: ringScale,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.86),
                    blurRadius: 50,
                    spreadRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
