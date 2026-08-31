# REVIEW_FIXES — kaenozu/dopa_calc@7224483 対応

## 対象
- Branch: `main`
- HEAD: `722448331d19201e2b1bb5704caa2389e245ea87`
- レビュー指摘: P1×3, P2×3 → 全件対応

## P1 — `=`後の連続計算で左辺が消える
**原因:** `lib/src/calculator_page.dart:123` `_appendOperator()` が `_showResult` を `false` にしないため、次の `_appendNumber()` で `_expression = ''` にリセット。
**修正:**
- `_appendOperator()` 先頭で `_showResult` を検知し、結果を左辺として継続。エラー表示中（`_display != _expression`）はクリア。
- 演算子追加時にも `_showResult = false` を明示。
- 回帰: `test/calculator_page_test.dart` で `1+2= → + → 4 → = → 7` と `3+` が消えないことを検証。

## P1 — 微小な非ゼロ値を`0`と表示
**原因:** `lib/src/calculator_engine.dart:29-44` の `abs(value - rounded) < 1e-10` が `1e-11` を `0` に丸める。`formatted == '0'` が `EffectDirector` に渡り全消灯が誤爆。
**修正:**
- `1e-10` 絶対閾値による整数化を廃止。
- `toStringAsFixed(10)` のトリム結果が `0/-0` かつ元が非ゼロなら `toStringAsExponential(10)` へフォールバック（仮数部の0除去、指数の+除去）。
- 回帰: `test/calculator_engine_test.dart` に `1÷100000000000 != 0` / `1÷3` / `0.99999999995` / `1e-11` を追加。

## P1 — clean checkoutからAndroidビルド不能
**原因:** `android/` と `.metadata` が未commit。READMEの `flutter create . --platforms=android` が必要。
**修正:** `flutter create . --platforms=android` (Flutter 3.44.0) で生成された `android/` 一式と `.metadata` をcommit。これにより `git clone && flutter pub get && flutter build apk --debug` が成立。CIでも検証。

## P2 — 常時AnimationController動作
**原因:** `initState()` で `..repeat(reverse:true)` を常時実行。
**修正:**
- `initState` では `value: 1.0` で停止状態で生成。
- `_startPulse()` / `_stopPulse()` を追加。`_resolve()` で `repeat`、`Timer`完了・`_skipEffect()`・`_clear()` で `stop`。
- `didChangeDependencies()` で `MediaQuery.disableAnimations` の切替に追従。
- `_EffectOverlay` では `disableAnimations` 時に `pulseDelta=0, scale=1, shake=false, AnimatedSwitcher duration=0`。

## P2 — SDK制約とlockfile不一致
**原因:** `pubspec.yaml` が `sdk: '>=3.6.0'` なのに `pubspec.lock` は `dart >=3.12.0 / flutter >=3.44.0`。
**修正:** `pubspec.yaml` を `sdk: '>=3.12.0 <4.0.0'` + `flutter: '>=3.44.0'` に更新。

## P2 — CI / Widgetテスト不在
**修正:**
- `test/calculator_page_test.dart` を追加（連続計算、±、⌫、AC、48文字境界、SKIP、SKIP不変、0除算エラー復帰、disableAnimations）。
- `tool/quality_gate.sh` を追加（format / analyze / test / build を一括）。
- `.github/workflows/ci.yml` を追加（push/PRで上記を実行）。

## 検証
```
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```
全てPASS。`flutter create` 由来の差分はSDKバージョン固定のため再現可能。
