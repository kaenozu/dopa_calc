import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'celebration_painter.dart';
import 'effect_director.dart';
import 'effect_widgets.dart';

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
    } else {
      _motionController.repeat();
    }
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _resultTimer?.cancel();
    _motionController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _scheduleNextBeat() {
    final beat = widget.plan.beats[_beatIndex];
    _beatTimer = Timer(beat.duration, () {
      if (!mounted) return;

      // 最後のビート到達: 結果表示 or 即時完了
      if (_beatIndex >= widget.plan.beats.length - 1) {
        if (widget.resultText != null) {
          setState(() => _showingResult = true);
          // 結果を1.5秒表示してからオーバーレイを閉じる
          _resultTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) widget.onSkip();
          });
        } else {
          // resultTextなしなら即時完了
          widget.onSkip();
        }
        return;
      }

      setState(() => _beatIndex++);
      // BeatEventでビート情報を渡す（音+ハプティクスはEffectPlayerが処理）
      widget.onBeat(
        BeatEvent(
          beatIndex: _beatIndex,
          intensity: widget.plan.beats[_beatIndex].intensity,
          silent: widget.plan.beats[_beatIndex].dark,
        ),
      );
      if (!_reduceMotion) {
        _flashController.forward(from: 0);
      }
      _scheduleNextBeat();
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final beat = plan.beats[_beatIndex];
    // displayRankが設定されていればそちらを使用、なければPlanのランク
    final effectiveRank = beat.displayRank ?? plan.rank;
    final theme = effectiveRank.theme;

    // 結果表示フェーズ: 計算結果を画面中央にドラマチックに表示
    if (_showingResult && widget.resultText != null) {
      return Positioned.fill(
        child: Material(
          color: Colors.black,
          child: Center(
            child: Text(
              widget.resultText!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 120,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                shadows: [
                  Shadow(color: theme.accent, blurRadius: 60),
                  Shadow(color: theme.accent, blurRadius: 120),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // darkビート: 全エフェクトをオフにし、静寂演出
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
            ]),
            builder: (context, child) {
              // Reduce Motion設定 または darkビート で全モーション無効
              final motionDisabled = _reduceMotion || isDark;
              final phase = motionDisabled ? 0.0 : _motionController.value;
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
                  // darkビートでは非常に暗い背景のみ表示
                  EffectBackdrop(
                    rank: effectiveRank,
                    accent: isDark ? Colors.black : accent,
                  ),
                  // パーティクル・放射線はdarkで非表示
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
                  // 走査光: Reduce Motion または darkビートで非表示
                  if (!motionDisabled)
                    SweepBeam(accent: accent, phase: phase, impact: impact),
                  if (!isDark) EdgeFrame(accent: accent, impact: impact),
                  SafeArea(
                    minimum: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    child: Column(
                      children: [
                        // ランクバナー: darkビートでは非表示
                        if (!isDark)
                          RankBanner(
                            rankLabel: theme.label,
                            rankSubtitle: theme.subtitle,
                            accent: accent,
                            phase: phase,
                            reduceMotion: motionDisabled,
                          ),
                        const Spacer(),
                        // ヘッドラインカード: darkビートでは最小限の表示
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
                        // プログレス表示: darkビートでは非表示
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
