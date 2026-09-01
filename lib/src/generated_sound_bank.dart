import 'dart:math' as math;
import 'dart:typed_data';

import 'effect_director.dart';

/// バイナリアセットを増やさず、短い専用SEをPCM WAVとして合成する。
///
/// 生成結果はCueごとにキャッシュし、演出中の再生成を避ける。
class GeneratedSoundBank {
  GeneratedSoundBank._();

  static const _sampleRate = 22050;
  static final Map<EffectCue, Uint8List> _cache = {};

  static void prime() {
    for (final cue in const [
      EffectCue.preAlert,
      EffectCue.shutter,
      EffectCue.revival,
      EffectCue.jackpot,
    ]) {
      bytesFor(cue);
    }
  }

  static Uint8List? bytesFor(EffectCue cue) {
    if (!_isGeneratedCue(cue)) return null;
    return _cache.putIfAbsent(cue, () => _generate(cue));
  }

  static bool _isGeneratedCue(EffectCue cue) {
    return switch (cue) {
      EffectCue.preAlert ||
      EffectCue.shutter ||
      EffectCue.revival ||
      EffectCue.jackpot =>
        true,
      _ => false,
    };
  }

  static Uint8List _generate(EffectCue cue) {
    return switch (cue) {
      EffectCue.preAlert => _wav(0.22, _preAlertSample),
      EffectCue.shutter => _shutterWav(),
      EffectCue.revival => _wav(0.55, _revivalSample),
      EffectCue.jackpot => _wav(0.95, _jackpotSample),
      _ => throw ArgumentError.value(cue, 'cue', 'generated cue required'),
    };
  }

  static double _preAlertSample(double t, double duration) {
    final progress = t / duration;
    final envelope = _attackRelease(t, duration, attack: 0.006, release: 0.035);
    // 先バレらしい短い上昇チャープ。位相積分で周波数を滑らかに上げる。
    final phase = 2 * math.pi * (1450 * t + 2100 * t * t);
    final carrier = math.sin(phase);
    final harmonic = 0.34 * math.sin(phase * 2.02);
    final pulse = progress < 0.46 || progress > 0.58 ? 1.0 : 0.26;
    return (carrier + harmonic) * 0.62 * envelope * pulse;
  }

  static Uint8List _shutterWav() {
    var noiseState = 0x13579BDF;
    double sample(double t, double duration) {
      noiseState = (1664525 * noiseState + 1013904223) & 0x7fffffff;
      final noise = (noiseState / 0x3fffffff) - 1.0;
      final envelope = _attackRelease(
        t,
        duration,
        attack: 0.002,
        release: 0.10,
      );
      final impactDecay = math.exp(-t * 15.0);
      final ringDecay = math.exp(-t * 7.2);
      final thump = math.sin(2 * math.pi * 82 * t) * impactDecay * 0.60;
      final metal =
          (math.sin(2 * math.pi * 690 * t) * 0.30 +
              math.sin(2 * math.pi * 1170 * t) * 0.20) *
          ringDecay;
      final scrape = noise * impactDecay * 0.26;
      return (thump + metal + scrape) * envelope;
    }

    return _wav(0.38, sample);
  }

  static double _revivalSample(double t, double duration) {
    final envelope = _attackRelease(t, duration, attack: 0.004, release: 0.08);
    final impact = math.sin(2 * math.pi * 72 * t) * math.exp(-t * 10.0) * 0.55;
    final sweepPhase = 2 * math.pi * (230 * t + 620 * t * t);
    final rise = math.sin(sweepPhase) * (0.25 + 0.55 * (t / duration));
    final shimmer = math.sin(sweepPhase * 2.01) * 0.18;
    return (impact + rise + shimmer) * envelope * 0.72;
  }

  static double _jackpotSample(double t, double duration) {
    const notes = [523.25, 659.25, 783.99, 1046.50];
    const noteSpan = 0.18;
    var sample = 0.0;

    for (var index = 0; index < notes.length; index++) {
      final start = index * noteSpan;
      final local = t - start;
      if (local < 0 || local > 0.34) continue;
      final noteEnvelope = math.min(local / 0.012, 1.0) * math.exp(-local * 5.0);
      final frequency = notes[index];
      final phase = 2 * math.pi * frequency * local;
      sample +=
          (math.sin(phase) + 0.30 * math.sin(phase * 2) + 0.12 * math.sin(phase * 3)) *
          noteEnvelope *
          0.30;
    }

    final sparkle =
        math.sin(2 * math.pi * 1760 * t) *
        math.exp(-math.max(0.0, t - 0.52) * 8.0) *
        (t > 0.52 ? 0.12 : 0.0);
    final master = _attackRelease(t, duration, attack: 0.005, release: 0.10);
    return (sample + sparkle) * master;
  }

  static double _attackRelease(
    double t,
    double duration, {
    required double attack,
    required double release,
  }) {
    final attackGain = attack <= 0 ? 1.0 : math.min(t / attack, 1.0);
    final remaining = duration - t;
    final releaseGain = release <= 0 ? 1.0 : math.min(remaining / release, 1.0);
    return math.max(0.0, math.min(attackGain, releaseGain));
  }

  static Uint8List _wav(
    double durationSeconds,
    double Function(double t, double duration) sampleAt,
  ) {
    final sampleCount = (_sampleRate * durationSeconds).round();
    final dataSize = sampleCount * 2;
    final bytes = ByteData(44 + dataSize);

    _ascii(bytes, 0, 'RIFF');
    bytes.setUint32(4, 36 + dataSize, Endian.little);
    _ascii(bytes, 8, 'WAVE');
    _ascii(bytes, 12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, _sampleRate, Endian.little);
    bytes.setUint32(28, _sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    _ascii(bytes, 36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / _sampleRate;
      final sample = sampleAt(t, durationSeconds).clamp(-1.0, 1.0);
      bytes.setInt16(44 + i * 2, (sample * 32767).round(), Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  static void _ascii(ByteData data, int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }
}
