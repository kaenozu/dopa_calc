import 'dart:math';
import 'dart:ui';

enum EffectRank { normal, chance, gekiatsu, premium }

enum EffectIntensity { low, medium, high, extreme }

/// 遊技機らしい予告・役物の出し分け。
enum EffectCue {
  standard,
  preAlert,
  symbolLock,
  pushPrompt,
  shutter,
  blackout,
  revival,
  jackpot,
}

/// ランクごとの外観テーマ。
class RankTheme {
  const RankTheme({
    required this.accent,
    required this.secondary,
    required this.label,
    required this.subtitle,
    required this.headlineSize,
    required this.letterSpacing,
  });

  /// ランクのメインカラー。
  final Color accent;

  /// バックドロップグラデーションのセカンダリカラー。
  final Color secondary;

  /// ランクバナーの表示ラベル。
  final String label;

  /// ランクバナーのサブタイトル。
  final String subtitle;

  /// ヘッドラインカードのフォントサイズ。
  final double headlineSize;

  /// ヘッドラインカードの文字間隔。
  final double letterSpacing;
}

/// EffectRank から外観テーマを取得する拡張。
extension RankThemeExtension on EffectRank {
  RankTheme get theme => switch (this) {
    EffectRank.normal => const RankTheme(
      accent: Color(0xFFE8F1FF),
      secondary: Color(0xFF10233C),
      label: 'NORMAL',
      subtitle: 'CALCULATION EFFECT',
      headlineSize: 56.0,
      letterSpacing: 5.0,
    ),
    EffectRank.chance => const RankTheme(
      accent: Color(0xFF4EDCFF),
      secondary: Color(0xFF00324B),
      label: 'CHANCE ZONE',
      subtitle: 'EXPECTATION UP',
      headlineSize: 82.0,
      letterSpacing: 7.0,
    ),
    EffectRank.gekiatsu => const RankTheme(
      accent: Color(0xFFFF3B30),
      secondary: Color(0xFF520000),
      label: '激 熱 ZONE',
      subtitle: 'HIGH IMPACT',
      headlineSize: 104.0,
      letterSpacing: 9.0,
    ),
    EffectRank.premium => const RankTheme(
      accent: Color(0xFFFFD700),
      secondary: Color(0xFF4A2400),
      label: 'PREMIUM RUSH',
      subtitle: 'MAXIMUM CELEBRATION',
      headlineSize: 126.0,
      letterSpacing: 10.0,
    ),
  };
}

/// インテンシティからエフェクト強度ファクタを返す。
double intensityFactor(EffectIntensity intensity) {
  return switch (intensity) {
    EffectIntensity.low => 0.45,
    EffectIntensity.medium => 0.7,
    EffectIntensity.high => 0.9,
    EffectIntensity.extreme => 1.0,
  };
}

/// ビートイベントの情報。
class BeatEvent {
  const BeatEvent({
    required this.beatIndex,
    required this.intensity,
    this.silent = false,
  });

  final int beatIndex;
  final EffectIntensity intensity;

  /// trueのとき、音+ハプティクスを両方抑止する（暗転ビート用）。
  final bool silent;
}

class EffectBeat {
  const EffectBeat({
    required this.headline,
    required this.subline,
    required this.duration,
    this.intensity = EffectIntensity.low,
    this.displayRank,
    this.cue = EffectCue.standard,
    this.dark = false,
  });

  final String headline;
  final String subline;
  final Duration duration;
  final EffectIntensity intensity;

  /// このビートで表示するランク。nullならPlanのrankを使用。
  final EffectRank? displayRank;

  /// 先バレ・図柄ロック・PUSH・シャッター・復活などの演出種別。
  final EffectCue cue;

  /// trueのとき、全画面暗転＋最小限のエフェクト（ハズレ偽装用）。
  final bool dark;
}

class EffectPlan {
  const EffectPlan({required this.rank, required this.beats});

  final EffectRank rank;
  final List<EffectBeat> beats;

  Duration get duration =>
      beats.fold(Duration.zero, (total, beat) => total + beat.duration);

  /// 視覚・音の両方で使う、そのビート時点の有効ランク。
  EffectRank rankForBeat(int index) => beats[index].displayRank ?? rank;
}

class EffectDirector {
  EffectDirector({Random? random, this.nextInt}) : _random = random ?? Random();

  final Random _random;
  final int Function(int max)? nextInt;

  int _roll(int max) => nextInt?.call(max) ?? _random.nextInt(max);

  EffectPlan planFor(String formattedResult) {
    final canonical = formattedResult.replaceAll(',', '');

    if (_isPremiumNumber(canonical)) {
      return EffectPlan(
        rank: EffectRank.premium,
        beats: [
          EffectBeat(
            headline: '・・・・・・',
            subline: '何かがおかしい',
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.low,
            displayRank: EffectRank.normal,
          ),
          EffectBeat(
            headline: '先 読 み 発 生',
            subline: '数字がざわついています',
            duration: const Duration(milliseconds: 1100),
            intensity: EffectIntensity.medium,
            displayRank: EffectRank.chance,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: '超・確・定',
            subline: '7系プレミアム確認中',
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.symbolLock,
          ),
          EffectBeat(
            headline: '押 せ',
            subline: 'PUSHで運命を決めろ',
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.pushPrompt,
          ),
          EffectBeat(
            headline: '役 物 閉 鎖',
            subline: '逃げ道を封鎖しています',
            duration: const Duration(milliseconds: 650),
            intensity: EffectIntensity.extreme,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.shutter,
          ),
          EffectBeat(
            headline: '…………',
            subline: '',
            duration: const Duration(milliseconds: 650),
            intensity: EffectIntensity.low,
            displayRank: EffectRank.normal,
            cue: EffectCue.blackout,
            dark: true,
          ),
          EffectBeat(
            headline: '復 活',
            subline: 'まだ終わってない',
            duration: const Duration(milliseconds: 1100),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.revival,
          ),
          EffectBeat(
            headline: 'ドパ計算RUSH',
            subline: '答えは最初から決まっている',
            duration: const Duration(milliseconds: 2500),
            intensity: EffectIntensity.extreme,
            displayRank: EffectRank.premium,
            cue: EffectCue.jackpot,
          ),
        ],
      );
    }

    if (canonical == '0') {
      return EffectPlan(
        rank: EffectRank.gekiatsu,
        beats: [
          EffectBeat(
            headline: '全 消 灯',
            subline: '画面が仕事をやめました',
            duration: const Duration(milliseconds: 1500),
            intensity: EffectIntensity.high,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: '…………',
            subline: 'からの？',
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.medium,
          ),
          EffectBeat(
            headline: '復 活',
            subline: 'そして答えは0',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.high,
            cue: EffectCue.revival,
          ),
        ],
      );
    }

    final roll = _roll(100);
    if (roll == 0) {
      return EffectPlan(
        rank: EffectRank.premium,
        beats: [
          EffectBeat(
            headline: '違 和 感',
            subline: 'ただの計算では終わらない',
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.medium,
            displayRank: EffectRank.chance,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: '激 熱',
            subline: '期待度 92%（演出上）',
            duration: const Duration(milliseconds: 1100),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.symbolLock,
          ),
          EffectBeat(
            headline: '押 せ',
            subline: 'PUSHでプレミアムを呼べ',
            duration: const Duration(milliseconds: 800),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.pushPrompt,
          ),
          EffectBeat(
            headline: '役 物 閉 鎖',
            subline: 'まだ結果は見せません',
            duration: const Duration(milliseconds: 550),
            intensity: EffectIntensity.extreme,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.shutter,
          ),
          EffectBeat(
            headline: '…………',
            subline: '',
            duration: const Duration(milliseconds: 650),
            intensity: EffectIntensity.low,
            displayRank: EffectRank.normal,
            cue: EffectCue.blackout,
            dark: true,
          ),
          EffectBeat(
            headline: '復 活',
            subline: 'まだだ！！',
            duration: const Duration(milliseconds: 1000),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.revival,
          ),
          EffectBeat(
            headline: '超 計 算',
            subline: 'PREMIUM',
            duration: const Duration(milliseconds: 2300),
            intensity: EffectIntensity.extreme,
            displayRank: EffectRank.premium,
            cue: EffectCue.jackpot,
          ),
        ],
      );
    }
    if (roll < 10) {
      return EffectPlan(
        rank: EffectRank.gekiatsu,
        beats: [
          EffectBeat(
            headline: 'CHANCE',
            subline: '期待しても計算結果は変わりません',
            duration: const Duration(milliseconds: 1000),
            intensity: EffectIntensity.high,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: '激 熱',
            subline: '期待度 92%（演出上）',
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.extreme,
            cue: EffectCue.symbolLock,
          ),
          EffectBeat(
            headline: '押 せ',
            subline: 'PUSHで復活を呼び込め',
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.high,
            cue: EffectCue.pushPrompt,
          ),
          EffectBeat(
            headline: 'まだだ！！',
            subline: '無駄にもう一回煽ります',
            duration: const Duration(milliseconds: 1700),
            intensity: EffectIntensity.high,
            cue: EffectCue.revival,
          ),
        ],
      );
    }
    if (roll < 30) {
      return EffectPlan(
        rank: EffectRank.chance,
        beats: [
          EffectBeat(
            headline: 'CHANCE',
            subline: 'ただの計算なのに期待度UP',
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.medium,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: '計 算 リ ー チ',
            subline: '答えを出すだけです',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.medium,
            cue: EffectCue.symbolLock,
          ),
        ],
      );
    }

    return EffectPlan(
      rank: EffectRank.normal,
      beats: [
        EffectBeat(
          headline: '計 算 中',
          subline: '無駄に溜めています',
          duration: const Duration(milliseconds: 1400),
          intensity: EffectIntensity.low,
        ),
      ],
    );
  }

  bool _isPremiumNumber(String value) {
    final normalized = value.startsWith('-') ? value.substring(1) : value;
    return normalized == '7' ||
        normalized == '77' ||
        normalized == '777' ||
        normalized == '7777' ||
        normalized == '8192';
  }
}
