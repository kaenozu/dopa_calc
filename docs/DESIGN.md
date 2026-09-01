# ドパ電卓 設計

## コンポーネント

- `CalculatorEngine`: 式の字句解析、RPN変換、計算、表示整形
- `CalculationController`: 入力式・表示・結果確定状態を管理し、計算状態遷移をUIから分離
- `EffectDirector`: 結果に応じた演出ランク・ビート・強度の決定
- `CalculatorPage`: Controller / Director / Player / Overlay のオーケストレーション
- `EffectOverlay`: 演出UI、ビート進行、描画、SKIP導線、最終結果クライマックス
- `EffectPlayer`: ビートごとの効果音・ハプティクスを統一管理
- `SoundManager`: オリジナルSEのアセット再生

## 設計原則

計算結果は先に確定し、その値を `EffectDirector` に渡す。演出抽選や描画が計算値を書き換える経路を持たせない。

入力・計算状態は `CalculationController`、演出の時間進行は `EffectOverlay` が所有する。Page側とOverlay側で同じタイマーを持たず、演出の完了通知はOverlayからPageへ一本化する。

PREMIUMのランク昇格では `EffectBeat.displayRank` を有効ランクとして扱い、視覚テーマと効果音のランクを同じ `EffectPlan.rankForBeat()` から取得する。暗転ビートは `BeatEvent.silent` により音・ハプティクスも抑止する。

## 状態

- `CalculationController.expression`: 現在の式
- `CalculationController.display`: 現在の表示
- `CalculationController.isResolving`: 演出中
- `CalculationController.showResult`: 結果表示状態
- `CalculatorPage._activePlan`: 現在の演出

## 演出描画

- ランク帯、DOPA HEAT、盤面ランプ、背景グラデーション、走査光、発光見出し、リング、粒子、放射線、流星、稲妻、フラッシュをレイヤー化する。
- 描画量はランクごとに上限を持たせ、PREMIUMでも粒子96個・放射線48本を上限とする。派手さは単純な描画数増加ではなく、演出レイヤーと時間構成で上げる。
- PREMIUMでは NORMAL → CHANCE → 激熱 → 暗転 → 復活 → PREMIUM のように、期待感と落差を段階的に作る。
- 最終結果は `ResultClimax` で解放表示し、長い指数表記でも `FittedBox` で画面内に収める。
- 小画面では `FittedBox` で見出しを縮小し、固定フォントサイズによるオーバーフローを避ける。
- `MediaQuery.disableAnimations` が有効なら常時アニメーション、フラッシュ、揺れを停止する。
- 暗転を含む全演出フェーズと最終結果表示中もSKIP導線を最前面に保持する。

## 例外

`CalculatorException` をUI境界で捕捉し、クラッシュではなく表示エラーへ変換する。

## 今後の拡張候補

1. 演出強度設定
2. サイレントモード
3. 計算履歴
4. 広告削除買い切り
5. 端末別の実測フレーム時間に基づく描画予算調整
