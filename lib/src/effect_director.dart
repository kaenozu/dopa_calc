import 'dart:math';

enum EffectRank { normal, chance, gekiatsu, premium }

enum EffectIntensity { low, medium, high, extreme }

class EffectBeat {
  const EffectBeat({
    required this.headline,
    required this.subline,
    required this.duration,
    this.intensity = EffectIntensity.low,
  });

  final String headline;
  final String subline;
  final Duration duration;
  final EffectIntensity intensity;
}

class EffectPlan {
  const EffectPlan({required this.rank, required this.beats});

  final EffectRank rank;
  final List<EffectBeat> beats;

  Duration get duration =>
      beats.fold(Duration.zero, (total, beat) => total + beat.duration);
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
            duration: const Duration(milliseconds: 1000),
            intensity: EffectIntensity.low,
          ),
          EffectBeat(
            headline: '先 読 み 発 生',
            subline: '数字がざわついています',
            duration: const Duration(milliseconds: 1500),
            intensity: EffectIntensity.medium,
          ),
          EffectBeat(
            headline: '超・確・定',
            subline: '7系プレミアム',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.high,
          ),
          EffectBeat(
            headline: 'ドパ計算RUSH',
            subline: '答えは最初から決まっている',
            duration: const Duration(milliseconds: 2500),
            intensity: EffectIntensity.extreme,
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
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.medium,
          ),
          EffectBeat(
            headline: '1% 突 破',
            subline: '確定音は脳内で鳴らしてください',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.high,
          ),
          EffectBeat(
            headline: '超 計 算',
            subline: 'PREMIUM',
            duration: const Duration(milliseconds: 2600),
            intensity: EffectIntensity.extreme,
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
            duration: const Duration(milliseconds: 1200),
            intensity: EffectIntensity.high,
          ),
          EffectBeat(
            headline: '激 熱',
            subline: '期待度 92%（演出上）',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.extreme,
          ),
          EffectBeat(
            headline: 'まだだ！！',
            subline: '無駄にもう一回煽ります',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.high,
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
          ),
          EffectBeat(
            headline: '計 算 リ ー チ',
            subline: '答えを出すだけです',
            duration: const Duration(milliseconds: 1800),
            intensity: EffectIntensity.medium,
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
