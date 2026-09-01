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

  int _roll(int max) {
    final raw = nextInt?.call(max) ?? _random.nextInt(max);
    // テストの nextInt モックが maxを無視して固定値を返す場合でも安全に収める
    return raw % max;
  }

  T _pick<T>(List<T> items) => items[_roll(items.length)];

  EffectPlan planFor(String formattedResult) {
    final canonical = formattedResult.replaceAll(',', '');

    if (_isPremiumNumber(canonical)) {
      // PREMIUMは毎回少し違う顔を見せる（保留変化・疑似連イメージでバリエーション）
      final premiumVariant = _roll(4);
      final revivalHeadlines = ['復 活', 'まだだ!!', '諦めるな', '起きろ!!'];
      final jackpotHeadlines = ['ドパ計算RUSH', '777 JACKPOT', '超ドパRUSH', 'PREMIUM確定'];
      final jackpotSublines = [
        '答えは最初から決まっている',
        '虹色に輝け',
        '全てを解放する',
        'ここからが本番',
      ];
      final preAlertPairs = [
        ('先 読 み 発 生', '数字がざわついています'),
        ('保留変化!!', '色が変わった!?'),
        ('違和感発生', '何かが違う...'),
        ('激ザワ!!', '盤面が騒がしい'),
      ];
      final lockPairs = [
        ('超・確・定', '7系プレミアム確認中'),
        ('擬似連×2', 'もう一度!'),
        ('擬似連×3', '止まらない!!'),
        ('金保留!!', '虹の前兆'),
      ];
      final preAlert = _pick(preAlertPairs);
      final lock = _pick(lockPairs);
      final revivalHead = _pick(revivalHeadlines);
      final jackpotHead = _pick(jackpotHeadlines);
      final jackpotSub = _pick(jackpotSublines);
      // variantでサブタイトルの強さを変える
      final openers = [
        ('・・・・・・', '何かがおかしい'),
        ('ざわ・・・', '空気が変わった'),
        ('…………', '静寂の中で'),
        ('キュイン!!', '先バレ!?'),
      ];
      final opener = openers[premiumVariant];
      return EffectPlan(
        rank: EffectRank.premium,
        beats: [
          EffectBeat(
            headline: opener.$1,
            subline: opener.$2,
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.low,
            displayRank: EffectRank.normal,
          ),
          EffectBeat(
            headline: preAlert.$1,
            subline: preAlert.$2,
            duration: const Duration(milliseconds: 1100),
            intensity: EffectIntensity.medium,
            displayRank: EffectRank.chance,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: lock.$1,
            subline: lock.$2,
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.symbolLock,
          ),
          EffectBeat(
            headline: '押 せ',
            subline: _pick(['PUSHで運命を決めろ', '連打で未来を掴め', '一撃で決めろ!!']),
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.pushPrompt,
          ),
          EffectBeat(
            headline: _pick(['役 物 閉 鎖', 'シャッター閉鎖', '完全包囲']),
            subline: _pick(['逃げ道を封鎖しています', 'もう戻れない', '覚悟はいいか']), // variation
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
            headline: revivalHead,
            subline: _pick(['まだ終わってない', 'ここからだ', '奇跡を起こせ', '立ち上がれ!!']),
            duration: const Duration(milliseconds: 1100),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.revival,
          ),
          EffectBeat(
            headline: jackpotHead,
            subline: jackpotSub,
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
      // 1%ランダムPREMIUMも毎回バリエーションを持たせる
      final heads = ['違 和 感', '虹の予感', '金保留降臨', '激震!!'];
      final subs = ['ただの計算では終わらない', '虹色に染まる', 'プレミアムの鼓動', '運命の1%'];
      return EffectPlan(
        rank: EffectRank.premium,
        beats: [
          EffectBeat(
            headline: _pick(heads),
            subline: _pick(subs),
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.medium,
            displayRank: EffectRank.chance,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: _pick(['激 熱', '灼熱!!', '超激熱']),
            subline: '期待度 92%（演出上）',
            duration: const Duration(milliseconds: 1100),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.symbolLock,
          ),
          EffectBeat(
            headline: '押 せ',
            subline: _pick(['PUSHでプレミアムを呼べ', '叩け!!', '魂を込めろ']),
            duration: const Duration(milliseconds: 800),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.pushPrompt,
          ),
          EffectBeat(
            headline: _pick(['役 物 閉 鎖', '扉閉鎖']),
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
            headline: _pick(['復 活', '覚醒', '再始動']),
            subline: _pick(['まだだ！！', 'ここからが本番', '奇跡の鼓動']),
            duration: const Duration(milliseconds: 1000),
            intensity: EffectIntensity.high,
            displayRank: EffectRank.gekiatsu,
            cue: EffectCue.revival,
          ),
          EffectBeat(
            headline: _pick(['超 計 算', '超ドパRUSH', '虹JACKPOT']),
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
      final gekiHeads = ['激 熱', '灼熱', '超激熱', '激アツ!!'];
      final chanceSubs = ['期待しても計算結果は変わりません', 'それでも期待させる', '煽りは本気'];
      return EffectPlan(
        rank: EffectRank.gekiatsu,
        beats: [
          EffectBeat(
            headline: _pick(['CHANCE', 'チャンス到来', '煽り開始']),
            subline: _pick(chanceSubs),
            duration: const Duration(milliseconds: 1000),
            intensity: EffectIntensity.high,
            cue: EffectCue.preAlert,
          ),
          EffectBeat(
            headline: _pick(gekiHeads),
            subline: _pick(['期待度 92%（演出上）', '信頼度MAX', '外したらごめん']),
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.extreme,
            cue: EffectCue.symbolLock,
          ),
          EffectBeat(
            headline: '押 せ',
            subline: _pick(['PUSHで復活を呼び込め', '連打!!', '魂のPUSH']),
            duration: const Duration(milliseconds: 900),
            intensity: EffectIntensity.high,
            cue: EffectCue.pushPrompt,
          ),
          EffectBeat(
            headline: _pick(['まだだ！！', '終わらんよ', 'もう一発']),
            subline: _pick(['無駄にもう一回煽ります', 'しつこい演出', '諦めない心']),
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
