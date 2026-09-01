import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'celebration_painter.dart';
import 'effect_director.dart';
import 'effect_widgets.dart';
import 'pachinko_accent_painter.dart';
import 'pachinko_cinematic_widgets.dart';
import 'pachinko_machine_widgets.dart';
import 'pachinko_widgets.dart';

class EffectOverlay extends StatefulWidget {
  const EffectOverlay({
    required this.plan,
    required this.pulse,
    required this.onBeat,
    required this.onSkip,
    this.resultText,
    super.key,
  });

  final EffectPlan plan;
  final Animation<double> pulse;
  final ValueChanged<BeatEvent> onBeat;
  final VoidCallback onSkip;

  /// 最後のビート後に表示する計算結果。nullなら通常のビート表示を維持。
  final String? resultText;

  @override
  State<EffectOverlay> createState() => _EffectOverlayState();
}

class _EffectOverlayState extends State<EffectOverlay>
    with TickerProviderStateMixin {
  Timer? _beatTimer;
  Timer? _resultTimer;
  var _beatIndex = 0;
  var _reduceMotion = false;
  var _showingResult = false;

  late final AnimationController _motionController;
  late final AnimationController _flashController;
  late final AnimationController _beatProgressController;

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
    _beatProgressController = AnimationController(
      vsync: this,
      duration: widget.plan.beats.first.duration,
    )..forward();
    widget.onBeat(
      BeatEvent(
        beatIndex: _beatIndex,
        intensity: widget.plan.beats[_beatIndex].intensity,
        silent: widget.plan.beats[_beatIndex].dark,
      ),
    );
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
      _beatProgressController.stop();
      _beatProgressController.value = 1;
    } else {
      _motionController.repeat();
      if (!_beatProgressController.isCompleted &&
          !_beatProgressController.isAnimating) {
        _beatProgressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _resultTimer?.cancel();
    _motionController.dispose();
    _flashController.dispose();
    _beatProgressController.dispose();
    super.dispose();
  }

  void _startProgress(Duration duration) {
    _beatProgressController.duration = duration;
    if (_reduceMotion) {
      _beatProgressController.value = 1;
    } else {
      _beatProgressController.forward(from: 0);
    }
  }

  void _scheduleNextBeat() {
    final beat = widget.plan.beats[_beatIndex];
    _beatTimer = Timer(beat.duration, () {
      if (!mounted) return;

      if (_beatIndex >= widget.plan.beats.length - 1) {
        if (widget.resultText != null) {
          setState(() => _showingResult = true);
          _startProgress(const Duration(milliseconds: 1500));
          _resultTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) widget.onSkip();
          });
        } else {
          widget.onSkip();
        }
        return;
      }

      setState(() => _beatIndex++);
      final nextBeat = widget.plan.beats[_beatIndex];
      _startProgress(nextBeat.duration);
      widget.onBeat(
        BeatEvent(
          beatIndex: _beatIndex,
          intensity: nextBeat.intensity,
          silent: nextBeat.dark,
        ),
      );
      if (!_reduceMotion) {
        _flashController.forward(from: 0);
      }
      _scheduleNextBeat();
    });
  }

  EffectIntensity _resultIntensity(EffectRank rank) {
    return switch (rank) {
      EffectRank.normal => EffectIntensity.medium,
      EffectRank.chance => EffectIntensity.high,
      EffectRank.gekiatsu || EffectRank.premium => EffectIntensity.extreme,
    };
  }

  EffectCue _resultCue(EffectRank rank) {
    return switch (rank) {
      EffectRank.normal => EffectCue.standard,
      EffectRank.chance => EffectCue.preAlert,
      EffectRank.gekiatsu => EffectCue.revival,
      EffectRank.premium => EffectCue.jackpot,
    };
  }

  Widget _buildResultClimax(EffectPlan plan) {
    final finalRank = plan.rankForBeat(plan.beats.length - 1);
    final theme = finalRank.theme;
    final intensity = _resultIntensity(finalRank);
    final resultCue = _resultCue(finalRank);

    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: Semantics(
          liveRegion: true,
          label: '計算結果 ${widget.resultText}',
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.pulse,
              _motionController,
              _beatProgressController,
            ]),
            builder: (context, child) {
              final motionDisabled = _reduceMotion;
              final phase = motionDisabled ? 0.0 : _motionController.value;
              final progress = motionDisabled
                  ? 1.0
                  : _beatProgressController.value;
              final accent = _animatedAccent(theme.accent, finalRank, phase);
              final impact = intensityFactor(intensity);

              return Stack(
                fit: StackFit.expand,
                children: [
                  EffectBackdrop(rank: finalRank, accent: accent),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: CelebrationPainter(
                        rank: finalRank,
                        intensity: intensity,
                        beatIndex: plan.beats.length,
                        phase: phase,
                        accent: accent,
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: PachinkoAccentPainter(
                        rank: finalRank,
                        intensity: intensity,
                        beatIndex: plan.beats.length,
                        phase: phase,
                        accent: accent,
                      ),
                    ),
                  ),
                  PachinkoMachineOverlay(
                    cue: resultCue,
                    rank: finalRank,
                    accent: accent,
                    phase: phase,
                    impact: impact,
                    reduceMotion: motionDisabled,
                  ),
                  PachinkoCinematicOverlay(
                    cue: resultCue,
                    accent: accent,
                    phase: phase,
                    progress: progress,
                    reduceMotion: motionDisabled,
                  ),
                  if (!motionDisabled)
                    SweepBeam(accent: accent, phase: phase, impact: impact),
                  EdgeFrame(accent: accent, impact: impact),
                  CabinetLamps(
                    accent: accent,
                    phase: phase,
                    impact: impact,
                    reduceMotion: motionDisabled,
                  ),
                  ResultClimax(
                    resultText: widget.resultText!,
                    rankLabel: theme.label,
                    accent: accent,
                    phase: phase,
                    reduceMotion: motionDisabled,
                    onSkip: widget.onSkip,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final beat = plan.beats[_beatIndex];
    final effectiveRank = plan.rankForBeat(_beatIndex);
    final theme = effectiveRank.theme;

    if (_showingResult && widget.resultText != null) {
      return _buildResultClimax(plan);
    }

    final isDark = beat.dark;

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
              _beatProgressController,
            ]),
            builder: (context, child) {
              final motionDisabled = _reduceMotion || isDark;
              final phase = motionDisabled ? 0.0 : _motionController.value;
              final progress = motionDisabled
                  ? 1.0
                  : _beatProgressController.value;
              final pulse = motionDisabled ? 1.0 : widget.pulse.value;
              final accent = _animatedAccent(
                theme.accent,
                effectiveRank,
                phase,
              );
              final impact = isDark ? 0.0 : intensityFactor(beat.intensity);
              final flash = motionDisabled
                  ? 0.0
                  : (1 - Curves.easeOut.transform(_flashController.value)) *
                        impact;
              final shakeX = motionDisabled
                  ? 0.0
                  : math.sin(phase * math.pi * 14) * 5.5 * impact;
              final shakeY = motionDisabled
                  ? 0.0
                  : math.cos(phase * math.pi * 18) * 3.5 * impact;
              final rotation = motionDisabled
                  ? 0.0
                  : math.sin(phase * math.pi * 10) * 0.012 * impact;

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (isDark)
                    const ColoredBox(color: Colors.black)
                  else
                    EffectBackdrop(rank: effectiveRank, accent: accent),
                  if (!isDark)
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: CelebrationPainter(
                          rank: effectiveRank,
                          intensity: beat.intensity,
                          beatIndex: _beatIndex,
                          phase: phase,
                          accent: accent,
                        ),
                      ),
                    ),
                  if (!isDark)
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: PachinkoAccentPainter(
                          rank: effectiveRank,
                          intensity: beat.intensity,
                          beatIndex: _beatIndex,
                          phase: phase,
                          accent: accent,
                        ),
                      ),
                    ),
                  if (!isDark)
                    PachinkoMachineOverlay(
                      cue: beat.cue,
                      rank: effectiveRank,
                      accent: accent,
                      phase: phase,
                      impact: impact,
                      reduceMotion: motionDisabled,
                    ),
                  if (!isDark)
                    PachinkoCinematicOverlay(
                      cue: beat.cue,
                      accent: accent,
                      phase: phase,
                      progress: progress,
                      reduceMotion: motionDisabled,
                    ),
                  if (!motionDisabled)
                    SweepBeam(accent: accent, phase: phase, impact: impact),
                  if (!isDark) EdgeFrame(accent: accent, impact: impact),
                  if (!isDark)
                    CabinetLamps(
                      accent: accent,
                      phase: phase,
                      impact: impact,
                      reduceMotion: motionDisabled,
                    ),
                  SafeArea(
                    minimum: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    child: Column(
                      children: [
                        if (!isDark)
                          RankBanner(
                            rankLabel: theme.label,
                            rankSubtitle: theme.subtitle,
                            accent: accent,
                            phase: phase,
                            reduceMotion: motionDisabled,
                          ),
                        if (!isDark) ...[
                          const SizedBox(height: 8),
                          HeatGauge(rank: effectiveRank, accent: accent),
                        ],
                        const Spacer(),
                        Transform.rotate(
                          angle: rotation,
                          child: Transform.translate(
                            offset: Offset(shakeX, shakeY),
                            child: Transform.scale(
                              scale: 1 + (pulse - 1) * 0.55,
                              child: HeadlineCard(
                                beat: beat,
                                rank: effectiveRank,
                                accent: accent,
                                phase: phase,
                                reduceMotion: _reduceMotion,
                                dark: isDark,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!isDark)
                          ProgressPips(
                            current: _beatIndex,
                            total: plan.beats.length,
                            accent: accent,
                            reduceMotion: motionDisabled,
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
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
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
                          alpha: (flash * 0.72).clamp(0.0, 0.72).toDouble(),
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

Color _animatedAccent(Color base, EffectRank rank, double phase) {
  if (rank != EffectRank.premium) return base;
  final hsv = HSVColor.fromColor(base);
  return hsv.withHue((hsv.hue + phase * 110) % 360).toColor();
}
