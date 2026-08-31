import 'dart:math';

enum EffectRank { normal, chance, gekiatsu, premium }

class EffectBeat {
  const EffectBeat({
    required this.headline,
    required this.subline,
    required this.duration,
  });

  final String headline;
  final String subline;
  final Duration duration;
}

class EffectPlan {
  const EffectPlan({required this.rank, required this.beats});

  final EffectRank rank;
  final List<EffectBeat> beats;

  Duration get duration =>
      beats.fold(Duration.zero, (total, beat) => total + beat.duration);
}

class EffectDirector {
  EffectDirector({Random? random}) : _random = random ?? Random();

  final Random _random;

  EffectPlan planFor(String formattedResult) {
    final canonical = formattedResult.replaceAll(',', '');

    if (_isPremiumNumber(canonical)) {
      return const EffectPlan(
        rank: EffectRank.premium,
        beats: [
          EffectBeat(
            headline: '・・・',
            subline: '何かがおかしい',
            duration: Duration(milliseconds: 420),
          ),
          EffectBeat(
            headline: '先 読 み 発 生',
            subline: '数字がざわついています',
            duration: Duration(milliseconds: 620),
          ),
          EffectBeat(
            headline: '超・確・定',
            subline: '7系プレミアム',
            duration: Duration(milliseconds: 720),
          ),
          EffectBeat(
            headline: 'ドパ計算RUSH',
            subline: '答えは最初から決まっている',
            duration: Duration(milliseconds: 900),
          ),
        ],
      );
    }

    if (canonical == '0') {
      return const EffectPlan(
        rank: EffectRank.gekiatsu,
        beats: [
          EffectBeat(
            headline: '全 消 灯',
            subline: '画面が仕事をやめました',
            duration: Duration(milliseconds: 700),
          ),
          EffectBeat(
            headline: '……',
            subline: 'からの？',
            duration: Duration(milliseconds: 560),
          ),
          EffectBeat(
            headline: '復 活',
            subline: 'そして答えは0',
            duration: Duration(milliseconds: 760),
          ),
        ],
      );
    }

    final roll = _random.nextInt(100);
    if (roll == 0) {
      return const EffectPlan(
        rank: EffectRank.premium,
        beats: [
          EffectBeat(
            headline: '違 和 感',
            subline: 'ただの計算では終わらない',
            duration: Duration(milliseconds: 500),
          ),
          EffectBeat(
            headline: '1% 突 破',
            subline: '確定音は脳内で鳴らしてください',
            duration: Duration(milliseconds: 760),
          ),
          EffectBeat(
            headline: '超 計 算',
            subline: 'PREMIUM',
            duration: Duration(milliseconds: 980),
          ),
        ],
      );
    }
    if (roll < 10) {
      return const EffectPlan(
        rank: EffectRank.gekiatsu,
        beats: [
          EffectBeat(
            headline: 'CHANCE',
            subline: '期待しても計算結果は変わりません',
            duration: Duration(milliseconds: 520),
          ),
          EffectBeat(
            headline: '激 熱',
            subline: '期待度 92%（演出上）',
            duration: Duration(milliseconds: 720),
          ),
          EffectBeat(
            headline: 'まだだ！！',
            subline: '無駄にもう一回煽ります',
            duration: Duration(milliseconds: 720),
          ),
        ],
      );
    }
    if (roll < 30) {
      return const EffectPlan(
        rank: EffectRank.chance,
        beats: [
          EffectBeat(
            headline: 'CHANCE',
            subline: 'ただの計算なのに期待度UP',
            duration: Duration(milliseconds: 540),
          ),
          EffectBeat(
            headline: '計 算 リ ー チ',
            subline: '答えを出すだけです',
            duration: Duration(milliseconds: 760),
          ),
        ],
      );
    }

    return const EffectPlan(
      rank: EffectRank.normal,
      beats: [
        EffectBeat(
          headline: '計 算 中',
          subline: '無駄に溜めています',
          duration: Duration(milliseconds: 620),
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
