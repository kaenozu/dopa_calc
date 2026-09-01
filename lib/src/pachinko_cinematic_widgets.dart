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
          alignment: const Alignment(0, -0.12),
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.76),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.88), blurRadius: 34, spreadRadius: 4)],
            ),
            alignment: Alignment.center,
            child: Text(countdown, style: TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900, shadows: [Shadow(color: accent, blurRadius: 20)])),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.46),
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/push_button.png', width: 260, height: 260, fit: BoxFit.contain, filterQuality: FilterQuality.high, errorBuilder: (c, e, s) => Container(width: 142, height: 142, decoration: BoxDecoration(shape: BoxShape.circle, color: accent, border: Border.all(color: Colors.white, width: 4))),),
                Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.95), blurRadius: 48 + wave * 24, spreadRadius: 10 + wave * 6)])),
                const Opacity(opacity: 0, child: Text('PUSH', style: TextStyle(fontSize: 1))),
              ],
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
        return Stack(fit: StackFit.expand, children: [
          Transform.translate(offset: Offset(-offset, 0), child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: halfWidth + 10, height: double.infinity, child: _ImageShutterPanel(accent: accent, rightEdge: true)))),
          Transform.translate(offset: Offset(offset, 0), child: Align(alignment: Alignment.centerRight, child: SizedBox(width: halfWidth + 10, height: double.infinity, child: _ImageShutterPanel(accent: accent, rightEdge: false)))),
        ]);
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

class _ImageShutterPanel extends StatelessWidget {
  const _ImageShutterPanel({required this.accent, required this.rightEdge});
  final Color accent;
  final bool rightEdge;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: rightEdge ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none, left: rightEdge ? BorderSide.none : const BorderSide(color: Colors.white, width: 3)),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.9), blurRadius: 34, spreadRadius: 4)],
      ),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/shutter_doors.png', fit: BoxFit.cover, alignment: rightEdge ? Alignment.centerLeft : Alignment.centerRight, errorBuilder: (c, e, s) => Container(color: Colors.black)),
        Container(color: accent.withValues(alpha: 0.08)),
        Center(child: RotatedBox(quarterTurns: rightEdge ? 1 : 3, child: Text('LOCK', style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 5, shadows: [Shadow(color: Colors.white, blurRadius: 6)])))),
      ]),
    );
  }
}

class _ShutterPanel extends StatelessWidget {
  const _ShutterPanel({required this.accent, required this.label, required this.rightEdge});
  final Color accent;
  final String label;
  final bool rightEdge;
  @override
  Widget build(BuildContext context) {
    final border = BorderSide(color: Colors.white, width: 3);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: rightEdge ? Alignment.centerLeft : Alignment.centerRight, end: rightEdge ? Alignment.centerRight : Alignment.centerLeft, colors: [Colors.black, accent.withValues(alpha: 0.76), Colors.white.withValues(alpha: 0.9), accent.withValues(alpha: 0.9), Colors.black]),
        border: Border(right: rightEdge ? border : BorderSide.none, left: rightEdge ? BorderSide.none : border),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.9), blurRadius: 34, spreadRadius: 4)],
      ),
      child: Center(child: RotatedBox(quarterTurns: rightEdge ? 1 : 3, child: Text('$label  LOCK  $label', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4, shadows: [Shadow(color: Colors.white, blurRadius: 4)])))),
    );
  }
}

class _RevivalBurst extends StatelessWidget {
  const _RevivalBurst({required this.accent, required this.progress, required this.reduceMotion});
  final Color accent;
  final double progress;
  final bool reduceMotion;
  @override
  Widget build(BuildContext context) {
    final normalized = (progress / 0.22).clamp(0.0, 1.0).toDouble();
    final flash = reduceMotion ? 0.12 : 1 - Curves.easeOut.transform(normalized);
    final ringScale = reduceMotion ? 1.0 : 0.45 + normalized * 1.7;
    return Stack(
      key: const Key('pachinko-revival-burst'),
      fit: StackFit.expand,
      children: [
        if (flash > 0.001) ColoredBox(color: Colors.white.withValues(alpha: (flash * 0.88).clamp(0.0, 0.88).toDouble())),
        // 画像フラッシュ（リッチ化）
        if (!reduceMotion && flash > 0.05)
          Center(
            child: Opacity(
              opacity: (flash * 0.9).clamp(0.0, 0.9).toDouble(),
              child: Image.asset('assets/images/revival_flash.png', width: 1200, height: 800, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox.shrink()),
            ),
          ),
        Center(
          child: Transform.scale(
            scale: ringScale,
            child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 5), boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.86), blurRadius: 50, spreadRadius: 14)])),
          ),
        ),
      ],
    );
  }
}
