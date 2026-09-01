import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculation_controller.dart';
import 'calculator_engine.dart';
import 'effect_director.dart';
import 'effect_overlay.dart';
import 'effect_player.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with SingleTickerProviderStateMixin {
  final _controller = CalculationController();
  final _director = EffectDirector();

  late final EffectPlayer _effectPlayer;
  late final AnimationController _pulseController;
  EffectPlan? _activePlan;

  final _debugClock = Stopwatch();
  final List<_DebugEffectLogEntry> _debugLog = [];
  var _debugCurrentCue = 'idle';
  var _debugExpanded = false;
  var _debugRefreshScheduled = false;

  static const _keys = <String>[
    'AC',
    '⌫',
    '÷',
    '×',
    '7',
    '8',
    '9',
    '−',
    '4',
    '5',
    '6',
    '+',
    '1',
    '2',
    '3',
    '±',
    '0',
    '00',
    '.',
    '=',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    if (kDebugMode) {
      _debugClock.start();
    }
    _effectPlayer = EffectPlayer(
      diagnosticSink: kDebugMode ? _onEffectDiagnostic : null,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      lowerBound: 0.94,
      upperBound: 1.06,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations && _pulseController.isAnimating) {
      _stopPulse();
    } else if (!disableAnimations &&
        _controller.isResolving &&
        !_pulseController.isAnimating) {
      _startPulse();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _pulseController.dispose();
    unawaited(_effectPlayer.dispose());
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  // ── パルスアニメーション ──────────────────────────────────

  void _startPulse() {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations || _pulseController.isAnimating) return;
    _pulseController.repeat(reverse: true);
  }

  void _stopPulse() {
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _pulseController.value = 1;
  }

  // ── キー入力 ──────────────────────────────────────────────

  void _press(String key) {
    if (_controller.isResolving) return;
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);

    switch (key) {
      case 'AC':
        _clear();
        return;
      case '⌫':
        _controller.backspace();
        return;
      case '=':
        _resolve();
        return;
      case '±':
        _controller.toggleSign();
        return;
      case '+':
      case '−':
      case '×':
      case '÷':
        _controller.appendOperator(key);
        return;
      default:
        _controller.appendNumber(key);
        return;
    }
  }

  void _clear() {
    unawaited(_effectPlayer.cancelPending());
    _stopPulse();
    setState(() {
      _activePlan = null;
      if (kDebugMode) _debugCurrentCue = 'idle';
    });
    _controller.clear();
  }

  // ── 演出オーケストレーション ──────────────────────────────

  void _resolve() {
    if (_controller.isEmpty || _controller.isResolving) return;

    try {
      final formatted = _controller.evaluate();
      final plan = _director.planFor(formatted);

      HapticFeedback.heavyImpact();
      _controller.beginResolving(formatted);
      setState(() {
        _activePlan = plan;
      });
      _startPulse();
      // タイミングはOverlayが管理。完了時にonSkipが呼ばれる。
    } on CalculatorException catch (error) {
      HapticFeedback.heavyImpact();
      _controller.showError(error.message);
      setState(() {
        _activePlan = null;
      });
    }
  }

  void _handleBeat(EffectPlan plan, BeatEvent event) {
    final cue = plan.beats[event.beatIndex].cue;
    if (kDebugMode) {
      _debugCurrentCue = cue.name;
      _appendDebugLog(
        'CUE',
        '${event.beatIndex + 1}/${plan.beats.length} ${cue.name} '
            '${plan.rankForBeat(event.beatIndex).name}',
      );
    }

    unawaited(
      _effectPlayer.playBeat(
        plan.rankForBeat(event.beatIndex),
        event,
        cue: cue,
      ),
    );
  }

  void _skipEffect() {
    if (!_controller.isResolving) return;
    unawaited(_effectPlayer.cancelPending());
    _stopPulse();
    _controller.finishResult(_controller.lastFormattedResult!);
    setState(() {
      _activePlan = null;
      if (kDebugMode) _debugCurrentCue = 'idle';
    });
  }

  // ── Debug実機診断 ─────────────────────────────────────────

  void _debugForcePremium() {
    if (!kDebugMode || _controller.isResolving) return;

    unawaited(_effectPlayer.cancelPending());
    _stopPulse();
    _debugClock.reset();
    _debugLog.clear();
    _debugCurrentCue = 'preparing';

    final plan = _director.planFor('777');
    _controller.beginResolving('777');
    setState(() {
      _activePlan = plan;
      _debugExpanded = true;
    });
    _appendDebugLog('TEST', 'FORCE PREMIUM result=777');
    _startPulse();
  }

  void _onEffectDiagnostic(EffectDiagnosticEvent event) {
    if (!kDebugMode) return;

    final cue = event.cue?.name ?? '-';
    final beat = event.beatIndex == null ? '-' : '${event.beatIndex! + 1}';
    final channel = switch (event.kind) {
      EffectDiagnosticKind.sound => 'SE',
      EffectDiagnosticKind.haptic => 'HAPTIC',
      EffectDiagnosticKind.control => 'CTRL',
    };
    _appendDebugLog(channel, 'b$beat $cue ${event.detail}');
  }

  void _appendDebugLog(String channel, String message) {
    if (!kDebugMode) return;

    _debugLog.insert(
      0,
      _DebugEffectLogEntry(
        elapsedMilliseconds: _debugClock.elapsedMilliseconds,
        channel: channel,
        message: message,
      ),
    );
    if (_debugLog.length > 14) {
      _debugLog.removeRange(14, _debugLog.length);
    }
    _scheduleDebugRefresh();
  }

  void _scheduleDebugRefresh() {
    if (_debugRefreshScheduled) return;
    _debugRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugRefreshScheduled = false;
      if (mounted) setState(() {});
    });
  }

  void _clearDebugLog() {
    if (!kDebugMode) return;
    setState(() {
      _debugLog.clear();
      _debugCurrentCue = _controller.isResolving ? _debugCurrentCue : 'idle';
      _debugClock.reset();
    });
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                children: [
                  _Header(onReset: _clear),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 3,
                    child: _Display(
                      expression: _controller.expression,
                      display: _controller.display,
                      isResult: _controller.showResult,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 7,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const columns = 4;
                        const rows = 5;
                        const gap = 10.0;
                        final keyWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        final keyHeight =
                            (constraints.maxHeight - gap * (rows - 1)) / rows;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: gap,
                                crossAxisSpacing: gap,
                                childAspectRatio: keyWidth / keyHeight,
                              ),
                          itemCount: _keys.length,
                          itemBuilder: (context, index) {
                            final key = _keys[index];
                            return _CalcKey(
                              label: key,
                              onTap: () => _press(key),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_activePlan case final plan?)
              EffectOverlay(
                plan: plan,
                pulse: _pulseController,
                onBeat: (event) => _handleBeat(plan, event),
                onSkip: _skipEffect,
                resultText: _controller.lastFormattedResult,
              ),
            if (kDebugMode)
              Positioned(
                top: 54,
                right: 8,
                child: _DebugEffectDiagnosticsPanel(
                  expanded: _debugExpanded,
                  currentCue: _debugCurrentCue,
                  resolving: _controller.isResolving,
                  entries: _debugLog,
                  onForcePremium: _debugForcePremium,
                  onToggle: () {
                    setState(() => _debugExpanded = !_debugExpanded);
                  },
                  onClear: _clearDebugLog,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _DebugEffectLogEntry {
  const _DebugEffectLogEntry({
    required this.elapsedMilliseconds,
    required this.channel,
    required this.message,
  });

  final int elapsedMilliseconds;
  final String channel;
  final String message;
}

class _DebugEffectDiagnosticsPanel extends StatelessWidget {
  const _DebugEffectDiagnosticsPanel({
    required this.expanded,
    required this.currentCue,
    required this.resolving,
    required this.entries,
    required this.onForcePremium,
    required this.onToggle,
    required this.onClear,
  });

  final bool expanded;
  final String currentCue;
  final bool resolving;
  final List<_DebugEffectLogEntry> entries;
  final VoidCallback onForcePremium;
  final VoidCallback onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('debug-effect-diagnostics'),
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E5FF), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'DEBUG FX',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CUE: $currentCue',
                    key: const ValueKey('debug-current-cue'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('debug-toggle-diagnostics'),
                  onPressed: onToggle,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  color: Colors.white70,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('debug-force-premium'),
                    onPressed: resolving ? null : onForcePremium,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFFD400),
                      side: const BorderSide(color: Color(0xFFFFD400)),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'FORCE PREMIUM',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  key: const ValueKey('debug-clear-log'),
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('CLEAR', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
            if (expanded) ...[
              const Divider(height: 10, color: Colors.white24),
              SizedBox(
                height: 128,
                child: entries.isEmpty
                    ? const Center(
                        child: Text(
                          'No events',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      )
                    : ListView.builder(
                        key: const ValueKey('debug-diagnostic-log'),
                        reverse: false,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final elapsed = entry.elapsedMilliseconds
                              .toString()
                              .padLeft(5, '0');
                          return Text(
                            '+${elapsed}ms ${entry.channel.padRight(6)} '
                            '${entry.message}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              height: 1.35,
                              fontFamily: 'monospace',
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFD400), width: 2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'ドパ電卓',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
        const Spacer(),
        TextButton(onPressed: onReset, child: const Text('RESET')),
      ],
    );
  }
}

class _Display extends StatelessWidget {
  const _Display({
    required this.expression,
    required this.display,
    required this.isResult,
  });

  final String expression;
  final String display;
  final bool isResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF161922), Color(0xFF0B0D12)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(blurRadius: 24, spreadRadius: -10, color: Colors.black),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            isResult ? 'RESULT' : (expression.isEmpty ? 'READY' : 'CALC'),
            style: const TextStyle(
              color: Color(0xFFFFD400),
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              display,
              maxLines: 1,
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w900,
                color: isResult ? const Color(0xFFFFF06A) : Colors.white,
                shadows: isResult
                    ? const [Shadow(blurRadius: 20, color: Color(0xFFFF8A00))]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalcKey extends StatelessWidget {
  const _CalcKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  bool get _isOperator => const {'÷', '×', '−', '+', '='}.contains(label);
  bool get _isUtility => const {'AC', '⌫', '±'}.contains(label);

  @override
  Widget build(BuildContext context) {
    final background = _isOperator
        ? const Color(0xFFFFC400)
        : _isUtility
        ? const Color(0xFF343946)
        : const Color(0xFF1A1E27);
    final foreground = _isOperator ? Colors.black : Colors.white;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
