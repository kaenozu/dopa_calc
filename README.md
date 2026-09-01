# ドパ電卓

普通の四則演算なのに、`=` を押した瞬間だけ無駄にパチンコ風の煽り演出が走るネタ電卓です。

## MVP

- 四則演算: `+ - × ÷`
- 小数・負数（±キー）
- 演算優先順位対応
- 0除算エラー
- 演出ランク: NORMAL / CHANCE / 激熱 / PREMIUM
- 演出は複数ビートで段階的に煽る（NORMAL → CHANCE → 激熱 → 暗転 → 復活 → PREMIUMなど）
- ランク帯、DOPA HEAT、盤面ランプ、発光文字、走査光、リング、粒子、放射線、流星、稲妻、フラッシュを重ねた演出
- 最終ビート後に計算結果を「RESULT UNLOCKED」として大きく解放表示
- `7 / 77 / 777 / 7777 / 8192` は強制PREMIUM
- 結果 `0` は「全消灯」演出
- 演出SKIP（結果解放中も利用可能）
- Reduce Motion (`disableAnimations`) 対応
- バイブ・クリック音
- オリジナル生成SE（tick / chance / impact / premium）
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

- BGM・より多彩なSE
- 広告
- 設定画面
- 計算履歴
- ストア用アイコン/スクリーンショット
- iOS固有調整

まず「計算機として壊れていない」「演出が笑える」の2点を優先して検証する構成です。
