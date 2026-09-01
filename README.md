# ドパ電卓

普通の四則演算なのに、`=` を押した瞬間だけ無駄にパチンコ風の煽り演出が走るネタ電卓です。

## MVP

- 四則演算: `+ - × ÷`
- 小数・負数（±キー）
- 演算優先順位対応
- 0除算エラー
- 演出ランク: NORMAL / CHANCE / 激熱 / PREMIUM
- 演出は複数ビートで段階的に煽る（NORMAL → CHANCE → 激熱 → PUSH → シャッター → 暗転 → 復活 → PREMIUMなど）
- 先バレ、7図柄ロック、3→2→1の擬似PUSH、左右シャッター、復活白フラッシュ、役物落下、777 JACKPOT
- ランク帯、DOPA HEAT、盤面ランプ、発光文字、走査光、リング、粒子、放射線、流星、稲妻、フラッシュを重ねた演出
- 最終ビート後に計算結果を「RESULT UNLOCKED」として大きく解放表示
- `7 / 77 / 777 / 7777 / 8192` は強制PREMIUM（8ビート、総尺9秒）
- 結果 `0` は「全消灯」演出
- 演出SKIP（PUSH・シャッター・暗転・結果解放中も利用可能）
- Reduce Motion (`disableAnimations`) 対応
- `EffectCue` に同期したSE・ハプティクス
  - 先バレ: 専用上昇チャープ + 中振動
  - 図柄ロック: `impact.wav` + 強振動
  - PUSH: `impact.wav` + 中→中→強の3段振動
  - シャッター: 専用の低音衝撃＋金属リング＋ノイズ + 強→長振動
  - 完全暗転: 再生中SE停止 + 無振動
  - 復活: 専用の低音衝撃＋上昇スイープ + 長→強振動
  - JACKPOT: 専用4音アルペジオ＋高域スパークル + 長→強→長の3段振動
- Cueごとに音量・再生速度も調整し、同じ素材を使う演出間にも重量感/鋭さの差を付与
- 先バレ/シャッター/復活/JACKPOTの専用SEは16bit mono PCM WAVをDartで合成し、`BytesSource` で再生
- 専用SEはSoundManager生成時にプリウォームして演出開始時の合成負荷を回避
- SKIP/RESET時は再生中SEと予約済み遅延ハプティクスをキャンセル
- 既存オリジナルSE（tick / chance / impact / premium）も継続利用
- 音声再生: `audioplayers ^6.8.1`

## 起動

Flutter SDKがある環境で:

```bash
flutter pub get
flutter test
flutter run
```

## 品質ゲート

```bash
flutter pub get
git diff --check
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

または:

```bash
./tool/quality_gate.sh
```

## MVPで意図的に未実装

- BGM
- 広告
- 設定画面
- 計算履歴
- ストア用アイコン/スクリーンショット
- iOS固有調整

まず「計算機として壊れていない」「演出が笑える」の2点を優先して検証する構成です。
