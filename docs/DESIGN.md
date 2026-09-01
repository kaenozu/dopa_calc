# ドパ電卓 設計

## コンポーネント

- `CalculatorEngine`: 式の字句解析、RPN変換、計算、表示整形
- `CalculationController`: 入力式・表示・結果確定状態を管理し、計算状態遷移をUIから分離
- `EffectDirector`: 結果に応じた演出ランク・ビート・強度・`EffectCue` の決定
- `CalculatorPage`: Controller / Director / Player / Overlay のオーケストレーション
- `EffectOverlay`: 演出UI、ビート進行、ビート内進行率、SKIP導線、最終結果クライマックス
- `PachinkoMachineOverlay`: 先バレ、サイレンLED、7図柄ロック、復活役物、777 JACKPOT
- `PachinkoCinematicOverlay`: PUSHカウントダウン、左右シャッター、復活白フラッシュなどビート進行率依存の演出
- `EffectPlayer`: `EffectCue` ごとのSE・ハプティクスパターンとキャンセル制御
- `SoundManager`: オリジナルSEの再生と純粋なCue→assetマッピング

## 設計原則

計算結果は先に確定し、その値を `EffectDirector` に渡す。演出抽選や描画が計算値を書き換える経路を持たせない。

入力・計算状態は `CalculationController`、演出の時間進行は `EffectOverlay` が所有する。Page側とOverlay側で同じタイマーを持たず、演出の完了通知はOverlayからPageへ一本化する。

PREMIUMのランク昇格では `EffectBeat.displayRank` を有効ランクとして扱い、視覚テーマと効果音のランクを同じ `EffectPlan.rankForBeat()` から取得する。暗転ビートは `BeatEvent.silent` により音・ハプティクスも抑止する。

`EffectCue` は `standard / preAlert / symbolLock / pushPrompt / shutter / blackout / revival / jackpot` を持つ。演出ロジック・描画・音・ハプティクスをCueで同期し、計算ロジックを変更せず予告や役物を追加できる構造を維持する。

## 状態

- `CalculationController.expression`: 現在の式
- `CalculationController.display`: 現在の表示
- `CalculationController.isResolving`: 演出中
- `CalculationController.showResult`: 結果表示状態
- `CalculatorPage._activePlan`: 現在の演出
- `EffectOverlay._beatIndex`: 現在のビート
- `EffectOverlay._beatProgressController`: 現ビート内の0〜1進行率。PUSHの3→2→1、シャッター閉→開、復活フラッシュに利用
- `EffectPlayer._generation`: 遅延ハプティクスの世代トークン。新ビート・SKIP・RESET・disposeで旧パターンを無効化

## 演出描画

- ランク帯、DOPA HEAT、盤面ランプ、背景グラデーション、走査光、発光見出し、リング、粒子、放射線、流星、稲妻、フラッシュをレイヤー化する。
- 描画量はランクごとに上限を持たせ、PREMIUMでも粒子96個・放射線48本を上限とする。派手さは単純な描画数増加ではなく、演出レイヤーと時間構成で上げる。
- 強制PREMIUMは **NORMAL → CHANCE → 激熱 → PUSH → シャッター → 暗転 → 復活 → PREMIUM** の8ビート、総尺9秒。ビート数を増やしても待ち時間を延ばさず、密度を上げる。
- ランク差を保つため、CHANCEにはPUSHを出さず、激熱以上でPUSH、PREMIUMのみシャッターとJACKPOTへ到達する。
- PUSHはビート進行率を使い3→2→1を表示する。実ボタン操作を要求せず、演出SKIPの操作性を阻害しない装飾レイヤーとする。
- シャッターはビート前半で左右から閉鎖し、後半で再び開く。暗転直前の圧縮感を作る。
- 復活/JACKPOT開始時は短い白フラッシュと拡大リングを重ね、暗転からの輝度差を強調する。
- 最終結果は `ResultClimax` で解放表示し、長い指数表記でも `FittedBox` で画面内に収める。
- 小画面では `FittedBox` で見出しを縮小し、固定フォントサイズによるオーバーフローを避ける。
- `MediaQuery.disableAnimations` が有効なら常時アニメーション、カウントダウン進行、シャッター移動、フラッシュ、揺れを停止し、意味のある静的表示を残す。
- `PachinkoMachineOverlay` / `PachinkoCinematicOverlay` は装飾用のため `ExcludeSemantics` と `IgnorePointer` でTalkBack・タップ操作を妨げない。
- PUSH・シャッター・暗転を含む全演出フェーズと最終結果表示中もSKIP導線を最前面に保持する。

## 音・ハプティクス

`EffectPlayer` は有効ランクだけでなく `EffectCue` を受け取り、映像の演出意味とSE・振動を同期する。

| Cue | SE | ハプティクス |
|---|---|---|
| `standard` | ランク/ビート従来マッピング | intensity準拠 |
| `preAlert` | `chance.wav` | medium |
| `symbolLock` | `impact.wav` | heavy |
| `pushPrompt` | `impact.wav` | medium → 240ms → medium → 240ms → heavy |
| `shutter` | `impact.wav` | heavy → 150ms → vibrate |
| `blackout` | 再生中SEを停止 | なし |
| `revival` | `premium.wav` | vibrate → 120ms → heavy |
| `jackpot` | `premium.wav` | vibrate → 100ms → heavy → 100ms → vibrate |

`SoundManager.assetFor()` はstaticな純粋関数とし、AudioPlayerを初期化せずCue→assetマッピングを単体テストできるようにする。

PUSH/JACKPOT等の遅延ハプティクスは世代トークンで管理する。新しいビートが開始された時点で旧世代は無効になり、SKIP/RESETでは `EffectPlayer.cancelPending()` が世代を進めて再生中SEも停止する。したがって演出終了後に予約済み振動が漏れない。

## 例外

`CalculatorException` をUI境界で捕捉し、クラッシュではなく表示エラーへ変換する。

## 今後の拡張候補

1. 演出強度設定
2. サイレントモード
3. 計算履歴
4. 広告削除買い切り
5. 端末別の実測フレーム時間に基づく描画予算調整
6. Cue専用SE素材の追加（先バレ音、シャッター金属音、確定ファンファーレ等）
