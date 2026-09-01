import 'dart:convert';
import 'dart:typed_data';

import 'package:dopa_calc/src/effect_director.dart';
import 'package:dopa_calc/src/generated_sound_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeneratedSoundBank', () {
    test('主要Cueだけ専用WAVを生成する', () {
      expect(GeneratedSoundBank.bytesFor(EffectCue.preAlert), isNotNull);
      expect(GeneratedSoundBank.bytesFor(EffectCue.shutter), isNotNull);
      expect(GeneratedSoundBank.bytesFor(EffectCue.revival), isNotNull);
      expect(GeneratedSoundBank.bytesFor(EffectCue.jackpot), isNotNull);

      expect(GeneratedSoundBank.bytesFor(EffectCue.standard), isNull);
      expect(GeneratedSoundBank.bytesFor(EffectCue.symbolLock), isNull);
      expect(GeneratedSoundBank.bytesFor(EffectCue.pushPrompt), isNull);
      expect(GeneratedSoundBank.bytesFor(EffectCue.blackout), isNull);
    });

    test('生成音は16bit mono PCM WAVヘッダーを持つ', () {
      for (final cue in const [
        EffectCue.preAlert,
        EffectCue.shutter,
        EffectCue.revival,
        EffectCue.jackpot,
      ]) {
        final bytes = GeneratedSoundBank.bytesFor(cue)!;
        final data = ByteData.sublistView(bytes);

        expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF', reason: '$cue');
        expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE', reason: '$cue');
        expect(ascii.decode(bytes.sublist(12, 16)), 'fmt ', reason: '$cue');
        expect(ascii.decode(bytes.sublist(36, 40)), 'data', reason: '$cue');
        expect(data.getUint16(20, Endian.little), 1, reason: '$cue');
        expect(data.getUint16(22, Endian.little), 1, reason: '$cue');
        expect(data.getUint32(24, Endian.little), 22050, reason: '$cue');
        expect(data.getUint16(34, Endian.little), 16, reason: '$cue');
        expect(data.getUint32(40, Endian.little), bytes.length - 44);
      }
    });

    test('全専用SEに無音ではないPCMデータが入る', () {
      for (final cue in const [
        EffectCue.preAlert,
        EffectCue.shutter,
        EffectCue.revival,
        EffectCue.jackpot,
      ]) {
        final bytes = GeneratedSoundBank.bytesFor(cue)!;
        final data = ByteData.sublistView(bytes);
        var hasSignal = false;
        for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
          if (data.getInt16(offset, Endian.little) != 0) {
            hasSignal = true;
            break;
          }
        }
        expect(hasSignal, isTrue, reason: '$cue');
      }
    });

    test('専用SEは16bit上限へ張り付かずクリップを避ける', () {
      for (final cue in const [
        EffectCue.preAlert,
        EffectCue.shutter,
        EffectCue.revival,
        EffectCue.jackpot,
      ]) {
        final bytes = GeneratedSoundBank.bytesFor(cue)!;
        final data = ByteData.sublistView(bytes);
        var peak = 0;
        for (var offset = 44; offset + 1 < bytes.length; offset += 2) {
          final magnitude = data.getInt16(offset, Endian.little).abs();
          if (magnitude > peak) peak = magnitude;
        }
        expect(peak, lessThan(32767), reason: '$cue peak=$peak');
      }
    });

    test('Cueごとに長さが異なり音響役割を分離する', () {
      final preAlert = GeneratedSoundBank.bytesFor(EffectCue.preAlert)!;
      final shutter = GeneratedSoundBank.bytesFor(EffectCue.shutter)!;
      final revival = GeneratedSoundBank.bytesFor(EffectCue.revival)!;
      final jackpot = GeneratedSoundBank.bytesFor(EffectCue.jackpot)!;

      expect(preAlert.length, lessThan(shutter.length));
      expect(shutter.length, lessThan(revival.length));
      expect(revival.length, lessThan(jackpot.length));
    });

    test('生成結果をCue単位でキャッシュする', () {
      final first = GeneratedSoundBank.bytesFor(EffectCue.jackpot);
      final second = GeneratedSoundBank.bytesFor(EffectCue.jackpot);
      expect(identical(first, second), isTrue);
    });
  });
}
