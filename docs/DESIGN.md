# ドパ電卓 設計

## コンポーネント

- `CalculatorEngine`: 式の字句解析、RPN変換、計算、表示整形
- `EffectDirector`: 結果に応じた演出ランク決定
- `CalculatorPage`: 入力状態、計算実行、演出の表示制御
- `_EffectOverlay`: 演出レイヤー
- `SoundManager`: オリジナルSEのアセット再生

## 設計原則

計算結果は先に確定し、その値を `EffectDirector` に渡す。演出抽選が計算値を書き換える経路を持たせない。

## 状態

- `_expression`: 現在の式
- `_display`: 表示文字列
- `_isResolving`: 演出中
- `_showResult`: 結果表示状態
- `_activePlan`: 現在の演出

## 例外

`CalculatorException` をUI境界で捕捉し、クラッシュではなく表示エラーへ変換する。

## 今後の拡張候補

1. オリジナルSE/BGM
2. 「先読み」「復活」「擬似連」などの演出シーケンス
3. 演出強度設定
4. サイレントモード
5. 計算履歴
6. 広告削除買い切り
